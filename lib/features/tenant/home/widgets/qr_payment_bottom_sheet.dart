import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Thư viện để dùng tính năng Copy vào Clipboard
import 'package:intl/intl.dart';

class QRPaymentBottomSheet extends StatelessWidget {
  final num amount;
  final String roomName;

  const QRPaymentBottomSheet({
    super.key,
    required this.amount,
    required this.roomName,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    // Thông tin ngân hàng giả lập của Chủ trọ
    const bankName = 'TECHCOMBANK';
    const accountName = 'PHAM THANH HAI';
    const accountNumber = '240205240205';
    final transferContent = 'Thanh toan tien phong $roomName';

    // API tạo mã QR động của VietQR (truyền sẵn số tiền và nội dung)
    final qrImageUrl =
        'https://img.vietqr.io/image/techcombank-$accountNumber-compact2.jpg?amount=${amount.toInt()}&addInfo=${Uri.encodeComponent(transferContent)}&accountName=${Uri.encodeComponent(accountName)}';

    return Container(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 40),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Thanh gạt (Handle)
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            const Text(
              'Thanh toán chuyển khoản',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Quét mã QR bằng ứng dụng ngân hàng',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // --- 1. HÌNH ẢNH MÃ QR ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.shade100, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.1),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  qrImageUrl,
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                  // Hiển thị vòng xoay trong lúc tải ảnh QR từ mạng về
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const SizedBox(
                      width: 200,
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  },
                  // Xử lý lỗi nếu mất mạng
                  errorBuilder: (context, error, stackTrace) => const SizedBox(
                    width: 200,
                    height: 200,
                    child: Center(
                      child: Icon(
                        Icons.broken_image,
                        size: 50,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- 2. THÔNG TIN CHUYỂN KHOẢN (VỚI NÚT COPY) ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _buildInfoRow(context, 'Ngân hàng', bankName),
                  const Divider(height: 24),
                  _buildInfoRow(context, 'Chủ tài khoản', accountName),
                  const Divider(height: 24),
                  _buildInfoRow(
                    context,
                    'Số tài khoản',
                    accountNumber,
                    isCopyable: true,
                  ),
                  const Divider(height: 24),
                  _buildInfoRow(
                    context,
                    'Số tiền',
                    currencyFormat.format(amount),
                  ),
                  const Divider(height: 24),
                  _buildInfoRow(
                    context,
                    'Nội dung',
                    transferContent,
                    isCopyable: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Hàm hỗ trợ vẽ từng dòng thông tin (Kèm tính năng copy)
  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value, {
    bool isCopyable = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              if (isCopyable) ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    // Lệnh copy text vào bộ nhớ tạm của điện thoại
                    Clipboard.setData(ClipboardData(text: value));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Đã sao chép $label'),
                        duration: const Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: const Icon(Icons.copy, size: 18, color: Colors.blue),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
