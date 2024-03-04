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
}
