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
import '../../features/admin/notifications/notifications_screen.dart';

import '../../features/tenant/home/tenant_home_screen.dart';
import '../../features/admin/properties/add_room_screen.dart';
import '../../features/admin/properties/edit_tenant_screen.dart';
import '../../features/admin/properties/edit_room_screen.dart';

// --- IMPORT MÀN HÌNH BÁO CÁO SỰ CỐ CỦA KHÁCH ---
import '../../features/tenant/maintenance/tenant_maintenance_screen.dart';
import '../../features/tenant/invoices/tenant_invoice_history_screen.dart';
import '../../features/tenant/contract/tenant_contract_screen.dart';

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
          return isLoggingIn ? null : '/login';

        case AuthState.admin:
          return isLoggingIn ? '/admin/dashboard' : null;

        case AuthState.tenant:
          return isLoggingIn ? '/tenant/home' : null;
      }
    },

    // Định nghĩa các Route
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),

      // === LAYOUT CHO ADMIN (CHỦ TRỌ) ===
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AdminMainScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/properties',
                builder: (context, state) => const PropertiesScreen(),
                routes: [
                  GoRoute(
                    path: 'detail',
                    builder: (context, state) {
                      final roomData = state.extra as RoomModel;
                      return RoomDetailScreen(room: roomData);
                    },
                    routes: [
                      GoRoute(
                        path: 'reading',
                        builder: (context, state) {
                          final roomData = state.extra as RoomModel;
                          return UtilityReadingScreen(room: roomData);
                        },
                      ),
                      GoRoute(
                        path: 'contract',
                        builder: (context, state) {
                          final roomData = state.extra as RoomModel;
                          return CreateContractScreen(room: roomData);
                        },
                      ),
                      GoRoute(
                        path: 'edit-tenant',
                        builder: (context, state) {
                          final roomData = state.extra as RoomModel;
                          return EditTenantScreen(room: roomData);
                        },
                      ),
                      GoRoute(
                        path: 'edit',
                        builder: (context, state) {
                          final roomData = state.extra as RoomModel;
                          return EditRoomScreen(room: roomData);
                        },
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'add',
                    builder: (context, state) => const AddRoomScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/notifications',
                builder: (context, state) => const NotificationsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/tenants',
                builder: (context, state) => const TenantsScreen(),
              ),
            ],
          ),
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

      // === CÁC MÀN HÌNH DÀNH CHO KHÁCH THUÊ ===
      GoRoute(
        path: '/tenant/home',
        builder: (context, state) => const TenantHomeScreen(),
      ),

      // ĐÃ THÊM: Route cho màn hình Báo cáo sự cố
      GoRoute(
        path: '/tenant/maintenance',
        builder: (context, state) {
          // Ép kiểu extra nhận được thành String (ID phòng)
          final roomId = state.extra as String;
          return TenantMaintenanceScreen(roomId: roomId);
        },
      ),
      GoRoute(
        path: '/tenant/invoices',
        builder: (context, state) {
          final roomId = state.extra as String;
          return TenantInvoiceHistoryScreen(roomId: roomId);
        },
      ),
      GoRoute(
        path: '/tenant/contract',
        builder: (context, state) {
          final roomId = state.extra as String;
          return TenantContractScreen(roomId: roomId);
        },
      ),
    ],
  );
});
