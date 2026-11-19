<#
  windows-awx-prep.ps1
  Minimal setup so AWX can connect to a Windows laptop over SSH as "surveily".
    - checks that the "surveily" account exists and is a local administrator
    - installs and enables OpenSSH Server, with PowerShell as the default shell
    - makes sure the SSH firewall rule exists (Private networks only)
    - installs the AWX public key ($AwxKey) and an admin key ($Key) in surveily's
      own authorized_keys, so AWX can make the first playbook run
    - marks the local network it runs on Private, so the playbook can also run
      over the LAN. Run it on a trusted network: SSH stays open there.
    - prints the host line for the AWX inventory

  The surveily account is created during installation (Rufus), not by this script.

  Working copy. The main copy lives in a separate repo.

  Run from an elevated PowerShell (Run as administrator):
    iex (irm https://raw.githubusercontent.com/Surveily/Images/refs/heads/master/script/host-setup/windows-awx-prep.ps1)
#>

# Everything is wrapped in a function that is only called on the last line, so
# a download cut off partway through never runs half the script.
function Invoke-AwxPrep {
    # Local to this function, so they don't leak into the calling session.
    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'

    # ---- Configuration -------------------------------------------------------
    $TargetUser = 'surveily'
    # Admin key: the admin who sets up laptops. Also in windows_laptop_baseline_ssh_admin_keys.
    $Key        = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC3YBf/6aIy5u/Mf+F6hxoBo4RSGpq8SsXBsb95KBCBG2T7s08nSYRKVTBlWw78qGh8fpXzjI6OsK1fwPGgIalxUSf34zftW1BgDpGOMrd3lYBBP9QgmlvoG8yginb5cfnAcLcGbp9NnWlLWF6vtMt2jzzqcjdwyywx1kpi5VmRUQmDHF/wlU/J2tbTA6OreLBcfAMAQ9W6ScslFeiFCVwoGB8r3ZuRi35PwjSIHr/MkPPswMaWplKjCgwVoq+vaZyO6k/fhkyKsRM28q9m0nIT+Cpvwit5DPCHZGcB33NdVbxc+PuWZzcI+BwZFPG+LH383DNR8vwAsQs7It/naTrslfmWOJaHpiqaxWC7QOBrLGIVrNalsRCtwOj0KZCUfW/3t7Tg000+u8JKRIfKc5CaZEM8nvLXp3XHMKKecYXLSCAzU6ur5kSIqhz6yNa3nU5J/wTo8ORHpux1q0n4ManqtyH0i6PSDWyrwHdt0PDFv161DhpesYpCI+a1zmZvVTPqM4uoaRPFSYMsxdmMb/myblb0sNUN7lhEM2BW5gw6AzVxPSMWio+TU77c3NyJHvFJgx5bVGq8lLjMDhZFal6XfIusHfa3BdP3nA2i9wKPGxV/dSBZU5vHPXY5ebEAFQiuU1GYMKHKbU4+CRNvibPESQFQc29XfUu6ECcHYMEI5w== bartosz.sadecki@surveily.com'
    # AWX key: public key of the AWX credential, so AWX can make the first
    # playbook run. Must match windows_laptop_baseline_ssh_awx_key.
    $AwxKey     = 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMiHvPpbe9l0PMtGhp2it79+fU24EietAFycy0FNN8X support@surveily.com'
    # --------------------------------------------------------------------------

    $SshdConfig = Join-Path $env:ProgramData 'ssh\sshd_config'

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

    # Catches copy/paste mistakes in the keys. ssh-keygen ships with Windows' OpenSSH client.
    $Keys = @($AwxKey, $Key)
    $sshKeygen = Join-Path $env:SystemRoot 'System32\OpenSSH\ssh-keygen.exe'
    if (Test-Path $sshKeygen) {
        foreach ($k in $Keys) {
            $tmp = New-TemporaryFile
            try {
                [System.IO.File]::WriteAllText($tmp.FullName, "$k`n")
                # Native tools writing to stderr would trip 'Stop', so relax it here.
                & { $ErrorActionPreference = 'Continue'; & $sshKeygen -l -f $tmp.FullName 2>&1 | Out-Null }
                if ($LASTEXITCODE -ne 0) { throw "This hard-coded key is not a valid SSH public key: $k" }
            } finally {
                Remove-Item $tmp.FullName -Force
            }
        }
    } else {
        Write-Warning 'ssh-keygen not found; skipping key validation.'
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
    # The playbook marks the WireGuard tunnel network Private, for admin SSH
    # when the user is away from the office.
    $ruleName = 'OpenSSH-Server-In-TCP'
    if (-not (Get-NetFirewallRule -Name $ruleName -ErrorAction SilentlyContinue)) {
        Write-Host '==> Adding firewall rule for SSH'
        New-NetFirewallRule -Name $ruleName -DisplayName 'OpenSSH Server (sshd)' -Direction Inbound `
            -Protocol TCP -LocalPort 22 -Action Allow -Profile Private | Out-Null
    }

    # ---- 4. SSH keys ---------------------------------------------------------
    Write-Host '==> Installing SSH keys'
    # -Force creates the .ssh folder too; it inherits the profile's permissions.
    if (-not (Test-Path $KeyFile)) { New-Item -ItemType File -Path $KeyFile -Force | Out-Null }

    # Only surveily, Administrators and SYSTEM may access the file; sshd
    # silently ignores it otherwise. Done before writing, so the key is never
    # in a file with looser permissions.
    & icacls.exe $KeyFile /inheritance:r /grant "${TargetUser}:F" /grant 'Administrators:F' /grant 'SYSTEM:F' | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Failed to set permissions on $KeyFile." }

    # .NET file I/O writes UTF-8 without a byte-order mark, which sshd needs.
    # (Windows PowerShell's own cmdlets would add one.) The playbook later
    # rewrites the whole file from its own key lists.
    foreach ($k in $Keys) {
        $content = [System.IO.File]::ReadAllText($KeyFile)
        $name = ($k -split ' ')[-1]
        # -ccontains: keys are case-sensitive; PowerShell compares case-insensitively by default.
        if (($content -split "`r?`n") -ccontains $k) {
            Write-Host "    $name already present"
        } else {
            # Without a final newline, the new key would be glued onto the last one.
            if ($content.Length -gt 0 -and -not $content.EndsWith("`n")) {
                [System.IO.File]::AppendAllText($KeyFile, "`r`n")
            }
            [System.IO.File]::AppendAllText($KeyFile, "$k`r`n")
            Write-Host "    $name added"
        }
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

    # ---- 6. Local network ----------------------------------------------------
    # The playbook always runs over the office LAN. The SSH rule is Private only,
    # so the network the laptop is on now is marked Private. Windows remembers
    # that for this network, so SSH stays open on it: run this script on a
    # trusted network (office, setup bench), not a cafe.
    # The network is the one Windows would use to reach the internet.
    $lan = Find-NetRoute -RemoteIPAddress '1.1.1.1' -ErrorAction SilentlyContinue |
        Where-Object { $_.CimClass.CimClassName -eq 'MSFT_NetIPAddress' } | Select-Object -First 1
    if ($lan) {
        Write-Host "==> Marking the local network on '$($lan.InterfaceAlias)' Private"
        Set-NetConnectionProfile -InterfaceAlias $lan.InterfaceAlias -NetworkCategory Private
    } else {
        throw 'No local network with a route to the internet found. Connect the laptop to the LAN, then re-run.'
    }

    # ---- 7. Summary for the inventory --------------------------------------
    # ansible_user, ansible_connection and ansible_shell_type come from the
    # inventory (all: vars, group_vars/windows_laptops.yml).
    Write-Host ''
    Write-Host '============================================'
    Write-Host ' Ready for the first playbook run (AWX or the admin), over this network.'
    Write-Host ' Add the host to the windows_laptops group:'
    Write-Host "   $env:COMPUTERNAME ansible_host=$($lan.IPAddress)"
    Write-Host '============================================'
}

# Errors are thrown rather than using "exit": exit inside iex would
# close the PowerShell window before anyone could read the message.
try {
    Invoke-AwxPrep
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
}
