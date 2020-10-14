---
external help file: MyTickle-help.xml
Module Name: mytickle
online version:
schema: 2.0.0
---

# Set-TickleEvent

## SYNOPSIS

Modify a tickle event.

## SYNTAX

### column (Default)

```yaml
Set-TickleEvent [-ID] <Int32> [-Event <String>] [-Date <DateTime>] [-Comment <String>]
 [-ServerInstance <String>] [-Credential <PSCredential>] [-Passthru] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### archive

```yaml
Set-TickleEvent [-ID] <Int32> [-ServerInstance <String>] [-Credential <PSCredential>] [-Passthru] [-Archive]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Use this command to update or modify an existing tickle event. This command will use the Tickle variables for its defaults.

## EXAMPLES

### Example 1

```powershell
PS C:\> Set-TickleEvent -id 100 -date "8/1/2020 5:00PM"
```

Set a new date for tickle event ID 100.

### Example 2

```powershell
PS C:\> Get-TickleEvent -expired | Set-TickleEvent -archived
```

Get all expired events and mark them as archived.

## PARAMETERS

### -Archive

Mark an entry as archived. The current version of the module retains all events in a single database table.

```yaml
Type: SwitchParameter
Parameter Sets: archive
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Comment

Update the event comment field.

```yaml
Type: String
Parameter Sets: column
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm

Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

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
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Date

Update the event's date field.

```yaml
Type: DateTime
Parameter Sets: column
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Event

Update the event name.

```yaml
Type: String
Parameter Sets: column
Aliases: Name

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ID

Select an event by its ID.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Passthru

Write the updated event back to the pipeline.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
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
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: $TickleServerInstance
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf

Shows what would happen if the cmdlet runs. The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.Int32

## OUTPUTS

### None

### MyTickle

## NOTES

Learn more about PowerShell: http://jdhitsolutions.com/blog/essential-powershell-resources/

## RELATED LINKS

[Add-TickleEvent](Add-TickleEvent.md)

[Get-TickleEvent](Get-TickleEvent.md)
