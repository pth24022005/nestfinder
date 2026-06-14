import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Đổi sang HookConsumerWidget để dùng biến trạng thái Loading và Riverpod
class QRPaymentBottomSheet extends HookConsumerWidget {
  final num amount;
  final String roomName;
  // Khai báo thêm 2 biến này để cập nhật Firebase
  final String invoiceId;
  final String roomId;

  const QRPaymentBottomSheet({
    super.key,
    required this.amount,
    required this.roomName,
    required this.invoiceId,
    required this.roomId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final isLoading = useState(false); // Trạng thái nút bấm xoay vòng

    // Thông tin ngân hàng giả lập của Chủ trọ
    const bankName = 'TECHCOMBANK';
    const accountName = 'PHAM THANH HAI';
    const accountNumber = '240205240205';
    final transferContent = 'Thanh toan tien phong $roomName';

    // API tạo mã QR động của VietQR
    final qrImageUrl =
        'https://img.vietqr.io/image/techcombank-$accountNumber-compact2.jpg?amount=${amount.toInt()}&addInfo=${Uri.encodeComponent(transferContent)}&accountName=${Uri.encodeComponent(accountName)}';

    // --- LOGIC XỬ LÝ GỬI THÔNG BÁO VÀ CHỜ DUYỆT ---
    Future<void> submitPaymentVerification() async {
      try {
        isLoading.value = true;
        final firestore = FirebaseFirestore.instance;
        final batch = firestore.batch();

        // 1. Cập nhật hóa đơn sang trạng thái chờ duyệt (pending)
        final invoiceRef = firestore.collection('invoices').doc(invoiceId);
        batch.update(invoiceRef, {'status': 'pending'});

        // 2. Gửi thông báo cho Admin
        final notifRef = firestore.collection('notifications').doc();
        batch.set(notifRef, {
          'title': '💰 Yêu cầu xác nhận thanh toán',
          'message': 'Phòng $roomName báo cáo đã chuyển khoản ${currencyFormat.format(amount)}.',
          'type': 'payment',
          'isRead': false,
          'roomId': roomId,
          'invoiceId': invoiceId,
          'createdAt': FieldValue.serverTimestamp(),
        });

        await batch.commit();

        if (context.mounted) {
          Navigator.pop(context); // Đóng BottomSheet
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã gửi thông báo xác nhận chuyển khoản đến quản lý!'),
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
      } finally {
        isLoading.value = false;
      }
    }

    return Container(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Thanh gạt (Handle)
            Container(
              width: 48,
              height: 5,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            const Text(
              'Thanh toán chuyển khoản',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Quét mã QR bằng ứng dụng ngân hàng',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 32),

            // --- 1. HÌNH ẢNH MÃ QR (VIETQR) ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.blue.shade50, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.05),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  qrImageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const SizedBox(
                      height: 250,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => const SizedBox(
                    height: 250,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image_rounded,
                            size: 48,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Không thể tải mã QR',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // --- 2. THÔNG TIN CHUYỂN KHOẢN (UI TỐI GIẢN) ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F5F7), // Nền xám nhạt gom nhóm thông tin
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  _buildInfoRow(context, 'Ngân hàng', bankName),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1, color: Colors.black12),
                  ),
                  _buildInfoRow(context, 'Chủ tài khoản', accountName),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1, color: Colors.black12),
                  ),
                  _buildInfoRow(
                    context,
                    'Số tài khoản',
                    accountNumber,
                    isCopyable: true,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1, color: Colors.black12),
                  ),
                  _buildInfoRow(
                    context,
                    'Số tiền',
                    currencyFormat.format(amount),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1, color: Colors.black12),
                  ),
                  _buildInfoRow(
                    context,
                    'Nội dung',
                    transferContent,
                    isCopyable: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // --- 3. NÚT XÁC NHẬN ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading.value ? null : submitPaymentVerification,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1C1C1E),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: isLoading.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'TÔI ĐÃ CHUYỂN KHOẢN',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HELPER VỚI NÚT COPY TINH TẾ ---
  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value, {
    bool isCopyable = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ),
              if (isCopyable) ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: value));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Đã sao chép $label'),
                        duration: const Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Colors.blue.shade700,
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.content_copy_rounded,
                      size: 16,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}