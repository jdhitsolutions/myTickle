#requires -version 5.0

#dot source module functions
. $PSScriptRoot\myTickleFunctions.ps1

#region Define module variables

#the default number of days to display for Show-TickleEvents
$TickleDefaultDays = 7 

#database defaults
$TickleDB = 'TickleEventDB'
$TickleTable = 'EventData'
$TickleServerInstance = ".\SqlExpress"

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

Set-Alias -Name gte -Value Get-TickleEvent
Set-Alias -name ate -Value Add-TickleEvent
Set-Alias -name rte -Value Remove-TickleEvent
Set-Alias -name ste -Value Set-TickleEvent
Set-Alias -name shte -Value Show-TickleEvent

#endregion

$export = @{
    Variable = 'TickleDefaultDays','TickleDB','TickleTable','TickleServerInstance' 
    Alias = 'gte','ate','rte','shte','ste' 
}
Export-ModuleMember @export

<#
function = 'Get-TickleEvent','Set-TickleEvent','Add-TickleEvent',
'Remove-TickleEvent','Show-TickleEvent','Initialize-TickleDatabase',
'Export-TickleDatabase','Import-TickleDatabase'
#>