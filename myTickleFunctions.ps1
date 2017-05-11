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
    SIZE = 100mb,
    MAXSIZE = 200,
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
else {
    $data 
}

Write-Verbose "[$((Get-Date).TimeofDay)] Ending $($myinvocation.mycommand)"

} #Get-TickleEvent

Function Set-TickleEvent {

[cmdletbinding(SupportsShouldProcess,DefaultParameterSetName="Inputobject")]
Param(
[Parameter(Position=0,Mandatory,HelpMessage="Enter the tickle event id",ParameterSetName="ID")]
[int]$Id,
[Parameter(Position=1,ValueFromPipeline,ParameterSetname="Inputobject")]
[object]$Inputobject,
[datetime]$Date,
[string]$Event,
[string]$Comment,
[ValidateScript({Test-Path $_} )]
[string]$Path=$TicklePath,
[switch]$Passthru
)
Begin {
    Write-Verbose "Using $($PSCmdlet.ParameterSetName) parameter set"
}
Process {

#if ID only then get event from CSV
Switch ($pscmdlet.ParameterSetName) {
 "ID" {
    Write-Verbose "Getting tickle event id $ID"
    $myevent = Get-TickleEvent -id $id
   }
 "Inputobject" {
    Write-Verbose "Modifying inputobject"
    $myevent = $Inputobject
 }
} #switch

#verify we have an event to work with
if ($myevent) {
    #modify the tickle event object
    Write-Verbose ($myevent | out-string)
    
    if ($Date) {
      Write-Verbose "Setting date to $date"
      $myevent.date = $Date
    }
    if ($Event) {
      Write-Verbose "Setting event to $event"
      $myevent.event = $Event
    }
    if ($comment) {
      Write-verbose "Setting comment to $comment"
      $myevent.comment = $comment
    }
    Write-Verbose "Revised: $($myevent | out-string)"

    #find all lines in the CSV except the matching event
    $otherevents = Get-Content -path $Path | where {$_ -notmatch "^""$($myevent.id)"} 
    #remove it
    $otherevents | Out-File -FilePath $Path -Encoding ascii 
   
    #append the revised event to the csv file
    $myevent | Export-Csv -Path $Path -Encoding ASCII -Append -NoTypeInformation

    if ($passthru) {
        $myevent
    }
}
else {
    Write-Warning "Failed to find a valid tickle event"
}

} #process

} #Set-TickleEvent

Function Remove-TickleEvent {

[cmdletbinding(SupportsShouldProcess,DefaultParameterSetName="Inputobject")]
Param(
[Parameter(Position=0,Mandatory,HelpMessage="Enter the tickle event id",ParameterSetName="ID")]
[int]$Id,
[Parameter(Position=1,ValueFromPipeline,ParameterSetname="Inputobject")]
[object]$Inputobject,
[ValidateScript({Test-Path $_} )]
[string]$Path=$TicklePath
)

Process {
    #if ID only then get event from CSV
    Switch ($pscmdlet.ParameterSetName) {
     "ID" {
        Write-Verbose "Getting tickle event id $ID"
        $myevent = Get-TickleEvent -id $id
       }
     "Inputobject" {
        Write-Verbose "Identifying inputobject"
        $myevent = $Inputobject
     }
    } #switch

    #verify we have an event to work with
    if ($myevent) {
        Write-Verbose "Removing event"
        Write-Verbose ($myEvent | Out-String)
        if ($pscmdlet.ShouldProcess(($myEvent | Out-String))) {
        #find all lines in the CSV except the matching event
        $otherevents = Import-CSV -Path $path | Where {$_.id -ne $myevent.id}
        #Get-Content -path $Path | where {$_ -notmatch "^$($myevent.id),"} 
        #remove it
        $otherevents | Export-CSV -Path $Path -Encoding ASCII -NoTypeInformation
        #Out-File -FilePath $Path -Encoding ascii 
        }
    } #if myevent

} #process

} #Remove-TickleEvent

Function Show-TickleEvent {

[cmdletbinding()]
Param(
[Parameter(Position=0)]
[ValidateScript({Test-Path $_})]
[string]$Path = $TicklePath,
[Parameter(Position=1)]
[ValidateScript({$_ -ge 1})]
[int]$Days = $TickleDefaultDays
)

#import events from CSV file
$events = Import-Csv -Path $Path

#get upcoming events within the value for $Days sorted by date
$upcoming = $events | 
where {
 #get the timespan between today and the event date
 $ts = (New-TimeSpan -Start (Get-Date) -end $_.Date).TotalHours 
 #find events less than the default days value and greater than 0
 Write-Verbose $ts
 $ts -le ($Days*24) -AND $ts -gt 0
 } |
Add-Member -MemberType ScriptProperty -Name Countdown -value {New-TimeSpan -start (Get-Date) -end $this.date} -PassThru -force |
sort CountDown

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

} #Show-TickleEvent

Function Backup-TickleFile {

[cmdletbinding(SupportsShouldProcess)]
Param(
[ValidateScript({Test-Path $_} )]
[string]$Path=$TicklePath,
[ValidateScript({Test-Path $_} )]
[string]$Destination = (Split-Path $TicklePath),
[switch]$Passthru
)

Try {
    $ticklefile = Get-Item -Path $path
    $backup = Join-Path -path $Destination -ChildPath "$($ticklefile.basename).bak"
    Write-Verbose "Copying $path to $backup"
    $ticklefile | Copy-Item  -Destination $backup -ErrorAction Stop -PassThru:$Passthru
}
Catch {
    Write-Warning "Failed to backup file"
    Write-Warning $_.exception.message
}

} #Backup-TickleFile

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