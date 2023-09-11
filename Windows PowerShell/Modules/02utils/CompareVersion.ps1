<#
.SYNOPSIS
Compare between baseline in XML file and current state of objects.
.DESCRIPTION
Compare between baseline in XML file and current state of objects.

The Compare-Version cmdlet compares two sets of objects. One set of objects is the "reference set," and the other set is the "difference set."

reference set is xml file that we have created in ..\Documents\PSbaselines\ folder running Save-Baseline cmdlet and represents snapshot or baseline of objects properties at some point in time.

difference set is current state of objects property values. 

Basically we compare snapshot taken in the past used as our baseline against current status and want to see the differance between them.


The result of the comparison indicates whether a property value appeared only in the object from the reference set (indicated by the <= symbol), only in the object from the difference set (indicated by the
    => symbol) or, if the IncludeEqual parameter is specified, in both objects (indicated by the == symbol).


Explanation - Result of comparation:
===============================================


Deleted objects
<=


New objects
=>


Updated objects

Equal objects


.PARAMETER Compare
Script block that will be passed as parameter and used for comparation.
.PARAMETER errorlog
write to log or not.
.EXAMPLE
Compare-Version -errorlog -Compare { Compare-Object -ReferenceObject ( Import-Clixml "$home\Documents\PSbaselines\Get-AllWindowsServices-OK-FIN.xml" ) -DifferenceObject (Get-AllWindowsServices -client "OK" -solution "FIN" -errorlog) -Property IP, "Service name", Status, "Start mode", Started, "Start name", "Accept pause", "Accept stop" -PassThru | Sort-Object -Property IP, "Service name", Collected | Select-Object SideIndicator, Environment, "Logical Name", "Server name", IP, "Service name", "Process Id", "Path name", Status, Collected, "Start mode", Started, "Start name", "Accept pause", "Accept stop", Description, Caption, "Display name" } | Out-GridView

Description
---------------------------------------
Compare diff of windows services on local server between baseline in XML file and current state of windows services.

.INPUTS
System.Management.Automation.PSCustomObject

InputObject parameter pipeline by value. 
.OUTPUTS
System.Boolen

.NOTES
FunctionName : Compare-Version
Created by   : Dejan Mladenovic
Date Coded   : 10/31/2018 19:06:41
More info    : https://improvescripting.com/

.LINK 
https://improvescripting.com/how-to-import-xml-file-in-powershell
Import-Clixml
Export-Clixml
Compare-Object
#>
Function Compare-Version {
[CmdletBinding()]
param (
    [Parameter(Mandatory=$true,
                HelpMessage="Path to XML baseline file name. Used as Reference object.")] 
    [ScriptBlock]$Compare,
    
    [Parameter(HelpMessage="Write to error log file or not.")]
    [switch]$errorlog
)
BEGIN { 
    
}
PROCESS { 

}
END { 


    try {
        
        Write-Verbose "Begin compare between baseline and objects."
        $obj = Invoke-Command -ScriptBlock $Compare -ErrorAction Stop
        Write-Output $obj        
        Write-Verbose "Objects compared against baseline: $obj"
        
    } catch {
        Write-Warning "Compare-Version function failed"
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
            Write-ErrorLog -hostname "Compare-Version has failed" -errormsg $errormsg -exception $exception -scriptname $scriptname -failinglinenumber $failinglinenumber -failingline $failingline -pscommandpath $pscommandpath -positionmsg $pscommandpath -stacktrace $stacktrace
            Write-Verbose "Finish writing to Error log."
        } 
    } 
}


}
#region Execution examples
#Differance from baseline
<#
Compare-Version -errorlog -Compare { Compare-Object -ReferenceObject ( Import-Clixml "$home\Documents\PSbaselines\Get-AllWindowsServices-OK-FIN.xml" ) -DifferenceObject (Get-AllWindowsServices -filename "OKFINservers.txt" -errorlog -client "OK" -solution "FIN") -Property IP, "Service name", Status, "Start mode", Started, "Start name", "Accept pause", "Accept stop" -PassThru | Sort-Object -Property IP, "Service name" | Select-Object * } | Save-ToExcel -sendemail -errorlog -ExcelFileName "DFB-GetAllWindowsServices" -title "Diff from baseline Get all windows services info of servers in Financial solution for " -author "DJ PowerScript" -WorkSheetName "DFB - All windows services" -client "OK" -solution "FIN" 
Compare-Version -errorlog -Compare { Compare-Object -ReferenceObject ( Import-Clixml "$home\Documents\PSbaselines\Get-AllWindowsServices-OK-FIN.xml" ) -DifferenceObject (Get-AllWindowsServices -client "OK" -solution "FIN" -errorlog) -Property IP, "Service name", Status, "Start mode", Started, "Start name", "Accept pause", "Accept stop" -PassThru | Sort-Object -Property IP, "Service name" | Select-Object * } | Save-ToExcel -sendemail -errorlog -ExcelFileName "DFB-GetAllWindowsServices" -title "Diff from baseline Get all windows services info of servers in Financial solution for " -author "DJ PowerScript" -WorkSheetName "DFB - All windows services" -client "OK" -solution "FIN" 
Compare-Version -errorlog -Compare { Compare-Object -ReferenceObject ( Import-Clixml "$home\Documents\PSbaselines\Get-AllWindowsServices-OK-FIN.xml" ) -DifferenceObject (Get-AllWindowsServices -client "OK" -solution "FIN" -errorlog) -Property IP, "Service name", Status, "Start mode", Started, "Start name", "Accept pause", "Accept stop" -PassThru | Sort-Object -Property IP, "Service name" | Select-Object * } | Out-GridView
Compare-Version -errorlog -Compare { Compare-Object -ReferenceObject ( Import-Clixml "$home\Documents\PSbaselines\Get-AllWindowsServices-OK-FIN.xml" ) -DifferenceObject (Get-AllWindowsServices -client "OK" -solution "FIN" -errorlog) -Property IP, "Service name", Status, "Start mode", Started, "Start name", "Accept pause", "Accept stop" -PassThru | Sort-Object -Property IP, "Service name", Collected | Select-Object SideIndicator, Environment, "Logical Name", "Server name", IP, "Service name", "Process Id", "Path name", Status, Collected, "Start mode", Started, "Start name", "Accept pause", "Accept stop", Description, Caption, "Display name" } | Out-GridView
Compare-Version -errorlog -Compare { Compare-Object -ReferenceObject ( Import-Clixml "$home\Documents\PSbaselines\Get-AllWindowsServices-OK-FIN.xml" ) -DifferenceObject (Get-AllWindowsServices -client "OK" -solution "FIN" -errorlog) -Property "Service name", Status, "Start mode", Started, "Start name", "Accept pause", "Accept stop" -PassThru | Sort-Object -Property "Service name", Collected | Select-Object SideIndicator, Environment, "Logical Name", "Server name", "Service name", "Process Id", "Path name", Status, Collected, "Start mode", Started, "Start name", "Accept pause", "Accept stop", Description, Caption, "Display name" } | Out-GridView
#>
#endregion