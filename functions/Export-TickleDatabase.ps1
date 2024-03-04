Function Export-TickleDatabase {
    [CmdletBinding()]
    [OutputType("None")]

    Param(
        [Parameter(
            Position = 0,
            Mandatory,
            HelpMessage = "The path and filename for the export xml file."
        )]
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

}
