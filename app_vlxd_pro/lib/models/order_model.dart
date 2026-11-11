class OrderItemModel {
  final int maChiTiet;
  final int maSanPham;
  final String tenSanPham;
  final String? hinhAnh;
  final int? maBienThe;
  final String? tenBienThe;
  final int soLuong;
  final double donGia;
  final String donViTinh;
  final double thanhTien;

  OrderItemModel({
    required this.maChiTiet,
    required this.maSanPham,
    required this.tenSanPham,
    this.hinhAnh,
    this.maBienThe,
    this.tenBienThe,
    required this.soLuong,
    required this.donGia,
    required this.donViTinh,
    required this.thanhTien,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      maChiTiet: json['maChiTiet'] ?? 0,
      maSanPham: json['maSanPham'] ?? 0,
      tenSanPham: json['tenSanPham'] ?? '',
      hinhAnh: json['hinhAnh'],
      maBienThe: json['maBienThe'],
      tenBienThe: json['tenBienThe'],
      soLuong: json['soLuong'] ?? 0,
      donGia: (json['donGia'] is num) ? (json['donGia'] as num).toDouble() : 0.0,
      donViTinh: json['donViTinh'] ?? '',
      thanhTien: (json['thanhTien'] is num) ? (json['thanhTien'] as num).toDouble() : 0.0,
    );
  }
}

class OrderPaymentModel {
  final String phuongThuc;
  final String trangThai;
  final double soTien;
  final DateTime? ngayThanhToan;

  OrderPaymentModel({
    required this.phuongThuc,
    required this.trangThai,
    required this.soTien,
    this.ngayThanhToan,
  });

  factory OrderPaymentModel.fromJson(Map<String, dynamic> json) {
    return OrderPaymentModel(
      phuongThuc: json['phuongThuc'] ?? 'Tiền mặt',
      trangThai: json['trangThai'] ?? 'Chưa thanh toán',
      soTien: (json['soTien'] is num) ? (json['soTien'] as num).toDouble() : 0.0,
      ngayThanhToan: json['ngayThanhToan'] != null ? DateTime.tryParse(json['ngayThanhToan']) : null,
    );
  }
}

class OrderDeliveryModel {
  final String trangThai;
  final DateTime? thoiGianNhanDon;
  final DateTime? thoiGianLayHang;
  final DateTime? thoiGianBatDauGiao;
  final DateTime? thoiGianGiaoThucTe;
  final String? hinhAnhXacNhan;
  final String? tenTaiXe;
  final String? sdtTaiXe;
  final String? loaiXe;
  final String? bienSoXe;

  OrderDeliveryModel({
    required this.trangThai,
    this.thoiGianNhanDon,
    this.thoiGianLayHang,
    this.thoiGianBatDauGiao,
    this.thoiGianGiaoThucTe,
    this.hinhAnhXacNhan,
    this.tenTaiXe,
    this.sdtTaiXe,
    this.loaiXe,
    this.bienSoXe,
  });

  factory OrderDeliveryModel.fromJson(Map<String, dynamic> json) {
    return OrderDeliveryModel(
      trangThai: json['trangThai'] ?? 'Chờ xác nhận',
      thoiGianNhanDon: json['thoiGianNhanDon'] != null ? DateTime.tryParse(json['thoiGianNhanDon']) : null,
      thoiGianLayHang: json['thoiGianLayHang'] != null ? DateTime.tryParse(json['thoiGianLayHang']) : null,
      thoiGianBatDauGiao: json['thoiGianBatDauGiao'] != null ? DateTime.tryParse(json['thoiGianBatDauGiao']) : null,
      thoiGianGiaoThucTe: json['thoiGianGiaoThucTe'] != null ? DateTime.tryParse(json['thoiGianGiaoThucTe']) : null,
      hinhAnhXacNhan: json['hinhAnhXacNhan'],
      tenTaiXe: json['tenTaiXe'],
      sdtTaiXe: json['sdtTaiXe'],
      loaiXe: json['loaiXe'],
      bienSoXe: json['bienSoXe'],
    );
  }
}

class OrderModel {
  final int maDonHang;
  final String orderCode;
  final DateTime? ngayDat;
  final String nguoiNhan;
  final String soDienThoaiNhan;
  final String diaChiGiao;
  final String khuVucGiaoHang;
  final double phiVanChuyen;
  final double tongTien;
  final double soTienDatCoc;
  final String trangThai;
  final String? ghiChu;
  final int soLuongSanPham;
  final String phuongThucThanhToan;
  final String trangThaiThanhToan;
  final String trangThaiGiaoHang;
  final String? loaiXe;
  final List<OrderItemModel> items;
  final OrderPaymentModel? paymentInfo;
  final OrderDeliveryModel? deliveryTracking;

  OrderModel({
    required this.maDonHang,
    required this.orderCode,
    this.ngayDat,
    required this.nguoiNhan,
    required this.soDienThoaiNhan,
    required this.diaChiGiao,
    required this.khuVucGiaoHang,
    required this.phiVanChuyen,
    required this.tongTien,
    required this.soTienDatCoc,
    required this.trangThai,
    this.ghiChu,
    this.soLuongSanPham = 0,
    required this.phuongThucThanhToan,
    required this.trangThaiThanhToan,
    required this.trangThaiGiaoHang,
    this.loaiXe,
    this.items = const [],
    this.paymentInfo,
    this.deliveryTracking,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    var rawItems = json['items'] as List<dynamic>?;
    List<OrderItemModel> itemList = rawItems != null
        ? rawItems.map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>)).toList()
        : [];

    return OrderModel(
      maDonHang: json['maDonHang'] ?? 0,
      orderCode: json['orderCode'] ?? 'DH-${json['maDonHang']}',
      ngayDat: json['ngayDat'] != null ? DateTime.tryParse(json['ngayDat']) : null,
      nguoiNhan: json['nguoiNhan'] ?? '',
      soDienThoaiNhan: json['soDienThoaiNhan'] ?? '',
      diaChiGiao: json['diaChiGiao'] ?? '',
      khuVucGiaoHang: json['khuVucGiaoHang'] ?? 'Nội thành',
      phiVanChuyen: (json['phiVanChuyen'] is num) ? (json['phiVanChuyen'] as num).toDouble() : 0.0,
      tongTien: (json['tongTien'] is num) ? (json['tongTien'] as num).toDouble() : 0.0,
      soTienDatCoc: (json['soTienDatCoc'] is num) ? (json['soTienDatCoc'] as num).toDouble() : 0.0,
      trangThai: json['trangThai'] ?? 'Chờ xác nhận',
      ghiChu: json['ghiChu'],
      soLuongSanPham: json['soLuongSanPham'] ?? itemList.fold(0, (sum, i) => sum + i.soLuong),
      phuongThucThanhToan: json['phuongThucThanhToan'] ?? (json['thanhToan'] != null ? json['thanhToan']['phuongThuc'] ?? 'Tiền mặt' : 'Tiền mặt'),
      trangThaiThanhToan: json['trangThaiThanhToan'] ?? (json['thanhToan'] != null ? json['thanhToan']['trangThai'] ?? 'Chưa thanh toán' : 'Chưa thanh toán'),
      trangThaiGiaoHang: json['trangThaiGiaoHang'] ?? (json['giaoHang'] != null ? json['giaoHang']['trangThai'] ?? 'Chờ xác nhận' : 'Chờ xác nhận'),
      loaiXe: json['loaiXe'] ?? (json['giaoHang'] != null ? json['giaoHang']['loaiXe'] : null),
      items: itemList,
      paymentInfo: json['thanhToan'] != null ? OrderPaymentModel.fromJson(json['thanhToan']) : null,
      deliveryTracking: json['giaoHang'] != null ? OrderDeliveryModel.fromJson(json['giaoHang']) : null,
    );
  }
}
