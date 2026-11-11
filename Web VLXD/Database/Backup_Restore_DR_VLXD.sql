-- ============================================================================
-- VLXD-PRO: Disaster Recovery & Backup Automation Script
-- Target: RTO < 30 minutes | RPO <= 15 minutes (Full + Diff + Log chain)
-- Database: QL_CUA_HANG_VLXD
-- ============================================================================
USE [QL_CUA_HANG_VLXD];
GO

-- Ensure FULL recovery model so point-in-time log backups & fast DR work cleanly
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = N'QL_CUA_HANG_VLXD' AND recovery_model_desc <> N'FULL')
BEGIN
    ALTER DATABASE [QL_CUA_HANG_VLXD] SET RECOVERY FULL WITH NO_WAIT;
END
GO

-- 1. Stored Procedure: Full Backup + Verification
CREATE OR ALTER PROCEDURE dbo.sp_VLXD_BackupFull
    @BackupDir NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Dir NVARCHAR(500) = ISNULL(@BackupDir, CAST(SERVERPROPERTY('InstanceDefaultBackupPath') AS NVARCHAR(500)));
    IF RIGHT(@Dir, 1) NOT IN (N'\', N'/') SET @Dir += N'\';

    DECLARE @Stamp NVARCHAR(32) = FORMAT(GETDATE(), 'yyyyMMdd_HHmmss');
    DECLARE @FilePath NVARCHAR(600) = @Dir + N'QL_CUA_HANG_VLXD_FULL_' + @Stamp + N'.bak';
    DECLARE @BackupName NVARCHAR(200) = N'QL_CUA_HANG_VLXD Full Backup ' + @Stamp;

    BACKUP DATABASE [QL_CUA_HANG_VLXD]
    TO DISK = @FilePath
    WITH INIT, CHECKSUM, STATS = 25, NAME = @BackupName;

    -- Verify backup integrity immediately
    RESTORE VERIFYONLY FROM DISK = @FilePath WITH CHECKSUM;

    SELECT @FilePath AS BackupFilePath, N'FULL_VERIFIED' AS Status, GETDATE() AS CompletedAt;
END
GO

-- 2. Stored Procedure: Differential Backup (fast periodic RPO checkpoint)
CREATE OR ALTER PROCEDURE dbo.sp_VLXD_BackupDiff
    @BackupDir NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Dir NVARCHAR(500) = ISNULL(@BackupDir, CAST(SERVERPROPERTY('InstanceDefaultBackupPath') AS NVARCHAR(500)));
    IF RIGHT(@Dir, 1) NOT IN (N'\', N'/') SET @Dir += N'\';

    DECLARE @Stamp NVARCHAR(32) = FORMAT(GETDATE(), 'yyyyMMdd_HHmmss');
    DECLARE @FilePath NVARCHAR(600) = @Dir + N'QL_CUA_HANG_VLXD_DIFF_' + @Stamp + N'.bak';
    DECLARE @BackupName NVARCHAR(200) = N'QL_CUA_HANG_VLXD Differential Backup ' + @Stamp;

    BACKUP DATABASE [QL_CUA_HANG_VLXD]
    TO DISK = @FilePath
    WITH DIFFERENTIAL, INIT, CHECKSUM, STATS = 25, NAME = @BackupName;

    RESTORE VERIFYONLY FROM DISK = @FilePath WITH CHECKSUM;

    SELECT @FilePath AS BackupFilePath, N'DIFF_VERIFIED' AS Status, GETDATE() AS CompletedAt;
END
GO

-- 3. Stored Procedure: Transaction Log Backup (supports RPO <= 15 minutes)
CREATE OR ALTER PROCEDURE dbo.sp_VLXD_BackupLog
    @BackupDir NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Dir NVARCHAR(500) = ISNULL(@BackupDir, CAST(SERVERPROPERTY('InstanceDefaultBackupPath') AS NVARCHAR(500)));
    IF RIGHT(@Dir, 1) NOT IN (N'\', N'/') SET @Dir += N'\';

    DECLARE @Stamp NVARCHAR(32) = FORMAT(GETDATE(), 'yyyyMMdd_HHmmss');
    DECLARE @FilePath NVARCHAR(600) = @Dir + N'QL_CUA_HANG_VLXD_LOG_' + @Stamp + N'.trn';
    DECLARE @BackupName NVARCHAR(200) = N'QL_CUA_HANG_VLXD Log Backup ' + @Stamp;

    BACKUP LOG [QL_CUA_HANG_VLXD]
    TO DISK = @FilePath
    WITH INIT, CHECKSUM, STATS = 25, NAME = @BackupName;

    RESTORE VERIFYONLY FROM DISK = @FilePath WITH CHECKSUM;

    SELECT @FilePath AS BackupFilePath, N'LOG_VERIFIED' AS Status, GETDATE() AS CompletedAt;
END
GO

-- 4. Reference Emergency Restore Procedure in master (RTO < 30 minutes)
USE [master];
GO

CREATE OR ALTER PROCEDURE dbo.sp_VLXD_RestoreEmergency
    @FullBackupFile NVARCHAR(600),
    @DiffBackupFile NVARCHAR(600) = NULL,
    @TargetDbName NVARCHAR(128) = N'QL_CUA_HANG_VLXD'
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @StartUtc DATETIME2 = SYSUTCDATETIME();

    -- Verify source backup before cutting connections
    RESTORE VERIFYONLY FROM DISK = @FullBackupFile WITH CHECKSUM;
    IF @DiffBackupFile IS NOT NULL
        RESTORE VERIFYONLY FROM DISK = @DiffBackupFile WITH CHECKSUM;

    DECLARE @Sql NVARCHAR(MAX);
    IF EXISTS (SELECT 1 FROM sys.databases WHERE name = @TargetDbName)
    BEGIN
        SET @Sql = N'ALTER DATABASE ' + QUOTENAME(@TargetDbName) + N' SET SINGLE_USER WITH ROLLBACK IMMEDIATE;';
        EXEC sp_executesql @Sql;
    END

    IF @DiffBackupFile IS NULL
    BEGIN
        SET @Sql = N'RESTORE DATABASE ' + QUOTENAME(@TargetDbName) +
                   N' FROM DISK = @pFull WITH REPLACE, RECOVERY, CHECKSUM, STATS = 25;';
        EXEC sp_executesql @Sql, N'@pFull NVARCHAR(600)', @pFull = @FullBackupFile;
    END
    ELSE
    BEGIN
        SET @Sql = N'RESTORE DATABASE ' + QUOTENAME(@TargetDbName) +
                   N' FROM DISK = @pFull WITH REPLACE, NORECOVERY, CHECKSUM, STATS = 25;';
        EXEC sp_executesql @Sql, N'@pFull NVARCHAR(600)', @pFull = @FullBackupFile;

        SET @Sql = N'RESTORE DATABASE ' + QUOTENAME(@TargetDbName) +
                   N' FROM DISK = @pDiff WITH RECOVERY, CHECKSUM, STATS = 25;';
        EXEC sp_executesql @Sql, N'@pDiff NVARCHAR(600)', @pDiff = @DiffBackupFile;
    END

    SET @Sql = N'ALTER DATABASE ' + QUOTENAME(@TargetDbName) + N' SET MULTI_USER;';
    EXEC sp_executesql @Sql;

    SELECT @TargetDbName AS RestoredDatabase,
           DATEDIFF(SECOND, @StartUtc, SYSUTCDATETIME()) AS ElapsedSeconds,
           N'RTO_RESTORED' AS Status;
END
GO
