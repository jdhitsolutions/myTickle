#requires -version 4.0

<#
TODO: ADD CUSTOM TYPE AND FORMAT EXTENSIONS
Convert to XML format to make it easier to preserve type
update file to set a new Expired property

$myclass = "my.tickle"

Update-TypeData -TypeName $myClass -MemberName "ID" -MemberType ScriptProperty -Value {$this.id -as [int]} -SerializationMethod AllPublicProperties -force
Update-TypeData -TypeName $myClass -MemberName "Date" -MemberType ScriptProperty -Value {$this.date -as [datetime]} -SerializationMethod AllPublicProperties -force 
Update-TypeData -TypeName $myClass -MemberName "Expired" -MemberType ScriptProperty -Value {$this.Expired -as [boolean]} -SerializationMethod AllPublicProperties -force 


MYTICKLE.PSM1
Last updated June 17, 2015

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


#region Define module variables
#This should be the WindowsPowerShell folder under your Documents folder
$profileDir = Split-Path $profile

#the path to the tickle csv file
$TicklePath = Join-Path -Path $profileDir -ChildPath "mytickler.csv"

#the default number of days to display for Show-TickleEvents
$TickleDefaultDays = 7 

#endregion

#region Define module functions

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
[ValidateScript({Test-Path $_} )]
[string]$Path = $TicklePath
)

Write-Verbose "Importing events from $Path"

Switch ($pscmdlet.ParameterSetName) {
 "ID"      {
            Write-Verbose "by ID" 
            $filter = [scriptblock]::Create("`$_.id -in `$id")  }
 "Name"    { 
            Write-Verbose "by Name"
            $filter = [scriptblock]::Create("`$_.Event -like `$Name") }
 "Expired" { 
            Write-Verbose "by Expiration"
            $filter = [scriptblock]::Create("`$_.Date -lt (Get-Date)") }
 "All"     { 
            Write-Verbose "All"
            $filter = [scriptblock]::Create("`$_ -match '\w+'") }
  Default {
            Write-Verbose "Default"
            $filter = [scriptblock]::Create("`$_ -match '\w+' -AND `$_.Date -gt (Get-Date)")
          }
} 

#import CSV and cast properties to correct type
$events = Import-CSV -Path $Path | 
Select-Object -property @{Name="ID";Expression={[int]$_.ID}},
@{Name="Date";Expression={[datetime]$_.Date}},
Event,Comment | where $Filter | Sort Date

Write-Verbose "Found $($events.count) matching events"
if ($Next) {
    $events | Select-Object -first $Next
}
else {
    $events 
}

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

Function Add-TickleEvent {

[cmdletbinding(SupportsShouldProcess)]

Param (
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
[ValidateNotNullorEmpty()]
[string]$Path=$TicklePath,
[switch]$Passthru
)

Begin {
    #verify the path and create the file if not found
    if (! (Test-Path $Path)) {
        Write-Verbose "Creating a new file: $Path"
        Try {
         '"id","Date","Event","Comment"' | 
         Out-File -FilePath $Path -Encoding ascii -ErrorAction Stop
        }
        Catch {
            Write-Warning "Failed to create $Path"
            Write-Warning $_.Exception.Message
            $NoFile = $True
        }
    }
}

Process {
    if ($NoFile) {
        Write-Verbose "No CSV file found."
        #bail out of the command
        Return
    }

    #get last id and add 1 to it
    [int]$last = Import-Csv -Path $Path | 
    Sort {$_.id -AS [int]} | Select -last 1 -expand id
    Write-Verbose "Last ID is $last"
    [int]$id = $last+1

    $hash=[ordered]@{
      ID = $id
      Date = $date
      Event = $event
      Comment = $comment
    }

    Write-Verbose "Adding new event"
    Write-Verbose ($hash | out-string)

    $myevent = [pscustomobject]$hash
    $myevent | Export-Csv -Path $Path -Append -Encoding ASCII -NoTypeInformation

    if ($passthru) {
        #display the added event if -Passthru
        $myevent
    }

} #process

} #Add-TickleEvent

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

#region Define module aliases

Set-Alias -Name gte -value Get-TickleEvent
Set-Alias -name ate -Value Add-TickleEvent
Set-Alias -name rte -Value Remove-TickleEvent
Set-Alias -name ste -Value Set-TickleEvent
Set-Alias -name shte -Value Show-TickleEvent
Set-Alias -name btf -Value Backup-Ticklefile

#endregion

#Export-ModuleMember -Function * -Variable TicklePath,TickleDefaultDays -Alias *
