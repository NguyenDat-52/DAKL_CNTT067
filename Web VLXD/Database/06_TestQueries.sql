-- ============================================================================
-- FILE 06: TEST QUERIES FOR SSMS & DATA VALIDATION
-- ============================================================================
USE QL_CUA_HANG_VLXD;
GO

-- 1. Xem danh sách tất cả Tài khoản và liên kết Quyền / Nhân viên / Khách hàng
SELECT 
    tk.MaTaiKhoan,
    tk.TenDangNhap,
    tk.VaiTro,
    tk.Email,
    tk.TrangThai,
    ISNULL(nv.HoTen, kh.HoTen) AS HoTenNguoiDung,
    ISNULL(nv.SoDienThoai, kh.SoDienThoai) AS SoDienThoai,
    tk.NgayTao
FROM TaiKhoan tk
LEFT JOIN NhanVien nv ON tk.MaNhanVien = nv.MaNhanVien
LEFT JOIN KhachHang kh ON tk.MaKhachHang = kh.MaKhachHang;

-- 2. Kiểm tra danh sách Sản phẩm, Giá bán hiện tại và Tồn kho
SELECT 
    sp.MaSanPham,
    sp.TenSanPham,
    dm.TenDanhMuc,
    sp.DonViTinh,
    sp.SoLuongTon,
    gb.GiaBan AS GiaHienTai,
    sp.TrangThai
FROM SanPham sp
JOIN DanhMuc dm ON sp.MaDanhMuc = dm.MaDanhMuc
LEFT JOIN GiaBan gb ON sp.MaSanPham = gb.MaSanPham AND gb.TrangThai = 1 AND (gb.DenNgay IS NULL OR gb.DenNgay >= GETDATE());

-- 3. Kiểm tra danh sách Đơn hàng và trạng thái Thanh toán / Giao hàng
SELECT 
    dh.MaDonHang,
    dh.NgayDat,
    dh.NguoiNhan,
    dh.SoDienThoaiNhan,
    dh.TongTien,
    dh.TrangThai AS TrangThaiDonHang,
    tt.PhuongThuc AS PhuongThucThanhToan,
    tt.TrangThai AS TrangThaiThanhToan,
    gh.TrangThai AS TrangThaiGiaoHang
FROM DonHang dh
LEFT JOIN ThanhToan tt ON dh.MaDonHang = tt.MaDonHang
LEFT JOIN GiaoHang gh ON dh.MaDonHang = gh.MaDonHang
ORDER BY dh.NgayDat DESC;
GO
