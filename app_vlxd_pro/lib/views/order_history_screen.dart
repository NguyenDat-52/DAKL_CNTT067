import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/order_model.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/order_viewmodel.dart';
import '../widgets/currency_formatter.dart';
import 'order_detail_screen.dart';
import 'product_detail_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final _phoneSearchController = TextEditingController();
  final _orderSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchOrders();
    });
  }

  @override
  void dispose() {
    _phoneSearchController.dispose();
    _orderSearchController.dispose();
    super.dispose();
  }

  Future<void> _fetchOrders() async {
    final authVm = context.read<AuthViewModel>();
    final orderVm = context.read<OrderViewModel>();

    if (authVm.currentUser?.maKhachHang != null) {
      await orderVm.loadOrders(customerId: authVm.currentUser!.maKhachHang);
    } else if (authVm.currentUser?.soDienThoai != null) {
      await orderVm.loadOrders(phone: authVm.currentUser!.soDienThoai);
    } else if (_phoneSearchController.text.trim().isNotEmpty) {
      await orderVm.loadOrders(phone: _phoneSearchController.text.trim());
    }
  }

  Future<void> _pickCustomDateRange(OrderViewModel orderVm) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: orderVm.customFromDate != null && orderVm.customToDate != null
          ? DateTimeRange(start: orderVm.customFromDate!, end: orderVm.customToDate!)
          : DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: const Color(0xFF1565C0),
            colorScheme: const ColorScheme.light(primary: Color(0xFF1565C0)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      orderVm.setTimeFilter('custom', fromDate: picked.start, toDate: picked.end);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final orderVm = context.watch<OrderViewModel>();
    final filteredOrders = orderVm.orders;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Lịch sử & Đơn đặt hàng'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 1. Top Order / Product Search Bar
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            color: Colors.white,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                controller: _orderSearchController,
                decoration: InputDecoration(
                  hintText: 'Tìm theo mã đơn (DH12...) hoặc tên vật liệu...',
                  hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF1565C0), size: 22),
                  suffixIcon: orderVm.searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                          onPressed: () {
                            _orderSearchController.clear();
                            orderVm.clearSearchQuery();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  isDense: true,
                ),
                onChanged: (val) => orderVm.setSearchQuery(val),
              ),
            ),
          ),
          const Divider(height: 1),

          // Search Results Notification Bar
          if (orderVm.searchQuery.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.blue.shade50,
              child: Row(
                children: [
                  const Icon(Icons.filter_list, size: 16, color: Color(0xFF1565C0)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tìm thấy ${filteredOrders.length} đơn hàng khớp với "${orderVm.searchQuery}"',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1565C0)),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      _orderSearchController.clear();
                      orderVm.clearSearchQuery();
                    },
                    child: const Text('Xóa', style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

          // Search by phone if not logged in
          if (!authVm.isLoggedIn)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _phoneSearchController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: 'Nhập số điện thoại tra cứu...',
                        isDense: true,
                        prefixIcon: const Icon(Icons.phone),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _fetchOrders,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Tra cứu'),
                  ),
                ],
              ),
            ),

          // Filters Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick Time Filters
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      const Icon(Icons.date_range, size: 16, color: Color(0xFF1565C0)),
                      const SizedBox(width: 6),
                      const Text(
                        'Khoảng thời gian:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      const Spacer(),
                      if (orderVm.selectedTimeFilter != 'all' || orderVm.selectedStatus != 'Tất cả')
                        InkWell(
                          onTap: () => orderVm.resetFilters(),
                          child: const Text(
                            'Đặt lại bộ lọc',
                            style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      _buildTimeChip('Tất cả', 'all', orderVm),
                      _buildTimeChip('Hôm nay', 'today', orderVm),
                      _buildTimeChip('Hôm qua', 'yesterday', orderVm),
                      _buildTimeChip('Tuần này', 'this_week', orderVm),
                      _buildTimeChip('Tháng này', 'this_month', orderVm),
                      ChoiceChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.calendar_month, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              orderVm.selectedTimeFilter == 'custom' && orderVm.customFromDate != null
                                  ? '${DateFormat('dd/MM').format(orderVm.customFromDate!)} - ${DateFormat('dd/MM').format(orderVm.customToDate!)}'
                                  : 'Tùy chọn ngày...',
                              style: TextStyle(
                                fontSize: 11,
                                color: orderVm.selectedTimeFilter == 'custom' ? Colors.white : Colors.black87,
                                fontWeight: orderVm.selectedTimeFilter == 'custom' ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                        selected: orderVm.selectedTimeFilter == 'custom',
                        selectedColor: const Color(0xFF1565C0),
                        onSelected: (_) => _pickCustomDateRange(orderVm),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 12),

                // Status Filter Chips
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: const Row(
                    children: [
                      Icon(Icons.filter_alt_outlined, size: 16, color: Color(0xFF1565C0)),
                      SizedBox(width: 6),
                      Text(
                        'Trạng thái đơn hàng:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      _buildStatusChip('Tất cả', 'Tất cả', orderVm),
                      _buildStatusChip('Chờ xác nhận', 'Chờ xác nhận', orderVm),
                      _buildStatusChip('Đang chuẩn bị', 'Đang chuẩn bị', orderVm),
                      _buildStatusChip('Đang giao', 'Đang giao', orderVm),
                      _buildStatusChip('Đã giao (Hoàn tất)', 'Đã giao', orderVm),
                      _buildStatusChip('Đã hủy', 'Đã hủy', orderVm),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Orders count indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey.shade100,
            child: Row(
              children: [
                Text(
                  'Tìm thấy ${filteredOrders.length} đơn hàng',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                ),
                const Spacer(),
                if (orderVm.allOrders.isNotEmpty && filteredOrders.length < orderVm.allOrders.length)
                  Text(
                    '(Tổng ${orderVm.allOrders.length} đơn)',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
              ],
            ),
          ),

          // Orders list
          Expanded(
            child: orderVm.isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _fetchOrders,
                    child: filteredOrders.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.assignment_outlined, size: 64, color: Colors.grey.shade400),
                                const SizedBox(height: 12),
                                const Text('Không tìm thấy đơn hàng nào', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(
                                  orderVm.allOrders.isEmpty
                                      ? 'Các đơn hàng bạn đặt sẽ được đồng bộ hiển thị tại đây'
                                      : 'Thử điều chỉnh lại bộ lọc thời gian hoặc trạng thái',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: filteredOrders.length,
                            itemBuilder: (context, index) {
                              final order = filteredOrders[index];
                              return _buildCustomOrderCard(order);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeChip(String label, String value, OrderViewModel orderVm) {
    final isSelected = orderVm.selectedTimeFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : Colors.black87)),
        selected: isSelected,
        selectedColor: const Color(0xFF1565C0),
        onSelected: (_) => orderVm.setTimeFilter(value),
      ),
    );
  }

  Widget _buildStatusChip(String label, String value, OrderViewModel orderVm) {
    final isSelected = orderVm.selectedStatus == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : Colors.black87)),
        selected: isSelected,
        selectedColor: const Color(0xFF1565C0),
        onSelected: (_) => orderVm.setStatusFilter(value),
      ),
    );
  }

  Widget _buildCustomOrderCard(OrderModel order) {
    final isDelivered = order.trangThai == 'Đã giao' ||
        order.trangThai == 'Đã đối soát xong' ||
        order.trangThai == 'Hoàn tất';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OrderDetailScreen(orderId: order.maDonHang),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Code & Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1565C0).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          order.orderCode,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1565C0), fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        order.ngayDat != null ? DateFormat('dd/MM/yyyy HH:mm').format(order.ngayDat!) : '',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  _buildStatusBadge(order.trangThai),
                ],
              ),
              const SizedBox(height: 10),

              // Items summary if present
              if (order.items.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: order.items.map((it) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline, size: 14, color: Colors.blueGrey),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${it.tenSanPham} (${it.soLuong} ${it.donViTinh})',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            Formatters.formatCurrency(it.thanhTien),
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    )).toList(),
                  ),
                ),
                const SizedBox(height: 10),
              ],

              // Address & Vehicle info
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.location_on_outlined, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      order.diaChiGiao,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                  ),
                ],
              ),

              if (order.loaiXe != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.local_shipping_outlined, size: 16, color: Colors.blue.shade700),
                    const SizedBox(width: 4),
                    Text(
                      'Xe vận chuyển: ${order.loaiXe}',
                      style: TextStyle(fontSize: 11, color: Colors.blue.shade900, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],

              const Divider(height: 18),

              // Bottom Row: Total & Action
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tổng thanh toán:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      Text(
                        Formatters.formatCurrency(order.tongTien),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFD32F2F)),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (isDelivered && order.items.isNotEmpty) ...[
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProductDetailScreen(productId: order.items.first.maSanPham),
                              ),
                            );
                          },
                          icon: const Icon(Icons.star_rate, size: 14, color: Colors.amber),
                          label: const Text('Đánh giá SP', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.amber),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            minimumSize: const Size(0, 32),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OrderDetailScreen(orderId: order.maDonHang),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1565C0),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          minimumSize: const Size(0, 32),
                        ),
                        child: const Text('Xem lộ trình', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg = Colors.grey.shade100;
    Color fg = Colors.grey.shade800;

    if (status.contains('Chờ')) {
      bg = Colors.amber.shade50;
      fg = Colors.amber.shade900;
    } else if (status.contains('chuẩn bị') || status.contains('tiến hành')) {
      bg = Colors.blue.shade50;
      fg = Colors.blue.shade800;
    } else if (status.contains('Đang giao')) {
      bg = Colors.purple.shade50;
      fg = Colors.purple.shade800;
    } else if (status.contains('Đã giao') || status.contains('đối soát') || status.contains('hoàn thành')) {
      bg = Colors.green.shade50;
      fg = Colors.green.shade800;
    } else if (status.contains('hủy')) {
      bg = Colors.red.shade50;
      fg = Colors.red.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        status,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
