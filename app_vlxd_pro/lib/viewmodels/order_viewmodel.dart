import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/api_service.dart';
import '../utils/vietnamese_helper.dart';

class OrderViewModel extends ChangeNotifier {
  List<OrderModel> _allOrders = [];
  OrderModel? _currentOrderDetail;
  bool _isLoading = false;
  String? _errorMessage;

  // Filters
  String _selectedTimeFilter = 'all'; // 'all', 'today', 'yesterday', 'this_week', 'this_month', 'custom'
  DateTime? _customFromDate;
  DateTime? _customToDate;
  String _selectedStatus = 'Tất cả'; // 'Tất cả', 'Chờ xác nhận', 'Đang chuẩn bị', 'Đang giao', 'Đã giao', 'Đã hủy'
  String _searchQuery = '';

  List<OrderModel> get orders => _applyFilters();
  List<OrderModel> get allOrders => _allOrders;
  OrderModel? get currentOrderDetail => _currentOrderDetail;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String get selectedTimeFilter => _selectedTimeFilter;
  DateTime? get customFromDate => _customFromDate;
  DateTime? get customToDate => _customToDate;
  String get selectedStatus => _selectedStatus;
  String get searchQuery => _searchQuery;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearSearchQuery() {
    _searchQuery = '';
    notifyListeners();
  }

  Future<void> loadOrders({int? customerId, String? phone}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allOrders = await ApiService.getCustomerOrders(
        customerId: customerId,
        phone: phone,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadOrderDetail(int orderId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentOrderDetail = await ApiService.getOrderDetail(orderId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> submitOrder(Map<String, dynamic> payload) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiService.createOrder(payload);
      _isLoading = false;
      notifyListeners();
      return res;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  void setTimeFilter(String filter, {DateTime? fromDate, DateTime? toDate}) {
    _selectedTimeFilter = filter;
    if (filter == 'custom') {
      _customFromDate = fromDate;
      _customToDate = toDate;
    }
    notifyListeners();
  }

  void setStatusFilter(String status) {
    _selectedStatus = status;
    notifyListeners();
  }

  void resetFilters() {
    _selectedTimeFilter = 'all';
    _customFromDate = null;
    _customToDate = null;
    _selectedStatus = 'Tất cả';
    _searchQuery = '';
    notifyListeners();
  }

  List<OrderModel> _applyFilters() {
    List<OrderModel> list = List.from(_allOrders);
    final now = DateTime.now();

    // 1. Status Filter
    if (_selectedStatus != 'Tất cả') {
      if (_selectedStatus == 'Đã hoàn thành' || _selectedStatus == 'Đã giao') {
        list = list.where((o) =>
          o.trangThai == 'Đã giao' ||
          o.trangThai == 'Đã đối soát xong' ||
          o.trangThai == 'Hoàn tất'
        ).toList();
      } else {
        list = list.where((o) => o.trangThai.toLowerCase().contains(_selectedStatus.toLowerCase())).toList();
      }
    }

    // 2. Time Filter
    if (_selectedTimeFilter == 'today') {
      final todayStart = DateTime(now.year, now.month, now.day);
      list = list.where((o) => o.ngayDat != null && o.ngayDat!.isAfter(todayStart)).toList();
    } else if (_selectedTimeFilter == 'yesterday') {
      final yStart = DateTime(now.year, now.month, now.day - 1);
      final yEnd = DateTime(now.year, now.month, now.day);
      list = list.where((o) => o.ngayDat != null && o.ngayDat!.isAfter(yStart) && o.ngayDat!.isBefore(yEnd)).toList();
    } else if (_selectedTimeFilter == 'this_week') {
      // Monday of current week
      final daysFromMonday = (now.weekday - 1);
      final monday = DateTime(now.year, now.month, now.day - daysFromMonday);
      list = list.where((o) => o.ngayDat != null && o.ngayDat!.isAfter(monday)).toList();
    } else if (_selectedTimeFilter == 'this_month') {
      final firstDay = DateTime(now.year, now.month, 1);
      list = list.where((o) => o.ngayDat != null && o.ngayDat!.isAfter(firstDay)).toList();
    } else if (_selectedTimeFilter == 'custom') {
      if (_customFromDate != null) {
        final start = DateTime(_customFromDate!.year, _customFromDate!.month, _customFromDate!.day);
        list = list.where((o) => o.ngayDat != null && o.ngayDat!.isAfter(start.subtract(const Duration(seconds: 1)))).toList();
      }
      if (_customToDate != null) {
        final end = DateTime(_customToDate!.year, _customToDate!.month, _customToDate!.day, 23, 59, 59);
        list = list.where((o) => o.ngayDat != null && o.ngayDat!.isBefore(end.add(const Duration(seconds: 1)))).toList();
      }
    }

    // 3. Search Query Filter (Mã đơn hàng hoặc Tên sản phẩm)
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim();
      final numDigits = q.replaceAll(RegExp(r'[^0-9]'), '');

      list = list.where((o) {
        // Match order code (e.g. "DH-12", "#12", "12")
        if (o.orderCode.toLowerCase().contains(q.toLowerCase())) return true;
        if (numDigits.isNotEmpty && o.maDonHang.toString() == numDigits) return true;

        // Match product name in items using Vietnamese unaccented matching
        if (o.items.any((item) => VietnameseHelper.matches(item.tenSanPham, q))) {
          return true;
        }

        // Match receiver name or phone
        if (VietnameseHelper.matches(o.nguoiNhan, q)) return true;
        if (o.soDienThoaiNhan.contains(q)) return true;

        return false;
      }).toList();
    }

    return list;
  }
}
