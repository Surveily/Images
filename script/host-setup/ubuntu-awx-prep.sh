#!/usr/bin/env bash
# Prepare a freshly installed Ubuntu host for Ansible provisioning from AWX.
#   - installs and enables OpenSSH server
#   - adds the hard-coded AWX public key to surveily's authorized_keys
#   - grants surveily passwordless sudo (needed for Ansible "become")
#   - prints the host IP for the AWX inventory
#
# Must be run as the "surveily" user.

# Everything is wrapped in main() so a partially downloaded script never runs.
main() {
    set -euo pipefail

    # ---- Configuration -------------------------------------------------------
    local EXPECTED_USER="surveily"
    local KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMiHvPpbe9l0PMtGhp2it79+fU24EietAFycy0FNN8X support@surveily.com"
    # --------------------------------------------------------------------------

    # Make sure we're running as the expected user
    if [[ "$(id -un)" != "$EXPECTED_USER" ]]; then
        echo "ERROR: this script must be run as '$EXPECTED_USER' (currently: $(id -un))" >&2
        exit 1
    fi

    echo "==> Preparing host for AWX (user: $EXPECTED_USER)"

    # 1. Install and enable OpenSSH server
    #
    # apt-get rather than apt: apt's CLI is meant for interactive use and isn't
    # guaranteed stable between releases; apt-get's is, so it's safe in scripts.
    #
    # DEBIAN_FRONTEND=noninteractive: stops debconf from showing prompts (e.g.
    # needrestart's "restart which services?" dialog) that would hang a piped
    # script; defaults are used instead. Passed via "sudo env" because sudo
    # strips most environment variables.
    #
    # Note: this does not cover dpkg's "keep or replace modified config file?"
    # prompts (those need --force-confdef/--force-confold). They only appear
    # when upgrading packages with edited config, so not on a fresh install.
    echo "==> Installing openssh-server"
    sudo apt-get update -qq
    sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y -qq openssh-server
    sudo systemctl enable --now ssh

    # 2. Install the SSH public key
    echo "==> Installing SSH key"

    # Sanity-check the hard-coded key (catches copy/paste mistakes)
    if ! ssh-keygen -l -f - <<<"$KEY" >/dev/null 2>&1; then
        echo "ERROR: the hard-coded KEY is not a valid SSH public key" >&2
        exit 1
    fi

    local SSH_DIR="$HOME/.ssh"
    local AUTH_KEYS="$SSH_DIR/authorized_keys"

    install -d -m 700 "$SSH_DIR"
    touch "$AUTH_KEYS"
    chmod 600 "$AUTH_KEYS"

    # Key comment (e.g. the email), taken from the third field of KEY
    local KEY_COMMENT
    KEY_COMMENT="$(awk '{print $3}' <<<"$KEY")"

    # Add the key only if not already present (safe to re-run)
    if ! grep -qxF "$KEY" "$AUTH_KEYS"; then
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
    local SUDOERS_FILE="/etc/sudoers.d/$EXPECTED_USER"
    local SUDOERS_RULE="$EXPECTED_USER ALL=(ALL) NOPASSWD:ALL"

    if sudo test -f "$SUDOERS_FILE" && sudo grep -qxF "$SUDOERS_RULE" "$SUDOERS_FILE"; then
        echo "    already configured, skipping"
    else
        local TMP_SUDOERS
        TMP_SUDOERS="$(mktemp)"
        echo "$SUDOERS_RULE" > "$TMP_SUDOERS"

        if ! sudo visudo -cqf "$TMP_SUDOERS"; then
            rm -f "$TMP_SUDOERS"
            echo "ERROR: generated sudoers rule failed validation, not installing" >&2
            exit 1
        fi

        sudo install -m 0440 -o root -g root "$TMP_SUDOERS" "$SUDOERS_FILE"
        rm -f "$TMP_SUDOERS"
        echo "    installed $SUDOERS_FILE"
    fi

    # 4. Print host details for the AWX inventory
    local PRIMARY_IP
    PRIMARY_IP="$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="src") print $(i+1)}')"

    echo
    echo "============================================"
    echo " Host ready for AWX"
    echo "   Hostname   : $(hostname)"
    echo "   Primary IP : ${PRIMARY_IP:-unknown}"
    echo "   All IPs    : $(hostname -I)"
    echo "   SSH user   : $EXPECTED_USER"
    echo
    echo " AWX inventory entry:"
    echo "   $(hostname) ansible_host=${PRIMARY_IP:-<ip>} ansible_user=$EXPECTED_USER"
    echo "============================================"
}

main "$@"
