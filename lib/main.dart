import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  // Đảm bảo các thành phần hệ thống của Flutter được khởi tạo trước
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Firebase kết nối với Server
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    // Bọc app bằng ProviderScope để dùng Riverpod
    const ProviderScope(
      child: MainApp(),
    ),
  );
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Lấy instance của router từ provider
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Quản Lý Phòng Trọ',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // Truyền router vào ứng dụng
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}