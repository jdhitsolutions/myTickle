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

}
