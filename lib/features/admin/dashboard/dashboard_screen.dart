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
      backgroundColor: const Color(
        0xFFF4F6F9,
      ), // Nền xám nhạt đồng bộ NestFinder
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.home_work,
                color: Color(0xFF2E7D32),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Xin chào, Quản lý!',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Khu trọ Hoa Mai',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: Colors.black87,
            ),
            onPressed: () => context.push('/admin/notifications'),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16.0, left: 8.0),
            child: CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11'),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Kéo để làm mới dữ liệu
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- KHU VỰC 1: BỨC TRANH TÀI CHÍNH THÁNG NÀY ---
              _buildFinancialCard(invoicesAsync, currencyFormat),
              const SizedBox(height: 32),

              // --- KHU VỰC 2: PHÍM TẮT HÀNH ĐỘNG ---
              _buildSectionTitle('HÀNH ĐỘNG NHANH'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                      const Color(0xFF2E7D32),
                      () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // --- KHU VỰC 3: THỐNG KÊ PHÒNG TRỌ (GRID) ---
              _buildSectionTitle('HIỆN TRẠNG KHU TRỌ'),
              const SizedBox(height: 16),
              _buildRoomStatsGrid(roomsAsync),
              const SizedBox(height: 32),

              // --- KHU VỰC 4: BẢNG TIN TỨC THỜI (CẦN XỬ LÝ) ---
              _buildSectionTitle('SỰ KIỆN CẦN CHÚ Ý'),
              const SizedBox(height: 16),
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: Colors.grey,
        letterSpacing: 1.2,
      ),
    );
  }

  // 1. Thẻ Báo cáo Tài chính (Phong cách thẻ tín dụng cao cấp)
  Widget _buildFinancialCard(
    AsyncValue<List<Map<String, dynamic>>> invoicesAsync,
    NumberFormat format,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1E3A8A),
            Color(0xFF3B82F6),
          ], // Dark blue to bright blue
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: invoicesAsync.when(
        loading: () => const SizedBox(
          height: 120,
          child: Center(child: CircularProgressIndicator(color: Colors.white)),
        ),
        error: (e, _) => const SizedBox(
          height: 120,
          child: Center(
            child: Text(
              'Lỗi tải dữ liệu',
              style: TextStyle(color: Colors.white),
            ),
          ),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'DOANH THU DỰ KIẾN',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'T${DateTime.now().month}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                format.format(totalExpected),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ĐÃ THU',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          format.format(totalCollected),
                          style: const TextStyle(
                            color: Color(0xFF6EE7B7),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ), // Xanh ngọc
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 30,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CHƯA THU',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          format.format(totalPending),
                          style: const TextStyle(
                            color: Color(0xFFFCD34D),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ), // Vàng cam
                        ),
                      ],
                    ),
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
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  // 3. Lưới thống kê phòng
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
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.6,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildMiniStatCard(
              'Tổng phòng',
              '$total',
              Icons.meeting_room,
              Colors.blue,
            ),
            _buildMiniStatCard(
              'Đang thuê',
              '$rented',
              Icons.how_to_reg,
              const Color(0xFF2E7D32),
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
              Icons.build_circle_outlined,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // 4. Bảng tin sự kiện
  Widget _buildLiveFeed(
    AsyncValue<List<RoomModel>> roomsAsync,
    AsyncValue<List<Map<String, dynamic>>> invoicesAsync,
    NumberFormat format,
  ) {
    final rooms = roomsAsync.maybeWhen(
      data: (data) => data,
      orElse: () => <RoomModel>[],
    );
    final invoices = invoicesAsync.maybeWhen(
      data: (data) => data,
      orElse: () => <Map<String, dynamic>>[],
    );

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
          icon: Icons.build_circle_outlined,
          color: Colors.red,
          title: 'Phòng ${room.name} cần bảo trì',
          subtitle: room.description?.isNotEmpty == true
              ? room.description!
              : 'Yêu cầu kiểm tra hệ thống',
        ),
      );
    }

    // 4.2. Quét hóa đơn chưa thanh toán
    final unpaidInvoices = invoices.where((i) => i['status'] == 'unpaid');
    for (var inv in unpaidInvoices) {
      feedItems.add(
        _buildAlertTile(
          icon: Icons.warning_amber_rounded,
          color: Colors.orange.shade600,
          title: '${inv['roomName']} chưa đóng tiền',
          subtitle: 'Cần thu: ${format.format(inv['totalAmount'] ?? 0)}',
        ),
      );
    }

    // 4.3. Quét hóa đơn VỪA THANH TOÁN
    final paidInvoices = invoices.where((i) => i['status'] == 'paid').take(3);
    for (var inv in paidInvoices) {
      feedItems.add(
        _buildAlertTile(
          icon: Icons.check_circle_outline,
          color: const Color(0xFF2E7D32),
          title: '${inv['roomName']} đã thanh toán',
          subtitle: 'Đã thu: ${format.format(inv['totalAmount'] ?? 0)}',
        ),
      );
    }

    if (feedItems.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(Icons.task_alt, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              'Không có sự kiện nào cần xử lý',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
            ),
          ],
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
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
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
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
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
