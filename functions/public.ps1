
#region Define module functions

Function Initialize-TickleDatabase {
    [cmdletbinding(SupportsShouldProcess, DefaultParameterSetName = 'default')]
    Param(
        [Parameter(Position = 0, Mandatory, HelpMessage = "Enter the folder path for the database file. If specifying a remote server the path is relative to the server." )]
        [ValidateScript( { Test-Path $_ })]
        [string]$DatabasePath,
        #Enter the name of the SQL Server instance
        [string]$ServerInstance = $TickleServerInstance,
        [Parameter(Mandatory, ParameterSetName = 'credential')]
        [pscredential]$Credential
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

SET QUOTED_IDENTIFIER ON

CREATE TABLE [$databasename].[dbo].[EventData](
	[EventID] [int] IDENTITY(100,1) NOT NULL,
	[EventDate] [datetime2](7) NOT NULL,
	[EventName] [nvarchar](50) NOT NULL,
	[EventComment] [nvarchar](50) NULL,
	[Archived] [bit] NULL
) ON [PRIMARY]

ALTER TABLE [$databasename].[dbo].[EventData] ADD CONSTRAINT [DF_EventData_Archived]  DEFAULT (N'0') FOR [Archived]

"@

    } #begin

    Process {
        if (Test-Path -Path $dbpath) {
            Write-Warning "A file was already found at $dbpath. Initialization aborted."
            #bail out if the database file already exists
            return
        }
        Write-Verbose "[$((Get-Date).TimeofDay) PROCESS] Creating Database file $dbpath"
        Write-Verbose $newDB
        Write-Verbose "[$((Get-Date).TimeofDay) PROCESS] Connect to $ServerInstance"
        if ($PSBoundParameters.ContainsKey('Databasepath')) {
            $PSBoundParameters.Remove('Databasepath') | Out-Null
        }
        #need to connect to a database
        $PSBoundParameters.add("Database", 'Master')
        $PSBoundParameters.Add("Query", $newDB)
        Write-Verbose ($PSBoundParameters | Out-String)
        if ($PSCmdlet.ShouldProcess($dbpath)) {
            #create the database
            Try {
                _InvokeSqlQuery @PSBoundParameters | Out-Null
            }
            Catch {
                Throw $_
            }
            #give SQL a chance to comnplete the action
            Start-Sleep -Seconds 2
            #create the table
            Try {
                Write-Verbose "[$((Get-Date).TimeofDay) PROCESS] Creating table EventData"
                Write-Verbose $newTable
                $PSBoundParameters.Query = $newTable
                $PSBoundParameters.Database = $DatabaseName
                Write-Verbose ($PSBoundParameters | Out-String)
                _InvokeSqlQuery @PSBoundParameters
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
    [OutputType("None", "MyTickle")]
    [Alias("ate")]

    Param(
        [Parameter(Position = 0, ValueFromPipelineByPropertyName, Mandatory, HelpMessage = "Enter the name of the event")]
        [Alias("Name")]
        [string]$EventName,
        [Parameter(Position = 1, ValueFromPipelineByPropertyName, Mandatory, HelpMessage = "Enter the datetime for the event")]
        [ValidateScript( {
                If ($_ -gt (Get-Date)) {
                    $True
                }
                else {
                    Throw "You must enter a future date and time."
                }
            })]
        [datetime]$Date,
        [Parameter(Position = 2, ValueFromPipelineByPropertyName)]
        [string]$Comment,
        #Enter the name of the SQL Server instance
        [ValidateNotNullOrEmpty()]
        [string]$ServerInstance = $TickleServerInstance,
        [ValidateNotNullOrEmpty()]
        [pscredential]$Credential,
        [switch]$Passthru
    )
    Begin {
        Write-Verbose "[$((Get-Date).TimeofDay) BEGIN  ] Starting $($myinvocation.mycommand)"
        $invokeParams = @{
            Query          = $null
            ServerInstance = $ServerInstance
            Database       = $TickleDB
            ErrorAction    = 'Stop'
        }
        if ($PSBoundParameters.ContainsKey('credential')) {
            $invokeParams.Add("credential", $Credential)
        }
    } #begin

    Process {
        Write-Verbose "[$((Get-Date).TimeofDay) PROCESS] Adding event '$EventName'"
        #events with apostrophes will have them stripped off
        $theEvent = $EventName.replace("'", '')
        $InvokeParams.query = "INSERT INTO EventData (EventDate,EventName,EventComment) VALUES ('$Date','$theEvent','$Comment')"

        $short = "[$Date] $Event"
        if ($PSCmdlet.ShouldProcess($short)) {
            Try {
                Write-Verbose "[$((Get-Date).TimeofDay) PROCESS] $($invokeparams.query)"
                _InvokeSqlQuery @invokeParams | Out-Null
            }
            Catch {
                throw $_
            }

            if ($passthru) {
                $query = "Select Top 1 * from EventData Order by EventID Desc"
                $invokeParams.query = $query
                _InvokeSqlQuery @invokeParams | _NewMyTickle
            } #if passthru
        } #if should process
    } #process

    End {
        Write-Verbose "[$((Get-Date).TimeofDay) END    ] Ending $($myinvocation.mycommand)"
    } #end

} #close Add-TickleEvent

Function Get-TickleEvent {

    [cmdletbinding(DefaultParameterSetname = "Days")]
    [OutputType("MyTickle")]
    [Alias("gte")]

    Param(
        [Parameter(ParameterSetName = "ID", ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int32]$Id,
        [Parameter(ParameterSetName = "Name", ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias("Name")]
        [string]$EventName,
        [Parameter(ParameterSetName = "All")]
        [switch]$All,
        [Parameter(ParameterSetName = "Expired")]
        [switch]$Expired,
        [Parameter(ParameterSetName = "Archived")]
        [switch]$Archived,
        [ValidateScript( { $_ -gt 0 })]
        [Parameter(ParameterSetName = "Days")]
        [Parameter(ParameterSetName = "Offline")]
        [Alias("days")]
        [int]$Next = $TickleDefaultDays,
        [Parameter(ParameterSetName = "ID")]
        [Parameter(ParameterSetName = "Archived")]
        [Parameter(ParameterSetName = "Expired")]
        [Parameter(ParameterSetName = "All")]
        [Parameter(ParameterSetName = "Days")]
        [Parameter(ParameterSetName = "Name")]
        #Enter the name of the SQL Server instance
        [ValidateNotNullOrEmpty()]
        [string]$ServerInstance = $TickleServerInstance,
        [Parameter(ParameterSetName = "ID")]
        [Parameter(ParameterSetName = "Archived")]
        [Parameter(ParameterSetName = "Expired")]
        [Parameter(ParameterSetName = "All")]
        [Parameter(ParameterSetName = "Days")]
        [Parameter(ParameterSetName = "Name")]
        [pscredential]$Credential,
        [Parameter(ParameterSetName = "Offline")]
        #Enter the path to an offline CSV file
        [ValidatePattern('\.csv$')]
        [ValidateScript( { Test-Path $_ })]
        [string]$Offline
    )

    Begin {

        Write-Verbose "[$((Get-Date).TimeofDay)] Starting $($myinvocation.mycommand)"

        $invokeParams = @{
            Query          = $null
            Database       = $TickleDB
            ServerInstance = $ServerInstance
            ErrorAction    = "Stop"
        }
        if ($PSBoundParameters.ContainsKey('credential')) {
            $invokeParams.Add("credential", $Credential)
        }
    } #begin
    Process {

        Switch ($pscmdlet.ParameterSetName) {
            "ID" {
                Write-Verbose "[$((Get-Date).TimeofDay)] by ID"
                $filter = "Select * from EventData where EventID='$ID'"
            }
            "Name" {
                Write-Verbose "[$((Get-Date).TimeofDay)] by Name"
                #get events that haven't expired or been archived by name
                if ($EventName -match "\*") {
                    $EventName = $EventName.replace("*", "%")
                }
                $filter = "Select * from EventData where EventName LIKE '$EventName' AND Archived='False' AND EventDate>'$(Get-Date)'"
            }
            "Days" {
                Write-Verbose "[$((Get-Date).TimeofDay)] for the next $next days"
                $target = (Get-Date).Date.AddDays($next).toString()
                $filter = "Select * from EventData where Archived='False' AND EventDate<='$target' AND eventdate > '$((Get-Date).ToString())' ORDER by EventDate Asc"
            }
            "Expired" {
                Write-Verbose "[$((Get-Date).TimeofDay)] by Expiration"
                #get expired events that have not been archived
                $filter = "Select * from EventData where Archived='False' AND EventDate<'$(Get-Date)' ORDER by EventDate Asc"
            }
            "Archived" {
                Write-Verbose "[$((Get-Date).TimeofDay)] by Archive"
                $filter = "Select * from EventData where Archived='True' ORDER by EventDate Asc"
            }
            "All" {
                Write-Verbose "[$((Get-Date).TimeofDay)] All"
                #get all non archived events
                $filter = "Select * from EventData where Archived='False' ORDER by EventDate Asc"
            }
            "Offline" {
                Write-Verbose "[$((Get-Date).TimeofDay)] Offline"
                Write-Verbose "[$((Get-Date).TimeOfDay)] Getting offline data from $Offline"
                #skip any expired entries when working offline
                $data = Import-Csv -Path $Offline | Where-Object { [datetime]$_.Date -ge (Get-Date).Date } | _NewMyTickle
            }
            Default {
                #this should never get called
                Write-Verbose "[$((Get-Date).TimeofDay)] Default"
                #get events that haven't been archived
                $filter = "Select * from EventData where Archived='False' AND EventDate>='$(Get-Date)' ORDER by EventDate Asc"
            }
        } #switch

        #if using offline data, display the results
        if ($Offline -AND $data) {
            Write-Verbose "[$((Get-Date).TimeofDay)] Getting events for the next $Next days."
            $Data | Where-Object { $_.Date -le (Get-Date).Date.addDays($Next) }
        }
        else {
            Write-Verbose "[$((Get-Date).TimeofDay)] Importing events from $TickleDB on $ServerInstance"
            #Query database for matching events
            Write-Verbose "[$((Get-Date).TimeofDay)] $filter"
            $invokeParams.query = $filter

            Try {
                $events = _InvokeSqlQuery @invokeParams # Invoke-SqlCmd @invokeParams
                #convert the data into mytickle objects
                $data = $events | _NewMyTickle
            }
            Catch {
                Throw $_
            }

            Write-Verbose "[$((Get-Date).TimeofDay)] Found $($events.count) matching events"
            #write event data to the pipeline
            $data

        } #else query for data
    } #process
    End {
        Write-Verbose "[$((Get-Date).TimeofDay)] Ending $($myinvocation.mycommand)"
    } #end
} #Get-TickleEvent

Function Set-TickleEvent {
    [cmdletbinding(SupportsShouldProcess, DefaultParameterSetname = "column")]
    [OutputType("None", "MyTickle")]
    [Alias("ste")]

    Param(
        [Parameter(Position = 0, ValueFromPipelineByPropertyName, Mandatory)]
        [int32]$ID,
        [Parameter(ParameterSetName = "column")]
        [alias("Name")]
        [string]$EventName,
        [Parameter(ParameterSetName = "column")]
        [datetime]$Date,
        [Parameter(ParameterSetName = "column")]
        [string]$Comment,
        #Enter the name of the SQL Server instance
        [ValidateNotNullOrEmpty()]
        [string]$ServerInstance = $TickleServerInstance,
        [pscredential]$Credential,
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

        $invokeParams = @{
            Query          = $null
            Database       = $TickleDB
            ServerInstance = $ServerInstance
            ErrorAction    = "Stop"
        }
        if ($PSBoundParameters.ContainsKey('credential')) {
            $invokeParams.Add("credential", $Credential)
        }

    } #begin

    Process {
        Write-Verbose "[$((Get-Date).TimeofDay) PROCESS] Updating Event ID $ID "
        $cols = @()
        if ($pscmdlet.ParameterSetName -eq 'column') {
            if ($Event) {
                $cols += "EventName='$EventName'"
            }
            if ($Comment) {
                $cols += "EventComment='$Comment'"
            }
            if ($Date) {
                $cols += "EventDate='$Date'"
            }
        }
        else {
            Write-Verbose "[$((Get-Date).TimeofDay) PROCESS] Archiving"
            $cols += "Archived='True'"
        }
        $data = $cols -join ","

        $query = $update -f $data, $ID
        $invokeParams.query = $query
        if ($PSCmdlet.ShouldProcess($query)) {
            _InvokeSqlQuery @invokeParams | Out-Null
            if ($Passthru) {
                Get-TickleEvent -Id $ID
            }
        }

    } #process

    End {
        Write-Verbose "[$((Get-Date).TimeofDay) END    ] Ending $($myinvocation.mycommand)"
    } #end

} #close Update-MyTickleEvent

Function Remove-TickleEvent {
    [cmdletbinding(SupportsShouldProcess)]
    [OutputType("None")]
    [Alias("rte")]

    Param(
        [Parameter(Position = 0, Mandatory, ValueFromPipelineByPropertyName)]
        [int32]$ID,
        #Enter the name of the SQL Server instance
        [ValidateNotNullOrEmpty()]
        [string]$ServerInstance = $TickleServerInstance,
        [pscredential]$Credential
    )
    Begin {
        Write-Verbose "[$((Get-Date).TimeofDay) BEGIN  ] Starting $($myinvocation.mycommand)"
        $invokeParams = @{
            Query          = $null
            ServerInstance = $ServerInstance
            Database       = $tickleDB
            ErrorAction    = "Stop"
        }

        if ($PSBoundParameters.ContainsKey('credential')) {
            $invokeParams.Add("credential", $Credential)
        }
    } #begin

    Process {
        Write-Verbose "[$((Get-Date).TimeofDay) PROCESS] Deleting tickle event $ID "
        $invokeParams.query = "DELETE From EventData where EventID='$ID'"
        if ($PSCmdlet.ShouldProcess("Event ID $ID")) {
            Try {
                _InvokeSqlQuery @invokeParams | Out-Null
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

Function Export-TickleDatabase {
    [cmdletbinding()]
    [OutputType("None")]

    Param(
        [Parameter(Position = 0, Mandatory, HelpMessage = "The path and filename for the export xml file.")]
        [String]$Path,
        #Enter the name of the SQL Server instance
        [ValidateNotNullOrEmpty()]
        [string]$ServerInstance = $TickleServerInstance,
        [pscredential]$Credential
    )
    Begin {
        Write-Verbose "[$((Get-Date).TimeofDay) BEGIN  ] Starting $($myinvocation.mycommand)"
        $invokeParams = @{
            Query          = "Select * from $tickleTable"
            ServerInstance = $ServerInstance
            Database       = $tickleDB
            ErrorAction    = "Stop"
        }

        if ($PSBoundParameters.ContainsKey('credential')) {
            $invokeParams.Add("credential", $Credential)
        }
    } #begin

    Process {
        Write-Verbose "[$((Get-Date).TimeofDay) PROCESS] Exporting database to $Path "
        Try {
            _InvokeSqlQuery @invokeParams | Export-Clixml -Path $Path
        }
        Catch {
            throw $_
        }
    } #process

    End {
        Write-Verbose "[$((Get-Date).TimeofDay) END    ] Ending $($myinvocation.mycommand)"

    } #end

} #close Export-TickleEventDatabase

Function Import-TickleDatabase {
    [cmdletbinding(SupportsShouldProcess)]
    [OutputType("None")]

    Param(
        [Parameter(Position = 0, Mandatory, HelpMessage = "The path and filename for the export xml file.")]
        [ValidateScript( { Test-Path $_ })]
        [String]$Path,
        #Enter the name of the SQL Server instance
        [ValidateNotNullOrEmpty()]
        [string]$ServerInstance = $TickleServerInstance,
        [pscredential]$Credential
    )
    Begin {
        Write-Verbose "[$((Get-Date).TimeofDay) BEGIN  ] Starting $($myinvocation.mycommand)"
        $invokeParams = @{
            Query          = ""
            ServerInstance = $ServerInstance
            Database       = $tickleDB
            ErrorAction    = "Stop"
        }

        if ($PSBoundParameters.ContainsKey('credential')) {
            $invokeParams.Add("credential", $Credential)
        }

        #turn off identity_insert
        $invokeParams.query = "Set identity_insert EventData On"
        _InvokeSqlQuery @invokeParams | Out-Null
    } #begin

    Process {
        Write-Verbose "[$((Get-Date).TimeofDay) PROCESS] Importing database data from $Path "
        Try {
            Import-Clixml -Path $path | ForEach-Object {
                $query = @"
Set identity_insert EventData On
INSERT INTO EventData (EventID,EventDate,EventName,EventComment,Archived) VALUES ('$($_.EventID)','$($_.EventDate)','$(($_.EventName).replace("'",""))','$($_.EventComment)','$($_.Archived)')
Set identity_insert EventData Off
"@
                $invokeparams.query = $query

                Write-Verbose "[$((Get-Date).TimeofDay) PROCESS] $($invokeparams.query)"

                if ($pscmdlet.ShouldProcess("VALUES ('$($_.EventID)','$($_.EventDate)','$($_.EventName)','$($_.EventComment)','$($_.Archived)'")) {
                    _InvokeSqlQuery @invokeParams | Out-Null
                }
            }
        }
        Catch {
            throw $_
        }
    } #process

    End {
        Write-Verbose "[$((Get-Date).TimeofDay) END    ] Ending $($myinvocation.mycommand)"

    } #end

} #close Import-TickleEventDatabase

Function Show-TickleEvent {
    [cmdletbinding(DefaultParameterSetName = "instance")]
    [OutputType("None")]
    [Alias("shte")]

    Param(
        [ValidateScript( { $_ -ge 1 })]
        #the next number of days to get
        [int]$Days = $TickleDefaultDays,

        [Parameter(ParameterSetName = "instance")]
        #Enter the name of the SQL Server instance
        [ValidateNotNullOrEmpty()]
        [string]$ServerInstance = $TickleServerInstance,

        [Parameter(ParameterSetName = "instance")]
        [pscredential]$Credential,

        [Parameter(ParameterSetName = "offline")]
        #Enter the path to an offline CSV file
        [ValidatePattern('\.csv$')]
        [ValidateScript( { Test-Path $_ })]
        [string]$Offline
    )

    Begin {
        Write-Verbose "[$((Get-Date).TimeofDay) BEGIN  ] Starting $($myinvocation.mycommand)"

        if ($PSCmdlet.ParameterSetName -eq 'instance') {
            $invokeParams = @{
                Days           = $Days
                ServerInstance = $ServerInstance
            }
            if ($PSBoundParameters.ContainsKey('credential')) {
                $invokeParams.Add("credential", $Credential)
            }
        }
        else {
            $invokeParams = @{Offline = $Offline }
        }

        #define ANSI color escapes
        #keep the lengths the same
        $red = "$([char]0x1b)[38;5;196m"
        $yellow = "$([char]0x1b)[38;5;228m"
        $green = "$([char]0x1b)[38;5;120m"
        $cyan = "$([char]0x1b)[36m"
        $cyanRev = "$([char]0x1b)[1;7;36m"
        $close = "$([char]0x1b)[0m"

        if ($host.name -eq "ConsoleHost" ) {
            Write-Information "Detected console host"
            [string]$topleft = [char]0x250c
            [string]$horizontal = [char]0x2500
            [string]$topright = [char]0x2510
            [string]$vertical = [char]0x2502
            [string]$bottomleft = [char]0x2514
            [string]$bottomright = [char]0x2518
        }
        else {
            #use a simple character for VSCode and the ISE
            Write-Information "Detected something other than console host"
            [string]$topleft = "*"
            [string]$horizontal = "*"
            [string]$topright = "*"
            [string]$vertical = "*"
            [string]$bottomleft = "*"
            [string]$bottomright = "*"
        }
    } #begin

    Process {
        #do not run in the PowerShell ISE
        if ($host.name -match 'ISE Host') {
            Write-Warning "This command will not display properly in the Windows PowerShell ISE"
            #bail out
            Return
        }
        Write-Verbose "[$((Get-Date).TimeofDay) PROCESS] Getting events for the next $Days days."

        if ($offline) {
            $target = (Get-Date).Date.AddDays($Days)
            $upcoming = Get-TickleEvent @invokeParams | Where-Object { $_.Date -le $Target }
        }
        else {
            Try {
                $upcoming = Get-TickleEvent @invokeParams
            }
            Catch {
                Throw $_
            }
        }
        if ($upcoming) {
            #how wide should the box be?
            #get the length of the longest line
            $l = 0
            foreach ($item in $upcoming) {
                #turn countdown into a string without the milliseconds
                $count = $item.countdown.ToString()
                $time = $count.Substring(0, $count.lastindexof("."))
                #add the time as a new property
                $item | Add-Member -MemberType Noteproperty -Name Time -Value $time
                $a = "$($item.event) $($item.Date) [$time]".length
                if ($a -gt $l) { $l = $a }
                $b = $item.comment.Length

                if ($b -gt $l) { $l = $b }
            }

            #need to take ANSI escape sequence into account
            [int]$width = $l + 11
            Write-Information "L = $l"
            Write-Information "width = $width"

            $header = " Reminders $((Get-Date).ToShortDateString()) "
            Write-Information "Header length = $($header.length)"

            "`r"

            $headerdisplay = "{0}{1}{2} {3}{4}{5} {6}{7}{8}{9}" -f $cyan, $topleft, $close, $cyanrev, $header, $close, $cyan, $($horizontal * ($width - 31)), $topright, $close
            Write-Information "Headerdisplay length = $($headerdisplay.length)"
            $headerdisplay
            #blank line
            #account for ANSI sequences
            $blank = "$cyan$vertical$(' '*($headerdisplay.length-33))$vertical$close"
            $blank

            foreach ($event in $upcoming) {

                if ($event.countdown.totalhours -le 24) {
                    $color = $red
                }
                elseif ($event.countdown.totalhours -le 48) {
                    $color = $yellow
                }
                else {
                    $color = $green
                }

                $line1 = "$cyan$vertical$close $color$($event.event) $($event.Date) [$($event.time)]$close"
                Write-Information "line 1: $line1 length = $($line1.Length)"
                #pad to account for length of ANSI escape plus spaces
                "$($line1.padRight($headerDisplay.length-9,' ')) $cyan$vertical$close"
                if ($event.comment -match "\w+") {
                    $line2 = "$cyan$vertical$close $color$($event.Comment)$close"
                    "$($line2.padright($headerDisplay.length-9, ' ')) $cyan$vertical$close"
                }
                $blank

                Write-Information "line 2: $line2 length = $($line2.length)"
                Write-Information "line 3: $line3 length = $($line3.length)"

            } #foreach

            "$cyan$bottomleft$($horizontal*($width-8))$bottomright$close"
            "`r"
        } #if upcoming events found
        else {
            $t = "No event reminders in the next $days days"
            $len = $t.length + 2

            $msg = @"

    $cyan$topleft$($horizontal*$len)$topright$close
    $cyan$vertical$close $yellow$t$close $cyan$vertical$close
    $cyan$bottomleft$($horizontal*$len)$bottomright$close

"@
            $msg
        }

    } #process

    End {
        Write-Verbose "[$((Get-Date).TimeofDay) END    ] Ending $($myinvocation.mycommand)"

    } #end

} #close Show-TickleEvent

#endregion

