-- ===============================================================================
-- MIGRATION SCRIPT: BCRYPT PASSWORDS, EXCEPTION WORKFLOWS, SUPPLIER DEBT & NFR INDEXES
-- Target Database: QL_CUA_HANG_VLXD
-- Idempotent (Safe to run multiple times)
-- ===============================================================================
USE QL_CUA_HANG_VLXD;
GO

-- 1. CHUẨN HÓA MẬT KHẨU SANG BCRYPT (WORK FACTOR 11) CHO TÀI KHOẢN MẪU/CŨ DÙNG SHA-256
-- Mật khẩu mặc định '123456' -> Bcrypt: $2a$11$dV/bXzHYKWkYUGqR6ZaoWeqhiI6qqVC6HUJxJEKHX94GxG2ZITv4m
DECLARE @BcryptDefault123456 NVARCHAR(255) = N'$2a$11$dV/bXzHYKWkYUGqR6ZaoWeqhiI6qqVC6HUJxJEKHX94GxG2ZITv4m';
DECLARE @LegacySha256_123456 NVARCHAR(255) = N'8D969EEF6ECAD3C29A3A629280E686CF0C3F5D5A86AFF3CA12020C923ADC6C92';

UPDATE KhachHang
SET MatKhau = @BcryptDefault123456
WHERE MatKhau = @LegacySha256_123456 OR MatKhau = N'123456';

UPDATE NhanVien
SET MatKhau = @BcryptDefault123456
WHERE MatKhau = @LegacySha256_123456 OR MatKhau = N'123456';

UPDATE TaiKhoan
SET MatKhau = @BcryptDefault123456
WHERE MatKhau = @LegacySha256_123456 OR MatKhau = N'123456';
GO

-- 2. BỔ SUNG CỘT XỬ LÝ NGOẠI LỆ TRÊN BẢNG DonHang
IF COL_LENGTH('DonHang', 'LyDoHuy') IS NULL
    ALTER TABLE DonHang ADD LyDoHuy NVARCHAR(500) NULL;
IF COL_LENGTH('DonHang', 'NgayHuy') IS NULL
    ALTER TABLE DonHang ADD NgayHuy DATETIME NULL;
IF COL_LENGTH('DonHang', 'NguoiHuy') IS NULL
    ALTER TABLE DonHang ADD NguoiHuy NVARCHAR(100) NULL;
IF COL_LENGTH('DonHang', 'SoTienHoan') IS NULL
    ALTER TABLE DonHang ADD SoTienHoan DECIMAL(18, 2) NOT NULL CONSTRAINT DF_DonHang_SoTienHoan DEFAULT 0;
IF COL_LENGTH('DonHang', 'LyDoDieuChinh') IS NULL
    ALTER TABLE DonHang ADD LyDoDieuChinh NVARCHAR(500) NULL;
GO

-- 3. BỔ SUNG CỘT XỬ LÝ TỪ CHỐI ĐƠN / SỰ CỐ GIAO HÀNG TRÊN BẢNG GiaoHang
IF COL_LENGTH('GiaoHang', 'PhanLoaiSuCo') IS NULL
    ALTER TABLE GiaoHang ADD PhanLoaiSuCo NVARCHAR(100) NULL;
IF COL_LENGTH('GiaoHang', 'LyDoThatBai') IS NULL
    ALTER TABLE GiaoHang ADD LyDoThatBai NVARCHAR(500) NULL;
IF COL_LENGTH('GiaoHang', 'SoLanGiaoThatBai') IS NULL
    ALTER TABLE GiaoHang ADD SoLanGiaoThatBai INT NOT NULL CONSTRAINT DF_GiaoHang_SoLanGiaoThatBai DEFAULT 0;
IF COL_LENGTH('GiaoHang', 'ThoiGianSuCo') IS NULL
    ALTER TABLE GiaoHang ADD ThoiGianSuCo DATETIME NULL;
IF COL_LENGTH('GiaoHang', 'MaNhanVienTuChoi') IS NULL
    ALTER TABLE GiaoHang ADD MaNhanVienTuChoi INT NULL;
IF COL_LENGTH('GiaoHang', 'TrangThaiXuLySuCo') IS NULL
    ALTER TABLE GiaoHang ADD TrangThaiXuLySuCo NVARCHAR(100) NULL;
GO

-- 4. BỔ SUNG CỘT NGHIỆM THU TRÊN PhieuNhap & ChiTietPhieuNhap
IF COL_LENGTH('PhieuNhap', 'TrangThaiNghiemThu') IS NULL
    ALTER TABLE PhieuNhap ADD TrangThaiNghiemThu NVARCHAR(50) NOT NULL CONSTRAINT DF_PhieuNhap_TrangThaiNghiemThu DEFAULT N'Chờ nghiệm thu';
IF COL_LENGTH('PhieuNhap', 'NgayNghiemThu') IS NULL
    ALTER TABLE PhieuNhap ADD NgayNghiemThu DATETIME NULL;
IF COL_LENGTH('PhieuNhap', 'NguoiNghiemThu') IS NULL
    ALTER TABLE PhieuNhap ADD NguoiNghiemThu NVARCHAR(100) NULL;
IF COL_LENGTH('PhieuNhap', 'TongTienThucTe') IS NULL
    ALTER TABLE PhieuNhap ADD TongTienThucTe DECIMAL(18, 2) NOT NULL CONSTRAINT DF_PhieuNhap_TongTienThucTe DEFAULT 0;
GO

-- Đồng bộ các phiếu nhập cũ đã xác nhận trước khi nâng cấp
UPDATE PhieuNhap
SET TrangThaiNghiemThu = N'Đã nghiệm thu',
    NgayNghiemThu = COALESCE(NgayNghiemThu, NgayNhap),
    TongTienThucTe = CASE WHEN TongTienThucTe = 0 THEN TongTien ELSE TongTienThucTe END
WHERE TrangThai IN (N'Đã xác nhận', N'Đã hoàn thành')
  AND TrangThaiNghiemThu = N'Chờ nghiệm thu';
GO

IF COL_LENGTH('ChiTietPhieuNhap', 'SoLuongThucNhan') IS NULL
    ALTER TABLE ChiTietPhieuNhap ADD SoLuongThucNhan INT NULL;
IF COL_LENGTH('ChiTietPhieuNhap', 'SoLuongLoi') IS NULL
    ALTER TABLE ChiTietPhieuNhap ADD SoLuongLoi INT NOT NULL CONSTRAINT DF_CTPN_SoLuongLoi DEFAULT 0;
IF COL_LENGTH('ChiTietPhieuNhap', 'GhiChuKiemTra') IS NULL
    ALTER TABLE ChiTietPhieuNhap ADD GhiChuKiemTra NVARCHAR(500) NULL;
GO

-- 5. TẠO BẢNG BienBanSuCoNhap
IF OBJECT_ID('BienBanSuCoNhap', 'U') IS NULL
BEGIN
    CREATE TABLE BienBanSuCoNhap (
        MaSuCo INT IDENTITY(1,1) PRIMARY KEY,
        MaPhieuNhap INT NOT NULL,
        MaSanPham INT NULL,
        MaNhanVienLap INT NULL,
        NgayLap DATETIME NOT NULL DEFAULT GETDATE(),
        LoaiSuCo NVARCHAR(100) NOT NULL,
        SoLuongThieu INT NOT NULL DEFAULT 0,
        SoLuongLoi INT NOT NULL DEFAULT 0,
        GiaTriGiamTru DECIMAL(18, 2) NOT NULL DEFAULT 0,
        MoTaChiTiet NVARCHAR(500) NOT NULL,
        HuongXuLy NVARCHAR(200) NOT NULL DEFAULT N'Trả lại NCC & Giảm trừ công nợ',
        TrangThai NVARCHAR(50) NOT NULL DEFAULT N'Chờ xử lý',
        CONSTRAINT FK_BienBanSuCoNhap_PhieuNhap FOREIGN KEY (MaPhieuNhap) REFERENCES PhieuNhap(MaPhieuNhap) ON DELETE CASCADE,
        CONSTRAINT FK_BienBanSuCoNhap_SanPham FOREIGN KEY (MaSanPham) REFERENCES SanPham(MaSanPham),
        CONSTRAINT FK_BienBanSuCoNhap_NhanVien FOREIGN KEY (MaNhanVienLap) REFERENCES NhanVien(MaNhanVien)
    );
END
GO

-- 6. TẠO BẢNG CongNoNCC
IF OBJECT_ID('CongNoNCC', 'U') IS NULL
BEGIN
    CREATE TABLE CongNoNCC (
        MaCongNo INT IDENTITY(1,1) PRIMARY KEY,
        MaNhaCungCap INT NOT NULL,
        MaPhieuNhap INT NOT NULL,
        NgayGhiNhan DATETIME NOT NULL DEFAULT GETDATE(),
        HanThanhToan DATETIME NULL,
        TongTienPhieu DECIMAL(18, 2) NOT NULL DEFAULT 0,
        GiaTriGiamTru DECIMAL(18, 2) NOT NULL DEFAULT 0,
        SoTienPhaiTra DECIMAL(18, 2) NOT NULL DEFAULT 0,
        SoTienDaTra DECIMAL(18, 2) NOT NULL DEFAULT 0,
        TrangThai NVARCHAR(50) NOT NULL DEFAULT N'Chưa thanh toán',
        GhiChu NVARCHAR(500) NULL,
        CONSTRAINT FK_CongNoNCC_NhaCungCap FOREIGN KEY (MaNhaCungCap) REFERENCES NhaCungCap(MaNhaCungCap),
        CONSTRAINT FK_CongNoNCC_PhieuNhap FOREIGN KEY (MaPhieuNhap) REFERENCES PhieuNhap(MaPhieuNhap)
    );
END
GO

-- Bổ sung công nợ cho các phiếu nhập đã nghiệm thu trước đây nếu chưa có bản ghi CongNoNCC
INSERT INTO CongNoNCC (MaNhaCungCap, MaPhieuNhap, NgayGhiNhan, HanThanhToan, TongTienPhieu, GiaTriGiamTru, SoTienPhaiTra, SoTienDaTra, TrangThai, GhiChu)
SELECT pn.MaNhaCungCap, pn.MaPhieuNhap, pn.NgayNhap, DATEADD(DAY, 30, pn.NgayNhap),
       pn.TongTien, CASE WHEN pn.TongTien > pn.TongTienThucTe THEN pn.TongTien - pn.TongTienThucTe ELSE 0 END,
       CASE WHEN pn.TongTienThucTe > 0 THEN pn.TongTienThucTe ELSE pn.TongTien END,
       0, N'Chưa thanh toán', N'Tự động đồng bộ từ phiếu nhập #' + CAST(pn.MaPhieuNhap AS NVARCHAR(20))
FROM PhieuNhap pn
WHERE pn.TrangThai IN (N'Đã xác nhận', N'Đã hoàn thành', N'Đã nhập (Có sự cố)')
  AND NOT EXISTS (SELECT 1 FROM CongNoNCC cn WHERE cn.MaPhieuNhap = pn.MaPhieuNhap);
GO

-- 7. BỔ SUNG CÁC CHỈ MỤC TỐI ƯU HIỆU NĂNG (< 1.5s)
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_SanPham_TrangThai_DanhMuc' AND object_id = OBJECT_ID('SanPham'))
    CREATE NONCLUSTERED INDEX IX_SanPham_TrangThai_DanhMuc ON SanPham(TrangThai, MaDanhMuc) INCLUDE (TenSanPham, DonViTinh, SoLuongTon, HinhAnh);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_DonHang_MaKhachHang_NgayDat' AND object_id = OBJECT_ID('DonHang'))
    CREATE NONCLUSTERED INDEX IX_DonHang_MaKhachHang_NgayDat ON DonHang(MaKhachHang, NgayDat DESC) INCLUDE (TrangThai, TongTien, DaTruKho);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_GiaoHang_TrangThai_NhanVien' AND object_id = OBJECT_ID('GiaoHang'))
    CREATE NONCLUSTERED INDEX IX_GiaoHang_TrangThai_NhanVien ON GiaoHang(TrangThai, MaNhanVienGiao);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_PhieuNhap_TrangThai_Ngay' AND object_id = OBJECT_ID('PhieuNhap'))
    CREATE NONCLUSTERED INDEX IX_PhieuNhap_TrangThai_Ngay ON PhieuNhap(TrangThai, NgayNhap DESC);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_CongNoNCC_NCC_TrangThai' AND object_id = OBJECT_ID('CongNoNCC'))
    CREATE NONCLUSTERED INDEX IX_CongNoNCC_NCC_TrangThai ON CongNoNCC(MaNhaCungCap, TrangThai);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_BienBanSuCoNhap_PhieuNhap' AND object_id = OBJECT_ID('BienBanSuCoNhap'))
    CREATE NONCLUSTERED INDEX IX_BienBanSuCoNhap_PhieuNhap ON BienBanSuCoNhap(MaPhieuNhap);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_DanhGia_SanPham_TrangThai' AND object_id = OBJECT_ID('DanhGia'))
    CREATE NONCLUSTERED INDEX IX_DanhGia_SanPham_TrangThai ON DanhGia(MaSanPham, TrangThai);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_KhuyenMai_HieuLuc' AND object_id = OBJECT_ID('KhuyenMai'))
    CREATE NONCLUSTERED INDEX IX_KhuyenMai_HieuLuc ON KhuyenMai(TrangThai, TuNgay, DenNgay);
GO
