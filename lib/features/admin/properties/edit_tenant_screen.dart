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
    // --- BỘ ĐIỀU KHIỂN: Tự động điền dữ liệu cũ vào các ô nhập liệu ---
    final nameController = useTextEditingController(text: room.tenantName);
    final phoneController = useTextEditingController(text: room.tenantPhone);
    final cccdController = useTextEditingController(text: room.tenantCCCD);
    final addressController = useTextEditingController(
      text: room.tenantAddress,
    );

    final isLoading = useState<bool>(false);

    // Hàm hỗ trợ hiển thị thông báo
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

    // --- LOGIC CẬP NHẬT DỮ LIỆU ---
    Future<void> submitUpdate() async {
      FocusScope.of(context).unfocus(); // Ẩn bàn phím khi bấm lưu

      final name = nameController.text.trim();
      final phone = phoneController.text.trim();

      if (name.isEmpty) {
        return showError('Tên không được để trống');
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
        showError('Lỗi: $e');
      } finally {
        isLoading.value = false;
      }
    }

    // UX: Bấm ra ngoài vùng trống để ẩn bàn phím
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
            'Sửa khách - ${room.name}',
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
                'HỒ SƠ KHÁCH THUÊ',
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
                label: 'Họ và tên người đại diện',
                hint: 'Nguyễn Văn A',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 16),

              _buildModernInput(
                controller: phoneController,
                label: 'Số điện thoại',
                hint: '0912345678',
                icon: Icons.phone_outlined,
                isNumber: true,
              ),
              const SizedBox(height: 16),

              _buildModernInput(
                controller: cccdController,
                label: 'Số CCCD/CMND',
                hint: '0012010...',
                icon: Icons.badge_outlined,
                isNumber: true,
              ),
              const SizedBox(height: 16),

              _buildModernInput(
                controller: addressController,
                label: 'Địa chỉ thường trú',
                hint: 'Nhập địa chỉ...',
                icon: Icons.location_on_outlined,
                maxLines: 2,
              ),

              // Khoảng trống dưới cùng để tránh bị che bởi nút bấm
              const SizedBox(height: 100),
            ],
          ),
        ),

        // --- NÚT XÁC NHẬN CHÍNH ---
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          color: Colors.white,
          child: ElevatedButton(
            onPressed: isLoading.value ? null : submitUpdate,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1C1C1E), // Đen nhám hiện đại
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
                    'LƯU THÔNG TIN',
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

  // ========================================================
  // CÁC WIDGET GIAO DIỆN TÙY CHỈNH (ATOMIC COMPONENTS)
  // ========================================================

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
}
