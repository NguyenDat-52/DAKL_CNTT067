-- ============================================================================
-- FILE 04: CREATE ACCOUNTS SCHEMA & INDEXES FOR QL_CUA_HANG_VLXD
-- ============================================================================
USE QL_CUA_HANG_VLXD;
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_TaiKhoan_TenDangNhap' AND object_id = OBJECT_ID('TaiKhoan'))
BEGIN
    CREATE UNIQUE INDEX IX_TaiKhoan_TenDangNhap ON TaiKhoan(TenDangNhap);
END

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_TaiKhoan_VaiTro' AND object_id = OBJECT_ID('TaiKhoan'))
BEGIN
    CREATE INDEX IX_TaiKhoan_VaiTro ON TaiKhoan(VaiTro);
END
GO
