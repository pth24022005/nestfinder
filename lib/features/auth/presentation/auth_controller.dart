import 'package:hooks_riverpod/hooks_riverpod.dart';

enum AuthState {
  unauthenticated, // Chưa đăng nhập
  admin, // Chủ trọ
  tenant, // Khách thuê
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Tạm thời Bypass thẳng vào giao diện Chủ trọ để test Firestore cực nhanh
    return AuthState.admin;
  }

  // Hàm giả lập (Chờ tích hợp Firebase Authentication sau nếu còn thời gian)
  Future<void> login(String email, String password) async {
    // Tạm thời chỉ đổi State để chuyển màn hình
    if (email.contains('admin')) {
      state = AuthState.admin;
    } else {
      state = AuthState.tenant;
    }
  }

  Future<void> logout() async {
    // Đăng xuất thì đẩy về trạng thái ban đầu
    state = AuthState.unauthenticated;
  }
}

// Provider quản lý trạng thái của AuthController
final authProvider = NotifierProvider<AuthController, AuthState>(() {
  return AuthController();
});
