#!/usr/bin/env bash
# Prepare a freshly installed Ubuntu host for Ansible provisioning from AWX.
#   - installs and enables OpenSSH server
#   - adds the hard-coded AWX public key to surveily's authorized_keys
#   - grants surveily passwordless sudo (needed for Ansible "become")
#   - prints the host IP for the AWX inventory
#
# Must be run as root.

# Everything is wrapped in main() so a partially downloaded script never runs.
main() {
    set -euo pipefail

    # ---- Configuration -------------------------------------------------------
    local TARGET_USER="surveily"
    local KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMiHvPpbe9l0PMtGhp2it79+fU24EietAFycy0FNN8X support@surveily.com"
    # --------------------------------------------------------------------------

    # Make sure we're running as root
    if [[ $EUID -ne 0 ]]; then
        echo "ERROR: this script must be run as root (e.g. 'curl ... | sudo bash')" >&2
        exit 1
    fi

    # Make sure the target user exists, and look up its home and group
    if ! id "$TARGET_USER" >/dev/null 2>&1; then
        echo "ERROR: user '$TARGET_USER' does not exist" >&2
        exit 1
    fi
    local TARGET_HOME TARGET_GROUP
    TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
    TARGET_GROUP="$(id -gn "$TARGET_USER")"

    echo "==> Preparing host for AWX (user: $TARGET_USER)"

    # 1. Install and enable OpenSSH server
    #
    # apt-get rather than apt: apt's CLI is meant for interactive use and isn't
    # guaranteed stable between releases; apt-get's is, so it's safe in scripts.
    #
    # DEBIAN_FRONTEND=noninteractive: stops debconf from showing prompts (e.g.
    # needrestart's "restart which services?" dialog) that would hang a piped
    # script; defaults are used instead.
    #
    # Note: this does not cover dpkg's "keep or replace modified config file?"
    # prompts (those need --force-confdef/--force-confold). They only appear
    # when upgrading packages with edited config, so not on a fresh install.
    echo "==> Installing openssh-server"
    apt-get update -qq
    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq openssh-server
    systemctl enable --now ssh

    # 2. Install the SSH public key
    echo "==> Installing SSH key"

    # Sanity-check the hard-coded key (catches copy/paste mistakes)
    if ! ssh-keygen -l -f - <<<"$KEY" >/dev/null 2>&1; then
        echo "ERROR: the hard-coded KEY is not a valid SSH public key" >&2
        exit 1
    fi

    local SSH_DIR="$TARGET_HOME/.ssh"
    local AUTH_KEYS="$SSH_DIR/authorized_keys"

    # Running as root, so ownership must be set explicitly: sshd ignores an
    # authorized_keys file or .ssh directory not owned by the user.
    install -d -m 700 -o "$TARGET_USER" -g "$TARGET_GROUP" "$SSH_DIR"
    touch "$AUTH_KEYS"
    chmod 600 "$AUTH_KEYS"
    chown "$TARGET_USER:$TARGET_GROUP" "$AUTH_KEYS"

    # Key comment (e.g. the email): everything after the second field of KEY,
    # since comments may contain spaces
    local KEY_COMMENT
    KEY_COMMENT="$(cut -d' ' -f3- <<<"$KEY")"

    # Add the key only if not already present (safe to re-run)
    if ! grep -qxF "$KEY" "$AUTH_KEYS"; then
        # If the file doesn't end in a newline, add one first; otherwise the
        # new key would be glued onto the end of the last existing key.
        if [[ -s "$AUTH_KEYS" && -n "$(tail -c1 "$AUTH_KEYS")" ]]; then
            echo >> "$AUTH_KEYS"
        fi
        echo "$KEY" >> "$AUTH_KEYS"
        echo "    added key: ${KEY_COMMENT:-<no comment>}"
    else
        echo "    key already present, skipping (${KEY_COMMENT:-<no comment>})"
    fi

    # 3. Passwordless sudo, so AWX can use "become" without a stored password
    #
    # The rule goes in its own file under /etc/sudoers.d/ rather than editing
    # /etc/sudoers directly. It's written to a temp file and checked with
    # "visudo -c" first: a syntax error in sudoers can lock you out of sudo
    # entirely, so a broken file is never installed. Mode 0440 is what sudo
    # expects; it ignores files in sudoers.d with looser permissions.
    echo "==> Configuring passwordless sudo"
    local SUDOERS_FILE="/etc/sudoers.d/$TARGET_USER"
    local SUDOERS_RULE="$TARGET_USER ALL=(ALL:ALL) NOPASSWD:ALL"

    if [[ -f "$SUDOERS_FILE" ]] && grep -qxF "$SUDOERS_RULE" "$SUDOERS_FILE"; then
        echo "    already configured, skipping"
    else
        local TMP_SUDOERS
        TMP_SUDOERS="$(mktemp)"
        echo "$SUDOERS_RULE" > "$TMP_SUDOERS"

        if ! visudo -cqf "$TMP_SUDOERS"; then
            rm -f "$TMP_SUDOERS"
            echo "ERROR: generated sudoers rule failed validation, not installing" >&2
            exit 1
        fi

        install -m 0440 -o root -g root "$TMP_SUDOERS" "$SUDOERS_FILE"
        rm -f "$TMP_SUDOERS"
        echo "    installed $SUDOERS_FILE"
    fi

    # 4. Print host details for the AWX inventory
    #
    # "|| true" matters: with no default route, "ip route get" fails, and under
    # set -e + pipefail that would abort the script here, silently, before the
    # summary is printed. With it, PRIMARY_IP is just empty and shows "unknown".
    local PRIMARY_IP
    PRIMARY_IP="$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="src") print $(i+1)}' || true)"

    echo
    echo "============================================"
    echo " Host ready for AWX"
    echo "   Hostname   : $(hostname)"
    echo "   Primary IP : ${PRIMARY_IP:-unknown}"
    echo "   All IPs    : $(hostname -I)"
    echo "   SSH user   : $TARGET_USER"
    echo
    echo " AWX inventory entry:"
    echo "   $(hostname) ansible_host=${PRIMARY_IP:-<ip>} ansible_user=$TARGET_USER"
    echo "============================================"
}

main "$@"
