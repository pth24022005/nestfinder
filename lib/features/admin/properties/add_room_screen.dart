import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class AddRoomScreen extends HookConsumerWidget {
  const AddRoomScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Các bộ điều khiển nhập liệu (Controllers)
    final nameController = useTextEditingController();
    final priceController = useTextEditingController();
    final areaController = useTextEditingController();
    final furnitureController = useTextEditingController();
    final descController = useTextEditingController();

    final selectedStatus = useState<String>('available');
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

    // Hàm đẩy lên Firebase (Chuẩn dự án thực tế)
    Future<void> _submitData() async {
      // 1. Lấy dữ liệu và cắt bỏ khoảng trắng thừa ở hai đầu
      final name = nameController.text.trim();
      final priceText = priceController.text.trim();
      final areaText = areaController.text.trim();
      final furniture = furnitureController.text.trim();
      final desc = descController.text.trim();

      // --- BƯỚC 1: VALIDATE DỮ LIỆU BẮT BUỘC ---
      if (name.isEmpty) return showError('Vui lòng nhập tên phòng.');
      if (name.length > 50)
        return showError('Tên phòng quá dài (tối đa 50 ký tự).');

      if (priceText.isEmpty) return showError('Vui lòng nhập giá phòng.');

      // --- BƯỚC 2: VALIDATE ĐỊNH DẠNG SỐ (GIÁ TIỀN) ---
      final rawPrice = priceText.replaceAll(RegExp(r'[., ]'), '');
      final price = double.tryParse(rawPrice);

      if (price == null) {
        return showError('Giá phòng sai định dạng. Vui lòng chỉ nhập số.');
      }
      if (price <= 0 || price > 1000000000) {
        return showError('Giá phòng phải lớn hơn 0 và dưới 1 tỷ.');
      }

      // --- BƯỚC 3: VALIDATE DỮ LIỆU TỰ CHỌN ---
      double? area;
      if (areaText.isNotEmpty) {
        final rawArea = areaText.replaceAll(RegExp(r'[., ]'), '');
        area = double.tryParse(rawArea);
        if (area == null || area <= 0 || area > 1000) {
          return showError('Diện tích sai định dạng hoặc không hợp lý.');
        }
      }

      if (furniture.length > 200)
        return showError('Nội thất quá dài (tối đa 200 ký tự).');
      if (desc.length > 500)
        return showError('Mô tả quá dài (tối đa 500 ký tự).');

      // --- BƯỚC 4: LƯU VÀO CƠ SỞ DỮ LIỆU ---
      try {
        isLoading.value = true;

        await FirebaseFirestore.instance.collection('rooms').add({
          'name': name,
          'price': price, // Đã là số nguyên thủy, cực kỳ an toàn
          'status': selectedStatus.value,
          'area': area,
          'furniture': furniture,
          'description': desc,
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã thêm thành công $name'),
              backgroundColor: Colors.green,
            ),
          );
          context.pop(); // Quay lại màn hình trước
        }
      } catch (e) {
        showError('Lỗi kết nối máy chủ: $e');
      } finally {
        isLoading.value = false;
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Thêm phòng trọ mới',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin bắt buộc',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Tên và Giá nằm trên 1 hàng cho gọn
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: nameController,
                    label: 'Tên phòng (VD: P.101)',
                    icon: Icons.meeting_room,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: priceController,
                    label: 'Giá (VNĐ)',
                    icon: Icons.monetization_on,
                    isNumber: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            const Text(
              'Thông tin chi tiết',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: areaController,
              label: 'Diện tích (m2)',
              icon: Icons.square_foot,
              isNumber: true,
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: furnitureController,
              label: 'Nội thất (VD: Điều hòa, giường, tủ...)',
              icon: Icons.chair_alt,
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: descController,
              label: 'Mô tả thêm (Không bắt buộc)',
              icon: Icons.description,
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            const Text(
              'Trạng thái ban đầu:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildStatusRadio(
                  selectedStatus,
                  'available',
                  'Phòng trống',
                  Colors.green,
                ),
                const SizedBox(width: 12),
                _buildStatusRadio(
                  selectedStatus,
                  'maintenance',
                  'Bảo trì',
                  Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
      // Thanh nút bấm cố định dưới cùng
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: isLoading.value ? null : _submitData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isLoading.value
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Lưu thông tin phòng',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  // Hàm hỗ trợ vẽ TextField cho gọn code
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isNumber = false,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: maxLines == 1
            ? Icon(icon)
            : Padding(
                padding: const EdgeInsets.only(bottom: 48),
                child: Icon(icon),
              ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  Widget _buildStatusRadio(
    ValueNotifier<String> selectedStatus,
    String value,
    String label,
    Color color,
  ) {
    final isSelected = selectedStatus.value == value;
    return InkWell(
      onTap: () => selectedStatus.value = value,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          border: Border.all(color: isSelected ? color : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
