-- ============================================================================
-- FILE 03: CREATE FOREIGN KEY RELATIONSHIPS FOR QL_CUA_HANG_VLXD
-- ============================================================================
USE QL_CUA_HANG_VLXD;
GO

-- FK SanPham -> DanhMuc
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_SanPham_DanhMuc')
    ALTER TABLE SanPham ADD CONSTRAINT FK_SanPham_DanhMuc FOREIGN KEY (MaDanhMuc) REFERENCES DanhMuc(MaDanhMuc);

-- FK GiaBan -> SanPham
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_GiaBan_SanPham')
    ALTER TABLE GiaBan ADD CONSTRAINT FK_GiaBan_SanPham FOREIGN KEY (MaSanPham) REFERENCES SanPham(MaSanPham);

-- FK SanPham_KhuyenMai -> SanPham / KhuyenMai
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_SPKM_SanPham')
    ALTER TABLE SanPham_KhuyenMai ADD CONSTRAINT FK_SPKM_SanPham FOREIGN KEY (MaSanPham) REFERENCES SanPham(MaSanPham);

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_SPKM_KhuyenMai')
    ALTER TABLE SanPham_KhuyenMai ADD CONSTRAINT FK_SPKM_KhuyenMai FOREIGN KEY (MaKhuyenMai) REFERENCES KhuyenMai(MaKhuyenMai);

-- FK PhieuNhap -> NhaCungCap / NhanVien
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_PhieuNhap_NCC')
    ALTER TABLE PhieuNhap ADD CONSTRAINT FK_PhieuNhap_NCC FOREIGN KEY (MaNhaCungCap) REFERENCES NhaCungCap(MaNhaCungCap);

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_PhieuNhap_NhanVien')
    ALTER TABLE PhieuNhap ADD CONSTRAINT FK_PhieuNhap_NhanVien FOREIGN KEY (MaNhanVien) REFERENCES NhanVien(MaNhanVien);

-- FK ChiTietPhieuNhap -> PhieuNhap / SanPham
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_CTPN_PhieuNhap')
    ALTER TABLE ChiTietPhieuNhap ADD CONSTRAINT FK_CTPN_PhieuNhap FOREIGN KEY (MaPhieuNhap) REFERENCES PhieuNhap(MaPhieuNhap);

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_CTPN_SanPham')
    ALTER TABLE ChiTietPhieuNhap ADD CONSTRAINT FK_CTPN_SanPham FOREIGN KEY (MaSanPham) REFERENCES SanPham(MaSanPham);

-- FK DonHang -> KhachHang
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_DonHang_KhachHang')
    ALTER TABLE DonHang ADD CONSTRAINT FK_DonHang_KhachHang FOREIGN KEY (MaKhachHang) REFERENCES KhachHang(MaKhachHang);

-- FK ChiTietDonHang -> DonHang / SanPham
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_CTDH_DonHang')
    ALTER TABLE ChiTietDonHang ADD CONSTRAINT FK_CTDH_DonHang FOREIGN KEY (MaDonHang) REFERENCES DonHang(MaDonHang);

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_CTDH_SanPham')
    ALTER TABLE ChiTietDonHang ADD CONSTRAINT FK_CTDH_SanPham FOREIGN KEY (MaSanPham) REFERENCES SanPham(MaSanPham);

-- FK ThanhToan -> DonHang
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_ThanhToan_DonHang')
    ALTER TABLE ThanhToan ADD CONSTRAINT FK_ThanhToan_DonHang FOREIGN KEY (MaDonHang) REFERENCES DonHang(MaDonHang);

-- FK GiaoHang -> DonHang / NhanVien
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_GiaoHang_DonHang')
    ALTER TABLE GiaoHang ADD CONSTRAINT FK_GiaoHang_DonHang FOREIGN KEY (MaDonHang) REFERENCES DonHang(MaDonHang);

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_GiaoHang_NhanVien')
    ALTER TABLE GiaoHang ADD CONSTRAINT FK_GiaoHang_NhanVien FOREIGN KEY (MaNhanVienGiao) REFERENCES NhanVien(MaNhanVien);

-- FK DoiTra -> DonHang
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_DoiTra_DonHang')
    ALTER TABLE DoiTra ADD CONSTRAINT FK_DoiTra_DonHang FOREIGN KEY (MaDonHang) REFERENCES DonHang(MaDonHang);

-- FK ChiTietDoiTra -> DoiTra / SanPham
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_CTDT_DoiTra')
    ALTER TABLE ChiTietDoiTra ADD CONSTRAINT FK_CTDT_DoiTra FOREIGN KEY (MaDoiTra) REFERENCES DoiTra(MaDoiTra);

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_CTDT_SanPham')
    ALTER TABLE ChiTietDoiTra ADD CONSTRAINT FK_CTDT_SanPham FOREIGN KEY (MaSanPham) REFERENCES SanPham(MaSanPham);

-- FK DanhGia -> SanPham / KhachHang
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_DanhGia_SanPham')
    ALTER TABLE DanhGia ADD CONSTRAINT FK_DanhGia_SanPham FOREIGN KEY (MaSanPham) REFERENCES SanPham(MaSanPham);

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_DanhGia_KhachHang')
    ALTER TABLE DanhGia ADD CONSTRAINT FK_DanhGia_KhachHang FOREIGN KEY (MaKhachHang) REFERENCES KhachHang(MaKhachHang);

-- FK TaiKhoan -> KhachHang / NhanVien
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_TaiKhoan_KhachHang')
    ALTER TABLE TaiKhoan ADD CONSTRAINT FK_TaiKhoan_KhachHang FOREIGN KEY (MaKhachHang) REFERENCES KhachHang(MaKhachHang);

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_TaiKhoan_NhanVien')
    ALTER TABLE TaiKhoan ADD CONSTRAINT FK_TaiKhoan_NhanVien FOREIGN KEY (MaNhanVien) REFERENCES NhanVien(MaNhanVien);
GO
