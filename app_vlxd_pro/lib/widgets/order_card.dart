import 'package:flutter/material.dart';
import '../models/order_model.dart';
import 'currency_formatter.dart';

class OrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onTap;

  const OrderCard({
    super.key,
    required this.order,
    required this.onTap,
  });

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'chờ xác nhận':
        return Colors.orange;
      case 'đã xác nhận':
      case 'chờ nhận đơn':
        return Colors.blue;
      case 'đang soạn hàng':
      case 'chuẩn bị hàng':
        return Colors.purple;
      case 'đang giao':
      case 'đang giao hàng':
        return Colors.amber.shade800;
      case 'đã giao':
      case 'hoàn thành':
      case 'đã đối soát xong':
        return Colors.green;
      case 'đã hủy':
        return Colors.red;
      default:
        return Colors.grey.shade700;
    }
  }

  IconData _getVehicleIcon(String? vehicle) {
    if (vehicle == null) return Icons.local_shipping_outlined;
    final v = vehicle.toLowerCase();
    if (v.contains('máy')) return Icons.two_wheeler;
    if (v.contains('gác')) return Icons.electric_rickshaw;
    return Icons.local_shipping;
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(order.trangThai);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Order Code & Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.receipt_long, size: 20, color: Color(0xFF1E88E5)),
                      const SizedBox(width: 6),
                      Text(
                        order.orderCode,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: statusColor.withOpacity(0.4)),
                    ),
                    child: Text(
                      order.trangThai,
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),

              // Date & Destination
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    Formatters.formatDate(order.ngayDat),
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                  ),
                  const Spacer(),
                  if (order.loaiXe != null && order.loaiXe!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(_getVehicleIcon(order.loaiXe), size: 14, color: Colors.blueGrey.shade800),
                          const SizedBox(width: 4),
                          Text(
                            order.loaiXe!,
                            style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade900, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.location_on_outlined, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${order.nguoiNhan} - ${order.diaChiGiao}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Total Amount & Item Count
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${order.soLuongSanPham} món hàng',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  Row(
                    children: [
                      const Text(
                        'Tổng: ',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        Formatters.formatCurrency(order.tongTien),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD32F2F),
                        ),
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
}
