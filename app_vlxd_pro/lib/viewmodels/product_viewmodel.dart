import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';
import '../models/promotion_model.dart';
import '../models/review_model.dart';
import '../services/api_service.dart';
import '../utils/vietnamese_helper.dart';

class ProductViewModel extends ChangeNotifier {
  List<ProductModel> _allProducts = [];
  List<ProductModel> _filteredProducts = [];
  List<CategoryModel> _categories = [];
  List<PromotionModel> _activePromotions = [];

  // Reviews cache by productId
  final Map<int, ReviewSummary> _reviewsMap = {};
  final Map<int, CanReviewResult> _canReviewMap = {};

  bool _isLoading = false;
  String? _errorMessage;
  int? _selectedCategoryId;
  String _searchQuery = '';
  String _sortBy = 'default'; // 'default', 'price_asc', 'price_desc'

  List<ProductModel> get products => _filteredProducts;
  List<ProductModel> get allProducts => _allProducts;
  List<CategoryModel> get categories => _categories;
  List<PromotionModel> get activePromotions => _activePromotions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int? get selectedCategoryId => _selectedCategoryId;
  String get searchQuery => _searchQuery;
  String get sortBy => _sortBy;

  ReviewSummary? getReviewsForProduct(int productId) => _reviewsMap[productId];
  CanReviewResult? getCanReviewForProduct(int productId) => _canReviewMap[productId];

  ProductViewModel() {
    initData();
  }

  Future<void> initData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        ApiService.getCategories(),
        ApiService.getProducts(),
        ApiService.getPromotions(),
      ]);

      _categories = results[0] as List<CategoryModel>;
      _allProducts = results[1] as List<ProductModel>;
      _activePromotions = results[2] as List<PromotionModel>;
      _applyFilter();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await initData();
  }

  void selectCategory(int? categoryId) {
    if (_selectedCategoryId == categoryId) {
      _selectedCategoryId = null; // Toggle unselect
    } else {
      _selectedCategoryId = categoryId;
    }
    _applyFilter();
    notifyListeners();
  }

  void search(String query) {
    _searchQuery = query;
    _applyFilter();
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _applyFilter();
    notifyListeners();
  }

  void setSortBy(String sort) {
    _sortBy = sort;
    _applyFilter();
    notifyListeners();
  }

  List<PromotionModel> getPromotionsForProduct(int productId) {
    return _activePromotions.where((km) => km.productIds.contains(productId)).toList();
  }

  /// Returns the specific list of products eligible for a given promotion
  List<ProductModel> getProductsForPromotion(PromotionModel promotion) {
    if (promotion.productIds.isEmpty) {
      // Empty productIds means store-wide campaign applicable to all materials
      return List.unmodifiable(_allProducts);
    }
    return _allProducts.where((p) => promotion.productIds.contains(p.maSanPham)).toList();
  }

  Future<void> loadReviews(int productId) async {
    try {
      final summary = await ApiService.getProductReviews(productId);
      _reviewsMap[productId] = summary;
      notifyListeners();
    } catch (_) {}
  }

  Future<CanReviewResult> checkCanReview(int productId, int customerId) async {
    try {
      final result = await ApiService.canReviewProduct(productId, customerId);
      _canReviewMap[productId] = result;
      notifyListeners();
      return result;
    } catch (e) {
      return CanReviewResult(
        canReview: false,
        message: 'Lỗi kiểm tra quyền đánh giá.',
        eligibleOrders: [],
        unreviewedOrders: [],
      );
    }
  }

  Future<bool> submitReview({
    required int customerId,
    required int productId,
    int? orderId,
    required int soSao,
    required String noiDung,
  }) async {
    try {
      final success = await ApiService.submitReview(
        customerId: customerId,
        productId: productId,
        orderId: orderId,
        soSao: soSao,
        noiDung: noiDung,
      );
      if (success) {
        // Refresh reviews and canReview state
        await loadReviews(productId);
        await checkCanReview(productId, customerId);
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  void _applyFilter() {
    List<ProductModel> temp = List.from(_allProducts);

    if (_selectedCategoryId != null && _selectedCategoryId! > 0) {
      temp = temp.where((p) => p.maDanhMuc == _selectedCategoryId).toList();
    }

    if (_searchQuery.trim().isNotEmpty) {
      temp = temp.where((p) {
        return VietnameseHelper.matches(p.tenSanPham, _searchQuery) ||
               VietnameseHelper.matches(p.tenDanhMuc, _searchQuery) ||
               (p.moTa != null && VietnameseHelper.matches(p.moTa!, _searchQuery)) ||
               VietnameseHelper.matches(p.donViTinh, _searchQuery);
      }).toList();
    }

    if (_sortBy == 'price_asc') {
      temp.sort((a, b) => a.giaBan.compareTo(b.giaBan));
    } else if (_sortBy == 'price_desc') {
      temp.sort((a, b) => b.giaBan.compareTo(a.giaBan));
    }

    _filteredProducts = temp;
  }
}
