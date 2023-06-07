# ChangeLog for MyTickle

## 3.3.2

### Changed

- Code clean-up.
- Help revisions.
- Changed statements using `Out-Null` to use `[void]`.
- Updated README.md.

## 3.3.1

- Fixed minor typos in help documentation.
- Updated `about_MyTickle.md`.
- Cleaned up module manifest.
- Updated README.md.

## 3.3.0

- Module manifest cleanup.
- Added an alias property of `Name` for `Event` on the `myTickle` object.
- Help updates.
- Updated default formatting to use ANSI color schemes to highlight upcoming events.
- Updated `README.md`.

## v3.2.1

- Working on the box outline dimensions in the `Show-TickleEvent` function.
- Fixed bug in `Show-TickleEvent` that wasn't passing `Days` value when using `-Offline`. ([Issue #14](https://github.com/jdhitsolutions/myTickle/issues/14))
- Updated license year

## v3.2.0

- Fixed bug in `Set-TickleEvent` that was failing to rename an event. ([Issue #12](https://github.com/jdhitsolutions/myTickle/issues/12))
- Updated `Show-TickleEvent` to adjust line widths for the box outline.
- Added a new formatted table view called `date`.
- Updates to the about Help topic.
- Added missing online help link for `Import-TickleDatabase`.
- Updated the private function `_InvokeSQLQuery` to be able to run stored procedures.
- Added `Get-TickleDBInformation` to display database information with custom views in `mytickle.format.ps1xml`.
- Updated `README.md`

## v3.1.0

- Modified `Get-TickleEvent` to not accept multiple ID numbers. Instead, the function will take pipeline input. ([Issue #11](https://github.com/jdhitsolutions/myTickle/issues/11))
- Modified `Get-TickleEvent` to accept `Name` parameter values from the pipeline.
- Renamed `Event` parameter in `Set-TickleEvent` and `Add-TickleEvent` to `EventName`.
- Renamed `Name` parameter in `Get-TickleEvent` to `EventName`. Added `Name` as a parameter alias for backward compatibility.
- Help updates.

## v3.0.0

- Modified `Show-TickleEvent` to use ANSI escape sequences in place of `Write-Host`. ([Issue #12](https://github.com/jdhitsolutions/myTickle/issues/12)) *Breaking Change*
- Modified `Show-TickleEvent` to display a warning and not run in the PowerShell ISE.
- `Show-TickleEvent` now uses special characters for the border if the console will support them. Otherwise, it will default to standard characters like "*".
- Restructured the module layout.
- Updated `README.md`.
- Help documentation updates.

## v2.8.0

- Raised the minimum PowerShell version to 5.1.
- Updated the module manifest to support both desktop and core.

## v2.7.0

- Explicitly exporting functions for PowerShell Core.
- Help updates.
- Minor file formatting.

## v2.6.1

- File cleanup for the published module in the PowerShell Gallery.

## v2.6.0

- Updated the offline process to not import past events and default to using the `$TickleDefaultDays`.

## v2.5.0

- Fixed bug with `Get-TickleEvent` that was including expired items.
- Updated event class to display expired events with a timespan of 0.
- Updated format.ps1xml to reflect expired timespan.
- Modified `Get-TickleEvent` to find names with wildcards.
- Added `event` alias to Name parameter for `Get-TickleEvent`.
- Updated help.

## v2.4.0

- Added support for offline use (read-only).
- Made DatabasePath mandatory for `Initialize-TickleDatabase`.
- Updated `Import-TickleDatabase` to suppress SQL output.
- Updated `Import-TickleDatabase` to remove apostrophe's in event names.
- Revised parameters for `Get-TickleEvent`.
- Added OutputType definitions.
- Added help documentation.
- Updated README.

## v2.3.1

- Modified the default instance name to not include a computer name. (Issue #8)

## v2.3.0

- Updated `README.md`.
- Made adjustments to the `mytickle.format.ps1xml` file.
- Fixed bug in `Initialize-TickleDatabase` when creating a remote database and table.
- Initial beta release

## v2.2.2

- Modified to support database setup on a remote SQL server. (Issue #7)
- Remote setup is still under development.
- Added custom format extension. (Issue #1)

## v2.2.1

- Updated the module manifest.

## v2.2.0

- Fixed a problem with variables not exporting.
- Changed default server instance to an exported tickle variable.

## v2.1.0

- Modified code to use .NET SQL classes and not rely on the SQLPS module
- Added "name" alias to Event parameter in `Add-TickleEvent` and `Set-TickleEvent`.
- Modified query in `Get-TickleEvent` to ignore archived and expired items when searching by event name.
- Modified `Get-TickleEvent` to retrieve archived entries.
- Added `Export-TickleDatabase` command.
- Added `Import-TickleDatabase` command.
- Modified commands to accept a user credential for SQL authentication.

## v2.0.0

- Modified module so that tickle data is stored in a SQL database.
- Added functions to create database and table.
- Moved functions to a separate file.
- Added class definition.
- Updated documentation.
- Set required PowerShell version to 5.0.
