<#
.SYNOPSIS
Gets Printers info for list of servers.
.DESCRIPTION
Gets Printers info for list of servers. 
List of servers is in txt file in 01servers folder or list of strings with names of computers.
CmdLet has two ParameterSets one for list of computers from file and another from list of strings as computer names.

Errors will be saved in log folder PSLogs with name Error_Log.txt. Parameter errorlog controls logging of errors in log file.

Get-Printers function uses Get-CimInstance -Class Win32_Printer PowerShell function to get Printer info.

Result shows following columns: Environment (PROD, Acceptance, Test, Course...), 
LogicalName (Application, web, integration, FTP, Scan, Terminal Server...), Server name, 
Name , Location, Job count since last reset, Status, Printer status, Printer state, Detected error state, 
Extended detected error state, Extended printer status, Port name, Driver name, Network, Shared, 
Share name, Spool enabled, Work offline, Default, IP, Collected
                    
.PARAMETER computers
List of computers that we want to get Printer info from. Parameter belongs to default Parameter Set = ServerNames.
.PARAMETER filename
Name of txt file with list of servers that we want to check Printer info. .txt file should be in 01servers folder.
Parameter belongs to Parameter Set = FileName.
.PARAMETER status
Filter list of printers by status. Default value for status is Error. That means only show printers with Error status.
Other valid values are: All and Offline.
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
Get-Printers -client "OK" -solution "FIN"

Description
---------------------------------------
Test of default parameter with default value ( computers = 'localhost' ) in default ParameterSet = ServerName.

.EXAMPLE
Get-Printers -client "OK" -solution "FIN" -Verbose

Description
---------------------------------------
Test of Verbose parameter. NOTE: Notice how localhost default value of parameter computers replaces with name of server.

.EXAMPLE
'ERROR' | Get-Printers -client "OK" -solution "FIN" -errorlog

Description
---------------------------------------
Test of errorlog parameter. There is no server with name ERROR so this call will fail and write to Error log since errorlog switch parameter is on. Look Error_Log.txt file in PSLogs folder.

.EXAMPLE
Get-Printers -computers 'APP100001' -client "OK" -solution "FIN" -errorlog

Description
---------------------------------------
Test of computers parameter with one value. Parameter accepts array of strings.

.EXAMPLE
Get-Printers -computers 'APP100001', 'APP100002' -client "OK" -solution "FIN" -errorlog -Verbose

Description
---------------------------------------
Test of computers parameter with array of strings. Parameter accepts array of strings.

.EXAMPLE
Get-Printers -hosts 'APP100001' -client "OK" -solution "FIN" -errorlog

Description
---------------------------------------
Test of computers paramater alias hosts.

.EXAMPLE
Get-Printers -computers (Get-Content( "$home\Documents\WindowsPowerShell\Modules\01servers\OKFINservers.txt" )) -client "OK" -solution "FIN" -errorlog -Verbose

Description
---------------------------------------
Test of computers parameter and values for parameter comes from .txt file that has list of servers.

.EXAMPLE
'APP100001' | Get-Printers -client "OK" -solution "FIN" -errorlog

Description
---------------------------------------
Test of pipeline by value of computers parameter.

.EXAMPLE
'APP100001', 'APP100002' | Get-Printers -client "OK" -solution "FIN" -errorlog -Verbose

Description
---------------------------------------
Test of pipeline by value with array of strings of computers parameter.

.EXAMPLE
'APP100001', 'APP100002' | Select-Object @{label="computers";expression={$_}} | Get-Printers -client "OK" -solution "FIN" -errorlog

Description
---------------------------------------
Test of values from pipeline by property name (computers).

.EXAMPLE
Get-Content( "$home\Documents\WindowsPowerShell\Modules\01servers\OKFINservers.txt" ) | Get-Printers -client "OK" -solution "FIN" -errorlog -Verbose

Description
---------------------------------------
Test of pipeline by value that comes as content of .txt file with list of servers.

.EXAMPLE
Help Get-Printers -Full

Description
---------------------------------------
Test of Powershell help.

.EXAMPLE
Get-Printers -filename "OKFINservers.txt" -errorlog -client "OK" -solution "FIN" -Verbose

Description
---------------------------------------
This is test of ParameterSet = FileName and parameter filename. There is list of servers in .txt file.

.EXAMPLE
Get-Printers -filename "OKFINserverss.txt" -errorlog -client "OK" -solution "FIN" -Verbose

Description
---------------------------------------
This is test of ParameterSet = FileName and parameter filename. This test will fail due to wrong name of the .txt file with warning message "WARNING: This file path does NOT exist:".

.INPUTS
System.String

Computers parameter pipeline both by Value and by Property Name value and has default value of localhost. (Parameter Set = ComputerNames)
Filename parameter does not pipeline and does not have default value. (Parameter Set = FileName)
.OUTPUTS
System.Management.Automation.PSCustomObject

Get-Print returns PSCustomObjects which has been converted from PowerShell function Get-WmiObject -Class Win32_Printer
Result shows following columns: Environment (PROD, Acceptance, Test, Course...), 
LogicalName (Application, web, integration, FTP, Scan, Terminal Server...), Server name, 
Name , Location, Job count since last reset, Status, Printer status, Printer state, Detected error state, 
Extended detected error state, Extended printer status, Port name, Driver name, Network, Shared, 
Share name, Spool enabled, Work offline, Default, IP, Collected

.NOTES
FunctionName : Get-Printers
Created by   : Dejan Mladenovic
Date Coded   : 10/31/2018 19:06:41
More info    : https://improvescripting.com/

.LINK 
https://improvescripting.com/how-to-list-installed-printers-using-powershell
Get-CimInstance -Class Win32_Printer
#>
Function Get-Printers {
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
    
    [Parameter(Mandatory=$false,
                HelpMessage="Status of printer. Values (All, Offline, Error).")]
    [ValidateSet("All", "Offline", "Error")] 
    [string]$status = 'Error',
    
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
            Write-Verbose "Start processing: $computer - $env - $logicalname"
            Write-Verbose "Start Win32_Printer processing..."
            $Printers = $null
            $Printer = $null
            $obj = $null
            
            switch($status) {
                'All' {
                    
                    $params = @{ 'ComputerName'=$computer;
                         'Class'='Win32_Printer';
                         'ErrorAction'='Stop'}

                    $Printers = Get-CimInstance @params | 
                                    Select-Object DetectedErrorState, DriverName, ExtendedDetectedErrorState, ExtendedPrinterStatus, JobCountSinceLastReset, Location, Name, Network, PortName, PrinterState, 
                                    PrinterStatus, Shared, ShareName, SpoolEnabled, Status, SystemName, WorkOffline, Default;
                    break
                }
                'Offline' {

                    $params = @{ 'ComputerName'=$computer;
                         'Class'='Win32_Printer';
                         'ErrorAction'='Stop';
                         'Filter'= "ExtendedPrinterStatus='7'"}

                    $Printers = Get-CimInstance @params | 
                                    Select-Object DetectedErrorState, DriverName, ExtendedDetectedErrorState, ExtendedPrinterStatus, JobCountSinceLastReset, Location, Name, Network, PortName, PrinterState, 
                                    PrinterStatus, Shared, ShareName, SpoolEnabled, Status, SystemName, WorkOffline, Default;
                    break
                }
                default {
                    
                    $params = @{ 'ComputerName'=$computer;
                         'Class'='Win32_Printer';
                         'ErrorAction'='Stop';
                         'Filter'= "ExtendedPrinterStatus='9'"}
 
                    $Printers = Get-CimInstance @params | 
                                    Select-Object DetectedErrorState, DriverName, ExtendedDetectedErrorState, ExtendedPrinterStatus, JobCountSinceLastReset, Location, Name, Network, PortName, PrinterState, 
                                    PrinterStatus, Shared, ShareName, SpoolEnabled, Status, SystemName, WorkOffline, Default;
                }
            }
            
            Write-Verbose "Finish Win32_Printer processing..."
            
            if ($Printers) {
                foreach ($Printer in $Printers) {
                    Write-Verbose "Start processing Printer: $Printer"
                   
                    $properties = @{ 'Environment'=$env;
                                     'Logical name'=$logicalname;
                                     'Server name'=$Printer.SystemName;
            	                     'Name'=$Printer.Name;
                                     'Location'=$Printer.Location;
                                     'Job count since last reset'=$Printer.JobCountSinceLastReset;
                                     'Status'=$Printer.Status;
                                     'Printer status'=$Printer.PrinterStatus;
                                     'Printer state'=$Printer.PrinterState;
                                     'Detected error state'=$Printer.DetectedErrorState;
                                     'Extended detected error state'=$Printer.ExtendedDetectedErrorState;
                                     'Extended printer status'=$Printer.ExtendedPrinterStatus;
                                     'Port name'=$Printer.PortName;
                                     'Driver name'=$Printer.DriverName;
                                     'Network'=$Printer.Network;
                                     'Shared'=$Printer.Shared;
                                     'Share name'=$Printer.ShareName;
                                     'Spool enabled'=$Printer.SpoolEnabled;
                                     'Work offline'=$Printer.WorkOffline;
                                     'Default'=$Printer.Default;
                                     'IP'=$ip;
                                     'Collected'=(Get-Date -UFormat %Y.%m.%d' '%H:%M:%S)}
                
                    $obj = New-Object -TypeName PSObject -Property $properties
                    $obj.PSObject.TypeNames.Insert(0,'Report.Printers')

                    Write-Output $obj
                    Write-Verbose "Finish processing Printer: $Printer"
                }
            }
            
            Write-Verbose "Finish processing: $computer - $env - $logicalname"
            
        } catch {
            Write-Warning "Computer failed: $computer - $env - $logicalname Printer failed: $Printer"
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
#List only printers with errors
#Get-Printers -filename "OKFINservers.txt" -errorlog -client "OK" -solution "FIN" -Verbose | Select-Object 'Environment', 'Logical name', 'Server name', 'Name', 'Location', 'Job count since last reset', 'Status', 'Printer status', 'Printer state', 'Detected error state', 'Extended detected error state', 'Extended printer status', 'Port name', 'Driver name', 'Network', 'Shared', 'Share name', 'Spool enabled', 'Work offline', 'Default', 'IP', 'Collected' | Out-GridView

#List only offline printers
#Get-Printers -filename "OKFINservers.txt" -status "Offline" -errorlog -client "OK" -solution "FIN" -Verbose | Select-Object 'Environment', 'Logical name', 'Server name', 'Name', 'Location', 'Job count since last reset', 'Status', 'Printer status', 'Printer state', 'Detected error state', 'Extended detected error state', 'Extended printer status', 'Port name', 'Driver name', 'Network', 'Shared', 'Share name', 'Spool enabled', 'Work offline', 'Default', 'IP', 'Collected' | Out-GridView

#List all printers
#Get-Printers -filename "OKFINservers.txt" -status "All" -errorlog -client "OK" -solution "FIN" -Verbose | Select-Object 'Environment', 'Logical name', 'Server name', 'Name', 'Location', 'Job count since last reset', 'Status', 'Printer status', 'Printer state', 'Detected error state', 'Extended detected error state', 'Extended printer status', 'Port name', 'Driver name', 'Network', 'Shared', 'Share name', 'Spool enabled', 'Work offline', 'Default', 'IP', 'Collected' | Out-GridView

#Get-Printers -status "All" -errorlog -client "OK" -solution "FIN" -Verbose | Select-Object 'Environment', 'Logical name', 'Server name', 'Name', 'Location', 'Job count since last reset', 'Status', 'Printer status', 'Printer state', 'Detected error state', 'Extended detected error state', 'Extended printer status', 'Port name', 'Driver name', 'Network', 'Shared', 'Share name', 'Spool enabled', 'Work offline', 'Default', 'IP', 'Collected' | Out-GridView

<#
#Test ParameterSet = ServerName
Get-Printers -client "OK" -solution "FIN"
Get-Printers -client "OK" -solution "FIN" -errorlog
Get-Printers -client "OK" -solution "FIN" -errorlog -Verbose
Get-Printers -computers 'APP100001' -client "OK" -solution "FIN" -errorlog
Get-Printers -computers 'APP100001', 'APP100002' -client "OK" -solution "FIN" -errorlog -Verbose
Get-Printers -hosts 'APP100001' -client "OK" -solution "FIN" -errorlog
Get-Printers -computers (Get-Content( "$home\Documents\WindowsPowerShell\Modules\01servers\OKFINservers.txt" )) -client "OK" -solution "FIN" -errorlog -Verbose

#Pipeline examples
'APP100001' | Get-Printers -client "OK" -solution "FIN" -errorlog
'APP100001', 'APP100002' | Get-Printers -client "OK" -solution "FIN" -errorlog -Verbose
'APP100001', 'APP100002' | Select-Object @{label="computers";expression={$_}} | Get-Printers -client "OK" -solution "FIN" -errorlog
Get-Content( "$home\Documents\WindowsPowerShell\Modules\01servers\OKFINservers.txt" ) | Get-Printers -client "OK" -solution "FIN" -errorlog -Verbose
'ERROR' | Get-Printers -client "OK" -solution "FIN" -errorlog

#Test CmdLet help
Help Get-Printers -Full

#SaveToExcel
Get-Printers -filename "OKFINservers.txt" -errorlog -client "OK" -solution "FIN" -Verbose | Save-ToExcel -errorlog -ExcelFileName "Get-Printers" -title "Get printers info of servers in Financial solution for " -author "Dejan Mladenovic" -WorkSheetName "Printer Info" -client "OK" -solution "FIN" 
#SaveToExcel and send email
Get-Printers -filename "OKFINservers.txt" -errorlog -client "OK" -solution "FIN" -Verbose | Save-ToExcel -sendemail -errorlog -ExcelFileName "Get-Printers" -title "Get printers info of servers in Financial solution for " -author "Dejan Mladenovic" -WorkSheetName "Printer Info" -client "OK" -solution "FIN" 

#Benchmark
#Time = 122 sec; Total Items = 1118
Measure-BenchmarksCmdLet { Get-Printers -filename "OKFINservers.txt" -status "All" -errorlog -client "OK" -solution "FIN" -Verbose }
#Time = 117 sec; Total Items = 1118
Measure-BenchmarksCmdLet { Get-Printers -filename "OKFINservers.txt" -status "All" -errorlog -client "OK" -solution "FIN" }

#Baseline create
Get-Printers -filename "OKFINservers.txt" -status "All" -errorlog -client "OK" -solution "FIN" -Verbose | Save-Baseline -errorlog -BaselineFileName "Get-Printers" -client "OK" -solution "FIN" -Verbose
#Baseline archive and create new
Get-Printers -filename "OKFINservers.txt" -status "All" -errorlog -client "OK" -solution "FIN" -Verbose | Save-Baseline -archive -errorlog -BaselineFileName "Get-Printers"  -client "OK" -solution "FIN" -Verbose

#Test ParameterSet = FileName
Get-Printers -filename "OKFINservers.txt" -errorlog -client "OK" -solution "FIN" -Verbose
Get-Printers -filename "OKFINserverss.txt" -errorlog -client "OK" -solution "FIN" -Verbose
#>
#endregion 