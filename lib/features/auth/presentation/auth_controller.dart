import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

enum AuthState {
  unauthenticated, // Chưa đăng nhập
  admin, // Chủ trọ
  tenant, // Khách thuê
}

class AuthController extends Notifier<AuthState> {
  // Biến lưu trữ SĐT khách để dùng lấy dữ liệu phòng, hóa đơn ở các màn sau
  String? currentTenantPhone;

  @override
  AuthState build() {
    // Không bypass nữa, mặc định mở app lên là bắt ở màn hình đăng nhập
    return AuthState.unauthenticated;
  }

  // Hàm xử lý đăng nhập thật
  Future<bool> login(String username, String password) async {
    // 1. LUỒNG ADMIN: Tài khoản cố định trong code
    if (username == 'admin' && password == 'admin123') {
      state = AuthState.admin;
      return true;
    }

    // 2. LUỒNG KHÁCH THUÊ: Kiểm tra đối chiếu với bảng 'users' trên Firebase
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('phone', isEqualTo: username)
          .where('password', isEqualTo: password)
          .get();

      // Nếu tìm thấy đúng tài khoản khớp SĐT và Mật khẩu
      if (querySnapshot.docs.isNotEmpty) {
        currentTenantPhone = username; // Lưu lại SĐT vào bộ nhớ
        state =
            AuthState.tenant; // Bật cờ AuthState để Router tự đẩy vào trang Chủ
        return true;
      }
    } catch (e) {
      print("Lỗi kết nối đăng nhập: $e");
    }

    // Nếu không lọt vào 2 trường hợp trên => Sai tài khoản hoặc mật khẩu
    return false;
  }

  void logout() {
    // Xóa SĐT và đẩy ra màn hình đăng nhập
    currentTenantPhone = null;
    state = AuthState.unauthenticated;
  }
}

// Provider quản lý trạng thái của AuthController
final authProvider = NotifierProvider<AuthController, AuthState>(() {
  return AuthController();
});

// Provider phụ để màn TenantHomeScreen gọi thẳng lấy SĐT một cách cực kỳ tiện lợi
final currentUserPhoneProvider = Provider<String>((ref) {
  // CỰC KỲ QUAN TRỌNG: Phải watch authProvider ở đây.
  // Mỗi khi có hành động Đăng nhập hoặc Đăng xuất (state thay đổi), 
  // provider này sẽ tự động chạy lại để bắt lấy SĐT mới nhất.
  ref.watch(authProvider); 
  
  return ref.read(authProvider.notifier).currentTenantPhone ?? '';
});