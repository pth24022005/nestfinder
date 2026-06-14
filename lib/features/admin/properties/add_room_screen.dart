import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class AddRoomScreen extends HookConsumerWidget {
  const AddRoomScreen({super.key});

  @override
  // ĐÃ SỬA: Bổ sung WidgetRef ref vào hàm build
  Widget build(BuildContext context, WidgetRef ref) {
    // --- BỘ ĐIỀU KHIỂN NHẬP LIỆU ---
    final nameController = useTextEditingController();
    final priceController = useTextEditingController();
    final areaController = useTextEditingController();
    final floorController = useTextEditingController();
    final furnitureController = useTextEditingController();
    final descController = useTextEditingController();

    final selectedStatus = useState<String>('available');
    final isLoading = useState<bool>(false);

    // Hàm hiển thị thông báo nhanh
    void showError(String message) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    // --- LOGIC XỬ LÝ CHẶN TRÙNG & LƯU DỮ LIỆU ---
    // ĐÃ SỬA: Xóa dấu gạch dưới "_" ở đầu tên hàm cục bộ
    Future<void> submitData() async {
      // Ẩn bàn phím khi bấm nút Lưu
      FocusScope.of(context).unfocus();

      final rawName = nameController.text.trim();
      final normalizedName = rawName.toUpperCase(); // "p.101" -> "P.101"

      final priceText = priceController.text.trim();
      final areaText = areaController.text.trim();
      final floorText = floorController.text.trim();
      final furniture = furnitureController.text.trim();
      final desc = descController.text.trim();

      // ĐÃ SỬA: Thêm ngoặc nhọn {} cho tất cả các câu lệnh if
      if (normalizedName.isEmpty) {
        return showError('Vui lòng nhập tên phòng.');
      }
      if (normalizedName.length > 50) {
        return showError('Tên phòng tối đa 50 ký tự.');
      }
      if (priceText.isEmpty) {
        return showError('Vui lòng nhập giá phòng.');
      }

      // Kiểm tra định dạng số giá tiền
      final rawPrice = priceText.replaceAll(RegExp(r'[., ]'), '');
      final price = double.tryParse(rawPrice);
      if (price == null || price <= 0 || price > 1000000000) {
        return showError('Giá phòng phải là số lớn hơn 0 và nhỏ hơn 1 tỷ.');
      }

      double? area;
      if (areaText.isNotEmpty) {
        final rawArea = areaText.replaceAll(RegExp(r'[., ]'), '');
        area = double.tryParse(rawArea);
      }

      try {
        isLoading.value = true;

        // KIỂM TRA TRÙNG LẶP TÊN PHÒNG REALTIME
        final existingRooms = await FirebaseFirestore.instance
            .collection('rooms')
            .where('name', isEqualTo: normalizedName)
            .get();

        if (existingRooms.docs.isNotEmpty) {
          showError('Phòng "$normalizedName" đã tồn tại trên hệ thống!');
          isLoading.value = false;
          return; // Dừng luồng, không cho lưu
        }

        // Đẩy lên Firebase kèm số Tầng và Đơn giá dịch vụ gốc
        await FirebaseFirestore.instance.collection('rooms').add({
          'name': normalizedName,
          'price': price,
          'status': selectedStatus.value,
          'area': area,
          'floor': floorText.isNotEmpty ? floorText : 'Tầng 1', // Lưu số tầng
          'furniture': furniture,
          'description': desc,

          // Gán sẵn đơn giá mặc định để màn hình tính tiền tháng sau không bị lỗi null
          'electricityPrice': 3500.0,
          'waterPrice': 25000.0,
          'internetPrice': 100000.0,
          'servicePrice': 50000.0,

          'createdAt': FieldValue.serverTimestamp(),
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã thêm thành công phòng $normalizedName'),
              backgroundColor: Colors.green,
            ),
          );
          context.pop();
        }
      } catch (e) {
        showError('Lỗi kết nối máy chủ: $e');
      } finally {
        isLoading.value = false;
      }
    }

    // UX: Chạm vào vùng trống bất kỳ để tự động đóng bàn phím ảo
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black87),
          centerTitle: false,
          title: const Text(
            'Thêm phòng mới',
            style: TextStyle(
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
                'THÔNG TIN CHÍNH',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              _buildModernInput(
                controller: nameController,
                label: 'Tên phòng',
                hint: 'VD: P.101',
                icon: Icons.meeting_room_outlined,
              ),
              const SizedBox(height: 16),
              _buildPriceInput(priceController),
              const SizedBox(height: 32),

              const Text(
                'CHI TIẾT PHÒNG',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildModernInput(
                      controller: areaController,
                      label: 'Diện tích',
                      hint: 'm²',
                      icon: Icons.square_foot_outlined,
                      isNumber: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildModernInput(
                      controller: floorController,
                      label: 'Tầng',
                      hint: 'VD: Tầng 1',
                      icon: Icons.layers_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _buildModernInput(
                controller: furnitureController,
                label: 'Nội thất',
                hint: 'Điều hòa, giường, tủ...',
                icon: Icons.weekend_outlined,
              ),
              const SizedBox(height: 16),

              _buildModernInput(
                controller: descController,
                label: 'Mô tả thêm',
                hint: 'Không bắt buộc...',
                icon: Icons.notes_outlined,
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              const Text(
                'TRẠNG THÁI BAN ĐẦU',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              _buildStatusToggle(selectedStatus),
              const SizedBox(height: 100),
            ],
          ),
        ),

        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: ElevatedButton(
              // ĐÃ SỬA: Cập nhật tên hàm gọi ở đây
              onPressed: isLoading.value ? null : submitData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1C1C1E),
                padding: const EdgeInsets.symmetric(vertical: 18),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: isLoading.value
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'LƯU THÔNG TIN PHÒNG',
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
      ),
    );
  }

  Widget _buildModernInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isNumber = false,
    int maxLines = 1,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F5F7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: maxLines > 1
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(top: maxLines > 1 ? 4.0 : 0),
            child: Icon(icon, color: Colors.grey.shade500, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextField(
                  controller: controller,
                  keyboardType: isNumber
                      ? TextInputType.number
                      : TextInputType.text,
                  maxLines: maxLines,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.only(top: 4),
                    border: InputBorder.none,
                    hintText: hint,
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceInput(TextEditingController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBF9),
        border: Border.all(color: const Color(0xFFE8F5E9), width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Giá thuê mỗi tháng',
            style: TextStyle(
              color: Color(0xFF2E7D32),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'đ',
                style: TextStyle(
                  color: Color(0xFF2E7D32),
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    hintText: '0',
                    hintStyle: TextStyle(color: Colors.grey.shade300),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusToggle(ValueNotifier<String> selectedStatus) {
    final isAvailable = selectedStatus.value == 'available';
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => selectedStatus.value = 'available',
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: isAvailable
                    ? const Color(0xFF388E3C)
                    : const Color(0xFFF4F5F7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.check_circle_outline,
                color: isAvailable ? Colors.white : Colors.grey.shade400,
                size: 28,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: InkWell(
            onTap: () => selectedStatus.value = 'maintenance',
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: !isAvailable
                    ? Colors.orange.shade600
                    : const Color(0xFFF4F5F7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.build_circle_outlined,
                color: !isAvailable ? Colors.white : Colors.grey.shade400,
                size: 28,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
