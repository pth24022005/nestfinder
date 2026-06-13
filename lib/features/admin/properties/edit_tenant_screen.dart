import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'properties_screen.dart';
import 'data/room_repository.dart';

class EditTenantScreen extends HookConsumerWidget {
  final RoomModel room;

  const EditTenantScreen({super.key, required this.room});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Tự động điền dữ liệu cũ vào các ô nhập liệu
    final nameController = useTextEditingController(text: room.tenantName);
    final phoneController = useTextEditingController(text: room.tenantPhone);
    final cccdController = useTextEditingController(text: room.tenantCCCD);
    final addressController = useTextEditingController(
      text: room.tenantAddress,
    );
    final isLoading = useState<bool>(false);

    Future<void> _submitUpdate() async {
      final name = nameController.text.trim();
      final phone = phoneController.text.trim();

      if (name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tên không được để trống'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      try {
        isLoading.value = true;
        // Chỉ cập nhật các trường liên quan đến thông tin cá nhân khách
        final updateData = {
          'tenantName': name,
          'tenantPhone': phone,
          'tenantCCCD': cccdController.text.trim(),
          'tenantAddress': addressController.text.trim(),
          'tenantUpdatedAt': FieldValue.serverTimestamp(),
        };

        await ref.read(roomRepositoryProvider).updateRoom(room.id, updateData);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cập nhật khách thuê thành công!'),
              backgroundColor: Colors.green,
            ),
          );
          context.pop();
        }
      } catch (e) {
        if (context.mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
          );
      } finally {
        isLoading.value = false;
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Sửa khách thuê - ${room.name}',
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
              'Hồ sơ khách thuê',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: nameController,
              label: 'Họ và tên',
              icon: Icons.person,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: phoneController,
              label: 'Số điện thoại',
              icon: Icons.phone,
              isNumber: true,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: cccdController,
              label: 'Số CCCD/CMND',
              icon: Icons.badge,
              isNumber: true,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: addressController,
              label: 'Địa chỉ thường trú',
              icon: Icons.location_on,
              maxLines: 2,
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: isLoading.value ? null : _submitUpdate,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isLoading.value
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Lưu thông tin',
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
        prefixIcon: Padding(
          padding: EdgeInsets.only(bottom: maxLines > 1 ? 24 : 0),
          child: Icon(icon),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }
}
