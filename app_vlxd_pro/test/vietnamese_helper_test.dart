import 'package:flutter_test/flutter_test.dart';
import 'package:app_vlxd_pro/utils/vietnamese_helper.dart';
import 'package:app_vlxd_pro/models/promotion_model.dart';

void main() {
  group('VietnameseHelper Tests', () {
    test('toUnaccented correctly strips Vietnamese diacritics', () {
      expect(VietnameseHelper.toUnaccented('Sắt Thép'), equals('sat thep'));
      expect(VietnameseHelper.toUnaccented('Xi Măng Vicem Hà Tiên'), equals('xi mang vicem ha tien'));
      expect(VietnameseHelper.toUnaccented('Ống Nước Bình Minh'), equals('ong nuoc binh minh'));
      expect(VietnameseHelper.toUnaccented('Gạch Men Viglacera'), equals('gach men viglacera'));
      expect(VietnameseHelper.toUnaccented('Đá Xây Dựng 1x2'), equals('da xay dung 1x2'));
      expect(VietnameseHelper.toUnaccented('Cát Vàng Xây Tô'), equals('cat vang xay to'));
    });

    test('matches handles both accented and unaccented queries correctly', () {
      const product1 = 'Sắt thép cây vằn Hòa Phát phi 18';
      const product2 = 'Xi măng Vicem Hà Tiên PCB40';
      const product3 = 'Ống nhựa Tiền Phong D90';
      const product4 = 'Gạch xây tuynel Bình Dương';
      const product5 = 'Đá mi sàng lọc';

      // Accented query matching
      expect(VietnameseHelper.matches(product1, 'sắt thép'), isTrue);
      expect(VietnameseHelper.matches(product2, 'xi măng'), isTrue);
      expect(VietnameseHelper.matches(product3, 'ống nhựa'), isTrue);
      expect(VietnameseHelper.matches(product4, 'gạch xây'), isTrue);
      expect(VietnameseHelper.matches(product5, 'đá mi'), isTrue);

      // Unaccented query matching (CRITICAL requirement)
      expect(VietnameseHelper.matches(product1, 'sat thep'), isTrue);
      expect(VietnameseHelper.matches(product1, 'hoa phat'), isTrue);
      expect(VietnameseHelper.matches(product2, 'xi mang'), isTrue);
      expect(VietnameseHelper.matches(product2, 'ha tien'), isTrue);
      expect(VietnameseHelper.matches(product3, 'ong nhua'), isTrue);
      expect(VietnameseHelper.matches(product3, 'tien phong'), isTrue);
      expect(VietnameseHelper.matches(product4, 'gach xay'), isTrue);
      expect(VietnameseHelper.matches(product4, 'binh duong'), isTrue);
      expect(VietnameseHelper.matches(product5, 'da mi'), isTrue);

      // Non-matching query
      expect(VietnameseHelper.matches(product1, 'xi mang'), isFalse);
      expect(VietnameseHelper.matches(product2, 'sat thep'), isFalse);
    });
  });

  group('PromotionModel Discount Calculations', () {
    test('Calculates percentage discount correctly', () {
      final promo = PromotionModel(
        maKhuyenMai: 1,
        tenKhuyenMai: 'Giảm 15% xi măng',
        phanTramGiam: 15,
        soTienGiam: 0,
        loaiKhuyenMai: 'Phần trăm',
        soLuongToiThieu: 1,
        productIds: [1, 2],
      );

      expect(promo.discountBadge, equals('Giảm 15%'));
      expect(promo.discountTag, equals('-15%'));
      expect(promo.getDiscountedPrice(100000.0), equals(85000.0));
      expect(promo.calculateDiscount(100000.0, 2), equals(30000.0));
    });

    test('Calculates fixed amount discount correctly', () {
      final promo = PromotionModel(
        maKhuyenMai: 2,
        tenKhuyenMai: 'Giảm 10.000đ/cây thép',
        phanTramGiam: 0,
        soTienGiam: 10000.0,
        loaiKhuyenMai: 'Số tiền',
        soLuongToiThieu: 1,
        productIds: [11],
      );

      expect(promo.discountBadge, contains('10.000'));
      expect(promo.discountTag, contains('-10.000'));
      expect(promo.getDiscountedPrice(250000.0), equals(240000.0));
      expect(promo.calculateDiscount(250000.0, 3), equals(30000.0));
    });
  });
}
