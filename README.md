# MyTickle

This PowerShell module is designed as a tickle or reminder system. You can add and edit reminders of upcoming events. Use the module commands to display upcoming events. If you are interested, the core object of the module is based on a PowerShell class.

You can install the latest version from the PowerShell Gallery.

```powershell
Install-Module MyTickle
```

This module requires a SQL Server installation but it should work cross platform and in PowerShell Core.

This module stores event information in a SQL database. Ideally, you will be running a version of SQL Server Express on your desktop. You can use the `Initialize-TickleDatabase` command to create the database and table. It is possible to store the database on a separate server (not tested). The module includes T-SQL files you can give to a database administrator to run and create the database for you.

The module uses a set of global variables to define the SQL connection. The default installation assumes a local SQL Server Express instance.

```powershell
PS C:\> Get-Variable Tickle*
Name                           Value
----                           -----
TickleDB                       TickleEventDB
TickleDefaultDays              7
TickleServerInstance           <computername>\SqlExpress
TickleTable                    EventData
```

If you use a remote server or some other named instance, you will need to change the value of $TickleServerInstance after you import the module. This is something you would most likely do in your PowerShell profile script.

```powershell
$TickleServerInstance = 'chi-sql01'
```

The module should work cross-platform even on Linux, although in that situation you will need to specify a username and password and it is assumed the SQL Server is configured to use both SQL and Windows authentication.

Once initialized and with entries added, you can easily get a look at upcoming events.

![get-tickleevent](assets/get-tickleevent.png)

Or display upcoming events in a color-coded format. The default is events in the next 7 days, but you can specify a different value.

![show-tickleevent](assets/show-tickleevent.png)

Events due in the next 24 hours will be displayed in red. Events due in 48 hours or less will be shown in yellow.

For more information, please read the [About](docs/about_MyTickle.md) help topic.

_last updated 9 January 2019_
