#dot source module functions
Get-ChildItem -Path $PSScriptRoot\functions\*.ps1 | ForEach-Object { . $_.FullName }

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

    [String]$Event
    [DateTime]$Date
    [String]$Comment
    [int32]$ID
    [boolean]$Expired = $False
    hidden [TimeSpan]$Countdown

    #constructor
    myTickle([int32]$ID, [String]$Event, [DateTime]$Date, [String]$Comment) {
        $this.ID = $ID
        $this.Event = $Event
        $this.Date = $Date
        $this.Comment = $Comment
        if ($Date -lt (Get-Date)) {
            $this.Expired = $True
        }
        $ts = $this.Date - (Get-Date)
        if ($ts.TotalMinutes -lt 0) {
            $ts = New-TimeSpan -Minutes 0
        }
        $this.Countdown = $ts
    }
} #close class

Update-TypeData -TypeName myTickle -DefaultDisplayPropertySet ID, Date, Event, Comment -Force
Update-TypeData -TypeName myTickle -MemberType AliasProperty -MemberName Name -Value Event -force

#endregion

$export = @{
    Variable = 'TickleDefaultDays', 'TickleDB', 'TickleTable', 'TickleServerInstance'
    Alias    = 'gte', 'ate', 'rte', 'shte', 'ste'
    Function = 'Get-TickleEvent', 'Set-TickleEvent', 'Add-TickleEvent',
    'Remove-TickleEvent', 'Initialize-TickleDatabase',
    'Export-TickleDatabase', 'Import-TickleDatabase','Show-TickleEvent','Get-TickleDBInformation'
}
Export-ModuleMember @export
