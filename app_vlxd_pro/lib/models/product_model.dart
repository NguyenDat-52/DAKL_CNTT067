class VariantModel {
  final int maBienThe;
  final String tenBienThe;
  final double giaBan;
  final int soLuongTon;

  VariantModel({
    required this.maBienThe,
    required this.tenBienThe,
    required this.giaBan,
    required this.soLuongTon,
  });

  factory VariantModel.fromJson(Map<String, dynamic> json) {
    return VariantModel(
      maBienThe: json['maBienThe'] ?? 0,
      tenBienThe: json['tenBienThe'] ?? '',
      giaBan: (json['giaBan'] is num) ? (json['giaBan'] as num).toDouble() : 0.0,
      soLuongTon: json['soLuongTon'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maBienThe': maBienThe,
      'tenBienThe': tenBienThe,
      'giaBan': giaBan,
      'soLuongTon': soLuongTon,
    };
  }
}

class UnitConversionModel {
  final int maQuyDoi;
  final String tenDonViQuyDoi;
  final String tenDonViGoc;
  final double heSoQuyDoi;
  final double giaBanQuyDoi;

  UnitConversionModel({
    required this.maQuyDoi,
    required this.tenDonViQuyDoi,
    required this.tenDonViGoc,
    required this.heSoQuyDoi,
    required this.giaBanQuyDoi,
  });

  factory UnitConversionModel.fromJson(Map<String, dynamic> json) {
    return UnitConversionModel(
      maQuyDoi: json['maQuyDoi'] ?? 0,
      tenDonViQuyDoi: json['tenDonViQuyDoi'] ?? '',
      tenDonViGoc: json['tenDonViGoc'] ?? '',
      heSoQuyDoi: (json['heSoQuyDoi'] is num) ? (json['heSoQuyDoi'] as num).toDouble() : 1.0,
      giaBanQuyDoi: (json['giaBanQuyDoi'] is num) ? (json['giaBanQuyDoi'] as num).toDouble() : 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maQuyDoi': maQuyDoi,
      'tenDonViQuyDoi': tenDonViQuyDoi,
      'tenDonViGoc': tenDonViGoc,
      'heSoQuyDoi': heSoQuyDoi,
      'giaBanQuyDoi': giaBanQuyDoi,
    };
  }
}

class ProductModel {
  final int maSanPham;
  final String tenSanPham;
  final String donViTinh;
  final int soLuongTon;
  final String? hinhAnh;
  final int maDanhMuc;
  final String tenDanhMuc;
  final double giaBan;
  final String? moTa;
  final bool trangThai;
  final List<VariantModel> bienThes;
  final List<UnitConversionModel> quyDoiDonVis;

  ProductModel({
    required this.maSanPham,
    required this.tenSanPham,
    required this.donViTinh,
    required this.soLuongTon,
    this.hinhAnh,
    required this.maDanhMuc,
    required this.tenDanhMuc,
    required this.giaBan,
    this.moTa,
    this.trangThai = true,
    this.bienThes = const [],
    this.quyDoiDonVis = const [],
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    var rawVariants = json['bienThes'] as List<dynamic>?;
    List<VariantModel> variantsList = rawVariants != null
        ? rawVariants.map((e) => VariantModel.fromJson(e as Map<String, dynamic>)).toList()
        : [];

    var rawConversions = json['quyDoiDonVis'] as List<dynamic>?;
    List<UnitConversionModel> conversionsList = rawConversions != null
        ? rawConversions.map((e) => UnitConversionModel.fromJson(e as Map<String, dynamic>)).toList()
        : [];

    return ProductModel(
      maSanPham: json['maSanPham'] ?? 0,
      tenSanPham: json['tenSanPham'] ?? '',
      donViTinh: json['donViTinh'] ?? 'Đơn vị',
      soLuongTon: json['soLuongTon'] ?? 0,
      hinhAnh: json['hinhAnh'],
      maDanhMuc: json['maDanhMuc'] ?? 0,
      tenDanhMuc: json['tenDanhMuc'] ?? 'Vật liệu xây dựng',
      giaBan: (json['giaBan'] is num) ? (json['giaBan'] as num).toDouble() : 0.0,
      moTa: json['moTa'],
      trangThai: json['trangThai'] ?? true,
      bienThes: variantsList,
      quyDoiDonVis: conversionsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maSanPham': maSanPham,
      'tenSanPham': tenSanPham,
      'donViTinh': donViTinh,
      'soLuongTon': soLuongTon,
      'hinhAnh': hinhAnh,
      'maDanhMuc': maDanhMuc,
      'tenDanhMuc': tenDanhMuc,
      'giaBan': giaBan,
      'moTa': moTa,
      'trangThai': trangThai,
      'bienThes': bienThes.map((e) => e.toJson()).toList(),
      'quyDoiDonVis': quyDoiDonVis.map((e) => e.toJson()).toList(),
    };
  }
}
