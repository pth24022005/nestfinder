import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// =====================================================================
// 1. PROVIDER LẤY LỊCH SỬ HÓA ĐƠN (XỬ LÝ SORT BẰNG DART ĐỂ TRÁNH LỖI INDEX)
// =====================================================================
final tenantInvoiceHistoryProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, roomId) {
      return FirebaseFirestore.instance
          .collection('invoices')
          .where('roomId', isEqualTo: roomId)
          .snapshots()
          .map((snapshot) {
            final list = snapshot.docs
                .map((doc) => {'id': doc.id, ...doc.data()})
                .toList();

            // Tự sắp xếp hóa đơn mới nhất lên đầu (Dùng createdAt)
            list.sort((a, b) {
              final dateA =
                  (a['createdAt'] as Timestamp?)?.toDate() ??
                  DateTime.fromMillisecondsSinceEpoch(0);
              final dateB =
                  (b['createdAt'] as Timestamp?)?.toDate() ??
                  DateTime.fromMillisecondsSinceEpoch(0);
              return dateB.compareTo(dateA);
            });

            return list;
          });
    });

// =====================================================================
// 2. MÀN HÌNH DANH SÁCH LỊCH SỬ HÓA ĐƠN
// =====================================================================
class TenantInvoiceHistoryScreen extends HookConsumerWidget {
  final String roomId;

  const TenantInvoiceHistoryScreen({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoicesAsync = ref.watch(tenantInvoiceHistoryProvider(roomId));

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        centerTitle: false,
        title: const Text(
          'Lịch sử hóa đơn',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 24,
            color: Colors.black87,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: invoicesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Lỗi tải dữ liệu: $err')),
        data: (invoices) {
          if (invoices.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có hóa đơn nào',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: invoices.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return _ExpandableInvoiceCard(invoice: invoices[index]);
            },
          );
        },
      ),
    );
  }
}

// =====================================================================
// 3. THẺ HÓA ĐƠN THÔNG MINH (CÓ THỂ MỞ RỘNG)
// =====================================================================
class _ExpandableInvoiceCard extends HookWidget {
  final Map<String, dynamic> invoice;

  const _ExpandableInvoiceCard({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final isExpanded = useState(false);
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    final month = invoice['month'] ?? 1;
    final year = invoice['year'] ?? 2026;
    final totalAmount = (invoice['totalAmount'] ?? 0) as num;
    final isPaid = invoice['status'] == 'paid';

    final rentCost = (invoice['rentCost'] ?? 0) as num;
    final elecCost = (invoice['electricityCost'] ?? 0) as num;
    final elecUsage = (invoice['electricityUsage'] ?? 0) as num;
    final waterCost = (invoice['waterCost'] ?? 0) as num;
    final waterUsage = (invoice['waterUsage'] ?? 0) as num;
    final internetCost = (invoice['internetCost'] ?? 0) as num;
    final serviceCost = (invoice['serviceCost'] ?? 0) as num;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isExpanded.value ? Colors.blue.shade100 : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            // --- PHẦN HEADER (Luôn hiển thị) ---
            InkWell(
              onTap: () => isExpanded.value = !isExpanded.value,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Icon hóa đơn
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isPaid
                            ? Colors.green.shade50
                            : Colors.red.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isPaid
                            ? Icons.check_circle_outline
                            : Icons.warning_amber_rounded,
                        color: isPaid
                            ? Colors.green.shade600
                            : Colors.red.shade600,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Tháng & Số tiền
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tháng $month/$year',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isPaid ? 'Đã thanh toán' : 'Chưa thanh toán',
                            style: TextStyle(
                              color: isPaid
                                  ? Colors.green.shade600
                                  : Colors.red.shade600,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Tổng tiền & Mũi tên
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          currencyFormat.format(totalAmount),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Icon(
                          isExpanded.value
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: Colors.grey.shade400,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // --- PHẦN CHI TIẾT (Trượt mở ra) ---
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity, height: 0),
              secondChild: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  border: Border(top: BorderSide(color: Colors.grey.shade100)),
                ),
                child: Column(
                  children: [
                    _buildDetailRow(
                      'Tiền phòng',
                      currencyFormat.format(rentCost),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      'Điện ($elecUsage kWh)',
                      currencyFormat.format(elecCost),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      'Nước ($waterUsage khối)',
                      currencyFormat.format(waterCost),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      'Internet & Dịch vụ',
                      currencyFormat.format(internetCost + serviceCost),
                    ),
                  ],
                ),
              ),
              crossFadeState: isExpanded.value
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
