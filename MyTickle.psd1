

@{

    # Script module or binary module file associated with this manifest.
    RootModule           = 'MyTickle.psm1'

    # Version number of this module.
    ModuleVersion        = '3.3.0'

    # ID used to uniquely identify this module
    GUID                 = 'e9534710-29f8-4291-be97-5c2b2df324c1'

    # Author of this module
    Author               = 'Jeff Hicks'

    # Company or vendor of this module
    CompanyName          = 'JDH Information Technology Solutions, Inc.'

    CompatiblePSEditions = "Desktop", "Core"

    # Copyright statement for this module
    Copyright            = '(c) 2017-2021 JDH Information Technology Solutions, Inc.'

    # Description of the functionality provided by this module
    Description          = 'A PowerShell module with commands for a simple event tickler system using a SQL Server instance as the backend storage.'

    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion    = '5.1'

    # Type files (.ps1xml) to be loaded when importing this module
    # TypesToProcess = @()

    # Format files (.ps1xml) to be loaded when importing this module
    FormatsToProcess     = 'formats\mytickle.format.ps1xml'

    # Functions to export from this module
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

    # Variables to export from this module
    VariablesToExport    = @(
        'tickledb',
        'tickledefaultdays',
        'tickleserverinstance',
        'tickletable'
    )

    # Aliases to export from this module
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

            # Tags applied to this module. These help with module discovery in online galleries.
            Tags         = @('reminder', 'tickle', 'calendar', 'database','SQL')

            # A URL to the license for this module.
            LicenseUri   = 'https://github.com/jdhitsolutions/myTickle/blob/master/LICENSE.txt'

            # A URL to the main website for this project.
            ProjectUri   = 'https://github.com/jdhitsolutions/myTickle'

            # A URL to an icon representing this module.
            IconUri      = 'https://raw.githubusercontent.com/jdhitsolutions/myTickle/master/assets/db.png'

            # ReleaseNotes of this module
            ReleaseNotes = 'https://github.com/jdhitsolutions/myTickle/blob/master/README.md'

        } # End of PSData hashtable

    } # End of PrivateData hashtable

    # HelpInfo URI of this module
    # HelpInfoURI = ''

    # Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
    # DefaultCommandPrefix = ''

}

