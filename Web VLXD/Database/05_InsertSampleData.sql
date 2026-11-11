-- ============================================================================
-- FILE 05: SEED INITIAL ACCOUNTS & SAMPLE DATA
-- ============================================================================
USE QL_CUA_HANG_VLXD;
GO

-- Seed Accounts for ADMIN, EMPLOYEE, CUSTOMER if not exists
-- Note: Password default '123456' hashed via Bcrypt (Work Factor 11) = $2a$11$dV/bXzHYKWkYUGqR6ZaoWeqhiI6qqVC6HUJxJEKHX94GxG2ZITv4m

-- 1. ADMIN Account
IF NOT EXISTS (SELECT * FROM TaiKhoan WHERE TenDangNhap = 'admin')
BEGIN
    INSERT INTO TaiKhoan (TenDangNhap, MatKhau, Email, VaiTro, TrangThai, MaNhanVien)
    VALUES ('admin', '$2a$11$dV/bXzHYKWkYUGqR6ZaoWeqhiI6qqVC6HUJxJEKHX94GxG2ZITv4m', 'admin@vlxdpro.vn', 'ADMIN', 1, 1);
END

-- 2. EMPLOYEE Account (Nhân viên kinh doanh)
IF NOT EXISTS (SELECT * FROM TaiKhoan WHERE TenDangNhap = 'nhanvien')
BEGIN
    INSERT INTO TaiKhoan (TenDangNhap, MatKhau, Email, VaiTro, TrangThai, MaNhanVien)
    VALUES ('nhanvien', '$2a$11$dV/bXzHYKWkYUGqR6ZaoWeqhiI6qqVC6HUJxJEKHX94GxG2ZITv4m', 'nhanvien@vlxdpro.vn', 'EMPLOYEE', 1, 2);
END

-- 3. CUSTOMER Account (Khách hàng)
IF NOT EXISTS (SELECT * FROM TaiKhoan WHERE TenDangNhap = 'khachhang')
BEGIN
    INSERT INTO TaiKhoan (TenDangNhap, MatKhau, Email, VaiTro, TrangThai, MaKhachHang)
    VALUES ('khachhang', '$2a$11$dV/bXzHYKWkYUGqR6ZaoWeqhiI6qqVC6HUJxJEKHX94GxG2ZITv4m', 'nguyenvana@gmail.com', 'CUSTOMER', 1, 1);
END
GO
