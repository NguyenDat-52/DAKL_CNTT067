import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/cart_viewmodel.dart';
import '../viewmodels/order_viewmodel.dart';
import '../widgets/currency_formatter.dart';
import 'order_detail_screen.dart';
import 'qr_payment_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _noteController = TextEditingController();

  String _paymentMethod = 'Tiền mặt'; // 'Tiền mặt' hoặc 'Chuyển khoản'
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill if customer is logged in
    final user = context.read<AuthViewModel>().currentUser;
    if (user != null) {
      _nameController.text = user.hoTen;
      _phoneController.text = user.soDienThoai;
      _addressController.text = user.diaChi;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _handlePlaceOrder() async {
    if (!_formKey.currentState!.validate()) return;

    final cartVm = context.read<CartViewModel>();
    if (cartVm.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Giỏ hàng rỗng! Không thể đặt hàng.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final authVm = context.read<AuthViewModel>();
    final orderVm = context.read<OrderViewModel>();

    String finalNote = _noteController.text.trim();
    if (cartVm.appliedPromotion != null) {
      finalNote = '${finalNote.isNotEmpty ? "$finalNote. " : ""}Ưu đãi áp dụng: ${cartVm.appliedPromotion!.tenKhuyenMai} (-${Formatters.formatCurrency(cartVm.totalDiscount)})';
    }

    final payload = {
      'CustomerId': authVm.currentUser?.maKhachHang,
      'ReceiverName': _nameController.text.trim(),
      'ReceiverPhone': _phoneController.text.trim(),
      'DeliveryAddress': _addressController.text.trim(),
      'Area': cartVm.selectedArea,
      'ShippingFee': cartVm.shippingFee,
      'PaymentMethod': _paymentMethod,
      'ChooseDeposit': cartVm.isDepositSelected,
      'Note': finalNote,
      'Items': cartVm.items.map((i) => {
        'ProductId': i.productId,
        'VariantId': i.variantId,
        'VariantName': i.variantName,
        'Quantity': i.quantity,
        'UnitPrice': i.unitPrice,
        'Unit': i.unit,
      }).toList(),
    };

    try {
      final res = await orderVm.submitOrder(payload);
      final int orderId = res['orderId'] ?? 0;
      final String orderCode = res['orderCode'] ?? 'DH-$orderId';

      // Clear Cart
      cartVm.clearCart();

      if (mounted) {
        setState(() => _isSubmitting = false);

        if (_paymentMethod == 'Chuyển khoản') {
          final totalPay = res['tongTien'] != null ? (res['tongTien'] as num).toDouble() : cartVm.grandTotal;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => QrPaymentScreen(
                orderId: orderId,
                orderCode: orderCode,
                totalAmount: totalPay,
                receiverPhone: _phoneController.text.trim(),
              ),
            ),
          );
        } else {
          // Show COD Success Dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 28),
                  SizedBox(width: 8),
                  Text('Đặt Hàng Thành Công!'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mã đơn hàng: $orderCode', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  const Text('Đơn hàng của bạn đã được chuyển tới bộ phận điều phối VLXD-PRO.'),
                  const SizedBox(height: 4),
                  Text('Nhân viên bán hàng sẽ liên hệ xác nhận chuyến xe tải sớm nhất.', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx); // Close dialog
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: orderId)),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0)),
                  child: const Text('THEO DÕI ĐƠN HÀNG', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartVm = context.watch<CartViewModel>();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Thanh toán & Đặt hàng'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section 1: Receiver Information
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.person_pin, size: 20, color: Color(0xFF1565C0)),
                        SizedBox(width: 8),
                        Text('Thông Tin Nhận Vật Tư Tại Công Trình', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Họ và tên người nhận *',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập họ tên' : null,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Số điện thoại nhận hàng *',
                        prefixIcon: Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập số điện thoại' : null,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _addressController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Địa chỉ chân công trình / giao hàng *',
                        prefixIcon: Icon(Icons.location_on_outlined),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập địa chỉ công trình' : null,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _noteController,
                      decoration: const InputDecoration(
                        labelText: 'Ghi chú cho tài xế xe tải (Đường cấm tải, giờ cẩu...)',
                        prefixIcon: Icon(Icons.notes),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Section 2: Large Order Deposit Option (>= 5,000,000 ₫)
              if (cartVm.canDeposit) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.shield_outlined, color: Colors.amber.shade900, size: 20),
                          const SizedBox(width: 8),
                          const Text('Chính Sách Đặt Cọc Công Trình Lớn', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Đặt cọc trước 30% giá trị đơn hàng', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          'Số tiền cọc: ${Formatters.formatCurrency(cartVm.depositAmount)} (Còn lại ${Formatters.formatCurrency(cartVm.grandTotal - cartVm.depositAmount)} thanh toán khi Shipper giao hàng).',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                        ),
                        value: cartVm.isDepositSelected,
                        activeColor: const Color(0xFF1565C0),
                        onChanged: (val) => cartVm.setDepositSelected(val ?? false),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Section 3: Payment Method
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.payment, size: 20, color: Color(0xFF1565C0)),
                        SizedBox(width: 8),
                        Text('Phương Thức Thanh Toán', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 8),

                    RadioListTile<String>(
                      value: 'Tiền mặt',
                      groupValue: _paymentMethod,
                      title: const Text('Tiền mặt khi nhận hàng (COD)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      subtitle: const Text('Kiểm đếm vật tư tại công trình xong mới thanh toán cho tài xế', style: TextStyle(fontSize: 11)),
                      onChanged: (v) => setState(() => _paymentMethod = v!),
                    ),
                    const Divider(height: 1),
                    RadioListTile<String>(
                      value: 'Chuyển khoản',
                      groupValue: _paymentMethod,
                      title: const Text('Chuyển khoản ngân hàng (QR Code)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      subtitle: const Text('Techcombank / Vietcombank - Cửa hàng xác nhận ngay', style: TextStyle(fontSize: 11)),
                      onChanged: (v) => setState(() => _paymentMethod = v!),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Section 4: Final Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Số lượng mặt hàng:'),
                        Text('${cartVm.totalItemCount} món', style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tiền vật tư gốc:'),
                        Text(Formatters.formatCurrency(cartVm.rawSubtotal), style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    if (cartVm.totalDiscount > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Ưu đãi chiết khấu / Giảm giá:'),
                          Text(
                            '-${Formatters.formatCurrency(cartVm.totalDiscount)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Cước xe tải (${cartVm.selectedArea}):'),
                        Text(
                          cartVm.shippingFee == 0 ? 'Miễn phí' : Formatters.formatCurrency(cartVm.shippingFee),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: cartVm.shippingFee == 0 ? Colors.green.shade700 : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tổng thanh toán:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        Text(
                          Formatters.formatCurrency(cartVm.grandTotal),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFD32F2F)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Place Order Button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _handlePlaceOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD32F2F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isSubmitting
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                          SizedBox(width: 12),
                          Text('ĐANG TẠO ĐƠN HÀNG LÊN HỆ THỐNG...', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline),
                          SizedBox(width: 8),
                          Text('XÁC NHẬN ĐẶT HÀNG NGAY', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
