import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../shared/custom_button.dart';
import '../../shared/custom_text_field.dart';
import 'auth_controller.dart'; // File AuthController tạo ở bước trước

class LoginScreen extends HookConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Sử dụng hooks để tạo controller (tự động dispose khi thoát màn hình)
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    
    // State quản lý việc ẩn/hiện mật khẩu
    final isPasswordHidden = useState(true);
    
    // State quản lý trạng thái loading của nút bấm
    final isLoading = useState(false);

    // Hàm xử lý đăng nhập
    Future<void> handleLogin() async {
      final email = emailController.text.trim();
      final password = passwordController.text.trim();

      if (email.isEmpty || password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin')),
        );
        return;
      }

      isLoading.value = true;
      // Gọi logic login từ Riverpod Provider
      await ref.read(authProvider.notifier).login(email, password);
      isLoading.value = false;
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
                // Logo Icon
                Icon(
                  Icons.apartment_rounded,
                  size: 80,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 24),
                
                // Tiêu đề
                const Text(
                  'Chào mừng trở lại',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Đăng nhập để quản lý hệ thống phòng trọ',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Form nhập liệu
                CustomTextField(
                  label: 'Email / Số điện thoại',
                  hint: 'Nhập email hoặc SĐT',
                  prefixIcon: Icons.email_outlined,
                  controller: emailController,
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  label: 'Mật khẩu',
                  hint: 'Nhập mật khẩu',
                  prefixIcon: Icons.lock_outline,
                  controller: passwordController,
                  isPassword: isPasswordHidden.value,
                  suffixIcon: IconButton(
                    icon: Icon(
                      isPasswordHidden.value
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      isPasswordHidden.value = !isPasswordHidden.value;
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // Quên mật khẩu
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: const Text('Quên mật khẩu?'),
                  ),
                ),
                const SizedBox(height: 24),

                // Nút Đăng nhập
                CustomButton(
                  text: 'Đăng nhập',
                  isLoading: isLoading.value,
                  onPressed: handleLogin,
                ),
                
                // Tip hướng dẫn cho Demo
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '💡 Mẹo: Nhập email có chứa chữ "admin" để vào giao diện Chủ Trọ, các email khác sẽ vào giao diện Khách.',
                    style: TextStyle(color: Colors.blue, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}