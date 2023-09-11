Function Get-AllWindowsServices {
<#
.SYNOPSIS
Gets list of all windows services from list of servers.
.DESCRIPTION
Gets list of all windows services from list of servers.
List of servers is in txt file in 01servers folder or list of strings with names of computers.
CmdLet has two ParameterSets one for list of computers from file and another from list of strings as computer names.

Errors will be saved in log folder PSLogs with name Error_Log.txt. Parameter errorlog controls logging of errors in log file.

Get-AllWindowsServices function uses Get-WmiObject -Class Win32_Service PowerShell function to get Windows services info.

Result shows following columns: Environment (PROD, Acceptance, Test, Course...), 
Logical Name (Application, web, integration, FTP, Scan, Terminal Server...), Server Name, Service name, Status, 
Start mode, Started, Process Id, Start name, Caption, Description, Display name, Accept pause, Accept stop, Path name, IP, Collected.
.PARAMETER computers
List of computers that we want to get All windows services info from. Parameter belongs to default Parameter Set = ServerNames.
.PARAMETER filename
Name of txt file with list of servers that we want to get list of all windows services. .txt file should be in 01servers folder.
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
Get-AllWindowsServices -client "OK" -solution "FIN"

Description
---------------------------------------
Test of default parameter with default value ( computers = 'localhost' ) in default ParameterSet = ServerName.

.EXAMPLE
Get-AllWindowsServices -client "OK" -solution "FIN" -Verbose

Description
---------------------------------------
Test of Verbose parameter. NOTE: Notice how localhost default value of parameter computers replaces with name of server.

.EXAMPLE
'ERROR' | Get-AllWindowsServices -client "OK" -solution "FIN" -errorlog

Description
---------------------------------------
Test of errorlog parameter. There is no server with name ERROR so this call will fail and write to Error log since errorlog switch parameter is on. Look Error_Log.txt file in PSLogs folder.

.EXAMPLE
Get-AllWindowsServices -computers 'APP100001' -client "OK" -solution "FIN" -errorlog

Description
---------------------------------------
Test of computers parameter with one value. Parameter accepts array of strings.

.EXAMPLE
Get-AllWindowsServices -computers 'APP100001', 'APP100002' -client "OK" -solution "FIN" -errorlog -Verbose

Description
---------------------------------------
Test of computers parameter with array of strings. Parameter accepts array of strings.

.EXAMPLE
Get-AllWindowsServices -hosts 'APP100001' -client "OK" -solution "FIN" -errorlog

Description
---------------------------------------
Test of computers paramater alias hosts.

.EXAMPLE
Get-AllWindowsServices -computers (Get-Content( "$home\Documents\WindowsPowerShell\Modules\01servers\OKFINservers.txt" )) -client "OK" -solution "FIN" -errorlog -Verbose

Description
---------------------------------------
Test of computers parameter and values for parameter comes from .txt file that has list of servers.

.EXAMPLE
'APP100001' | Get-AllWindowsServices -client "OK" -solution "FIN" -errorlog

Description
---------------------------------------
Test of pipeline by value of computers parameter.

.EXAMPLE
'APP100001', 'APP100002' | Get-AllWindowsServices -client "OK" -solution "FIN" -errorlog -Verbose

Description
---------------------------------------
Test of pipeline by value with array of strings of computers parameter.

.EXAMPLE
'APP100001', 'APP100002' | Select-Object @{label="computers";expression={$_}} | Get-AllWindowsServices -client "OK" -solution "FIN" -errorlog

Description
---------------------------------------
Test of values from pipeline by property name (computers).

.EXAMPLE
Get-Content( "$home\Documents\WindowsPowerShell\Modules\01servers\OKFINservers.txt" ) | Get-AllWindowsServices -client "OK" -solution "FIN" -errorlog -Verbose

Description
---------------------------------------
Test of pipeline by value that comes as content of .txt file with list of servers.

.EXAMPLE
Help Get-AllWindowsServices -Full

Description
---------------------------------------
Test of Powershell help.

.EXAMPLE
Get-AllWindowsServices -filename "OKFINkservers.txt" -errorlog -client "OK" -solution "FIN" -Verbose

Description
---------------------------------------
This is test of ParameterSet = FileName and parameter filename. There is list of servers in .txt file.

.EXAMPLE
Get-AllWindowsServices -filename "OKFINserverss.txt" -errorlog -client "OK" -solution "FIN" -Verbose

Description
---------------------------------------
This is test of ParameterSet = FileName and parameter filename. This test will fail due to wrong name of the .txt file with warning message "WARNING: This file path does NOT exist:".

.INPUTS
System.String

Computers parameter pipeline both by Value and by Property Name value and has default value of localhost. (Parameter Set = ComputerNames)
Filename parameter does not pipeline and does not have default value. (Parameter Set = FileName)
.OUTPUTS
System.Management.Automation.PSCustomObject

Get-AllWindowsServices returns PSCustomObjects which has been converted from PowerShell function Get-CimInstance -Class Win32_Service
Result shows following columns: Environment (PROD, Acceptance, Test, Course...), 
Logical name (Application, web, integration, FTP, Scan, Terminal Server...), Server name, Service name, Status, 
Start mode, Started, Process Id, Start name, Caption, Description, Display name, Accept pause, Accept stop, Path name, IP, Collected.
.LINK 
Get-CimInstance -Class Win32_Service
#>

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
            Write-Verbose "Start Win32_Service processing..."
            $AllWindowsService = $null

            $params = @{ 'ComputerName'=$computer;
                         'Class'='Win32_Service';
                         'ErrorAction'='Stop'}

            $AllWindowsServices = Get-CimInstance @params | 
                                      Select-Object __SERVER, Name, Status, StartMode, Started, ProcessId, StartName, Caption, Description, DisplayName, AcceptPause, AcceptStop, PathName
            
            Write-Verbose "Finish Win32_Service processing..."        
            
            foreach ($AllWindowsService in $AllWindowsServices) {
                Write-Verbose "Start processing windows service: $AllWindowsService"
                
                $properties = @{ 'Environment'=$env;
                                 'Logical name'=$logicalname;
                                 'Server name'=$computer;
            	                 'Service name'=$AllWindowsService.Name;
            	                 'Status'=$AllWindowsService.Status;
            	                 'Start mode'=$AllWindowsService.StartMode; 
                                 'Started'=$AllWindowsService.Started;
                                 'Process Id'=$AllWindowsService.ProcessId;
                                 'Start name'=$AllWindowsService.StartName;
                                 'Caption'=$AllWindowsService.Caption;
                                 'Description'=$AllWindowsService.Description;
                                 'Display name'=$AllWindowsService.DisplayName;
                                 'Accept pause'=$AllWindowsService.AcceptPause;
                                 'Accept stop'=$AllWindowsService.AcceptStop;
                                 'Path name'=$AllWindowsService.PathName;
                                 'IP'=$ip;
                                 'Collected'=(Get-Date -UFormat %Y.%m.%d' '%H:%M:%S)}
                
                $obj = New-Object -TypeName PSObject -Property $properties
                $obj.PSObject.TypeNames.Insert(0,'Report.AllWindowsServices')

                Write-Output $obj
                Write-Verbose "Finish processing windows service: $AllWindowsService"
                }
                
            Write-Verbose "Finish processing: $computer - $env - $logicalname"
            
        } catch {
            Write-Warning "Computer failed: $computer - $env - $logicalname Service failed: $AllWindowsService"
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
                Write-ErrorLog -hostname $hostname -env $env -logicalname $logicalname -errormsg $errormsg -exception $exception -scriptname $scriptname -failinglinenumber $failinglinenumber -failingline $failingline -pscommandpath $pscommandpath -positionmsg $pscommandpath -stacktrace $stacktrace
                Write-Verbose "Finish writing to Error log."
            }
        }
    }
}
END { 
}
}

#Get-AllWindowsServices -filename "OKFINservers.txt" -errorlog -client "OK" -solution "FIN" -Verbose | Select-Object 'Environment', 'Logical Name', 'Server Name', 'Service name', 'Status','Start mode', 'Started', 'Process Id', 'Start name', 'Caption', 'Description', 'Display name', 'Accept pause', 'Accept stop', 'Path name', 'IP', 'Collected'   | Out-GridView

#Get-AllWindowsServices -client "OK" -solution "FIN" -errorlog -Verbose | Select-Object 'Environment', 'Logical Name', 'Server Name', 'Service name', 'Status','Start mode', 'Started', 'Process Id', 'Start name', 'Caption', 'Description', 'Display name', 'Accept pause', 'Accept stop', 'Path name', 'IP', 'Collected'   | Out-GridView
            	                  
                                 
<#
#Test ParameterSet = ServerName
Get-AllWindowsServices -client "OK" -solution "FIN"
Get-AllWindowsServices -client "OK" -solution "FIN" -errorlog
Get-AllWindowsServices -client "OK" -solution "FIN" -errorlog -Verbose
Get-AllWindowsServices -computers 'APP100001' -client "OK" -solution "FIN" -errorlog
Get-AllWindowsServices -computers 'APP100001', 'APP100002' -client "OK" -solution "FIN" -errorlog -Verbose
Get-AllWindowsServices -hosts 'APP100001' -client "OK" -solution "FIN" -errorlog
Get-AllWindowsServices -computers (Get-Content( "$home\Documents\WindowsPowerShell\Modules\01servers\OKFINservers.txt" )) -client "OK" -solution "FIN" -errorlog -Verbose

#Pipeline examples
'APP100001' | Get-AllWindowsServices -client "OK" -solution "FIN" -errorlog
'APP100001', 'APP100002' | Get-AllWindowsServices -client "OK" -solution "FIN" -errorlog -Verbose
'APP100001', 'APP100002' | Select-Object @{label="computers";expression={$_}} | Get-AllWindowsServices -client "OK" -solution "FIN" -errorlog
Get-Content( "$home\Documents\WindowsPowerShell\Modules\01servers\OKFINservers.txt" ) | Get-AllWindowsServices -client "OK" -solution "FIN" -errorlog -Verbose
'ERROR' | Get-AllWindowsServices -client "OK" -solution "FIN" -errorlog

#Test CmdLet help
Help Get-AllWindowsServices -Full

#SaveToExcel
Get-AllWindowsServices -filename "OKFINservers.txt" -errorlog -client "OK" -solution "FIN" -Verbose | Save-ToExcel -errorlog -ExcelFileName "Get-AllWindowsServices" -title "Get All windows services info of servers in Financial solution for " -author "DJ PowerScript" -WorkSheetName "Windows services Info" -client "OK" -solution "FIN" 
#SaveToExcel and send email
Get-AllWindowsServices -filename "OKFINservers.txt" -errorlog -client "OK" -solution "FIN" -Verbose | Save-ToExcel -sendemail -errorlog -ExcelFileName "Get-AllWindowsServices" -title "Get All windows services info of servers in Financial solution for " -author "DJ PowerScript" -WorkSheetName "Windows services Info" -client "OK" -solution "FIN" 

#Benchmark
#Time = 44 sec; Total Items = 3891
Measure-BenchmarksCmdLet { Get-AllWindowsServices -filename "OKFINservers.txt" -errorlog -client "OK" -solution "FIN" -Verbose }
#Time = 27 sec; Total Items = 3891
Measure-BenchmarksCmdLet { Get-AllWindowsServices -filename "OKFINservers.txt" -errorlog -client "OK" -solution "FIN" }

#Baseline create
Get-AllWindowsServices -filename "OKFINservers.txt" -errorlog -client "OK" -solution "FIN" -Verbose | Save-Baseline -errorlog -BaselineFileName "Get-AllWindowsServices" -client "OK" -solution "FIN" -Verbose
Get-AllWindowsServices -client "OK" -solution "FIN" -errorlog -Verbose | Save-Baseline -errorlog -BaselineFileName "Get-AllWindowsServices" -client "OK" -solution "FIN" -Verbose 
#Baseline archive and create new
Get-AllWindowsServices -filename "OKFINservers.txt" -errorlog -client "OK" -solution "FIN" -Verbose | Save-Baseline -archive -errorlog -BaselineFileName "Get-AllWindowsServices"  -client "OK" -solution "FIN" -Verbose
Get-AllWindowsServices -client "OK" -solution "FIN" -errorlog -Verbose | Save-Baseline -archive -errorlog -BaselineFileName "Get-AllWindowsServices" -client "OK" -solution "FIN" -Verbose

#Test ParameterSet = FileName
Get-AllWindowsServices -filename "OKFINkursservers.txt" -errorlog -client "OK" -solution "FIN" -Verbose
Get-AllWindowsServices -filename "OKFINkursserverss.txt" -errorlog -client "OK" -solution "FIN" -Verbose

#Differance from baseline
Compare-Version -errorlog -Compare { Compare-Object -ReferenceObject ( Import-Clixml "$home\Documents\PSbaselines\Get-AllWindowsServices-OK-FIN.xml" ) -DifferenceObject (Get-AllWindowsServices -filename "OKFINservers.txt" -errorlog -client "OK" -solution "FIN") -Property IP, "Service name", Status, "Start mode", Started, "Start name", "Accept pause", "Accept stop" -PassThru | Sort-Object -Property IP, "Service name" | Select-Object * } | Save-ToExcel -sendemail -errorlog -ExcelFileName "DFB-GetAllWindowsServices" -title "Diff from baseline Get all windows services info of servers in Financial solution for " -author "DJ PowerScript" -WorkSheetName "DFB - All windows services" -client "OK" -solution "FIN" 
Compare-Version -errorlog -Compare { Compare-Object -ReferenceObject ( Import-Clixml "$home\Documents\PSbaselines\Get-AllWindowsServices-OK-FIN.xml" ) -DifferenceObject (Get-AllWindowsServices -client "OK" -solution "FIN" -errorlog) -Property IP, "Service name", Status, "Start mode", Started, "Start name", "Accept pause", "Accept stop" -PassThru | Sort-Object -Property IP, "Service name" | Select-Object * } | Save-ToExcel -sendemail -errorlog -ExcelFileName "DFB-GetAllWindowsServices" -title "Diff from baseline Get all windows services info of servers in Financial solution for " -author "DJ PowerScript" -WorkSheetName "DFB - All windows services" -client "OK" -solution "FIN" 
Compare-Version -errorlog -Compare { Compare-Object -ReferenceObject ( Import-Clixml "$home\Documents\PSbaselines\Get-AllWindowsServices-OK-FIN.xml" ) -DifferenceObject (Get-AllWindowsServices -client "OK" -solution "FIN" -errorlog) -Property IP, "Service name", Status, "Start mode", Started, "Start name", "Accept pause", "Accept stop" -PassThru | Sort-Object -Property IP, "Service name" | Select-Object * } | Out-GridView

#>