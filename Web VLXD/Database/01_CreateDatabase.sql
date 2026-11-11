-- ============================================================================
-- FILE 01: CREATE DATABASE QL_CUA_HANG_VLXD
-- ============================================================================
USE master;
GO

IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'QL_CUA_HANG_VLXD')
BEGIN
    CREATE DATABASE QL_CUA_HANG_VLXD;
    PRINT N'Đã tạo Database QL_CUA_HANG_VLXD thành công.';
END
ELSE
BEGIN
    PRINT N'Database QL_CUA_HANG_VLXD đã tồn tại.';
END
GO
