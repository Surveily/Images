<#
  windows-laptop-prep.ps1
  Minimal setup so AWX can connect to a Windows laptop over SSH as "surveily".
    - checks that the "surveily" account exists and is a local administrator
    - installs and enables OpenSSH Server, with PowerShell as the default shell
    - makes sure the SSH firewall rule exists (Private networks only)
    - installs the AWX public key in surveily's own authorized_keys
    - installs WireGuard and this laptop's tunnel as a service, marked Private
    - prints the host line for the AWX inventory

  Other hardening (password login, firewall profiles, Entra admin access) is
  left to the playbook (playbooks/windows-laptop-baseline.yml).

  The surveily account is created during installation (Rufus), not by this script.
  The WireGuard config comes from an admin: one per laptop, with its own key and
  tunnel IP, and PersistentKeepalive = 25 under [Peer]. Put it on surveily's
  Desktop as vpn.conf before running this script.

  Working copy. The main copy lives in a separate repo.

  Run from an elevated PowerShell (Run as administrator):
    iex (irm https://your.server/windows-laptop-prep.ps1)
#>

# Everything is wrapped in a function that is only called on the last line, so
# a download cut off partway through never runs half the script.
function Invoke-AwxPrep {
    # Local to this function, so they don't leak into the calling session.
    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'

    # ---- Configuration -------------------------------------------------------
    $TargetUser = 'surveily'
    $Key        = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC3YBf/6aIy5u/Mf+F6hxoBo4RSGpq8SsXBsb95KBCBG2T7s08nSYRKVTBlWw78qGh8fpXzjI6OsK1fwPGgIalxUSf34zftW1BgDpGOMrd3lYBBP9QgmlvoG8yginb5cfnAcLcGbp9NnWlLWF6vtMt2jzzqcjdwyywx1kpi5VmRUQmDHF/wlU/J2tbTA6OreLBcfAMAQ9W6ScslFeiFCVwoGB8r3ZuRi35PwjSIHr/MkPPswMaWplKjCgwVoq+vaZyO6k/fhkyKsRM28q9m0nIT+Cpvwit5DPCHZGcB33NdVbxc+PuWZzcI+BwZFPG+LH383DNR8vwAsQs7It/naTrslfmWOJaHpiqaxWC7QOBrLGIVrNalsRCtwOj0KZCUfW/3t7Tg000+u8JKRIfKc5CaZEM8nvLXp3XHMKKecYXLSCAzU6ur5kSIqhz6yNa3nU5J/wTo8ORHpux1q0n4ManqtyH0i6PSDWyrwHdt0PDFv161DhpesYpCI+a1zmZvVTPqM4uoaRPFSYMsxdmMb/myblb0sNUN7lhEM2BW5gw6AzVxPSMWio+TU77c3NyJHvFJgx5bVGq8lLjMDhZFal6XfIusHfa3BdP3nA2i9wKPGxV/dSBZU5vHPXY5ebEAFQiuU1GYMKHKbU4+CRNvibPESQFQc29XfUu6ECcHYMEI5w== bartosz.sadecki@surveily.com'
    # The playbook expects this name: service WireGuardTunnel$surveily, adapter "surveily".
    $TunnelName = 'surveily'
    # This laptop's WireGuard config from the admin, on surveily's Desktop.
    $WgConfName = 'vpn.conf'
    # Alias for the newest amd64 MSI. It is not in the directory listing, so it
    # may disappear without notice. If the download fails with 404, use
    # wireguard-installer.exe or a versioned MSI from that directory instead.
    $WgMsiUrl   = 'https://download.wireguard.com/windows-client/wireguard-amd64-latest.msi'
    # --------------------------------------------------------------------------

    $SshdConfig = Join-Path $env:ProgramData 'ssh\sshd_config'
    $WgExe      = Join-Path $env:ProgramFiles 'WireGuard\wireguard.exe'
    $WgService  = "WireGuardTunnel`$$TunnelName"

    # Runs $Condition once a second until it returns something true, and
    # returns that. Throws $Failure after $Seconds.
    function Wait-Until([scriptblock]$Condition, [int]$Seconds, [string]$Failure) {
        for ($i = 0; $i -lt $Seconds; $i++) {
            $result = & $Condition
            if ($result) { return $result }
            Start-Sleep -Seconds 1
        }
        throw $Failure
    }

    # ---- Checks --------------------------------------------------------------
    $principal = New-Object System.Security.Principal.WindowsPrincipal(
        [System.Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw 'This script must be run from an elevated PowerShell (Run as administrator).'
    }

    $user = Get-LocalUser -Name $TargetUser -ErrorAction SilentlyContinue
    if (-not $user) {
        throw "User '$TargetUser' does not exist. It should be created during installation."
    }

    # The playbook runs as this user without become, so it must be a local
    # administrator. Members are read over ADSI: Get-LocalGroupMember fails on
    # Entra members, and an Entra-joined laptop has some in Administrators.
    $adminsName = (Get-LocalGroup -SID 'S-1-5-32-544').Name
    $adminSids = @(([ADSI]"WinNT://$env:COMPUTERNAME/$adminsName,group").psbase.Invoke('Members') | ForEach-Object {
        $bytes = $_.GetType().InvokeMember('objectSid', 'GetProperty', $null, $_, $null)
        (New-Object System.Security.Principal.SecurityIdentifier($bytes, 0)).Value
    })
    if ($adminSids -notcontains $user.SID.Value) {
        throw "User '$TargetUser' is not in the local '$adminsName' group. The playbook needs it to be an administrator."
    }

    # SSH login for Entra groups only works on an Entra-joined device, not a
    # registered one. Warn only: the join can also be done afterwards.
    $dsreg = & dsregcmd.exe /status 2>$null
    if (-not ($dsreg -match 'AzureAdJoined\s*:\s*YES')) {
        Write-Warning ('This laptop is not Entra joined. Entra users will not be able to log in over SSH ' +
            'until it is. Use "Join this device to Microsoft Entra ID" in Settings > Accounts > ' +
            'Access work or school, not the email box above it.')
    }

    # The key goes in surveily's profile, which Windows only creates at its
    # first logon. Rufus-created accounts log in during setup, so it should exist.
    $profilePath = (Get-CimInstance Win32_UserProfile |
        Where-Object { $_.SID -eq $user.SID.Value } | Select-Object -First 1).LocalPath
    if (-not $profilePath) {
        throw "User '$TargetUser' has no profile yet. Log in as $TargetUser once, then re-run."
    }
    $KeyFile = Join-Path $profilePath '.ssh\authorized_keys'

    # An account that must change its password, or whose password has expired,
    # may be refused even with a valid key. Warn rather than change the account.
    # (No "password last set" date usually means "must change at next logon".)
    if ($null -eq $user.PasswordLastSet) {
        Write-Warning "'$TargetUser' must change its password at next logon. SSH key login may fail until it has."
    } elseif ($null -ne $user.PasswordExpires) {
        Write-Warning "'$TargetUser' password expires on $($user.PasswordExpires). Once expired, SSH key login may fail."
    }

    # Catches copy/paste mistakes in $Key. ssh-keygen ships with Windows' OpenSSH client.
    $sshKeygen = Join-Path $env:SystemRoot 'System32\OpenSSH\ssh-keygen.exe'
    if (Test-Path $sshKeygen) {
        $tmp = New-TemporaryFile
        try {
            [System.IO.File]::WriteAllText($tmp.FullName, "$Key`n")
            # Native tools writing to stderr would trip 'Stop', so relax it here.
            & { $ErrorActionPreference = 'Continue'; & $sshKeygen -l -f $tmp.FullName 2>&1 | Out-Null }
            if ($LASTEXITCODE -ne 0) { throw 'The hard-coded $Key is not a valid SSH public key.' }
        } finally {
            Remove-Item $tmp.FullName -Force
        }
    } else {
        Write-Warning 'ssh-keygen not found; skipping key validation.'
    }

    # Checked now, so a missing or wrong file stops the script before anything
    # changes. Not needed when the tunnel is already installed.
    $WgConfSource = $null
    if (-not (Get-Service -Name $WgService -ErrorAction SilentlyContinue)) {
        $WgConfSource = Join-Path $profilePath "Desktop\$WgConfName"
        if (-not (Test-Path $WgConfSource -PathType Leaf)) {
            throw "WireGuard config not found at $WgConfSource. Copy this laptop's config from the admin there, then re-run."
        }
        $confText = [System.IO.File]::ReadAllText($WgConfSource)
        foreach ($needed in '[Interface]', 'PrivateKey', 'Address', '[Peer]', 'Endpoint') {
            if ($confText -notmatch [regex]::Escape($needed)) {
                throw "$WgConfSource has no '$needed'. It does not look like this laptop's WireGuard config."
            }
        }
        # Without it the home router drops the idle tunnel, and AWX cannot reach
        # the laptop until it sends traffic itself.
        if ($confText -notmatch '(?m)^\s*PersistentKeepalive\s*=') {
            Write-Warning ("$WgConfSource has no 'PersistentKeepalive = 25' under [Peer]. AWX may not " +
                'reach this laptop at home. Ask the admin for a config with it.')
        }
    }

    Write-Host "==> Preparing host for AWX (user: $TargetUser)"

    # ---- 1. OpenSSH Server ---------------------------------------------------
    Write-Host '==> Installing OpenSSH Server'
    $cap = Get-WindowsCapability -Online -Name 'OpenSSH.Server*' | Select-Object -First 1
    if (-not $cap) { throw 'OpenSSH Server is not available as a capability on this Windows build.' }
    if ($cap.State -ne 'Installed') {
        Add-WindowsCapability -Online -Name $cap.Name | Out-Null
    } else {
        Write-Host '    already installed'
    }
    Set-Service -Name sshd -StartupType Automatic
    Start-Service -Name sshd

    # ---- 2. Default shell ----------------------------------------------------
    # OpenSSH on Windows defaults to cmd.exe. Ansible recommends PowerShell, and
    # the inventory sets ansible_shell_type: powershell to match. SSH sessions
    # only; takes effect on the next connection.
    Write-Host '==> Setting PowerShell as the default SSH shell'
    $regPath = 'HKLM:\SOFTWARE\OpenSSH'
    if (-not (Test-Path $regPath)) { New-Item -Path $regPath | Out-Null }
    New-ItemProperty -Path $regPath -Name DefaultShell -PropertyType String -Force `
        -Value (Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe') | Out-Null

    # ---- 3. Firewall ---------------------------------------------------------
    # Installing OpenSSH normally creates this rule; add it only if missing.
    # Private only: new networks are Public, so cafe and home Wi-Fi stay closed.
    # AWX comes in over the tunnel, which section 6 marks Private.
    $ruleName = 'OpenSSH-Server-In-TCP'
    if (-not (Get-NetFirewallRule -Name $ruleName -ErrorAction SilentlyContinue)) {
        Write-Host '==> Adding firewall rule for SSH'
        New-NetFirewallRule -Name $ruleName -DisplayName 'OpenSSH Server (sshd)' -Direction Inbound `
            -Protocol TCP -LocalPort 22 -Action Allow -Profile Private | Out-Null
    }

    # ---- 4. SSH key ----------------------------------------------------------
    Write-Host '==> Installing SSH key'
    # -Force creates the .ssh folder too; it inherits the profile's permissions.
    if (-not (Test-Path $KeyFile)) { New-Item -ItemType File -Path $KeyFile -Force | Out-Null }

    # Only surveily, Administrators and SYSTEM may access the file; sshd
    # silently ignores it otherwise. Done before writing, so the key is never
    # in a file with looser permissions.
    & icacls.exe $KeyFile /inheritance:r /grant "${TargetUser}:F" /grant 'Administrators:F' /grant 'SYSTEM:F' | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Failed to set permissions on $KeyFile." }

    # .NET file I/O writes UTF-8 without a byte-order mark, which sshd needs.
    # (Windows PowerShell's own cmdlets would add one.)
    $content = [System.IO.File]::ReadAllText($KeyFile)
    # -ccontains: keys are case-sensitive; PowerShell compares case-insensitively by default.
    if (($content -split "`r?`n") -ccontains $Key) {
        Write-Host '    key already present'
    } else {
        # Without a final newline, the new key would be glued onto the last one.
        if ($content.Length -gt 0 -and -not $content.EndsWith("`n")) {
            [System.IO.File]::AppendAllText($KeyFile, "`r`n")
        }
        [System.IO.File]::AppendAllText($KeyFile, "$Key`r`n")
        Write-Host '    key added'
    }

    # ---- 5. sshd_config: stop using the shared administrators key file -------
    # The default config ends with a "Match Group administrators" block that
    # points every admin, surveily included, at a shared key file and makes
    # sshd ignore their own authorized_keys. Commenting it out makes sshd use
    # each user's own file. Re-runs are safe: commented lines don't match.
    # The playbook later writes the whole sshd_config, also without that block.
    Write-Host '==> Updating sshd_config'
    $config  = [System.IO.File]::ReadAllText($SshdConfig)
    # [ \t] rather than \s: \s also matches line breaks and would spill onto other lines.
    $updated = $config -replace '(?m)^([ \t]*Match[ \t]+Group[ \t]+administrators[ \t]*)(?=\r?$)', '#$1' `
                       -replace '(?m)^([ \t]*AuthorizedKeysFile[ \t]+__PROGRAMDATA__/ssh/administrators_authorized_keys)', '#$1'
    if ($updated -cne $config) {
        [System.IO.File]::WriteAllText($SshdConfig, $updated)
        Restart-Service -Name sshd
    } else {
        Write-Host '    already updated'
    }

    # ---- 6. WireGuard tunnel -------------------------------------------------
    # Installed as a service: it runs as SYSTEM and starts at boot, so no user
    # has to start the VPN, and standard users cannot stop it. The playbook
    # keeps it running and Private, and updates WireGuard.
    Write-Host '==> Installing WireGuard'
    if (-not (Test-Path $WgExe)) {
        $msi = Join-Path $env:TEMP 'wireguard.msi'
        # Windows PowerShell 5.1: older .NET defaults may not offer TLS 1.2, and
        # the progress bar makes Invoke-WebRequest very slow.
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $WgMsiUrl -OutFile $msi -UseBasicParsing
        # DO_NOT_LAUNCH=1: do not open the WireGuard window after install.
        $p = Start-Process msiexec.exe -ArgumentList '/i', "`"$msi`"", '/qn', 'DO_NOT_LAUNCH=1' -Wait -PassThru
        Remove-Item $msi -Force
        # 3010: installed, a reboot is needed to finish. Still a success.
        if ($p.ExitCode -notin 0, 3010) { throw "WireGuard install failed (msiexec exit code $($p.ExitCode))." }
        if ($p.ExitCode -eq 3010) { Write-Warning 'WireGuard asks for a reboot to finish installing.' }
    } else {
        Write-Host '    already installed'
    }

    if ($WgConfSource) {
        Write-Host '==> Installing WireGuard tunnel'
        # The tunnel service reads its config from the path it was installed
        # with (wireguard-windows docs/enterprise.md), so the file must stay.
        # It is kept in a folder only SYSTEM and Administrators can read, so a
        # standard user cannot read the private key. No WireGuard manager
        # service: it is not needed for a tunnel service, and it opens a window
        # for administrators.
        $confDir = Join-Path $env:ProgramData 'Surveily\WireGuard'
        if (-not (Test-Path $confDir)) { New-Item -ItemType Directory -Path $confDir -Force | Out-Null }
        # Set before the file is copied in, so it is never readable by others.
        # SIDs, not names: S-1-5-18 is SYSTEM, S-1-5-32-544 is Administrators.
        & icacls.exe $confDir /inheritance:r /grant '*S-1-5-18:(OI)(CI)F' /grant '*S-1-5-32-544:(OI)(CI)F' | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "Failed to set permissions on $confDir." }

        # WireGuard takes the tunnel name from the file name.
        $conf = Join-Path $confDir "$TunnelName.conf"
        Copy-Item $WgConfSource $conf -Force
        & $WgExe /installtunnelservice $conf
        Wait-Until { Get-Service -Name $WgService -ErrorAction SilentlyContinue } 15 `
            "Tunnel service $WgService was not created." | Out-Null
        Write-Host "    installed. Delete the admin's copy at $WgConfSource too: it holds the private key."
    } else {
        Write-Host '    tunnel already installed'
    }

    # Windows marks the new tunnel network Public. SSH is allowed on Private only.
    # The adapter can take a few seconds to get a network profile.
    Write-Host '==> Marking the tunnel network Private'
    Wait-Until { Get-NetConnectionProfile -InterfaceAlias $TunnelName -ErrorAction SilentlyContinue } 60 `
        "Tunnel adapter '$TunnelName' has no network profile after 60 seconds." | Out-Null
    Set-NetConnectionProfile -InterfaceAlias $TunnelName -NetworkCategory Private

    # ---- 7. Summary for the AWX inventory ------------------------------------
    # AWX reaches the laptop over the tunnel, so ansible_host is the tunnel IP,
    # which is fixed per laptop. ansible_user, ansible_connection and
    # ansible_shell_type come from the inventory (all: vars, group_vars/windows_laptops.yml).
    $tunnelIp = Get-NetIPAddress -InterfaceAlias $TunnelName -AddressFamily IPv4 -ErrorAction SilentlyContinue |
        Select-Object -First 1 -ExpandProperty IPAddress
    if (-not $tunnelIp) { $tunnelIp = '<tunnel ip>' }

    Write-Host ''
    Write-Host '============================================'
    Write-Host ' Host ready for AWX. Add it to the windows_laptops group:'
    Write-Host "   $env:COMPUTERNAME ansible_host=$tunnelIp"
    Write-Host '============================================'
}

# Errors are thrown rather than using "exit": exit inside iex would
# close the PowerShell window before anyone could read the message.
try {
    Invoke-AwxPrep
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
}

