import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'properties_screen.dart';
import 'data/room_repository.dart';

class EditRoomScreen extends HookConsumerWidget {
  final RoomModel room;

  const EditRoomScreen({super.key, required this.room});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // --- BỘ ĐIỀU KHIỂN (Tự động điền dữ liệu cũ của phòng) ---
    final nameController = useTextEditingController(text: room.name);
    final priceController = useTextEditingController(
      text: room.price.toInt().toString(),
    );
    final areaController = useTextEditingController(
      text: room.area?.toString() ?? '',
    );
    final furnitureController = useTextEditingController(
      text: room.furniture ?? '',
    );
    final descController = useTextEditingController(
      text: room.description ?? '',
    );

    final selectedStatus = useState<String>(room.status.name);
    final isLoading = useState<bool>(false);

    // Hàm hỗ trợ hiển thị thông báo lỗi ngắn gọn
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

    // --- LOGIC CẬP NHẬT DỮ LIỆU (GIỮ NGUYÊN 100%) ---
    Future<void> _submitData() async {
      final name = nameController.text.trim();
      final priceText = priceController.text.trim();

      if (name.isEmpty) return showError('Vui lòng nhập tên phòng.');
      if (priceText.isEmpty) return showError('Vui lòng nhập giá phòng.');

      final rawPrice = priceText.replaceAll(RegExp(r'[., ]'), '');
      final price = double.tryParse(rawPrice);
      if (price == null || price <= 0)
        return showError('Giá phòng sai định dạng.');

      double? area;
      if (areaController.text.trim().isNotEmpty) {
        final rawArea = areaController.text.trim().replaceAll(
          RegExp(r'[., ]'),
          '',
        );
        area = double.tryParse(rawArea);
      }

      try {
        isLoading.value = true;

        final updatedData = {
          'name': name,
          'price': price,
          'status': selectedStatus.value,
          'area': area,
          'furniture': furnitureController.text.trim(),
          'description': descController.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        await ref.read(roomRepositoryProvider).updateRoom(room.id, updatedData);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cập nhật phòng thành công!'),
              backgroundColor: Colors.green,
            ),
          );
          context.pop(); // Quay lại màn hình chi tiết
        }
      } catch (e) {
        showError('Lỗi: $e');
      } finally {
        isLoading.value = false;
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        centerTitle: false,
        title: const Text(
          'Sửa thông tin phòng',
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
            // --- SECTION 1: THÔNG TIN CHÍNH ---
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

            // --- SECTION 2: CHI TIẾT PHÒNG ---
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
            _buildModernInput(
              controller: areaController,
              label: 'Diện tích',
              hint: 'm²',
              icon: Icons.square_foot_outlined,
              isNumber: true,
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

            // --- SECTION 3: TRẠNG THÁI (CHỈ HIỆN NẾU PHÒNG CHƯA CHO THUÊ) ---
            if (room.status != RoomStatus.rented) ...[
              const Text(
                'TRẠNG THÁI PHÒNG',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              _buildStatusToggle(selectedStatus),
            ] else ...[
              // Thông báo nhỏ nếu phòng đang có người thuê
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Phòng đang có khách thuê, không thể thay đổi trạng thái lúc này.',
                        style: TextStyle(
                          color: Colors.blue.shade800,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Khoảng trống dưới cùng để tránh bị che bởi nút
            const SizedBox(height: 100),
          ],
        ),
      ),

      // --- NÚT LƯU THAY ĐỔI ---
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        color: Colors.white, // Nền trắng che mờ nội dung cuộn bên dưới
        child: ElevatedButton(
          onPressed: isLoading.value ? null : _submitData,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1C1C1E), // Màu đen nhám
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
                  'LƯU THAY ĐỔI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
        ),
      ),
    );
  }

  // ========================================================
  // CÁC WIDGET GIAO DIỆN TÙY CHỈNH (ATOMIC COMPONENTS)
  // ========================================================

  // 1. Ô nhập liệu tiêu chuẩn (Border-less, nền xám nhạt)
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
        color: const Color(0xFFF4F5F7), // Xám cực nhạt
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

  // 2. Ô nhập Giá tiền đặc biệt (Nổi bật, Typography lớn)
  Widget _buildPriceInput(TextEditingController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBF9), // Xanh lá cực kỳ nhạt
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

  // 3. Nút Toggle chọn trạng thái phòng (Trống / Bảo trì)
  Widget _buildStatusToggle(ValueNotifier<String> selectedStatus) {
    final isAvailable = selectedStatus.value == 'available';

    return Row(
      children: [
        // Nút Trống
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
        // Nút Bảo trì
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
