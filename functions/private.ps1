# private module functions

function _NewMyTickle {
    [CmdletBinding()]
    [OutputType("MyTickle")]

    Param(
        [Parameter(ValueFromPipelineByPropertyName)]
        [alias("ID")]
        [int32]$EventID,
        [Parameter(ValueFromPipelineByPropertyName)]
        [alias("Event", "Name")]
        [String]$EventName,
        [Parameter(ValueFromPipelineByPropertyName)]
        [alias("Date")]
        [DateTime]$EventDate,
        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias("Comment")]
        [String]$EventComment
    )
    Process {
        New-Object -TypeName mytickle -ArgumentList @($eventID, $EventName, $EventDate, $EventComment)
    }
} #close _NewMyTickle

Function _InvokeSqlQuery {
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = "Default")]
    [OutputType([PSObject])]

    Param(
        [Parameter(Position = 0, Mandatory, HelpMessage = "The T-SQL query to execute")]
        [ValidateNotNullOrEmpty()]
        [String]$Query,
        [Parameter(Mandatory, HelpMessage = "The name of the database")]
        [ValidateNotNullOrEmpty()]
        [String]$Database,
        [Parameter(Mandatory, ParameterSetName = 'credential')]
        [PSCredential]$Credential,
        #The server instance name
        [ValidateNotNullOrEmpty()]
        [String]$ServerInstance = "$(hostname)\SqlExpress"
    )

    Begin {
        Write-Verbose "[BEGIN  ] Starting: $($MyInvocation.MyCommand)"

        if ($PSCmdlet.ParameterSetName -eq 'credential') {
            $username = $Credential.UserName
            $password = $Credential.GetNetworkCredential().Password
        }

        Write-Verbose "[BEGIN  ] Creating the SQL Connection object"
        $connection = New-Object System.Data.SQLClient.SQLConnection

        Write-Verbose "[BEGIN  ] Creating the SQL Command object"
        $cmd = New-Object system.Data.SqlClient.SqlCommand

    } #begin

    Process {
        Write-Verbose "[PROCESS] Opening the connection to $ServerInstance"
        Write-Verbose "[PROCESS] Using database $Database"
        if ($Username -AND $password) {
            Write-Verbose "[PROCESS] Using credential"
            $connection.ConnectionString = "Data Source=$ServerInstance;Initial Catalog=$Database;User ID=$Username;Password=$Password;"
        }
        else {
            Write-Verbose "[PROCESS] Using Windows authentication"
            $connection.ConnectionString = "Data Source=$ServerInstance;Initial Catalog=$Database;Integrated Security=SSPI;"
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
                "^Select (\w+|\*)|(@@\w+ AS)|(exec)" {
                    Write-Verbose "ExecuteReader"
                    $reader = $cmd.ExecuteReader()
                    $out = @()
                    #convert data rows to a custom object
                    while ($reader.read()) {

                        $h = [ordered]@{}
                        for ($i = 0; $i -lt $reader.FieldCount; $i++) {
                            $col = $reader.GetName($i)

                            $h.add($col, $reader.GetValue($i))
                        } #for
                        $out += New-Object -TypeName PSObject -Property $h
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
        Write-Verbose "[END    ] Ending: $($MyInvocation.MyCommand)"
    } #end

} #close _InvokeSqlQuery

