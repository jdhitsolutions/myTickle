---
external help file: MyTickle-help.xml
Module Name: MyTickle
online version: https://bit.ly/3sUUH6l
schema: 2.0.0
---

# Get-TickleDBInformation

## SYNOPSIS

Get information about the TickleEventDB database.

## SYNTAX

```yaml
Get-TickleDBInformation [-BackupInformation] [[-ServerInstance] <String>]
[[-Credential] <PSCredential>] [<CommonParameters>]
```

## DESCRIPTION

This command will display information about the tickle database.

## EXAMPLES

### Example 1

```powershell
PS C:\> Get-TickleDBInformation

Name           : TickleEventDB
Path           : C:\Program Files\Microsoft SQL Server\MSSQL15.SQLEXPRESS\MSSQL\DATA\TickleEventDB.mdf
SizeMB         : 100
UsedMB         : 3.375
AvailableMB    : 96.625
LastFullbackup : 4/23/2021 9:00:05 PM
```

This is the default, formatted result for this command.

### Example 2

```powershell
PS C:\>  Get-TickleDBInformation | Select-Object *

Name                           : TickleEventDB
Path                           : C:\Program Files\Microsoft SQL Server\MSSQL15.SQLEXPRESS\MSSQL\DATA\TickleEventDB.mdf
Size                           : 104857600
UsedSpace                      : 3538944
AvailableSpace                 : 101318656
LastFullBackup                 : 4/23/2021 9:00:05 PM
LastFullBackupLocation         : D:\OneDrive\Backup\TickleEventDB_20210423.bak
LastDifferentialBackup         :
LastDifferentialBackupLocation :
LastLogBackup                  :
LastLogBackupLocation          :
Date                           : 4/28/2021 8:41:29 AM
```

The information object includes backup information. You can view backup information alone by running Get-TickleDBInformation -BackupInformation or Get-TickleDBInformation | format-list -view backup.

## PARAMETERS

### -BackupInformation

Display backup information only.

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

### -Credential

Specify a credential to authenticate to the SQL Server instance. This should normally not be required.

```yaml
Type: PSCredential
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
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
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

## OUTPUTS

### myTickleDBInfo

## NOTES

Learn more about PowerShell: http://jdhitsolutions.com/blog/essential-powershell-resources/

## RELATED LINKS

[Export-TickleDatabase](Export-TickleDatabasae.md)

[Import-TickleDatabase](Import-TickleDatabasae.md)
