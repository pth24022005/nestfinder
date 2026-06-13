import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'properties_screen.dart'; // Import file chứa RoomModel của bạn

class UtilityReadingScreen extends HookConsumerWidget {
  final RoomModel room;

  const UtilityReadingScreen({super.key, required this.room});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Khởi tạo dữ liệu và Trạng thái
    // Nếu phòng chưa có chỉ số cũ (null) thì mặc định là 0
    final oldElectricity = room.electricityIndex ?? 0;
    final oldWater = room.waterIndex ?? 0;

    final newElecController = useTextEditingController();
    final newWaterController = useTextEditingController();
    final isSubmitting = useState(false); // Trạng thái nút bấm xoay loading

    // 2. Hàm xử lý Logic khi bấm nút "Xác nhận"
    // Hàm xử lý Logic khi bấm nút "Xác nhận & Gửi thông báo"
    Future<void> _submitReading() async {
      FocusScope.of(context).unfocus();

      final newElecStr = newElecController.text.trim();
      final newWaterStr = newWaterController.text.trim();

      if (newElecStr.isEmpty || newWaterStr.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng nhập đầy đủ số mới!'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final newElec = int.tryParse(newElecStr);
      final newWater = int.tryParse(newWaterStr);

      if (newElec == null || newWater == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chỉ số phải là con số hợp lệ!'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (newElec < oldElectricity || newWater < oldWater) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lỗi: Số mới không được nhỏ hơn số cũ!'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      isSubmitting.value = true;
      try {
        final firestore = FirebaseFirestore.instance;
        final batch = firestore
            .batch(); // Dùng Batch để chạy 2 lệnh lưu cùng 1 lúc

        // 1. TÍNH TOÁN TIỀN NONG (Lấy giá từ phòng, nếu phòng chưa cài đặt thì lấy giá mặc định)
        final elecPrice = room.electricityPrice ?? 3500.0; // Mặc định 3500đ/số
        final waterPrice = room.waterPrice ?? 25000.0; // Mặc định 25k/khối
        final internetPrice =
            room.internetPrice ?? 100000.0; // Mặc định 100k/tháng
        final servicePrice = room.servicePrice ?? 50000.0; // Mặc định 50k/tháng

        final elecUsage = newElec - oldElectricity;
        final waterUsage = newWater - oldWater;

        final elecCost = elecUsage * elecPrice;
        final waterCost = waterUsage * waterPrice;

        // Tổng tiền = Tiền phòng + Điện + Nước + Mạng + Dịch vụ
        final totalBill =
            room.price + elecCost + waterCost + internetPrice + servicePrice;

        // 2. LỆNH 1: CẬP NHẬT SỐ ĐIỆN NƯỚC MỚI CHO PHÒNG
        final roomRef = firestore.collection('rooms').doc(room.id);
        batch.update(roomRef, {
          'electricityIndex': newElec,
          'waterIndex': newWater,
        });

        // 3. LỆNH 2: TẠO HÓA ĐƠN MỚI TRONG BẢNG 'invoices'
        final invoiceRef = firestore.collection('invoices').doc();
        final currentMonth = DateTime.now();

        batch.set(invoiceRef, {
          'roomId': room.id,
          'roomName': room.name,
          'tenantName': room.tenantName,
          'month': currentMonth.month,
          'year': currentMonth.year,

          // Chi tiết các khoản thu
          'rentCost': room.price,
          'electricityUsage': elecUsage,
          'electricityCost': elecCost,
          'waterUsage': waterUsage,
          'waterCost': waterCost,
          'internetCost': internetPrice,
          'serviceCost': servicePrice,
          'totalAmount': totalBill,

          'status': 'unpaid', // Trạng thái: Chưa thanh toán
          'createdAt': FieldValue.serverTimestamp(),
        });

        // 4. THỰC THI TOÀN BỘ LỆNH
        await batch.commit();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã chốt số và xuất hóa đơn thành công!'),
              backgroundColor: Colors.green,
            ),
          );
          context.pop(); // Quay về màn hình Chi tiết phòng
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        isSubmitting.value = false;
      }
    }

    // 3. GIAO DIỆN
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Chốt điện nước ${room.name}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Thẻ nhập Chỉ số Điện
            _buildReadingCard(
              title: 'Chỉ số Điện (kWh)',
              icon: Icons.bolt,
              iconColor: Colors.orange,
              oldValue: oldElectricity,
              newController: newElecController,
            ),

            const SizedBox(height: 16),

            // Thẻ nhập Chỉ số Nước
            _buildReadingCard(
              title: 'Chỉ số Nước (m³)',
              icon: Icons.water_drop,
              iconColor: Colors.blue,
              oldValue: oldWater,
              newController: newWaterController,
            ),
          ],
        ),
      ),

      // Nút Xác nhận ghim dưới cùng
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: isSubmitting.value ? null : _submitReading,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
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
                    'Xác nhận & Gửi thông báo',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  // Khung UI chuẩn cho 1 khối chốt điện/nước (Tái sử dụng)
  Widget _buildReadingCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required int oldValue,
    required TextEditingController newController,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Ô chứa SỐ CŨ (Màu xám, khóa không cho nhập)
              Expanded(
                child: TextField(
                  controller: TextEditingController(text: oldValue.toString()),
                  readOnly: true, // Khóa
                  decoration: InputDecoration(
                    labelText: 'Số cũ',
                    filled: true,
                    fillColor: Colors.grey.shade100, // Nền xám
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.arrow_forward, color: Colors.grey),
              ),

              // Ô chứa SỐ MỚI (Màu trắng, cho phép nhập số)
              Expanded(
                child: TextField(
                  controller: newController,
                  keyboardType: TextInputType.number, // Bật bàn phím số
                  decoration: InputDecoration(
                    labelText: 'Số mới',
                    hintText: 'Nhập số...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
