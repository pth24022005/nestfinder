import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/custom_button.dart';
import '../../../shared/custom_text_field.dart';

class ChangePasswordBottomSheet extends HookConsumerWidget {
  const ChangePasswordBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phoneController = useTextEditingController(); // Thêm SĐT
    final oldPasswordController = useTextEditingController();
    final newPasswordController = useTextEditingController();
    final confirmPasswordController = useTextEditingController();

    final isLoading = useState(false);

    Future<void> handleSave() async {
      final phone = phoneController.text.trim();
      final oldPass = oldPasswordController.text.trim();
      final newPass = newPasswordController.text.trim();

      if (phone.isEmpty ||
          oldPass.isEmpty ||
          newPass.isEmpty ||
          confirmPasswordController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin')),
        );
        return;
      }

      if (newPass != confirmPasswordController.text.trim()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mật khẩu mới không khớp!')),
        );
        return;
      }

      isLoading.value = true;
      try {
        // 1. Kiểm tra xem SĐT và Pass cũ có khớp trên hệ thống không
        final query = await FirebaseFirestore.instance
            .collection('users')
            .where('phone', isEqualTo: phone)
            .where('password', isEqualTo: oldPass)
            .get();

        if (query.docs.isEmpty) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Số điện thoại hoặc mật khẩu cũ sai!'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else {
          // 2. Khớp thì tiến hành Update mật khẩu mới
          await query.docs.first.reference.update({'password': newPass});

          if (context.mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Đổi mật khẩu thành công! Bạn có thể đăng nhập ngay.',
                ),
                backgroundColor: Colors.green,
              ),
            );
          }
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

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: bottomInset > 0 ? bottomInset + 24 : 40,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text(
              'Đổi mật khẩu',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            CustomTextField(
              label: 'Số điện thoại',
              hint: 'Nhập SĐT của bạn',
              prefixIcon: Icons.phone_android,
              controller: phoneController,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Mật khẩu hiện tại',
              hint: 'Nhập mật khẩu cũ',
              prefixIcon: Icons.lock_outline,
              controller: oldPasswordController,
              isPassword: true,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Mật khẩu mới',
              hint: 'Nhập mật khẩu mới',
              prefixIcon: Icons.lock_outline,
              controller: newPasswordController,
              isPassword: true,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Xác nhận mật khẩu',
              hint: 'Nhập lại mật khẩu mới',
              prefixIcon: Icons.lock_outline,
              controller: confirmPasswordController,
              isPassword: true,
            ),
            const SizedBox(height: 32),

            CustomButton(
              text: 'Cập nhật mật khẩu',
              isLoading: isLoading.value,
              onPressed: handleSave,
            ),
          ],
        ),
      ),
    );
  }
}
