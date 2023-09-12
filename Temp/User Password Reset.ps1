﻿#====================================================================
# Server AD User Account Tool version 1 / revision 2
# Created by Mark Tinder / Benjamin Steel Company, Inc.
# Change-date:  16 Feb 2017
# Go Navy! / Beat Army!
#====================================================================
# This script can be used to check status of a users active directory
# account, and can be used to reset a user's password.  This tool does
# not all the ability to Enable a disabled user account by default.
# Password reset functionality is also not available for disabled accounts.
# This is by design.  To allow account Enable, change the $disabledAD paramter
# to $true on line 155.
#
# This script assumes passwords expire in 90 days.  If you use a different
# password lifespan, please change the $PasswordLife variable on line 160.
#
# To function properly, PowerShell Execution Policy must be set to
# Unrestricted unless launching from a batch file with an ExecutionPolicy
# statement.  Recommend setting your ExecutionPolicy to RemoteSigned and 
# using the batch file to launch the script.  See below for  the batch file I use:
# @echo off
# Powershell.exe -sta -executionpolicy remotesigned -WindowStyle Hidden ".\ADPwordResetTool.ps1"
# pause
#
# Active Directory Users and Computers must be available under
# Administrative Tools (Control Panel) on the PC running this script.
# ADUC is installed by default on a domain controller, but can be
# installed on any PC by installing the Microsoft Remote Server
# Administrative Tool.  Note:  the download is OS specific.
# https://technet.microsoft.com/en-us/library/cc731209(v=ws.11).aspx
#
# User running this script must also have permissions to access and
# modify Active Directory.  Ref this "How-To" for delegation
# instructions:  https://community.spiceworks.com/how_to/1464-how-to-delegate-password-reset-permissions-for-your-it-staff
#====================================================================
# Special thanks to:
#   Aaron Winston (Spiceworks) - https://community.spiceworks.com/topic/1851390-5-powershell-tricks-every-sysadmin-should-know?source=topic&pos=15
#      for his write-up: "5 PowerShell tricks every SysAdmin should know".
#      Props to TFL and Martin9700 (fellow Spiceheads, and PowerShell gurus) for
#      assisting in that write-up.
#   Rob Dunn (Spicehead) - https://community.spiceworks.com/how_to/1464-how-to-delegate-password-reset-permissions-for-your-it-staff
#      for his write-up:  "How to delegate password reset permissions to your IT staff"
#   Stuart Barrett (aka Stubar / Spicehead) - https://community.spiceworks.com/scripts/show/573-aduc-update-utility
#      for his script "ADUC Update Utility".  I used this many times in
#      the past, before I became more versed in PowerShell.
#====================================================================
# Known Issues
# - None.
#====================================================================
# v1r0 - Initial release
# v1r1 - Modified function GetADUserData to use an array of strings for
#        the pipe to Select-Object (clean up the code).
#      - Added code to properly query the LockedOut status of an AD
#        account, allow for account Unlock, and refresh the display
#        after the account has been unlocked.
#      - Fixed issue where user data labels did not properly clear
#        after a bad user was given (failed to locate user).
#      - Modified code so password reset functionality was not enabled
#        for Disabled user accounts.
# v1r2 - Changed the background colors for the password entry text box
#        to better illustrate disabled status.
#      - Changed text for force password reset text box label to light
#        gray when disabled.
#      - Added ability to turn on the ability to Enable a disabled
#        AD account with the $disabledAD parameter.
#      - Reformatted year text for Last Logon and Last Invalid Attempt to
#        allow room for Enable button.
#=====================================================================

[void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
Add-Type -Assembly System.Windows.Forms

[xml]$XAML = @'
<Window x:Name="ADPwordReset"
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="AD Password Reset Tool" Height="360.000" Width="300.000" Foreground="#FF161ED4" Background="#FFF3EB93"
    FocusManager.FocusedElement="{Binding ElementName=UserNameTextBox}">
    <Grid Margin="0,0,0,-131">
    
    <Button Name="btnUnlock" Content="Unlock" VerticalAlignment="Top" HorizontalAlignment="right" Margin="0,215,90,0" Width="50" IsEnabled="False" ToolTip="Click to unlock user account." />
    <Button Name="btnEnable" Content="Enable" VerticalAlignment="Top" HorizontalAlignment="right" Margin="0,215,15,0" Width="50" IsEnabled="False" ToolTip="Click to unlock user account." />
    <Button Name="btnGetData" Content="Get Data" VerticalAlignment="Top" HorizontalAlignment="Left" Margin="20,295,0,0" Width="50" />
    <Button Name="btnReset" Content="Reset" VerticalAlignment="Top" HorizontalAlignment="Center" Margin="0,295,0,0" Width="50" IsEnabled="False" />
    <Button Name="btnExit" Content="Exit" VerticalAlignment="Top" HorizontalAlignment="right" Margin="0,295,20,0" Width="50" />
    
    <Label Name="toolVersionRevisionTxt" Content="Active Directory Password Reset Tool version 1.0 rev 2" HorizontalAlignment="Right" Margin="0,5,9,0" VerticalAlignment="Top" FontSize="8" Foreground="#FFFF8C00"/>
    <Label Name="creatorTxt" Content="created by Mark Tinder" HorizontalAlignment="Right" Margin="0,15,8,0" VerticalAlignment="Top" FontSize="8" Foreground="#FFFF8C00"/>
    <Label Name="UserNameLbl" Content="User:" VerticalAlignment="Top" HorizontalAlignment="Left" Margin="10,40,0,0" Foreground="Black" />
    <TextBox Name="UserNameTextBox" HorizontalAlignment="Left" Height="25" Margin="50,40,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="150" BorderBrush="Black" Background="White"/>
    
    <Border Name="UserDataBdr" BorderBrush="Red" BorderThickness="2" HorizontalAlignment="Left" Height="170" Margin="5,70,0,0" VerticalAlignment="Top" Width="275" CornerRadius="5"/>
    <Label Name="FullNameFieldLbl" Content="Name:" VerticalAlignment="Top" HorizontalAlignment="Left" Margin="10,70,0,0" Foreground="Black" />
    <Label Name="FullNameLbl" Content="" VerticalAlignment="Top" HorizontalAlignment="Left" Margin="50,70,0,0" Foreground="Blue" />
    <Label Name="ExtensionFieldLbl" Content="Ext:" VerticalAlignment="Top" HorizontalAlignment="Left" Margin="170,70,0,0" Foreground="Black" />
    <Label Name="ExtensionLbl" Content="" VerticalAlignment="Top" HorizontalAlignment="Left" Margin="195,70,0,0" Foreground="Blue" />
    <Label Name="UserIDFieldLbl" Content="UserID:" VerticalAlignment="Top" HorizontalAlignment="Left" Margin="10,90,0,0" Foreground="Black" />
    <Label Name="UserIDLbl" Content="" VerticalAlignment="Top" HorizontalAlignment="Left" Margin="55,90,0,0" Foreground="Blue" />
    <Label Name="BranchFieldLbl" Content="Branch:" VerticalAlignment="Top" HorizontalAlignment="Left" Margin="10,110,0,0" Foreground="Black" />
    <Label Name="BranchLbl" Content="" VerticalAlignment="Top" HorizontalAlignment="Left" Margin="55,110,0,0" Foreground="Blue" />
    <Label Name="DeptFieldLbl" Content="Dept:" VerticalAlignment="Top" HorizontalAlignment="Left" Margin="135,110,0,0" Foreground="Black" />
    <Label Name="DeptLbl" Content="" VerticalAlignment="Top" HorizontalAlignment="Left" Margin="170,110,0,0" Foreground="Blue" />
    <Label Name="TitleFieldLbl" Content="Title:" VerticalAlignment="Top" HorizontalAlignment="Left" Margin="10,130,0,0" Foreground="Black" />
    <Label Name="TitleLbl" Content="" VerticalAlignment="Top" HorizontalAlignment="Left" Margin="40,130,0,0" Foreground="Blue" />
    <Ellipse Name="ExpiredStpLt" VerticalAlignment="Top" HorizontalAlignment="Left" Margin="15,155,0,0" Fill="LightGray" Height="15" Width="15" StrokeThickness="2" Stroke="Black" ToolTip="User's password has expired." />
    <Label Name="ExpiredLbl" Content="Expired" VerticalAlignment="Top" HorizontalAlignment="Left" Margin="30,150,0,0" Foreground="LightGray" />
    <Label Name="ResetCountFieldLbl" Content="Next Reset:" VerticalAlignment="Top" HorizontalAlignment="Left" Margin="135,150,0,0" Foreground="Black" />
    <Label Name="ResetCountLbl" Content="0" VerticalAlignment="Top" HorizontalAlignment="Left" Margin="205,150,0,0" Foreground="Blue" />
    <Label Name="ResetCountUnitsLbl" Content="Days" VerticalAlignment="Top" HorizontalAlignment="Left" Margin="225,150,0,0" Foreground="Black" />
    <Label Name="LastFailedLogonFieldLbl" Content="Last Failed Logon:" VerticalAlignment="Top" HorizontalAlignment="Left" Margin="10,170,0,0" Foreground="Black" />
    <Label Name="LastFailedLogonLbl" Content="" VerticalAlignment="Top" HorizontalAlignment="Left" Margin="110,170,0,0" Foreground="Blue" />
    <Label Name="FailedAttemptsFieldLbl" Content="Failed Attempts:" VerticalAlignment="Top" HorizontalAlignment="Left" Margin="10,190,0,0" Foreground="Black" />
    <Label Name="FailedAttemptsLbl" Content="0" VerticalAlignment="Top" HorizontalAlignment="Left" Margin="100,190,0,0" Foreground="Blue" />
    <Label Name="LockedLbl" Content=" Locked" VerticalAlignment="Top" HorizontalAlignment="Left" Margin="140,190,0,0" Foreground="LightGray" />
    <Ellipse Name="EnabledStpLt" VerticalAlignment="Top" HorizontalAlignment="Left" Margin="205,195,0,0" Fill="LightGray" Height="15" Width="15" StrokeThickness="2" Stroke="Black" ToolTip="User account has been disabled." />
    <Label Name="EnabledLbl" Content="Disabled" VerticalAlignment="Top" HorizontalAlignment="Left" Margin="220,190,0,0" Foreground="LightGray" />
    <Label Name="LastLogonFieldLbl" Content="Last Logon:" VerticalAlignment="Top" HorizontalAlignment="Left" Margin="10,210,0,0" Foreground="Black" />
    <Label Name="LastLogonLbl" Content="" VerticalAlignment="Top" HorizontalAlignment="Left" Margin="75,210,0,0" Foreground="Blue" />
    
    <Label Name="NewPasswordLbl" Content="New Password:" VerticalAlignment="Top" HorizontalAlignment="Left" Margin="10,245,0,0" Foreground="Black" />
    <TextBox Name="NewPasswordTextBox" HorizontalAlignment="Left" Height="25" Margin="105,245,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="150" BorderBrush="Black" Background="DarkGray" IsEnabled="False" />
    
    <CheckBox Name="ForceChangeCheckbox" Content="Force change at next logon" IsEnabled="False" Margin="115,275,0,0" HorizontalAlignment="Left" VerticalAlignment="Top" Foreground="LightGray" ToolTip="Check this box to force user to change their password at next logon." />

    </Grid>
</Window>
'@

# Read XAML
$reader=(New-Object System.Xml.XmlNodeReader $xaml)
try{$Form=[Windows.Markup.XamlReader]::Load($reader)}
catch{Write-Host "Unable to load Windows.Markup.XamlReader.  Some possible causes for this problem include:  .NET Framework is missing.  PowerShell must be launched with PowerShell -sta. Invalid XAML code was encournted.":exit}

#============================================
# Store From Objects in PowerShell
#============================================
$xaml.SelectNodes("//*[@Name]") | %{Set-Variable -Name ($_.Name) -Value $Form.FindName($_.Name)}

#============================================
# Add events to Form Objects
#============================================
$btnUnlock.Add_Click({UnlockADAccount})
$btnEnable.Add_Click({EnableADAccount})
$btnGetData.Add_Click({GetADUserData})
$btnReset.Add_Click({SetADPassword})
$btnExit.Add_Click({$Form.Close()})
$UserNameTextBox.Add_KeyDown({if ($Args[1].key -eq 'Return') {GetADUserData}})

#============================================
# Global Parameters
#============================================
[string] $global:targetUser = ""
[array] $global:UserData = @()
[boolean] $global:forceReset = $false
[boolean] $global:disabledAD = $false
[array] $global:UserFieldLbls = @($FullNameLbl,$ExtensionLbl,$UserIDLbl,$EnabledLbl,$BranchLbl,$DeptLbl,
                                $TitleLbl,$ExpiredLbl,$ResetCountLbl,$LastFailedLogonLbl,$FailedAttemptsLbl,
                                $LockedLbl,$LastLogonLbl)
[array] $global:StopLgts = @($EnabledStpLt,$ExpiredStpLt)
[int] $global:PasswordLife = 90

#============================================
# Reset Focus Function - reset's focus to User Name text box 
#============================================
function Reset-Focus {
    $UserNameTextBox.Focus()
    $UserNameTextBox.SelectAll()
    
    Return
}

#============================================
# Reset form Function - reset's the form to starting defaults 
#============================================
function Reset-Form {
    # blank all the user data labels
    ForEach ($label in $UserFieldLbls) {
        $label.Content = ""
    }

    # reset all the stoplights to default
    ForEach ($light in $StopLgts) {
        $light.Fill = "LightGray"
    }

    # disable reset functions
    $btnReset.IsEnabled = $false
    $ForceChangeCheckbox.IsEnabled = $false
    $ForceChangeCheckbox.Foreground = "LightGray"
    $NewPasswordTextBox.IsEnabled = $false
    $NewPasswordTextBox.Background = "DarkGray"
    
    Return
}

#============================================
# Unlock AD account function
#============================================

Function UnlockADAccount {
    $user = $targetUser
    Unlock-ADAccount -Identity $user

    GetADUserData
}

#============================================
# Enable AD account function
#============================================

Function EnableADAccount {
    $user = $targetUser
    Enable-ADAccount -Identity $user

    GetADUserData
}

#============================================
# reset form after password reset and unable
# force change at next logon
#============================================
Function UnableToForce {
    # send the pop-up
    $wshell = New-Object -ComObject Wscript.Shell
    $wshell.Popup("This password does not expire.  Unable to force change at next logon.",0,"Done!",0x0)
    
    $NewPasswordTextBox.Text = ""
    $ForceChangeCheckbox.IsChecked = $false
    $ForceChangeCheckbox.IsEnabled = $false

    Return
}

#============================================
# reset form after password reset
#============================================
Function PasswordSet {
    # send the pop-up
    $wshell = New-Object -ComObject Wscript.Shell
    $wshell.Popup("Password reset.",0,"Done!",0x0)
    
    $NewPasswordTextBox.Text = ""
    $ForceChangeCheckbox.IsChecked = $false

    Return
}

#============================================
# reset AD user account password
#============================================

Function SetADPassword {
    $password = $NewPasswordTextBox.Text.ToString()
    
    Set-ADAccountPassword -Identity $targetUser -Reset -NewPassword (ConvertTo-SecureString -AsPlainText $password -Force)
    
    If ($($ForceChangeCheckbox.IsChecked))
    {
        Set-ADUser -Identity $targetUser -ChangePasswordAtLogon $true
    } Else
    {
        Set-ADUser -Identity $targetUser -ChangePasswordAtLogon $false
    }

    If ($($userData.PasswordNeverExpires))
    {
        UnableToForce
    } Else
    {
        PasswordSet
    }

    Reset-Focus

    Return
}

#============================================
# reset form if bad or no username
#============================================
Function NoUser {
    
    Reset-Form

    # send the pop-up
    $wshell = New-Object -ComObject Wscript.Shell
    $wshell.Popup("Could not find user: $targetUser.",0,"Oops!",0x0)
    
    Return
}

#============================================
# Output AD user data to Form
#============================================
Function FormatUserData {
    # local function parameter reset
    $lastLogon = ""
    $lastFail = ""
    $expiresOn = ""
    $resetDays = 0

    # Password day and date calculations
    $lastLogon = '{0:dd-MMM-yy}' -f $($UserData.LastLogonDate)
    $lastFail = '{0:dd-MMM-yy  /  HH:mm}' -f $($UserData.LastBadPasswordAttempt)
    $today = Get-Date # today's date
    $expiresOn = $($UserData.PasswordLastSet).AddDays($PasswordLife)
    $resetDays = $($expiresOn - $today).Days

    # Fill-in-the-Blanks
    $FullNameLbl.Content = $UserData.Name
    $ExtensionLbl.Content = $UserData.telephoneNumber
    $UserIDLbl.Content = $UserData.SamAccountName
    $BranchLbl.Content = $UserData.City
    $DeptLbl.Content = $UserData.Department
    $TitleLbl.Content = $UserData.Title
    $LastLogonLbl.Content = $lastLogon
    $LastFailedLogonLbl.Content = $lastFail
    $FailedAttemptsLbl = $UserData.badPwdCount
    
    # Color-coding the Output and allow for password reset
    if ($($UserData.Enabled))
    {
        $EnabledStpLt.Fill = "Green"
        $EnabledLbl.Content = "Enabled"
        $EnabledLbl.Foreground = "Green"
        If ($disabledAD)
        {
            $btnEnable.IsEnabled = $false
        } Else
        {
            Out-Null
        }
        
        # enable reset functions
        $btnReset.IsEnabled = $true
        $ForceChangeCheckbox.IsEnabled = $true
        $ForceChangeCheckbox.Foreground = "Black"
        $NewPasswordTextBox.IsEnabled = $true
        $NewPasswordTextBox.Background = "White"

    } Else
    {
        $EnabledStpLt.Fill = "Red"
        $EnabledLbl.Content = "Disabled"
        $EnabledLbl.Foreground = "Red"
        If ($disabledAD)
        {
            $btnEnable.IsEnabled = $true
        } Else
        {
            Out-Null
        }
        
        # disable reset functions
        $btnReset.IsEnabled = $false
        $ForceChangeCheckbox.IsEnabled = $false
        $ForceChangeCheckbox.Foreground = "LightGray"
        $NewPasswordTextBox.IsEnabled = $false
        $NewPasswordTextBox.Background = "DarkGray"
    }

    If ($($UserData.PasswordNeverExpires))
    {
        $resetDaysColor = "Green"
        $ExpiredStpLt.Fill = "Orange"
        $resetDays = 0
        $ExpiredLbl.Content = "Never Expires"
        $ExpiredLbl.Foreground = "Orange"
        $ExpiredStpLt.ToolTip = "This password never expires.  Not best practice..."
    } Else
    {   
        $resetDaysColor = Switch ($resetDays) {
            {$_ -lt 0} {"Red"}
            {$_ -ge 0 -and $_ -le 4} {"Red"}
            {$_ -ge 5 -and $_ -le 14} {"Orange"}
            {$_ -ge 15} {"Green"}
        }
        $ExpiredLbl.Foreground = $resetDaysColor
        $ExpiredStpLt.Fill = $resetDaysColor
        
        If ($resetDays -le 0)
        {
            $ExpiredLbl.Content = "Expired"
            $resetDays = 0
            $ExpiredStpLt.ToolTip = "This password has expired."
        } Else
        {
            $ExpiredLbl.Content = "Not Expired"
            $ExpiredStpLt.ToolTip = "This password is still good."
        }
    }

    If ($($userData.LockedOut))
    {
        $LockedLbl.Content = "Locked"
        $LockedLbl.Foreground = "Red"
        $btnUnlock.IsEnabled = $true
    } Else
    {
        $LockedLbl.Content = "Unlocked"
        $LockedLbl.Foreground = "Green"
        $btnUnlock.IsEnabled = $false
    }

    $ResetCountLbl.Content = $resetDays
    $ResetCountLbl.Foreground = $resetDaysColor

}

#============================================
# get AD user data
#============================================

Function GetADUserData {
    # Parameters
    $global:targetUser = $UserNameTextBox.Text.ToString()
    $global:UserData = @()
    $userProperties = @("Name","SamAccountName","Enabled","Title","telephoneNumber","badPwdCount",
                        "City","Department","LastBadPasswordAttempt","LastLogonDate","PasswordExpired",
                        "PasswordLastSet","PasswordNeverExpires","LockedOut")
    
    # Pull Active Directory user data
    $global:UserData = Get-ADUser -Identity $targetUser -Properties * | Select $userProperties
    
    If ($($UserData.Length) -gt 0)
    {
        FormatUserData
    } Else
    {
        NoUser
    }
    
    Reset-Focus

    Return
}

#============================================
# Shows the form
#============================================
$Form.ShowDialog() | out-null