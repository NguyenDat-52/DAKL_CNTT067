-- ============================================================================
-- FILE 02: CREATE TABLES FOR QL_CUA_HANG_VLXD
-- ============================================================================
USE QL_CUA_HANG_VLXD;
GO

-- 1. DanhMuc
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'DanhMuc')
BEGIN
    CREATE TABLE DanhMuc (
        MaDanhMuc INT IDENTITY(1,1) PRIMARY KEY,
        TenDanhMuc NVARCHAR(100) NOT NULL,
        MoTa NVARCHAR(255) NULL,
        TrangThai BIT NOT NULL DEFAULT 1
    );
END
GO

-- 2. SanPham
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'SanPham')
BEGIN
    CREATE TABLE SanPham (
        MaSanPham INT IDENTITY(1,1) PRIMARY KEY,
        TenSanPham NVARCHAR(150) NOT NULL,
        DonViTinh NVARCHAR(50) NOT NULL,
        SoLuongTon INT NOT NULL DEFAULT 0,
        MoTa NVARCHAR(MAX) NULL,
        HinhAnh NVARCHAR(255) NULL,
        TrangThai BIT NOT NULL DEFAULT 1,
        MaDanhMuc INT NOT NULL
    );
END
GO

-- 3. GiaBan
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'GiaBan')
BEGIN
    CREATE TABLE GiaBan (
        MaGia INT IDENTITY(1,1) PRIMARY KEY,
        MaSanPham INT NOT NULL,
        GiaBan DECIMAL(18, 2) NOT NULL,
        TuNgay DATETIME NOT NULL DEFAULT GETDATE(),
        DenNgay DATETIME NULL,
        TrangThai BIT NOT NULL DEFAULT 1
    );
END
GO

-- 4. KhuyenMai
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'KhuyenMai')
BEGIN
    CREATE TABLE KhuyenMai (
        MaKhuyenMai INT IDENTITY(1,1) PRIMARY KEY,
        TenKhuyenMai NVARCHAR(150) NOT NULL,
        PhanTramGiam DECIMAL(5,2) DEFAULT 0,
        SoTienGiam DECIMAL(18,2) DEFAULT 0,
        TuNgay DATETIME NOT NULL,
        DenNgay DATETIME NOT NULL,
        TrangThai BIT NOT NULL DEFAULT 1
    );
END
GO

-- 5. SanPham_KhuyenMai
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'SanPham_KhuyenMai')
BEGIN
    CREATE TABLE SanPham_KhuyenMai (
        MaSanPham INT NOT NULL,
        MaKhuyenMai INT NOT NULL,
        PRIMARY KEY (MaSanPham, MaKhuyenMai)
    );
END
GO

-- 6. KhachHang
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'KhachHang')
BEGIN
    CREATE TABLE KhachHang (
        MaKhachHang INT IDENTITY(1,1) PRIMARY KEY,
        HoTen NVARCHAR(100) NOT NULL,
        SoDienThoai VARCHAR(20) NOT NULL UNIQUE,
        Email NVARCHAR(100) NULL,
        DiaChi NVARCHAR(255) NULL,
        MatKhau NVARCHAR(255) NULL,
        NgayTao DATETIME NOT NULL DEFAULT GETDATE(),
        TrangThai BIT NOT NULL DEFAULT 1
    );
END
GO

-- 7. NhanVien
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'NhanVien')
BEGIN
    CREATE TABLE NhanVien (
        MaNhanVien INT IDENTITY(1,1) PRIMARY KEY,
        HoTen NVARCHAR(100) NOT NULL,
        ChucVu NVARCHAR(50) NOT NULL,
        SoDienThoai VARCHAR(20) NOT NULL UNIQUE,
        Email NVARCHAR(100) NULL,
        LuongCoban DECIMAL(18,2) DEFAULT 0,
        NgayVaoLam DATETIME NOT NULL DEFAULT GETDATE(),
        TrangThai BIT NOT NULL DEFAULT 1
    );
END
GO

-- 8. NhaCungCap
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'NhaCungCap')
BEGIN
    CREATE TABLE NhaCungCap (
        MaNhaCungCap INT IDENTITY(1,1) PRIMARY KEY,
        TenNhaCungCap NVARCHAR(150) NOT NULL,
        NguoiLienHe NVARCHAR(100) NULL,
        SoDienThoai VARCHAR(20) NOT NULL,
        Email NVARCHAR(100) NULL,
        DiaChi NVARCHAR(255) NULL,
        TrangThai BIT NOT NULL DEFAULT 1
    );
END
GO

-- 9. PhieuNhap
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'PhieuNhap')
BEGIN
    CREATE TABLE PhieuNhap (
        MaPhieuNhap INT IDENTITY(1,1) PRIMARY KEY,
        MaNhaCungCap INT NOT NULL,
        MaNhanVien INT NOT NULL,
        NgayNhap DATETIME NOT NULL DEFAULT GETDATE(),
        TongTien DECIMAL(18,2) NOT NULL DEFAULT 0,
        GhiChu NVARCHAR(255) NULL
    );
END
GO

-- 10. ChiTietPhieuNhap
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ChiTietPhieuNhap')
BEGIN
    CREATE TABLE ChiTietPhieuNhap (
        MaPhieuNhap INT NOT NULL,
        MaSanPham INT NOT NULL,
        SoLuong INT NOT NULL,
        GianNhap DECIMAL(18,2) NOT NULL,
        ThanhTien AS (SoLuong * GianNhap),
        PRIMARY KEY (MaPhieuNhap, MaSanPham)
    );
END
GO

-- 11. DonHang
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'DonHang')
BEGIN
    CREATE TABLE DonHang (
        MaDonHang INT IDENTITY(1,1) PRIMARY KEY,
        MaKhachHang INT NOT NULL,
        NgayDat DATETIME NOT NULL DEFAULT GETDATE(),
        NguoiNhan NVARCHAR(100) NOT NULL,
        SoDienThoaiNhan VARCHAR(20) NOT NULL,
        DiaChiGiao NVARCHAR(255) NOT NULL,
        TongTien DECIMAL(18,2) NOT NULL DEFAULT 0,
        TrangThai NVARCHAR(50) NOT NULL DEFAULT N'Chờ xác nhận',
        GhiChu NVARCHAR(255) NULL
    );
END
GO

-- 12. ChiTietDonHang
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ChiTietDonHang')
BEGIN
    CREATE TABLE ChiTietDonHang (
        MaDonHang INT NOT NULL,
        MaSanPham INT NOT NULL,
        SoLuong INT NOT NULL,
        DonGia DECIMAL(18,2) NOT NULL,
        ThanhTien AS (SoLuong * DonGia),
        PRIMARY KEY (MaDonHang, MaSanPham)
    );
END
GO

-- 13. ThanhToan
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ThanhToan')
BEGIN
    CREATE TABLE ThanhToan (
        MaThanhToan INT IDENTITY(1,1) PRIMARY KEY,
        MaDonHang INT NOT NULL,
        PhuongThuc NVARCHAR(50) NOT NULL,
        SoTien DECIMAL(18,2) NOT NULL,
        NgayThanhToan DATETIME NOT NULL DEFAULT GETDATE(),
        TrangThai NVARCHAR(50) NOT NULL DEFAULT N'Chưa thanh toán'
    );
END
GO

-- 14. GiaoHang
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'GiaoHang')
BEGIN
    CREATE TABLE GiaoHang (
        MaGiaoHang INT IDENTITY(1,1) PRIMARY KEY,
        MaDonHang INT NOT NULL,
        MaNhanVienGiao INT NULL,
        NgayGiaoDukien DATETIME NULL,
        NgayGiaoThucte DATETIME NULL,
        TrangThai NVARCHAR(50) NOT NULL DEFAULT N'Chờ giao hàng',
        GhiChu NVARCHAR(255) NULL
    );
END
GO

-- 15. DoiTra
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'DoiTra')
BEGIN
    CREATE TABLE DoiTra (
        MaDoiTra INT IDENTITY(1,1) PRIMARY KEY,
        MaDonHang INT NOT NULL,
        NgayYeuCau DATETIME NOT NULL DEFAULT GETDATE(),
        LyDo NVARCHAR(255) NOT NULL,
        TrangThai NVARCHAR(50) NOT NULL DEFAULT N'Chờ xử lý',
        TongTienHoan DECIMAL(18,2) DEFAULT 0
    );
END
GO

-- 16. ChiTietDoiTra
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ChiTietDoiTra')
BEGIN
    CREATE TABLE ChiTietDoiTra (
        MaDoiTra INT NOT NULL,
        MaSanPham INT NOT NULL,
        SoLuong INT NOT NULL,
        DonGia DECIMAL(18,2) NOT NULL,
        ThanhTien AS (SoLuong * DonGia),
        PRIMARY KEY (MaDoiTra, MaSanPham)
    );
END
GO

-- 17. DanhGia
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'DanhGia')
BEGIN
    CREATE TABLE DanhGia (
        MaDanhGia INT IDENTITY(1,1) PRIMARY KEY,
        MaSanPham INT NOT NULL,
        MaKhachHang INT NOT NULL,
        SoSao INT NOT NULL CHECK (SoSao BETWEEN 1 AND 5),
        NoiDung NVARCHAR(MAX) NULL,
        NgayDanhGia DATETIME NOT NULL DEFAULT GETDATE()
    );
END
GO

-- 18. TaiKhoan (AUTH & ROLE MANAGEMENT)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'TaiKhoan')
BEGIN
    CREATE TABLE TaiKhoan (
        MaTaiKhoan INT IDENTITY(1,1) PRIMARY KEY,
        TenDangNhap NVARCHAR(50) NOT NULL UNIQUE,
        MatKhau NVARCHAR(255) NOT NULL,
        Email NVARCHAR(100) NULL,
        VaiTro NVARCHAR(20) NOT NULL CHECK (VaiTro IN (N'ADMIN', N'EMPLOYEE', N'CUSTOMER')),
        TrangThai BIT NOT NULL DEFAULT 1,
        MaKhachHang INT NULL,
        MaNhanVien INT NULL,
        NgayTao DATETIME NOT NULL DEFAULT GETDATE()
    );
END
GO
