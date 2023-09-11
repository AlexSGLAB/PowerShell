<#
.SYNOPSIS
Test server connection with ping.
.DESCRIPTION
Test server connection with ping.
List of servers is in txt file in 01servers folder or list of strings with names of computers.
CmdLet has two ParameterSets one for list of computers from file and another from list of strings as computer names.

Errors will be saved in log folder PSLogs with name Error_Log.txt. Parameter errorlog controls logging of errors in log file.

Test-ServerConnection function uses Test-Connection PowerShell function to get connectiont to servers info.

Result shows following columns: Environment (PROD, Acceptance, Test, Course...), 
Logical Name (Application, web, integration, FTP, Scan, Terminal Server...), Server name, Status, IP

.PARAMETER computers
List of computers that we want to get connection status from. Parameter belongs to default Parameter Set = ServerNames.
.PARAMETER filename
Name of txt file with list of servers that we want to check connection status. .txt file should be in 01servers folder.
Parameter belongs to Parameter Set = FileName.
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
Test-ServerConnection -client "OK" -solution "FIN"

Description
---------------------------------------
Test of default parameter with default value ( computers = 'localhost' ) in default ParameterSet = ServerName.

.EXAMPLE
Test-ServerConnection -client "OK" -solution "FIN" -Verbose

Description
---------------------------------------
Test of Verbose parameter. NOTE: Notice how localhost default value of parameter computers replaces with name of server.

.EXAMPLE
'ERROR' | Test-ServerConnection -client "OK" -solution "FIN" -errorlog

Description
---------------------------------------
Test of errorlog parameter. There is no server with name ERROR so this call will fail and write to Error log since errorlog switch parameter is on. Look Error_Log.txt file in PSLogs folder.

.EXAMPLE
Test-ServerConnection -computers 'APP100001' -client "OK" -solution "FIN" -errorlog

Description
---------------------------------------
Test of computers parameter with one value. Parameter accepts array of strings.

.EXAMPLE
Test-ServerConnection -computers 'APP100001', 'APP100002' -client "OK" -solution "FIN" -errorlog -Verbose

Description
---------------------------------------
Test of computers parameter with array of strings. Parameter accepts array of strings.

.EXAMPLE
Test-ServerConnection -hosts 'APP100001' -client "OK" -solution "FIN" -errorlog

Description
---------------------------------------
Test of computers paramater alias hosts.

.EXAMPLE
Test-ServerConnection -computers (Get-Content( "$home\Documents\WindowsPowerShell\Modules\01servers\OKFINservers.txt" )) -client "OK" -solution "FIN" -errorlog -Verbose

Description
---------------------------------------
Test of computers parameter and values for parameter comes from .txt file that has list of servers.

.EXAMPLE
'APP100001' | Test-ServerConnection -client "OK" -solution "FIN" -errorlog

Description
---------------------------------------
Test of pipeline by value of computers parameter.

.EXAMPLE
'APP100001', 'APP100002' | Test-ServerConnection -client "OK" -solution "FIN" -errorlog -Verbose

Description
---------------------------------------
Test of pipeline by value with array of strings of computers parameter.

.EXAMPLE
'APP100001', 'APP100002' | Select-Object @{label="computers";expression={$_}} | Test-ServerConnection -client "OK" -solution "FIN" -errorlog

Description
---------------------------------------
Test of values from pipeline by property name (computers).

.EXAMPLE
Get-Content( "$home\Documents\WindowsPowerShell\Modules\01servers\OKFINservers.txt" ) | Test-ServerConnection -client "OK" -solution "FIN" -errorlog -Verbose

Description
---------------------------------------
Test of pipeline by value that comes as content of .txt file with list of servers.

.EXAMPLE
Help Test-ServerConnection -Full

Description
---------------------------------------
Test of Powershell help.

.EXAMPLE
Test-ServerConnection -filename "OKFINservers.txt" -errorlog -client "OK" -solution "FIN" -Verbose

Description
---------------------------------------
This is test of ParameterSet = FileName and parameter filename. There is list of servers in .txt file.

.EXAMPLE
Test-ServerConnection -filename "OKFINserverss.txt" -errorlog -client "OK" -solution "FIN" -Verbose

Description
---------------------------------------
This is test of ParameterSet = FileName and parameter filename. This test will fail due to wrong name of the .txt file with warning message "WARNING: This file path does NOT exist:".

.INPUTS
System.String

Computers parameter pipeline both by Value and by Property Name value and has default value of localhost. (Parameter Set = ComputerNames)
Filename parameter does not pipeline and does not have default value. (Parameter Set = FileName)
.OUTPUTS
System.Management.Automation.PSCustomObject

Test-ServerConnection returns PSCustomObjects which has been converted from PowerShell function Test-Connection
Result shows following columns: Environment (PROD, Acceptance, Test, Course...), 
Logical name (Application, web, integration, FTP, Scan, Terminal Server...), Server name, Status, IP, Collected

.NOTES
FunctionName : Test-ServerConnection
Created by   : Dejan Mladenovic
Date Coded   : 10/31/2018 19:06:41
More info    : https://improvescripting.com/

.LINK 
https://improvescripting.com/how-to-ping-servers-using-powershell
Test-Connection
#>
Function Test-ServerConnection {
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
            Write-Verbose "Replace localhost with real name of the server."
        }

        $computerinfo = Get-ComputerInfo -computername $computer -client $client -solution $solution
        $hostname = $computerinfo.hostname
        $env = $computerinfo.environment
        $logicalname = $computerinfo.logicalname
        $ip = $computerinfo.ipaddress
        
        try {
            Write-Verbose "Start processing: $computer - $env - $logicalname"
            $TestConnections = $null

            $params = @{ 'ComputerName'=$computer;
                         'ErrorAction'='Stop';
                         'Count'='1'}
            
            $TestConnections = Test-Connection @params -Quiet

            Write-Verbose "Finish Test-Connection processing..."
          
            $Status = $null

            if ( $TestConnections ) {
                
                $Status = "Connected"

                Write-Verbose "Computer $computer - connected"
            
            } else {
                
                $Status = "NOT Connected"
                
                Write-Verbose "Computer $computer - NOT connected"
            }

            $properties = @{ 'Environment'=$env;
                             'Logical name'=$logicalname;
                             'Server name'=$computer;
            	             'Status'=$Status;
                             'IP'=$ip;
                             'Collected'=(Get-Date -UFormat %Y.%m.%d' '%H:%M:%S)}
            
            $obj = New-Object -TypeName PSObject -Property $properties
            $obj.PSObject.TypeNames.Insert(0,'Report.TestServerConnection')

            Write-Output $obj

            Write-Verbose "Finish processing: $computer - $env - $logicalname"
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
#Test-ServerConnection -filename "OKFINservers.txt" -errorlog -client "OK" -solution "FIN" -Verbose | Select-Object 'Environment', 'Logical Name', 'Server Name', Status, IP, Collected | Out-GridView

<#
#Test ParameterSet = ServerName
Test-ServerConnection -client "OK" -solution "FIN"
Test-ServerConnection -client "OK" -solution "FIN" -errorlog
Test-ServerConnection -client "OK" -solution "FIN" -errorlog -Verbose
Test-ServerConnection -computers 'APP100001' -client "OK" -solution "FIN" -errorlog
Test-ServerConnection -computers 'APP100001', 'APP100002' -client "OK" -solution "FIN" -errorlog -Verbose
Test-ServerConnection -hosts 'APP100001' -client "OK" -solution "FIN" -errorlog
Test-ServerConnection -computers (Get-Content( "$home\Documents\WindowsPowerShell\Modules\01servers\OKFINservers.txt" )) -client "OK" -solution "FIN" -errorlog -Verbose

#Pipeline examples
'APP100001' | Test-ServerConnection -client "OK" -solution "FIN" -errorlog
'APP100001', 'APP100002' | Test-ServerConnection -client "OK" -solution "FIN" -errorlog -Verbose
'APP100001', 'APP100002' | Select-Object @{label="computers";expression={$_}} | Test-ServerConnection -client "OK" -solution "FIN" -errorlog
Get-Content( "$home\Documents\WindowsPowerShell\Modules\01servers\OKFINservers.txt" ) | Test-ServerConnection -client "OK" -solution "FIN" -errorlog -Verbose
'ERROR' | Test-ServerConnection -client "OK" -solution "FIN" -errorlog

#Test CmdLet help
Help Test-ServerConnection -Full

#SaveToExcel
Test-ServerConnection -filename "OKFINservers.txt" -errorlog -client "OK" -solution "FIN" -Verbose | Save-ToExcel -errorlog -ExcelFileName "Test-ServerConnection" -title "Get connection to servers info of servers in Financial solution for " -author "Dejan Mladenovic" -WorkSheetName "Connection to servers info" -client "OK" -solution "FIN" 
#SaveToExcel and send email
Test-ServerConnection -filename "OKFINservers.txt" -errorlog -client "OK" -solution "FIN" -Verbose | Save-ToExcel -sendemail -errorlog -ExcelFileName "Test-ServerConnection" -title "Get connection to servers info of servers in Financial solution for " -author "Dejan Mladenovic" -WorkSheetName "Connection to servers info" -client "OK" -solution "FIN" 

#Benchmark
#Time = 52; Total Items = 46
Measure-BenchmarksCmdLet { Test-ServerConnection -filename "OKFINservers.txt" -errorlog -client "OK" -solution "FIN" -Verbose }
#Time = 52 sec; Total Items = 46
Measure-BenchmarksCmdLet { Test-ServerConnection -filename "OKFINservers.txt" -errorlog -client "OK" -solution "FIN" }

#Test ParameterSet = FileName
Test-ServerConnection -filename "OKFINservers.txt" -errorlog -client "OK" -solution "FIN" -Verbose
Test-ServerConnection -filename "OKFINserverss.txt" -errorlog -client "OK" -solution "FIN" -Verbose
#>
#endregion