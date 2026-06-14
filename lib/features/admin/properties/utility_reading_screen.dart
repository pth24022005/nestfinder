import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'properties_screen.dart';

class UtilityReadingScreen extends HookConsumerWidget {
  final RoomModel room;

  const UtilityReadingScreen({super.key, required this.room});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Khởi tạo dữ liệu
    final oldElectricity = room.electricityIndex ?? 0;
    final oldWater = room.waterIndex ?? 0;

    final newElecController = useTextEditingController();
    final newWaterController = useTextEditingController();
    final isSubmitting = useState(false);

    // Hàm hỗ trợ thông báo
    void showError(String message, {bool isWarning = false}) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: isWarning ? Colors.orange.shade700 : Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    // 2. Logic Xử lý Chốt số & Tạo hóa đơn (Giữ nguyên 100%)
    Future<void> submitReading() async {
      FocusScope.of(context).unfocus();

      final newElecStr = newElecController.text.trim();
      final newWaterStr = newWaterController.text.trim();

      if (newElecStr.isEmpty || newWaterStr.isEmpty) {
        return showError('Vui lòng nhập đầy đủ số điện và số nước mới!');
      }

      final newElec = int.tryParse(newElecStr);
      final newWater = int.tryParse(newWaterStr);

      if (newElec == null || newWater == null) {
        return showError('Chỉ số nhập vào phải là con số hợp lệ!');
      }

      if (newElec < oldElectricity || newWater < oldWater) {
        return showError('Số mới KHÔNG ĐƯỢC nhỏ hơn số cũ!', isWarning: true);
      }

      isSubmitting.value = true;
      try {
        final firestore = FirebaseFirestore.instance;
        final batch = firestore.batch();

        // TÍNH TOÁN TIỀN NONG
        final elecPrice = room.electricityPrice ?? 3500.0;
        final waterPrice = room.waterPrice ?? 25000.0;
        final internetPrice = room.internetPrice ?? 100000.0;
        final servicePrice = room.servicePrice ?? 50000.0;

        final elecUsage = newElec - oldElectricity;
        final waterUsage = newWater - oldWater;

        final elecCost = elecUsage * elecPrice;
        final waterCost = waterUsage * waterPrice;

        // Tổng tiền
        final totalBill =
            room.price + elecCost + waterCost + internetPrice + servicePrice;

        // LỆNH 1: CẬP NHẬT SỐ ĐIỆN NƯỚC MỚI CHO PHÒNG
        final roomRef = firestore.collection('rooms').doc(room.id);
        batch.update(roomRef, {
          'electricityIndex': newElec,
          'waterIndex': newWater,
        });

        // LỆNH 2: TẠO HÓA ĐƠN
        final invoiceRef = firestore.collection('invoices').doc();
        final currentMonth = DateTime.now();

        batch.set(invoiceRef, {
          'roomId': room.id,
          'roomName': room.name,
          'tenantName': room.tenantName,
          'month': currentMonth.month,
          'year': currentMonth.year,
          'rentCost': room.price,
          'electricityUsage': elecUsage,
          'electricityCost': elecCost,
          'waterUsage': waterUsage,
          'waterCost': waterCost,
          'internetCost': internetPrice,
          'serviceCost': servicePrice,
          'totalAmount': totalBill,
          'status': 'unpaid',
          'createdAt': FieldValue.serverTimestamp(),
        });

        // THỰC THI BATCH
        await batch.commit();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã chốt số và xuất hóa đơn thành công!'),
              backgroundColor: Colors.green,
            ),
          );
          context.pop();
        }
      } catch (e) {
        showError('Lỗi kết nối máy chủ: $e');
      } finally {
        isSubmitting.value = false;
      }
    }

    // 3. GIAO DIỆN CHÍNH
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black87),
          centerTitle: false,
          title: Text(
            'Chốt số - ${room.name}',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 24,
              color: Colors.black87,
              letterSpacing: -0.5,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'NHẬP CHỈ SỐ THÁNG NÀY',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),

              // Thẻ Điện
              _buildModernReadingCard(
                title: 'Điện năng tiêu thụ (kWh)',
                icon: Icons.bolt,
                iconColor: Colors.orange.shade500,
                iconBg: Colors.orange.shade50,
                oldValue: oldElectricity,
                newController: newElecController,
              ),

              const SizedBox(height: 24),

              // Thẻ Nước
              _buildModernReadingCard(
                title: 'Nước sinh hoạt (m³)',
                icon: Icons.water_drop,
                iconColor: Colors.blue.shade500,
                iconBg: Colors.blue.shade50,
                oldValue: oldWater,
                newController: newWaterController,
              ),

              const SizedBox(height: 100), // Không gian cuộn dưới cùng
            ],
          ),
        ),

        // --- NÚT XÁC NHẬN ---
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          color: Colors.white,
          child: ElevatedButton(
            onPressed: isSubmitting.value ? null : submitReading,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1C1C1E), // Đen nhám
              padding: const EdgeInsets.symmetric(vertical: 18),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: isSubmitting.value
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'XUẤT HÓA ĐƠN THÁNG NÀY',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // WIDGET UI HỖ TRỢ (THẺ CHỐT SỐ CHUẨN NESTFINDER)
  // ==========================================
  Widget _buildModernReadingCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required int oldValue,
    required TextEditingController newController,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề & Icon
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Row chứa Số Cũ và Số Mới
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Cột: Số cũ (Chỉ đọc)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Số tháng trước',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors
                            .grey
                            .shade50, // Nền xám nhạt thể hiện việc không thể sửa
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Text(
                        oldValue.toString(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Padding(
                  padding: EdgeInsets.only(
                    top: 20,
                  ), // Đẩy icon xuống cân bằng với box input
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.grey,
                    size: 20,
                  ),
                ),
              ),

              // Cột: Số mới (Nhập liệu)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chỉ số mới',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50.withValues(
                          alpha: 0.5,
                        ), // Nền xanh nhạt nổi bật
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: TextField(
                        controller: newController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.blue,
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 13,
                          ),
                          border: InputBorder.none,
                          hintText: 'Nhập...',
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.normal,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
