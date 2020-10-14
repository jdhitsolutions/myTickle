# private module functions

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
                        $out += New-Object -TypeName psobject -Property $h
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

