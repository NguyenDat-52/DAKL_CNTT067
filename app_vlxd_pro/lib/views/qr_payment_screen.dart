import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../widgets/currency_formatter.dart';
import 'order_detail_screen.dart';
import 'main_navigation_screen.dart';

class QrPaymentScreen extends StatefulWidget {
  final int orderId;
  final String orderCode;
  final double totalAmount;
  final String? receiverPhone;

  const QrPaymentScreen({
    super.key,
    required this.orderId,
    required this.orderCode,
    required this.totalAmount,
    this.receiverPhone,
  });

  @override
  State<QrPaymentScreen> createState() => _QrPaymentScreenState();
}

class _QrPaymentScreenState extends State<QrPaymentScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _isPaidSuccess = false;
  bool _isChecking = false;

  Map<String, dynamic> _paymentConfig = {};
  Timer? _pollingTimer;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _loadConfigAndStartPolling();
  }

  Future<void> _loadConfigAndStartPolling() async {
    final cfg = await ApiService.getPaymentConfig();
    if (!mounted) return;

    setState(() {
      _paymentConfig = cfg;
      _isLoading = false;
    });

    // Start auto-checking payment status every 3.5 seconds
    _pollingTimer = Timer.periodic(const Duration(milliseconds: 3500), (timer) {
      _checkPaymentStatus();
    });
  }

  Future<void> _checkPaymentStatus() async {
    if (_isPaidSuccess || _isChecking) return;
    _isChecking = true;

    try {
      final status = await ApiService.getOrderPaymentStatus(widget.orderId);
      if (status['daThanhToan'] == true || status['trangThaiThanhToan'] == 'Đã thanh toán') {
        _pollingTimer?.cancel();
        if (mounted) {
          setState(() {
            _isPaidSuccess = true;
          });
        }
      }
    } catch (_) {
      // Ignore network flutter
    } finally {
      _isChecking = false;
    }
  }

  Future<void> _handleManualConfirmPaid() async {
    setState(() => _isChecking = true);
    await ApiService.confirmOrderPaid(widget.orderId);

    // Wait 1.5s to simulate instant Web Bank Webhook acknowledgement
    await Future.delayed(const Duration(milliseconds: 1500));
    _pollingTimer?.cancel();

    if (mounted) {
      setState(() {
        _isChecking = false;
        _isPaidSuccess = true;
      });
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã sao chép $label: $text'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1565C0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF1565C0)),
              SizedBox(height: 16),
              Text('Đang tải thông tin thanh toán QR từ hệ thống...'),
            ],
          ),
        ),
      );
    }

    if (_isPaidSuccess) {
      return _buildSuccessScreen();
    }

    final bankName = _paymentConfig['tenNganHang'] ?? 'MBBank (Ngân Hàng Quân Đội)';
    final bankAcc = _paymentConfig['soTaiKhoan'] ?? '0908123456';
    final bankOwner = _paymentConfig['chuTaiKhoan'] ?? 'CONG TY TNHH VLXD PRO';
    final rawHinhAnh = _paymentConfig['hinhAnhQR'] ?? '';
    final bankCode = _paymentConfig['bankCode'] ?? 'MB';

    String memoSyntax = _paymentConfig['cuPhapNoiDung'] ?? 'VLXD DH[MADONHANG]';
    final transferMemo = memoSyntax
        .replaceAll('[MADONHANG]', widget.orderId.toString())
        .replaceAll('[SODIENTHOAI]', widget.receiverPhone ?? '');

    // Dynamic VietQR generator URL
    final vietQrUrl = 'https://img.vietqr.io/image/$bankCode-$bankAcc-compact2.png'
        '?amount=${widget.totalAmount.toInt()}'
        '&addInfo=${Uri.encodeComponent(transferMemo)}'
        '&accountName=${Uri.encodeComponent(bankOwner)}';

    final qrImageUrl = rawHinhAnh.isNotEmpty
        ? ApiService.getImageUrl(rawHinhAnh)
        : vietQrUrl;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('Thanh Toán Chuyển Khoản QR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined),
            tooltip: 'Trang chủ',
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Status Listening Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade800, Colors.deepOrange],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3)),
                ],
              ),
              child: Row(
                children: [
                  FadeTransition(
                    opacity: _pulseController.drive(Tween(begin: 0.4, end: 1.0)),
                    child: const Icon(Icons.radio_button_checked, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Đang chờ nhận tiền chuyển khoản...',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Màn hình sẽ tự động cập nhật khi website nhận tiền',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // QR Code Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'QUÉT MÃ QR ĐỂ THANH TOÁN',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Mở ứng dụng ngân hàng bất kỳ (VietQR, Mobile Banking)',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),

                  // QR Image Box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300, width: 1.5),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Image.network(
                      qrImageUrl,
                      width: 220,
                      height: 220,
                      fit: BoxFit.contain,
                      loadingBuilder: (ctx, child, progress) {
                        if (progress == null) return child;
                        return const SizedBox(
                          width: 220,
                          height: 220,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      },
                      errorBuilder: (ctx, err, stack) => Image.network(
                        vietQrUrl,
                        width: 220,
                        height: 220,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Order Total Amount Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Số tiền thanh toán:', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                            const SizedBox(height: 2),
                            Text(
                              Formatters.formatCurrency(widget.totalAmount),
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFD32F2F)),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, color: Color(0xFFD32F2F)),
                          tooltip: 'Sao chép số tiền',
                          onPressed: () => _copyToClipboard(widget.totalAmount.toInt().toString(), 'Số tiền'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Bank Account Details Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.account_balance, color: Color(0xFF1565C0), size: 20),
                      SizedBox(width: 8),
                      Text('Thông Tin Chuyển Khoản Thủ Công', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  const Divider(height: 20),

                  _buildDetailRow('Ngân hàng:', bankName, canCopy: false),
                  const Divider(height: 16),
                  _buildDetailRow('Số tài khoản:', bankAcc, canCopy: true, label: 'Số tài khoản'),
                  const Divider(height: 16),
                  _buildDetailRow('Chủ tài khoản:', bankOwner, canCopy: true, label: 'Chủ tài khoản'),
                  const Divider(height: 16),
                  _buildDetailRow(
                    'Nội dung chuyển khoản:',
                    transferMemo,
                    canCopy: true,
                    label: 'Nội dung chuyển khoản',
                    isHighlight: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Customer Confirmation Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isChecking ? null : _handleManualConfirmPaid,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                icon: _isChecking
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(
                  _isChecking ? 'Đang kiểm tra đối soát...' : 'TÔI ĐÃ CHUYỂN KHOẢN THÀNH CÔNG',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Order detail button
            TextButton.icon(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: widget.orderId)),
                );
              },
              icon: const Icon(Icons.receipt_long, size: 18),
              label: Text('Theo dõi đơn hàng #${widget.orderCode}'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String title, String value, {bool canCopy = false, String label = '', bool isHighlight = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isHighlight ? const Color(0xFF1565C0) : Colors.black87,
            ),
          ),
        ),
        if (canCopy)
          InkWell(
            onTap: () => _copyToClipboard(value, label),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.copy, size: 14, color: Color(0xFF1565C0)),
                  SizedBox(width: 4),
                  Text('Chép', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSuccessScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Thanh Toán Thành Công'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, size: 76, color: Color(0xFF2E7D32)),
              ),
              const SizedBox(height: 24),
              const Text(
                'THANH TOÁN THÀNH CÔNG!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Mã Đơn Hàng: #${widget.orderCode}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1565C0), fontSize: 15),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Hệ thống VLXD-PRO đã ghi nhận thanh toán ${Formatters.formatCurrency(widget.totalAmount)} thành công.\nBộ phận kho và điều phối xe tải đang tiến hành chuẩn bị vật tư xuất kho.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.5),
              ),
              const SizedBox(height: 36),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: widget.orderId)),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.local_shipping_outlined),
                  label: const Text('THEO DÕI ĐƠN HÀNG', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
                      (route) => false,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.home),
                  label: const Text('VỀ TRANG CHỦ'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
