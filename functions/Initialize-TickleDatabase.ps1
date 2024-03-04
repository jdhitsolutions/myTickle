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

}
