import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/promotion_model.dart';
import '../viewmodels/product_viewmodel.dart';
import 'promotion_detail_screen.dart';

class PromotionsScreen extends StatefulWidget {
  const PromotionsScreen({super.key});

  @override
  State<PromotionsScreen> createState() => _PromotionsScreenState();
}

class _PromotionsScreenState extends State<PromotionsScreen> {
  String _selectedFilter = 'all'; // 'all', 'percent', 'amount', 'quantity'

  @override
  Widget build(BuildContext context) {
    final productVm = context.watch<ProductViewModel>();
    final allPromotions = productVm.activePromotions;

    List<PromotionModel> filteredPromos = allPromotions;
    if (_selectedFilter == 'percent') {
      filteredPromos = allPromotions.where((p) => p.phanTramGiam > 0).toList();
    } else if (_selectedFilter == 'amount') {
      filteredPromos = allPromotions.where((p) => p.soTienGiam > 0).toList();
    } else if (_selectedFilter == 'quantity') {
      filteredPromos = allPromotions.where((p) => p.isQuantityDiscount || p.soLuongToiThieu > 1).toList();
    }

    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Chương Trình Khuyến Mãi',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () => productVm.refresh(),
        color: const Color(0xFF1565C0),
        child: Column(
          children: [
            // Top Highlights Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF1565C0), Colors.blue.shade800],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.campaign, color: Colors.amberAccent, size: 28),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ưu Đãi Đặc Biệt Cho Công Trình',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Mua số lượng lớn hoặc theo đợt nhận ngay chiết khấu trực tiếp',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Filter Tabs Row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  _buildFilterChip('all', 'Tất cả (${allPromotions.length})'),
                  const SizedBox(width: 8),
                  _buildFilterChip('percent', 'Giảm theo %'),
                  const SizedBox(width: 8),
                  _buildFilterChip('amount', 'Giảm tiền mặt'),
                  const SizedBox(width: 8),
                  _buildFilterChip('quantity', 'Mua số lượng lớn'),
                ],
              ),
            ),

            // Promotions List
            Expanded(
              child: productVm.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredPromos.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.local_offer_outlined, size: 64, color: Colors.grey.shade400),
                                const SizedBox(height: 16),
                                Text(
                                  'Hiện không có chương trình ưu đãi nào phù hợp.',
                                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          itemCount: filteredPromos.length,
                          itemBuilder: (context, index) {
                            final km = filteredPromos[index];
                            final promoProducts = productVm.getProductsForPromotion(km);

                            String expiryText = 'Áp dụng lâu dài';
                            if (km.denNgay != null) {
                              expiryText = 'Hạn đến: ${dateFormat.format(km.denNgay!)}';
                            }

                            return Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.orange.shade100, width: 1.2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PromotionDetailScreen(promotion: km),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(14),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Header Row: Badge & Type
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFD32F2F),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              km.discountBadge,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.orange.shade50,
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: Colors.orange.shade200),
                                            ),
                                            child: Text(
                                              km.loaiKhuyenMai.isNotEmpty ? km.loaiKhuyenMai : 'Ưu đãi',
                                              style: TextStyle(
                                                color: Colors.orange.shade900,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            expiryText,
                                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),

                                      // Promotion Name
                                      Text(
                                        km.tenKhuyenMai,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF222222),
                                          height: 1.3,
                                        ),
                                      ),
                                      const SizedBox(height: 6),

                                      // Condition
                                      Row(
                                        children: [
                                          const Icon(Icons.info_outline, size: 14, color: Colors.blueGrey),
                                          const SizedBox(width: 5),
                                          Expanded(
                                            child: Text(
                                              km.conditionText,
                                              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 20),

                                      // Bottom Row: Applied products preview and CTA
                                      Row(
                                        children: [
                                          const Icon(Icons.check_box_outlined, size: 16, color: Colors.green),
                                          const SizedBox(width: 5),
                                          Expanded(
                                            child: Text(
                                              km.productIds.isEmpty
                                                  ? 'Áp dụng cho toàn bộ vật tư'
                                                  : 'Áp dụng cho ${promoProducts.length} vật tư cụ thể',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.grey.shade800,
                                              ),
                                            ),
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: const [
                                              Text(
                                                'Xem vật phẩm',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF1565C0),
                                                ),
                                              ),
                                              SizedBox(width: 2),
                                              Icon(Icons.arrow_forward_ios, size: 12, color: Color(0xFF1565C0)),
                                            ],
                                          ),
                                        ],
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
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedFilter == key;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : Colors.grey.shade800,
        ),
      ),
      selected: isSelected,
      selectedColor: const Color(0xFF1565C0),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? const Color(0xFF1565C0) : Colors.grey.shade300,
        ),
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedFilter = key;
          });
        }
      },
    );
  }
}
