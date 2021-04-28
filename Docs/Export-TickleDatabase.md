---
external help file: MyTickle-help.xml
Module Name: myTickle
online version: https://bit.ly/3sXrQOL
schema: 2.0.0
---

# Export-TickleDatabase

## SYNOPSIS

Export a tickle database to a Clixml file.

## SYNTAX

```yaml
Export-TickleDatabase [-Path] <String> [-ServerInstance <String>] [-Credential <PSCredential>]
 [<CommonParameters>]
```

## DESCRIPTION

Use this command to export the entire tickle database to an XML file. This can be in addition to whatever SQL Server backup procedures you may follow. The XML file is created with Export-CliXML.

## EXAMPLES

### Example 1

```powershell
PS C:\> Export-TickleDatabase -path C:\users\jeff\dropbox\tickle\export.xml
```

Export the database to a Dropbox folder.

## PARAMETERS

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

### -Path

The path and filename for the export XML file.

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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

## OUTPUTS

### None

## NOTES

Learn more about PowerShell: http://jdhitsolutions.com/blog/essential-powershell-resources/

## RELATED LINKS

[Import-TickleDatabase](Import-TickleDatabase.md)

[Get-TickleDBInformation](Get-TickleDBInformation.md)
