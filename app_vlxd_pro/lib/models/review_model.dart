class ReviewModel {
  final int maDanhGia;
  final int maSanPham;
  final int maKhachHang;
  final String hoTenKhachHang;
  final int maDonHang;
  final int soSao;
  final String noiDung;
  final DateTime? ngayDanhGia;

  ReviewModel({
    required this.maDanhGia,
    required this.maSanPham,
    required this.maKhachHang,
    required this.hoTenKhachHang,
    required this.maDonHang,
    required this.soSao,
    required this.noiDung,
    this.ngayDanhGia,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      maDanhGia: json['maDanhGia'] ?? 0,
      maSanPham: json['maSanPham'] ?? 0,
      maKhachHang: json['maKhachHang'] ?? 0,
      hoTenKhachHang: json['hoTenKhachHang'] ?? 'Khách hàng',
      maDonHang: json['maDonHang'] ?? 0,
      soSao: (json['soSao'] as num?)?.toInt() ?? 5,
      noiDung: json['noiDung'] ?? '',
      ngayDanhGia: json['ngayDanhGia'] != null ? DateTime.tryParse(json['ngayDanhGia']) : null,
    );
  }
}

class ReviewSummary {
  final int productId;
  final int totalReviews;
  final double averageRating;
  final List<ReviewModel> reviews;

  ReviewSummary({
    required this.productId,
    required this.totalReviews,
    required this.averageRating,
    required this.reviews,
  });

  factory ReviewSummary.fromJson(Map<String, dynamic> json) {
    var rawList = json['reviews'] as List<dynamic>? ?? [];
    var list = rawList.map((e) => ReviewModel.fromJson(e)).toList();

    return ReviewSummary(
      productId: json['productId'] ?? 0,
      totalReviews: (json['totalReviews'] as num?)?.toInt() ?? 0,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 5.0,
      reviews: list,
    );
  }
}

class CanReviewResult {
  final bool canReview;
  final bool hasExistingReview;
  final String message;
  final List<Map<String, dynamic>> eligibleOrders;
  final List<Map<String, dynamic>> unreviewedOrders;

  CanReviewResult({
    required this.canReview,
    this.hasExistingReview = false,
    required this.message,
    required this.eligibleOrders,
    required this.unreviewedOrders,
  });

  factory CanReviewResult.fromJson(Map<String, dynamic> json) {
    var eligible = (json['eligibleOrders'] as List<dynamic>? ?? [])
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    var unreviewed = (json['unreviewedOrders'] as List<dynamic>? ?? [])
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    return CanReviewResult(
      canReview: json['canReview'] ?? false,
      hasExistingReview: json['hasExistingReview'] ?? false,
      message: json['message'] ?? '',
      eligibleOrders: eligible,
      unreviewedOrders: unreviewed,
    );
  }
}
