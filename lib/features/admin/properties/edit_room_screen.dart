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
    // Tự động điền dữ liệu CŨ của tất cả các trường
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

    void showError(String message) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    }

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
        title: Text(
          'Sửa thông tin - ${room.name}',
          style: const TextStyle(fontWeight: FontWeight.bold),
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
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: nameController,
                    label: 'Tên phòng',
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
              label: 'Nội thất',
              icon: Icons.chair_alt,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: descController,
              label: 'Mô tả',
              icon: Icons.description,
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            if (room.status != RoomStatus.rented) ...[
              const Text(
                'Trạng thái:',
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
          ],
        ),
      ),
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
                      'Lưu thay đổi',
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
