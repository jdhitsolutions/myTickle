---
external help file: MyTickle-help.xml
Module Name: myTickle
online version: https://github.com/jdhitsolutions/myTickle/blob/master/Docs/Show-TickleEvent.md
schema: 2.0.0
---

# Show-TickleEvent

## SYNOPSIS

Display a colorized list of upcoming events.

## SYNTAX

### instance (Default)

```yaml
Show-TickleEvent [-Days <Int32>] [-ServerInstance <String>] [-Credential <PSCredential>] [<CommonParameters>]
```

### offline

```yaml
Show-TickleEvent [-Days <Int32>] [-Offline <String>] [<CommonParameters>]
```

## DESCRIPTION

This is a specialized version of Get-TickleEvent that uses ANSI-escape sequences to display a formatted and colorized display of upcoming events. Events due in 24 hours or less will be displayed in red. Events due in 48 hours or less will be displayed in yellow. Otherwise, the event is displayed in green. It is not possible to modify these colors at this time. The default behavior is to show events due in the next number of days as specified by the $TickleDefaultDays variable.

## EXAMPLES

### Example 1

```powershell
PS C:\> Show-TickleEvent

* Reminders 9/23/2021 *********************************
*                                                     *
* Project Review 09/25/2021 00:00:00 [1.02:25:46]     *
*                                                     *
* Haircut 09/27/2021 16:00:00 [3.18:29:02]            *
*                                                     *
*******************************************************
```

The actual console output will be colorized. If your PowerShell console supports it, you may also see a lined box instead of the asterisk characters.

## PARAMETERS

### -Credential

Specify a credential to authenticate to the SQL Server instance. This should normally not be required.

```yaml
Type: PSCredential
Parameter Sets: instance
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Days

Specify the next number of days to display.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: $TickleDefaultDays
Accept pipeline input: False
Accept wildcard characters: False
```

### -Offline

Use an offline version of the tickle event database. Specify the path to the CSV file.

```yaml
Type: String
Parameter Sets: offline
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
Parameter Sets: instance
Aliases:

Required: False
Position: Named
Default value: $TickleServerInstance
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

## OUTPUTS

### None. This command writes to the PowerShell host.

## NOTES

Learn more about PowerShell: http://jdhitsolutions.com/blog/essential-powershell-resources/

## RELATED LINKS

[Get-TickleEvent](Get-TickleEvent.md)
