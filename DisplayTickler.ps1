#requires -version 3.0

$profileDir = Split-Path $profile
$csvPath = Join-Path -Path $profileDir -ChildPath "mytickler.csv"

$events = import-csv $csvpath

#get upcoming events within 7 days sorted by date
$upcoming = $events | 
where { (New-TimeSpan -Start (Get-Date) -end $_.Date).Days -gt 10000 } |
Add-Member -MemberType Scriptproperty -Name Countdown -value {New-TimeSpan -start (Get-Date) -end $this.date} -PassThru -force|
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

$header="* Reminders "

#display events
Write-host "$($header.padright($width,"*"))" -ForegroundColor Cyan

foreach ($event in $upcoming) {
     
  if ($event.countdown.totalhours -le 24) {
    $color = "Red"
  }
  else {
    $color = "Green"
  }
     
  #define the message string
  $line1 = "* $($event.event) $($event.Date) [$($event.time)]"
  $line2 = "* $($event.Comment)"
  $line3 = "*"

$msg = @"
$($line1.padRight($width-1))*
$($line2.padright($width-1))*
$($line3.padright($width-1))*
"@

  Write-Host $msg -ForegroundColor $color

 } #foreach
 Write-host ("*"*$width) -ForegroundColor Cyan
} #if upcoming
else {
  $msg = @"
**********************
* No event reminders *
**********************
"@
  Write-host $msg -foregroundcolor Cyan
}

