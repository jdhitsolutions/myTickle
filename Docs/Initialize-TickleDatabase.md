---
external help file: MyTickle-help.xml
Module Name: mytickle
online version:
schema: 2.0.0
---

# Initialize-TickleDatabase

## SYNOPSIS

Initialize a new tickle event database.

## SYNTAX

### default (Default)

```yaml
Initialize-TickleDatabase [-DatabasePath] <String> [-ServerInstance <String>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### credential

```yaml
Initialize-TickleDatabase [-DatabasePath] <String> [-ServerInstance <String>] -Credential <PSCredential>
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Use this command to initialize a new tickle event database and table. You need to specify the path for the new database file. The command will use the built-in Tickle variables so update them if necessary before running this command.

## EXAMPLES

### Example 1

```powershell
PS C:\> Initialize-TickleDatabase -databasepath c:\db\mytickle
```

Initialize an empty database and create the files at c:\db\mytickle. The folder must exist before running this command.

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
Parameter Sets: credential
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DatabasePath

The folder for the database to be created.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 0
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

Shows what would happen if the cmdlet runs.
The cmdlet is not run.

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

### None

## OUTPUTS

### System.Object

## NOTES

## RELATED LINKS

[Import-TickleDatabase](Import-TickleDatabase.md)
