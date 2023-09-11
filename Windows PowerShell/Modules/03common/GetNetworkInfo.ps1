<#
.SYNOPSIS
Get Network's Adapter info for list of computers.
.DESCRIPTION
Get Network's Adapters info for list of servers. 
List of servers is in txt file in 01servers folder or list of strings with names of computers.
CmdLet has two ParameterSets one for list of computers from file and another from list of strings as computer names.

Errors will be saved in log folder PSLogs with name Error_Log.txt. Parameter errorlog controls logging of errors in log file.

Get-NetworkInfo function uses Get-CimInstance -Class CIM_NetworkAdapter PowerShell function to get Network Adapter info.
Result shows following columns: Environment (PROD, Acceptance, Test, Course...), 
LogicalName (Application, web, integration, FTP, Scan, Terminal Server...), Server name, 
Product name, Name, Manufacturer, Physical adapter, Speed, MAC Address, GUID, Adapter type, Description, Device ID, 
Net connection ID, Net connection status, Net enabled, Service name, Status, Status info, IP, Collected.

.PARAMETER computers
List of computers that we want to get Network's adapters Info from. Parameter belongs to default Parameter Set = ServerNames.
.PARAMETER filename
Name of txt file with list of servers that we want to check Network's adapters info. .txt file should be in 01servers folder.
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
Get-NetworkInfo -client "OK" -solution "FIN"

Description
---------------------------------------
Test of default parameter with default value ( computers = 'localhost' ) in default ParameterSet = ServerName.

.EXAMPLE
Get-NetworkInfo -client "OK" -solution "FIN" -Verbose

Description
---------------------------------------
Test of Verbose parameter. NOTE: Notice how localhost default value of parameter computers replaces with name of server.

.EXAMPLE
'ERROR' | Get-NetworkInfo -client "OK" -solution "FIN" -errorlog

Description
---------------------------------------
Test of errorlog parameter. There is no server with name ERROR so this call will fail and write to Error log since errorlog switch parameter is on. Look Error_Log.txt file in PSLogs folder.

.EXAMPLE
Get-NetworkInfo -computers 'APP100001' -client "OK" -solution "FIN" -errorlog

Description
---------------------------------------
Test of computers parameter with one value. Parameter accepts array of strings.

.EXAMPLE
Get-NetworkInfo -computers 'APP100001', 'APP100002' -client "OK" -solution "FIN" -errorlog -Verbose

Description
---------------------------------------
Test of computers parameter with array of strings. Parameter accepts array of strings.

.EXAMPLE
Get-NetworkInfo -hosts 'APP100001' -client "OK" -solution "FIN" -errorlog

Description
---------------------------------------
Test of computers paramater alias hosts.

.EXAMPLE
Get-NetworkInfo -computers (Get-Content( "$home\Documents\WindowsPowerShell\Modules\01servers\OKFINservers.txt" )) -client "OK" -solution "FIN" -errorlog -Verbose

Description
---------------------------------------
Test of computers parameter and values for parameter comes from .txt file that has list of servers.

.EXAMPLE
'APP100001' | Get-NetworkInfo -client "OK" -solution "FIN" -errorlog

Description
---------------------------------------
Test of pipeline by value of computers parameter.

.EXAMPLE
'APP100001', 'APP100002' | Get-NetworkInfo -client "OK" -solution "FIN" -errorlog -Verbose

Description
---------------------------------------
Test of pipeline by value with array of strings of computers parameter.

.EXAMPLE
'APP100001', 'APP100002' | Select-Object @{label="computers";expression={$_}} | Get-NetworkInfo -client "OK" -solution "FIN" -errorlog

Description
---------------------------------------
Test of values from pipeline by property name (computers).

.EXAMPLE
Get-Content( "$home\Documents\WindowsPowerShell\Modules\01servers\OKFINservers.txt" ) | Get-NetworkInfo -client "OK" -solution "FIN" -errorlog -Verbose

Description
---------------------------------------
Test of pipeline by value that comes as content of .txt file with list of servers.

.EXAMPLE
Help Get-NetworkInfo -Full

Description
---------------------------------------
Test of Powershell help.

.EXAMPLE
Get-NetworkInfo -filename "OKFINservers.txt" -errorlog -client "OK" -solution "FIN" -Verbose

Description
---------------------------------------
This is test of ParameterSet = FileName and parameter filename. There is list of servers in .txt file.

.EXAMPLE
Get-NetworkInfo -filename "OKFINserverss.txt" -errorlog -client "OK" -solution "FIN" -Verbose

Description
---------------------------------------
This is test of ParameterSet = FileName and parameter filename. This test will fail due to wrong name of the .txt file with warning message "WARNING: This file path does NOT exist:".

.INPUTS
System.String

Computers parameter pipeline both by Value and by Property Name value and has default value of localhost. (Parameter Set = ComputerNames)
Filename parameter does not pipeline and does not have default value. (Parameter Set = FileName)
.OUTPUTS
System.Management.Automation.PSCustomObject

Get-NetworkInfo returns PSCustomObjects which has been converted from PowerShell function Get-CimInstance -Class CIM_NetworkAdapter
Result shows following columns: Environment (PROD, Acceptance, Test, Course...), 
LogicalName (Application, web, integration, FTP, Scan, Terminal Server...), ServerName, 
Product name, Name, Manufacturer, Physical adapter, Speed, MAC Address, GUID, Adapter type, Description, Device ID, 
Net connection ID, Net connection status, Net enabled, Service name, Status, Status info, IP, Collected

.NOTES
FunctionName : Get-NetworkInfo
Created by   : Dejan Mladenovic
Date Coded   : 10/31/2018 19:06:41
More info    : https://improvescripting.com/

.LINK 
https://improvescripting.com/how-to-get-network-card-properties-using-powershell/
Get-WmiObject -Class Win32_NetworkAdapter
Get-CimInstance -Class CIM_NetworkAdapter
#>
Function Get-NetworkInfo {
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
        }

        $computerinfo = Get-ComputerInfo -computername $computer -client $client -solution $solution
        $hostname = $computerinfo.hostname
        $env = $computerinfo.environment
        $logicalname = $computerinfo.logicalname
        $ip = $computerinfo.ipaddress
        
        try {
            Write-Verbose "Start processing: $computer - $env - $logicalname"
            Write-Verbose "Start CIM_NetworkAdapter processing..."
            # I have to null the values in order not to send network info of wrong server into error log.
            $networks = $null
            $obj = $null
            $network = $null

            $params = @{ 'ComputerName'=$computer;
            'Class'='CIM_NetworkAdapter';
            'ErrorAction'='Stop'}

            $networks = Get-CimInstance @params | 
                            Select-Object   @{label="ServerName"; Expression={$_.SystemName}}, 
                                            ProductName, 
                                            Name, 
                                            Manufacturer, 
                                            PhysicalAdapter, 
                                            Speed, 
                                            MACAddress, 
                                            GUID, 
                                            AdapterType, 
                                            Description, 
                                            DeviceID, 
                                            NetConnectionID, 
                                            NetConnectionStatus, 
                                            NetEnabled, 
                                            ServiceName, 
                                            Status, 
                                            StatusInfo            

            Write-Verbose "Finish CIM_NetworkAdapter processing..."
            
            foreach ($network in $networks) {
                Write-Verbose "Start processing NIC: $network"

                $properties = @{ 'Environment'=$env;
                                 'Logical name'=$logicalname;
                                 'Server name'=$network.ServerName;
                                 "Product name"=$network.ProductName;
                                 'Name'=$network.Name;
                                 'Manufacturer'=$network.Manufacturer;
                                 'Physical adapter'=$network.PhysicalAdapter;
                                 'Speed'=$network.Speed;
                                 'MAC Address'=$network.MACAddress;
                                 'GUID'=$network.GUID;
                                 'Adapter type'=$network.AdapterType;
                                 'Description'=$network.Description;
                                 'Device ID'=$network.DeviceID;
                                 'Net connection ID'=$network.NetConnectionID;
                                 'Net connection status'=$network.NetConnectionStatus;
                                 'Net enabled'=$network.NetEnabled;
                                 'Service name'=$network.ServiceName;
                                 'Status'=$network.Status;
                                 'Status info'=$network.StatusInfo;
                                 'IP'=$ip;
                                 'Collected'=(Get-Date -UFormat %Y.%m.%d' '%H:%M:%S)}

                $obj = New-Object -TypeName PSObject -Property $properties
                $obj.PSObject.TypeNames.Insert(0,'Report.NetworkCard')
                
                Write-Output $obj
                Write-Verbose "Finish processing NIC: $network"
            }
            
            Write-Verbose "Finish processing: $computer - $env - $logicalname"
            
        } catch {
            Write-Warning "Computer failed: $computer - $env - $logicalname NIC failed: $network"
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
#Get-NetworkInfo -client "OK" -solution "FIN"
#Get-NetworkInfo -filename "OKFINservers.txt" -errorlog -client "OK" -solution "FIN" -Verbose | Out-GridView

#Get-NetworkInfo -filename "OKFINservers.txt" -errorlog -client "OK" -solution "FIN" -Verbose | Select-Object 'Environment', 'Logical name', 'Server name', 'Product name', 'Name', 'Manufacturer', 'Physical adapter', 'Speed', 'MAC Address', 'GUID', 'Adapter type', 'Description', 'Device ID', 'Net connection ID', 'Net connection status', 'Net enabled', 'Service name', 'Status', 'Status info', 'IP', 'Collected'

<#
#Test ParameterSet = ServerName
Get-NetworkInfo -client "OK" -solution "FIN"
Get-NetworkInfo -client "OK" -solution "FIN" -errorlog
Get-NetworkInfo -client "OK" -solution "FIN" -errorlog -Verbose
Get-NetworkInfo -computers 'APP100001' -client "OK" -solution "FIN" -errorlog
Get-NetworkInfo -computers 'APP100001', 'APP100002' -client "OK" -solution "FIN" -errorlog -Verbose
Get-NetworkInfo -hosts 'APP100001' -client "OK" -solution "FIN" -errorlog
Get-NetworkInfo -computers (Get-Content( "$home\Documents\WindowsPowerShell\Modules\01servers\OKFINservers.txt" )) -client "OK" -solution "FIN" -errorlog -Verbose

#Pipeline examples
'APP100001' | Get-NetworkInfo -client "OK" -solution "FIN" -errorlog
'APP100001', 'APP100002' | Get-NetworkInfo -client "OK" -solution "FIN" -errorlog -Verbose
'APP100001', 'APP100002' | Select-Object @{label="computers";expression={$_}} | Get-NetworkInfo -client "OK" -solution "FIN" -errorlog
Get-Content( "$home\Documents\WindowsPowerShell\Modules\01servers\OKFINservers.txt" ) | Get-NetworkInfo -client "OK" -solution "FIN" -errorlog -Verbose
'ERROR' | Get-NetworkInfo -client "OK" -solution "FIN" -errorlog

#Test CmdLet help
Help Get-NetworkInfo -Full

#SaveToExcel
Get-NetworkInfo -filename "OKFINservers.txt" -errorlog -client "OK" -solution "FIN" -Verbose | Select-Object 'Environment', 'Logical name', 'Server name', 'Product name', 'Name', 'Manufacturer', 'Physical adapter', 'Speed', 'MAC Address', 'GUID', 'Adapter type', 'Description', 'Device ID', 'Net connection ID', 'Net connection status', 'Net enabled', 'Service name', 'Status', 'Status info', 'IP', 'Collected' | Save-ToExcel -errorlog -ExcelFileName "Get-NetworkInfo" -title "Get Network adapters info of servers in Financial solution for " -author "Dejan Mladenovic" -WorkSheetName "Network adapters Info" -client "OK" -solution "FIN" 
#SaveToExcel and send email
Get-NetworkInfo -filename "OKFINservers.txt" -errorlog -client "OK" -solution "FIN" -Verbose | Select-Object 'Environment', 'Logical name', 'Server name', 'Product name', 'Name', 'Manufacturer', 'Physical adapter', 'Speed', 'MAC Address', 'GUID', 'Adapter type', 'Description', 'Device ID', 'Net connection ID', 'Net connection status', 'Net enabled', 'Service name', 'Status', 'Status info', 'IP', 'Collected' | Save-ToExcel -sendemail -errorlog -ExcelFileName "Get-NetworkInfo" -title "Get Network adapters info of servers in Financial solution for " -author "Dejan Mladenovic" -WorkSheetName "Network adapter Info" -client "OK" -solution "FIN" 

#Benchmark
#Time = 52; Total Items = 46
Measure-BenchmarksCmdLet { Get-NetworkInfo -filename "OKFINservers.txt" -errorlog -client "OK" -solution "FIN" -Verbose }
#Time = 52 sec; Total Items = 46
Measure-BenchmarksCmdLet { Get-NetworkInfo -filename "OKFINservers.txt" -errorlog -client "OK" -solution "FIN" }

#Baseline create
Get-NetworkInfo -filename "OKFINservers.txt" -errorlog -client "OK" -solution "FIN" -Verbose | Save-Baseline -errorlog -BaselineFileName "Get-NetworkInfo" -client "OK" -solution "FIN" -Verbose
#Baseline archive and create new
Get-NetworkInfo -filename "OKFINservers.txt" -errorlog -client "OK" -solution "FIN" -Verbose | Save-Baseline -archive -errorlog -BaselineFileName "Get-NetworkInfo"  -client "OK" -solution "FIN" -Verbose

#Test ParameterSet = FileName
Get-NetworkInfo -filename "OKFINservers.txt" -errorlog -client "OK" -solution "FIN" -Verbose
Get-NetworkInfo -filename "OKFINserverss.txt" -errorlog -client "OK" -solution "FIN" -Verbose
#>
#endregion