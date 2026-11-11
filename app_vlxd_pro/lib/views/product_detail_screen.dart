import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/cart_viewmodel.dart';
import '../viewmodels/product_viewmodel.dart';
import '../widgets/currency_formatter.dart';
import 'cart_screen.dart';
import 'checkout_screen.dart';
import 'login_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  ProductModel? _product;
  bool _isLoading = true;
  String? _error;

  int _quantity = 1;
  VariantModel? _selectedVariant;
  UnitConversionModel? _selectedConversion;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final p = await ApiService.getProductDetail(widget.productId);
      if (mounted) {
        setState(() {
          _product = p;
          _isLoading = false;
          if (p.bienThes.isNotEmpty) {
            _selectedVariant = p.bienThes.first;
          }
        });

        // Load reviews and check review permission
        final productVm = context.read<ProductViewModel>();
        productVm.loadReviews(widget.productId);

        final authVm = context.read<AuthViewModel>();
        if (authVm.isLoggedIn && authVm.currentUser?.maKhachHang != null) {
          productVm.checkCanReview(widget.productId, authVm.currentUser!.maKhachHang!);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  double get _currentPrice {
    if (_selectedVariant != null) {
      return _selectedVariant!.giaBan;
    }
    if (_selectedConversion != null) {
      return _selectedConversion!.giaBanQuyDoi;
    }
    return _product?.giaBan ?? 0.0;
  }

  String get _currentUnit {
    if (_selectedConversion != null) {
      return _selectedConversion!.tenDonViQuyDoi;
    }
    return _product?.donViTinh ?? 'Đơn vị';
  }

  int get _maxStock {
    if (_selectedVariant != null) {
      return _selectedVariant!.soLuongTon;
    }
    return _product?.soLuongTon ?? 0;
  }

  void _openReviewDialog() {
    final authVm = context.read<AuthViewModel>();
    final productVm = context.read<ProductViewModel>();

    if (!authVm.isLoggedIn || authVm.currentUser?.maKhachHang == null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Yêu cầu đăng nhập'),
          content: const Text('Vui lòng đăng nhập tài khoản Khách hàng để viết đánh giá cho sản phẩm.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Đóng'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
              },
              child: const Text('Đăng nhập ngay'),
            ),
          ],
        ),
      );
      return;
    }

    final canReviewResult = productVm.getCanReviewForProduct(widget.productId);
    if (canReviewResult == null || !canReviewResult.canReview) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.amber.shade800),
              const SizedBox(width: 8),
              const Text('Chưa đủ điều kiện'),
            ],
          ),
          content: Text(
            canReviewResult?.message ??
                'Bạn chỉ có thể đánh giá sản phẩm sau khi đã mua và nhận hàng thành công (Đơn hàng ở trạng thái Đã giao).',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Đã hiểu'),
            ),
          ],
        ),
      );
      return;
    }

    // Open BottomSheet Form
    int selectedStars = 5;
    final contentCtrl = TextEditingController();
    int? selectedOrderId = canReviewResult.unreviewedOrders.isNotEmpty
        ? (canReviewResult.unreviewedOrders.first['maDonHang'] as num?)?.toInt()
        : (canReviewResult.eligibleOrders.isNotEmpty
            ? (canReviewResult.eligibleOrders.first['maDonHang'] as num?)?.toInt()
            : null);
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Đánh Giá Sản Phẩm',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(sheetCtx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _product?.tenSanPham ?? '',
                style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1565C0)),
              ),
              const SizedBox(height: 16),

              // Star Selector
              const Text('Chất lượng vật tư:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Row(
                children: List.generate(5, (starIdx) {
                  final starVal = starIdx + 1;
                  return IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      starVal <= selectedStars ? Icons.star : Icons.star_border,
                      color: Colors.amber.shade700,
                      size: 34,
                    ),
                    onPressed: () {
                      setSheetState(() {
                        selectedStars = starVal;
                      });
                    },
                  );
                }),
              ),
              const SizedBox(height: 14),

              // Review Content Input
              TextField(
                controller: contentCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Nhận xét về chất lượng vật liệu xây dựng, quy cách đóng gói, tiến độ xe giao tận nơi...',
                  hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              const SizedBox(height: 16),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (contentCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(sheetCtx).showSnackBar(
                              const SnackBar(content: Text('Vui lòng viết nội dung nhận xét.')),
                            );
                            return;
                          }

                          setSheetState(() => isSubmitting = true);
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            await productVm.submitReview(
                              customerId: authVm.currentUser!.maKhachHang!,
                              productId: widget.productId,
                              orderId: selectedOrderId,
                              soSao: selectedStars,
                              noiDung: contentCtrl.text.trim(),
                            );
                            if (sheetCtx.mounted) {
                              Navigator.pop(sheetCtx);
                            }
                            if (mounted) {
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Gửi đánh giá sản phẩm thành công! Cảm ơn bạn.'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (err) {
                            setSheetState(() => isSubmitting = false);
                            if (sheetCtx.mounted) {
                              ScaffoldMessenger.of(sheetCtx).showSnackBar(
                                SnackBar(content: Text(err.toString())),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: isSubmitting
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Gửi Đánh Giá', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết vật tư')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(_error ?? 'Không thể tải chi tiết sản phẩm'),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _loadDetail, child: const Text('Thử lại')),
            ],
          ),
        ),
      );
    }

    final p = _product!;
    final imageUrl = ApiService.getImageUrl(p.hinhAnh);
    final productVm = context.watch<ProductViewModel>();
    final promotions = productVm.getPromotionsForProduct(p.maSanPham);
    final reviewsSummary = productVm.getReviewsForProduct(p.maSanPham);
    final canReviewResult = productVm.getCanReviewForProduct(p.maSanPham);

    return Scaffold(
      appBar: AppBar(
        title: Text(p.tenSanPham),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            AspectRatio(
              aspectRatio: 1.3,
              child: Container(
                color: Colors.white,
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey.shade100,
                          child: const Center(
                            child: Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.grey.shade100,
                        child: const Center(
                          child: Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                        ),
                      ),
              ),
            ),

            // Main Info Box
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category & Stock Status
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          p.tenDanhMuc,
                          style: TextStyle(color: Colors.blue.shade800, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        p.soLuongTon > 0 ? Icons.check_circle : Icons.cancel,
                        size: 16,
                        color: p.soLuongTon > 0 ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        p.soLuongTon > 0 ? 'Còn hàng trong kho: ${p.soLuongTon} ${p.donViTinh}' : 'Tạm hết hàng',
                        style: TextStyle(
                          fontSize: 12,
                          color: p.soLuongTon > 0 ? Colors.green.shade800 : Colors.red.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Product Title
                  Text(
                    p.tenSanPham,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.3),
                  ),
                  const SizedBox(height: 8),

                  // Reviews quick summary header
                  if (reviewsSummary != null && reviewsSummary.totalReviews > 0)
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          '${reviewsSummary.averageRating}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '(${reviewsSummary.totalReviews} đánh giá từ khách hàng)',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                        ),
                      ],
                    ),

                  const SizedBox(height: 12),

                  // Price & Unit
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      if (promotions.isNotEmpty && promotions.first.getDiscountedPrice(_currentPrice) < _currentPrice) ...[
                        Text(
                          Formatters.formatCurrency(promotions.first.getDiscountedPrice(_currentPrice)),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD32F2F),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          Formatters.formatCurrency(_currentPrice),
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey.shade500,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD32F2F),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            promotions.first.discountTag,
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ] else ...[
                        Text(
                          Formatters.formatCurrency(_currentPrice),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD32F2F),
                          ),
                        ),
                      ],
                      const SizedBox(width: 6),
                      Text(
                        '/ $_currentUnit',
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Active Promotions Banner for Product
            if (promotions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                color: Colors.orange.shade50,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.local_offer, color: Colors.deepOrange, size: 18),
                        const SizedBox(width: 6),
                        const Text(
                          'Ưu Đãi Khuyến Mãi Áp Dụng:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.deepOrange),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...promotions.map((km) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.deepOrange,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              km.discountBadge,
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${km.tenKhuyenMai} (${km.conditionText})',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 8),

            // Unit Conversions (Pills Selector)
            if (p.quyDoiDonVis.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Chọn đơn vị bán (Sỉ kiện / Bán lẻ):',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        // Base unit
                        ChoiceChip(
                          label: Text('${p.donViTinh} (Gốc) - ${Formatters.formatCurrency(p.giaBan)}'),
                          selected: _selectedConversion == null,
                          selectedColor: const Color(0xFF1565C0),
                          labelStyle: TextStyle(
                            color: _selectedConversion == null ? Colors.white : Colors.black87,
                            fontWeight: _selectedConversion == null ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (_) {
                            setState(() {
                              _selectedConversion = null;
                            });
                          },
                        ),
                        // Conversions
                        ...p.quyDoiDonVis.map((q) => ChoiceChip(
                          label: Text('${q.tenDonViQuyDoi} - ${Formatters.formatCurrency(q.giaBanQuyDoi)}'),
                          selected: _selectedConversion?.maQuyDoi == q.maQuyDoi,
                          selectedColor: const Color(0xFF1565C0),
                          labelStyle: TextStyle(
                            color: _selectedConversion?.maQuyDoi == q.maQuyDoi ? Colors.white : Colors.black87,
                            fontWeight: _selectedConversion?.maQuyDoi == q.maQuyDoi ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (_) {
                            setState(() {
                              _selectedConversion = q;
                            });
                          },
                        )),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Variants (Pills Selector)
            if (p.bienThes.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quy cách / Biến thể sản phẩm:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: p.bienThes.map((v) => ChoiceChip(
                        label: Text('${v.tenBienThe} (${Formatters.formatCurrency(v.giaBan)})'),
                        selected: _selectedVariant?.maBienThe == v.maBienThe,
                        selectedColor: const Color(0xFF1565C0),
                        labelStyle: TextStyle(
                          color: _selectedVariant?.maBienThe == v.maBienThe ? Colors.white : Colors.black87,
                          fontWeight: _selectedVariant?.maBienThe == v.maBienThe ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (_) {
                          setState(() {
                            _selectedVariant = v;
                          });
                        },
                      )).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Quantity Selector
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                children: [
                  const Text(
                    'Số lượng đặt:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const Spacer(),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove, size: 18),
                          onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            '$_quantity',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, size: 18),
                          onPressed: (_maxStock == 0 || _quantity < _maxStock)
                              ? () => setState(() => _quantity++)
                              : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Description Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mô Tả Sản Phẩm & Quy Cách Kỹ Thuật',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    p.moTa != null && p.moTa!.trim().isNotEmpty
                        ? p.moTa!
                        : 'Sản phẩm vật liệu xây dựng chính hãng đạt chuẩn TCVN, cung cấp đầy đủ chứng chỉ chất lượng xuất xưởng (CO/CQ). Hỗ trợ nghiệm thu mẫu trực tiếp tại chân công trình.',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade800, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    'Chính Sách Vận Chuyển Xe Tải VLXD-PRO',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  _buildPolicyRow(Icons.check_circle_outline, 'Nội thành TP.HCM: Cước xe tải 150.000 ₫ (Miễn phí từ 10 triệu).'),
                  _buildPolicyRow(Icons.check_circle_outline, 'Ngoại thành & lân cận: Cước xe tải 350.000 ₫ (Giảm còn 150k từ 15 triệu).'),
                  _buildPolicyRow(Icons.check_circle_outline, 'Hỗ trợ xe cẩu ben, kiểm đếm vật tư đầy đủ trước khi thanh toán.'),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Customer Reviews & Ratings Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Đánh Giá & Nhận Xét',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      TextButton.icon(
                        onPressed: _openReviewDialog,
                        icon: const Icon(Icons.rate_review, size: 16),
                        label: const Text('Viết đánh giá', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Rating Score Overview
                  if (reviewsSummary != null && reviewsSummary.totalReviews > 0) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        children: [
                          Column(
                            children: [
                              Text(
                                '${reviewsSummary.averageRating}',
                                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                              ),
                              Row(
                                children: List.generate(
                                  5,
                                  (i) => Icon(
                                    i < reviewsSummary.averageRating.round() ? Icons.star : Icons.star_border,
                                    size: 16,
                                    color: Colors.amber.shade700,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text('${reviewsSummary.totalReviews} lượt đánh giá', style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                            ],
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Text(
                              'Đánh giá thực tế từ khách hàng đã mua và nghiệm thu vật tư tại công trình.',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Reviews List
                    ...reviewsSummary.reviews.map((rv) => Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: const Color(0xFF1565C0),
                                child: Text(
                                  rv.hoTenKhachHang.isNotEmpty ? rv.hoTenKhachHang[0].toUpperCase() : 'K',
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      rv.hoTenKhachHang,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    Text(
                                      rv.ngayDanhGia != null ? DateFormat('dd/MM/yyyy HH:mm').format(rv.ngayDanhGia!) : '',
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: List.generate(
                                  5,
                                  (s) => Icon(
                                    s < rv.soSao ? Icons.star : Icons.star_border,
                                    size: 14,
                                    color: Colors.amber.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            rv.noiDung,
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade800, height: 1.3),
                          ),
                        ],
                      ),
                    )),
                  ] else ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.comment_outlined, size: 36, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          const Text(
                            'Chưa có đánh giá nào cho sản phẩm này.',
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            canReviewResult != null && canReviewResult.canReview
                                ? 'Bạn đã hoàn thành đơn hàng sản phẩm này, hãy viết đánh giá ngay!'
                                : 'Chỉ khách hàng đã mua và nhận hàng thành công mới có thể đánh giá.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Add to Cart
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  context.read<CartViewModel>().addToCart(
                    p,
                    quantity: _quantity,
                    variant: _selectedVariant,
                    conversion: _selectedConversion,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã thêm $_quantity $_currentUnit vào giỏ hàng'),
                      backgroundColor: Colors.green.shade700,
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.add_shopping_cart, color: Color(0xFF1565C0)),
                label: const Text('Thêm vào giỏ', style: TextStyle(color: Color(0xFF1565C0), fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Color(0xFF1565C0)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Buy Now
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  context.read<CartViewModel>().addToCart(
                    p,
                    quantity: _quantity,
                    variant: _selectedVariant,
                    conversion: _selectedConversion,
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                  );
                },
                icon: const Icon(Icons.flash_on, color: Colors.white),
                label: const Text('Mua ngay', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD32F2F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPolicyRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: Colors.blue.shade700),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
          ),
        ],
      ),
    );
  }
}
