import '../widgets/currency_formatter.dart';

class PromotionModel {
  final int maKhuyenMai;
  final String tenKhuyenMai;
  final int phanTramGiam;
  final double soTienGiam;
  final String loaiKhuyenMai;
  final int soLuongToiThieu;
  final DateTime? tuNgay;
  final DateTime? denNgay;
  final List<int> productIds;
  final bool isOrderTotalDiscount;
  final bool isQuantityDiscount;

  PromotionModel({
    required this.maKhuyenMai,
    required this.tenKhuyenMai,
    required this.phanTramGiam,
    required this.soTienGiam,
    required this.loaiKhuyenMai,
    required this.soLuongToiThieu,
    this.tuNgay,
    this.denNgay,
    required this.productIds,
    this.isOrderTotalDiscount = false,
    this.isQuantityDiscount = false,
  });

  factory PromotionModel.fromJson(Map<String, dynamic> json) {
    var rawProductIds = json['productIds'] as List<dynamic>? ?? [];
    List<int> pIds = rawProductIds.map((e) => (e as num).toInt()).toList();

    return PromotionModel(
      maKhuyenMai: json['maKhuyenMai'] ?? 0,
      tenKhuyenMai: json['tenKhuyenMai'] ?? '',
      phanTramGiam: (json['phanTramGiam'] as num?)?.toInt() ?? 0,
      soTienGiam: (json['soTienGiam'] as num?)?.toDouble() ?? 0.0,
      loaiKhuyenMai: json['loaiKhuyenMai'] ?? '',
      soLuongToiThieu: (json['soLuongToiThieu'] as num?)?.toInt() ?? 1,
      tuNgay: json['tuNgay'] != null ? DateTime.tryParse(json['tuNgay']) : null,
      denNgay: json['denNgay'] != null ? DateTime.tryParse(json['denNgay']) : null,
      productIds: pIds,
      isOrderTotalDiscount: json['isOrderTotalDiscount'] ?? false,
      isQuantityDiscount: json['isQuantityDiscount'] ?? false,
    );
  }

  String get discountBadge {
    if (phanTramGiam > 0) {
      return 'Giảm $phanTramGiam%';
    } else if (soTienGiam > 0) {
      return 'Giảm ${Formatters.formatCurrency(soTienGiam)}';
    }
    return 'Ưu đãi đặc biệt';
  }

  String get conditionText {
    if (isQuantityDiscount && soLuongToiThieu > 1) {
      return 'Áp dụng khi mua từ $soLuongToiThieu đơn vị';
    } else if (isOrderTotalDiscount && soLuongToiThieu > 1) {
      return 'Áp dụng cho đơn hàng từ ${Formatters.formatCurrency(soLuongToiThieu.toDouble())}';
    }
    return 'Áp dụng cho tất cả đơn hàng';
  }

  String get discountTag {
    if (phanTramGiam > 0) {
      return '-$phanTramGiam%';
    } else if (soTienGiam > 0) {
      return '-${Formatters.formatCurrency(soTienGiam)}';
    }
    return 'GIẢM GIÁ';
  }

  /// Calculates the discounted unit price for a given original price
  double getDiscountedPrice(double originalPrice) {
    if (phanTramGiam > 0) {
      final res = originalPrice * (1.0 - phanTramGiam / 100.0);
      return res > 0 ? res : 0.0;
    } else if (soTienGiam > 0) {
      final res = originalPrice - soTienGiam;
      return res > 0 ? res : 0.0;
    }
    return originalPrice;
  }

  /// Calculates discount amount for a given unit price and quantity
  double calculateDiscount(double price, int quantity) {
    if (isQuantityDiscount && quantity < soLuongToiThieu) {
      return 0.0;
    }
    if (phanTramGiam > 0) {
      return price * quantity * phanTramGiam / 100.0;
    } else if (soTienGiam > 0) {
      return soTienGiam * quantity;
    }
    return 0.0;
  }
}
