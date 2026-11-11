class CategoryModel {
  final int maDanhMuc;
  final String tenDanhMuc;
  final String? moTa;
  final int soLuongSanPham;

  CategoryModel({
    required this.maDanhMuc,
    required this.tenDanhMuc,
    this.moTa,
    this.soLuongSanPham = 0,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      maDanhMuc: json['maDanhMuc'] ?? 0,
      tenDanhMuc: json['tenDanhMuc'] ?? '',
      moTa: json['moTa'],
      soLuongSanPham: json['soLuongSanPham'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maDanhMuc': maDanhMuc,
      'tenDanhMuc': tenDanhMuc,
      'moTa': moTa,
      'soLuongSanPham': soLuongSanPham,
    };
  }
}
