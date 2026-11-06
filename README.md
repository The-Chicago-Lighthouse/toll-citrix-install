# toll-citrix-install
 Used to configure tollway remote employee laptops/computers
 Run the following in elavated mode [run as administrator] on the command prompt:
```
cd c:\ && mkdir tolltemp && cd tolltemp && curl -L -o main.zip https://github.com/The-Chicago-Lighthouse/toll-citrix-install/archive/refs/heads/main.zip && for %i in (main.zip) do tar -xf "%i" && cd toll-citrix-install-main && curl -L -o CitrixWorkspaceAppCLH.exe https://github.com/The-Chicago-Lighthouse/toll-citrix-install/raw/refs/heads/main/CitrixWorkspaceApp.exe?download=CitrixWorkspaceApp.exe && powershell && .\Citrix_Uninstaller.ps1 && cmd && main.bat

```

or

Run the following in elavated mode [run as administrator] in PowerShell:
```
Set-Location C:\
New-Item -ItemType Directory -Force -Path tolltemp | Out-Null
Set-Location tolltemp
Invoke-WebRequest -Uri "https://github.com/The-Chicago-Lighthouse/toll-citrix-install/archive/refs/heads/main.zip" -OutFile "main.zip"
Expand-Archive -Path "main.zip" -DestinationPath .
Set-Location "toll-citrix-install-main"
Start-BitsTransfer -Source "https://github.com/The-Chicago-Lighthouse/toll-citrix-install/raw/refs/heads/main/CitrixWorkspaceApp.exe?download=CitrixWorkspaceApp.exe" -Destination "CitrixWorkspaceAppCLH.exe"
.\Citrix_Uninstaller.ps1
Start-Process ".\main.bat"

```
 Best,

 Esmeil Naqeeb
 Network Security Engineer
 The Chicago Lighthouse
 Email: Esmeil.Naqeeb@chicagolighthouse.org