import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'properties/properties_screen.dart'; // Để lấy RoomStatus
import 'properties/data/room_repository.dart'; // Để lấy danh sách phòng

// Đổi từ StatelessWidget sang ConsumerWidget để lắng nghe được dữ liệu
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
    // --- 1. LOGIC ĐẾM SỐ THÔNG BÁO ---
    final roomsAsyncValue = ref.watch(roomListStreamProvider);
    int notificationCount = 0;

    // Quét ngầm danh sách phòng để đếm xem có bao nhiêu phòng dính cảnh báo
    roomsAsyncValue.whenData((rooms) {
      final today = DateTime.now();
      for (var room in rooms) {
        if (room.status == RoomStatus.rented && room.contractEndDate != null) {
          final endDate = DateTime(
            room.contractEndDate!.year,
            room.contractEndDate!.month,
            room.contractEndDate!.day,
          );
          final currentDate = DateTime(today.year, today.month, today.day);
          final daysLeft = endDate.difference(currentDate).inDays;

          // Tính tổng thời hạn gốc của hợp đồng
          final totalDuration = room.contractEndDate!
              .difference(room.contractStartDate!)
              .inDays;

          // SỬA ĐIỀU KIỆN ĐẾM: Đếm nếu còn dưới 30 ngày HOẶC nếu đó là HĐ ngắn hạn theo tháng
          if (daysLeft <= 30 || totalDuration <= 31) {
            notificationCount++;
          }
        }
      }
    });

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

          // --- 2. TAB THÔNG BÁO CÓ GẮN "CHẤM ĐỎ" CHUẨN APP NGÂN HÀNG ---
          NavigationDestination(
            // Dùng widget Badge bọc ngoài Icon để tạo chấm đỏ
            icon: Badge(
              isLabelVisible:
                  notificationCount > 0, // Ẩn hoàn toàn nếu không có thông báo
              label: Text(notificationCount.toString()), // Hiển thị số lượng
              child: const Icon(Icons.notifications_none),
            ),
            selectedIcon: Badge(
              isLabelVisible: notificationCount > 0,
              label: Text(notificationCount.toString()),
              child: const Icon(Icons.notifications, color: Colors.blue),
            ),
            label: 'Thông báo',
          ),

          // -------------------------------------------------------------
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
