-- ===============================================================================
-- MIGRATION 09: QUAN LY DANH MUC COT LOI (QUY CACH KY THUAT & DON VI TINH)
-- ===============================================================================
USE QL_CUA_HANG_VLXD;
GO

-- 1. Bang QuyCachKyThuat (Specifications linked optionally to DanhMuc)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'QuyCachKyThuat')
BEGIN
    CREATE TABLE QuyCachKyThuat (
        MaQuyCach INT IDENTITY(1,1) PRIMARY KEY,
        MaDanhMuc INT NULL,
        TenQuyCach NVARCHAR(150) NOT NULL,
        MoTa NVARCHAR(300) NULL,
        TrangThai BIT NOT NULL DEFAULT 1,
        NgayTao DATETIME NOT NULL DEFAULT GETDATE(),
        CONSTRAINT FK_QuyCachKyThuat_DanhMuc FOREIGN KEY (MaDanhMuc) REFERENCES DanhMuc(MaDanhMuc)
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_QuyCachKyThuat_DanhMuc' AND object_id = OBJECT_ID('QuyCachKyThuat'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_QuyCachKyThuat_DanhMuc ON QuyCachKyThuat(MaDanhMuc, TrangThai);
END
GO

-- 2. Bang DonViTinh (Standardized Units)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'DonViTinh')
BEGIN
    CREATE TABLE DonViTinh (
        MaDonVi INT IDENTITY(1,1) PRIMARY KEY,
        TenDonVi NVARCHAR(50) NOT NULL,
        MoTa NVARCHAR(200) NULL,
        LaMacDinh BIT NOT NULL DEFAULT 0,
        TrangThai BIT NOT NULL DEFAULT 1,
        NgayTao DATETIME NOT NULL DEFAULT GETDATE(),
        CONSTRAINT UQ_DonViTinh_TenDonVi UNIQUE (TenDonVi)
    );
END
GO

-- 3. Bo sung MaQuyCach va TenQuyCach cho bang SanPham
IF COL_LENGTH('SanPham', 'MaQuyCach') IS NULL
BEGIN
    ALTER TABLE SanPham ADD MaQuyCach INT NULL;
    ALTER TABLE SanPham ADD CONSTRAINT FK_SanPham_QuyCachKyThuat FOREIGN KEY (MaQuyCach) REFERENCES QuyCachKyThuat(MaQuyCach);
END
GO

IF COL_LENGTH('SanPham', 'TenQuyCach') IS NULL
BEGIN
    ALTER TABLE SanPham ADD TenQuyCach NVARCHAR(150) NULL;
END
GO

-- 4. Seed danh sach DonViTinh chuan (idempotent)
DECLARE @SeedUnits TABLE (TenDonVi NVARCHAR(50), MoTa NVARCHAR(200), LaMacDinh BIT);
INSERT INTO @SeedUnits (TenDonVi, MoTa, LaMacDinh) VALUES
(N'kg', N'Kilôgam (trọng lượng)', 1),
(N'tấn', N'Tấn (1.000 kg)', 1),
(N'bao', N'Bao đóng gói (xi măng, keo, bột trét)', 1),
(N'viên', N'Viên (gạch xây, gạch lát, ngói)', 1),
(N'm', N'Mét dài (dây, ống, thép)', 1),
(N'm²', N'Mét vuông (gạch ốp lát, tấm)', 1),
(N'm³', N'Mét khối / Khối (cát, đá, bê tông)', 1),
(N'lít', N'Lít (sơn, dung môi, phụ gia lỏng)', 1),
(N'thùng', N'Thùng (sơn 18L, gạch đóng thùng, keo)', 1),
(N'bộ', N'Bộ phụ kiện / thiết bị hoàn chỉnh', 1),
(N'cuộn', N'Cuộn (thép cuộn, dây điện, màng chống thấm)', 1),
(N'tấm', N'Tấm (tôn, thạch cao, cemboard)', 1),
(N'cây', N'Cây (thép cây 11.7m, ống nhựa 4m)', 1),
(N'hộp', N'Hộp (đinh, vít, phụ kiện, gạch hộp)', 1),
(N'chai', N'Chai / Lọ (keo dán ống, silicon)', 1),
(N'cái', N'Cái / Chiếc (van, co, tê, phụ kiện lẻ)', 1),
(N'thanh', N'Thanh (xà gồ, thép hình, nẹp)', 1),
(N'lon', N'Lon (sơn 1L, sơn 5L, keo)', 1),
(N'bịch', N'Bịch / Túi đóng lẻ', 1),
(N'xe', N'Chuyến xe ben (cát, đá nguyên xe)', 1);

INSERT INTO DonViTinh (TenDonVi, MoTa, LaMacDinh, TrangThai)
SELECT u.TenDonVi, u.MoTa, u.LaMacDinh, 1
FROM @SeedUnits u
WHERE NOT EXISTS (
    SELECT 1 FROM DonViTinh d WHERE LOWER(LTRIM(RTRIM(d.TenDonVi))) = LOWER(LTRIM(RTRIM(u.TenDonVi)))
);

-- Dong bo don vi tinh dang su dung o SanPham va QuyDoiDonVi (neu co don vi tuy chinh)
INSERT INTO DonViTinh (TenDonVi, MoTa, LaMacDinh, TrangThai)
SELECT DISTINCT LTRIM(RTRIM(s.DonViTinh)), N'Đồng bộ từ sản phẩm hiện có', 0, 1
FROM SanPham s
WHERE s.DonViTinh IS NOT NULL AND LTRIM(RTRIM(s.DonViTinh)) <> ''
  AND NOT EXISTS (
      SELECT 1 FROM DonViTinh d WHERE LOWER(LTRIM(RTRIM(d.TenDonVi))) = LOWER(LTRIM(RTRIM(s.DonViTinh)))
  );

INSERT INTO DonViTinh (TenDonVi, MoTa, LaMacDinh, TrangThai)
SELECT DISTINCT LTRIM(RTRIM(q.TenDonViQuyDoi)), N'Đồng bộ từ quy đổi bán lẻ', 0, 1
FROM QuyDoiDonVi q
WHERE q.TenDonViQuyDoi IS NOT NULL AND LTRIM(RTRIM(q.TenDonViQuyDoi)) <> ''
  AND NOT EXISTS (
      SELECT 1 FROM DonViTinh d WHERE LOWER(LTRIM(RTRIM(d.TenDonVi))) = LOWER(LTRIM(RTRIM(q.TenDonViQuyDoi)))
  );
GO

-- 5. Seed QuyCachKyThuat mau theo danh muc (idempotent)
DECLARE @SeedSpecs TABLE (MaDanhMuc INT NULL, TenQuyCach NVARCHAR(150), MoTa NVARCHAR(300));
INSERT INTO @SeedSpecs (MaDanhMuc, TenQuyCach, MoTa) VALUES
-- 1: Xi mang
(1, N'PCB30 - Bao 50 kg', N'Xi măng pooclăng hỗn hợp mác PCB30, bao 50 kg'),
(1, N'PCB40 - Bao 50 kg', N'Xi măng pooclăng hỗn hợp cường độ cao PCB40, bao 50 kg'),
(1, N'Xi măng xây tô - Bao 50 kg', N'Xi măng chuyên dụng xây tô tường'),
(1, N'Xi măng trắng - Bao 40 kg', N'Xi măng trắng trang trí / chà ron'),
-- 2: Cat xay dung
(2, N'Cát vàng hạt lớn (Đổ bê tông)', N'Cát sạch mô-đun lớn 2.0 - 3.3 mm'),
(2, N'Cát xây tô hạt mịn', N'Cát hạt vừa/mịn chuyên xây gạch và tô trát'),
(2, N'Cát san lấp', N'Cát nền san lấp mặt bằng công trình'),
(2, N'Đóng bao 50 kg', N'Cát đóng bao tiện giao lẻ / sửa chữa nhỏ'),
-- 3: Da xay dung
(3, N'Đá 1x2 (10x20 mm)', N'Đá dăm tiêu chuẩn đổ bê tông cột, dầm, sàn'),
(3, N'Đá 4x6 (40x60 mm)', N'Đá hộc dăm gia cố nền móng công trình'),
(3, N'Đá mi bụi / mi sàng', N'Đá mạt làm gạch block hoặc rải nền'),
(3, N'Đá 0x4 (Cấp phối)', N'Đá cấp phối làm đường và nền nhà xưởng'),
-- 4: Gach xay dung
(4, N'Gạch Tuynel 4 lỗ (8x8x18 cm)', N'Gạch đất sét nung truyền thống 4 lỗ'),
(4, N'Gạch thẻ đặc (4x8x18 cm)', N'Gạch đặc chịu lực xây móng, trụ, hố ga'),
(4, N'Gạch Block không nung (9x19x39 cm)', N'Gạch xi măng cốt liệu cách âm tốt'),
(4, N'Gạch men lát nền 60x60 cm', N'Gạch lát nền kích thước 600x600 mm'),
(4, N'Gạch ốp tường 30x60 cm', N'Gạch men ốp tường kích thước 300x600 mm'),
(4, N'Gạch lát sân 40x40 cm', N'Gạch chống trơn kích thước 400x400 mm'),
-- 5: Sat thep xay dung
(5, N'Phi 6 (D6) - Cuộn', N'Thép tròn trơn đường kính 6 mm dạng cuộn'),
(5, N'Phi 8 (D8) - Cuộn', N'Thép tròn trơn đường kính 8 mm dạng cuộn'),
(5, N'Phi 10 (D10) - Cây 11.7 m', N'Thép thanh vằn đường kính 10 mm dài 11.7 m'),
(5, N'Phi 12 (D12) - Cây 11.7 m', N'Thép thanh vằn đường kính 12 mm dài 11.7 m'),
(5, N'Phi 16 (D16) - Cây 11.7 m', N'Thép thanh vằn đường kính 16 mm dài 11.7 m'),
(5, N'Thép hộp 40x80 mm - Cây 6 m', N'Thép hộp mạ kẽm làm xà gồ / khung mái'),
-- 6: Son & Chong tham
(6, N'Thùng 18 L', N'Thùng sơn dung tích lớn 18 lít (hoặc 15-18L)'),
(6, N'Lon 5 L', N'Lon sơn dung tích 5 lít'),
(6, N'Lon 1 L', N'Lon sơn dung tích 1 lít dặm vá / trang trí'),
(6, N'Bao / Thùng 20 kg', N'Chống thấm hoặc bột trét quy cách 20 kg'),
-- 7: Ong nuoc & Phu kien
(7, N'Phi 21 - Cây 4 m', N'Ống uPVC đường kính ngoài 21 mm, dài 4 m'),
(7, N'Phi 27 - Cây 4 m', N'Ống uPVC đường kính ngoài 27 mm, dài 4 m'),
(7, N'Phi 34 - Cây 4 m', N'Ống uPVC đường kính ngoài 34 mm, dài 4 m'),
(7, N'Phi 60 - Cây 4 m', N'Ống uPVC thoát nước đường kính 60 mm, dài 4 m'),
(7, N'Phi 90 - Cây 4 m', N'Ống uPVC thoát nước đường kính 90 mm, dài 4 m'),
(7, N'Phi 114 - Cây 4 m', N'Ống uPVC trục chính đường kính 114 mm, dài 4 m'),
(7, N'Phụ kiện Co / Tê / Nối PVC', N'Phụ kiện nối ống đa quy cách tiêu chuẩn');

INSERT INTO QuyCachKyThuat (MaDanhMuc, TenQuyCach, MoTa, TrangThai)
SELECT s.MaDanhMuc, s.TenQuyCach, s.MoTa, 1
FROM @SeedSpecs s
WHERE (s.MaDanhMuc IS NULL OR EXISTS (SELECT 1 FROM DanhMuc dm WHERE dm.MaDanhMuc = s.MaDanhMuc))
  AND NOT EXISTS (
      SELECT 1 FROM QuyCachKyThuat q
      WHERE ISNULL(q.MaDanhMuc, 0) = ISNULL(s.MaDanhMuc, 0)
        AND LOWER(LTRIM(RTRIM(q.TenQuyCach))) = LOWER(LTRIM(RTRIM(s.TenQuyCach)))
  );
GO
