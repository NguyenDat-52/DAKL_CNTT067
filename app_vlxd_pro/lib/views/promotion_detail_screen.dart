import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/promotion_model.dart';
import '../services/api_service.dart';
import '../utils/vietnamese_helper.dart';
import '../viewmodels/cart_viewmodel.dart';
import '../viewmodels/product_viewmodel.dart';
import '../widgets/currency_formatter.dart';
import 'product_detail_screen.dart';

class PromotionDetailScreen extends StatefulWidget {
  final PromotionModel promotion;

  const PromotionDetailScreen({
    super.key,
    required this.promotion,
  });

  @override
  State<PromotionDetailScreen> createState() => _PromotionDetailScreenState();
}

class _PromotionDetailScreenState extends State<PromotionDetailScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchKeyword = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productVm = context.watch<ProductViewModel>();
    final allPromoProducts = productVm.getProductsForPromotion(widget.promotion);

    // Apply Vietnamese search (diacritics & non-diacritics)
    final filteredPromoProducts = _searchKeyword.trim().isEmpty
        ? allPromoProducts
        : allPromoProducts.where((p) {
            return VietnameseHelper.matches(p.tenSanPham, _searchKeyword) ||
                   VietnameseHelper.matches(p.tenDanhMuc, _searchKeyword) ||
                   VietnameseHelper.matches(p.donViTinh, _searchKeyword);
          }).toList();

    final dateFormat = DateFormat('dd/MM/yyyy');
    String dateRange = '';
    if (widget.promotion.tuNgay != null && widget.promotion.denNgay != null) {
      dateRange = 'Từ ${dateFormat.format(widget.promotion.tuNgay!)} đến ${dateFormat.format(widget.promotion.denNgay!)}';
    } else if (widget.promotion.denNgay != null) {
      dateRange = 'Hạn dùng đến: ${dateFormat.format(widget.promotion.denNgay!)}';
    } else {
      dateRange = 'Áp dụng cho mọi công trình';
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Ưu Đãi & Khuyến Mãi',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header Promotion Banner Card
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1565C0),
                  const Color(0xFF0D47A1),
                  Colors.deepOrange.shade800,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge discount
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade400,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.local_offer, size: 16, color: Color(0xFFB71C1C)),
                          const SizedBox(width: 4),
                          Text(
                            widget.promotion.discountBadge,
                            style: const TextStyle(
                              color: Color(0xFFB71C1C),
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widget.promotion.loaiKhuyenMai.isNotEmpty
                            ? widget.promotion.loaiKhuyenMai
                            : 'Ưu đãi vật tư',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  widget.promotion.tenKhuyenMai,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 15),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.promotion.conditionText,
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.amberAccent, size: 15),
                    const SizedBox(width: 6),
                    Text(
                      dateRange,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Search in promotion & Item count row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() {
                          _searchKeyword = val;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm vật liệu trong ưu đãi...',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                        prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF1565C0)),
                        suffixIcon: _searchKeyword.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchKeyword = '';
                                  });
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.inventory_2_outlined, size: 18, color: Color(0xFF1565C0)),
                const SizedBox(width: 6),
                Text(
                  'Sản Phẩm Áp Dụng (${filteredPromoProducts.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF333333),
                  ),
                ),
                const Spacer(),
                const Text(
                  'Giá gốc & Giá ưu đãi',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),

          // Products List
          Expanded(
            child: filteredPromoProducts.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.discount_outlined, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            _searchKeyword.isNotEmpty
                                ? 'Không tìm thấy vật tư nào khớp với "$_searchKeyword"'
                                : 'Chưa có sản phẩm nào cho chương trình ưu đãi này.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                          ),
                          if (_searchKeyword.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            TextButton.icon(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchKeyword = '';
                                });
                              },
                              icon: const Icon(Icons.refresh, size: 18),
                              label: const Text('Xóa bộ lọc tìm kiếm'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: filteredPromoProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredPromoProducts[index];
                      final discountedPrice = widget.promotion.getDiscountedPrice(product.giaBan);
                      final savings = product.giaBan - discountedPrice;
                      final imageUrl = ApiService.getImageUrl(product.hinhAnh);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.shade100),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProductDetailScreen(productId: product.maSanPham),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Thumbnail with Discount Badge
                                Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        width: 88,
                                        height: 88,
                                        color: Colors.grey.shade100,
                                        child: imageUrl.isNotEmpty
                                            ? Image.network(
                                                imageUrl,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) =>
                                                    Icon(Icons.inventory_2_outlined, size: 36, color: Colors.grey.shade400),
                                              )
                                            : Icon(Icons.inventory_2_outlined, size: 36, color: Colors.grey.shade400),
                                      ),
                                    ),
                                    Positioned(
                                      top: 0,
                                      left: 0,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFD32F2F),
                                          borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(8),
                                            bottomRight: Radius.circular(8),
                                          ),
                                        ),
                                        child: Text(
                                          widget.promotion.discountTag,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 12),

                                // Product Info & Prices
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.tenSanPham,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          height: 1.25,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade100,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              product.tenDanhMuc,
                                              style: TextStyle(color: Colors.grey.shade700, fontSize: 10),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'ĐVT: ${product.donViTinh}',
                                            style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                                          ),
                                          const Spacer(),
                                          Text(
                                            'Kho: ${product.soLuongTon}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: product.soLuongTon > 10 ? Colors.green.shade700 : Colors.red.shade700,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),

                                      // Prices Row
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Original price strikethrough
                                              Row(
                                                children: [
                                                  Text(
                                                    'Giá gốc: ',
                                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                                  ),
                                                  Text(
                                                    Formatters.formatCurrency(product.giaBan),
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey.shade500,
                                                      decoration: TextDecoration.lineThrough,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              // Discounted price
                                              Text(
                                                Formatters.formatCurrency(discountedPrice),
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFFD32F2F),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const Spacer(),

                                          // Quick add to cart
                                          ElevatedButton.icon(
                                            onPressed: () {
                                              context.read<CartViewModel>().addToCart(product);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('Đã thêm "${product.tenSanPham}" vào giỏ hàng'),
                                                  duration: const Duration(seconds: 1),
                                                  behavior: SnackBarBehavior.floating,
                                                ),
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF1565C0),
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              minimumSize: Size.zero,
                                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                            ),
                                            icon: const Icon(Icons.add_shopping_cart, size: 14),
                                            label: const Text(
                                              'Thêm',
                                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (savings > 0) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'Tiết kiệm ${Formatters.formatCurrency(savings)}/${product.donViTinh}',
                                          style: TextStyle(
                                            color: Colors.orange.shade800,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
