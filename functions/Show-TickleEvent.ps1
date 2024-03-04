Function Show-TickleEvent {
    [CmdletBinding(DefaultParameterSetName = "instance")]
    [OutputType("None")]
    [Alias("shte")]

    Param(
        [ValidateScript({ $_ -ge 1 })]
        #the next number of days to get
        [Int]$Days = $TickleDefaultDays,

        [Parameter(ParameterSetName = "instance")]
        #Enter the name of the SQL Server instance
        [ValidateNotNullOrEmpty()]
        [String]$ServerInstance = $TickleServerInstance,

        [Parameter(ParameterSetName = "instance")]
        [PSCredential]$Credential,

        [Parameter(ParameterSetName = "offline")]
        #Enter the path to an offline CSV file
        [ValidatePattern('\.csv$')]
        [ValidateScript( { Test-Path $_ })]
        [String]$Offline
    )

    Begin {
        Write-Verbose "[$((Get-Date).TimeOfDay) BEGIN  ] Starting $($MyInvocation.MyCommand)"

        if ($PSCmdlet.ParameterSetName -eq 'instance') {
            $InvokeParams = @{
                Days           = $Days
                ServerInstance = $ServerInstance
            }
            if ($PSBoundParameters.ContainsKey('credential')) {
                $InvokeParams.Add("credential", $Credential)
            }
        }
        else {
            $InvokeParams = @{
                Days = $Days
                Offline = $Offline
            }
        }

        #define ANSI color escapes
        #keep the lengths the same
        $red = "$([char]0x1b)[38;5;196m"
        $yellow = "$([char]0x1b)[38;5;228m"
        $green = "$([char]0x1b)[38;5;120m"
        $cyan = "$([char]0x1b)[36m"
        $reminderBox = "$([char]0x1b)[1;7;36m"
        $close = "$([char]0x1b)[0m"

        if ($host.name -eq "ConsoleHost" ) {
            Write-Information "Detected console host"
            [String]$TopLeft = [char]0x250c
            [String]$horizontal = [char]0x2500
            [String]$TopRight = [char]0x2510
            [String]$vertical = [char]0x2502
            [String]$BottomLeft = [char]0x2514
            [String]$BottomRight = [char]0x2518
        }
        else {
            #use a simple character for VSCode and the ISE
            Write-Information "Detected something other than console host"
            [String]$TopLeft = "*"
            [String]$horizontal = "*"
            [String]$TopRight = "*"
            [String]$vertical = "*"
            [String]$BottomLeft = "*"
            [String]$BottomRight = "*"
        }
    } #begin

    Process {
        #do not run in the PowerShell ISE
        if ($host.name -match 'ISE Host') {
            Write-Warning "This command will not display properly in the Windows PowerShell ISE"
            #bail out
            Return
        }
        Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] Getting events for the next $Days days."

        if ($offline) {
            $target = (Get-Date).Date.AddDays($Days)
            $upcoming = Get-TickleEvent @InvokeParams | Where-Object { $_.Date -le $Target }
        }
        else {
            Try {
                $upcoming = Get-TickleEvent @InvokeParams
            }
            Catch {
                Throw $_
            }
        }
        if ($upcoming) {
            Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] $($upcoming.count) upcoming events found"
            #how wide should the box be?
            #get the length of the longest line
            $l = 0
            foreach ($item in $upcoming) {
                #turn countdown into a string without the milliseconds
                $count = $item.countdown.ToString()
                #10/31/2023 need to handle events where the countdown is 0
                If ($count -match "\.") {
                    $time = $count.Substring(0, $count.LastIndexOf("."))
                }
                else {
                    $time = "00:00:00"
                }
                #add the time as a new property
                $item | Add-Member -MemberType NoteProperty -Name Time -Value $time
                $a = "$($item.event) $($item.Date) [$time]".length
                if ($a -gt $l) { $l = $a }
                $b = $item.comment.Length

                if ($b -gt $l) { $l = $b }
            }

            #need to take ANSI escape sequence into account
            [Int]$width = $l + 11
            Write-Information "L = $l"
            Write-Information "width = $width"

            $header = " Reminders $((Get-Date).ToShortDateString()) "
            Write-Information "Header length = $($header.length)"

            "`r"

            $HeaderDisplay = "{0}{1}{2} {3}{4}{5} {6}{7}{8}{9}" -f $cyan, $TopLeft, $close, $reminderBox, $header, $close, $cyan, $($horizontal * ($width - 31)), $TopRight, $close
            Write-Information "HeaderDisplay length = $($HeaderDisplay.length)"
            $HeaderDisplay
            #blank line
            #account for ANSI sequences
            $blank = "$cyan$vertical$(' '*($HeaderDisplay.length-33))$vertical$close"
            $blank

            foreach ($event in $upcoming) {

                if ($event.countdown.TotalHours -le 24) {
                    $color = $red
                }
                elseif ($event.countdown.TotalHours -le 48) {
                    $color = $yellow
                }
                else {
                    $color = $green
                }

                $line1 = "$cyan$vertical$close $color$($event.event) $($event.Date) [$($event.time)]$close"
                Write-Information "line 1: $line1 length = $($line1.Length)"
                #pad to account for length of ANSI escape plus spaces
                "$($line1.PadRight($HeaderDisplay.length-9,' ')) $cyan$vertical$close"
                if ($event.comment -match "\w+") {
                    $line2 = "$cyan$vertical$close $color$($event.Comment)$close"
                    "$($line2.PadRight($HeaderDisplay.length-9, ' ')) $cyan$vertical$close"
                }
                $blank

                Write-Information "line 2: $line2 length = $($line2.length)"
                Write-Information "line 3: $line3 length = $($line3.length)"

            } #foreach

            #adjusted width to better draw the outline box 1/20/2021 JDH
            "$cyan$BottomLeft$($horizontal*($width-8))$BottomRight$close"
            "`r"
        } #if upcoming events found
        else {
            $t = "No event reminders in the next $days days"
            $len = $t.length + 2

            $msg = @"

    $cyan$TopLeft$($horizontal*$len)$TopRight$close
    $cyan$vertical$close $yellow$t$close $cyan$vertical$close
    $cyan$BottomLeft$($horizontal*$len)$BottomRight$close

"@
            $msg
        }

    } #process

    End {
        Write-Verbose "[$((Get-Date).TimeOfDay) END    ] Ending $($MyInvocation.MyCommand)"

    } #end
}
