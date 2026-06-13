import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../shared/custom_button.dart';
import '../../../shared/custom_text_field.dart';

class ChangePasswordBottomSheet extends HookConsumerWidget {
  const ChangePasswordBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final oldPasswordController = useTextEditingController();
    final newPasswordController = useTextEditingController();
    final confirmPasswordController = useTextEditingController();

    final isLoading = useState(false);

    Future<void> handleSave() async {
      // Validate cơ bản
      if (oldPasswordController.text.isEmpty ||
          newPasswordController.text.isEmpty ||
          confirmPasswordController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin')),
        );
        return;
      }

      if (newPasswordController.text != confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mật khẩu mới không khớp!')),
        );
        return;
      }

      isLoading.value = true;
      // Giả lập gọi API đổi mật khẩu
      await Future.delayed(const Duration(seconds: 1));
      isLoading.value = false;

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đổi mật khẩu thành công!'),
            backgroundColor: Colors.green,
          ),
        );
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
            // Thanh gạt (Handle)
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
