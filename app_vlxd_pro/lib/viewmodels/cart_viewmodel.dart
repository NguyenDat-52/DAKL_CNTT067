import 'package:flutter/material.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';
import '../models/promotion_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class CartViewModel extends ChangeNotifier {
  List<CartItemModel> _items = [];
  String _selectedArea = 'Nội thành'; // 'Nội thành' hoặc 'Ngoại thành'
  bool _isDepositSelected = false;

  List<PromotionModel> _availablePromotions = [];
  PromotionModel? _appliedPromotion;
  String _promoCodeInput = '';

  List<CartItemModel> get items => _items;
  int get totalItemCount => _items.fold(0, (sum, i) => sum + i.quantity);
  String get selectedArea => _selectedArea;
  bool get isDepositSelected => _isDepositSelected;
  List<PromotionModel> get availablePromotions => _availablePromotions;
  PromotionModel? get appliedPromotion => _appliedPromotion;
  String get promoCodeInput => _promoCodeInput;

  CartViewModel() {
    loadSavedCart();
    fetchPromotions();
  }

  Future<void> loadSavedCart() async {
    _items = await StorageService.getCart();
    notifyListeners();
  }

  Future<void> fetchPromotions() async {
    try {
      _availablePromotions = await ApiService.getPromotions();
      _autoEvaluateBestPromotions();
      notifyListeners();
    } catch (_) {}
  }

  /// Original subtotal without any discounts
  double get rawSubtotal => _items.fold(0.0, (sum, i) => sum + (i.unitPrice * i.quantity));

  /// Calculates item-level discount for a specific cart item
  double calculateItemDiscount(CartItemModel item) {
    if (_availablePromotions.isEmpty) return 0.0;

    // Filter promotions targeting this product
    var matching = _availablePromotions.where((km) => km.productIds.contains(item.productId)).toList();
    if (matching.isEmpty) return 0.0;

    double maxDiscount = 0.0;
    for (var km in matching) {
      if (km.isQuantityDiscount && item.quantity < km.soLuongToiThieu) {
        continue;
      }
      double d = km.calculateDiscount(item.unitPrice, item.quantity);
      if (d > maxDiscount) {
        maxDiscount = d;
      }
    }
    return maxDiscount;
  }

  /// Total discount on individual items
  double get itemDiscountsTotal {
    double sum = 0.0;
    for (var item in _items) {
      sum += calculateItemDiscount(item);
    }
    return sum;
  }

  /// Order-level threshold discount or applied coupon discount
  double get orderLevelDiscount {
    double netSubtotal = rawSubtotal - itemDiscountsTotal;
    if (netSubtotal <= 0) return 0.0;

    // 1. If user explicitly applied a coupon/promo
    if (_appliedPromotion != null) {
      if (_appliedPromotion!.soLuongToiThieu > 1 && netSubtotal < _appliedPromotion!.soLuongToiThieu) {
        return 0.0;
      }
      if (_appliedPromotion!.phanTramGiam > 0) {
        return (netSubtotal * _appliedPromotion!.phanTramGiam / 100.0);
      } else if (_appliedPromotion!.soTienGiam > 0) {
        return _appliedPromotion!.soTienGiam;
      }
    }

    // 2. Otherwise auto-apply order-level threshold promo if eligible
    var orderPromos = _availablePromotions
        .where((km) => km.isOrderTotalDiscount || km.loaiKhuyenMai == 'Định mức tổng tiền' || km.loaiKhuyenMai == 'ORDER_TOTAL')
        .where((km) => netSubtotal >= km.soLuongToiThieu)
        .toList();

    if (orderPromos.isNotEmpty) {
      orderPromos.sort((a, b) => b.soLuongToiThieu.compareTo(a.soLuongToiThieu));
      var best = orderPromos.first;
      if (best.phanTramGiam > 0) {
        return (netSubtotal * best.phanTramGiam / 100.0);
      } else if (best.soTienGiam > 0) {
        return best.soTienGiam;
      }
    }

    return 0.0;
  }

  /// Total savings across both item and order discounts
  double get totalDiscount => itemDiscountsTotal + orderLevelDiscount;

  /// Effective subtotal after all discounts
  double get subtotal => (rawSubtotal - totalDiscount).clamp(0.0, double.infinity);

  /// Shipping fee calculation based on delivery area and net subtotal
  double get shippingFee {
    if (_items.isEmpty) return 0.0;
    if (_selectedArea == 'Nội thành') {
      return subtotal >= 10000000 ? 0.0 : 150000.0;
    } else {
      return subtotal >= 15000000 ? 150000.0 : 350000.0;
    }
  }

  /// Grand total rounded to thousands according to COD commercial standard
  double get grandTotal {
    if (_items.isEmpty) return 0.0;
    double rawTotal = subtotal + shippingFee;
    return roundToThousand(rawTotal);
  }

  bool get canDeposit => grandTotal >= 5000000;

  double get depositAmount {
    if (canDeposit && _isDepositSelected) {
      return roundToThousand(grandTotal * 0.3);
    }
    return grandTotal;
  }

  static double roundToThousand(double val) {
    return ((val / 1000.0).round() * 1000).toDouble();
  }

  void setArea(String area) {
    _selectedArea = area;
    notifyListeners();
  }

  void setDepositSelected(bool selected) {
    _isDepositSelected = selected;
    notifyListeners();
  }

  void setPromoCodeInput(String code) {
    _promoCodeInput = code;
    notifyListeners();
  }

  bool applyPromotion(PromotionModel promo) {
    _appliedPromotion = promo;
    notifyListeners();
    return true;
  }

  void removePromotion() {
    _appliedPromotion = null;
    notifyListeners();
  }

  bool applyPromoCode(String code) {
    String cleanCode = code.trim().toLowerCase();
    if (cleanCode.isEmpty) return false;

    // Search by title or promo id
    var found = _availablePromotions.firstWhere(
      (p) => p.tenKhuyenMai.toLowerCase().contains(cleanCode) ||
             'km${p.maKhuyenMai}' == cleanCode ||
             'km-${p.maKhuyenMai}' == cleanCode,
      orElse: () => PromotionModel(
        maKhuyenMai: 0,
        tenKhuyenMai: '',
        phanTramGiam: 0,
        soTienGiam: 0,
        loaiKhuyenMai: '',
        soLuongToiThieu: 1,
        productIds: [],
      ),
    );

    if (found.maKhuyenMai > 0) {
      _appliedPromotion = found;
      notifyListeners();
      return true;
    }
    return false;
  }

  void _autoEvaluateBestPromotions() {
    // If no manual promo is selected, order-level discount is calculated automatically
    notifyListeners();
  }

  void addToCart(ProductModel product, {int quantity = 1, VariantModel? variant, UnitConversionModel? conversion}) {
    String unit = product.donViTinh;
    double price = product.giaBan;
    int? varId;
    String? varName;
    int? convId;
    double convRatio = 1.0;

    if (variant != null) {
      varId = variant.maBienThe;
      varName = variant.tenBienThe;
      price = variant.giaBan;
    } else if (conversion != null) {
      convId = conversion.maQuyDoi;
      unit = conversion.tenDonViQuyDoi;
      price = conversion.giaBanQuyDoi;
      convRatio = conversion.heSoQuyDoi;
    }

    final key = '${product.maSanPham}_${varId ?? 0}_$unit';
    final existingIndex = _items.indexWhere((i) => i.uniqueKey == key);

    if (existingIndex >= 0) {
      _items[existingIndex].quantity += quantity;
    } else {
      _items.add(CartItemModel(
        productId: product.maSanPham,
        productName: product.tenSanPham,
        imageUrl: product.hinhAnh,
        unit: unit,
        unitPrice: price,
        quantity: quantity,
        variantId: varId,
        variantName: varName,
        conversionId: convId,
        conversionRatio: convRatio,
        availableStock: product.soLuongTon,
      ));
    }

    _syncStorage();
    notifyListeners();
  }

  void updateQuantity(int index, int newQuantity) {
    if (index >= 0 && index < _items.length) {
      if (newQuantity <= 0) {
        _items.removeAt(index);
      } else {
        _items[index].quantity = newQuantity;
      }
      _syncStorage();
      notifyListeners();
    }
  }

  void removeItem(int index) {
    if (index >= 0 && index < _items.length) {
      _items.removeAt(index);
      _syncStorage();
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    _appliedPromotion = null;
    _syncStorage();
    notifyListeners();
  }

  void _syncStorage() {
    StorageService.saveCart(_items);
  }
}
