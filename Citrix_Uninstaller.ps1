# Citrix_Uninstaller.ps1
# Silently removes all Citrix components found in the Uninstall registry keys.
# Run elevated.

$appNamePattern = '*Citrix*'
$timeoutSec     = 600   # per-item ceiling so a stuck installer can't hang the whole run

$uninstallKeys = @(
    'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
)

function Split-CommandLine([string]$cmd) {
    if ($cmd -match '^\s*"([^"]+)"\s*(.*)$') { return $Matches[1], $Matches[2] }
    # Unquoted path: grab up to the .exe so paths with spaces still work
    if ($cmd -match '^\s*(.+?\.exe)\s*(.*)$') { return $Matches[1], $Matches[2] }
    $parts = $cmd -split ' ', 2
    return $parts[0], $parts[1]
}

function Invoke-Uninstaller([string]$exe, [string]$argList) {
    Write-Host "  -> $exe $argList" -ForegroundColor DarkGray
    try {
        $p = Start-Process -FilePath $exe -ArgumentList $argList -PassThru -NoNewWindow -ErrorAction Stop
        $null = $p.Handle   # cache handle so ExitCode is populated
    } catch {
        Write-Warning "  Failed to start: $($_.Exception.Message)"
        return
    }
    if (-not $p.WaitForExit($timeoutSec * 1000)) {
        Write-Warning "  Timed out after $timeoutSec s - killing process"
        try { $p.Kill() } catch {}
        return
    }
    switch ($p.ExitCode) {
        0       { Write-Host "  Done." -ForegroundColor Green }
        3010    { Write-Host "  Done (reboot required)." -ForegroundColor Green }
        1605    { Write-Host "  Already removed." -ForegroundColor DarkGray }
        default { Write-Warning "  Exit code $($p.ExitCode)" }
    }
}

$apps = Get-ItemProperty $uninstallKeys -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -like $appNamePattern -and ($_.UninstallString -or $_.QuietUninstallString) } |
        # Bundles (Burn/Package Cache) first: removing them usually removes their child MSIs too
        Sort-Object @{ Expression = { if ($_.QuietUninstallString -or $_.BundleCachePath -or $_.UninstallString -like '*Package Cache*') { 0 } else { 1 } } }

foreach ($app in $apps) {
    # Skip entries that a previous bundle uninstall already removed
    if (-not (Test-Path $app.PSPath)) { continue }

    Write-Host "Found: $($app.DisplayName)" -ForegroundColor Cyan
    $us = [string]$app.UninstallString

    # 1. Vendor-provided silent command (Burn bundles like Endpoint Analysis register one)
    if ($app.QuietUninstallString) {
        $exe, $argList = Split-CommandLine $app.QuietUninstallString
        Invoke-Uninstaller $exe $argList
    }
    # 2. MSI product
    elseif ($us -match '(?i)msiexec.*?/[XI]\s*(\{[0-9A-F-]+\})') {
        Invoke-Uninstaller 'msiexec.exe' "/x $($Matches[1]) /qn /norestart"
    }
    # 3. WiX Burn bundle without a QuietUninstallString (e.g. "...\Package Cache\{GUID}\setup.exe" /modify)
    elseif ($us -like '*\Package Cache\*' -or $app.BundleCachePath) {
        $exe, $null = Split-CommandLine $us
        Invoke-Uninstaller $exe '/uninstall /quiet /norestart'
    }
    # 4. Citrix Workspace app's own uninstaller
    elseif ($us -match '(?i)TrolleyExpress\.exe') {
        $exe, $null = Split-CommandLine $us
        Invoke-Uninstaller $exe '/uninstall /cleanup /silent'
    }
    # 5. Anything else: add /silent only if no quiet-style switch is already present
    else {
        $exe, $argList = Split-CommandLine $us
        if ($argList -notmatch '(?i)(^|\s)[/-](s|silent|quiet|q|qn|verysilent)(\s|$)') {
            $argList = "$argList /silent".Trim()
        }
        Invoke-Uninstaller $exe $argList
    }
}

Write-Host "Uninstallation loop complete." -ForegroundColor Green
