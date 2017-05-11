#requires -version 5.0

#region Define module functions

Function Initialize-TickleDatabase {
    [cmdletbinding(SupportsShouldProcess)]
    Param(
        [Parameter(Position = 0)]
        #Enter the folder path for the database file.
        [string]$DatabasePath,
        #Enter the name of the SQL Server instance
        [string]$ServerInstance = "$($env:COMPUTERNAME)\SqlExpress"
    )
    Begin {
        Write-Verbose "[$((Get-Date).TimeofDay) BEGIN  ] Starting $($myinvocation.mycommand)"

        #Enter the filename for the database file using the module variable
        $DatabaseName = $TickleDB
        $dbpath = Join-Path -Path $DatabasePath -ChildPath "$Databasename.mdf"
        $newDB = @"
CREATE DATABASE $DatabaseName
ON PRIMARY
    (FILENAME = '$dbpath',
    NAME = TickleEvents,
    SIZE = 10mb,
    MAXSIZE = 100,
    FILEGROWTH = 20
    )
"@

    $newTable = @"
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[EventData](
	[EventID] [int] IDENTITY(100,1) NOT NULL,
	[EventDate] [datetime2](7) NOT NULL,
	[EventName] [nvarchar](50) NOT NULL,
	[EventComment] [nvarchar](50) NULL,
	[Archived] [bit] NULL
) ON [PRIMARY]

ALTER TABLE [dbo].[EventData] ADD CONSTRAINT [DF_EventData_Archived]  DEFAULT (N'0') FOR [Archived]

"@

    } #begin

    Process {
        if (Test-Path -path $dbpath) {
            Write-Warning "A file was already found at $dbpath. Initialization aborted."
            #bail out if the database file already exists
            return
        }
        Write-Verbose "[$((Get-Date).TimeofDay) PROCESS] Creating Database file $dbpath"
        Write-Verbose "[$((Get-Date).TimeofDay) PROCESS] Connect to $ServerInstance"
        if ($PSCmdlet.ShouldProcess($dbpath)) {
            #create the database
            Try {
                Invoke-Sqlcmd -query $newDB -ServerInstance $ServerInstance -ErrorAction stop
            }
        Catch {
            Throw $_
        }
        
        #create the table
        Try {
            Write-Verbose "[$((Get-Date).TimeofDay) PROCESS] Creating table EventData"
            Invoke-Sqlcmd -query $newTable -ServerInstance $ServerInstance -Database $DatabaseName -ErrorAction Stop
        }
        Catch {
            Throw $_
        }
        Write-Host "Database inialization complete." -ForegroundColor Green
        } #if should process
    } #process

    End {
        Write-Verbose "[$((Get-Date).TimeofDay) END    ] Ending $($myinvocation.mycommand)"

    } #end 

} #close Initialize-TickleDatabase

Function Add-TickleEvent {
    [cmdletbinding(SupportsShouldProcess)]
    Param(
        [Parameter(Position=0,ValueFromPipelineByPropertyName,Mandatory,HelpMessage="Enter the name of the event")]
        [string]$Event,
        [Parameter(Position=1,ValueFromPipelineByPropertyName,Mandatory,HelpMessage="Enter the datetime for the event")]
        [ValidateScript({
        If ($_ -gt (Get-Date)) {
            $True
        }
        else {
            Throw "You must enter a future date and time."
        }
        })]
        [datetime]$Date,
        [Parameter(Position=2,ValueFromPipelineByPropertyName)]
        [string]$Comment,
        #Enter the name of the SQL Server instance
        [ValidateNotNullOrEmpty()]
        [string]$ServerInstance = "$($env:COMPUTERNAME)\SqlExpress",
        [switch]$Passthru
    )
    Begin {
        Write-Verbose "[$((Get-Date).TimeofDay) BEGIN  ] Starting $($myinvocation.mycommand)"
        $invokeParams = @{
            Query = $null
            ServerInstance = $ServerInstance
            Database = $TickleDB
            ErrorAction = 'Stop'
        }
    } #begin

    Process {
        Write-Verbose "[$((Get-Date).TimeofDay) PROCESS] Adding event '$event'"
        #events with apostrophes will have them stripped off
        $theEvent = $Event.replace("'",'')
        $InvokeParams.query = "INSERT INTO EventData (EventDate,EventName,EventComment) VALUES ('$Date','$theEvent','$Comment')"
        
        $short= "[$Date] $Event"
        if ($PSCmdlet.ShouldProcess($short)) {
            Try {
                Write-Verbose "[$((Get-Date).TimeofDay) PROCESS] $($invokeparams.query)"
                Invoke-Sqlcmd @invokeParams
            }
            Catch {
                throw $_
            }

            if ($passthru) {
                #TODO - change this to use the Get-TickleEvent function when completed
                $query = "Select Top 1 * from EventData Order by EventID Desc"
                Invoke-Sqlcmd -query $query -ServerInstance $ServerInstance -Database $tickleDB -ErrorAction stop | _NewMyTickle

            } #if passthru
        } #if should process

    } #process

    End {
        Write-Verbose "[$((Get-Date).TimeofDay) END    ] Ending $($myinvocation.mycommand)"

    } #end 

} #close Add-TickleEvent

Function Get-TickleEvent {

[cmdletbinding(DefaultParameterSetname="Default")]

Param(
[Parameter(Position=0,ParameterSetName="ID")]
[int[]]$Id,
[Parameter(Position=0,ParameterSetName="Name")]
[string]$Name,
[Parameter(Position=0,ParameterSetName="Days")]
[int32]$Days,
[Parameter(Position=0,ParameterSetName="All")]
[switch]$All,
[Parameter(Position=0,ParameterSetName="Expired")]
[switch]$Expired,
[ValidateScript({$_ -gt 0})]
[Parameter(ParameterSetName="Default")]
[int]$Next,
#Enter the name of the SQL Server instance
[ValidateNotNullOrEmpty()]
[string]$ServerInstance = "$($env:COMPUTERNAME)\SqlExpress"
)

Write-Verbose "[$((Get-Date).TimeofDay)] Starting $($myinvocation.mycommand)"
Write-Verbose "[$((Get-Date).TimeofDay)] Importing events from $TickleDB on $ServerInstance"

$invokeParams = @{
    Query = $null
    Database = $TickleDB
    ServerInstance = $ServerInstance
    ErrorAction = "Stop"
}
Switch ($pscmdlet.ParameterSetName) {
 "ID"      {
            Write-Verbose "[$((Get-Date).TimeofDay)] by ID" 
            $filter = "Select * from EventData where EventID='$ID'"
            }
 "Name"    { 
            Write-Verbose "[$((Get-Date).TimeofDay)] by Name"
            $filter = "Select * from EventData where EventName='$Name'"
 }
 "Days"  {
            Write-Verbose "[$((Get-Date).TimeofDay)] for the next $Days days"
            $target = (Get-Date).Date.AddDays($Days).toString()
            $filter = "Select * from EventData where Archived='False' AND EventDate<='$target' ORDER by EventDate Asc"
 }
 "Expired" { 
            Write-Verbose "[$((Get-Date).TimeofDay)] by Expiration"
            $filter = "Select * from EventData where EventDate<'$(Get-Date)' ORDER by EventDate Asc"
 }
 "All"     { 
            Write-Verbose "[$((Get-Date).TimeofDay)] All"
            $filter = "Select * from EventData where Archived='False' ORDER by EventDate Asc"
 }
  Default {
            Write-Verbose "[$((Get-Date).TimeofDay)] Default"
            $filter = "Select * from EventData where Archived='False' AND EventDate>='$(Get-Date)' ORDER by EventDate Asc"
          }
} #switch

#Query database for matching events
Write-Verbose "[$((Get-Date).TimeofDay)] $filter"
$invokeParams.query = $filter

Try {
    $events = Invoke-SqlCmd @invokeParams
    #convert the data into mytickle objects
    $data = $events | _NewMyTickle
    # foreach {
    #    New-object -TypeName mytickle -ArgumentList @($_.eventID,$_.eventname,$_.eventDate,$_.comment)
    #}
}
Catch {
    Throw $_
}

Write-Verbose "[$((Get-Date).TimeofDay)] Found $($events.count) matching events"

if ($Next) {
    Write-Verbose "[$((Get-Date).TimeofDay)] Displaying next $next events"
    $data | Select-Object -first $Next
}
elseif ($Days) {
    $data | Where {$_.countdown.totaldays -ge 0 -AND $_.countdown.totaldays -le $Days}
}
else {
    $data 
}

Write-Verbose "[$((Get-Date).TimeofDay)] Ending $($myinvocation.mycommand)"

} #Get-TickleEvent

Function Set-TickleEvent  {
    [cmdletbinding(SupportsShouldProcess,DefaultParameterSetname = "column")]
    Param(
        [Parameter(Position = 0,ValueFromPipelineByPropertyName,Mandatory)]
        [int32]$ID,
        [Parameter(ParameterSetName = "column")]
        [string]$Event,
        [Parameter(ParameterSetName = "column")]
        [datetime]$Date,
        [Parameter(ParameterSetName = "column")]
        [string]$Comment,
        #Enter the name of the SQL Server instance
        [ValidateNotNullOrEmpty()]
        [string]$ServerInstance = "$($env:COMPUTERNAME)\SqlExpress",
        [switch]$Passthru,
        [Parameter(ParameterSetName = "archive")]
        [switch]$Archive
    )
    Begin {
        Write-Verbose "[$((Get-Date).TimeofDay) BEGIN  ] Starting $($myinvocation.mycommand)"

        $update = @"
UPDATE EventData
SET {0} Where EventID='{1}'
"@

    } #begin

    Process {
        Write-Verbose "[$((Get-Date).TimeofDay) PROCESS] Updating Event ID $ID "
        $cols = @()
        if ($pscmdlet.ParameterSetName -eq 'column') {
            if ($Event) {
                $cols+="EventName='$Event'"
            }
            if ($Comment) {
                $cols+="EventComment='$Comment'"
            }
            if ($Date) {
                $cols+="EventDate='$Date'"
            }
        }
    else {
            Write-Verbose "[$((Get-Date).TimeofDay) PROCESS] Archiving"
            $cols+="Archived='True'"
        }
        $data = $cols -join ","

        $query = $update -f $data,$ID
        if ($PSCmdlet.ShouldProcess($query)) {
            Invoke-Sqlcmd -query $query -Database $TickleDB -ServerInstance $ServerInstance -ErrorAction stop
            if ($Passthru) {
                Get-TickleEvent -id $ID
            }
        }

    } #process

    End {
        Write-Verbose "[$((Get-Date).TimeofDay) END    ] Ending $($myinvocation.mycommand)"

    } #end 

} #close Update-MyTickleEvent 

Function Remove-TickleEvent {
    [cmdletbinding(SupportsShouldProcess)]
    Param(
        [Parameter(Position = 0, Mandatory,ValueFromPipelineByPropertyName)]
        [int32]$ID,
        #Enter the name of the SQL Server instance
        [ValidateNotNullOrEmpty()]
        [string]$ServerInstance = "$($env:COMPUTERNAME)\SqlExpress"
    )
    Begin {
        Write-Verbose "[$((Get-Date).TimeofDay) BEGIN  ] Starting $($myinvocation.mycommand)"
        $invokeParams = @{
            Query = $null
            ServerInstance = $ServerInstance
            Database = $tickleDB
            ErrorAction = "Stop"
        }
    } #begin

    Process {
        Write-Verbose "[$((Get-Date).TimeofDay) PROCESS] Deleting tickle event $ID "
        $invokeParams.query = "DELETE From EventData where EventID='$ID'"
        if ($PSCmdlet.ShouldProcess("Event ID $ID")) {
            Try {
                Invoke-Sqlcmd @invokeParams
            }
            Catch {
                Throw $_
            }
        } #should process
    } #process

    End {
        Write-Verbose "[$((Get-Date).TimeofDay) END    ] Ending $($myinvocation.mycommand)"

    } #end 

} #close Remove-TickleEvent

Function Show-TickleEvent {
    [cmdletbinding()]
    Param(
    [ValidateScript({$_ -ge 1})]
    #the next number of days to get
    [int]$Days = $TickleDefaultDays,
    #Enter the name of the SQL Server instance
    [ValidateNotNullOrEmpty()]
    [string]$ServerInstance = "$($env:COMPUTERNAME)\SqlExpress"
    )

    Begin {
        Write-Verbose "[$((Get-Date).TimeofDay) BEGIN  ] Starting $($myinvocation.mycommand)"
        
    } #begin

    Process {
        Write-Verbose "[$((Get-Date).TimeofDay) PROCESS] Getting events for the next $Days days."
        Try {
            $upcoming = Get-TickleEvent -Days $Days -ServerInstance $ServerInstance -ErrorAction Stop
        }
        Catch {
            Throw $_
        }
        if ($upcoming) {         
        #how wide should the box be?
        #get the length of the longest line
        $l = 0
        foreach ($item in $upcoming) {
            #turn countdown into a string without the milliseconds
            $count = $item.countdown.ToString()
            $time = $count.Substring(0,$count.lastindexof("."))
            #add the time as a new property
            $item | Add-Member -MemberType Noteproperty -name Time -Value $time
            $a = "$($item.event) $($item.Date) [$time]".length
            if ($a -gt $l) {$l = $a}
            $b = $item.comment.Length
        
           if ($b -gt $l) {$l = $b}
        }

        [int]$width = $l+5

        $header="* Reminders $((Get-Date).ToShortDateString()) "

        #display events
        Write-Host "`r"
        Write-host "$($header.padright($width,"*"))" -ForegroundColor Cyan
        Write-Host "*$(' '*($width-2))*" -ForegroundColor Cyan

    foreach ($event in $upcoming) {
        
        if ($event.countdown.totalhours -le 24) {
            $color = "Red"
        }
        elseif ($event.countdown.totalhours -le 48) {
            $color = "Yellow"
        }
        else {
            $color = "Green"
        }
        
        #define the message string
        $line1 = "* $($event.event) $($event.Date) [$($event.time)]"
        if ($event.comment -match "\w+") {
            $line2 = "* $($event.Comment)"
            $line3 = "*"
        }
        else {
            $line2 = "*"
            $line3 = $null
        }
    
    $msg = @"
$($line1.padRight($width-1))*
$($line2.padright($width-1))*
"@

    if ($line3) {
        #if there was a comment add a third line that is blank
        $msg+="`n$($line3.padright($width-1))*"
    }

    Write-Host $msg -ForegroundColor $color

    } #foreach

    Write-Host ("*"*$width) -ForegroundColor Cyan
    Write-Host "`r"
    } #if upcoming events found
    else {
    $msg = @"

    **********************
    * No event reminders *
    **********************

"@
    Write-Host $msg -foregroundcolor Green
    }
        
    } #process

    End {
        Write-Verbose "[$((Get-Date).TimeofDay) END    ] Ending $($myinvocation.mycommand)"

    } #end 

} #close Show-TickleEvent

#endregion

#region private functions

function _NewMyTickle {
[cmdletbinding()]
Param(
    [Parameter(ValueFromPipelineByPropertyName)]
    [int32]$EventID,
    [Parameter(ValueFromPipelineByPropertyName)]
    [string]$EventName,
    [Parameter(ValueFromPipelineByPropertyName)]
    [datetime]$EventDate,
    [Parameter(ValueFromPipelineByPropertyName)]
    [string]$EventComment
)
Process {
    New-Object -TypeName mytickle -ArgumentList @($eventID,$Eventname,$EventDate,$EventComment)
}
}

#endregion