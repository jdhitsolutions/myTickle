Function Get-TickleDBInformation {
    [CmdletBinding()]
    [OutputType("myTickleDBInfo")]
    Param(
        [Parameter(HelpMessage = "Display backup information only.")]
        [Switch]$BackupInformation,
        [ValidateNotNullOrEmpty()]
        [String]$ServerInstance = $TickleServerInstance,
        [ValidateNotNullOrEmpty()]
        [PSCredential]$Credential
    )

    #remove BackupInformation from PSBoundParameters
    if ($PSBoundParameters.ContainsKey("BackupInformation")) {
        [void]($PSBoundParameters.remove("BackupInformation"))
    }

    $query = @"
SELECT f.[name] AS [FileName], f.physical_name AS [Path], size,
FILEPROPERTY(f.name, 'SpaceUsed') AS Used,
f.size - FILEPROPERTY(f.name, 'SpaceUsed') AS [Available]
FROM sys.database_files AS f WITH (NOLOCK)
LEFT OUTER JOIN sys.filegroups AS fg WITH (NOLOCK)
ON f.data_space_id = fg.data_space_id
where f.[name] = 'TickleEvents'
ORDER BY f.[type], f.[file_id] OPTION (RECOMPILE);
"@

    $PSBoundParameters.Add("Query", $query)
    $PSBoundParameters.Add("Database", "TickleEventDB")
    $r = _InvokeSqlQuery @PSBoundParameters
    if ($r) {

        #get backup information. The query returns more information than I am using now.
        $q = @"
Select ISNULL(d.[name], bs.[database_name]) AS [Database], d.recovery_model_desc AS [RecoveryModel],
MAX(CASE WHEN [type] = 'D' THEN bs.backup_finish_date ELSE NULL END) AS [LastFullBackup],
MAX(CASE WHEN [type] = 'D' THEN bmf.physical_device_name ELSE NULL END) AS [LastFullBackupLocation],
MAX(CASE WHEN [type] = 'I' THEN bs.backup_finish_date ELSE NULL END) AS [LastDifferentialBackup],
MAX(CASE WHEN [type] = 'I' THEN bmf.physical_device_name ELSE NULL END) AS [LastDifferentialBackupLocation],
MAX(CASE WHEN [type] = 'L' THEN bs.backup_finish_date ELSE NULL END) AS [LastLogBackup],
MAX(CASE WHEN [type] = 'L' THEN bmf.physical_device_name ELSE NULL END) AS [LastLogBackupLocation]
FROM sys.databases  AS d WITH (NOLOCK)
LEFT OUTER JOIN msdb.dbo.backupset AS bs WITH (NOLOCK)
ON bs.[database_name] = d.[name]
LEFT OUTER JOIN msdb.dbo.backupmediafamily AS bmf WITH (NOLOCK)
ON bs.media_set_id = bmf.media_set_id
AND bs.backup_finish_date > GETDATE()- 30
Where d.name = N'TickleEventDB'
Group BY ISNULL(d.[name], bs.[database_name]), d.recovery_model_desc, d.log_reuse_wait_desc, d.[name]
ORDER BY d.recovery_model_desc, d.[name] OPTION (RECOMPILE);
"@
        $PSBoundParameters.query = $q
        $PSBoundParameters.database = "master"
        $BackupInfo = _InvokeSqlQuery @PSBoundParameters
        #create a composite custom object
        $obj = [PSCustomObject]@{
            PSTypename                     = "myTickleDBInfo"
            Name                           = "TickleEventDB"
            Path                           = $r.path
            Size                           = $r.Size * 8KB
            UsedSpace                      = $r.used * 8KB
            AvailableSpace                 = $r.available * 8KB
            LastFullBackup                 = $BackupInfo.LastFullBackup
            LastFullBackupLocation         = $BackupInfo.LastFullBackupLocation
            LastDifferentialBackup         = $BackupInfo.LastDifferentialBackup
            LastDifferentialBackupLocation = $BackupInfo.LastDifferentialBackupLocation
            LastLogBackup                  = $BackupInfo.LastLogBackup
            LastLogBackupLocation          = $BackupInfo.LastLogBackupLocation
            Date                           = Get-Date
        }
        if ($BackupInformation) {
            $obj | Select-Object -Property Name,Path,Last*
        }
        else {
            $obj
        }
    } #if $r
}
