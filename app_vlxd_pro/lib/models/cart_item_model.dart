class CartItemModel {
  final int productId;
  final String productName;
  final String? imageUrl;
  final String unit;
  final double unitPrice;
  int quantity;
  final int? variantId;
  final String? variantName;
  final int? conversionId;
  final double conversionRatio;
  final int availableStock;

  CartItemModel({
    required this.productId,
    required this.productName,
    this.imageUrl,
    required this.unit,
    required this.unitPrice,
    required this.quantity,
    this.variantId,
    this.variantName,
    this.conversionId,
    this.conversionRatio = 1.0,
    required this.availableStock,
  });

  double get subtotal => unitPrice * quantity;

  String get uniqueKey => '${productId}_${variantId ?? 0}_$unit';

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      productId: json['productId'] ?? 0,
      productName: json['productName'] ?? '',
      imageUrl: json['imageUrl'],
      unit: json['unit'] ?? 'Đơn vị',
      unitPrice: (json['unitPrice'] is num) ? (json['unitPrice'] as num).toDouble() : 0.0,
      quantity: json['quantity'] ?? 1,
      variantId: json['variantId'],
      variantName: json['variantName'],
      conversionId: json['conversionId'],
      conversionRatio: (json['conversionRatio'] is num) ? (json['conversionRatio'] as num).toDouble() : 1.0,
      availableStock: json['availableStock'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'imageUrl': imageUrl,
      'unit': unit,
      'unitPrice': unitPrice,
      'quantity': quantity,
      'variantId': variantId,
      'variantName': variantName,
      'conversionId': conversionId,
      'conversionRatio': conversionRatio,
      'availableStock': availableStock,
    };
  }
}
