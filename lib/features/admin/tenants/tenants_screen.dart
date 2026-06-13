import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart'; // Thêm thư viện quản lý trạng thái cục bộ
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

import '../properties/properties_screen.dart'; // Để lấy RoomModel & RoomStatus
import '../properties/data/room_repository.dart'; // Để lấy roomListStreamProvider

// --- 1. MODEL DỮ LIỆU KHÁCH THUÊ ---
class TenantModel {
  final String roomId;
  final String fullName;
  final String phone;
  final String roomName;
  final RoomModel room; // <-- THÊM: Đính kèm luôn dữ liệu phòng gốc vào đây

  TenantModel({
    required this.roomId,
    required this.fullName,
    required this.phone,
    required this.roomName,
    required this.room,
  });
}

// --- 2. PROVIDER TÍNH NỢ ---
final tenantDebtProvider = StreamProvider.family<double, String>((ref, roomId) {
  return FirebaseFirestore.instance
      .collection('invoices')
      .where('roomId', isEqualTo: roomId)
      .where('status', isEqualTo: 'unpaid') // Chỉ lấy hóa đơn chưa thanh toán
      .snapshots()
      .map((snapshot) {
        double totalDebt = 0;
        for (var doc in snapshot.docs) {
          totalDebt += (doc.data()['totalAmount'] ?? 0) as num;
        }
        return totalDebt;
      });
});

// --- 3. GIAO DIỆN CHÍNH ---
class TenantsScreen extends HookConsumerWidget {
  const TenantsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // SỬA LỖI 1: Dùng useState cục bộ cực kỳ an toàn, thay thế cho StateProvider
    final searchQuery = useState('');
    final roomsAsync = ref.watch(roomListStreamProvider);

    // Lọc danh sách ngay bên trong hàm build
    final tenants = roomsAsync.maybeWhen(
      data: (rooms) {
        // 1. Lọc ra các phòng ĐÃ THUÊ
        final rentedRooms = rooms.where(
          (r) => r.status == RoomStatus.rented && r.tenantName != null,
        );

        // 2. Chuyển đổi và đính kèm RoomModel
        var tenantList = rentedRooms
            .map(
              (r) => TenantModel(
                roomId: r.id,
                fullName: r.tenantName!,
                phone: r.tenantPhone?.isNotEmpty == true
                    ? r.tenantPhone!
                    : 'Chưa cập nhật',
                roomName: r.name,
                room: r, // Truyền trực tiếp dữ liệu phòng vào đây
              ),
            )
            .toList();

        // 3. Xử lý Logic Tìm kiếm
        if (searchQuery.value.isNotEmpty) {
          final query = searchQuery.value.toLowerCase();
          tenantList = tenantList
              .where(
                (t) =>
                    t.fullName.toLowerCase().contains(query) ||
                    t.phone.contains(query),
              )
              .toList();
        }

        return tenantList;
      },
      orElse: () => <TenantModel>[], // Trả về mảng rỗng nếu chưa tải xong
    );

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Danh bạ Khách thuê',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ),
      body: Column(
        children: [
          // Thanh tìm kiếm
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) {
                searchQuery.value = value; // Cập nhật biến State
              },
              decoration: InputDecoration(
                hintText: 'Tìm theo tên, SĐT...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blue, width: 1),
                ),
              ),
            ),
          ),

          // Danh sách khách thuê
          Expanded(
            child: tenants.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    itemCount: tenants.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final tenant = tenants[index];
                      return TenantCard(tenant: tenant);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // Giao diện khi không có khách hoặc tìm không ra
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Không tìm thấy khách thuê',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

// --- 4. WIDGET THẺ KHÁCH THUÊ ---
class TenantCard extends HookConsumerWidget {
  final TenantModel tenant;

  const TenantCard({super.key, required this.tenant});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    // Lắng nghe realtime số nợ
    final debtAsync = ref.watch(tenantDebtProvider(tenant.roomId));

    // SỬA LỖI 2: Dùng .when() tương thích tuyệt đối với mọi phiên bản Riverpod
    final debtAmount = debtAsync.when(
      data: (debt) => debt,
      loading: () => 0.0,
      error: (_, __) => 0.0,
    );

    final hasDebt = debtAmount > 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: hasDebt ? Colors.red.shade300 : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: hasDebt ? Colors.red.shade50 : Colors.blue.shade50,
          child: Text(
            tenant.fullName.isNotEmpty
                ? tenant.fullName.substring(0, 1).toUpperCase()
                : '?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: hasDebt ? Colors.red : Colors.blue,
            ),
          ),
        ),
        title: Text(
          tenant.fullName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.meeting_room_outlined,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text('Phòng: ${tenant.roomName}'),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.phone_outlined,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(tenant.phone),
                ],
              ),
            ],
          ),
        ),
        trailing: hasDebt
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Đang nợ',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    currencyFormat.format(debtAmount),
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
            : const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () {
          // SỬA LỖI 3: Ném thẳng dữ liệu phòng gốc sang màn hình Chi tiết!
          // Không cần dùng fromMap, không tốn tài nguyên gọi lại Firebase.
          context.push('/admin/properties/detail', extra: tenant.room);
        },
      ),
    );
  }
}
