import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/api_service.dart';
import '../widgets/currency_formatter.dart';
import 'qr_payment_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  OrderModel? _order;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrderDetail();
  }

  Future<void> _loadOrderDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final o = await ApiService.getOrderDetail(widget.orderId);
      setState(() {
        _order = o;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  int _getStepIndex(String status) {
    switch (status.toLowerCase()) {
      case 'chờ xác nhận':
        return 0;
      case 'đã xác nhận':
      case 'chờ nhận đơn':
        return 1;
      case 'đã nhận đơn':
      case 'đang soạn hàng':
      case 'chuẩn bị hàng':
        return 2;
      case 'đang giao':
      case 'đang giao hàng':
        return 3;
      case 'đã giao':
      case 'hoàn thành':
      case 'đã đối soát xong':
        return 4;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Đơn hàng #${widget.orderId}'), backgroundColor: const Color(0xFF1565C0), foregroundColor: Colors.white),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _order == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Đơn hàng #${widget.orderId}'), backgroundColor: const Color(0xFF1565C0), foregroundColor: Colors.white),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(_error ?? 'Không thể tải chi tiết đơn hàng'),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _loadOrderDetail, child: const Text('Thử lại')),
            ],
          ),
        ),
      );
    }

    final o = _order!;
    final stepIndex = _getStepIndex(o.trangThai);
    final delivery = o.deliveryTracking;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(o.orderCode),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrderDetail,
            tooltip: 'Làm mới tiến trình',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadOrderDetail,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          o.orderCode,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1565C0).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            o.trangThai,
                            style: const TextStyle(color: Color(0xFF1565C0), fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Thời gian đặt: ${Formatters.formatDate(o.ngayDat)}',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Tracking Timeline Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.timeline, color: Color(0xFF1565C0), size: 20),
                        SizedBox(width: 8),
                        Text('Lộ Trình Giao Hàng Thời Gian Thực', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _buildTimelineStep(
                      title: '1. Khách đặt đơn hàng',
                      subtitle: Formatters.formatDate(o.ngayDat),
                      isDone: stepIndex >= 0,
                      isCurrent: stepIndex == 0,
                    ),
                    _buildTimelineStep(
                      title: '2. Cửa hàng xác nhận đơn hàng',
                      subtitle: stepIndex >= 1 ? 'Đã duyệt kho và chuyển sang hồ điều phối xe' : 'Đang chờ nhân viên kiểm duyệt',
                      isDone: stepIndex >= 1,
                      isCurrent: stepIndex == 1,
                    ),
                    _buildTimelineStep(
                      title: '3. Phân công đội xe & Chuẩn bị vật tư',
                      subtitle: delivery?.tenTaiXe != null
                          ? 'Tài xế: ${delivery!.tenTaiXe} (${delivery.loaiXe ?? "Xe giao hàng"})'
                          : (stepIndex >= 2 ? 'Đang soạn hàng tại bãi kho' : 'Chờ phân xe'),
                      isDone: stepIndex >= 2,
                      isCurrent: stepIndex == 2,
                    ),
                    _buildTimelineStep(
                      title: '4. Đang trên đường vận chuyển',
                      subtitle: delivery?.thoiGianBatDauGiao != null
                          ? 'Xuất phát lúc: ${Formatters.formatDate(delivery!.thoiGianBatDauGiao)}'
                          : (stepIndex >= 3 ? 'Xe đang di chuyển tới công trình' : 'Chờ xuất kho'),
                      isDone: stepIndex >= 3,
                      isCurrent: stepIndex == 3,
                    ),
                    _buildTimelineStep(
                      title: '5. Đã giao hàng & Nghiệm thu',
                      subtitle: delivery?.thoiGianGiaoThucTe != null
                          ? 'Giao thành công: ${Formatters.formatDate(delivery!.thoiGianGiaoThucTe)}'
                          : 'Khách hàng ký biên bản nhận hàng',
                      isDone: stepIndex >= 4,
                      isCurrent: stepIndex == 4,
                      isLast: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Vehicle & Driver Details Card (If available)
              if (delivery != null && (delivery.loaiXe != null || delivery.tenTaiXe != null)) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.local_shipping, color: Color(0xFF1565C0), size: 20),
                          SizedBox(width: 8),
                          Text('Phương Tiện & Tài Xế Phụ Trách', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0D47A1))),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.blue.shade300),
                            ),
                            child: const Icon(Icons.person, color: Color(0xFF1565C0)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  delivery.tenTaiXe ?? 'Tài xế cửa hàng',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                if (delivery.sdtTaiXe != null)
                                  Text(
                                    'SĐT: ${delivery.sdtTaiXe}',
                                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                                  ),
                                if (delivery.loaiXe != null)
                                  Text(
                                    'Phương tiện: ${delivery.loaiXe} ${delivery.bienSoXe != null ? "(${delivery.bienSoXe})" : ""}',
                                    style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Receiver & Site Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.location_on, color: Color(0xFF1565C0), size: 20),
                        SizedBox(width: 8),
                        Text('Địa Chỉ Chân Công Trình', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text('${o.nguoiNhan} - ${o.soDienThoaiNhan}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(o.diaChiGiao, style: TextStyle(color: Colors.grey.shade800, fontSize: 13)),
                    const SizedBox(height: 6),
                    Text('Khu vực: ${o.khuVucGiaoHang}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    if (o.ghiChu != null && o.ghiChu!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text('Ghi chú: ${o.ghiChu}', style: const TextStyle(color: Colors.amber, fontSize: 12, fontStyle: FontStyle.italic)),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Items Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Danh Sách Vật Liệu (${o.items.length} món)',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: o.items.length,
                      separatorBuilder: (context, index) => const Divider(height: 16),
                      itemBuilder: (context, index) {
                        final item = o.items[index];
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.tenSanPham,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                  ),
                                  if (item.tenBienThe != null) ...[
                                    const SizedBox(height: 2),
                                    Text(item.tenBienThe!, style: TextStyle(fontSize: 12, color: Colors.purple.shade700)),
                                  ],
                                  const SizedBox(height: 4),
                                  Text(
                                    '${item.soLuong} ${item.donViTinh} x ${Formatters.formatCurrency(item.donGia)}',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              Formatters.formatCurrency(item.thanhTien),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Payment Summary Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Cước xe tải giao hàng:'),
                        Text(
                          o.phiVanChuyen == 0 ? 'Miễn phí' : Formatters.formatCurrency(o.phiVanChuyen),
                          style: TextStyle(fontWeight: FontWeight.w600, color: o.phiVanChuyen == 0 ? Colors.green.shade700 : Colors.black87),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Phương thức thanh toán:'),
                        Text(o.phuongThucThanhToan, style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tình trạng thanh toán:'),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: o.trangThaiThanhToan == 'Đã thanh toán' ? Colors.green.shade50 : Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            o.trangThaiThanhToan,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: o.trangThaiThanhToan == 'Đã thanh toán' ? Colors.green.shade800 : Colors.orange.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (o.soTienDatCoc > 0 && o.soTienDatCoc < o.tongTien) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Đã đặt cọc (30%):'),
                          Text(Formatters.formatCurrency(o.soTienDatCoc), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                        ],
                      ),
                    ],
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tổng thanh toán:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        Text(
                          Formatters.formatCurrency(o.tongTien),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFD32F2F)),
                        ),
                      ],
                    ),
                    if (o.phuongThucThanhToan.contains('Chuyển khoản') && o.trangThaiThanhToan != 'Đã thanh toán') ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => QrPaymentScreen(
                                  orderId: o.maDonHang,
                                  orderCode: o.orderCode,
                                  totalAmount: o.tongTien,
                                  receiverPhone: o.soDienThoaiNhan,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1565C0),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.qr_code_2, size: 20),
                          label: const Text('MỞ MÃ QR THANH TOÁN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineStep({
    required String title,
    required String subtitle,
    required bool isDone,
    required bool isCurrent,
    bool isLast = false,
  }) {
    final color = isDone
        ? const Color(0xFF1565C0)
        : (isCurrent ? Colors.amber.shade800 : Colors.grey.shade400);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step circle & line
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isDone ? const Color(0xFF1565C0) : (isCurrent ? Colors.amber.shade800 : Colors.white),
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                ),
                child: isDone
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : (isCurrent
                        ? const Center(child: SizedBox(width: 8, height: 8, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 1.5)))
                        : null),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isDone ? const Color(0xFF1565C0) : Colors.grey.shade300,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: isDone || isCurrent ? FontWeight.bold : FontWeight.normal,
                      color: isDone || isCurrent ? Colors.black87 : Colors.grey.shade500,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
