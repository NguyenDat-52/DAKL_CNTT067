import 'package:flutter_test/flutter_test.dart';
import 'package:app_vlxd_pro/services/otp_service.dart';
import 'package:app_vlxd_pro/models/order_model.dart';
import 'package:app_vlxd_pro/utils/vietnamese_helper.dart';

void main() {
  group('OTP Generation & Verification Tests', () {
    test('generateOtp returns a 6-digit numeric string', () {
      for (int i = 0; i < 20; i++) {
        final otp = OtpService.generateOtp();
        expect(otp.length, equals(6));
        expect(int.tryParse(otp), isNotNull);
        expect(int.parse(otp), greaterThanOrEqualTo(100000));
        expect(int.parse(otp), lessThanOrEqualTo(999999));
      }
    });

    test('sendOtp and verifyOtp locally validates correctly', () async {
      const email = 'khachhang1@gmail.com';
      final res = await OtpService.sendOtp(recipientEmail: email);
      expect(res['success'], isTrue);

      final otpCode = res['otp'] as String;
      expect(otpCode.length, equals(6));

      // Correct OTP
      expect(OtpService.verifyOtp(email, otpCode), isTrue);

      // Wrong OTP
      expect(OtpService.verifyOtp(email, '000000'), isFalse);
      expect(OtpService.verifyOtp(email, '12345'), isFalse);

      // Wrong email
      expect(OtpService.verifyOtp('other@gmail.com', otpCode), isFalse);
    });

    test('resetPassword requires valid OTP and updates', () async {
      const email = 'test_reset@gmail.com';
      final res = await OtpService.sendOtp(recipientEmail: email);
      final otp = res['otp'] as String;

      // Fail with wrong OTP
      final failResult = await OtpService.resetPassword(
        email: email,
        otp: '999999',
        newPassword: 'newpassword123',
      );
      expect(failResult['success'], isFalse);

      // Success with correct OTP
      final successResult = await OtpService.resetPassword(
        email: email,
        otp: otp,
        newPassword: 'newpassword123',
      );
      expect(successResult['success'], isTrue);
    });
  });

  group('Order Search Logic Tests', () {
    final sampleOrders = [
      OrderModel(
        maDonHang: 12,
        orderCode: 'DH-12',
        nguoiNhan: 'Nguyễn Văn Đạt',
        soDienThoaiNhan: '0908123456',
        diaChiGiao: '123 QL1A',
        khuVucGiaoHang: 'Nội thành',
        phiVanChuyen: 150000,
        tongTien: 444000,
        soTienDatCoc: 0,
        trangThai: 'Chờ xác nhận',
        phuongThucThanhToan: 'Chuyển khoản',
        trangThaiThanhToan: 'Chờ thanh toán',
        trangThaiGiaoHang: 'Chờ xác nhận',
        items: [
          OrderItemModel(
            maChiTiet: 1,
            maSanPham: 1,
            tenSanPham: 'Xi măng Vicem Hà Tiên PCB40',
            soLuong: 6,
            donGia: 74000,
            donViTinh: 'Bao',
            thanhTien: 444000,
          ),
        ],
      ),
      OrderModel(
        maDonHang: 15,
        orderCode: 'DH-15',
        nguoiNhan: 'Trần Thị Mai',
        soDienThoaiNhan: '0912345678',
        diaChiGiao: '456 Lê Lợi',
        khuVucGiaoHang: 'Ngoại thành',
        phiVanChuyen: 0,
        tongTien: 1200000,
        soTienDatCoc: 0,
        trangThai: 'Đang giao',
        phuongThucThanhToan: 'Tiền mặt',
        trangThaiThanhToan: 'Chưa thanh toán',
        trangThaiGiaoHang: 'Đang giao',
        items: [
          OrderItemModel(
            maChiTiet: 2,
            maSanPham: 11,
            tenSanPham: 'Thép vằn Hòa Phát phi 18 (Cây 11.7m)',
            soLuong: 10,
            donGia: 120000,
            donViTinh: 'Cây',
            thanhTien: 1200000,
          ),
        ],
      ),
    ];

    test('Filter orders by Order ID / Code', () {
      final query = '12';
      final matches = sampleOrders.where((o) =>
        o.orderCode.toLowerCase().contains(query.toLowerCase()) ||
        o.maDonHang.toString() == query
      ).toList();

      expect(matches.length, equals(1));
      expect(matches.first.maDonHang, equals(12));
    });

    test('Filter orders by product name unaccented', () {
      final query1 = 'xi mang';
      final matches1 = sampleOrders.where((o) =>
        o.items.any((item) => VietnameseHelper.matches(item.tenSanPham, query1))
      ).toList();

      expect(matches1.length, equals(1));
      expect(matches1.first.maDonHang, equals(12));

      final query2 = 'thep hoa phat';
      final matches2 = sampleOrders.where((o) =>
        o.items.any((item) => VietnameseHelper.matches(item.tenSanPham, query2))
      ).toList();

      expect(matches2.length, equals(1));
      expect(matches2.first.maDonHang, equals(15));
    });
  });
}
