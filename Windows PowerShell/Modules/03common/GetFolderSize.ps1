<#
.SYNOPSIS
Get the size of folder and number of items (subfolders and files) in folder.
.DESCRIPTION
Get the size of folder and number of items (subfolders and files) in folder. 
List of servers is in txt file in 01servers folder or list of strings with names of computers.
CmdLet has two ParameterSets one for list of computers from file and another from list of strings as computer names.

Errors will be saved in log folder PSLogs with name Error_Log.txt. Parameter errorlog controls logging of errors in log file.

Get-FolderSize function uses Get-ChildItem PowerShell function to get size of folder and Invoke-Command to remotely connect to 
the servers and do the calculation.

Result shows following columns: Environment (PROD, Acceptance, Test, Course...), 
Logical Name (Application, web, integration, FTP, Scan, Terminal Server...), Server Name, 
Folder path, Size(MB), Items count, IP 

.PARAMETER computers
List of computers that we want to get Last bootup time from. Parameter belongs to default Parameter Set = ServerNames.
.PARAMETER filename
Name of txt file with list of servers that we want to check Last bootup time. .txt file should be in 01servers folder.
Parameter belongs to Parameter Set = FileName.
.PARAMETER path
Absolute folder path that we want to find size of.
.PARAMETER errorlog
Switch parameter that sets to write to log or not to write to log. Error file is in PSLog folder with name Error_Log.txt.
.PARAMETER client
OK - O client
BK - B client
etc.
.PARAMETER solution
FIN - Financial solution
HR - Human resource solution
etc.

.EXAMPLE
Get-FolderSize -path "C:\Windows\Microsoft.NET\Framework*\v*\Temporary ASP.NET Files" -client "OK" -solution "FIN"

Description
---------------------------------------
Test of default parameter with default value ( computers = 'localhost' ) in default ParameterSet = ServerName.

.EXAMPLE
Get-FolderSize -client "OK" -solution "FIN" -Verbose

Description
---------------------------------------
Test of Verbose parameter. NOTE: Notice how localhost default value of parameter computers replaces with name of server.

.EXAMPLE
'ERROR' | Get-FolderSize -client "OK" -solution "FIN" -errorlog

Description
---------------------------------------
Test of errorlog parameter. There is no server with name ERROR so this call will fail and write to Error log since errorlog switch parameter is on. Look Error_Log.txt file in PSLogs folder.

.EXAMPLE
Get-FolderSize -computers 'APP100001' -client "OK" -solution "FIN" -errorlog

Description
---------------------------------------
Test of computers parameter with one value. Parameter accepts array of strings.

.EXAMPLE
Get-FolderSize -computers 'APP100001', 'APP100002' -client "OK" -solution "FIN" -errorlog -Verbose

Description
---------------------------------------
Test of computers parameter with array of strings. Parameter accepts array of strings.

.EXAMPLE
Get-FolderSize -hosts 'APP100001' -client "OK" -solution "FIN" -errorlog

Description
---------------------------------------
Test of computers paramater alias hosts.

.EXAMPLE
Get-FolderSize -computers (Get-Content( "$home\Documents\WindowsPowerShell\Modules\01servers\OKFINservers.txt" )) -client "OK" -solution "FIN" -errorlog -Verbose

Description
---------------------------------------
Test of computers parameter and values for parameter comes from .txt file that has list of servers.

.EXAMPLE
'APP100001' | Get-FolderSize -client "OK" -solution "FIN" -errorlog

Description
---------------------------------------
Test of pipeline by value of computers parameter.

.EXAMPLE
'APP100001', 'APP100002' | Get-FolderSize -client "OK" -solution "FIN" -errorlog -Verbose

Description
---------------------------------------
Test of pipeline by value with array of strings of computers parameter.

.EXAMPLE
'APP100001', 'APP100002' | Select-Object @{label="computers";expression={$_}} | Get-FolderSize -client "OK" -solution "FIN" -errorlog

Description
---------------------------------------
Test of values from pipeline by property name (computers).

.EXAMPLE
Get-Content( "$home\Documents\WindowsPowerShell\Modules\01servers\OKFINservers.txt" ) | Get-FolderSize -client "OK" -solution "FIN" -errorlog -Verbose

Description
---------------------------------------
Test of pipeline by value that comes as content of .txt file with list of servers.

.EXAMPLE
Help Get-FolderSize -Full

Description
---------------------------------------
Test of Powershell help.

.EXAMPLE
Get-FolderSize -filename "OKFINservers.txt" -errorlog -client "OK" -solution "FIN" -Verbose

Description
---------------------------------------
This is test of ParameterSet = FileName and parameter filename. There is list of servers in .txt file.

.EXAMPLE
Get-FolderSize -file "OKFINserverss.txt" -errorlog -client "OK" -solution "FIN" -Verbose

Description
---------------------------------------
This is test of ParameterSet = FileName and parameter filename. This test will fail due to wrong name of the .txt file with warning message "WARNING: This file path does NOT exist:".

.INPUTS
System.String

Computers parameter pipeline both by Value and by Property Name value and has default value of localhost. (Parameter Set = ComputerNames)
Filename parameter does not pipeline and does not have default value. (Parameter Set = FileName)
.OUTPUTS
System.Management.Automation.PSCustomObject

Get-FolderSize returns PSCustomObjects
Result shows following columns: Environment (PROD, Acceptance, Test, Course...), 
Logical name (Application, web, integration, FTP, Scan, Terminal Server...), Server name, OS, LastBootUpTime, IP 

.NOTES
FunctionName : Get-FolderSize
Created by   : Dejan Mladenovic
Date Coded   : 10/19/2020 19:06:41
More info    : https://improvescripting.com/

.LINK 
https://improvescripting.com/get-folder-size-and-file-count-using-powershell-examples/
Get-ChildItem
Measure-Object
Invoke-Command
#>
Function Get-FolderSize {
[CmdletBinding(DefaultParametersetName="ServerNames")]
param (
    [Parameter( ValueFromPipeline=$true,
                ValueFromPipelineByPropertyName=$true,
                ParameterSetName="ServerNames",
                HelpMessage="List of computer names separated by commas.")]
    [Alias('hosts')] 
    [string[]]$computers = 'localhost',
    
    [Parameter( ParameterSetName="FileName",
                HelpMessage="Name of txt file with list of servers. Txt file should be in 01servers folder.")] 
    [string]$filename,
    
    [Parameter( Mandatory=$true,
                HelpMessage="Absolute folder path that we want to measure size of.")]
    [string]$path,
    
    [Parameter( Mandatory=$false,
                HelpMessage="Write to error log file or not.")]
    [switch]$errorlog,
    
    [Parameter(Mandatory=$true, 
                HelpMessage="Client for example OK = O client, BK = B client")]
    [string]$client,
     
    [Parameter(Mandatory=$true,
                HelpMessage="Solution, for example FIN = Financial, HR = Human Resource")]
    [string]$solution     
)

BEGIN {

    if ( $PsCmdlet.ParameterSetName -eq "FileName") {

        if ( Test-Path -Path "$home\Documents\WindowsPowerShell\Modules\01servers\$filename" -PathType Leaf ) {
            Write-Verbose "Read content from file: $filename"
            $computers = Get-Content( "$home\Documents\WindowsPowerShell\Modules\01servers\$filename" )        
        } else {
            Write-Warning "This file path does NOT exist: $home\Documents\WindowsPowerShell\Modules\01servers\$filename"
            Write-Warning "Create file $filename in folder $home\Documents\WindowsPowerShell\Modules\01servers with list of server names."
            break;
        }
       
    }

}

PROCESS {               

        foreach ($computer in $computers ) {
        
            if ( $computer -eq 'localhost' ) {
            $computer = $env:COMPUTERNAME
            }
            
            $computerinfo = Get-ComputerInfo -computername $computer -client $client -solution $solution
            $hostname = $computerinfo.hostname
            $env = $computerinfo.environment
            $logicalname = $computerinfo.logicalname
            $ip = $computerinfo.ipaddress
            
            try {
                Write-Verbose "Processing: $computer - $env - $logicalname"
                
                Write-Verbose "Start Invoke-Command processing..."
                
                $foldersize = $null
                $folderpath = $path
                Write-Verbose "Folder path: $folderpath"
                
                #$scriptblock = { param ($parampath) Get-ChildItem -Path $parampath -Recurse | Measure-Object -Property Length -Sum | Select-Object @{Name="Size(MB)";Expression={("{0:N2}" -f($_.Sum/1mb))}}, Count }

#IMPORTANT - DO NOT use formatting ("{0:N2}" -f($_.Sum/1mb)) of expression if you want to explicit convert to decimal data type. (see down in properties variable)                
                $scriptblock = { param ($parampath) Get-ChildItem -Path $parampath -Recurse -Force | 
                                    Measure-Object -Property Length -Sum | 
                                    Select-Object @{Name="Size(MB)";Expression={$_.Sum/1mb}}, Count }

                ##REPLACE THIS VALUE!!
                $EncryptedPasswordFile = "C:\Users\dekib\Documents\PSCredential\Invoke-Command.txt"
                ##REPLACE THIS VALUE!!
                $username="user_name" 
                $password = Get-Content -Path $EncryptedPasswordFile | ConvertTo-SecureString
                $Credentials = New-Object System.Management.Automation.PSCredential($username, $password)

                $params = @{ 'ComputerName'=$computer;
                             'ErrorAction'='Stop';
                             'ScriptBlock'=$scriptblock;
                             'Credential'=$Credentials;
                             'ArgumentList'=$path }

                $foldersize = Invoke-Command @params
                
                Write-Verbose "Finish Invoke-Command processing..."
                
                if ( $foldersize ) {

                    $properties = @{ 'Environment'=$env;
                                     'Logical name'=$logicalname;
                                     'Server name'=$computer;
                                     'Folder path'=$path;
                                     'Size(MB)'=[decimal]$foldersize."Size(MB)";
                                     'Items count'=[int]$foldersize.Count;
            	                     'IP'=$ip;
                                     'Collected'=(Get-Date -UFormat %Y.%m.%d' '%H:%M:%S)}

                    $obj = New-Object -TypeName PSObject -Property $properties
                    $obj.PSObject.TypeNames.Insert(0,'Report.FolderSize')

                    Write-Output $obj
                    
                }
                
                Write-Verbose "Finished processing: $computer - $env - $logicalname"
            
            } catch {
                Write-Warning "Computer failed: $computer - $env - $logicalname"
                Write-Warning "Error message: $_"

                if ( $errorlog ) {

                    $errormsg = $_.ToString()
                    $exception = $_.Exception
                    $stacktrace = $_.ScriptStackTrace
                    $failingline = $_.InvocationInfo.Line
                    $positionmsg = $_.InvocationInfo.PositionMessage
                    $pscommandpath = $_.InvocationInfo.PSCommandPath
                    $failinglinenumber = $_.InvocationInfo.ScriptLineNumber
                    $scriptname = $_.InvocationInfo.ScriptName

                    Write-Verbose "Start writing to Error log."
                    Write-ErrorLog -hostname $computer -env $env -logicalname $logicalname -errormsg $errormsg -exception $exception -scriptname $scriptname -failinglinenumber $failinglinenumber -failingline $failingline -pscommandpath $pscommandpath -positionmsg $pscommandpath -stacktrace $stacktrace
                    Write-Verbose "Finish writing to Error log."
                }
            }
        
        }        
}
END { 
}
}
#region Execution examples
#Get-FolderSize -filename "OKFINservers.txt" -path "C:\Temp" -errorlog -client "OK" -solution "FIN" | Select-Object 'Environment', 'Logical Name', 'Server Name', 'Folder path', 'Size(MB)', 'Items count', 'IP', 'Collected' | Out-GridView

#Get-FolderSize -filename "OKFINservers.txt" -path "C:\Windows\Microsoft.NET\Framework*\v*\Temporary ASP.NET Files" -errorlog -client "OK" -solution "FIN" -Verbose | Select-Object 'Environment', 'Logical Name', 'Server Name', 'Folder path', 'Size(MB)', 'Items count', 'IP', 'Collected' | Out-GridView

#Get-FolderSize -filename "OKFINservers.txt" -path "C:\Users\user_name\AppData\Local\Temp" -errorlog -client "OK" -solution "FIN" -Verbose | Select-Object 'Environment', 'Logical Name', 'Server Name', 'Folder path', 'Size(MB)', 'Items count', 'IP', 'Collected' | Out-GridView

<#
#Test ParameterSet = ServerName
Get-FolderSize -path "C:\Users\user_name\AppData\Local\Temp" -client "OK" -solution "FIN"
Get-FolderSize -path "C:\Users\user_name\AppData\Local\Temp" -client "OK" -solution "FIN" -errorlog
Get-FolderSize -path "C:\Users\user_name\AppData\Local\Temp" -client "OK" -solution "FIN" -errorlog -Verbose
Get-FolderSize -computers 'APP100001' -path "C:\Users\user_name\AppData\Local\Temp" -client "OK" -solution "FIN" -errorlog
Get-FolderSize -computers 'APP100001', 'APP100002' -path "C:\Users\user_name\AppData\Local\Temp" -client "OK" -solution "FIN" -errorlog -Verbose
Get-FolderSize -hosts 'APP100001' -path "C:\Users\user_name\AppData\Local\Temp" -client "OK" -solution "FIN" -errorlog
Get-FolderSize -computers (Get-Content( "$home\Documents\WindowsPowerShell\Modules\01servers\OKFINservers.txt" )) -path "C:\Users\user_name\AppData\Local\Temp" -client "OK" -solution "FIN" -errorlog -Verbose

#Pipeline examples
'APP100001' | Get-FolderSize -path "C:\Users\user_name\AppData\Local\Temp" -client "OK" -solution "FIN" -errorlog
'APP100001', 'APP100002' | Get-FolderSize -path "C:\Users\user_name\AppData\Local\Temp" -client "OK" -solution "FIN" -errorlog -Verbose
'APP100001', 'APP100002' | Select-Object @{label="computers";expression={$_}} | Get-FolderSize -path "C:\Users\user_name\AppData\Local\Temp" -client "OK" -solution "FIN" -errorlog
Get-Content( "$home\Documents\WindowsPowerShell\Modules\01servers\OKFINservers.txt" ) | Get-FolderSize -path "C:\Users\user_name\AppData\Local\Temp" -client "OK" -solution "FIN" -errorlog -Verbose
'ERROR' | Get-FolderSize -path "C:\Users\user_name\AppData\Local\Temp" -client "OK" -solution "FIN" -errorlog

#Test CmdLet help
Help Get-FolderSize -Full

#SaveToExcel
Get-FolderSize -filename "OKFINservers.txt" -path "C:\Temp" -errorlog -client "OK" -solution "FIN" -Verbose | Save-ToExcel -errorlog -ExcelFileName "Get-FolderSize_Temp" -title "Get folder size in Financial solution for " -author "Dejan Mladenovic" -WorkSheetName "User Temp Folder size" -client "OK" -solution "FIN" 
#SaveToExcel and send email
Get-FolderSize -filename "OKFINservers.txt" -path "C:\Temp" -errorlog -client "OK" -solution "FIN" -Verbose | Save-ToExcel -sendemail -errorlog -ExcelFileName "Get-FolderSize_Temp" -title "Get folder size in Financial solution for " -author "Dejan Mladenovic" -WorkSheetName "User Temp Folder size" -client "OK" -solution "FIN" 

#Test ParameterSet = FileName
Get-FolderSize -filename "OKFINservers.txt" -path "C:\Users\user_name\AppData\Local\Temp" -errorlog -client "OK" -solution "FIN" -Verbose
Get-FolderSize -filename "OKFINserverss.txt" -path "C:\Users\user_name\AppData\Local\Temp" -errorlog -client "OK" -solution "FIN" -Verbose
#>

#Get-FolderSize -filename "OKFINservers.txt" -path "C:\Windows\Microsoft.NET\Framework*\v*\Temporary ASP.NET Files" -errorlog -client "OK" -solution "FIN" -Verbose | Out-GridView

#Get-FolderSize -filename "OKFINservers.txt" -path "C:\Users\user_name\AppData\Local\Temp" -errorlog -client "OK" -solution "FIN" -Verbose | Out-GridView

#Get-FolderSize -filename "OKFINservers.txt" -path "C:\Windows\Microsoft.NET\Framework*\v*\Temporary ASP.NET Files" -errorlog -client "OK" -solution "FIN" -Verbose | Save-ToExcel -sendemail -errorlog -ExcelFileName "Get-FolderSize_ASP_Cache" -title "Get ASP cache size in Financial solution for " -author "Dejan Mladenovic" -WorkSheetName "ASP.NET cache size" -client "OK" -solution "FIN" 

#Get-FolderSize -filename "OKFINservers.txt" -path "C:\Users\user_name\AppData\Local\Temp" -errorlog -client "OK" -solution "FIN" -Verbose | Save-ToExcel -sendemail -errorlog -ExcelFileName "Get-FolderSize_Agresso_Temp" -title "Get Temp folder size in Financial solution for " -author "Dejan Mladenovic" -WorkSheetName "Temp folder size" -client "OK" -solution "FIN" 
#endregion