import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// =====================================================================
// 1. PROVIDER LẤY DỮ LIỆU PHÒNG & HỢP ĐỒNG HIỆN TẠI
// =====================================================================
final tenantContractProvider =
    StreamProvider.family<Map<String, dynamic>?, String>((ref, roomId) {
      return FirebaseFirestore.instance
          .collection('rooms') // Đọc trực tiếp từ bảng rooms
          .doc(roomId)
          .snapshots()
          .map((doc) {
            if (doc.exists) {
              return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
            }
            return null;
          });
    });

// =====================================================================
// 2. MÀN HÌNH CHI TIẾT HỢP ĐỒNG ĐIỆN TỬ
// =====================================================================
class TenantContractScreen extends HookConsumerWidget {
  final String roomId;

  const TenantContractScreen({super.key, required this.roomId});

  // Hàm hỗ trợ dịch ngày tháng an toàn chống lỗi màn hình đỏ
  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contractAsync = ref.watch(tenantContractProvider(roomId));
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        centerTitle: false,
        title: const Text(
          'Hợp đồng & Nội quy',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 24,
            color: Colors.black87,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: contractAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Lỗi: $err')),
        data: (roomData) {
          if (roomData == null) {
            return const Center(
              child: Text('Không tìm thấy dữ liệu hợp đồng.'),
            );
          }

          final tenantName = roomData['tenantName'] ?? 'Chưa cập nhật';
          final tenantPhone = roomData['tenantPhone'] ?? 'Chưa cập nhật';
          final roomName = roomData['name'] ?? '';
          final rentPrice =
              (roomData['rentPrice'] ?? roomData['price'] ?? 0)
                  as num; // Đề phòng lưu tên trường là price

          // Sử dụng hàm an toàn để parse ngày tháng
          final startDate = _parseDate(roomData['contractStartDate']);
          final endDate = _parseDate(roomData['contractEndDate']);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // --- TỜ GIẤY A4 (THẺ CHỨA HỢP ĐỒNG) ---
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TIÊU ĐỀ
                    Center(
                      child: Column(
                        children: [
                          Text(
                            'CỘNG HÒA XÃ HỘI CHỦ NGHĨA VIỆT NAM',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          Text(
                            'Độc lập - Tự do - Hạnh phúc',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: 150,
                            height: 1,
                            color: Colors.black87,
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'HỢP ĐỒNG THUÊ PHÒNG',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.verified,
                                  color: Colors.green.shade600,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Có hiệu lực',
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // THÔNG TIN CÁC BÊN
                    _buildSectionTitle('1. THÔNG TIN BÊN THUÊ (BÊN B)'),
                    _buildInfoRow('Họ và tên:', tenantName),
                    _buildInfoRow('Số điện thoại:', tenantPhone),
                    _buildInfoRow('Thuê phòng:', roomName),
                    const SizedBox(height: 20),

                    // CHI TIẾT HỢP ĐỒNG
                    _buildSectionTitle('2. CHI TIẾT THUÊ'),
                    _buildInfoRow(
                      'Giá thuê/tháng:',
                      currencyFormat.format(rentPrice),
                      isBold: true,
                    ),
                    _buildInfoRow('Tiền cọc:', 'Đã thu theo thỏa thuận'),
                    _buildInfoRow(
                      'Ngày bắt đầu:',
                      startDate != null ? dateFormat.format(startDate) : '---',
                    ),
                    _buildInfoRow(
                      'Ngày kết thúc:',
                      endDate != null ? dateFormat.format(endDate) : '---',
                    ),
                    const SizedBox(height: 20),

                    // NỘI QUY
                    _buildSectionTitle('3. NỘI QUY CHUNG'),
                    _buildBulletPoint(
                      'Đóng tiền nhà từ ngày 01 đến ngày 05 hàng tháng.',
                    ),
                    _buildBulletPoint(
                      'Giữ gìn vệ sinh chung, không vứt rác bừa bãi.',
                    ),
                    _buildBulletPoint('Giữ yên tĩnh sau 22h00 đêm.'),
                    _buildBulletPoint(
                      'Báo trước 30 ngày nếu có ý định chuyển đi để nhận lại cọc.',
                    ),
                    const SizedBox(height: 32),

                    // CHỮ KÝ ĐIỆN TỬ
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          children: [
                            const Text(
                              'BÊN CHO THUÊ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Icon(
                              Icons.draw_rounded,
                              size: 40,
                              color: Colors.blue.shade300,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Quản lý hệ thống',
                              style: TextStyle(
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            const Text(
                              'BÊN THUÊ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Icon(
                              Icons.fingerprint_rounded,
                              size: 40,
                              color: Colors.green.shade300,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              tenantName,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              // Nút tải PDF
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Tính năng xuất PDF đang được phát triển!',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.download_rounded, color: Colors.white),
                  label: const Text(
                    'Tải bản sao (PDF)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  // --- Các Widget hỗ trợ vẽ giao diện ---
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 15,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isBold ? Colors.blue.shade700 : Colors.black87,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
