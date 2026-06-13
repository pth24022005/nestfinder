import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../shared/custom_button.dart';
import 'widgets/qr_payment_bottom_sheet.dart';

class TenantHomeScreen extends HookConsumerWidget {
  const TenantHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    // --- MOCK DATA: Dữ liệu giả lập hóa đơn tháng này ---
    const roomName = 'P.201';
    const totalAmount = 4350000;
    const isPaid = false;
    const dueDate = '15/06/2026';

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Xin chào, Trần Thị B',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            Text(
              'Phòng đang ở: $roomName',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () {
              // Đăng xuất
              ref.read(authProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. THẺ TỔNG TIỀN (BILL SUMMARY) ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isPaid
                      ? [Colors.green.shade400, Colors.green.shade600]
                      : [Theme.of(context).primaryColor, Colors.blue.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isPaid ? 'ĐÃ THANH TOÁN' : 'CHƯA THANH TOÁN',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Tổng tiền tháng 06/2026',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currencyFormat.format(totalAmount),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Hạn đóng: $dueDate',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // --- 2. CHI TIẾT HÓA ĐƠN ---
            const Text(
              'Chi tiết hóa đơn',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.grey.shade200, blurRadius: 6),
                ],
              ),
              child: Column(
                children: [
                  _buildBillItem(
                    icon: Icons.meeting_room,
                    color: Colors.blue,
                    title: 'Tiền phòng',
                    subtitle: 'Cố định hàng tháng',
                    amount: 3500000,
                    format: currencyFormat,
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildBillItem(
                    icon: Icons.electric_bolt,
                    color: Colors.orange,
                    title: 'Tiền điện',
                    subtitle:
                        'Số mới: 1250 - Số cũ: 1200\nTiêu thụ: 50 kWh x 3,500đ',
                    amount: 175000,
                    format: currencyFormat,
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildBillItem(
                    icon: Icons.water_drop,
                    color: Colors.cyan,
                    title: 'Tiền nước',
                    subtitle:
                        'Số mới: 450 - Số cũ: 440\nTiêu thụ: 10 m³ x 20,000đ',
                    amount: 200000,
                    format: currencyFormat,
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildBillItem(
                    icon: Icons.wifi,
                    color: Colors.purple,
                    title: 'Internet & Dịch vụ',
                    subtitle: 'Wifi, Rác, Vệ sinh chung',
                    amount: 150000,
                    format: currencyFormat,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // --- 3. NÚT THANH TOÁN ---
            if (!isPaid)
              CustomButton(
                text: 'Thanh toán ngay',
                onPressed: () {
                  // GỌI BOTTOM SHEET HIỂN THỊ MÃ QR TẠI ĐÂY
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const QRPaymentBottomSheet(
                      amount: totalAmount, // Lấy biến totalAmount ở trên cùng
                      roomName: roomName, // Lấy biến roomName ở trên cùng
                    ),
                  );
                },
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // Widget vẽ từng dòng chi tiết
  Widget _buildBillItem({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required num amount,
    required NumberFormat format,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Text(
            format.format(amount),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
