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
}
