# MyTickle #

This PowerShell module is designed as a tickle or reminder system. You can add and edit reminders of upcoming events. Use the module commands to display upcoming events.

This module stores event information in a SQL database. Ideally, you will be running a version of SQL Server Express on your desktop. You can use the `Initialize-TickleDatabase` command to create the database and table. It is possible to store the database on a separate server (not tested). The module includes T-SQL files you can give to a database administrator to run and create the database for you. 

The module uses a set of global variables to define the SQL connection. The default installation assumes a local SQLExpress instance.

```
PS C:\> Get-Variable Tickle*
Name                           Value
----                           -----
TickleDB                       TickleEventDB
TickleDefaultDays              7
TickleServerInstance           <computername>\SqlExpress
TickleTable                    EventData
```
If you use a remote server or some other named instance, you will need to change the value of $TickleServerInstance after you import the module. This is something you would most likely do in your PowerShell profile script.

```
$TickleServerInstance = 'chi-sql01'
```

The module should work cross-platform even on Linux, although in that situation you will need to specify a username and password and it is assumed the SQL Server is configured to use both SQL and Windows authentication.

*This module is very much still in development.*

_last updated 6 October 2017_
