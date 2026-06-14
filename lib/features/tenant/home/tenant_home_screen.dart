import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../auth/presentation/auth_controller.dart';
import 'widgets/qr_payment_bottom_sheet.dart';
import '../../admin/properties/properties_screen.dart';
import 'package:go_router/go_router.dart';

// =====================================================================
// PROVIDER KẾT NỐI DỮ LIỆU THẬT TỪ FIREBASE
// =====================================================================

final currentTenantRoomProvider = StreamProvider<RoomModel?>((ref) {
  final phone = ref.watch(currentUserPhoneProvider);

  if (phone.isEmpty) return Stream.value(null);

  return FirebaseFirestore.instance
      .collection('rooms')
      .where('tenantPhone', isEqualTo: phone)
      .where('status', isEqualTo: 'rented')
      .snapshots()
      .map((snapshot) {
        if (snapshot.docs.isEmpty) return null;

        final data = snapshot.docs.first.data();
        return RoomModel(
          id: snapshot.docs.first.id,
          name: data['name'] ?? '',
          status: RoomStatus.rented,
          price: (data['price'] ?? data['rentPrice'] ?? 0).toDouble(),
          tenantName: data['tenantName'],
        );
      });
});

// Lấy hóa đơn mới nhất của phòng
final tenantLatestInvoiceProvider =
    StreamProvider.family<Map<String, dynamic>?, String>((ref, roomId) {
      return FirebaseFirestore.instance
          .collection('invoices')
          .where('roomId', isEqualTo: roomId)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .snapshots()
          .map((snapshot) {
            if (snapshot.docs.isEmpty) return null;
            // SỬA LỖI Ở ĐÂY: Phải nhét thêm cái 'id' vào cục data
            return {
              'id': snapshot.docs.first.id,
              ...snapshot.docs.first.data(),
            };
          });
    });

// =====================================================================
// GIAO DIỆN CHÍNH
// =====================================================================

class TenantHomeScreen extends HookConsumerWidget {
  const TenantHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final roomAsync = ref.watch(currentTenantRoomProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 20,
        title: roomAsync.maybeWhen(
          data: (room) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Xin chào, ${room?.tenantName ?? "Khách thuê"}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                room != null ? 'Phòng đang ở: ${room.name}' : 'Chưa xếp phòng',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          orElse: () => const Text(
            'Đang tải...',
            style: TextStyle(color: Colors.black87),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                Icons.logout_rounded,
                color: Colors.red.shade700,
                size: 20,
              ),
              onPressed: () {
                ref.read(authProvider.notifier).logout();
              },
            ),
          ),
        ],
      ),
      body: roomAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Lỗi kết nối: $err')),
        data: (room) {
          if (room == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.house_siding_rounded,
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Bạn chưa có phòng',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Vui lòng liên hệ chủ trọ để được cấp hợp đồng.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final invoiceAsync = ref.watch(tenantLatestInvoiceProvider(room.id));

          return invoiceAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Lỗi tải hóa đơn: $err')),
            data: (invoice) {
              final totalAmount = (invoice?['totalAmount'] ?? 0) as num;
              final isPaid =
                  invoice?['status'] == 'paid' ||
                  invoice?['status'] ==
                      'pending'; // Ẩn nút thanh toán nếu đang chờ duyệt
              final isPending = invoice?['status'] == 'pending';
              final month = invoice?['month'] ?? DateTime.now().month;
              final year = invoice?['year'] ?? DateTime.now().year;

              return RefreshIndicator(
                onRefresh: () async {},
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 16.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- 1. THẺ HÓA ĐƠN THÔNG MINH ---
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isPaid
                                ? (isPending
                                      ? [
                                          Colors.orange.shade500,
                                          Colors.orange.shade700,
                                        ] // Màu cam nếu chờ duyệt
                                      : [
                                          const Color(0xFF10B981),
                                          const Color(0xFF059669),
                                        ]) // Màu xanh nếu đã duyệt
                                : [
                                    const Color(0xFFEF4444),
                                    const Color(0xFFDC2626),
                                  ], // Màu đỏ nếu chưa trả
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (isPaid
                                          ? (isPending
                                                ? Colors.orange
                                                : Colors.green)
                                          : Colors.red)
                                      .withValues(alpha: 0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'TỔNG TIỀN THÁNG $month/$year',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    isPaid
                                        ? (isPending
                                              ? 'ĐANG CHỜ DUYỆT'
                                              : 'ĐÃ THANH TOÁN')
                                        : 'CHƯA THANH TOÁN',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              currencyFormat.format(totalAmount),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  color: Colors.white.withValues(alpha: 0.7),
                                  size: 14,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  invoice == null
                                      ? 'Bạn chưa có hóa đơn nào'
                                      : (isPaid
                                            ? (isPending
                                                  ? 'Quản lý đang kiểm tra tài khoản'
                                                  : 'Cảm ơn bạn đã đóng tiền đúng hạn')
                                            : 'Vui lòng thanh toán sớm nhé!'),
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // --- NÚT THANH TOÁN QR ---
                      if (invoice != null && !isPaid) ...[
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) => QRPaymentBottomSheet(
                                  amount: totalAmount.toDouble(),
                                  roomName: room.name,
                                  // SỬA LỖI Ở ĐÂY: Truyền ID an toàn
                                  invoiceId: invoice['id'] ?? '',
                                  roomId: room.id,
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.qr_code_2,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'THANH TOÁN BẰNG MÃ QR',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1C1C1E),
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],

                      // --- 2. THANH LỐI TẮT ---
                      const Text(
                        'TIỆN ÍCH DỊCH VỤ',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.grey,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildActionIcon(
                              Icons.build_circle_outlined,
                              'Báo sự cố',
                              Colors.orange.shade600,
                              () {
                                context.push(
                                  '/tenant/maintenance',
                                  extra: room.id,
                                );
                              },
                            ),
                            _buildActionIcon(
                              Icons.history_rounded,
                              'Lịch sử',
                              Colors.blue.shade600,
                              () {
                                context.push(
                                  '/tenant/invoices',
                                  extra: room.id,
                                );
                              },
                            ),
                            _buildActionIcon(
                              Icons.description_outlined,
                              'Hợp đồng',
                              Colors.purple.shade500,
                              () {
                                context.push(
                                  '/tenant/contract',
                                  extra: room.id,
                                );
                              },
                            ),
                            _buildActionIcon(
                              Icons.gavel_rounded,
                              'Nội quy',
                              const Color(0xFF2E7D32),
                              () {
                                context.push(
                                  '/tenant/contract',
                                  extra: room.id,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // --- 3. BẢNG TIN TỪ QUẢN LÝ ---
                      const Text(
                        'THÔNG BÁO TỪ QUẢN LÝ',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.grey,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.blue.shade100),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.campaign_rounded,
                                color: Colors.blue.shade700,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Chào mừng bạn đến với khu trọ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.blue.shade900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Mọi thông tin hóa đơn và sự cố phòng sẽ được cập nhật trực tiếp tại ứng dụng này nhé!',
                                    style: TextStyle(
                                      color: Colors.blue.shade800,
                                      fontSize: 13,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // --- 4. CHI TIẾT HÓA ĐƠN ---
                      if (invoice != null) ...[
                        const Text(
                          'CHI TIẾT TIỀN NHÀ THÁNG NÀY',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.grey,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildBillItem(
                                icon: Icons.meeting_room_outlined,
                                color: Colors.blue,
                                title: 'Tiền phòng',
                                subtitle: 'Cố định theo hợp đồng',
                                amount: invoice['rentCost'] ?? 0,
                                format: currencyFormat,
                              ),
                              _buildDivider(),
                              _buildBillItem(
                                icon: Icons.electric_bolt_rounded,
                                color: Colors.orange,
                                title: 'Tiền điện',
                                subtitle:
                                    'Tiêu thụ: ${invoice['electricityUsage'] ?? 0} kWh',
                                amount: invoice['electricityCost'] ?? 0,
                                format: currencyFormat,
                              ),
                              _buildDivider(),
                              _buildBillItem(
                                icon: Icons.water_drop_outlined,
                                color: Colors.cyan,
                                title: 'Tiền nước',
                                subtitle:
                                    'Tiêu thụ: ${invoice['waterUsage'] ?? 0} khối',
                                amount: invoice['waterCost'] ?? 0,
                                format: currencyFormat,
                              ),
                              _buildDivider(),
                              _buildBillItem(
                                icon: Icons.wifi,
                                color: Colors.purple,
                                title: 'Dịch vụ chung',
                                subtitle: 'Internet, Rác, Vệ sinh',
                                amount:
                                    (invoice['internetCost'] ?? 0) +
                                    (invoice['serviceCost'] ?? 0),
                                format: currencyFormat,
                              ),
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF9FAFB),
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(20),
                                    bottomRight: Radius.circular(20),
                                  ),
                                  border: Border(
                                    top: BorderSide(
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'TỔNG CỘNG',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      currencyFormat.format(totalAmount),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 20,
                                        color: isPaid && !isPending
                                            ? Colors.green.shade700
                                            : Colors.red.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // --- WIDGET HELPER ---
  Widget _buildActionIcon(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillItem({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required num amount,
    required NumberFormat format,
  }) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
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
                    fontSize: 15,
                    color: Colors.black87,
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
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 66, right: 20),
      child: Divider(height: 1, color: Colors.grey.shade200),
    );
  }
}
