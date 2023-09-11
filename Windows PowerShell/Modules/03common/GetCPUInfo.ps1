﻿<#
.SYNOPSIS
Get CPU info for list of computers.
.DESCRIPTION
Gets CPU info for list of servers. 
List of servers is in txt file in 01servers folder or list of strings with names of computers.
CmdLet has two ParameterSets one for list of computers from file and another from list of strings as computer names.

Errors will be saved in log folder PSLogs with name Error_Log.txt. Parameter errorlog controls logging of errors in log file.

Get-CPUInfo function uses Get-CimInstance -Class Win32_Processor PowerShell function to get CPU info.

Result shows following columns: Environment (PROD, Acceptance, Test, Course...), 
Logical Name (Application, web, integration, FTP, Scan, Terminal Server...), Server Name
CPU, CPU ID, Number of CPU cores, 32 or 64 bits CPU, IP, Collected
.PARAMETER computers
List of computers that we want to get CPU Info from. Parameter belongs to default Parameter Set = ServerNames.
.PARAMETER filename
Name of txt file with list of servers that we want to check CPUInfo. .txt file should be in 01servers folder.
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
Get-CPUInfo -client "OK" -solution "FIN"

Description
---------------------------------------
Test of default parameter with default value ( computers = 'localhost' ) in default ParameterSet = ServerName.

.EXAMPLE
Get-CPUInfo -client "OK" -solution "FIN" -Verbose

Description
---------------------------------------
Test of Verbose parameter. NOTE: Notice how localhost default value of parameter computers replaces with name of server.

.EXAMPLE
'ERROR' | Get-CPUInfo -client "OK" -solution "FIN" -errorlog

Description
---------------------------------------
Test of errorlog parameter. There is no server with name ERROR so this call will fail and write to Error log since errorlog switch parameter is on. Look Error_Log.txt file in PSLogs folder.

.EXAMPLE
Get-CPUInfo -computers 'APP100001' -client "OK" -solution "FIN" -errorlog

Description
---------------------------------------
Test of computers parameter with one value. Parameter accepts array of strings.

.EXAMPLE
Get-CPUInfo -computers 'APP100001', 'APP100002' -client "OK" -solution "FIN" -errorlog -Verbose

Description
---------------------------------------
Test of computers parameter with array of strings. Parameter accepts array of strings.

.EXAMPLE
Get-CPUInfo -hosts 'APP100001' -client "OK" -solution "FIN" -errorlog

Description
---------------------------------------
Test of computers paramater alias hosts.

.EXAMPLE
Get-CPUInfo -computers (Get-Content( "$home\Documents\WindowsPowerShell\Modules\01servers\OKFINservers.txt" )) -client "OK" -solution "FIN" -errorlog -Verbose

Description
---------------------------------------
Test of computers parameter and values for parameter comes from .txt file that has list of servers.

.EXAMPLE
'APP100001' | Get-CPUInfo -client "OK" -solution "FIN" -errorlog

Description
---------------------------------------
Test of pipeline by value of computers parameter.

.EXAMPLE
'APP100001', 'APP100002' | Get-CPUInfo -client "OK" -solution "FIN" -errorlog -Verbose

Description
---------------------------------------
Test of pipeline by value with array of strings of computers parameter.

.EXAMPLE
'APP100001', 'APP100002' | Select-Object @{label="computers";expression={$_}} | Get-CPUInfo -client "OK" -solution "FIN" -errorlog

Description
---------------------------------------
Test of values from pipeline by property name (computers).

.EXAMPLE
Get-Content( "$home\Documents\WindowsPowerShell\Modules\01servers\OKFINservers.txt" ) | Get-CPUInfo -client "OK" -solution "FIN" -errorlog -Verbose

Description
---------------------------------------
Test of pipeline by value that comes as content of .txt file with list of servers.

.EXAMPLE
Help Get-CPUInfo -Full

Description
---------------------------------------
Test of Powershell help.

.EXAMPLE
Get-CPUInfo -filename "OKFINservers.txt" -errorlog -client "OK" -solution "FIN" -Verbose

Description
---------------------------------------
This is test of ParameterSet = FileName and parameter filename. There is list of servers in .txt file.

.EXAMPLE
Get-CPUInfo -filename "OKFINseserverss.txt" -errorlog -client "OK" -solution "FIN" -Verbose

Description
---------------------------------------
This is test of ParameterSet = FileName and parameter filename. This test will fail due to wrong name of the .txt file with warning message "WARNING: This file path does NOT exist:".

.INPUTS
System.String

Computers parameter pipeline both by Value and by Property Name value and has default value of localhost. (Parameter Set = ComputerNames)
Filename parameter does not pipeline and does not have default value. (Parameter Set = FileName)
.OUTPUTS
System.Management.Automation.PSCustomObject

Get-CPUInfo returns PSCustomObjects which has been converted from PowerShell function Get-WmiObject -Class Win32_Processor
Result shows following columns: Environment (PROD, Acceptance, Test, Course...), 
Logical name (Application, web, integration, FTP, Scan, Terminal Server...), Server name
CPU, CPU ID, Number of CPU cores, 32 or 64 bits CPU, IP, Collected

.NOTES
FunctionName : Get-CPUInfo
Created by   : Dejan Mladenovic
Date Coded   : 10/31/2018 19:06:41
More info    : https://improvescripting.com/

.LINK 
https://improvescripting.com/get-processor-cpu-information-using-powershell-script
Get-CimInstance -Class Win32_Processor
Get-CimInstance -Class CIM_Processor
#>
Function Get-CPUInfo {
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
            Write-Verbose "Start CIM_Processor processing..."
            $CPUInfos = $null

            $params = @{ 'ComputerName'=$computer;
                         'Class'='CIM_Processor';
                         'ErrorAction'='Stop'}

            $CPUInfos = Get-CimInstance @params | 
                            Select-Object   @{label="ServerName"; Expression={$_.SystemName}}, 
                                            @{label="CPU"; Expression={$_.Name}}, 
                                            @{label="CPUid"; Expression={$_.DeviceID}}, 
                                            NumberOfCores, 
                                            AddressWidth
            
            Write-Verbose "Finish CIM_Processor processing..."        
            
            foreach ($CPUInfo in $CPUInfos) {
                Write-Verbose "Start processing CPU: $CPUInfo"

                $properties = @{ 'Environment'=$env;
                                 'Logical name'=$logicalname;
                                 'Server name'=$CPUInfo.ServerName;
            	                 'CPU'=$CPUInfo.CPU;
            	                 'CPU ID'=$CPUInfo.CPUid;
            	                 'Number of CPU cores'=$CPUInfo.NumberOfCores; 
                                 '64 or 32 bits'=$CPUInfo.AddressWidth;
                                 'IP'=$ip;
                                 'Collected'=(Get-Date -UFormat %Y.%m.%d' '%H:%M:%S)}

                $obj = New-Object -TypeName PSObject -Property $properties
                $obj.PSObject.TypeNames.Insert(0,'Report.CPUInfo')

                Write-Output $obj
                Write-Verbose "Finish processing CPU: $CPUInfo"
            }
            
            Write-Verbose "Finish processing: $computer - $env - $logicalname"
                        
        } catch {
            Write-Warning "Computer failed: $computer - $env - $logicalname CPU failed: $CPUInfos"
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

               
                $ErrorArguments = @{
                    'hostname' = $computer;
                    'env' = $env;
                    'logicalname' = $logicalname;
                    'errormsg' = $errormsg;
                    'exception' = $exception;
                    'stacktrace'= $stacktrace;
                    'failingline' = $failingline;
                    'positionmsg' = $positionmsg;
                    'pscommandpath' = $pscommandpath;
                    'failinglinenumber' = $failinglinenumber;
                    'scriptname' = $scriptname
                }
               
                ##Splatting as array
                ##$ErrorArguments = 'Test', 'PROD', 'APP'

                Write-Verbose "Start writing to Error log."
                Write-ErrorLog @ErrorArguments
                #Write-ErrorLog -hostname $computer -env $env -logicalname $logicalname -errormsg $errormsg -exception $exception -scriptname $scriptname -failinglinenumber $failinglinenumber -failingline $failingline -pscommandpath $pscommandpath -positionmsg $pscommandpath -stacktrace $stacktrace
                Write-Verbose "Finish writing to Error log."
            }
        }
                        
    }
     
}
END { 
}
}
#region Execution examples
#Get-CPUInfo -filename "OKFINservers.txt" -errorlog -client "OK" -solution "FIN" -Verbose | Select-Object 'Environment', 'Logical Name', 'Server Name', 'CPU', 'CPU ID', 'Number of CPU cores', '64 or 32 bits', 'IP', 'Collected'   | Out-GridView

<#
#Test ParameterSet = ServerName
Get-CPUInfo -client "OK" -solution "FIN"
Get-CPUInfo -client "OK" -solution "FIN" -errorlog
Get-CPUInfo -client "OK" -solution "FIN" -errorlog -Verbose
Get-CPUInfo -computers 'APP100001' -client "OK" -solution "FIN" -errorlog
Get-CPUInfo -computers 'APP100001', 'APP100002' -client "OK" -solution "FIN" -errorlog -Verbose
Get-CPUInfo -hosts 'APP100001' -client "OK" -solution "FIN" -errorlog
Get-CPUInfo -computers (Get-Content( "$home\Documents\WindowsPowerShell\Modules\01servers\OKFINservers.txt" )) -client "OK" -solution "FIN" -errorlog -Verbose

#Pipeline examples
'APP100001' | Get-CPUInfo -client "OK" -solution "FIN" -errorlog
'APP100001', 'APP100002' | Get-CPUInfo -client "OK" -solution "FIN" -errorlog -Verbose
'APP100001', 'APP100002' | Select-Object @{label="computers";expression={$_}} | Get-CPUInfo -client "OK" -solution "FIN" -errorlog
Get-Content( "$home\Documents\WindowsPowerShell\Modules\01servers\OKFINservers.txt" ) | Get-CPUInfo -client "OK" -solution "FIN" -errorlog -Verbose
'ERROR' | Get-CPUInfo -client "OK" -solution "FIN" -errorlog

#Test CmdLet help
Help Get-CPUInfo -Full

#SaveToExcel
Get-CPUInfo -filename "OKFINservers.txt" -errorlog -client "OK" -solution "FIN" -Verbose | Save-ToExcel -errorlog -ExcelFileName "Get-CPUinfo" -title "Get CPU info of servers in Financial solution for " -author "Dejan Mladenovic" -WorkSheetName "CPU Info" -client "OK" -solution "FIN" 
#SaveToExcel and send email
Get-CPUInfo -filename "OKFINservers.txt" -errorlog -client "OK" -solution "FIN" -Verbose | Save-ToExcel -sendemail -errorlog -ExcelFileName "Get-CPUinfo" -title "Get CPU info of servers in Financial solution for " -author "Dejan Mladenovic" -WorkSheetName "CPU Info" -client "OK" -solution "FIN" 

#Benchmark
#Time = 52; Total Items = 46
Measure-BenchmarksCmdLet { Get-CPUInfo -filename "OKFINservers.txt" -errorlog -client "OK" -solution "FIN" -Verbose }
#Time = 52 sec; Total Items = 46
Measure-BenchmarksCmdLet { Get-CPUInfo -filename "OKFINservers.txt" -errorlog -client "OK" -solution "FIN" }

#Baseline create
Get-CPUInfo -filename "OKFINservers.txt" -errorlog -client "OK" -solution "FIN" -Verbose | Save-Baseline -errorlog -BaselineFileName "Get-CPUInfo" -client "OK" -solution "FIN" -Verbose
#Baseline archive and create new
Get-CPUInfo -filename "OKFINservers.txt" -errorlog -client "OK" -solution "FIN" -Verbose | Save-Baseline -archive -errorlog -BaselineFileName "Get-CPUInfo"  -client "OK" -solution "FIN" -Verbose

#Test ParameterSet = FileName
Get-CPUInfo -filename "OKFINservers.txt" -errorlog -client "OK" -solution "FIN" -Verbose
Get-CPUInfo -filename "OKFINcourseserverss.txt" -errorlog -client "OK" -solution "FIN" -Verbose
#>
#endregion
