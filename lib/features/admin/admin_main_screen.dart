import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// Import file này để lấy Provider đếm số thông báo tổng hợp (đã trừ đi những cái đã đọc)
import 'notifications/notifications_screen.dart';

class AdminMainScreen extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const AdminMainScreen({super.key, required this.navigationShell});

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // --- 1. LOGIC ĐẾM SỐ THÔNG BÁO (SIÊU NGẮN GỌN) ---
    // Gọi thẳng Provider từ file thông báo sang. Nó tự động đếm cả Firebase và Hợp đồng!
    final notificationCount = ref.watch(unreadNotificationCountProvider);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _goBranch,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: Colors.blue),
            label: 'Tổng quan',
          ),
          const NavigationDestination(
            icon: Icon(Icons.meeting_room_outlined),
            selectedIcon: Icon(Icons.meeting_room, color: Colors.blue),
            label: 'Phòng trọ',
          ),

          // --- 2. TAB THÔNG BÁO GẮN CHẤM ĐỎ ---
          NavigationDestination(
            icon: Badge(
              isLabelVisible: notificationCount > 0,
              label: Text(notificationCount.toString()),
              child: const Icon(Icons.notifications_none),
            ),
            selectedIcon: Badge(
              isLabelVisible: notificationCount > 0,
              label: Text(notificationCount.toString()),
              child: const Icon(Icons.notifications, color: Colors.blue),
            ),
            label: 'Thông báo',
          ),

          const NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people, color: Colors.blue),
            label: 'Khách',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Colors.blue),
            label: 'Cá nhân',
          ),
        ],
      ),
    );
  }
}
