---
external help file: MyTickle-help.xml
Module Name: MyTickle
online version: https://github.com/jdhitsolutions/myTickle/blob/master/Docs/Add-TickleEvent.md
schema: 2.0.0
---

# Add-TickleEvent

## SYNOPSIS

Add an entry to the tickle database.

## SYNTAX

```yaml
Add-TickleEvent [-EventName] <String> [-Date] <DateTime> [[-Comment] <String>] [-ServerInstance <String>]
 [-Credential <PSCredential>] [-Passthru] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Add a tickle event to the database. The command will use the global Tickle variables, although you can override the server instance parameter. It is strongly recommended that you avoid using special characters, especially apostrophes and commas, in your event name.

## EXAMPLES

### Example 1

```powershell
PS C:\> Add-TickleEvent -event "company picnic" -date "7/1/2021 12:00PM"
```

Add an event to the database.

## PARAMETERS

### -Comment

Enter an option comment or description.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: True (ByPropertyName)
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

Enter the date and time for the event.

```yaml
Type: DateTime
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Passthru

Write the new event object to the pipeline.

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

### -EventName

Enter the name of the event.

```yaml
Type: String
Parameter Sets: (All)
Aliases: Name

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String

### System.DateTime

## OUTPUTS

### None

### MyTickle

## NOTES

Learn more about PowerShell: http://jdhitsolutions.com/blog/essential-powershell-resources/

## RELATED LINKS

[Get-TickleEvent](Get-TickleEvent.md)

[Set-TickleEvent](Set-TickleEvent.md)
