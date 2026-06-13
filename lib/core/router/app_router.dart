import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';

import '../../features/admin/admin_main_screen.dart';
import '../../features/admin/dashboard/dashboard_screen.dart';
import '../../features/admin/properties/properties_screen.dart';
import '../../features/admin/properties/room_detail_screen.dart';
import '../../features/admin/tenants/tenants_screen.dart';
import '../../features/admin/properties/utility_reading_screen.dart';
import '../../features/admin/profile/profile_screen.dart';
import '../../features/admin/properties/create_contract_screen.dart';
// --- IMPORT MÀN HÌNH THÔNG BÁO ---
import '../../features/admin/notifications/notifications_screen.dart';

import '../../features/tenant/home/tenant_home_screen.dart';
import '../../features/admin/properties/add_room_screen.dart';
import '../../features/admin/properties/edit_tenant_screen.dart';
import '../../features/admin/properties/edit_room_screen.dart'; 

// Biến global key dùng cho Router
final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  // Lắng nghe sự thay đổi của AuthState
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',

    // Logic tự động chuyển hướng (Redirect)
    redirect: (context, state) {
      final isLoggingIn = state.uri.toString() == '/login';

      switch (authState) {
        case AuthState.unauthenticated:
          // Nếu chưa đăng nhập mà cố vào màn khác thì khóa lại, đẩy về login
          return isLoggingIn ? null : '/login';

        case AuthState.admin:
          // Nếu Chủ trọ đã đăng nhập mà đang đứng ở màn login thì đẩy thẳng vào Dashboard
          return isLoggingIn ? '/admin/dashboard' : null;

        case AuthState.tenant:
          // Nếu Khách thuê đã đăng nhập mà đang đứng ở màn login thì đẩy thẳng vào trang xem hóa đơn
          return isLoggingIn ? '/tenant/home' : null;
      }
    },

    // Định nghĩa các Route
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),

      // === LAYOUT CHO ADMIN (CHỦ TRỌ) SỬ DỤNG BOTTOM NAVIGATION BAR ===
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          // Trả về cái "Vỏ" chứa Bottom Navigation Bar
          return AdminMainScreen(navigationShell: navigationShell);
        },
        branches: [
          // Nhánh 1: Tổng quan (Index 0)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          // Nhánh 2: Phòng trọ (Index 1)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/properties', // Cấp 0 (Cha)
                builder: (context, state) => const PropertiesScreen(),
                routes: [
                  // 1. Màn hình chi tiết phòng
                  GoRoute(
                    path: 'detail', // Tự động thành: /admin/properties/detail
                    builder: (context, state) {
                      final roomData = state.extra as RoomModel;
                      return RoomDetailScreen(room: roomData);
                    },
                    routes: [
                      // Sub-route: Chốt điện nước
                      GoRoute(
                        path:
                            'reading', // Tự động thành: /admin/properties/detail/reading
                        builder: (context, state) {
                          final roomData = state.extra as RoomModel;
                          return UtilityReadingScreen(room: roomData);
                        },
                      ),
                      // Sub-route: Tạo hợp đồng
                      GoRoute(
                        path:
                            'contract', // Full path: /admin/properties/detail/contract
                        builder: (context, state) {
                          final roomData = state.extra as RoomModel;
                          return CreateContractScreen(room: roomData);
                        },
                      ),
                      // Sub-route: Sửa khách thuê
                      GoRoute(
                        path:
                            'edit-tenant', // Full path: /admin/properties/detail/edit-tenant
                        builder: (context, state) {
                          final roomData = state.extra as RoomModel;
                          return EditTenantScreen(room: roomData);
                        },
                      ),
                      // Sub-route: Sửa phòng
                      GoRoute(
                        path:
                            'edit', // Full path: /admin/properties/detail/edit
                        builder: (context, state) {
                          final roomData = state.extra as RoomModel;
                          return EditRoomScreen(room: roomData);
                        },
                      ),
                    ],
                  ),

                  // 2. Màn hình thêm phòng mới (Nằm CÙNG CẤP với detail)
                  GoRoute(
                    path: 'add', // Tự động thành: /admin/properties/add
                    builder: (context, state) => const AddRoomScreen(),
                  ),
                ], // Kết thúc mảng routes của properties
              ),
            ],
          ),

          // --- NHÁNH 3: THÔNG BÁO (Index 2 - VỪA CHÈN VÀO ĐÂY) ---
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/notifications',
                builder: (context, state) => const NotificationsScreen(),
              ),
            ],
          ),

          // Nhánh 4: Khách thuê (Index 3 - Đẩy lùi xuống)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/tenants',
                builder: (context, state) => const TenantsScreen(),
              ),
            ],
          ),
          // Nhánh 5: Cài đặt cá nhân (Index 4 - Đẩy lùi xuống)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // === MÀN HÌNH DÀNH CHO KHÁCH THUÊ ===
      GoRoute(
        path: '/tenant/home',
        builder: (context, state) => const TenantHomeScreen(),
      ),
    ],
  );
});
