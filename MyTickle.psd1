@{
    RootModule           = 'MyTickle.psm1'
    ModuleVersion        = '3.3.2'
    GUID                 = 'e9534710-29f8-4291-be97-5c2b2df324c1'
    Author               = 'Jeff Hicks'
    CompanyName          = 'JDH Information Technology Solutions, Inc.'
    CompatiblePSEditions = "Desktop", "Core"
    Copyright            = '(c) 2017-2023 JDH Information Technology Solutions, Inc.'
    Description          = 'A PowerShell module with commands for a simple event tickler system using a SQL Server instance as the backend storage.'
    PowerShellVersion    = '5.1'
    # TypesToProcess = @()
    FormatsToProcess     = 'formats\mytickle.format.ps1xml'
    FunctionsToExport    = @(
        'Get-TickleEvent',
        'Set-TickleEvent',
        'Add-TickleEvent',
        'Remove-TickleEvent',
        'Initialize-TickleDatabase',
        'Export-TickleDatabase',
        'Import-TickleDatabase',
        'Show-TickleEvent',
        'Get-TickleDBInformation'
    )
    VariablesToExport    = @(
        'tickledb',
        'tickledefaultdays',
        'tickleserverinstance',
        'tickletable'
    )
    AliasesToExport      = @(
        'gte',
        'ate',
        'rte',
        'shte',
        'ste'
    )
    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData          = @{

        PSData = @{
            Tags         = @('reminder', 'tickle', 'calendar', 'database', 'SQL')
            LicenseUri   = 'https://github.com/jdhitsolutions/myTickle/blob/master/LICENSE.txt'
            ProjectUri   = 'https://github.com/jdhitsolutions/myTickle'
            IconUri      = 'https://raw.githubusercontent.com/jdhitsolutions/myTickle/master/assets/db.png'
            ReleaseNotes = 'https://github.com/jdhitsolutions/myTickle/blob/master/README.md'

        } # End of PSData hashtable

    } # End of PrivateData hashtable

}

