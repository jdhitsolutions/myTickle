

#dot source module functions
. $PSScriptRoot\functions\private.ps1
. $PSScriptRoot\functions\public.ps1

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
    myTickle([int32]$ID, [string]$Event, [datetime]$Date, [string]$Comment) {
        $this.ID = $ID
        $this.Event = $Event
        $this.Date = $Date
        $this.Comment = $Comment
        if ($Date -lt (Get-Date)) {
            $this.Expired = $True
        }
        $ts = $this.Date - (Get-Date)
        if ($ts.totalminutes -lt 0) {
            $ts = New-TimeSpan -Minutes 0
        }
        $this.Countdown = $ts
    }
} #close class

Update-TypeData -TypeName myTickle -DefaultDisplayPropertySet ID, Date, Event, Comment -Force

#endregion

$export = @{
    Variable = 'TickleDefaultDays', 'TickleDB', 'TickleTable', 'TickleServerInstance'
    Alias    = 'gte', 'ate', 'rte', 'shte', 'ste'
    Function = 'Get-TickleEvent', 'Set-TickleEvent', 'Add-TickleEvent',
    'Remove-TickleEvent', 'Initialize-TickleDatabase',
    'Export-TickleDatabase', 'Import-TickleDatabase','Show-TickleEvent','Get-TickleDBInformation'
}
Export-ModuleMember @export
