# Change Log for MyTickle

## v2.8.0

+ raised minimum PowerShell version to 5.1
+ updated manifest to support both desktop and core

## v2.7.0

+ Explicitly exporting functions for PowerShell Core.
+ Help updates
+ minor file formatting

## v2.6.1

+ file cleanup for the published module in the PowerShell Gallery

## v2.6.0

+ Updated the offline process to not import past events and to default to using the $TickleDefaultDays

## v2.5.0

+ Fixed bug with `Get-TickleEvent` that was including expired items
+ Updated event class to display expired events with a timespan of 0
+ Updated format.ps1xml to reflect expired timespan
+ Modified `Get-TickleEvent` to find names with wildcards
+ Added `event` alias to Name parameter for `Get-TickleEvent`
+ Updated help

## v2.4.0

+ Added support for offline use (read-only)
+ Made DatabasePath mandatory for `Initialize-TickleDatabase`
+ Updated `Import-TickleDatabase` to suppress SQL output
+ Updated `Import-TickleDatabase` to remove apostrophe's in event names
+ Revised parameters for `Get-TickleEvent`
+ Added OutputType definitions
+ Added help documentation
+ Updated README

## v2.3.1

+ modified default instance name to not include a computer name (Issue #8)

## v2.3.0

+ Updated `README.md`
+ adjustments to `mytickle.format.ps1xml` file
+ Fixed bug in `Initialize-TickleDatabase` when creating a remote database and table
+ initial beta

## v2.2.2

+ Modified to support database setup on a remote SQL server (Issue #7)
+ Remote setup is still under development
+ Added custom format extension (Issue #1)

## v2.2.1

+ updated manifest
+ made github repository public

## v2.2.0

+ fixed problem with variables not exporting.
+ Changed default server instance to an exported tickle variable

## v2.1.0

+ modified code to use .NET SQL classes and not rely on the SQLPS module
+ Added "name" alias to Event parameter in `Add-TickleEvent` and `Set-TickleEvent`
+ Modified query in `Get-TickleEvent` to ignore archived and expired items when
+ searching by event name.
+ Modified `Get-TickleEvent` to retrieve archived entries
+ Added `Export-TickleDatabase` command
+ Added `Import-TickleDatabase` command
+ Modified commands to accept a user credential for SQL authentication

## v2.0.0

+ Modified module so that tickle data is stored in a SQL database.
+ Added functions to create database and table.
+ Moved functions to separate file
+ Added class definition
+ Updated documentation
+ set required PowerShell version to 5.0
