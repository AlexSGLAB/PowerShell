<#
.SYNOPSIS
Get errors from Event Viewer logs for a list of servers.
.DESCRIPTION
Get errors from Event Viewer logs for a list of servers. List of servers is in txt file in 01servers folder
or list of strings with names of computers.
CmdLet has two ParameterSets one for list of computers from file and another from list of strings as computer names.

Errors will be saved in log folder PSLogs with name Error_Log.txt. Parameter errorlog controls logging of errors in log file.

Get-ErrorFromEventLog function uses Get-WinEvent PowerShell function to get errors from Event Viewer logs.
NOTE: Get-WinEvent function has best performance among all other functions that can be used for same purpose.

Result shows following columns: Environment (PROD, Acceptance, Test, Course...), 
Logical Name (Application, web, integration, FTP, Scan, Terminal Server...), Server Name, 
Log name, Message, Level, Level description, Logged Time, Source, Event ID, Event record ID, Server, User, IP 
.PARAMETER computers
List of computers that we want to get Event Logs info from. Parameter belongs to default Parameter Set = ServerNames.
.PARAMETER filename
Name of txt file with list of servers that we want to check Event Log. .txt file should be in 01servers folder.
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
.PARAMETER days
Number of days to go in past when searching for errors from Event Viewer.

.EXAMPLE
Get-ErrorFromEventLog -client "OK" -solution "FIN" -days 7 

Description
---------------------------------------
Test of default parameter with default value ( computers = 'localhost' ) in default ParameterSet = ServerName.

.EXAMPLE
Get-ErrorFromEventLog -client "OK" -solution "FIN" -days 7 -Verbose

Description
---------------------------------------
Test of Verbose parameter. NOTE: Notice how localhost default value of parameter computers replaces with name of server.

.EXAMPLE
'ERROR' | Get-ErrorFromEventLog -client "OK" -solution "FIN" -days 7 -errorlog

Description
---------------------------------------
Test of errorlog parameter. There is no server with name ERROR so this call will fail and write to Error log since errorlog switch parameter is on. Look Error_Log.txt file in PSLogs folder.

.EXAMPLE
Get-ErrorFromEventLog -computers 'APP100001' -client "OK" -solution "FIN" -days 7 -errorlog

Description
---------------------------------------
Test of computers parameter with one value. Parameter accepts array of strings.

.EXAMPLE
Get-ErrorFromEventLog -computers 'APP100001', 'APP100002' -client "OK" -solution "FIN" -days 7 -errorlog -Verbose

Description
---------------------------------------
Test of computers parameter with array of strings. Parameter accepts array of strings.

.EXAMPLE
Get-ErrorFromEventLog -hosts 'APP100001' -client "OK" -solution "FIN" -days 7 -errorlog

Description
---------------------------------------
Test of computers paramater alias hosts.

.EXAMPLE
Get-ErrorFromEventLog -computers (Get-Content( "$home\Documents\WindowsPowerShell\Modules\01servers\OKFINservers.txt" )) -client "OK" -solution "FIN" -days 7 -errorlog -Verbose

Description
---------------------------------------
Test of computers parameter and values for parameter comes from .txt file that has list of servers.

.EXAMPLE
'APP100001' | Get-ErrorFromEventLog -client "OK" -solution "FIN" -days 7 -errorlog

Description
---------------------------------------
Test of pipeline by value of computers parameter.

.EXAMPLE
'APP100001', 'APP100002' | Get-ErrorFromEventLog -client "OK" -solution "FIN" -days 7 -errorlog -Verbose

Description
---------------------------------------
Test of pipeline by value with array of strings of computers parameter.

.EXAMPLE
'APP100001', 'APP100002' | Select-Object @{label="computers";expression={$_}} | Get-ErrorFromEventLog -client "OK" -solution "FIN" -days 7 -errorlog

Description
---------------------------------------
Test of values from pipeline by property name (computers).

.EXAMPLE
Get-Content( "$home\Documents\WindowsPowerShell\Modules\01servers\OKFINservers.txt" ) | Get-ErrorFromEventLog -client "OK" -solution "FIN" -days 7 -errorlog -Verbose

Description
---------------------------------------
Test of pipeline by value that comes as content of .txt file with list of servers.

.EXAMPLE
Help Get-ErrorFromEventLog -Full

Description
---------------------------------------
Test of Powershell help.

.EXAMPLE
Get-ErrorFromEventLog -filename "OKFINservers.txt" -errorlog -client "OK" -solution "FIN" -days 7 -Verbose

Description
---------------------------------------
This is test of ParameterSet = FileName and parameter filename. There is list of servers in .txt file.

.EXAMPLE
Get-ErrorFromEventLog -file "OKFINserverss.txt" -errorlog -client "OK" -solution "FIN" -days 7 -Verbose

Description
---------------------------------------
This is test of ParameterSet = FileName and parameter filename. This test will fail due to wrong name of the .txt file with warning message "WARNING: This file path does NOT exist:".

.INPUTS
System.String

Computers parameter pipeline both by Value and by Property Name value and has default value of localhost. (Parameter Set = ComputerNames)
Filename parameter does not pipeline and does not have default value. (Parameter Set = FileName)
.OUTPUTS
System.Management.Automation.PSCustomObject

Get-ErrorFromEventLog returns PSCustomObjects which has been converted from PowerShell function Get-WinEvent
Result shows following columns: Environment (PROD, Acceptance, Test, Course...), 
Logical name (Application, web, integration, FTP, Scan, Terminal Server...), Server name
Log name, Message, Level, Level description, Logged Time, Source, Event ID, Event record ID, Server, User, IP 

.NOTES
FunctionName : Get-ErrorFromEventLog
Created by   : Dejan Mladenovic
Date Coded   : 10/31/2018 19:06:41
More info    : https://improvescripting.com/

.LINK 
https://improvescripting.com/how-to-get-windows-event-logs-details-using-powershell
http://www.powershellish.com/blog/2015-01-19-get-winevent-max-logs
Get-WinEvent
#>
Function Get-ErrorFromEventLog {
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
    [string]$solution,

    [Parameter(Mandatory=$true,
                HelpMessage="How many days in the past to look for error.")]
    #[ValidateRange(0,100)]
    [int]$days
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
            Write-Verbose "Start Get-WinEvent processing..."
            
            $events = $null
            $event = $null
            $obj = $null
            

            #THIS SOLVES PROBLEM WITH EMPTY MESSAGE PROPERTY IN PS v3.0
            $orgCulture = Get-Culture
            [System.Threading.Thread]::CurrentThread.CurrentCulture = New-Object "System.Globalization.CultureInfo" "en-US"

            #$events = Get-WinEvent -ErrorAction Stop -ComputerName $computer -FilterHashtable @{ LogName = "*"

            #Use this to avoid Invalid data error due to limitation of 256 logs searching if used LogName = "*" with wildcard
            #We will look only into logs that have records
            $logs = Get-WinEvent -ListLog * | Where-Object {$_.RecordCount} | Select-Object -ExpandProperty LogName

            $params = @{ 'ComputerName'=$computer;
                         'ErrorAction'='Stop';
                         'FilterHashtable'=@{ LogName = $logs; StartTime = ((Get-Date).AddDays(-1*[int]$days)); Level=1,2}
                         #'FilterHashtable'=@{ LogName = "Security", "Application", "System"; StartTime = ((Get-Date).AddDays(-1*[int]$days)); Level=1,2}
                         }
            
            #'FilterHashtable'=@{ LogName = "Application", "System"; StartTime = ((Get-Date).AddDays(-1*[int]$days)); Level=1,2}
            #-FilterHashtable @{ LogName = "Application"; StartTime = ((Get-Date).AddDays(-1*[int]$days)); Level=1,2}

            $events = Get-WinEvent @params  | 
                            Select-Object   LogName, 
                                            Level, 
                                            LevelDisplayName, 
                                            TimeCreated, 
                                            ProviderName, 
                                            MachineName, 
                                            Id, 
                                            RecordId, 
                                            UserId, 
                                            Message | 
                            Sort-Object TimeCreated
            
            [System.Threading.Thread]::CurrentThread.CurrentCulture = $orgCulture
                        
            Write-Verbose "Finish Get-WinEvent processing..."
            
            foreach ( $event in $events ) {
            
                Write-Verbose "Start processing event: $event"
                
                $properties = @{ 'Environment'=$env;
                                 'Logical name'=$logicalname;
                                 'Computer name'=$computer;
            	                 'Log name'=$event.LogName;
            	                 'Message'=$event.Message;
            	                 'Level'=$event.Level; 
                                 'Level description'=$event.LevelDisplayName;
                                 'Logged'=$event.TimeCreated;
                                 'Source'=$event.ProviderName;
                                 'Event ID'=$event.Id;
                                 'Event record ID'=$event.RecordId;
                                 'Server'=$event.MachineName;
                                 'User'=$event.UserId;
                                 'IP'=$ip;
                                 'Collected'=(Get-Date -UFormat %Y.%m.%d' '%H:%M:%S)}

                $obj = New-Object -TypeName PSObject -Property $properties
                $obj.PSObject.TypeNames.Insert(0,'Report.ErrorFromEventLog')

                Write-Output $obj
                Write-Verbose "Finish processing event: $event"
            }
            
        Write-Verbose "Computer processed: $computer - $env - $logicalname"
        
        } catch {
                 Write-Warning "Computer failed: $computer - $env - $logicalname Event failed: $event"
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
END {  }
}
#region Execution examples
#[System.Threading.Thread]::CurrentThread.CurrentCulture = "en-US";[System.Threading.Thread]::CurrentThread.CurrentCulture;
#[System.Threading.Thread]::CurrentThread.CurrentCulture = "en-US";Get-ErrorFromEventLog -computers "OKFINservers.txt" -errorlog -client "OK" -solution "FIN" -days 7 -Verbose
#Get-ErrorFromEventLog -filename "OKFINservers.txt" -errorlog -client "OK" -solution "FIN" -days 3 -Verbose |  Out-GridView 
#Get-ErrorFromEventLog -filename "OKFINservers.txt" -errorlog -client "OK" -solution "FIN" -days 30  -Verbose |  Out-GridView 
#Get-ErrorFromEventLog -filename "OKFINservers.txt" -errorlog -client "OK" -solution "FIN" -days 30 -Verbose |  Out-GridView 

#Get-ErrorFromEventLog -filename "OKFINservers.txt" -errorlog -client "OK" -solution "FIN" -days 3 -Verbose | Export-Csv -Path "$home\Documents\PSreports\kurs.csv" -NoTypeInformation -Delimiter ";"

#Get-ErrorFromEventLog -filename "OKFINservers.txt" -errorlog -client "OK" -solution "FIN" -days 3 -Verbose | Export-Csv -Path "$home\Documents\PSreports\all.csv" -NoTypeInformation -Delimiter ";"

<#
#Test ParameterSet = ServerName
Get-ErrorFromEventLog -client "OK" -solution "FIN" -days 7 | Out-GridView
Get-ErrorFromEventLog -client "OK" -solution "FIN" -days 7 -errorlog | Out-GridView
Get-ErrorFromEventLog -client "OK" -solution "FIN" -days 7 -errorlog -Verbose | Out-GridView
Get-ErrorFromEventLog -computers 'APP100001' -client "OK" -solution "FIN" -days 7 -errorlog | Out-GridView
Get-ErrorFromEventLog -computers 'APP100001', 'APP100002' -client "OK" -solution "FIN" -days 7 -errorlog -Verbose | Out-GridView
Get-ErrorFromEventLog -hosts 'APP100001' -client "OK" -solution "FIN" -days 7 -errorlog | Out-GridView
Get-ErrorFromEventLog -computers (Get-Content( "$home\Documents\WindowsPowerShell\Modules\01servers\OKFINservers.txt" )) -client "OK" -solution "FIN" -days 7 -errorlog -Verbose | Out-GridView

#Pipeline examples
'APP100001' | Get-ErrorFromEventLog -client "OK" -solution "FIN" -days 7 -errorlog | Out-GridView
'APP100001', 'APP100002' | Get-ErrorFromEventLog -client "OK" -solution "FIN" -days 7 -errorlog -Verbose | Out-GridView
'APP100001', 'APP100002' | Select-Object @{label="computers";expression={$_}} | Get-ErrorFromEventLog -client "OK" -solution "FIN" -days 7 -errorlog | Out-GridView
Get-Content( "$home\Documents\WindowsPowerShell\Modules\01servers\OKFINkursservers.txt" ) | Get-ErrorFromEventLog -client "OK" -solution "FIN" -days 7 -errorlog -Verbose | Out-GridView
'ERROR' | Get-ErrorFromEventLog -client "OK" -solution "FIN" -days 7 -errorlog | Out-GridView

#Test CmdLet help
Help Get-ErrorFromEventLog -Full

#SaveToExcel
Get-ErrorFromEventLog -filename "OKFINservers.txt" -errorlog -client "OK" -solution "FIN" -days 30 -Verbose | Save-ToExcel -errorlog -ExcelFileName "Get-ErrorFromEventLog" -title "Get errors from servers in Financial solution for " -author "DJ PowerScript" -WorkSheetName "Errors from Event logs" -client "OK" -solution "FIN" 
#SaveToExcel and send email
Get-ErrorFromEventLog -filename "OKFINservers.txt" -errorlog -client "OK" -solution "FIN" -days 30 -Verbose | Save-ToExcel -sendemail -errorlog -ExcelFileName "Get-ErrorFromEventLog" -title "Get errors from servers in Financial solution for " -author "DJ PowerScript" -WorkSheetName "Errors from Event logs" -client "OK" -solution "FIN" 

Get-ErrorFromEventLog -client "OK" -solution "FIN" -days 7 -errorlog -Verbose | Save-ToExcel -sendemail -errorlog -ExcelFileName "Get-ErrorFromEventLog" -title "Get errors from servers in Financial solution for " -author "DJ PowerScript" -WorkSheetName "Errors from Event logs" -client "OK" -solution "FIN" 
Get-ErrorFromEventLog -client "OK" -solution "FIN" -days 7 -errorlog -Verbose | Save-ToExcel -errorlog -ExcelFileName "Get-ErrorFromEventLog" -title "Get errors from servers in Financial solution for " -author "DJ PowerScript" -WorkSheetName "Errors from Event logs" -client "OK" -solution "FIN" 

#Benchmark
#Time = 466 sec; Total Items = 13725
Measure-BenchmarksCmdLet { Get-ErrorFromEventLog -filename "OKFINservers.txt" -errorlog -client "OK" -solution "FIN" -days 30 -Verbose }
#Time = 325 sec; Total Items = 13725
Measure-BenchmarksCmdLet { Get-ErrorFromEventLog -filename "OKFINservers.txt" -errorlog -client "OK" -solution "FIN" -days 30  }
#Time =  sec; Total Items = 
Measure-BenchmarksCmdLet { Get-ErrorFromEventLog -filename "OKFINservers.txt" -errorlog -client "OK" -solution "FIN" -days 30 | Save-ToExcel -sendemail -errorlog -ExcelFileName "Get-ErrorFromEventLog" -title "Get errors from servers in Financial solution for " -author "DJ PowerScript" -WorkSheetName "Errors from Event logs" -client "OK" -solution "FIN" }

#Test ParameterSet = FileName
Get-ErrorFromEventLog -filename "OKFINservers.txt" -errorlog -client "OK" -solution "FIN" -days 7 -Verbose | Out-GridView
Get-ErrorFromEventLog -filename "OKFINserverss.txt" -errorlog -client "OK" -solution "FIN" -days 7 -Verbose | Out-GridView
#>
#endregion