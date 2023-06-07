
#region Define module functions

Function Initialize-TickleDatabase {
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'default')]
    Param(
        [Parameter(Position = 0, Mandatory, HelpMessage = "Enter the folder path for the database file. If specifying a remote server the path is relative to the server." )]
        [ValidateScript( { Test-Path $_ })]
        [String]$DatabasePath,
        #Enter the name of the SQL Server instance
        [String]$ServerInstance = $TickleServerInstance,
        [Parameter(Mandatory, ParameterSetName = 'credential')]
        [PSCredential]$Credential
    )
    Begin {
        Write-Verbose "[$((Get-Date).TimeOfDay) BEGIN  ] Starting $($MyInvocation.MyCommand)"

        #Enter the filename for the database file using the module variable
        $DatabaseName = $TickleDB
        $DBPath = Join-Path -Path $DatabasePath -ChildPath "$DatabaseName.mdf"
        $newDB = @"
CREATE DATABASE $DatabaseName
ON PRIMARY
    (FILENAME = '$DBPath',
    NAME = TickleEvents,
    SIZE = 10mb,
    MAXSIZE = 100,
    FILEGROWTH = 20
    )
"@
        $newTable = @"
SET ANSI_NULLS ON

SET QUOTED_IDENTIFIER ON

CREATE TABLE [$DatabaseName].[dbo].[EventData](
	[EventID] [Int] IDENTITY(100,1) NOT NULL,
	[EventDate] [datetime2](7) NOT NULL,
	[EventName] [nvarchar](50) NOT NULL,
	[EventComment] [nvarchar](50) NULL,
	[Archived] [bit] NULL
) ON [PRIMARY]

ALTER TABLE [$DatabaseName].[dbo].[EventData] ADD CONSTRAINT [DF_EventData_Archived]  DEFAULT (N'0') FOR [Archived]

"@

    } #begin

    Process {
        if (Test-Path -Path $DBPath) {
            Write-Warning "A file was already found at $DBPath. Initialization aborted."
            #bail out if the database file already exists
            return
        }
        Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] Creating Database file $DBPath"
        Write-Verbose $newDB
        Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] Connect to $ServerInstance"
        if ($PSBoundParameters.ContainsKey('DatabasePath')) {
            [void]($PSBoundParameters.Remove('DatabasePath'))
        }
        #need to connect to a database
        $PSBoundParameters.add("Database", 'Master')
        $PSBoundParameters.Add("Query", $newDB)
        Write-Verbose ($PSBoundParameters | Out-String)
        if ($PSCmdlet.ShouldProcess($DBPath)) {
            #create the database
            Try {
                [void](_InvokeSqlQuery @PSBoundParameters)
            }
            Catch {
                Throw $_
            }
            #give SQL a chance to complete the action
            Start-Sleep -Seconds 2
            #create the table
            Try {
                Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] Creating table EventData"
                Write-Verbose $newTable
                $PSBoundParameters.Query = $newTable
                $PSBoundParameters.Database = $DatabaseName
                Write-Verbose ($PSBoundParameters | Out-String)
                _InvokeSqlQuery @PSBoundParameters
            }
            Catch {
                Throw $_
            }
            Write-Host "Database initialization complete." -ForegroundColor Green
        } #if should process
    } #process

    End {
        Write-Verbose "[$((Get-Date).TimeOfDay) END    ] Ending $($MyInvocation.MyCommand)"

    } #end

} #close Initialize-TickleDatabase

Function Add-TickleEvent {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType("None", "MyTickle")]
    [Alias("ate")]

    Param(
        [Parameter(Position = 0, ValueFromPipelineByPropertyName, Mandatory, HelpMessage = "Enter the name of the event")]
        [Alias("Name")]
        [String]$EventName,
        [Parameter(Position = 1, ValueFromPipelineByPropertyName, Mandatory, HelpMessage = "Enter the datetime for the event")]
        [ValidateScript( {
                If ($_ -gt (Get-Date)) {
                    $True
                }
                else {
                    Throw "You must enter a future date and time."
                }
            })]
        [DateTime]$Date,
        [Parameter(Position = 2, ValueFromPipelineByPropertyName)]
        [String]$Comment,
        #Enter the name of the SQL Server instance
        [ValidateNotNullOrEmpty()]
        [String]$ServerInstance = $TickleServerInstance,
        [ValidateNotNullOrEmpty()]
        [PSCredential]$Credential,
        [Switch]$PassThru
    )
    Begin {
        Write-Verbose "[$((Get-Date).TimeOfDay) BEGIN  ] Starting $($MyInvocation.MyCommand)"
        $InvokeParams = @{
            Query          = $null
            ServerInstance = $ServerInstance
            Database       = $TickleDB
            ErrorAction    = 'Stop'
        }
        if ($PSBoundParameters.ContainsKey('credential')) {
            $InvokeParams.Add("credential", $Credential)
        }
    } #begin

    Process {
        Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] Adding event '$EventName'"
        #events with apostrophes will have them stripped off
        $theEvent = $EventName.replace("'", '')
        $InvokeParams.query = "INSERT INTO EventData (EventDate,EventName,EventComment) VALUES ('$Date','$theEvent','$Comment')"

        $short = "[$Date] $Event"
        if ($PSCmdlet.ShouldProcess($short)) {
            Try {
                Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] $($InvokeParams.query)"
                [void](_InvokeSqlQuery @InvokeParams)
            }
            Catch {
                throw $_
            }

            if ($PassThru) {
                $query = "Select Top 1 * from EventData Order by EventID Desc"
                $InvokeParams.query = $query
                _InvokeSqlQuery @InvokeParams | _NewMyTickle
            } #if PassThru
        } #if should process
    } #process

    End {
        Write-Verbose "[$((Get-Date).TimeOfDay) END    ] Ending $($MyInvocation.MyCommand)"
    } #end

} #close Add-TickleEvent

Function Get-TickleEvent {

    [CmdletBinding(DefaultParameterSetName = "Days")]
    [OutputType("MyTickle")]
    [Alias("gte")]

    Param(
        [Parameter(
            ParameterSetName = "ID",
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [int32]$Id,
        [Parameter(
            ParameterSetName = "Name",
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [Alias("Name")]
        [String]$EventName,
        [Parameter(ParameterSetName = "All")]
        [Switch]$All,
        [Parameter(ParameterSetName = "Expired")]
        [Switch]$Expired,
        [Parameter(ParameterSetName = "Archived")]
        [Switch]$Archived,
        [ValidateScript( { $_ -gt 0 })]
        [Parameter(ParameterSetName = "Days")]
        [Parameter(ParameterSetName = "Offline")]
        [Alias("days")]
        [Int]$Next = $TickleDefaultDays,
        [Parameter(ParameterSetName = "ID")]
        [Parameter(ParameterSetName = "Archived")]
        [Parameter(ParameterSetName = "Expired")]
        [Parameter(ParameterSetName = "All")]
        [Parameter(ParameterSetName = "Days")]
        [Parameter(ParameterSetName = "Name")]
        #Enter the name of the SQL Server instance
        [ValidateNotNullOrEmpty()]
        [String]$ServerInstance = $TickleServerInstance,
        [Parameter(ParameterSetName = "ID")]
        [Parameter(ParameterSetName = "Archived")]
        [Parameter(ParameterSetName = "Expired")]
        [Parameter(ParameterSetName = "All")]
        [Parameter(ParameterSetName = "Days")]
        [Parameter(ParameterSetName = "Name")]
        [PSCredential]$Credential,
        [Parameter(ParameterSetName = "Offline")]
        #Enter the path to an offline CSV file
        [ValidatePattern('\.csv$')]
        [ValidateScript( { Test-Path $_ })]
        [String]$Offline
    )

    Begin {

        Write-Verbose "[$((Get-Date).TimeOfDay)] Starting $($MyInvocation.MyCommand)"

        $InvokeParams = @{
            Query          = $null
            Database       = $TickleDB
            ServerInstance = $ServerInstance
            ErrorAction    = "Stop"
        }
        if ($PSBoundParameters.ContainsKey('credential')) {
            $InvokeParams.Add("credential", $Credential)
        }
    } #begin
    Process {
        Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] Using parameter set $($PSCmdlet.ParameterSetName)"
        Switch ($PSCmdlet.ParameterSetName) {
            "ID" {
                Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] by ID"
                $filter = "Select * from EventData where EventID='$ID'"
            }
            "Name" {
                Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] by Name"
                #get events that haven't expired or been archived by name
                if ($EventName -match "\*") {
                    $EventName = $EventName.replace("*", "%")
                }
                $filter = "Select * from EventData where EventName LIKE '$EventName' AND Archived='False' AND EventDate>'$(Get-Date)'"
            }
            "Days" {
                Write-Verbose "[$((Get-Date).TimeOfDay)] for the next $next days"
                $target = (Get-Date).Date.AddDays($next).ToString()
                $filter = "Select * from EventData where Archived='False' AND EventDate<='$target' AND eventdate > '$((Get-Date).ToString())' ORDER by EventDate Asc"
            }
            "Expired" {
                Write-Verbose "[$((Get-Date).TimeOfDay)] by Expiration"
                #get expired events that have not been archived
                $filter = "Select * from EventData where Archived='False' AND EventDate<'$(Get-Date)' ORDER by EventDate Asc"
            }
            "Archived" {
                Write-Verbose "[$((Get-Date).TimeOfDay)] by Archive"
                $filter = "Select * from EventData where Archived='True' ORDER by EventDate Asc"
            }
            "All" {
                Write-Verbose "[$((Get-Date).TimeOfDay)] All"
                #get all non archived events
                $filter = "Select * from EventData where Archived='False' ORDER by EventDate Asc"
            }
            "Offline" {
                Write-Verbose "[$((Get-Date).TimeOfDay)] Offline"
                Write-Verbose "[$((Get-Date).TimeOfDay)] Getting offline data from $Offline"
                #skip any expired entries when working offline
                $data = Import-Csv -Path $Offline | Where-Object { [DateTime]$_.Date -ge (Get-Date).Date } | _NewMyTickle
            }
            Default {
                #this should never get called
                Write-Verbose "[$((Get-Date).TimeOfDay)] Default"
                #get events that haven't been archived
                $filter = "Select * from EventData where Archived='False' AND EventDate>='$(Get-Date)' ORDER by EventDate Asc"
            }
        } #switch

        #if using offline data, display the results
        if ($Offline -AND $data) {
            Write-Verbose "[$((Get-Date).TimeOfDay)] Getting events for the next $Next days."
            $Data | Where-Object { $_.Date -le (Get-Date).Date.addDays($Next) }
        }
        else {
            Write-Verbose "[$((Get-Date).TimeOfDay)] Importing events from $TickleDB on $ServerInstance"
            #Query database for matching events
            Write-Verbose "[$((Get-Date).TimeOfDay)] $filter"
            $InvokeParams.query = $filter

            Try {
                $events = _InvokeSqlQuery @InvokeParams # Invoke-SqlCmd @InvokeParams
                #convert the data into mytickle objects
                $data = $events | _NewMyTickle
            }
            Catch {
                Throw $_
            }

            Write-Verbose "[$((Get-Date).TimeOfDay)] Found $($events.count) matching events"
            #write event data to the pipeline
            $data

        } #else query for data
    } #process
    End {
        Write-Verbose "[$((Get-Date).TimeOfDay)] Ending $($MyInvocation.MyCommand)"
    } #end
} #Get-TickleEvent

Function Set-TickleEvent {
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = "column")]
    [OutputType("None", "MyTickle")]
    [Alias("ste")]

    Param(
        [Parameter(
            Position = 0,
            ValueFromPipelineByPropertyName,
            Mandatory
        )]
        [int32]$ID,
        [Parameter(ParameterSetName = "column")]
        [alias("Name")]
        [String]$EventName,
        [Parameter(ParameterSetName = "column")]
        [DateTime]$Date,
        [Parameter(ParameterSetName = "column")]
        [String]$Comment,
        #Enter the name of the SQL Server instance
        [ValidateNotNullOrEmpty()]
        [String]$ServerInstance = $TickleServerInstance,
        [PSCredential]$Credential,
        [Switch]$PassThru,
        [Parameter(ParameterSetName = "archive")]
        [Switch]$Archive
    )
    Begin {
        Write-Verbose "[$((Get-Date).TimeOfDay) BEGIN  ] Starting $($MyInvocation.MyCommand)"

        $update = @"
UPDATE EventData
SET {0} Where EventID='{1}'
"@

        $InvokeParams = @{
            Query          = $null
            Database       = $TickleDB
            ServerInstance = $ServerInstance
            ErrorAction    = "Stop"
        }
        if ($PSBoundParameters.ContainsKey('credential')) {
            $InvokeParams.Add("credential", $Credential)
        }

    } #begin

    Process {
        Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] Updating Event ID $ID "
        $cols = @()
        Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] Using parameter set $($PSCmdlet.ParameterSetName)"
        if ($PSCmdlet.ParameterSetName -eq 'column') {
            if ($EventName) {
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
            Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] Archiving"
            $cols += "Archived='True'"
        }
        $data = $cols -join ","

        $query = $update -f $data, $ID
        $InvokeParams.query = $query
        if ($PSCmdlet.ShouldProcess($query)) {
            [void](_InvokeSqlQuery @InvokeParams)
            if ($PassThru) {
                Get-TickleEvent -Id $ID
            }
        }

    } #process

    End {
        Write-Verbose "[$((Get-Date).TimeOfDay) END    ] Ending $($MyInvocation.MyCommand)"
    } #end

} #close Update-MyTickleEvent

Function Remove-TickleEvent {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType("None")]
    [Alias("rte")]

    Param(
        [Parameter(Position = 0, Mandatory, ValueFromPipelineByPropertyName)]
        [int32]$ID,
        #Enter the name of the SQL Server instance
        [ValidateNotNullOrEmpty()]
        [String]$ServerInstance = $TickleServerInstance,
        [PSCredential]$Credential
    )
    Begin {
        Write-Verbose "[$((Get-Date).TimeOfDay) BEGIN  ] Starting $($MyInvocation.MyCommand)"
        $InvokeParams = @{
            Query          = $null
            ServerInstance = $ServerInstance
            Database       = $tickleDB
            ErrorAction    = "Stop"
        }

        if ($PSBoundParameters.ContainsKey('credential')) {
            $InvokeParams.Add("credential", $Credential)
        }
    } #begin

    Process {
        Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] Deleting tickle event $ID "
        $InvokeParams.query = "DELETE From EventData where EventID='$ID'"
        if ($PSCmdlet.ShouldProcess("Event ID $ID")) {
            Try {
                [void]( _InvokeSqlQuery @InvokeParams)
            }
            Catch {
                Throw $_
            }
        } #should process
    } #process

    End {
        Write-Verbose "[$((Get-Date).TimeOfDay) END    ] Ending $($MyInvocation.MyCommand)"

    } #end

} #close Remove-TickleEvent

Function Export-TickleDatabase {
    [CmdletBinding()]
    [OutputType("None")]

    Param(
        [Parameter(Position = 0, Mandatory, HelpMessage = "The path and filename for the export xml file.")]
        [String]$Path,
        #Enter the name of the SQL Server instance
        [ValidateNotNullOrEmpty()]
        [String]$ServerInstance = $TickleServerInstance,
        [PSCredential]$Credential
    )
    Begin {
        Write-Verbose "[$((Get-Date).TimeOfDay) BEGIN  ] Starting $($MyInvocation.MyCommand)"
        $InvokeParams = @{
            Query          = "Select * from $tickleTable"
            ServerInstance = $ServerInstance
            Database       = $tickleDB
            ErrorAction    = "Stop"
        }

        if ($PSBoundParameters.ContainsKey('credential')) {
            $InvokeParams.Add("credential", $Credential)
        }
    } #begin

    Process {
        Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] Exporting database to $Path "
        Try {
            _InvokeSqlQuery @InvokeParams | Export-Clixml -Path $Path
        }
        Catch {
            throw $_
        }
    } #process

    End {
        Write-Verbose "[$((Get-Date).TimeOfDay) END    ] Ending $($MyInvocation.MyCommand)"

    } #end

} #close Export-TickleEventDatabase

Function Import-TickleDatabase {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType("None")]

    Param(
        [Parameter(Position = 0, Mandatory, HelpMessage = "The path and filename for the export xml file.")]
        [ValidateScript( { Test-Path $_ })]
        [String]$Path,
        #Enter the name of the SQL Server instance
        [ValidateNotNullOrEmpty()]
        [String]$ServerInstance = $TickleServerInstance,
        [PSCredential]$Credential
    )
    Begin {
        Write-Verbose "[$((Get-Date).TimeOfDay) BEGIN  ] Starting $($MyInvocation.MyCommand)"
        $InvokeParams = @{
            Query          = ""
            ServerInstance = $ServerInstance
            Database       = $tickleDB
            ErrorAction    = "Stop"
        }

        if ($PSBoundParameters.ContainsKey('credential')) {
            $InvokeParams.Add("credential", $Credential)
        }

        #turn off identity_insert
        $InvokeParams.query = "Set identity_insert EventData On"
        [void](_InvokeSqlQuery @InvokeParams)
    } #begin

    Process {
        Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] Importing database data from $Path "
        Try {
            Import-Clixml -Path $path | ForEach-Object {
                $query = @"
Set identity_insert EventData On
INSERT INTO EventData (EventID,EventDate,EventName,EventComment,Archived) VALUES ('$($_.EventID)','$($_.EventDate)','$(($_.EventName).replace("'",""))','$($_.EventComment)','$($_.Archived)')
Set identity_insert EventData Off
"@
                $InvokeParams.query = $query

                Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] $($InvokeParams.query)"

                if ($PSCmdlet.ShouldProcess("VALUES ('$($_.EventID)','$($_.EventDate)','$($_.EventName)','$($_.EventComment)','$($_.Archived)'")) {
                    [void](_InvokeSqlQuery @InvokeParams)
                }
            }
        }
        Catch {
            throw $_
        }
    } #process

    End {
        Write-Verbose "[$((Get-Date).TimeOfDay) END    ] Ending $($MyInvocation.MyCommand)"

    } #end

} #close Import-TickleEventDatabase

Function Show-TickleEvent {
    [CmdletBinding(DefaultParameterSetName = "instance")]
    [OutputType("None")]
    [Alias("shte")]

    Param(
        [ValidateScript({ $_ -ge 1 })]
        #the next number of days to get
        [Int]$Days = $TickleDefaultDays,

        [Parameter(ParameterSetName = "instance")]
        #Enter the name of the SQL Server instance
        [ValidateNotNullOrEmpty()]
        [String]$ServerInstance = $TickleServerInstance,

        [Parameter(ParameterSetName = "instance")]
        [PSCredential]$Credential,

        [Parameter(ParameterSetName = "offline")]
        #Enter the path to an offline CSV file
        [ValidatePattern('\.csv$')]
        [ValidateScript( { Test-Path $_ })]
        [String]$Offline
    )

    Begin {
        Write-Verbose "[$((Get-Date).TimeOfDay) BEGIN  ] Starting $($MyInvocation.MyCommand)"

        if ($PSCmdlet.ParameterSetName -eq 'instance') {
            $InvokeParams = @{
                Days           = $Days
                ServerInstance = $ServerInstance
            }
            if ($PSBoundParameters.ContainsKey('credential')) {
                $InvokeParams.Add("credential", $Credential)
            }
        }
        else {
            $InvokeParams = @{
                Days = $Days
                Offline = $Offline
            }
        }

        #define ANSI color escapes
        #keep the lengths the same
        $red = "$([char]0x1b)[38;5;196m"
        $yellow = "$([char]0x1b)[38;5;228m"
        $green = "$([char]0x1b)[38;5;120m"
        $cyan = "$([char]0x1b)[36m"
        $reminderBox = "$([char]0x1b)[1;7;36m"
        $close = "$([char]0x1b)[0m"

        if ($host.name -eq "ConsoleHost" ) {
            Write-Information "Detected console host"
            [String]$TopLeft = [char]0x250c
            [String]$horizontal = [char]0x2500
            [String]$TopRight = [char]0x2510
            [String]$vertical = [char]0x2502
            [String]$BottomLeft = [char]0x2514
            [String]$BottomRight = [char]0x2518
        }
        else {
            #use a simple character for VSCode and the ISE
            Write-Information "Detected something other than console host"
            [String]$TopLeft = "*"
            [String]$horizontal = "*"
            [String]$TopRight = "*"
            [String]$vertical = "*"
            [String]$BottomLeft = "*"
            [String]$BottomRight = "*"
        }
    } #begin

    Process {
        #do not run in the PowerShell ISE
        if ($host.name -match 'ISE Host') {
            Write-Warning "This command will not display properly in the Windows PowerShell ISE"
            #bail out
            Return
        }
        Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] Getting events for the next $Days days."

        if ($offline) {
            $target = (Get-Date).Date.AddDays($Days)
            $upcoming = Get-TickleEvent @InvokeParams | Where-Object { $_.Date -le $Target }
        }
        else {
            Try {
                $upcoming = Get-TickleEvent @InvokeParams
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
                $time = $count.Substring(0, $count.LastIndexOf("."))
                #add the time as a new property
                $item | Add-Member -MemberType NoteProperty -Name Time -Value $time
                $a = "$($item.event) $($item.Date) [$time]".length
                if ($a -gt $l) { $l = $a }
                $b = $item.comment.Length

                if ($b -gt $l) { $l = $b }
            }

            #need to take ANSI escape sequence into account
            [Int]$width = $l + 11
            Write-Information "L = $l"
            Write-Information "width = $width"

            $header = " Reminders $((Get-Date).ToShortDateString()) "
            Write-Information "Header length = $($header.length)"

            "`r"

            $HeaderDisplay = "{0}{1}{2} {3}{4}{5} {6}{7}{8}{9}" -f $cyan, $TopLeft, $close, $reminderBox, $header, $close, $cyan, $($horizontal * ($width - 31)), $TopRight, $close
            Write-Information "HeaderDisplay length = $($HeaderDisplay.length)"
            $HeaderDisplay
            #blank line
            #account for ANSI sequences
            $blank = "$cyan$vertical$(' '*($HeaderDisplay.length-33))$vertical$close"
            $blank

            foreach ($event in $upcoming) {

                if ($event.countdown.TotalHours -le 24) {
                    $color = $red
                }
                elseif ($event.countdown.TotalHours -le 48) {
                    $color = $yellow
                }
                else {
                    $color = $green
                }

                $line1 = "$cyan$vertical$close $color$($event.event) $($event.Date) [$($event.time)]$close"
                Write-Information "line 1: $line1 length = $($line1.Length)"
                #pad to account for length of ANSI escape plus spaces
                "$($line1.PadRight($HeaderDisplay.length-9,' ')) $cyan$vertical$close"
                if ($event.comment -match "\w+") {
                    $line2 = "$cyan$vertical$close $color$($event.Comment)$close"
                    "$($line2.PadRight($HeaderDisplay.length-9, ' ')) $cyan$vertical$close"
                }
                $blank

                Write-Information "line 2: $line2 length = $($line2.length)"
                Write-Information "line 3: $line3 length = $($line3.length)"

            } #foreach

            #adjusted width to better draw the outline box 1/20/2021 JDH
            "$cyan$BottomLeft$($horizontal*($width-8))$BottomRight$close"
            "`r"
        } #if upcoming events found
        else {
            $t = "No event reminders in the next $days days"
            $len = $t.length + 2

            $msg = @"

    $cyan$TopLeft$($horizontal*$len)$TopRight$close
    $cyan$vertical$close $yellow$t$close $cyan$vertical$close
    $cyan$BottomLeft$($horizontal*$len)$BottomRight$close

"@
            $msg
        }

    } #process

    End {
        Write-Verbose "[$((Get-Date).TimeOfDay) END    ] Ending $($MyInvocation.MyCommand)"

    } #end

} #close Show-TickleEvent

Function Get-TickleDBInformation {
    [CmdletBinding()]
    [OutputType("myTickleDBInfo")]
    Param(
        [Parameter(HelpMessage = "Display backup information only.")]
        [Switch]$BackupInformation,
        [ValidateNotNullOrEmpty()]
        [String]$ServerInstance = $TickleServerInstance,
        [ValidateNotNullOrEmpty()]
        [PSCredential]$Credential
    )

    #remove BackupInformation from PSBoundParameters
    if ($PSBoundParameters.ContainsKey("BackupInformation")) {
        [void]($PSBoundParameters.remove("BackupInformation"))
    }

    $query = @"
SELECT f.[name] AS [FileName], f.physical_name AS [Path], size,
FILEPROPERTY(f.name, 'SpaceUsed') AS Used,
f.size - FILEPROPERTY(f.name, 'SpaceUsed') AS [Available]
FROM sys.database_files AS f WITH (NOLOCK)
LEFT OUTER JOIN sys.filegroups AS fg WITH (NOLOCK)
ON f.data_space_id = fg.data_space_id
where f.[name] = 'TickleEvents'
ORDER BY f.[type], f.[file_id] OPTION (RECOMPILE);
"@

    $PSBoundParameters.Add("Query", $query)
    $PSBoundParameters.Add("Database", "TickleEventDB")
    $r = _InvokeSqlQuery @PSBoundParameters
    if ($r) {

        #get backup information. The query returns more information than I am using now.
        $q = @"
Select ISNULL(d.[name], bs.[database_name]) AS [Database], d.recovery_model_desc AS [RecoveryModel],
MAX(CASE WHEN [type] = 'D' THEN bs.backup_finish_date ELSE NULL END) AS [LastFullBackup],
MAX(CASE WHEN [type] = 'D' THEN bmf.physical_device_name ELSE NULL END) AS [LastFullBackupLocation],
MAX(CASE WHEN [type] = 'I' THEN bs.backup_finish_date ELSE NULL END) AS [LastDifferentialBackup],
MAX(CASE WHEN [type] = 'I' THEN bmf.physical_device_name ELSE NULL END) AS [LastDifferentialBackupLocation],
MAX(CASE WHEN [type] = 'L' THEN bs.backup_finish_date ELSE NULL END) AS [LastLogBackup],
MAX(CASE WHEN [type] = 'L' THEN bmf.physical_device_name ELSE NULL END) AS [LastLogBackupLocation]
FROM sys.databases  AS d WITH (NOLOCK)
LEFT OUTER JOIN msdb.dbo.backupset AS bs WITH (NOLOCK)
ON bs.[database_name] = d.[name]
LEFT OUTER JOIN msdb.dbo.backupmediafamily AS bmf WITH (NOLOCK)
ON bs.media_set_id = bmf.media_set_id
AND bs.backup_finish_date > GETDATE()- 30
Where d.name = N'TickleEventDB'
Group BY ISNULL(d.[name], bs.[database_name]), d.recovery_model_desc, d.log_reuse_wait_desc, d.[name]
ORDER BY d.recovery_model_desc, d.[name] OPTION (RECOMPILE);
"@
        $PSBoundParameters.query = $q
        $PSBoundParameters.database = "master"
        $BackupInfo = _InvokeSqlQuery @PSBoundParameters
        #create a composite custom object
        $obj = [PSCustomObject]@{
            PSTypename                     = "myTickleDBInfo"
            Name                           = "TickleEventDB"
            Path                           = $r.path
            Size                           = $r.Size * 8KB
            UsedSpace                      = $r.used * 8KB
            AvailableSpace                 = $r.available * 8KB
            LastFullBackup                 = $BackupInfo.LastFullBackup
            LastFullBackupLocation         = $BackupInfo.LastFullBackupLocation
            LastDifferentialBackup         = $BackupInfo.LastDifferentialBackup
            LastDifferentialBackupLocation = $BackupInfo.LastDifferentialBackupLocation
            LastLogBackup                  = $BackupInfo.LastLogBackup
            LastLogBackupLocation          = $BackupInfo.LastLogBackupLocation
            Date                           = Get-Date
        }
        if ($BackupInformation) {
            $obj | Select-Object -Property Name,Path,Last*
        }
        else {
            $obj
        }
    } #if $r
} #close function

#endregion

