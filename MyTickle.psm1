#requires -version 5.0

<#
originally published at:
http://jdhitsolutions.com/blog/2013/05/friday-fun-a-powershell-tickler/

Learn more about PowerShell:
http://jdhitsolutions.com/blog/essential-powershell-resources/

  ****************************************************************
  * DO NOT USE IN A PRODUCTION ENVIRONMENT UNTIL YOU HAVE TESTED *
  * THOROUGHLY IN A LAB ENVIRONMENT. USE AT YOUR OWN RISK.  IF   *
  * YOU DO NOT UNDERSTAND WHAT THIS SCRIPT DOES OR HOW IT WORKS, *
  * DO NOT USE IT OUTSIDE OF A SECURE, TEST SETTING.             *
  ****************************************************************
#>

#dot source functions
. $PSScriptRoot\mytickleFunctions.ps1

#region Define module variables
#This should be the WindowsPowerShell folder under your Documents folder
#$profileDir = Split-Path $profile

#the path to the tickle csv file
#$TicklePath = Join-Path -Path $profileDir -ChildPath "mytickler.csv"

#the default number of days to display for Show-TickleEvents
$TickleDefaultDays = 7 

#database defaults

$TickleDB = 'TickleEventDB'
$TickleTable = 'EventData'

#endregion

#region Class definition

Class myTickle {

[string]$Event
[datetime]$Date
[string]$Comment
[int32]$ID
[boolean]$Expired = $False
hidden [timespan]$Countdown

#constructor
myTickle([int32]$ID,[string]$Event,[datetime]$Date,[string]$Comment) {
    $this.ID = $ID
    $this.Event = $Event
    $this.Date = $Date
    $this.Comment = $Comment
    if ($Date -lt (Get-Date)) {
        $this.Expired = $True
    }
    $this.Countdown = $this.Date - (Get-Date)
}
} #close class

Update-TypeData -TypeName myTickle -DefaultDisplayPropertySet ID,Date,Event,Comment -force

#endregion

#region Define module aliases

Set-Alias -Name gte -value Get-TickleEvent
Set-Alias -name ate -Value Add-TickleEvent
Set-Alias -name rte -Value Remove-TickleEvent
Set-Alias -name ste -Value Set-TickleEvent
Set-Alias -name shte -Value Show-TickleEvent

#endregion

