# 1. Define the application search pattern
$appNamePattern = "*Citrix*"

# 2. Gather matching registry entries from both 32-bit and 64-bit paths
$installedApps = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*, 
                                   HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*,
                                   HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* -ErrorAction SilentlyContinue | 
                 Where-Object { $_.DisplayName -like $appNamePattern -and $_.UninstallString }

# 3. Loop through each discovered item and trigger the uninstaller
foreach ($app in $installedApps) {
    Write-Host "Found: $($app.DisplayName)" -ForegroundColor Cyan
    $uninstallString = $app.UninstallString
    
    # Check if the uninstaller uses MSIexec
    if ($uninstallString -match 'msiexec.*\/X\s*(\{[\w-]+\})' -or $uninstallString -match 'msiexec.*\/I\s*(\{[\w-]+\})') {
        $guid = $Matches[1]
        Write-Host "Uninstalling via MSI Product Code: $guid" -ForegroundColor Yellow
        # Launch msiexec with silent (/qn) and no-restart parameters, then wait for completion
        Start-Process "msiexec.exe" -ArgumentList "/x $guid /qn /norestart" -Wait -NoNewWindow
    }
    # Handle standard EXE uninstall strings (like a native uninstaller.exe)
    else {
        Write-Host "Uninstalling via native string: $uninstallString" -ForegroundColor Yellow
        
        # Parse the executable path and arguments securely
        if ($uninstallString -match '^"([^"]+)"\s*(.*)$') {
            $exePath = $Matches[1]
            $arguments = $Matches[2]
        } else {
            $parts = $uninstallString -split ' ', 2
            $exePath = $parts[0]
            $arguments = $parts[1]
        }
        
        # Append silent flag if it looks like an executable that supports it
        if ($arguments -notmatch '/silent' -and $arguments -notmatch '/s') {
            $arguments += " /silent"
        }
        
        Start-Process -FilePath $exePath -ArgumentList $arguments -Wait -NoNewWindow -ErrorAction SilentlyContinue
    }
}
Write-Host "Uninstallation loop complete." -ForegroundColor Green
