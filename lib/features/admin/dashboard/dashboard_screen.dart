import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

import '../properties/properties_screen.dart'; // Để lấy RoomStatus
import '../properties/data/room_repository.dart'; // Để lấy danh sách phòng

// --- 1. PROVIDER LẤY DỮ LIỆU HÓA ĐƠN THÁNG HIỆN TẠI ---
final currentMonthInvoicesProvider = StreamProvider<List<Map<String, dynamic>>>(
  (ref) {
    final now = DateTime.now();
    return FirebaseFirestore.instance
        .collection('invoices')
        .where('month', isEqualTo: now.month)
        .where('year', isEqualTo: now.year)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  },
);

// --- 2. GIAO DIỆN CHÍNH ---
class DashboardScreen extends HookConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(roomListStreamProvider);
    final invoicesAsync = ref.watch(currentMonthInvoicesProvider);
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Xin chào, Quản lý!',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            Text(
              'Khu trọ Hoa Mai',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: Colors.black,
            ),
            onPressed: () => context.push('/admin/notifications'),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11'),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Kéo để làm mới dữ liệu (nếu cần thiết)
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- KHU VỰC 1: BỨC TRANH TÀI CHÍNH THÁNG NÀY ---
              _buildFinancialCard(invoicesAsync, currencyFormat),
              const SizedBox(height: 24),

              // --- KHU VỰC 2: PHÍM TẮT HÀNH ĐỘNG ---
              const Text(
                'Hành động nhanh',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildQuickAction(
                    context,
                    Icons.add_home_work_outlined,
                    'Thêm phòng',
                    Colors.blue,
                    () => context.push('/admin/properties/add'),
                  ),
                  _buildQuickAction(
                    context,
                    Icons.electric_meter_outlined,
                    'Chốt số',
                    Colors.orange,
                    () {},
                  ),
                  _buildQuickAction(
                    context,
                    Icons.description_outlined,
                    'Hợp đồng',
                    Colors.purple,
                    () {},
                  ),
                  _buildQuickAction(
                    context,
                    Icons.group_add_outlined,
                    'Khách mới',
                    Colors.green,
                    () {},
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // --- KHU VỰC 3: THỐNG KÊ PHÒNG TRỌ (GRID) ---
              const Text(
                'Hiện trạng khu trọ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildRoomStatsGrid(roomsAsync),
              const SizedBox(height: 24),

              // --- KHU VỰC 4: BẢNG TIN TỨC THỜI (CẦN XỬ LÝ) ---
              const Text(
                'Sự kiện cần chú ý',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildLiveFeed(roomsAsync, invoicesAsync, currencyFormat),

              const SizedBox(height: 40), // Cắt lề đáy
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // CÁC WIDGET THÀNH PHẦN (ATOMIC COMPONENTS)
  // ==========================================

  // 1. Thẻ Báo cáo Tài chính
  Widget _buildFinancialCard(
    AsyncValue<List<Map<String, dynamic>>> invoicesAsync,
    NumberFormat format,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade800, Colors.blue.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: invoicesAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        error: (e, _) => const Text(
          'Lỗi tải dữ liệu',
          style: TextStyle(color: Colors.white),
        ),
        data: (invoices) {
          double totalExpected = 0;
          double totalCollected = 0;
          double totalPending = 0;

          for (var inv in invoices) {
            final amount = (inv['totalAmount'] ?? 0) as num;
            totalExpected += amount;
            if (inv['status'] == 'paid') {
              totalCollected += amount;
            } else {
              totalPending += amount;
            }
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Doanh thu dự kiến tháng này',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                format.format(totalExpected),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(color: Colors.white24, height: 1),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Đã thu',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        format.format(totalCollected),
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(width: 1, height: 30, color: Colors.white24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Chưa thu',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        format.format(totalPending),
                        style: const TextStyle(
                          color: Colors.orangeAccent,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  // 2. Phím tắt
  Widget _buildQuickAction(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // 3. Lưới thống kê phòng (Lấy dữ liệu thật)
  Widget _buildRoomStatsGrid(AsyncValue<List<RoomModel>> roomsAsync) {
    return roomsAsync.when(
      loading: () => const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text('Lỗi: $e'),
      data: (rooms) {
        final total = rooms.length;
        final available = rooms
            .where((r) => r.status == RoomStatus.available)
            .length;
        final rented = rooms.where((r) => r.status == RoomStatus.rented).length;
        final maintenance = rooms
            .where((r) => r.status == RoomStatus.maintenance)
            .length;

        return GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5, // Thẻ dẹt hơn cho hiện đại
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildMiniStatCard(
              'Tổng số phòng',
              '$total',
              Icons.meeting_room,
              Colors.blue,
            ),
            _buildMiniStatCard(
              'Đang cho thuê',
              '$rented',
              Icons.check_circle,
              Colors.green,
            ),
            _buildMiniStatCard(
              'Phòng trống',
              '$available',
              Icons.door_front_door,
              Colors.orange,
            ),
            _buildMiniStatCard(
              'Bảo trì',
              '$maintenance',
              Icons.build,
              Colors.red,
            ),
          ],
        );
      },
    );
  }

  Widget _buildMiniStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // 4. Bảng tin sự kiện (Gom chung các cảnh báo)
  Widget _buildLiveFeed(
    AsyncValue<List<RoomModel>> roomsAsync,
    AsyncValue<List<Map<String, dynamic>>> invoicesAsync,
    NumberFormat format,
  ) {
    // SỬA LỖI: Dùng maybeWhen thay cho valueOrNull để tương thích 100% với mọi bản Riverpod
    final rooms = roomsAsync.maybeWhen(
      data: (data) => data,
      orElse: () => <RoomModel>[],
    );

    final invoices = invoicesAsync.maybeWhen(
      data: (data) => data,
      orElse: () => <Map<String, dynamic>>[],
    );

    // Hiển thị loading nếu 1 trong 2 đang tải và chưa có dữ liệu hiển thị
    if ((rooms.isEmpty && roomsAsync.isLoading) ||
        (invoices.isEmpty && invoicesAsync.isLoading)) {
      return const Padding(
        padding: EdgeInsets.all(20.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    List<Widget> feedItems = [];

    // 4.1. Quét phòng đang bảo trì
    final brokenRooms = rooms.where((r) => r.status == RoomStatus.maintenance);
    for (var room in brokenRooms) {
      feedItems.add(
        _buildAlertTile(
          icon: Icons.plumbing,
          color: Colors.red,
          title: 'Phòng ${room.name} đang báo lỗi/bảo trì',
          subtitle: room.description?.isNotEmpty == true
              ? room.description!
              : 'Cần kiểm tra ngay',
        ),
      );
    }

    // 4.2. Quét hóa đơn chưa thanh toán
    final unpaidInvoices = invoices.where((i) => i['status'] == 'unpaid');
    for (var inv in unpaidInvoices) {
      feedItems.add(
        _buildAlertTile(
          icon: Icons.payment,
          color: Colors.orange,
          title: '${inv['roomName']} chưa thanh toán',
          subtitle: 'Cần thu: ${format.format(inv['totalAmount'] ?? 0)}',
        ),
      );
    }

    // 4.3. Quét hóa đơn VỪA THANH TOÁN (Hiển thị màu xanh cho có không khí tích cực)
    final paidInvoices = invoices
        .where((i) => i['status'] == 'paid')
        .take(3); // Chỉ lấy 3 cái gần nhất
    for (var inv in paidInvoices) {
      feedItems.add(
        _buildAlertTile(
          icon: Icons.check_circle,
          color: Colors.green,
          title: '${inv['roomName']} đã thanh toán',
          subtitle: 'Đã thu: ${format.format(inv['totalAmount'] ?? 0)}',
        ),
      );
    }

    if (feedItems.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: const Text(
          'Mọi thứ đang hoạt động hoàn hảo! 🎉',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Column(children: feedItems);
  }

  Widget _buildAlertTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.grey.shade300),
        ],
      ),
    );
  }
}
