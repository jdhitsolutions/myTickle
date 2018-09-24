#requires -version 5.0

#region Define module functions

Function Initialize-TickleDatabase {
    [cmdletbinding(SupportsShouldProcess, DefaultParameterSetName = 'default')]
    Param(
        [Parameter(Position = 0,Mandatory,HelpMessage = "Enter the folder path for the database file. If specifying a remote server the path is relative to the server." )]
        [ValidateScript({Test-Path $_})]
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
        if (Test-Path -path $dbpath) {
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
    [OutputType("None","MyTickle")]
    [Alias("ate")]

    Param(
        [Parameter(Position = 0, ValueFromPipelineByPropertyName, Mandatory, HelpMessage = "Enter the name of the event")]
        [Alias("Name")]
        [string]$Event,
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
        Write-Verbose "[$((Get-Date).TimeofDay) PROCESS] Adding event '$event'"
        #events with apostrophes will have them stripped off
        $theEvent = $Event.replace("'", '')
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
        [Parameter(ParameterSetName = "ID")]
        [int[]]$Id,
        [Parameter(ParameterSetName = "Name")]
        [string]$Name,
        [Parameter(ParameterSetName = "All")]
        [switch]$All,
        [Parameter(ParameterSetName = "Expired")]
        [switch]$Expired,
        [Parameter(ParameterSetName = "Archived")]
        [switch]$Archived,
        [ValidateScript( {$_ -gt 0})]
        [Parameter(ParameterSetName = "Days")]
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
        [ValidateScript( {Test-Path $_})]
        [string]$Offline
    )

    Write-Verbose "[$((Get-Date).TimeofDay)] Starting $($myinvocation.mycommand)"
    Write-Verbose "[$((Get-Date).TimeofDay)] Importing events from $TickleDB on $ServerInstance"

    $invokeParams = @{
        Query          = $null
        Database       = $TickleDB
        ServerInstance = $ServerInstance
        ErrorAction    = "Stop"
    }
    if ($PSBoundParameters.ContainsKey('credential')) {
        $invokeParams.Add("credential", $Credential)
    }

    Switch ($pscmdlet.ParameterSetName) {
        "ID" {
            Write-Verbose "[$((Get-Date).TimeofDay)] by ID" 
            $filter = "Select * from EventData where EventID='$ID'"
        }
        "Name" { 
            Write-Verbose "[$((Get-Date).TimeofDay)] by Name"
            #get events that haven't expired or been archived by name
            $filter = "Select * from EventData where EventName='$Name' AND Archived='False' AND EventDate>'$(Get-Date)'"
        }
        "Days" {
            Write-Verbose "[$((Get-Date).TimeofDay)] for the next $next days"
            $target = (Get-Date).Date.AddDays($next).toString()
            $filter = "Select * from EventData where Archived='False' AND EventDate<='$target' ORDER by EventDate Asc"
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
            $data = import-csv -Path $Offline | _NewMyTickle
        }
        Default {
            Write-Verbose "[$((Get-Date).TimeofDay)] Default"
            #get events that haven't been archived
            $filter = "Select * from EventData where Archived='False' AND EventDate>='$(Get-Date)' ORDER by EventDate Asc"
        }
    } #switch

    #if using offline data, display the results
    if ($Offline -AND $data) {
        $Data
    } 
    else {
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

    Write-Verbose "[$((Get-Date).TimeofDay)] Ending $($myinvocation.mycommand)"

} #Get-TickleEvent

Function Set-TickleEvent {
    [cmdletbinding(SupportsShouldProcess, DefaultParameterSetname = "column")]
    [OutputType("None","MyTickle")]
    [Alias("ste")]

    Param(
        [Parameter(Position = 0, ValueFromPipelineByPropertyName, Mandatory)]
        [int32]$ID,
        [Parameter(ParameterSetName = "column")]
        [alias("Name")]
        [string]$Event,
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
                $cols += "EventName='$Event'"
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
            _InvokeSqlQuery @invokeParams | Export-clixml -Path $Path
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
        [ValidateScript( {Test-Path $_})]
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
        _InvokeSqlQuery @invokeParams | out-null
    } #begin

    Process {
        Write-Verbose "[$((Get-Date).TimeofDay) PROCESS] Importing database data from $Path "
        Try {
            Import-clixml -Path $path | foreach-object {
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
        [ValidateScript( {$_ -ge 1})]
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
        [ValidateScript( {Test-Path $_})]
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
            $invokeParams = @{Offline = $Offline}
        }
    } #begin

    Process {
        Write-Verbose "[$((Get-Date).TimeofDay) PROCESS] Getting events for the next $Days days."

        if ($offline) {
            $target = (Get-Date).Date.AddDays($Days)
            $upcoming = Get-TickleEvent @invokeParams | Where-Object {$_.Date -le $Target}
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
                $item | Add-Member -MemberType Noteproperty -name Time -Value $time
                $a = "$($item.event) $($item.Date) [$time]".length
                if ($a -gt $l) {$l = $a}
                $b = $item.comment.Length
        
                if ($b -gt $l) {$l = $b}
            }

            [int]$width = $l + 5

            $header = "* Reminders $((Get-Date).ToShortDateString()) "

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
                    $msg += "`n$($line3.padright($width-1))*"
                }

                Write-Host $msg -ForegroundColor $color

            } #foreach

            Write-Host ("*" * $width) -ForegroundColor Cyan
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
    [OutputType("MyTickle")]

    Param(
        [Parameter(ValueFromPipelineByPropertyName)]
        [alias("ID")]
        [int32]$EventID,
        [Parameter(ValueFromPipelineByPropertyName)]
        [alias("Event", "Name")]
        [string]$EventName,
        [Parameter(ValueFromPipelineByPropertyName)]
        [alias("Date")]
        [datetime]$EventDate,
        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias("Comment")]
        [string]$EventComment
    )
    Process {
        New-Object -TypeName mytickle -ArgumentList @($eventID, $Eventname, $EventDate, $EventComment)
    }
} #close _NewMyTickle

Function _InvokeSqlQuery {
    [cmdletbinding(SupportsShouldProcess, DefaultParameterSetName = "Default")]
    [OutputType([PSObject])]

    Param(
        [Parameter(Position = 0, Mandatory, HelpMessage = "The T-SQL query to execute")]
        [ValidateNotNullorEmpty()]
        [string]$Query,
        [Parameter(Mandatory, HelpMessage = "The name of the database")]
        [ValidateNotNullorEmpty()]
        [string]$Database,
        [Parameter(Mandatory, ParameterSetName = 'credential')]
        [pscredential]$Credential,
        #The server instance name
        [ValidateNotNullorEmpty()]
        [string]$ServerInstance = "$(hostname)\SqlExpress"
    )

    Begin {
        Write-Verbose "[BEGIN  ] Starting: $($MyInvocation.Mycommand)"  

        if ($PSCmdlet.ParameterSetName -eq 'credential') {
            $username = $Credential.UserName
            $password = $Credential.GetNetworkCredential().Password
        }

        Write-Verbose "[BEGIN  ] Creating the SQL Connection object"
        $connection = New-Object system.data.sqlclient.sqlconnection
    
        Write-Verbose "[BEGIN  ] Creating the SQL Command object"
        $cmd = New-Object system.Data.SqlClient.SqlCommand
 
    } #begin

    Process {
        Write-Verbose "[PROCESS] Opening the connection to $ServerInstance"
        Write-Verbose "[PROCESS] Using database $Database"
        if ($Username -AND $password) {
            Write-Verbose "[PROCESS] Using credential"
            $connection.connectionstring = "Data Source=$ServerInstance;Initial Catalog=$Database;User ID=$Username;Password=$Password;"
        }
        else {
            Write-Verbose "[PROCESS] Using Windows authentication"
            $connection.connectionstring = "Data Source=$ServerInstance;Initial Catalog=$Database;Integrated Security=SSPI;"
        }
        Write-Verbose "[PROCESS] Opening Connection"
        Write-Verbose "[PROCESS] $($connection.ConnectionString)"
        Try {
            $connection.open()
        }
        Catch {
            Throw $_
            #bail out
            Return
        }

        #join the connection to the command object
        $cmd.connection = $connection
        $cmd.CommandText = $query
    
        Write-Verbose "[PROCESS] Invoking $query"
        if ($PSCmdlet.ShouldProcess($Query)) {
        
            #determine what method to invoke based on the query
            Switch -regex ($query) {
                "^Select (\w+|\*)|(@@\w+ AS)" { 
                    Write-Verbose "ExecuteReader"
                    $reader = $cmd.executereader()
                    $out = @()
                    #convert datarows to a custom object
                    while ($reader.read()) {
                
                        $h = [ordered]@{}
                        for ($i = 0; $i -lt $reader.FieldCount; $i++) {
                            $col = $reader.getname($i)
                  
                            $h.add($col, $reader.getvalue($i))
                        } #for
                        $out += new-object -TypeName psobject -Property $h 
                    } #while

                    $out
                    $reader.close()
                    Break
                }
                "@@" { 
                    Write-Verbose "ExecuteScalar"
                    $cmd.ExecuteScalar()
                    Break
                }
                Default {
                    Write-Verbose "ExecuteNonQuery"
                    $cmd.ExecuteNonQuery()
                }
            }
        } #should process

    }

    End {
        Write-Verbose "[END    ] Closing the connection"
        $connection.close()

        Write-Verbose "[END    ] Ending: $($MyInvocation.Mycommand)"
    } #end

} #close _InvokeSqlQuery

#endregion