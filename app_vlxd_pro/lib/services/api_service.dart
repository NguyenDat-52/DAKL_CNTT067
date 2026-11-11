import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../models/order_model.dart';
import '../models/promotion_model.dart';
import '../models/review_model.dart';

class ApiService {
  static const String baseUrl = 'https://henrynguyen2005-001-site1.ctempurl.com/api';
  static const String liveServerHost = 'https://henrynguyen2005-001-site1.ctempurl.com';
  static const String cdnHost = 'https://nguyendat-52.github.io/VLXD-PRO';

  static final Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Chuẩn hóa đường dẫn hình ảnh vật liệu xây dựng
  static String getImageUrl(String? rawPath) {
    if (rawPath == null || rawPath.trim().isEmpty) {
      return '';
    }

    String path = rawPath.trim();
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }

    // Clean relative path ./Content/... -> Content/...
    if (path.startsWith('./')) {
      path = path.substring(2);
    } else if (path.startsWith('/')) {
      path = path.substring(1);
    }

    // Uploads from driver deliveries reside on live IIS
    if (path.toLowerCase().startsWith('uploads/')) {
      return '$liveServerHost/$path';
    }

    // Product images reside on high-speed CDN GitHub Pages
    return '$cdnHost/$path';
  }

  // --- 1. AUTHENTICATION & PROFILE ---
  static Future<UserModel> login(String username, String password) async {
    final url = Uri.parse('$baseUrl/auth/login');
    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          'TenDangNhap': username.trim(),
          'MatKhau': password.trim(),
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data['success'] == true && data['user'] != null) {
          return UserModel.fromJson(data['user'], token: data['token']);
        }
        throw Exception(data['message'] ?? 'Đăng nhập không thành công.');
      } else if (response.statusCode == 401) {
        throw Exception('Tên đăng nhập hoặc mật khẩu không chính xác.');
      } else {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(data['Message'] ?? data['message'] ?? 'Lỗi đăng nhập: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  static Future<bool> register({
    required String username,
    required String password,
    required String fullName,
    required String phone,
    String? email,
    String? address,
  }) async {
    final url = Uri.parse('$baseUrl/auth/register');
    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          'TenDangNhap': username.trim(),
          'MatKhau': password.trim(),
          'HoTen': fullName.trim(),
          'SoDienThoai': phone.trim(),
          'Email': email?.trim() ?? '',
          'DiaChi': address?.trim() ?? '',
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return true;
      } else {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(data['Message'] ?? data['message'] ?? 'Đăng ký thất bại.');
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  static Future<Map<String, dynamic>> getProfile(int customerId) async {
    final url = Uri.parse('$baseUrl/auth/profile?customerId=$customerId');
    try {
      final response = await http.get(url, headers: _headers).timeout(const Duration(seconds: 12));
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      } else {
        throw Exception('Không tìm thấy thông tin hồ sơ.');
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  static Future<UserModel> updateProfile({
    required int customerId,
    required String hoTen,
    required String soDienThoai,
    required String diaChi,
    required String email,
  }) async {
    final url = Uri.parse('$baseUrl/auth/profile');
    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          'CustomerId': customerId,
          'HoTen': hoTen.trim(),
          'SoDienThoai': soDienThoai.trim(),
          'DiaChi': diaChi.trim(),
          'Email': email.trim(),
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data['user'] != null) {
          return UserModel.fromJson(data['user']);
        }
        throw Exception(data['message'] ?? 'Cập nhật thành công.');
      } else {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(data['Message'] ?? data['message'] ?? 'Lỗi cập nhật hồ sơ');
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // --- 2. CATEGORIES & PRODUCTS ---
  static Future<List<CategoryModel>> getCategories() async {
    final url = Uri.parse('$baseUrl/categories');
    try {
      final response = await http.get(url, headers: _headers).timeout(const Duration(seconds: 12));
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(utf8.decode(response.bodyBytes));
        return list.map((e) => CategoryModel.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<List<ProductModel>> getProducts({String? search, int? categoryId}) async {
    var queryParams = <String, String>{};
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }
    if (categoryId != null && categoryId > 0) {
      queryParams['categoryId'] = categoryId.toString();
    }

    final uri = Uri.parse('$baseUrl/products').replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
    try {
      final response = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(utf8.decode(response.bodyBytes));
        return list.map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Không thể tải danh sách sản phẩm (${response.statusCode})');
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  static Future<ProductModel> getProductDetail(int id) async {
    final url = Uri.parse('$baseUrl/products/$id');
    try {
      final response = await http.get(url, headers: _headers).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return ProductModel.fromJson(data);
      } else {
        throw Exception('Không tìm thấy thông tin sản phẩm #$id');
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // --- 3. PROMOTIONS & DISCOUNTS ---
  static Future<List<PromotionModel>> getPromotions() async {
    final url = Uri.parse('$baseUrl/promotions');
    try {
      final response = await http.get(url, headers: _headers).timeout(const Duration(seconds: 12));
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(utf8.decode(response.bodyBytes));
        return list.map((e) => PromotionModel.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<List<PromotionModel>> getProductPromotions(int productId) async {
    final url = Uri.parse('$baseUrl/promotions/product/$productId');
    try {
      final response = await http.get(url, headers: _headers).timeout(const Duration(seconds: 12));
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(utf8.decode(response.bodyBytes));
        return list.map((e) => PromotionModel.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // --- 4. PRODUCT REVIEWS & RATINGS ---
  static Future<ReviewSummary> getProductReviews(int productId) async {
    final url = Uri.parse('$baseUrl/reviews/product/$productId');
    try {
      final response = await http.get(url, headers: _headers).timeout(const Duration(seconds: 12));
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return ReviewSummary.fromJson(data);
      }
      return ReviewSummary(productId: productId, totalReviews: 0, averageRating: 5.0, reviews: []);
    } catch (_) {
      return ReviewSummary(productId: productId, totalReviews: 0, averageRating: 5.0, reviews: []);
    }
  }

  static Future<CanReviewResult> canReviewProduct(int productId, int customerId) async {
    final url = Uri.parse('$baseUrl/reviews/can-review?productId=$productId&customerId=$customerId');
    try {
      final response = await http.get(url, headers: _headers).timeout(const Duration(seconds: 12));
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return CanReviewResult.fromJson(data);
      }
      return CanReviewResult(
        canReview: false,
        message: 'Không thể kiểm tra điều kiện đánh giá.',
        eligibleOrders: [],
        unreviewedOrders: [],
      );
    } catch (e) {
      return CanReviewResult(
        canReview: false,
        message: 'Lỗi kiểm tra quyền đánh giá.',
        eligibleOrders: [],
        unreviewedOrders: [],
      );
    }
  }

  static Future<bool> submitReview({
    required int customerId,
    required int productId,
    int? orderId,
    required int soSao,
    required String noiDung,
  }) async {
    final url = Uri.parse('$baseUrl/reviews');
    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          'CustomerId': customerId,
          'ProductId': productId,
          'OrderId': orderId,
          'SoSao': soSao,
          'NoiDung': noiDung.trim(),
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return true;
      } else {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(data['Message'] ?? data['message'] ?? 'Lỗi khi gửi đánh giá.');
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // --- 5. ORDERS & TRACKING ---
  static Future<Map<String, dynamic>> createOrder(Map<String, dynamic> orderPayload) async {
    final url = Uri.parse('$baseUrl/orders');
    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode(orderPayload),
      ).timeout(const Duration(seconds: 25));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data as Map<String, dynamic>;
      } else {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(data['Message'] ?? data['message'] ?? 'Lỗi khi tạo đơn hàng: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  static Future<List<OrderModel>> getCustomerOrders({
    int? customerId,
    String? phone,
    String? status,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    var queryParams = <String, String>{};
    if (customerId != null && customerId > 0) {
      queryParams['customerId'] = customerId.toString();
    } else if (phone != null && phone.trim().isNotEmpty) {
      queryParams['phone'] = phone.trim();
    } else {
      return [];
    }

    if (status != null && status.isNotEmpty && status != 'Tất cả') {
      queryParams['status'] = status;
    }
    if (fromDate != null) {
      queryParams['fromDate'] = fromDate.toIso8601String();
    }
    if (toDate != null) {
      queryParams['toDate'] = toDate.toIso8601String();
    }

    final uri = Uri.parse('$baseUrl/orders').replace(queryParameters: queryParams);
    try {
      final response = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(utf8.decode(response.bodyBytes));
        return list.map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<OrderModel> getOrderDetail(int orderId) async {
    final url = Uri.parse('$baseUrl/orders/$orderId');
    try {
      final response = await http.get(url, headers: _headers).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return OrderModel.fromJson(data);
      } else {
        throw Exception('Không tìm thấy đơn hàng #$orderId');
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // --- 6. FORGOT PASSWORD & OTP ---
  static Future<Map<String, dynamic>> requestForgotPassword(String email) async {
    final url = Uri.parse('$baseUrl/auth/forgot-password');
    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({'Email': email.trim()}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      } else {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return {
          'success': false,
          'message': data['Message'] ?? data['message'] ?? 'Lỗi gửi OTP (${response.statusCode})',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': e.toString().replaceAll('Exception: ', ''),
      };
    }
  }

  static Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    final url = Uri.parse('$baseUrl/auth/verify-otp');
    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({'Email': email.trim(), 'Otp': otp.trim()}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      } else {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return {
          'success': false,
          'message': data['Message'] ?? data['message'] ?? 'Mã OTP không hợp lệ.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': e.toString().replaceAll('Exception: ', ''),
      };
    }
  }

  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final url = Uri.parse('$baseUrl/auth/reset-password');
    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          'Email': email.trim(),
          'Otp': otp.trim(),
          'MatKhauMoi': newPassword.trim(),
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      } else {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return {
          'success': false,
          'message': data['Message'] ?? data['message'] ?? 'Đặt lại mật khẩu thất bại.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': e.toString().replaceAll('Exception: ', ''),
      };
    }
  }

  // --- 7. QR PAYMENT & BANK CONFIG ---
  static Future<Map<String, dynamic>> getPaymentConfig() async {
    final url = Uri.parse('$baseUrl/orders/payment-config');
    try {
      final response = await http.get(url, headers: _headers).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      }
    } catch (_) {}

    // Fallback default configured from VLXD-PRO web system
    return {
      'tenNganHang': 'MBBank (Ngân Hàng Quân Đội)',
      'soTaiKhoan': '0908123456',
      'chuTaiKhoan': 'CONG TY TNHH VLXD PRO',
      'bankCode': 'MB',
      'cuPhapNoiDung': 'VLXD DH[MADONHANG]',
      'ghiChuHuongDan': 'Quý khách vui lòng chuyển đúng nội dung để hệ thống tự động xác nhận đơn hàng.',
    };
  }

  static Future<Map<String, dynamic>> getOrderPaymentStatus(int orderId) async {
    final url = Uri.parse('$baseUrl/orders/$orderId/payment-status');
    try {
      final response = await http.get(url, headers: _headers).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      }
    } catch (_) {}

    // Check through getOrderDetail as fallback
    try {
      final detail = await getOrderDetail(orderId);
      final isPaid = detail.trangThaiThanhToan == 'Đã thanh toán' || detail.trangThai == 'Đã giao hàng';
      return {
        'maDonHang': detail.maDonHang,
        'tongTien': detail.tongTien,
        'phuongThuc': detail.phuongThucThanhToan,
        'trangThaiThanhToan': detail.trangThaiThanhToan,
        'daThanhToan': isPaid,
      };
    } catch (_) {
      return {
        'maDonHang': orderId,
        'daThanhToan': false,
        'trangThaiThanhToan': 'Chờ thanh toán',
      };
    }
  }

  static Future<bool> confirmOrderPaid(int orderId) async {
    final url = Uri.parse('$baseUrl/orders/$orderId/confirm-paid');
    try {
      final response = await http.post(url, headers: _headers).timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (_) {
      return true; // Optimistic confirmation
    }
  }
}
