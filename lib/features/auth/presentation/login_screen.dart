import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../shared/custom_button.dart';
import '../../shared/custom_text_field.dart';
import 'auth_controller.dart';
import '../../admin/profile/widgets/change_password_bottom_sheet.dart';

class LoginScreen extends HookConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final isPasswordHidden = useState(true);
    final isLoading = useState(false);

    // Thêm tham số [String? _] để hàm này có thể nhận sự kiện từ phím Enter
    Future<void> handleLogin([String? _]) async {
      final username = emailController.text.trim();
      final password = passwordController.text.trim();

      // Xóa các thông báo cũ trước khi hiện thông báo mới để tránh bị kẹt
      ScaffoldMessenger.of(context).clearSnackBars();

      if (username.isEmpty || password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Vui lòng nhập đầy đủ tài khoản và mật khẩu'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(20),
          ),
        );
        return;
      }

      isLoading.value = true;
      final success = await ref
          .read(authProvider.notifier)
          .login(username, password);
      isLoading.value = false;

      // XỬ LÝ LỖI SAI TÀI KHOẢN HIỂN THỊ RÕ RÀNG
      if (!success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Tài khoản hoặc mật khẩu không chính xác!'),
            backgroundColor: Colors.red,
            behavior:
                SnackBarBehavior.floating, // Hiển thị nổi lên trên bàn phím
            margin: EdgeInsets.all(20),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.apartment_rounded,
                  size: 80,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Chào mừng trở lại',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Đăng nhập để quản lý hệ thống phòng trọ',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                CustomTextField(
                  label: 'Tên đăng nhập',
                  hint: 'Nhập số điện thoại',
                  prefixIcon: Icons.person_outline,
                  controller: emailController,
                  // Gõ xong tài khoản ấn Next trên bàn phím sẽ nhảy xuống ô Mật khẩu
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  label: 'Mật khẩu',
                  hint: 'Nhập mật khẩu',
                  prefixIcon: Icons.lock_outline,
                  controller: passwordController,
                  isPassword: isPasswordHidden.value,
                  // Gắn sự kiện: Bấm Enter (hoặc Done trên đt) là gọi hàm Đăng nhập
                  textInputAction: TextInputAction.done,
                  onSubmitted: handleLogin,
                  suffixIcon: IconButton(
                    icon: Icon(
                      isPasswordHidden.value
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.grey,
                    ),
                    onPressed: () =>
                        isPasswordHidden.value = !isPasswordHidden.value,
                  ),
                ),
                const SizedBox(height: 12),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => const ChangePasswordBottomSheet(),
                      );
                    },
                    child: const Text('Quên mật khẩu?'),
                  ),
                ),
                const SizedBox(height: 24),

                CustomButton(
                  text: 'Đăng nhập',
                  isLoading: isLoading.value,
                  onPressed: handleLogin,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
