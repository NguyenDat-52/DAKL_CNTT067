-- ===============================================================================
-- HE THONG QUAN LY CUA HANG VAT LIEU XAY DUNG (VLXD-PRO)
-- FILE SCRIPT CO SO DU LIEU CHUAN: QL_CUA_HANG_VLXD
-- PHIEN BAN DONG BO TOAN DIEN (MULTI-MACHINE & VISUAL STUDIO READY)
-- BAO GOM TRON BO 27 BANG, KHOA NGOAI, INDEX, RANG BUOC, BCRYPT HASH VA DU LIEU MAU DAY DU
-- ===============================================================================

USE master;
GO

IF EXISTS (SELECT name FROM sys.databases WHERE name = N'QL_CUA_HANG_VLXD')
BEGIN
    ALTER DATABASE QL_CUA_HANG_VLXD SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE QL_CUA_HANG_VLXD;
END
GO

CREATE DATABASE QL_CUA_HANG_VLXD;
GO

USE QL_CUA_HANG_VLXD;
GO

-- ===============================================================================
-- 1. BANG DANH MUC SAN PHAM
-- ===============================================================================
CREATE TABLE DanhMuc (
    MaDanhMuc INT IDENTITY(1,1) PRIMARY KEY,
    TenDanhMuc NVARCHAR(100) NOT NULL,
    MoTa NVARCHAR(500) NULL,
    HinhAnh NVARCHAR(500) NULL,
    TrangThai BIT NOT NULL DEFAULT 1
);
GO

-- ===============================================================================
-- 2. BANG SAN PHAM
-- ===============================================================================
CREATE TABLE SanPham (
    MaSanPham INT IDENTITY(1,1) PRIMARY KEY,
    MaDanhMuc INT NOT NULL,
    TenSanPham NVARCHAR(200) NOT NULL,
    DonViTinh NVARCHAR(50) NOT NULL,
    MoTa NVARCHAR(MAX) NULL,
    HinhAnh NVARCHAR(500) NULL,
    SoLuongTon INT NOT NULL DEFAULT 0,
    TrangThai BIT NOT NULL DEFAULT 1,
    NgayTao DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_SanPham_DanhMuc FOREIGN KEY (MaDanhMuc) REFERENCES DanhMuc(MaDanhMuc)
);
GO

-- ===============================================================================
-- 3. BANG BIEN THE SAN PHAM (QUY CACH / KICH THUOC / MAU SAC)
-- ===============================================================================
CREATE TABLE BienTheSanPham (
    MaBienThe INT IDENTITY(1,1) PRIMARY KEY,
    MaSanPham INT NOT NULL,
    TenBienThe NVARCHAR(100) NOT NULL,
    MaSKU NVARCHAR(50) NULL,
    GiaNhap DECIMAL(18,2) NOT NULL DEFAULT 0,
    GiaBan DECIMAL(18,2) NOT NULL DEFAULT 0,
    SoLuongTon INT NOT NULL DEFAULT 0,
    HinhAnh NVARCHAR(500) NULL,
    TrangThai BIT NOT NULL DEFAULT 1,
    NgayTao DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_BienTheSanPham_SanPham FOREIGN KEY (MaSanPham) REFERENCES SanPham(MaSanPham)
);
GO

-- ===============================================================================
-- 4. BANG GIA BAN SAN PHAM (LICH SU GIA)
-- ===============================================================================
CREATE TABLE GiaBan (
    MaGia INT IDENTITY(1,1) PRIMARY KEY,
    MaSanPham INT NOT NULL,
    Gia DECIMAL(18,2) NOT NULL,
    TuNgay DATETIME NOT NULL DEFAULT GETDATE(),
    DenNgay DATETIME NULL,
    TrangThai BIT NOT NULL DEFAULT 1,
    LyDo NVARCHAR(255) NULL,
    CONSTRAINT FK_GiaBan_SanPham FOREIGN KEY (MaSanPham) REFERENCES SanPham(MaSanPham)
);
GO

-- ===============================================================================
-- 5. BANG KHUYEN MAI (HO TRO MUA THEO SO LUONG / DINH MUC)
-- ===============================================================================
CREATE TABLE KhuyenMai (
    MaKhuyenMai INT IDENTITY(1,1) PRIMARY KEY,
    TenKhuyenMai NVARCHAR(200) NOT NULL,
    LoaiKhuyenMai NVARCHAR(100) NOT NULL DEFAULT N'Giảm giá thông thường',
    SoLuongToiThieu INT NOT NULL DEFAULT 1,
    PhanTramGiam INT NOT NULL DEFAULT 0,
    SoTienGiam DECIMAL(18,2) NOT NULL DEFAULT 0,
    TuNgay DATETIME NOT NULL,
    DenNgay DATETIME NOT NULL,
    TrangThai BIT NOT NULL DEFAULT 1
);
GO

-- ===============================================================================
-- 6. BANG LIEN KET SAN PHAM - KHUYEN MAI
-- ===============================================================================
CREATE TABLE SanPham_KhuyenMai (
    MaSanPham INT NOT NULL,
    MaKhuyenMai INT NOT NULL,
    PRIMARY KEY (MaSanPham, MaKhuyenMai),
    CONSTRAINT FK_SPKM_SanPham FOREIGN KEY (MaSanPham) REFERENCES SanPham(MaSanPham),
    CONSTRAINT FK_SPKM_KhuyenMai FOREIGN KEY (MaKhuyenMai) REFERENCES KhuyenMai(MaKhuyenMai)
);
GO

-- ===============================================================================
-- 7. BANG KHACH HANG
-- ===============================================================================
CREATE TABLE KhachHang (
    MaKhachHang INT IDENTITY(1,1) PRIMARY KEY,
    HoTen NVARCHAR(100) NOT NULL,
    Email NVARCHAR(100) NULL,
    SoDienThoai NVARCHAR(20) NOT NULL,
    DiaChi NVARCHAR(255) NULL,
    MatKhau NVARCHAR(255) NOT NULL,
    NgayTao DATETIME NOT NULL DEFAULT GETDATE(),
    TrangThai BIT NOT NULL DEFAULT 1
);
GO

-- ===============================================================================
-- 8. BANG NHAN VIEN
-- ===============================================================================
CREATE TABLE NhanVien (
    MaNhanVien INT IDENTITY(1,1) PRIMARY KEY,
    HoTen NVARCHAR(100) NOT NULL,
    Email NVARCHAR(100) NOT NULL,
    SoDienThoai NVARCHAR(20) NOT NULL,
    ChucVu NVARCHAR(50) NOT NULL DEFAULT N'Nhân viên',
    MatKhau NVARCHAR(255) NOT NULL,
    TrangThai BIT NOT NULL DEFAULT 1
);
GO

-- ===============================================================================
-- 9. BANG TAI KHOAN HE THONG (AUTHENTICATION & RBAC ROLES)
-- ===============================================================================
CREATE TABLE TaiKhoan (
    MaTaiKhoan INT IDENTITY(1,1) PRIMARY KEY,
    TenDangNhap NVARCHAR(50) NOT NULL UNIQUE,
    MatKhau NVARCHAR(255) NOT NULL,
    Email NVARCHAR(100) NULL,
    VaiTro NVARCHAR(20) NOT NULL,
    TrangThai BIT NOT NULL DEFAULT 1,
    MaKhachHang INT NULL,
    MaNhanVien INT NULL,
    NgayTao DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT CK_TaiKhoan_VaiTro CHECK (VaiTro IN ('ADMIN', 'SALES', 'SHIPPER', 'EMPLOYEE', 'CUSTOMER')),
    CONSTRAINT FK_TaiKhoan_KhachHang FOREIGN KEY (MaKhachHang) REFERENCES KhachHang(MaKhachHang),
    CONSTRAINT FK_TaiKhoan_NhanVien FOREIGN KEY (MaNhanVien) REFERENCES NhanVien(MaNhanVien)
);
GO

-- ===============================================================================
-- 10. BANG NHA CUNG CAP
-- ===============================================================================
CREATE TABLE NhaCungCap (
    MaNhaCungCap INT IDENTITY(1,1) PRIMARY KEY,
    TenNhaCungCap NVARCHAR(200) NOT NULL,
    SoDienThoai NVARCHAR(20) NULL,
    Email NVARCHAR(100) NULL,
    DiaChi NVARCHAR(255) NULL,
    TrangThai BIT NOT NULL DEFAULT 1
);
GO

-- ===============================================================================
-- 11. BANG LIEN KET NHA CUNG CAP - SAN PHAM
-- ===============================================================================
CREATE TABLE NhaCungCap_SanPham (
    MaNhaCungCap INT NOT NULL,
    MaSanPham INT NOT NULL,
    NgayLienKet DATETIME NOT NULL DEFAULT GETDATE(),
    PRIMARY KEY (MaNhaCungCap, MaSanPham),
    CONSTRAINT FK_NCCSP_NhaCungCap FOREIGN KEY (MaNhaCungCap) REFERENCES NhaCungCap(MaNhaCungCap),
    CONSTRAINT FK_NCCSP_SanPham FOREIGN KEY (MaSanPham) REFERENCES SanPham(MaSanPham)
);
GO

-- ===============================================================================
-- 12. BANG PHIEU NHAP KHO
-- ===============================================================================
CREATE TABLE PhieuNhap (
    MaPhieuNhap INT IDENTITY(1,1) PRIMARY KEY,
    MaNhaCungCap INT NOT NULL,
    MaNhanVien INT NOT NULL,
    NgayNhap DATETIME NOT NULL DEFAULT GETDATE(),
    TongTien DECIMAL(18,2) NOT NULL DEFAULT 0,
    TrangThai NVARCHAR(50) NOT NULL DEFAULT N'Chờ nghiệm thu',
    TrangThaiNghiemThu NVARCHAR(50) NOT NULL DEFAULT N'Chờ nghiệm thu',
    NgayNghiemThu DATETIME NULL,
    NguoiNghiemThu NVARCHAR(100) NULL,
    TongTienThucTe DECIMAL(18,2) NOT NULL DEFAULT 0,
    GhiChu NVARCHAR(500) NULL,
    CONSTRAINT FK_PhieuNhap_NCC FOREIGN KEY (MaNhaCungCap) REFERENCES NhaCungCap(MaNhaCungCap),
    CONSTRAINT FK_PhieuNhap_NhanVien FOREIGN KEY (MaNhanVien) REFERENCES NhanVien(MaNhanVien)
);
GO

-- ===============================================================================
-- 13. BANG CHI TIET PHIEU NHAP KHO
-- ===============================================================================
CREATE TABLE ChiTietPhieuNhap (
    MaChiTietPhieuNhap INT IDENTITY(1,1) PRIMARY KEY,
    MaPhieuNhap INT NOT NULL,
    MaSanPham INT NOT NULL,
    MaBienThe INT NULL,
    SoLuong INT NOT NULL,
    DonGiaNhap DECIMAL(18,2) NOT NULL,
    ThanhTien AS (CAST(SoLuong * DonGiaNhap AS DECIMAL(29,2))),
    SoLuongThucNhan INT NULL,
    SoLuongLoi INT NOT NULL DEFAULT 0,
    GhiChuKiemTra NVARCHAR(500) NULL,
    CONSTRAINT FK_CTPN_PhieuNhap FOREIGN KEY (MaPhieuNhap) REFERENCES PhieuNhap(MaPhieuNhap),
    CONSTRAINT FK_CTPN_SanPham FOREIGN KEY (MaSanPham) REFERENCES SanPham(MaSanPham),
    CONSTRAINT FK_CTPN_BienThe FOREIGN KEY (MaBienThe) REFERENCES BienTheSanPham(MaBienThe)
);
GO

-- ===============================================================================
-- 13B. BANG BIEN BAN SU CO NHAP HANG (HANG LOI, THIEU, SAI QUY CACH, HU HONG)
-- ===============================================================================
CREATE TABLE BienBanSuCoNhap (
    MaSuCo INT IDENTITY(1,1) PRIMARY KEY,
    MaPhieuNhap INT NOT NULL,
    MaSanPham INT NULL,
    MaNhanVienLap INT NULL,
    NgayLap DATETIME NOT NULL DEFAULT GETDATE(),
    LoaiSuCo NVARCHAR(100) NOT NULL,
    SoLuongThieu INT NOT NULL DEFAULT 0,
    SoLuongLoi INT NOT NULL DEFAULT 0,
    GiaTriGiamTru DECIMAL(18,2) NOT NULL DEFAULT 0,
    MoTaChiTiet NVARCHAR(500) NOT NULL,
    HuongXuLy NVARCHAR(200) NOT NULL DEFAULT N'Trả lại NCC & Giảm trừ công nợ',
    TrangThai NVARCHAR(50) NOT NULL DEFAULT N'Chờ xử lý',
    CONSTRAINT FK_BienBanSuCoNhap_PhieuNhap FOREIGN KEY (MaPhieuNhap) REFERENCES PhieuNhap(MaPhieuNhap) ON DELETE CASCADE,
    CONSTRAINT FK_BienBanSuCoNhap_SanPham FOREIGN KEY (MaSanPham) REFERENCES SanPham(MaSanPham),
    CONSTRAINT FK_BienBanSuCoNhap_NhanVien FOREIGN KEY (MaNhanVienLap) REFERENCES NhanVien(MaNhanVien)
);
GO

-- ===============================================================================
-- 13C. BANG CONG NO NHA CUNG CAP (CHI GHI NHAN THEO SO LUONG THUC TE NGHIEM THU)
-- ===============================================================================
CREATE TABLE CongNoNCC (
    MaCongNo INT IDENTITY(1,1) PRIMARY KEY,
    MaNhaCungCap INT NOT NULL,
    MaPhieuNhap INT NOT NULL,
    NgayGhiNhan DATETIME NOT NULL DEFAULT GETDATE(),
    HanThanhToan DATETIME NULL,
    TongTienPhieu DECIMAL(18,2) NOT NULL DEFAULT 0,
    GiaTriGiamTru DECIMAL(18,2) NOT NULL DEFAULT 0,
    SoTienPhaiTra DECIMAL(18,2) NOT NULL DEFAULT 0,
    SoTienDaTra DECIMAL(18,2) NOT NULL DEFAULT 0,
    TrangThai NVARCHAR(50) NOT NULL DEFAULT N'Chưa thanh toán',
    GhiChu NVARCHAR(500) NULL,
    CONSTRAINT FK_CongNoNCC_NhaCungCap FOREIGN KEY (MaNhaCungCap) REFERENCES NhaCungCap(MaNhaCungCap),
    CONSTRAINT FK_CongNoNCC_PhieuNhap FOREIGN KEY (MaPhieuNhap) REFERENCES PhieuNhap(MaPhieuNhap)
);
GO

-- ===============================================================================
-- 14. BANG PHUONG TIEN GIAO HANG / DOI XE
-- ===============================================================================
CREATE TABLE PhuongTien (
    MaPhuongTien INT IDENTITY(1,1) PRIMARY KEY,
    TenPhuongTien NVARCHAR(100) NOT NULL,
    LoaiXe NVARCHAR(50) NOT NULL,
    BienSo NVARCHAR(30) NOT NULL,
    TaiTrongKg INT NOT NULL,
    TheTichToiDaM3 FLOAT NULL,
    TrangThai NVARCHAR(50) NOT NULL DEFAULT N'Đang hoạt động',
    GhiChu NVARCHAR(255) NULL
);
GO

-- ===============================================================================
-- 15. BANG DON HANG (HO TRO DAT COC, HEN GIAO NGAY MAI, QUY CACH PHI)
-- ===============================================================================
CREATE TABLE DonHang (
    MaDonHang INT IDENTITY(1,1) PRIMARY KEY,
    MaKhachHang INT NOT NULL,
    NgayDat DATETIME NOT NULL DEFAULT GETDATE(),
    NguoiNhan NVARCHAR(100) NOT NULL,
    SoDienThoaiNhan NVARCHAR(20) NOT NULL,
    DiaChiGiao NVARCHAR(255) NOT NULL,
    TongTien DECIMAL(18,2) NOT NULL DEFAULT 0,
    TrangThai NVARCHAR(50) NOT NULL DEFAULT N'Chờ xác nhận',
    GhiChu NVARCHAR(500) NULL,
    PhiVanChuyen DECIMAL(18,2) NOT NULL DEFAULT 0,
    KhuVucGiaoHang NVARCHAR(50) NOT NULL DEFAULT N'Nội thành',
    MaNhanVien INT NULL,
    DaTruKho BIT NOT NULL DEFAULT 0,
    SoTienDatCoc DECIMAL(18,2) NOT NULL DEFAULT 0,
    DaThanhToan DECIMAL(18,2) NOT NULL DEFAULT 0,
    HenGiaoNgayMai BIT NOT NULL DEFAULT 0,
    NgayHenGiao DATETIME NULL,
    QuyCachTinhPhi NVARCHAR(100) NULL,
    LyDoHuy NVARCHAR(500) NULL,
    NgayHuy DATETIME NULL,
    NguoiHuy NVARCHAR(100) NULL,
    SoTienHoan DECIMAL(18,2) NOT NULL DEFAULT 0,
    LyDoDieuChinh NVARCHAR(500) NULL,
    CONSTRAINT FK_DonHang_KhachHang FOREIGN KEY (MaKhachHang) REFERENCES KhachHang(MaKhachHang),
    CONSTRAINT FK_DonHang_NhanVien FOREIGN KEY (MaNhanVien) REFERENCES NhanVien(MaNhanVien)
);
GO

-- ===============================================================================
-- 16. BANG CHI TIET DON HANG
-- ===============================================================================
CREATE TABLE ChiTietDonHang (
    MaChiTietDonHang INT IDENTITY(1,1) PRIMARY KEY,
    MaDonHang INT NOT NULL,
    MaSanPham INT NOT NULL,
    MaBienThe INT NULL,
    TenBienThe NVARCHAR(100) NULL,
    DonViTinh NVARCHAR(50) NULL,
    SoLuong INT NOT NULL,
    DonGia DECIMAL(18,2) NOT NULL,
    ThanhTien AS (CAST(SoLuong * DonGia AS DECIMAL(29,2))),
    CONSTRAINT FK_CTDH_DonHang FOREIGN KEY (MaDonHang) REFERENCES DonHang(MaDonHang),
    CONSTRAINT FK_CTDH_SanPham FOREIGN KEY (MaSanPham) REFERENCES SanPham(MaSanPham),
    CONSTRAINT FK_CTDH_BienThe FOREIGN KEY (MaBienThe) REFERENCES BienTheSanPham(MaBienThe)
);
GO

-- ===============================================================================
-- 17. BANG THANH TOAN
-- ===============================================================================
CREATE TABLE ThanhToan (
    MaThanhToan INT IDENTITY(1,1) PRIMARY KEY,
    MaDonHang INT NOT NULL,
    PhuongThuc NVARCHAR(50) NOT NULL DEFAULT N'Tiền mặt',
    SoTien DECIMAL(18,2) NOT NULL,
    NgayThanhToan DATETIME NOT NULL DEFAULT GETDATE(),
    TrangThai NVARCHAR(50) NOT NULL DEFAULT N'Chưa thanh toán',
    MaNhanVien INT NULL,
    CONSTRAINT FK_ThanhToan_DonHang FOREIGN KEY (MaDonHang) REFERENCES DonHang(MaDonHang),
    CONSTRAINT FK_ThanhToan_NhanVien FOREIGN KEY (MaNhanVien) REFERENCES NhanVien(MaNhanVien)
);
GO

-- ===============================================================================
-- 18. BANG GIAO HANG & DIEU PHOI DOI XE (CAC MOC TIEN TRINH & DOI SOAT COD)
-- ===============================================================================
CREATE TABLE GiaoHang (
    MaGiaoHang INT IDENTITY(1,1) PRIMARY KEY,
    MaDonHang INT NOT NULL,
    MaNhanVienGiao INT NULL,
    MaPhuongTien INT NULL,
    NgayGiao DATETIME NULL,
    NgayGiaoDuKien DATETIME NULL,
    ViDo FLOAT NULL,
    KinhDo FLOAT NULL,
    TrangThai NVARCHAR(50) NOT NULL DEFAULT N'Chờ nhận đơn',
    GhiChu NVARCHAR(500) NULL,
    HinhAnhXacNhan NVARCHAR(500) NULL,
    ThoiGianNhanDon DATETIME NULL,
    ThoiGianBanGiaoKho DATETIME NULL,
    ThoiGianLayHang DATETIME NULL,
    ThoiGianBatDauGiao DATETIME NULL,
    ThoiGianToiNoi DATETIME NULL,
    ThoiGianThuTien DATETIME NULL,
    SoTienThuThucTe DECIMAL(18,2) NULL,
    ThoiGianDoiSoat DATETIME NULL,
    NguoiDoiSoat NVARCHAR(100) NULL,
    TrangThaiDoiSoat NVARCHAR(50) NOT NULL DEFAULT N'Chưa đối soát',
    PhanLoaiSuCo NVARCHAR(100) NULL,
    LyDoThatBai NVARCHAR(500) NULL,
    SoLanGiaoThatBai INT NOT NULL DEFAULT 0,
    ThoiGianSuCo DATETIME NULL,
    MaNhanVienTuChoi INT NULL,
    TrangThaiXuLySuCo NVARCHAR(100) NULL,
    CONSTRAINT FK_GiaoHang_DonHang FOREIGN KEY (MaDonHang) REFERENCES DonHang(MaDonHang),
    CONSTRAINT FK_GiaoHang_NhanVien FOREIGN KEY (MaNhanVienGiao) REFERENCES NhanVien(MaNhanVien),
    CONSTRAINT FK_GiaoHang_PhuongTien FOREIGN KEY (MaPhuongTien) REFERENCES PhuongTien(MaPhuongTien)
);
GO

-- ===============================================================================
-- 19. BANG DOI TRA HANG HOA
-- ===============================================================================
CREATE TABLE DoiTra (
    MaDoiTra INT IDENTITY(1,1) PRIMARY KEY,
    MaDonHang INT NOT NULL,
    MaKhachHang INT NOT NULL,
    NgayYeuCau DATETIME NOT NULL DEFAULT GETDATE(),
    LyDo NVARCHAR(500) NOT NULL,
    TrangThai NVARCHAR(50) NOT NULL DEFAULT N'Chờ duyệt',
    GhiChu NVARCHAR(500) NULL,
    LoaiYeuCau NVARCHAR(50) NOT NULL DEFAULT N'Đổi hàng',
    PhuongAn NVARCHAR(100) NULL,
    HinhAnh NVARCHAR(500) NULL,
    CONSTRAINT FK_DoiTra_DonHang FOREIGN KEY (MaDonHang) REFERENCES DonHang(MaDonHang),
    CONSTRAINT FK_DoiTra_KhachHang FOREIGN KEY (MaKhachHang) REFERENCES KhachHang(MaKhachHang)
);
GO

-- ===============================================================================
-- 20. BANG CHI TIET DOI TRA
-- ===============================================================================
CREATE TABLE ChiTietDoiTra (
    MaChiTietDoiTra INT IDENTITY(1,1) PRIMARY KEY,
    MaDoiTra INT NOT NULL,
    MaSanPham INT NOT NULL,
    MaBienThe INT NULL,
    SoLuong INT NOT NULL,
    CONSTRAINT FK_CTDT_DoiTra FOREIGN KEY (MaDoiTra) REFERENCES DoiTra(MaDoiTra),
    CONSTRAINT FK_CTDT_SanPham FOREIGN KEY (MaSanPham) REFERENCES SanPham(MaSanPham),
    CONSTRAINT FK_CTDT_BienThe FOREIGN KEY (MaBienThe) REFERENCES BienTheSanPham(MaBienThe)
);
GO

-- ===============================================================================
-- 21. BANG DANH GIA SAN PHAM
-- ===============================================================================
CREATE TABLE DanhGia (
    MaDanhGia INT IDENTITY(1,1) PRIMARY KEY,
    MaSanPham INT NOT NULL,
    MaKhachHang INT NOT NULL,
    MaDonHang INT NOT NULL,
    SoSao INT NOT NULL,
    NoiDung NVARCHAR(1000) NULL,
    NgayDanhGia DATETIME NOT NULL DEFAULT GETDATE(),
    TrangThai BIT NOT NULL DEFAULT 1,
    CONSTRAINT CK_DanhGia_SoSao CHECK (SoSao >= 1 AND SoSao <= 5),
    CONSTRAINT FK_DanhGia_SanPham FOREIGN KEY (MaSanPham) REFERENCES SanPham(MaSanPham),
    CONSTRAINT FK_DanhGia_KhachHang FOREIGN KEY (MaKhachHang) REFERENCES KhachHang(MaKhachHang),
    CONSTRAINT FK_DanhGia_DonHang FOREIGN KEY (MaDonHang) REFERENCES DonHang(MaDonHang)
);
GO

-- ===============================================================================
-- 22. BANG QUY DOI DON VI TINH (BAN LE LINH HOAT)
-- ===============================================================================
CREATE TABLE QuyDoiDonVi (
    MaQuyDoi INT IDENTITY(1,1) PRIMARY KEY,
    MaSanPham INT NOT NULL,
    TenDonViQuyDoi NVARCHAR(50) NOT NULL,
    TenDonViGoc NVARCHAR(50) NOT NULL,
    HeSoQuyDoi DECIMAL(18,4) NOT NULL,
    GiaBanQuyDoi DECIMAL(18,2) NOT NULL,
    GhiChu NVARCHAR(255) NULL,
    TrangThai BIT NOT NULL DEFAULT 1,
    CONSTRAINT FK_QDDV_SanPham FOREIGN KEY (MaSanPham) REFERENCES SanPham(MaSanPham)
);
GO

-- ===============================================================================
-- 23. BANG BIEN DONG TON KHO (LICH SU XUAT / NHAP / CAN BANG TON)
-- ===============================================================================
CREATE TABLE BienDongTonKho (
    MaBienDong INT IDENTITY(1,1) PRIMARY KEY,
    Ngay DATE NOT NULL DEFAULT CAST(GETDATE() AS DATE),
    MaSanPham INT NOT NULL,
    MaBienThe INT NULL,
    TonDauNgay INT NOT NULL DEFAULT 0,
    NhapTrongNgay INT NOT NULL DEFAULT 0,
    XuatTrongNgay INT NOT NULL DEFAULT 0,
    BienDong INT NOT NULL DEFAULT 0,
    TonCuoiNgay INT NOT NULL DEFAULT 0,
    GhiChu NVARCHAR(255) NULL,
    CONSTRAINT FK_BienDongTonKho_SanPham FOREIGN KEY (MaSanPham) REFERENCES SanPham(MaSanPham),
    CONSTRAINT FK_BienDongTonKho_BienThe FOREIGN KEY (MaBienThe) REFERENCES BienTheSanPham(MaBienThe)
);
GO

-- ===============================================================================
-- CHI MUC (INDEXES) TOI UU HOA TRUY VAN NGHIEP VU
-- ===============================================================================
CREATE NONCLUSTERED INDEX IX_SanPham_DanhMuc ON SanPham(MaDanhMuc);
CREATE NONCLUSTERED INDEX IX_BienThe_SanPham ON BienTheSanPham(MaSanPham);
CREATE NONCLUSTERED INDEX IX_GiaBan_SanPham ON GiaBan(MaSanPham);
CREATE NONCLUSTERED INDEX IX_DonHang_KhachHang ON DonHang(MaKhachHang);
CREATE NONCLUSTERED INDEX IX_DonHang_TrangThai ON DonHang(TrangThai);
CREATE NONCLUSTERED INDEX IX_ChiTietDonHang_DonHang ON ChiTietDonHang(MaDonHang);
CREATE NONCLUSTERED INDEX IX_ChiTietDonHang_SanPham ON ChiTietDonHang(MaSanPham);
CREATE NONCLUSTERED INDEX IX_GiaoHang_DonHang ON GiaoHang(MaDonHang);
CREATE NONCLUSTERED INDEX IX_GiaoHang_NhanVien ON GiaoHang(MaNhanVienGiao);
CREATE NONCLUSTERED INDEX IX_GiaoHang_TrangThai ON GiaoHang(TrangThai);
CREATE NONCLUSTERED INDEX IX_BienDongTonKho_Ngay_SP ON BienDongTonKho(Ngay, MaSanPham);
CREATE NONCLUSTERED INDEX IX_SanPham_TrangThai_DanhMuc ON SanPham(TrangThai, MaDanhMuc) INCLUDE (TenSanPham, DonViTinh, SoLuongTon, HinhAnh);
CREATE NONCLUSTERED INDEX IX_DonHang_MaKhachHang_NgayDat ON DonHang(MaKhachHang, NgayDat DESC) INCLUDE (TrangThai, TongTien, DaTruKho);
CREATE NONCLUSTERED INDEX IX_GiaoHang_TrangThai_NhanVien ON GiaoHang(TrangThai, MaNhanVienGiao);
CREATE NONCLUSTERED INDEX IX_PhieuNhap_TrangThai_Ngay ON PhieuNhap(TrangThai, NgayNhap DESC);
CREATE NONCLUSTERED INDEX IX_CongNoNCC_NCC_TrangThai ON CongNoNCC(MaNhaCungCap, TrangThai);
CREATE NONCLUSTERED INDEX IX_BienBanSuCoNhap_PhieuNhap ON BienBanSuCoNhap(MaPhieuNhap);
CREATE NONCLUSTERED INDEX IX_DanhGia_SanPham_TrangThai ON DanhGia(MaSanPham, TrangThai);
CREATE NONCLUSTERED INDEX IX_KhuyenMai_HieuLuc ON KhuyenMai(TrangThai, TuNgay, DenNgay);
GO

-- ===============================================================================
-- DULIEU MAU KHOI TAO (SEED DATA CHUYEN NGHIEP VLXD-PRO)
-- ===============================================================================

SET IDENTITY_INSERT DanhMuc ON;
INSERT INTO DanhMuc (MaDanhMuc, TenDanhMuc, MoTa, HinhAnh, TrangThai) VALUES
(1, N'Xi măng', N'Các loại xi măng xây dựng, tô trát cao cấp', N'/Content/images/category/xi-mang.jpg', 1),
(2, N'Cát xây dựng', N'Cát tô, cát xây, cát bê tông chất lượng', N'/Content/images/category/cat-xay-dung.jpg', 1),
(3, N'Đá xây dựng', N'Đá 1x2, đá 4x6, đá mi tô trát', N'/Content/images/category/da-xay-dung.jpg', 1),
(4, N'Gạch xây dựng', N'Gạch ống, gạch thẻ, gạch block, gạch bê tông', N'/Content/images/category/gach-xay.jpg', 1),
(5, N'Sắt thép xây dựng', N'Thép cuộn, thép cây Pomina, Hòa Phát, Việt Nhật', N'/Content/images/category/sat-thep.jpg', 1),
(6, N'Sơn & Chống thấm', N'Sơn nội thất, ngoại thất, chất chống thấm cao cấp', N'/Content/images/category/son-chong-tham.jpg', 1),
(7, N'Ống nước & Phụ kiện', N'Ống nhựa PVC, PPR, Bình Minh, Hoa Sen', N'/Content/images/category/ong-nuoc.jpg', 1);
SET IDENTITY_INSERT DanhMuc OFF;
GO

SET IDENTITY_INSERT SanPham ON;
INSERT INTO SanPham (MaSanPham, MaDanhMuc, TenSanPham, DonViTinh, MoTa, HinhAnh, SoLuongTon, TrangThai, NgayTao) VALUES
(1, 1, N'Xi măng Hà Tiên Đa Dụng (50kg)', N'Bao', N'Xi măng Hà Tiên Đa Dụng dùng cho đổ bê tông, tô trát tường.', N'./Content/images/products/xi-mang-ha-tien.jpg', 592, 1, '2026-01-01'),
(2, 1, N'Xi măng Nghi Sơn PCB40 (50kg)', N'Bao', N'Xi măng Nghi Sơn chịu mặn, độ bền cao cho công trình dầm móng.', N'./Content/images/products/xi-mang-nghi-son.jpg', 349, 1, '2026-01-01'),
(3, 1, N'Xi măng Insee Wall Master (50kg)', N'Bao', N'Xi măng chuyên tô trát chống nứt bề mặt hiệu quả.', N'./Content/images/products/xi-mang-insee.jpg', 194, 1, '2026-01-01'),
(4, 2, N'Cát vàng đổ bê tông loại 1', N'Khối (m³)', N'Cát hạt to, sạch không lẫn tạp chất, phù hợp đổ bê tông tươi.', N'./Content/images/products/cat-vang.jpg', 120, 1, '2026-01-01'),
(5, 2, N'Cát tô trát tường sạch', N'Khối (m³)', N'Cát mịn dùng tô trát bề mặt tường mịn đẹp.', N'./Content/images/products/cat-to.jpg', 250, 1, '2026-01-01'),
(6, 3, N'Đá 1x2 xanh Đồng Nai', N'Khối (m³)', N'Đá 1x2 dùng làm bê tông sàn, dầm móng công trình.', N'./Content/images/products/da-1x2.jpg', 100, 1, '2026-01-01'),
(7, 3, N'Đá 4x6 lót móng', N'Khối (m³)', N'Đá 4x6 kiên cố dùng làm lớp lót móng nhà.', N'./Content/images/products/da-4x6.jpg', 80, 1, '2026-01-01'),
(8, 4, N'Gạch ống 4 lỗ Bình Dương 8x8x18', N'Viên', N'Gạch nung 4 lỗ kích thước chuẩn 8x8x18cm.', N'./Content/images/products/gach-4-lo.jpg', 49897, 1, '2026-01-01'),
(9, 4, N'Gạch đẻn 2 lỗ chịu lực', N'Viên', N'Gạch đặc 2 lỗ độ nung cao chịu lực tốt.', N'./Content/images/products/gach-2-lo.jpg', 29950, 1, '2026-01-01'),
(10, 4, N'Gạch Block siêu nhẹ 600x200x100mm', N'Viên', N'Gạch bê tông khí chưng áp chống nóng, cách âm.', N'./Content/images/products/gach-block.jpg', 5000, 1, '2026-01-01'),
(11, 5, N'Thép vằn Hòa Phát D10 (Cây 11.7m)', N'Cây', N'Thép phi 10 Hòa Phát tiêu chuẩn CB300V.', N'./Content/images/products/thep-hoa-phat-d10.jpg', 799, 1, '2026-01-01'),
(12, 5, N'Thép vằn Hòa Phát D12 (Cây 11.7m)', N'Cây', N'Thép phi 12 Hòa Phát mác thép cao cấp.', N'./Content/images/products/thep-hoa-phat-d12.jpg', 593, 1, '2026-01-01'),
(13, 5, N'Thép cuộn Pomina Phi 6 (kg)', N'Kg', N'Thép cuộn D6 Pomina chất lượng dẻo dai.', N'./Content/images/products/thep-cuon-pomina.jpg', 2495, 1, '2026-01-01'),
(14, 6, N'Sơn Dulux Weathershield 外墙 (Thùng 15L)', N'Thùng', N'Sơn ngoại thất chống bám bụi, bảo vệ 8 năm.', N'./Content/images/products/son-dulux-ngoai-that.jpg', 47, 1, '2026-01-01'),
(19, 2, N'Cát loại 2', N'm2', N'Cát san lấp công trình xây dựng.', N'./Content/images/products/no-image.jpg', 90, 1, '2026-01-01'),
(22, 7, N'Ong Nuoc Hoa Phat', N'm2', N'Ống nước bảo vệ công trình dẫn nước chịu áp lực.', N'./Content/images/products/no-image.jpg', 198, 1, '2026-01-01'),
(23, 7, N'Keo dan ong nuoc', N'g', N'Keo dán chuyên dụng ống nước PVC.', N'./Content/images/products/no-image.jpg', 98, 1, '2026-01-01');
SET IDENTITY_INSERT SanPham OFF;
GO

SET IDENTITY_INSERT BienTheSanPham ON;
INSERT INTO BienTheSanPham (MaBienThe, MaSanPham, TenBienThe, MaSKU, GiaNhap, GiaBan, SoLuongTon, HinhAnh, TrangThai, NgayTao) VALUES
(1, 22, N'Quy cách 60x60 (Phi 60)', N'ONG-60x60', 45000, 65000, 80, N'./Content/images/products/no-image.jpg', 1, '2026-01-01'),
(2, 22, N'Quy cách 80x60 (Phi 80)', N'ONG-80x60', 65000, 95000, 70, N'./Content/images/products/no-image.jpg', 1, '2026-01-01'),
(3, 22, N'Quy cách 100x100 (Phi 100)', N'ONG-100x100', 95000, 135000, 50, N'./Content/images/products/no-image.jpg', 1, '2026-01-01'),
(4, 14, N'Màu trắng sứ (White 100)', N'DLX-W100', 1100000, 1350000, 20, N'./Content/images/products/son-dulux-ngoai-that.jpg', 1, '2026-01-01'),
(5, 14, N'Màu ghi sáng (Grey 200)', N'DLX-G200', 1150000, 1400000, 15, N'./Content/images/products/son-dulux-ngoai-that.jpg', 1, '2026-01-01'),
(6, 14, N'Màu vàng kem (Cream 300)', N'DLX-C300', 1150000, 1400000, 14, N'./Content/images/products/son-dulux-ngoai-that.jpg', 1, '2026-01-01'),
(7, 10, N'Dày 100mm (600x200x100)', N'BLK-100', 12000, 16000, 2500, N'./Content/images/products/gach-block.jpg', 1, '2026-01-01'),
(8, 10, N'Dày 150mm (600x200x150)', N'BLK-150', 17000, 22000, 1500, N'./Content/images/products/gach-block.jpg', 1, '2026-01-01'),
(9, 10, N'Dày 200mm (600x200x200)', N'BLK-200', 22000, 28000, 1000, N'./Content/images/products/gach-block.jpg', 1, '2026-01-01');
SET IDENTITY_INSERT BienTheSanPham OFF;
GO

SET IDENTITY_INSERT GiaBan ON;
INSERT INTO GiaBan (MaGia, MaSanPham, Gia, TuNgay, DenNgay, TrangThai, LyDo) VALUES
(1, 1, 74000, '2026-01-01', NULL, 1, N'Giá niêm yết chuẩn'),
(2, 2, 92000, '2026-01-01', NULL, 1, N'Giá niêm yết chuẩn'),
(3, 3, 85000, '2026-01-01', NULL, 1, N'Giá niêm yết chuẩn'),
(4, 4, 340000, '2026-01-01', NULL, 1, N'Giá niêm yết chuẩn'),
(5, 5, 310000, '2026-01-01', NULL, 1, N'Giá niêm yết chuẩn'),
(6, 6, 420000, '2026-01-01', NULL, 1, N'Giá niêm yết chuẩn'),
(7, 7, 380000, '2026-01-01', NULL, 1, N'Giá niêm yết chuẩn'),
(8, 8, 1250, '2026-01-01', NULL, 1, N'Giá niêm yết chuẩn'),
(9, 9, 1100, '2026-01-01', NULL, 1, N'Giá niêm yết chuẩn'),
(10, 10, 18500, '2026-01-01', NULL, 1, N'Giá niêm yết chuẩn'),
(11, 11, 115000, '2026-01-01', NULL, 1, N'Giá niêm yết chuẩn'),
(12, 12, 165000, '2026-01-01', NULL, 1, N'Giá niêm yết chuẩn'),
(13, 13, 16800, '2026-01-01', NULL, 1, N'Giá niêm yết chuẩn'),
(14, 14, 1350000, '2026-01-01', NULL, 1, N'Giá niêm yết chuẩn'),
(15, 19, 50000, '2026-01-01', NULL, 1, N'Giá niêm yết chuẩn'),
(16, 22, 65000, '2026-01-01', NULL, 1, N'Giá niêm yết chuẩn'),
(17, 23, 20000, '2026-01-01', NULL, 1, N'Giá niêm yết chuẩn');
SET IDENTITY_INSERT GiaBan OFF;
GO

SET IDENTITY_INSERT KhuyenMai ON;
INSERT INTO KhuyenMai (MaKhuyenMai, TenKhuyenMai, LoaiKhuyenMai, SoLuongToiThieu, PhanTramGiam, SoTienGiam, TuNgay, DenNgay, TrangThai) VALUES
(1, N'Tri ân công trình - Giảm 5% Xi măng', N'Giảm giá thông thường', 1, 5, 0, '2026-01-01', '2026-12-31', 1),
(2, N'Khuyến mãi Thép Hòa Phát - Giảm 10.000đ/cây', N'Giảm giá thông thường', 1, 0, 10000, '2026-01-01', '2026-12-31', 1),
(3, N'Ưu đãi Sơn Dulux - Giảm 8%', N'Giảm giá thông thường', 1, 8, 0, '2026-01-01', '2026-12-31', 1),
(4, N'Ưu đãi mua từ 5 bao xi măng giảm 15%', N'Mua theo số lượng', 5, 15, 0, '2026-01-01', '2026-12-31', 1),
(5, N'Ưu đãi đơn hàng lớn mua từ 10 cây thép giảm 10%', N'Mua theo số lượng', 10, 10, 0, '2026-01-01', '2026-12-31', 1);
SET IDENTITY_INSERT KhuyenMai OFF;
GO

INSERT INTO SanPham_KhuyenMai (MaSanPham, MaKhuyenMai) VALUES
(1, 1),
(2, 1),
(11, 2),
(12, 2),
(14, 3),
(1, 4),
(11, 5);
GO

SET IDENTITY_INSERT KhachHang ON;
INSERT INTO KhachHang (MaKhachHang, HoTen, Email, SoDienThoai, DiaChi, MatKhau, NgayTao, TrangThai) VALUES
(1, N'Nguyễn Văn Hùng', N'khachhang1@gmail.com', N'0908123456', N'123 Lê Văn Việt, TP. Thủ Đức, TP.HCM', N'$2a$11$dV/bXzHYKWkYUGqR6ZaoWeqhiI6qqVC6HUJxJEKHX94GxG2ZITv4m', '2026-01-01', 1),
(2, N'Trần Thị Mai', N'khachhang2@gmail.com', N'0918654321', N'456 Nguyễn Xiển, Quận 9, TP.HCM', N'$2a$11$dV/bXzHYKWkYUGqR6ZaoWeqhiI6qqVC6HUJxJEKHX94GxG2ZITv4m', '2026-01-01', 1),
(3, N'Lê Hoàng Phúc', N'khachhang3@gmail.com', N'0933456789', N'789 Đỗ Xuân Hợp, Phước Long B, TP. Thủ Đức', N'$2a$11$dV/bXzHYKWkYUGqR6ZaoWeqhiI6qqVC6HUJxJEKHX94GxG2ZITv4m', '2026-01-01', 1);
SET IDENTITY_INSERT KhachHang OFF;
GO

SET IDENTITY_INSERT NhanVien ON;
INSERT INTO NhanVien (MaNhanVien, HoTen, Email, SoDienThoai, ChucVu, MatKhau, TrangThai) VALUES
(1, N'Quản Trị Viên VLXD', N'admin@vlxdpro.vn', N'0900000001', N'Quản trị viên', N'$2a$11$dV/bXzHYKWkYUGqR6ZaoWeqhiI6qqVC6HUJxJEKHX94GxG2ZITv4m', 1),
(2, N'Lê Văn Nam', N'nam.nv@vlxdpro.vn', N'0900000002', N'Nhân viên bán hàng', N'$2a$11$dV/bXzHYKWkYUGqR6ZaoWeqhiI6qqVC6HUJxJEKHX94GxG2ZITv4m', 1),
(3, N'Nguyễn Tấn Đạt', N'dat.giaohang@vlxdpro.vn', N'0900000003', N'Nhân viên giao hàng', N'$2a$11$dV/bXzHYKWkYUGqR6ZaoWeqhiI6qqVC6HUJxJEKHX94GxG2ZITv4m', 1),
(4, N'Nguyễn Văn C', N'nhanvienvlxd@gmail.com', N'0123456768', N'Nhân viên bán hàng', N'$2a$11$dV/bXzHYKWkYUGqR6ZaoWeqhiI6qqVC6HUJxJEKHX94GxG2ZITv4m', 1);
SET IDENTITY_INSERT NhanVien OFF;
GO

SET IDENTITY_INSERT TaiKhoan ON;
INSERT INTO TaiKhoan (MaTaiKhoan, TenDangNhap, MatKhau, Email, VaiTro, TrangThai, MaKhachHang, MaNhanVien, NgayTao) VALUES
(1, N'admin', N'$2a$11$dV/bXzHYKWkYUGqR6ZaoWeqhiI6qqVC6HUJxJEKHX94GxG2ZITv4m', N'admin@vlxdpro.vn', 'ADMIN', 1, NULL, 1, '2026-01-01'),
(2, N'nhanvien', N'$2a$11$dV/bXzHYKWkYUGqR6ZaoWeqhiI6qqVC6HUJxJEKHX94GxG2ZITv4m', N'nam.nv@vlxdpro.vn', 'SALES', 1, NULL, 2, '2026-01-01'),
(3, N'shipper', N'$2a$11$dV/bXzHYKWkYUGqR6ZaoWeqhiI6qqVC6HUJxJEKHX94GxG2ZITv4m', N'dat.giaohang@vlxdpro.vn', 'SHIPPER', 1, NULL, 3, '2026-01-01'),
(4, N'khachhang', N'$2a$11$dV/bXzHYKWkYUGqR6ZaoWeqhiI6qqVC6HUJxJEKHX94GxG2ZITv4m', N'khachhang1@gmail.com', 'CUSTOMER', 1, 1, NULL, '2026-01-01'),
(5, N'customer2', N'$2a$11$dV/bXzHYKWkYUGqR6ZaoWeqhiI6qqVC6HUJxJEKHX94GxG2ZITv4m', N'khachhang2@gmail.com', 'CUSTOMER', 1, 2, NULL, '2026-01-01');
SET IDENTITY_INSERT TaiKhoan OFF;
GO

SET IDENTITY_INSERT NhaCungCap ON;
INSERT INTO NhaCungCap (MaNhaCungCap, TenNhaCungCap, SoDienThoai, Email, DiaChi, TrangThai) VALUES
(1, N'Công Ty Xi Măng Hà Tiên 1', N'02838234567', N'contact@hatien1.com.vn', N'TP. Hồ Chí Minh', 1),
(2, N'Tập Đoàn Thép Hòa Phát', N'02439765432', N'sales@hoaphat.com.vn', N'Hà Nội', 1),
(3, N'Công Ty Sơn Dulux Việt Nam', N'02839998888', N'info@dulux.vn', N'Bình Dương', 1),
(4, N'Công Ty Cổ Phần Cát Đá & Gạch Miền Đông', N'02837654321', N'catda@miendong.vn', N'TP. Biên Hòa, Đồng Nai', 1),
(5, N'Tổng Kho Vật Liệu Xây Dựng Nam Sài Gòn', N'02838765432', N'vlxd.namsaigon@gmail.com', N'Quận 7, TP.HCM', 1);
SET IDENTITY_INSERT NhaCungCap OFF;
GO

INSERT INTO NhaCungCap_SanPham (MaNhaCungCap, MaSanPham, NgayLienKet) VALUES
(1, 1, '2026-01-01'),
(1, 2, '2026-01-01'),
(2, 11, '2026-01-01'),
(2, 12, '2026-01-01'),
(2, 13, '2026-01-01'),
(3, 14, '2026-01-01'),
(4, 4, '2026-01-01'),
(4, 5, '2026-01-01'),
(4, 6, '2026-01-01'),
(4, 7, '2026-01-01'),
(4, 8, '2026-01-01'),
(4, 9, '2026-01-01'),
(4, 10, '2026-01-01');
GO

SET IDENTITY_INSERT PhieuNhap ON;
INSERT INTO PhieuNhap (MaPhieuNhap, MaNhaCungCap, MaNhanVien, NgayNhap, TongTien, TrangThai, TrangThaiNghiemThu, NgayNghiemThu, NguoiNghiemThu, TongTienThucTe, GhiChu) VALUES
(1, 1, 1, '2026-01-02', 37000000, N'Đã xác nhận', N'Đã nghiệm thu', '2026-01-02', N'Quản Trị Viên VLXD', 37000000, N'Nhập 500 bao xi măng Hà Tiên về kho trung tâm'),
(2, 2, 1, '2026-01-03', 92000000, N'Đã xác nhận', N'Đã nghiệm thu', '2026-01-03', N'Quản Trị Viên VLXD', 92000000, N'Nhập thép cuộn và thép cây Hòa Phát'),
(3, 4, 2, '2026-01-04', 45000000, N'Đã xác nhận', N'Đã nghiệm thu', '2026-01-04', N'Lê Văn Nam', 45000000, N'Nhập 50.000 gạch ống 4 lỗ Bình Dương');
SET IDENTITY_INSERT PhieuNhap OFF;
GO

SET IDENTITY_INSERT ChiTietPhieuNhap ON;
INSERT INTO ChiTietPhieuNhap (MaChiTietPhieuNhap, MaPhieuNhap, MaSanPham, MaBienThe, SoLuong, DonGiaNhap, SoLuongThucNhan, SoLuongLoi) VALUES
(1, 1, 1, NULL, 500, 74000, 500, 0),
(2, 2, 11, NULL, 400, 115000, 400, 0),
(3, 2, 12, NULL, 280, 165000, 280, 0),
(4, 3, 8, NULL, 50000, 900, 50000, 0);
SET IDENTITY_INSERT ChiTietPhieuNhap OFF;
GO

SET IDENTITY_INSERT CongNoNCC ON;
INSERT INTO CongNoNCC (MaCongNo, MaNhaCungCap, MaPhieuNhap, NgayGhiNhan, HanThanhToan, TongTienPhieu, GiaTriGiamTru, SoTienPhaiTra, SoTienDaTra, TrangThai, GhiChu) VALUES
(1, 1, 1, '2026-01-02', '2026-02-01', 37000000, 0, 37000000, 37000000, N'Đã thanh toán', N'Thanh toán đủ phiếu nhập #PN0001'),
(2, 2, 2, '2026-01-03', '2026-02-02', 92000000, 0, 92000000, 50000000, N'Thanh toán một phần', N'Đã ứng 50 triệu đồng phiếu nhập #PN0002'),
(3, 4, 3, '2026-01-04', '2026-02-03', 45000000, 0, 45000000, 0, N'Chưa thanh toán', N'Công nợ phiếu nhập #PN0003 theo nghiệm thu thực tế');
SET IDENTITY_INSERT CongNoNCC OFF;
GO

SET IDENTITY_INSERT PhuongTien ON;
INSERT INTO PhuongTien (MaPhuongTien, TenPhuongTien, LoaiXe, BienSo, TaiTrongKg, TheTichToiDaM3, TrangThai, GhiChu) VALUES
(1, N'Xe máy Honda Wave Alpha 01', N'Xe máy', N'59-X1 123.45', 100, 0.2, N'Đang hoạt động', N'Giao đơn lẻ, cự ly ngắn, khối lượng nhỏ'),
(2, N'Xe máy Honda Future 02', N'Xe máy', N'59-X2 987.65', 120, 0.25, N'Đang hoạt động', N'Giao đơn lẻ hỏa tốc'),
(3, N'Xe ba gác T&T Fushida 01', N'Xe ba gác', N'59-B1 456.78', 1000, 1.5, N'Đang hoạt động', N'Giao ngõ hẻm, công trình vừa, gạch xi măng lẻ'),
(4, N'Xe ba gác Nam Định 02', N'Xe ba gác', N'59-B2 234.56', 1200, 1.8, N'Đang hoạt động', N'Giao ngõ hẻm nội thành'),
(5, N'Xe tải Isuzu 2.5 Tấn', N'Xe tải', N'51C-123.45', 2500, 5.0, N'Đang hoạt động', N'Chở sắt thép, xi măng, gạch công trình lớn'),
(6, N'Xe tải Hino 5 Tấn (Ben)', N'Xe tải', N'51C-678.90', 5000, 12.0, N'Đang hoạt động', N'Chở cát đá đổ nền, dầm móng công trình');
SET IDENTITY_INSERT PhuongTien OFF;
GO

SET IDENTITY_INSERT DonHang ON;
INSERT INTO DonHang (MaDonHang, MaKhachHang, NgayDat, NguoiNhan, SoDienThoaiNhan, DiaChiGiao, TongTien, TrangThai, GhiChu, PhiVanChuyen, KhuVucGiaoHang, MaNhanVien, DaTruKho, SoTienDatCoc, DaThanhToan, HenGiaoNgayMai, NgayHenGiao, QuyCachTinhPhi) VALUES
(1, 1, '2026-01-05 09:00:00', N'Nguyễn Văn Hùng', N'0908123456', N'123 Lê Văn Việt, TP. Thủ Đức, TP.HCM', 4550000, N'Đã giao', N'Giao xe ba gác vào hẻm', 150000, N'Nội thành', 2, 1, 4550000, 4550000, 0, NULL, N'KhuVuc'),
(2, 2, '2026-01-06 14:30:00', N'Trần Thị Mai', N'0918654321', N'456 Nguyễn Xiển, Quận 9, TP.HCM', 3850000, N'Đã giao', N'Hẹn giao giờ hành chính', 150000, N'Nội thành', 2, 1, 3850000, 3850000, 0, NULL, N'KhuVuc'),
(3, 1, '2026-01-07 10:15:00', N'Nguyễn Văn Hùng', N'0908123456', N'123 Lê Văn Việt, TP. Thủ Đức, TP.HCM', 1872600, N'Chờ xác nhận', N'Giao sáng mai công trình', 150000, N'Nội thành', NULL, 0, 0, 0, 1, '2026-01-08', N'KhuVuc');
SET IDENTITY_INSERT DonHang OFF;
GO

SET IDENTITY_INSERT ChiTietDonHang ON;
INSERT INTO ChiTietDonHang (MaChiTietDonHang, MaDonHang, MaSanPham, MaBienThe, TenBienThe, DonViTinh, SoLuong, DonGia) VALUES
(1, 1, 1, NULL, NULL, N'Bao', 50, 88000),
(2, 2, 8, NULL, NULL, N'Viên', 2000, 1250),
(3, 2, 1, NULL, NULL, N'Bao', 10, 88000),
(4, 3, 22, 1, N'Quy cách 60x60 (Phi 60)', N'm2', 20, 65000);
SET IDENTITY_INSERT ChiTietDonHang OFF;
GO

SET IDENTITY_INSERT ThanhToan ON;
INSERT INTO ThanhToan (MaThanhToan, MaDonHang, PhuongThuc, SoTien, NgayThanhToan, TrangThai, MaNhanVien) VALUES
(1, 1, N'Tiền mặt', 4550000, '2026-01-05 11:30:00', N'Đã thanh toán', 3),
(2, 2, N'Chuyển khoản', 3850000, '2026-01-06 16:00:00', N'Đã thanh toán', 2),
(3, 3, N'Tiền mặt', 1872600, '2026-01-07 10:15:00', N'Chưa thanh toán', NULL);
SET IDENTITY_INSERT ThanhToan OFF;
GO

SET IDENTITY_INSERT GiaoHang ON;
INSERT INTO GiaoHang (MaGiaoHang, MaDonHang, MaNhanVienGiao, MaPhuongTien, NgayGiao, NgayGiaoDuKien, ViDo, KinhDo, TrangThai, GhiChu, HinhAnhXacNhan, ThoiGianNhanDon, ThoiGianBanGiaoKho, ThoiGianLayHang, ThoiGianBatDauGiao, ThoiGianToiNoi, ThoiGianThuTien, SoTienThuThucTe, ThoiGianDoiSoat, NguoiDoiSoat, TrangThaiDoiSoat) VALUES
(1, 1, 3, 3, '2026-01-05 11:30:00', '2026-01-05 12:00:00', 10.8500, 106.7700, N'Đã giao', N'Đã giao đủ 50 bao tận tay anh Hùng', N'/Content/images/delivery/proof_1.jpg', '2026-01-05 09:15:00', '2026-01-05 09:30:00', '2026-01-05 09:45:00', '2026-01-05 10:00:00', '2026-01-05 10:45:00', '2026-01-05 11:00:00', 4550000, '2026-01-05 17:00:00', N'Lê Văn Nam', N'Đã đối soát xong'),
(2, 2, 3, 5, '2026-01-06 16:00:00', '2026-01-06 16:30:00', 10.8300, 106.7900, N'Đã giao', N'Đã hạ gạch và xi măng tại công trình', N'/Content/images/delivery/proof_2.jpg', '2026-01-06 14:40:00', '2026-01-06 15:00:00', '2026-01-06 15:15:00', '2026-01-06 15:30:00', '2026-01-06 15:50:00', '2026-01-06 16:00:00', 0, '2026-01-06 17:30:00', N'Lê Văn Nam', N'Đã đối soát xong'),
(3, 3, NULL, NULL, NULL, '2026-01-08 10:00:00', 10.8500, 106.7700, N'Chờ nhận đơn', N'Đơn hẹn giao ngày mai, chờ điều phối', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL, NULL, N'Chưa đối soát');
SET IDENTITY_INSERT GiaoHang OFF;
GO

SET IDENTITY_INSERT DoiTra ON;
INSERT INTO DoiTra (MaDoiTra, MaDonHang, MaKhachHang, NgayYeuCau, LyDo, TrangThai, GhiChu, LoaiYeuCau, PhuongAn, HinhAnh) VALUES
(1, 1, 1, '2026-01-06 08:30:00', N'Thừa 2 bao xi măng do ước lượng dư diện tích', N'Đã duyệt', N'Hỗ trợ khách hàng hoàn trả nhập lại kho', N'Trả hàng', N'Hoàn tiền mặt', N'/Content/images/returns/return_1.jpg');
SET IDENTITY_INSERT DoiTra OFF;
GO

SET IDENTITY_INSERT ChiTietDoiTra ON;
INSERT INTO ChiTietDoiTra (MaChiTietDoiTra, MaDoiTra, MaSanPham, MaBienThe, SoLuong) VALUES
(1, 1, 1, NULL, 2);
SET IDENTITY_INSERT ChiTietDoiTra OFF;
GO

SET IDENTITY_INSERT DanhGia ON;
INSERT INTO DanhGia (MaDanhGia, MaSanPham, MaKhachHang, MaDonHang, SoSao, NoiDung, NgayDanhGia, TrangThai) VALUES
(1, 1, 1, 1, 5, N'Xi măng chất lượng tốt, giao hàng đúng hẹn bằng xe tải tận công trình!', '2026-01-06 09:00:00', 1);
SET IDENTITY_INSERT DanhGia OFF;
GO

SET IDENTITY_INSERT QuyDoiDonVi ON;
INSERT INTO QuyDoiDonVi (MaQuyDoi, MaSanPham, TenDonViQuyDoi, TenDonViGoc, HeSoQuyDoi, GiaBanQuyDoi, GhiChu, TrangThai) VALUES
(1, 1, N'Kg', N'Bao', 50.0000, 2000.00, N'Bán lẻ theo Kg cho nhu cầu sửa chữa nhỏ (1 Bao = 50 Kg)', 1),
(2, 2, N'Kg', N'Bao', 50.0000, 2100.00, N'Bán lẻ theo Kg (1 Bao = 50 Kg)', 1),
(3, 11, N'Mét (m)', N'Cây', 11.7000, 14000.00, N'Cắt lẻ theo mét dài cho công trình (1 Cây = 11.7m)', 1),
(4, 12, N'Mét (m)', N'Cây', 11.7000, 20000.00, N'Cắt lẻ theo mét dài (1 Cây = 11.7m)', 1),
(5, 14, N'Lít', N'Thùng', 18.0000, 80000.00, N'Chiết lẻ theo lít cho dặm vá tường (1 Thùng = 18 Lít)', 1),
(6, 8, N'Viên', N'Thùng', 8.0000, 22000.00, N'Bán lẻ theo từng viên gạch (1 Thùng = 8 Viên)', 1),
(7, 8, N'm²', N'Thùng', 1.4400, 115000.00, N'Bán theo mét vuông ốp lát (1 Thùng = 1.44 m²)', 1);
SET IDENTITY_INSERT QuyDoiDonVi OFF;
GO

SET IDENTITY_INSERT BienDongTonKho ON;
INSERT INTO BienDongTonKho (MaBienDong, Ngay, MaSanPham, MaBienThe, TonDauNgay, NhapTrongNgay, XuatTrongNgay, BienDong, TonCuoiNgay, GhiChu) VALUES
(1, CAST(GETDATE() AS DATE), 1, NULL, 592, 0, 0, 0, 592, N'Cân bằng kho đầu ngày'),
(2, CAST(GETDATE() AS DATE), 2, NULL, 349, 0, 0, 0, 349, N'Cân bằng kho đầu ngày'),
(3, CAST(GETDATE() AS DATE), 3, NULL, 194, 0, 0, 0, 194, N'Cân bằng kho đầu ngày'),
(4, CAST(GETDATE() AS DATE), 8, NULL, 49897, 0, 0, 0, 49897, N'Cân bằng kho gạch ống'),
(5, CAST(GETDATE() AS DATE), 11, NULL, 799, 0, 0, 0, 799, N'Cân bằng kho thép D10'),
(6, CAST(GETDATE() AS DATE), 12, NULL, 593, 0, 0, 0, 593, N'Cân bằng kho thép D12'),
(7, CAST(DATEADD(DAY, -1, GETDATE()) AS DATE), 1, NULL, 592, 0, 0, 0, 592, N'Ghi nhận biến động hôm qua'),
(8, CAST(DATEADD(DAY, -3, GETDATE()) AS DATE), 1, NULL, 642, 0, 50, -50, 592, N'Xuất giao đơn hàng #1');
SET IDENTITY_INSERT BienDongTonKho OFF;
GO

-- ===============================================================================
-- 24. BANG XAC THUC OTP KHOI PHUC MAT KHAU
-- ===============================================================================
CREATE TABLE XacThucOTP (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Email NVARCHAR(100) NOT NULL,
    MaOTP NVARCHAR(10) NOT NULL,
    ThoiGianHetHan DATETIME NOT NULL,
    DaSuDung BIT NOT NULL DEFAULT 0,
    NgayTao DATETIME NOT NULL DEFAULT GETDATE()
);
GO

-- ===============================================================================
-- 25. BANG CAU HINH THANH TOAN VIETQR
-- ===============================================================================
CREATE TABLE CauHinhThanhToan (
    MaCauHinh INT IDENTITY(1,1) PRIMARY KEY,
    TenNganHang NVARCHAR(100) NOT NULL,
    SoTaiKhoan NVARCHAR(50) NOT NULL,
    ChuTaiKhoan NVARCHAR(100) NOT NULL,
    HinhAnhQR NVARCHAR(500) NULL,
    MaQRDuPhong NVARCHAR(500) NULL,
    CuPhapNoiDung NVARCHAR(200) NULL,
    GhiChuHuongDan NVARCHAR(500) NULL,
    NgayCapNhat DATETIME NOT NULL DEFAULT GETDATE()
);
GO

INSERT INTO CauHinhThanhToan (TenNganHang, SoTaiKhoan, ChuTaiKhoan, HinhAnhQR, CuPhapNoiDung, GhiChuHuongDan)
VALUES (N'Vietcombank (VCB) - CN Thủ Đức', '9908 1234 5678', N'CỬA HÀNG VẬT LIỆU XÂY DỰNG VLXD-PRO', '/Uploads/QR/default-qr.png', N'VLXD DH {MaDonHang}', N'Quét mã QR bằng ứng dụng ngân hàng hoặc ví điện tử để thanh toán');
GO

-- ===============================================================================
-- HOAN TAT TAO TOAN BO CO SO DU LIEU QL_CUA_HANG_VLXD
-- ===============================================================================
