import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'data/room_repository.dart';

// --- 1. ĐỊNH NGHĨA TRẠNG THÁI PHÒNG (ENUM) ---
enum RoomStatus { available, rented, maintenance }

extension RoomStatusExtension on RoomStatus {
  String get label {
    switch (this) {
      case RoomStatus.available:
        return 'Trống';
      case RoomStatus.rented:
        return 'Đã thuê';
      case RoomStatus.maintenance:
        return 'Bảo trì';
    }
  }

  Color get color {
    switch (this) {
      case RoomStatus.available:
        return const Color(0xFF2E7D32); 
      case RoomStatus.rented:
        return Colors.grey.shade600;
      case RoomStatus.maintenance:
        return Colors.orange.shade700;
    }
  }

  Color get bgColor {
    switch (this) {
      case RoomStatus.available:
        return const Color(0xFFE8F5E9); // Xanh nhạt
      case RoomStatus.rented:
        return Colors.grey.shade100;
      case RoomStatus.maintenance:
        return Colors.orange.shade50;
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

  final int? electricityIndex;
  final int? waterIndex;

  final double? electricityPrice;
  final double? waterPrice;
  final double? internetPrice;
  final double? servicePrice;

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
    final statusFilter = useState<RoomStatus?>(null);
    final sortFilter = useState<String>('default');

    // --- HÀM BẬT BẢNG LỌC TỪ DƯỚI LÊN ---
    void _showFilterModal() {
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

                  // Nhóm Lọc Trạng Thái
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

                  // Nhóm Sắp Xếp Giá
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
                        'Mặc định',
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

                  // Nút Áp dụng & Đặt lại
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: OutlinedButton(
                          onPressed: () {
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
                            statusFilter.value = tempStatus;
                            sortFilter.value = tempSort;
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
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
                  SizedBox(height: MediaQuery.of(context).padding.bottom),
                ],
              ),
            );
          },
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9), // Nền xám nhạt để nổi thẻ trắng
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            // Logo Icon NestFinder
            const Icon(Icons.home_work, color: Color(0xFF2E7D32), size: 24),
            const SizedBox(width: 8),
            const Text(
              'NestFinder',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            const Text(
              'Phòng trọ',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black,
              ),
            ),
            const Spacer(),
          ],
        ),
        actions: [
          // Nút Lọc có hiệu ứng
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(
                  Icons.filter_list,
                  color:
                      (statusFilter.value != null ||
                          sortFilter.value != 'default')
                      ? const Color(0xFF2E7D32)
                      : Colors.black87,
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
          IconButton(
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: Colors.black87,
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // --- THANH TÌM KIẾM ---
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              controller: searchController,
              onChanged: (value) => searchQuery.value = value,
              decoration: InputDecoration(
                hintText: 'Tìm phòng, khách thuê...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: searchQuery.value.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.cancel,
                          color: Colors.grey,
                          size: 20,
                        ),
                        onPressed: () {
                          searchController.clear();
                          searchQuery.value = '';
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF4F5F7),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // --- DANH SÁCH PHÒNG ---
          Expanded(
            child: roomsAsyncValue.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
              ),
              error: (err, stack) =>
                  Center(child: Text('Lỗi tải dữ liệu: $err')),
              data: (rooms) {
                // Áp dụng Đa tầng lọc
                var filteredRooms = rooms.where((room) {
                  final query = searchQuery.value.toLowerCase().trim();
                  final matchText =
                      query.isEmpty ||
                      room.name.toLowerCase().contains(query) ||
                      (room.tenantName?.toLowerCase().contains(query) ?? false);
                  final matchStatus =
                      statusFilter.value == null ||
                      room.status == statusFilter.value;
                  return matchText && matchStatus;
                }).toList();

                // Áp dụng Sắp xếp
                if (sortFilter.value == 'asc') {
                  filteredRooms.sort((a, b) => a.price.compareTo(b.price));
                } else if (sortFilter.value == 'desc') {
                  filteredRooms.sort((a, b) => b.price.compareTo(a.price));
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

                // Dùng ListView dọc thay cho GridView
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredRooms.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    return RoomCard(room: filteredRooms[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
      // --- NÚT FAB MỚI (Hình vuông bo góc) ---
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/admin/properties/add'),
        backgroundColor: const Color(0xFF388E3C), // Xanh NestFinder đậm
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F5E9) : Colors.grey.shade100,
          border: Border.all(
            color: isSelected ? const Color(0xFF2E7D32) : Colors.transparent,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF2E7D32) : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// --- 4. WIDGET THẺ PHÒNG (GIAO DIỆN THEO ẢNH) ---
class RoomCard extends ConsumerWidget {
  final RoomModel room;

  const RoomCard({super.key, required this.room});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    // Vẫn giữ lại logic vuốt ngang để xóa như cũ
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
      confirmDismiss: (direction) async => _confirmDelete(context, ref),
      onDismissed: (direction) => _deleteRoom(context, ref),

      // Khung thẻ chính
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => context.push('/admin/properties/detail', extra: room),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- DẢI MÀU TRẠNG THÁI BÊN TRÁI ---
                  Container(
                    width: 6,
                    decoration: BoxDecoration(
                      color: room.status.color,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                      ),
                    ),
                  ),

                  // --- NỘI DUNG CHÍNH ---
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Hàng 1: Tên phòng & Huy hiệu trạng thái
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                room.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: room.status.bgColor,
                                  borderRadius: BorderRadius.circular(6),
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
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Hàng 2: Giá tiền & Hành động (Sửa/Xóa)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                currencyFormat.format(room.price),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),

                              // Các nút bấm hành động tích hợp thẳng trên thẻ
                              Row(
                                children: [
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.blue,
                                      size: 20,
                                    ),
                                    onPressed: () => context.push(
                                      '/admin/properties/detail/edit',
                                      extra: room,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                    onPressed: () async {
                                      final confirm = await _confirmDelete(
                                        context,
                                        ref,
                                      );
                                      if (confirm == true) {
                                        _deleteRoom(context, ref);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- LOGIC XÓA (ĐƯỢC TÁCH RA ĐỂ DÙNG CHUNG CHO VUỐT VÀ BẤM NÚT) ---
  Future<bool?> _confirmDelete(BuildContext context, WidgetRef ref) async {
    return await showDialog<bool>(
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
              child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              style: TextButton.styleFrom(backgroundColor: Colors.red.shade50),
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
  }

  Future<void> _deleteRoom(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(roomRepositoryProvider).deleteRoom(room.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã xóa ${room.name}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
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
  }
}
