Function Add-TickleEvent {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType("None", "MyTickle")]
    [Alias("ate")]

    Param(
        [Parameter(Position = 0, ValueFromPipelineByPropertyName, Mandatory, HelpMessage = "Enter the name of the event")]
        [Alias("Name")]
        [String]$EventName,
        [Parameter(Position = 1, ValueFromPipelineByPropertyName, Mandatory, HelpMessage = "Enter the date and time for the event")]
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

}
