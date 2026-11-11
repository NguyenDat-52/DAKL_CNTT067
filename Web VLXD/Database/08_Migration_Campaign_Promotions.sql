-- ===============================================================================
-- MIGRATION 08: MO HINH KHUYEN MAI CHA - CON (CHIEN DICH KHUYEN MAI & QUY TAC CON)
-- ===============================================================================
USE QL_CUA_HANG_VLXD;
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ChienDichKhuyenMai')
BEGIN
    CREATE TABLE ChienDichKhuyenMai (
        MaChienDich INT IDENTITY(1,1) PRIMARY KEY,
        TenChienDich NVARCHAR(200) NOT NULL,
        MoTa NVARCHAR(500) NULL,
        NgayBatDau DATETIME NOT NULL,
        NgayKetThuc DATETIME NOT NULL,
        TrangThai BIT NOT NULL DEFAULT 1,
        NgayTao DATETIME NOT NULL DEFAULT GETDATE()
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_ChienDichKhuyenMai_HieuLuc' AND object_id = OBJECT_ID('ChienDichKhuyenMai'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_ChienDichKhuyenMai_HieuLuc ON ChienDichKhuyenMai(TrangThai, NgayBatDau, NgayKetThuc);
END
GO

IF COL_LENGTH('KhuyenMai', 'MaChienDich') IS NULL
BEGIN
    ALTER TABLE KhuyenMai ADD MaChienDich INT NULL;
    ALTER TABLE KhuyenMai ADD CONSTRAINT FK_KhuyenMai_ChienDich FOREIGN KEY (MaChienDich) REFERENCES ChienDichKhuyenMai(MaChienDich);
END
GO

IF COL_LENGTH('KhuyenMai', 'MaDanhMucApDung') IS NULL
BEGIN
    ALTER TABLE KhuyenMai ADD MaDanhMucApDung INT NULL;
    ALTER TABLE KhuyenMai ADD CONSTRAINT FK_KhuyenMai_DanhMucApDung FOREIGN KEY (MaDanhMucApDung) REFERENCES DanhMuc(MaDanhMuc);
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_KhuyenMai_ChienDich' AND object_id = OBJECT_ID('KhuyenMai'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_KhuyenMai_ChienDich ON KhuyenMai(MaChienDich, TrangThai, TuNgay, DenNgay);
END
GO

-- Backfill: Gan cac khuyen mai hien huu vao chien dich cha mac dinh neu chua co Campaign
IF EXISTS (SELECT 1 FROM KhuyenMai WHERE MaChienDich IS NULL)
BEGIN
    DECLARE @DefaultCampaignId INT;
    SELECT TOP 1 @DefaultCampaignId = MaChienDich FROM ChienDichKhuyenMai ORDER BY MaChienDich ASC;

    IF @DefaultCampaignId IS NULL
    BEGIN
        DECLARE @MinStart DATETIME = (SELECT ISNULL(MIN(TuNgay), '2026-01-01') FROM KhuyenMai);
        DECLARE @MaxEnd DATETIME = (SELECT ISNULL(MAX(DenNgay), '2026-12-31 23:59:59') FROM KhuyenMai);
        IF @MaxEnd < GETDATE() SET @MaxEnd = '2026-12-31 23:59:59';

        INSERT INTO ChienDichKhuyenMai (TenChienDich, MoTa, NgayBatDau, NgayKetThuc, TrangThai, NgayTao)
        VALUES (
            N'Chiến dịch Khuyến mãi Vật liệu Xây dựng 2026',
            N'Chiến dịch tổng hợp các ưu đãi xi măng, sắt thép, sơn và đơn hàng công trình năm 2026.',
            @MinStart,
            @MaxEnd,
            1,
            GETDATE()
        );
        SET @DefaultCampaignId = SCOPE_IDENTITY();
    END

    UPDATE KhuyenMai
    SET MaChienDich = @DefaultCampaignId
    WHERE MaChienDich IS NULL;
END
GO

-- Tu dong tat cac chien dich / khuyen mai da qua thoi han hieu luc
UPDATE ChienDichKhuyenMai
SET TrangThai = 0
WHERE TrangThai = 1 AND NgayKetThuc < GETDATE();

UPDATE k
SET k.TrangThai = 0
FROM KhuyenMai k
LEFT JOIN ChienDichKhuyenMai cd ON k.MaChienDich = cd.MaChienDich
WHERE k.TrangThai = 1
  AND (k.DenNgay < GETDATE() OR (cd.MaChienDich IS NOT NULL AND cd.NgayKetThuc < GETDATE()));
GO
