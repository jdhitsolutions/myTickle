---
external help file: MyTickle-help.xml
Module Name: myTickle
online version: https://bit.ly/2R33je0
schema: 2.0.0
---

# Remove-TickleEvent

## SYNOPSIS

Delete a tickle event from the database.

## SYNTAX

```yaml
Remove-TickleEvent [-ID] <Int32> [-ServerInstance <String>] [-Credential <PSCredential>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Events in the tickle database remain, even though they may not be displayed by default. Normally, you can archive expired events. However, you can also delete entries with this command.

## EXAMPLES

### Example 1

```powershell
PS C:\> Remove-TickleEvent -id 100
```

Removed the event with an ID of 100.

### Example 2

```powershell
PS C:\> Get-TickleEvent -name Dentist | Remove-TickleEvent
```

Remove all tickle events with the name "Dentist". This will only remove un-expired and un-archived entries.

## PARAMETERS

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

### -ID

A tickle event ID.

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

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.Int32

## OUTPUTS

### None

## NOTES

Learn more about PowerShell: http://jdhitsolutions.com/blog/essential-powershell-resources/

## RELATED LINKS

[Set-TickleEvent](Set-TickleEvent.md)

[Add-TickleEvent](Add-TickleEvent.md)
