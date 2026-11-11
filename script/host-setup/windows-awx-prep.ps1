<#
  awx-prep.ps1
  Minimal setup so AWX can connect to a Windows laptop over SSH as "surveily".
    - checks that the "surveily" account exists and is a local administrator
    - installs and enables OpenSSH Server, with PowerShell as the default shell
    - makes sure the SSH firewall rule exists
    - installs the AWX public key in surveily's own authorized_keys
    - prints the host details for the AWX inventory

  The only sshd_config change is turning off the default rule that sends
  administrators to a shared key file. Other hardening (password login,
  firewall profiles, Entra admin access) is left to an Ansible playbook run
  afterwards.

  The surveily account is created during installation (Rufus), not by this script.

  Run from an elevated PowerShell (Run as administrator):
    iex (irm https://your.server/awx-prep.ps1)
#>

# Everything is wrapped in a function that is only called on the last line, so
# a download cut off partway through never runs half the script.
function Invoke-AwxPrep {
    # Both settings are local to this function, so they don't leak into the
    # PowerShell session the script was run from.
    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'

    # ---- Configuration -------------------------------------------------------
    $TargetUser = 'surveily'
    $Key        = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC3YBf/6aIy5u/Mf+F6hxoBo4RSGpq8SsXBsb95KBCBG2T7s08nSYRKVTBlWw78qGh8fpXzjI6OsK1fwPGgIalxUSf34zftW1BgDpGOMrd3lYBBP9QgmlvoG8yginb5cfnAcLcGbp9NnWlLWF6vtMt2jzzqcjdwyywx1kpi5VmRUQmDHF/wlU/J2tbTA6OreLBcfAMAQ9W6ScslFeiFCVwoGB8r3ZuRi35PwjSIHr/MkPPswMaWplKjCgwVoq+vaZyO6k/fhkyKsRM28q9m0nIT+Cpvwit5DPCHZGcB33NdVbxc+PuWZzcI+BwZFPG+LH383DNR8vwAsQs7It/naTrslfmWOJaHpiqaxWC7QOBrLGIVrNalsRCtwOj0KZCUfW/3t7Tg000+u8JKRIfKc5CaZEM8nvLXp3XHMKKecYXLSCAzU6ur5kSIqhz6yNa3nU5J/wTo8ORHpux1q0n4ManqtyH0i6PSDWyrwHdt0PDFv161DhpesYpCI+a1zmZvVTPqM4uoaRPFSYMsxdmMb/myblb0sNUN7lhEM2BW5gw6AzVxPSMWio+TU77c3NyJHvFJgx5bVGq8lLjMDhZFal6XfIusHfa3BdP3nA2i9wKPGxV/dSBZU5vHPXY5ebEAFQiuU1GYMKHKbU4+CRNvibPESQFQc29XfUu6ECcHYMEI5w== bartosz.sadecki@surveily.com'
    # --------------------------------------------------------------------------

    $SshExeDir  = Join-Path $env:SystemRoot 'System32\OpenSSH'
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

    # Sanity-check the hard-coded key before changing anything (catches
    # copy/paste mistakes). ssh-keygen ships with Windows' OpenSSH client.
    $sshKeygen = Join-Path $SshExeDir 'ssh-keygen.exe'
    if (Test-Path $sshKeygen) {
        $tmp = New-TemporaryFile
        try {
            [System.IO.File]::WriteAllText($tmp.FullName, "$Key`n")
            # Native tools writing to stderr would trip 'Stop', so relax it here
            & { $ErrorActionPreference = 'Continue'; & $sshKeygen -l -f $tmp.FullName 2>&1 | Out-Null }
            if ($LASTEXITCODE -ne 0) { throw 'The hard-coded $Key is not a valid SSH public key.' }
        } finally {
            Remove-Item $tmp.FullName -Force
        }
    } else {
        Write-Warning 'ssh-keygen not found; skipping key validation.'
    }

    $keyParts   = $Key -split ' ', 3
    $KeyComment = if ($keyParts.Count -ge 3) { $keyParts[2] } else { '<no comment>' }

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
    # OpenSSH on Windows defaults to cmd.exe; Ansible expects PowerShell.
    # Only affects SSH sessions, not the local terminal. Takes effect on the
    # next connection, no restart needed.
    Write-Host '==> Setting PowerShell as the default SSH shell'
    $regPath = 'HKLM:\SOFTWARE\OpenSSH'
    if (-not (Test-Path $regPath)) { New-Item -Path $regPath | Out-Null }
    New-ItemProperty -Path $regPath -Name DefaultShell -PropertyType String -Force `
        -Value (Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe') | Out-Null

    # ---- 3. Firewall ---------------------------------------------------------
    # Installing OpenSSH normally creates this rule. Only add it if it's missing,
    # since AWX can't connect without it; restricting it is left to the playbook.
    $ruleName = 'OpenSSH-Server-In-TCP'
    if (-not (Get-NetFirewallRule -Name $ruleName -ErrorAction SilentlyContinue)) {
        Write-Host '==> Adding firewall rule for SSH'
        New-NetFirewallRule -Name $ruleName -DisplayName 'OpenSSH Server (sshd)' -Direction Inbound `
            -Protocol TCP -LocalPort 22 -Action Allow | Out-Null
    }

    # ---- 4. SSH key ----------------------------------------------------------
    Write-Host '==> Installing SSH key'
    # -Force creates the .ssh folder too; it inherits the profile's permissions
    if (-not (Test-Path $KeyFile)) { New-Item -ItemType File -Path $KeyFile -Force | Out-Null }

    # Only surveily, Administrators and SYSTEM may access the file; sshd
    # silently ignores it otherwise. Done before writing, so the key is never
    # in a file with looser permissions.
    & icacls.exe $KeyFile /inheritance:r /grant "${TargetUser}:F" /grant 'Administrators:F' /grant 'SYSTEM:F' | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Failed to set permissions on $KeyFile." }

    # File I/O goes through .NET: it writes UTF-8 without a byte-order mark,
    # which sshd needs. (Windows PowerShell's own cmdlets would add one.)
    $content = [System.IO.File]::ReadAllText($KeyFile)
    # -ccontains: keys are case-sensitive, and PowerShell compares case-insensitively by default
    if (($content -split "`r?`n") -ccontains $Key) {
        Write-Host "    key already present, skipping ($KeyComment)"
    } else {
        # If the file doesn't end in a newline, add one first; otherwise the
        # new key would be glued onto the end of the last existing key.
        if ($content.Length -gt 0 -and -not $content.EndsWith("`n")) {
            [System.IO.File]::AppendAllText($KeyFile, "`r`n")
        }
        [System.IO.File]::AppendAllText($KeyFile, "$Key`r`n")
        Write-Host "    added key: $KeyComment"
    }

    # ---- 5. sshd_config: stop using the shared administrators key file -------
    # The default config ends with a "Match Group administrators" block that
    # points every admin, surveily included, at a shared key file and makes
    # sshd ignore their own authorized_keys. Commenting it out makes sshd use
    # each user's own file. Re-runs are safe: commented lines don't match.
    Write-Host '==> Updating sshd_config'
    $config  = [System.IO.File]::ReadAllText($SshdConfig)
    # [ \t] rather than \s: \s also matches line breaks and would spill onto other lines
    $updated = $config -replace '(?m)^([ \t]*Match[ \t]+Group[ \t]+administrators[ \t]*)(?=\r?$)', '#$1' `
                       -replace '(?m)^([ \t]*AuthorizedKeysFile[ \t]+__PROGRAMDATA__/ssh/administrators_authorized_keys)', '#$1'
    if ($updated -cne $config) {
        # Written through .NET for UTF-8 without a byte-order mark, which sshd needs
        [System.IO.File]::WriteAllText($SshdConfig, $updated)
        Restart-Service -Name sshd
    } else {
        Write-Host '    already updated'
    }

    # ---- 6. Summary for the AWX inventory ------------------------------------
    # Like "ip route get" on Linux: the address Windows would use to reach the
    # internet. With no route it fails; the summary then shows "unknown".
    $primaryIp = $null
    try {
        $primaryIp = Find-NetRoute -RemoteIPAddress '1.1.1.1' -ErrorAction Stop |
            Where-Object { $_.CimClass.CimClassName -eq 'MSFT_NetIPAddress' } |
            Select-Object -First 1 -ExpandProperty IPAddress
    } catch { }

    $allIps = (Get-NetIPAddress -AddressFamily IPv4 |
        Where-Object { $_.IPAddress -notlike '127.*' -and $_.IPAddress -notlike '169.254.*' } |
        Select-Object -ExpandProperty IPAddress) -join ' '

    $ipText = if ($primaryIp) { $primaryIp } else { 'unknown' }
    $ipInv  = if ($primaryIp) { $primaryIp } else { '<ip>' }

    Write-Host ''
    Write-Host '============================================'
    Write-Host ' Host ready for AWX'
    Write-Host "   Hostname   : $env:COMPUTERNAME"
    Write-Host "   Primary IP : $ipText"
    Write-Host "   All IPs    : $allIps"
    Write-Host "   SSH user   : $TargetUser"
    Write-Host ''
    Write-Host ' AWX inventory entry:'
    Write-Host "   $env:COMPUTERNAME ansible_host=$ipInv ansible_user=$TargetUser ansible_connection=ssh ansible_shell_type=powershell"
    Write-Host '============================================'
}

# Errors are thrown rather than using "exit": exit inside iex would
# close the PowerShell window before anyone could read the message.
try {
    Invoke-AwxPrep
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
}
