# List Installed Softwares #

Get-WmiObject -Class Win32_Product | Select-Object -Property Name

# ------------------------------------------------------------------------------------- #

#Remote PowerShell# 
Enable-PSRemoting
Enter-PSSession -ComputerName dc01 -Credential $Cred

# ------------------------------------------------------------------------------------- #

# Remote Access Testing #
Get-Process | Get-Member

# ------------------------------------------------------------------------------------- #

# Uninstall Softwares #

$SQLVer = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object { $_.DisplayName -match "Microsoft SQL Server Management Studio" } | Select-Object -Property DisplayName, UninstallString

ForEach ($ver in $SQLVer) {

    If ($ver.UninstallString) {

        $uninst = $ver.UninstallString
        Start-Process cmd -ArgumentList "/c $uninst /quiet /norestart" -NoNewWindow
        
    }

}

# ------------------------------------------------------------------------------------- #