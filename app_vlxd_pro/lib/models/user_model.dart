class UserModel {
  final int maTaiKhoan;
  final String tenDangNhap;
  final String? email;
  final String vaiTro;
  final String hoTen;
  final String soDienThoai;
  final String diaChi;
  final int? maKhachHang;
  final int? maNhanVien;
  final String? token;

  UserModel({
    required this.maTaiKhoan,
    required this.tenDangNhap,
    this.email,
    required this.vaiTro,
    required this.hoTen,
    required this.soDienThoai,
    required this.diaChi,
    this.maKhachHang,
    this.maNhanVien,
    this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, {String? token}) {
    return UserModel(
      maTaiKhoan: json['maTaiKhoan'] ?? 0,
      tenDangNhap: json['tenDangNhap'] ?? '',
      email: json['email'],
      vaiTro: json['vaiTro'] ?? 'CUSTOMER',
      hoTen: json['hoTen'] ?? json['tenDangNhap'] ?? '',
      soDienThoai: json['soDienThoai'] ?? '',
      diaChi: json['diaChi'] ?? '',
      maKhachHang: json['maKhachHang'],
      maNhanVien: json['maNhanVien'],
      token: token ?? json['token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maTaiKhoan': maTaiKhoan,
      'tenDangNhap': tenDangNhap,
      'email': email,
      'vaiTro': vaiTro,
      'hoTen': hoTen,
      'soDienThoai': soDienThoai,
      'diaChi': diaChi,
      'maKhachHang': maKhachHang,
      'maNhanVien': maNhanVien,
      'token': token,
    };
  }

  UserModel copyWith({
    int? maTaiKhoan,
    String? tenDangNhap,
    String? email,
    String? vaiTro,
    String? hoTen,
    String? soDienThoai,
    String? diaChi,
    int? maKhachHang,
    int? maNhanVien,
    String? token,
  }) {
    return UserModel(
      maTaiKhoan: maTaiKhoan ?? this.maTaiKhoan,
      tenDangNhap: tenDangNhap ?? this.tenDangNhap,
      email: email ?? this.email,
      vaiTro: vaiTro ?? this.vaiTro,
      hoTen: hoTen ?? this.hoTen,
      soDienThoai: soDienThoai ?? this.soDienThoai,
      diaChi: diaChi ?? this.diaChi,
      maKhachHang: maKhachHang ?? this.maKhachHang,
      maNhanVien: maNhanVien ?? this.maNhanVien,
      token: token ?? this.token,
    );
  }
}
