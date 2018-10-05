---
external help file: MyTickle-help.xml
Module Name: MyTickle
online version:
schema: 2.0.0
---

# Get-TickleEvent

## SYNOPSIS

Get one or more tickle event entries.

## SYNTAX

### Days (Default)

```yaml
Get-TickleEvent [-Next <Int32>] [-ServerInstance <String>] [-Credential <PSCredential>] [<CommonParameters>]
```

### ID

```yaml
Get-TickleEvent [-Id <Int32[]>] [-ServerInstance <String>] [-Credential <PSCredential>] [<CommonParameters>]
```

### Name

```yaml
Get-TickleEvent [-Name <String>] [-ServerInstance <String>] [-Credential <PSCredential>] [<CommonParameters>]
```

### All

```yaml
Get-TickleEvent [-All] [-ServerInstance <String>] [-Credential <PSCredential>] [<CommonParameters>]
```

### Expired

```yaml
Get-TickleEvent [-Expired] [-ServerInstance <String>] [-Credential <PSCredential>] [<CommonParameters>]
```

### Archived

```yaml
Get-TickleEvent [-Archived] [-ServerInstance <String>] [-Credential <PSCredential>] [<CommonParameters>]
```

### Offline

```yaml
Get-TickleEvent [-Next <Int32>] [-Offline <String>] [<CommonParameters>]
```

## DESCRIPTION

This command will query the tickle event database and return matching events. The parameters are used to fine-tune the query and should be self-explanatory.

The default behavior is to query the designated SQL Server instance, but you can specify a CSV file of event log entries and access the event data in an offline, or read-only mode.

## EXAMPLES

### Example 1

```powershell
PS C:\> Get-TickleEvent
```

Display all non-expired and non-archived events.

### Example 2

```powershell
PS C:\> Get-TickleEvent -next 14
```

Display all non-expired and non-archived events scheduled for the next 14 days.

### Example 3

```powershell
PS C:\> Get-TickleEvent -offline c:\users\jeff\dropbox\tickledb.csv
```

Display all non-expired from an offline source. By default, offline mode will display events scheduled for the next number days specified by $TickleDefaultDays or the value of the -Next parameter.

## PARAMETERS

### -All

List all entries in the tickle event database table.

```yaml
Type: SwitchParameter
Parameter Sets: All
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Archived

List entries that have been marked as Archived.

```yaml
Type: SwitchParameter
Parameter Sets: Archived
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Credential

Specify a credential to authenticate to the SQL Server instance. This should normally not be required.

```yaml
Type: PSCredential
Parameter Sets: Days, ID, Name, All, Expired, Archived
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Expired

Display events that have expired.

```yaml
Type: SwitchParameter
Parameter Sets: Expired
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Id

Display an event by its ID number.

```yaml
Type: Int32[]
Parameter Sets: ID
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Name

Display an event by its name. You can use wildcards.

```yaml
Type: String
Parameter Sets: Name
Aliases: event

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: True
```

### -Next

Get events in the next number of days.

```yaml
Type: Int32
Parameter Sets: Days, Offline
Aliases: days

Required: False
Position: Named
Default value: $TickleDefaultDays
Accept pipeline input: False
Accept wildcard characters: False
```

### -Offline

Access an offline, CSV version. It is assumed you have previously run a command like Get-TickleEvent | Export-CSV tickleexport.csv

Offline mode will not include any past events.

```yaml
Type: String
Parameter Sets: Offline
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ServerInstance

The name of your SQL Server instance. The parameter will default to the module variable.

```yaml
Type: String
Parameter Sets: Days, ID, Name, All, Expired, Archived
Aliases:

Required: False
Position: Named
Default value: $TickleServerInstance
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

## OUTPUTS

### MyTickle

## NOTES

Learn more about PowerShell: http://jdhitsolutions.com/blog/essential-powershell-resources/

## RELATED LINKS

[Set-TickleEvent]()

[Add-TickleEvent]()