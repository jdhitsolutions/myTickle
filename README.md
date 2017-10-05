# MyTickle #

This PowerShell module is designed as a tickle or reminder system. You can add and edit reminders of upcoming events. Use the module commands to display upcoming events.

This module stores event information in a SQL database. Ideally, you will be running a version of SQL Server Express on your desktop. You can use the `Initialize-TickleDatabase` command to create the database and table. It is possible to store the database on a separate server (not tested). The module includes T-SQL files you can give to a database administrator to run and create the database for you. *SETUP ON A REMOTE SQL SERVER IS STILL UNDER DEVELOPMENT*

The module should work cross-platform even on Linux, although in that situation you will need to specify a username and password and it is assumed the SQL Server is configured to use both SQL and Windows authentication.

*This module is very much still in development.*

_last updated 5 October 2017_
