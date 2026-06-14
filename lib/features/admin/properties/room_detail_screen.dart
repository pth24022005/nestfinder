import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'properties_screen.dart';
import 'data/room_repository.dart';

// Bộ Radar lắng nghe hóa đơn mới nhất của 1 phòng
final latestInvoiceProvider =
    StreamProvider.family<Map<String, dynamic>?, String>((ref, roomId) {
      return FirebaseFirestore.instance
          .collection('invoices')
          .where('roomId', isEqualTo: roomId)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs.isNotEmpty ? snapshot.docs.first.data() : null,
          );
    });

class RoomDetailScreen extends ConsumerWidget {
  final RoomModel room;

  const RoomDetailScreen({super.key, required this.room});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final dateFormat = DateFormat('dd/MM/yyyy');
    final roomListAsync = ref.watch(roomListStreamProvider);

    final liveRoom = roomListAsync.maybeWhen(
      data: (rooms) =>
          rooms.firstWhere((r) => r.id == room.id, orElse: () => room),
      orElse: () => room,
    );

    final invoiceAsync = ref.watch(latestInvoiceProvider(liveRoom.id));
    final now = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    final isLast3Days = now.day >= (daysInMonth - 3);

    Future<void> handleCheckout() async {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Xác nhận trả phòng',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Bạn có chắc chắn muốn kết thúc hợp đồng và làm thủ tục trả phòng cho ${liveRoom.name}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              style: TextButton.styleFrom(backgroundColor: Colors.red.shade50),
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Xác nhận trả',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );

      if (confirm == true) {
        try {
          final clearData = {
            'status': 'available',
            'tenantName': null,
            'tenantPhone': null,
            'tenantCCCD': null,
            'tenantAddress': null,
            'contractDeposit': null,
            'contractStartDate': null,
            'contractEndDate': null,
            'rentedAt': null,
          };
          await ref
              .read(roomRepositoryProvider)
              .updateRoom(liveRoom.id, clearData);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đã hoàn tất thủ tục trả phòng!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
            );
          }
        }
      }
    }

    final Color bgColor = const Color(0xFFF4F6F9);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: InkWell(
              onTap: () => context.push(
                '/admin/properties/detail/edit',
                extra: liveRoom,
              ),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit, size: 20, color: Colors.black87),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  liveRoom.name,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                    letterSpacing: -0.5,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: liveRoom.status.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        liveRoom.status == RoomStatus.available
                            ? Icons.check_circle
                            : Icons.info,
                        color: liveRoom.status.color,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        liveRoom.status.label,
                        style: TextStyle(
                          color: liveRoom.status.color,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: _buildSquareInfoCard(
                    icon: Icons.payments_outlined,
                    iconBg: Colors.blue.shade50,
                    iconColor: Colors.blue.shade600,
                    label: 'Giá thuê/tháng',
                    value: currencyFormat.format(liveRoom.price),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSquareInfoCard(
                    icon: Icons.square_foot_outlined,
                    iconBg: Colors.orange.shade50,
                    iconColor: Colors.orange.shade600,
                    label: 'Diện tích',
                    value: liveRoom.area != null && liveRoom.area! > 0
                        ? '${liveRoom.area} m²'
                        : '---',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.weekend_outlined,
                      color: Colors.grey.shade600,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Nội thất cung cấp',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          liveRoom.furniture?.isNotEmpty == true
                              ? liveRoom.furniture!
                              : 'Phòng trống',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            if (liveRoom.status == RoomStatus.rented &&
                liveRoom.tenantName != null) ...[
              const Text(
                'HỒ SƠ KHÁCH THUÊ',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.blueAccent.shade400,
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                liveRoom.tenantName!,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                liveRoom.tenantPhone ?? '---',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () => context.push(
                            '/admin/properties/detail/edit-tenant',
                            extra: liveRoom,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.edit,
                              size: 16,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Divider(height: 1, color: Color(0xFFEEEEEE)),
                    ),

                    _buildTenantDetailRow(
                      Icons.badge_outlined,
                      'CCCD',
                      liveRoom.tenantCCCD ?? '---',
                    ),
                    const SizedBox(height: 16),
                    _buildTenantDetailRow(
                      Icons.home_outlined,
                      'Thường trú',
                      liveRoom.tenantAddress ?? '---',
                    ),
                    const SizedBox(height: 16),
                    _buildTenantDetailRow(
                      Icons.calendar_month_outlined,
                      'Thời hạn hợp đồng',
                      liveRoom.contractStartDate != null &&
                              liveRoom.contractEndDate != null
                          ? '${dateFormat.format(liveRoom.contractStartDate!)} - ${dateFormat.format(liveRoom.contractEndDate!)}'
                          : '---',
                      valueColor: Colors.blue.shade700,
                    ),

                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () => context.push(
                              '/admin/properties/detail/contract',
                              extra: liveRoom,
                            ),
                            icon: Icon(
                              Icons.history,
                              size: 18,
                              color: Colors.blue.shade700,
                            ),
                            label: Text(
                              'Gia hạn HĐ',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.blue.shade50,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextButton.icon(
                            onPressed: handleCheckout,
                            icon: Icon(
                              Icons.logout,
                              size: 18,
                              color: Colors.red.shade700,
                            ),
                            label: Text(
                              'Trả phòng',
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.red.shade50,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(
              height: 100,
            ), // Cắt lề đáy để cuộn không bị che bởi nút
          ],
        ),
      ),

      // --- NÚT BOTTOM (PHÂN NHÁNH CHUẨN LOGIC) ---
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Builder(
            builder: (context) {
              // 1. NẾU LÀ PHÒNG TRỐNG -> Hiện nút Thêm Khách / Tạo Hợp Đồng
              if (liveRoom.status == RoomStatus.available) {
                return ElevatedButton.icon(
                  onPressed: () {
                    // Nhảy sang màn hình tạo hợp đồng (cũng là màn hình nạp thông tin khách)
                    context.push(
                      '/admin/properties/detail/contract',
                      extra: liveRoom,
                    );
                  },
                  icon: const Icon(
                    Icons.person_add_alt_1,
                    color: Colors.white,
                    size: 20,
                  ),
                  label: const Text(
                    'THÊM KHÁCH THUÊ',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(
                      0xFF2E7D32,
                    ), // Màu Xanh lá NestFinder
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                );
              }

              // 2. NẾU LÀ PHÒNG BẢO TRÌ -> Ẩn luôn nút
              if (liveRoom.status == RoomStatus.maintenance) {
                return const SizedBox.shrink();
              }

              // 3. NẾU ĐÃ CÓ KHÁCH -> Logic Chốt điện nước / Hóa đơn
              return invoiceAsync.when(
                loading: () => const SizedBox(
                  height: 56,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, stack) => Text('Lỗi: $err'),
                data: (latestInvoice) {
                  bool isSubmitMode = false;
                  String buttonLabel = '';
                  Color buttonColor = const Color(0xFF1E3A8A); // Màu Dark Blue
                  IconData buttonIcon = Icons.receipt_long;

                  if (latestInvoice != null) {
                    final invMonth = latestInvoice['month'];
                    final invYear = latestInvoice['year'];

                    if (invMonth == now.month && invYear == now.year) {
                      isSubmitMode = false;
                      buttonLabel = 'XEM HÓA ĐƠN THÁNG $invMonth';
                      buttonColor = const Color(0xFF10B981); // Xanh lá cây nhạt
                      buttonIcon = Icons.visibility;
                    } else {
                      if (isLast3Days) {
                        isSubmitMode = true;
                        buttonLabel = 'CHỐT ĐIỆN NƯỚC THÁNG ${now.month}';
                        buttonIcon = Icons.flash_on;
                      } else {
                        isSubmitMode = false;
                        buttonLabel = 'XEM HÓA ĐƠN THÁNG $invMonth';
                        buttonColor = Colors.grey.shade800;
                        buttonIcon = Icons.history;
                      }
                    }
                  } else {
                    isSubmitMode = true;
                    buttonLabel = 'CHỐT ĐIỆN NƯỚC (KỲ ĐẦU TIÊN)';
                    buttonIcon = Icons.receipt;
                  }

                  return ElevatedButton.icon(
                    onPressed: () {
                      if (isSubmitMode) {
                        context.push(
                          '/admin/properties/detail/reading',
                          extra: room,
                        );
                      } else {
                        _showInvoiceDialog(context, latestInvoice!);
                      }
                    },
                    icon: Icon(buttonIcon, color: Colors.white, size: 20),
                    label: Text(
                      buttonLabel,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  // ==========================================
  // UI HELPER WIDGETS
  // ==========================================

  Widget _buildSquareInfoCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
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

  Widget _buildTenantDetailRow(
    IconData icon,
    String label,
    String value, {
    Color valueColor = Colors.black87,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade400),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showInvoiceDialog(
    BuildContext context,
    Map<String, dynamic> invoiceData,
  ) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final createdAt =
        (invoiceData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.receipt_long,
                    size: 40,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'HÓA ĐƠN TIỀN NHÀ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Kỳ thanh toán: Tháng ${invoiceData['month']}/${invoiceData['year']}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                const SizedBox(height: 24),
                const Divider(color: Colors.grey, thickness: 1),
                const SizedBox(height: 16),
                _buildInvoiceRow(
                  'Tiền phòng',
                  currencyFormat.format(invoiceData['rentCost'] ?? 0),
                ),
                const SizedBox(height: 12),
                _buildInvoiceRow(
                  'Tiền điện (${invoiceData['electricityUsage']} số)',
                  currencyFormat.format(invoiceData['electricityCost'] ?? 0),
                ),
                const SizedBox(height: 12),
                _buildInvoiceRow(
                  'Tiền nước (${invoiceData['waterUsage']} khối)',
                  currencyFormat.format(invoiceData['waterCost'] ?? 0),
                ),
                const SizedBox(height: 12),
                _buildInvoiceRow(
                  'Tiền mạng',
                  currencyFormat.format(invoiceData['internetCost'] ?? 0),
                ),
                const SizedBox(height: 12),
                _buildInvoiceRow(
                  'Phí dịch vụ',
                  currencyFormat.format(invoiceData['serviceCost'] ?? 0),
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.grey, thickness: 1),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TỔNG CỘNG',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      currencyFormat.format(invoiceData['totalAmount'] ?? 0),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: invoiceData['status'] == 'paid'
                        ? Colors.green.shade50
                        : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: invoiceData['status'] == 'paid'
                          ? Colors.green
                          : Colors.orange,
                    ),
                  ),
                  child: Text(
                    invoiceData['status'] == 'paid'
                        ? 'Đã thanh toán'
                        : 'Chưa thanh toán',
                    style: TextStyle(
                      color: invoiceData['status'] == 'paid'
                          ? Colors.green.shade700
                          : Colors.orange.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Ngày chốt: ${dateFormat.format(createdAt)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.grey.shade100,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Đóng',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInvoiceRow(String label, String amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
        ),
        Text(
          amount,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ],
    );
  }
}
