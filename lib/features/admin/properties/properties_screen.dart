import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'data/room_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// --- 1. ĐỊNH NGHĨA TRẠNG THÁI PHÒNG (ENUM) ---
enum RoomStatus { available, rented, maintenance }

extension RoomStatusExtension on RoomStatus {
  String get label {
    switch (this) {
      case RoomStatus.available:
        return 'Phòng trống';
      case RoomStatus.rented:
        return 'Đã thuê';
      case RoomStatus.maintenance:
        return 'Bảo trì';
    }
  }

  Color get color {
    switch (this) {
      case RoomStatus.available:
        return Colors.green;
      case RoomStatus.rented:
        return Colors.blue;
      case RoomStatus.maintenance:
        return Colors.orange;
    }
  }
}

// --- 2. MÔ HÌNH DỮ LIỆU (MODEL) ---
class RoomModel {
  final String id;
  final String name;
  final RoomStatus status;
  final double price;
  final double? area;
  final String? furniture;
  final String? description;

  final String? tenantName;
  final String? tenantPhone;
  final String? tenantCCCD;
  final String? tenantAddress;
  final double? contractDeposit;
  final DateTime? contractStartDate;
  final DateTime? contractEndDate;

  final int? electricityIndex; // Chỉ số điện cũ
  final int? waterIndex; // Chỉ số nước cũ

  final double? electricityPrice; // Giá điện (VD: 3500 đ/số)
  final double? waterPrice;       // Giá nước (VD: 25000 đ/khối)
  final double? internetPrice;    // Tiền mạng/tháng
  final double? servicePrice;     // Tiền rác, vệ sinh/tháng

  RoomModel({
    required this.id,
    required this.name,
    required this.status,
    required this.price,
    this.area,
    this.furniture,
    this.description,
    this.tenantName,
    this.tenantPhone,
    this.tenantCCCD,
    this.tenantAddress,
    this.contractDeposit,
    this.contractStartDate,
    this.contractEndDate,
    this.electricityIndex,
    this.waterIndex,
    this.electricityPrice,
    this.waterPrice,
    this.internetPrice,
    this.servicePrice,
  });
}

// --- 3. MÀN HÌNH CHÍNH TÍCH HỢP RIVERPOD API ---
class PropertiesScreen extends HookConsumerWidget {
  const PropertiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsyncValue = ref.watch(roomListStreamProvider);

    final searchQuery = useState<String>('');
    final searchController = useTextEditingController();

    // --- STATE CHO BỘ LỌC ---
    final statusFilter = useState<RoomStatus?>(null); // null = Hiển thị tất cả
    final sortFilter = useState<String>(
      'default',
    ); // 'default', 'asc' (Tăng), 'desc' (Giảm)

    // --- HÀM BẬT BẢNG LỌC TỪ DƯỚI LÊN ---
    void _showFilterModal() {
      // Dùng biến tạm để lưu trạng thái lựa chọn trước khi bấm "Áp dụng"
      RoomStatus? tempStatus = statusFilter.value;
      String tempSort = sortFilter.value;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thanh ngang trang trí
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Text(
                    'Lọc danh sách phòng',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),

                  // 1. Nhóm Lọc Trạng Thái
                  const Text(
                    'Trạng thái phòng',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFilterChip(
                        'Tất cả',
                        tempStatus == null,
                        () => setModalState(() => tempStatus = null),
                      ),
                      _buildFilterChip(
                        'Phòng trống',
                        tempStatus == RoomStatus.available,
                        () => setModalState(
                          () => tempStatus = RoomStatus.available,
                        ),
                      ),
                      _buildFilterChip(
                        'Đã thuê',
                        tempStatus == RoomStatus.rented,
                        () =>
                            setModalState(() => tempStatus = RoomStatus.rented),
                      ),
                      _buildFilterChip(
                        'Bảo trì',
                        tempStatus == RoomStatus.maintenance,
                        () => setModalState(
                          () => tempStatus = RoomStatus.maintenance,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 2. Nhóm Sắp Xếp Giá
                  const Text(
                    'Sắp xếp theo giá',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFilterChip(
                        'Mặc định (Mới nhất)',
                        tempSort == 'default',
                        () => setModalState(() => tempSort = 'default'),
                      ),
                      _buildFilterChip(
                        'Giá thấp đến cao',
                        tempSort == 'asc',
                        () => setModalState(() => tempSort = 'asc'),
                      ),
                      _buildFilterChip(
                        'Giá cao xuống thấp',
                        tempSort == 'desc',
                        () => setModalState(() => tempSort = 'desc'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Nút Áp dụng & Nút Đặt lại
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: OutlinedButton(
                          onPressed: () {
                            // Xóa sạch bộ lọc
                            statusFilter.value = null;
                            sortFilter.value = 'default';
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Bỏ lọc',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            // Cập nhật State chính thức
                            statusFilter.value = tempStatus;
                            sortFilter.value = tempSort;
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Áp dụng',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).padding.bottom,
                  ), // Đẩy lên để không bị lẹm vào viền iPhone
                ],
              ),
            );
          },
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Quản lý Phòng trọ',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Nút Lọc: Đổi thành màu xanh và thêm chấm hiệu ứng nếu đang có bộ lọc
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(
                  Icons.filter_list,
                  // Đổi màu Icon nếu có bật lọc
                  color:
                      (statusFilter.value != null ||
                          sortFilter.value != 'default')
                      ? Colors.blue
                      : Colors.black,
                ),
                onPressed: _showFilterModal,
              ),
              if (statusFilter.value != null || sortFilter.value != 'default')
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // --- THANH TÌM KIẾM ---
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: TextField(
              controller: searchController,
              onChanged: (value) => searchQuery.value = value,
              decoration: InputDecoration(
                hintText: 'Tìm phòng, khách thuê...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: searchQuery.value.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.grey),
                        onPressed: () {
                          searchController.clear();
                          searchQuery.value = '';
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // --- DANH SÁCH PHÒNG ĐÃ ÁP DỤNG "ĐA TẦNG LỌC" ---
          Expanded(
            child: roomsAsyncValue.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) =>
                  Center(child: Text('Lỗi tải dữ liệu: $err')),
              data: (rooms) {
                // BƯỚC 1: Lọc bằng Thanh Tìm Kiếm & Trạng Thái
                var filteredRooms = rooms.where((room) {
                  // Lọc Text
                  final query = searchQuery.value.toLowerCase().trim();
                  final matchText =
                      query.isEmpty ||
                      room.name.toLowerCase().contains(query) ||
                      (room.tenantName?.toLowerCase().contains(query) ?? false);

                  // Lọc Status
                  final matchStatus =
                      statusFilter.value == null ||
                      room.status == statusFilter.value;

                  return matchText && matchStatus;
                }).toList();

                // BƯỚC 2: Áp dụng Sắp Xếp (Sort)
                if (sortFilter.value == 'asc') {
                  filteredRooms.sort(
                    (a, b) => a.price.compareTo(b.price),
                  ); // Rẻ lên đầu
                } else if (sortFilter.value == 'desc') {
                  filteredRooms.sort(
                    (a, b) => b.price.compareTo(a.price),
                  ); // Đắt lên đầu
                }

                if (filteredRooms.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Không tìm thấy phòng nào phù hợp',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: filteredRooms.length,
                  itemBuilder: (context, index) {
                    return RoomCard(room: filteredRooms[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/admin/properties/add'),
        icon: const Icon(Icons.add),
        label: const Text('Thêm phòng'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  // Hàm hỗ trợ vẽ nút bấm lựa chọn (Chip) cho bộ lọc
  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.grey.shade100,
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.transparent,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.blue.shade700 : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// --- 4. WIDGET THẺ PHÒNG (ROOM CARD) ---
class RoomCard extends ConsumerWidget {
  final RoomModel room;

  const RoomCard({super.key, required this.room});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Dismissible(
      key: Key(room.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24.0),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 32),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Xác nhận xóa',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Text(
                'Bạn có chắc chắn muốn xóa vĩnh viễn ${room.name} không?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text(
                    'Hủy',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text(
                    'Xóa ngay',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) async {
        try {
          await ref.read(roomRepositoryProvider).deleteRoom(room.id);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Đã xóa ${room.name}'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Lỗi khi xóa: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border(left: BorderSide(color: room.status.color, width: 6)),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              context.push('/admin/properties/detail', extra: room);
            },
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        room.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(
                        Icons.more_vert,
                        color: Colors.grey.shade600,
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: room.status.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      room.status.label,
                      style: TextStyle(
                        color: room.status.color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (room.status == RoomStatus.rented &&
                      room.tenantName != null) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            room.tenantName!,
                            style: TextStyle(
                              color: Colors.grey.shade800,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Icon(
                          Icons.sell_outlined,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          currencyFormat.format(room.price),
                          style: TextStyle(
                            color: Colors.grey.shade800,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
