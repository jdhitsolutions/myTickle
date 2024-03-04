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
}
