import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../properties/properties_screen.dart';
import '../properties/data/room_repository.dart';

// =====================================================================
// 1. CÁC PROVIDER QUẢN LÝ DỮ LIỆU & TRẠNG THÁI THÔNG BÁO
// =====================================================================

// Provider 1: Lấy danh sách thông báo sự cố từ Firebase
final notificationsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return FirebaseFirestore.instance
      .collection('notifications')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList(),
      );
});

// Provider 2 (NÂNG CẤP CHUẨN MỚI): Quản lý Hợp đồng đã đọc bằng Notifier (Bỏ StateProvider)
class ReadContractsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => <String>{};

  // Hàm đánh dấu đọc 1 hợp đồng
  void markAsRead(String roomId) {
    state = {...state, roomId}; // Cập nhật state an toàn để báo UI vẽ lại
  }

  // Hàm đánh dấu đọc tất cả hợp đồng
  void markAllAsRead(Set<String> roomIds) {
    state = roomIds;
  }
}

final readContractAlertsProvider =
    NotifierProvider<ReadContractsNotifier, Set<String>>(() {
      return ReadContractsNotifier();
    });

// Provider 3: TỔNG HỢP SỐ ĐẾM THÔNG BÁO CHƯA ĐỌC (Dùng cho chấm đỏ ở Bottom Nav)
final unreadNotificationCountProvider = Provider<int>((ref) {
  int count = 0;

  // 1. Đếm sự cố chưa đọc từ Firebase
  final List<Map<String, dynamic>> firebaseNotifs =
      ref.watch(notificationsProvider).value ?? [];
  count += firebaseNotifs.where((n) => n['isRead'] == false).length;

  // 2. Đếm cảnh báo hợp đồng chưa đọc
  final List<RoomModel> rooms = ref.watch(roomListStreamProvider).value ?? [];
  final Set<String> readContracts = ref.watch(readContractAlertsProvider);
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

      // Đếm tăng lên nếu hợp đồng sắp/đã hết hạn VÀ admin CHƯA bấm vào đọc
      if (daysLeft <= 30 && !readContracts.contains(room.id)) {
        count++;
      }
    }
  }
  return count;
});

// =====================================================================
// 2. MÀN HÌNH CHÍNH
// =====================================================================
class NotificationsScreen extends HookConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsyncValue = ref.watch(roomListStreamProvider);
    final notificationsAsync = ref.watch(notificationsProvider);
    final readContracts = ref.watch(readContractAlertsProvider);

    final dateFormat = DateFormat('dd/MM/yyyy');

    // --- HÀM XỬ LÝ THÔNG BÁO FIREBASE ---
    Future<void> markAsReadFirebase(String id, bool currentStatus) async {
      if (!currentStatus) {
        await FirebaseFirestore.instance
            .collection('notifications')
            .doc(id)
            .update({'isRead': true});
      }
    }

    Future<void> markAllAsRead(
      List<Map<String, dynamic>> notifications,
      List<RoomModel> rooms,
    ) async {
      // 1. Đánh dấu đọc tất cả Firebase
      final batch = FirebaseFirestore.instance.batch();
      for (var notif in notifications) {
        if (notif['isRead'] == false) {
          final docRef = FirebaseFirestore.instance
              .collection('notifications')
              .doc(notif['id']);
          batch.update(docRef, {'isRead': true});
        }
      }
      await batch.commit();

      // 2. Đánh dấu đọc tất cả Hợp đồng bằng hàm chuẩn mới
      final Set<String> allAlertRoomIds = {};
      final today = DateTime.now();
      for (var room in rooms) {
        if (room.status == RoomStatus.rented && room.contractEndDate != null) {
          final endDate = DateTime(
            room.contractEndDate!.year,
            room.contractEndDate!.month,
            room.contractEndDate!.day,
          );
          final currentDate = DateTime(today.year, today.month, today.day);
          if (endDate.difference(currentDate).inDays <= 30) {
            allAlertRoomIds.add(room.id);
          }
        }
      }
      // Gọi hàm thay vì update rườm rà
      ref
          .read(readContractAlertsProvider.notifier)
          .markAllAsRead(allAlertRoomIds);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã đánh dấu đọc tất cả!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        centerTitle: false,
        title: const Text(
          'Thông báo hệ thống',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 24,
            color: Colors.black87,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          roomsAsyncValue.maybeWhen(
            data: (rooms) => notificationsAsync.maybeWhen(
              data: (notifs) {
                final unreadCount = ref.watch(unreadNotificationCountProvider);
                if (unreadCount == 0) return const SizedBox.shrink();

                return IconButton(
                  tooltip: 'Đánh dấu đã đọc tất cả',
                  icon: const Icon(Icons.done_all_rounded, color: Colors.blue),
                  onPressed: () => markAllAsRead(notifs, rooms),
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),

      body: roomsAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Lỗi: $err')),
        data: (rooms) {
          return notificationsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Lỗi: $err')),
            data: (firestoreNotifs) {
              // ==========================================
              // KHỐI 1: CẢNH BÁO HỢP ĐỒNG
              // ==========================================
              final today = DateTime.now();
              List<Widget> contractCards = [];

              for (var room in rooms) {
                if (room.status == RoomStatus.rented &&
                    room.contractEndDate != null) {
                  final endDate = DateTime(
                    room.contractEndDate!.year,
                    room.contractEndDate!.month,
                    room.contractEndDate!.day,
                  );
                  final currentDate = DateTime(
                    today.year,
                    today.month,
                    today.day,
                  );
                  final daysLeft = endDate.difference(currentDate).inDays;

                  final isRead = readContracts.contains(
                    room.id,
                  ); // Kiểm tra xem đã đọc chưa

                  Widget? card;
                  if (daysLeft < 0) {
                    card = _buildAlertCard(
                      context: context,
                      ref: ref,
                      room: room,
                      isRead: isRead,
                      icon: Icons.warning_amber_rounded,
                      color: Colors.red.shade600,
                      bgColor: Colors.red.shade50,
                      title: 'Hợp đồng đã quá hạn!',
                      message:
                          'Phòng ${room.name} (${room.tenantName}) đã quá hạn hợp đồng ${daysLeft.abs()} ngày. Vui lòng xử lý ngay!',
                      dateText:
                          'Hết hạn từ: ${dateFormat.format(room.contractEndDate!)}',
                    );
                  } else if (daysLeft <= 3) {
                    card = _buildAlertCard(
                      context: context,
                      ref: ref,
                      room: room,
                      isRead: isRead,
                      icon: Icons.notification_important_outlined,
                      color: Colors.deepOrange.shade500,
                      bgColor: Colors.deepOrange.shade50,
                      title: daysLeft == 0
                          ? 'Hết hạn hợp đồng HÔM NAY'
                          : 'Sắp hết hạn hợp đồng: Còn $daysLeft ngày',
                      message:
                          'Hợp đồng của ${room.tenantName} tại ${room.name} sắp kết thúc. Hãy liên hệ khách để gia hạn hoặc làm thủ tục trả phòng.',
                      dateText:
                          'Ngày hết hạn: ${dateFormat.format(room.contractEndDate!)}',
                    );
                  } else if (daysLeft <= 30) {
                    card = _buildAlertCard(
                      context: context,
                      ref: ref,
                      room: room,
                      isRead: isRead,
                      icon: Icons.calendar_month_outlined,
                      color: Colors.blue.shade600,
                      bgColor: Colors.blue.shade50,
                      title: 'Đến hạn nhắc gia hạn hợp đồng',
                      message:
                          'Hợp đồng phòng ${room.name} (${room.tenantName}) sẽ hết hạn trong $daysLeft ngày nữa.',
                      dateText:
                          'Ngày hết hạn: ${dateFormat.format(room.contractEndDate!)}',
                    );
                  }

                  if (card != null) contractCards.add(card);
                }
              }

              // ==========================================
              // KHỐI 2: THÔNG BÁO TỪ FIREBASE (SỰ CỐ/THANH TOÁN)
              // ==========================================
              List<Widget> userNotifCards = [];
              for (var notif in firestoreNotifs) {
                final isRead = notif['isRead'] ?? true;
                final type = notif['type'] ?? 'info';
                final createdAt =
                    (notif['createdAt'] as Timestamp?)?.toDate() ??
                    DateTime.now();
                final invoiceId = notif['invoiceId']; // Lấy ID hóa đơn nếu có

                IconData iconData = Icons.notifications;
                Color iconColor = Colors.blue;
                Color iconBg = Colors.blue.shade50;

                if (type == 'incident') {
                  iconData = Icons.handyman_rounded;
                  iconColor = Colors.orange.shade700;
                  iconBg = Colors.orange.shade50;
                } else if (type == 'payment') {
                  iconData = Icons.payments_rounded;
                  iconColor = Colors.green.shade700;
                  iconBg = Colors.green.shade50;
                }

                userNotifCards.add(
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isRead
                          ? Colors.white
                          : Colors.blue.shade50.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isRead
                            ? Colors.transparent
                            : Colors.blue.shade100,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          markAsReadFirebase(notif['id'], isRead);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isRead
                                          ? Colors.grey.shade100
                                          : iconBg,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      iconData,
                                      color: isRead
                                          ? Colors.grey.shade400
                                          : iconColor,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                notif['title'] ?? 'Thông báo',
                                                style: TextStyle(
                                                  fontWeight: isRead
                                                      ? FontWeight.w600
                                                      : FontWeight.w800,
                                                  fontSize: 15,
                                                  color: isRead
                                                      ? Colors.grey.shade700
                                                      : Colors.blue.shade900,
                                                ),
                                              ),
                                            ),
                                            if (!isRead)
                                              Container(
                                                width: 10,
                                                height: 10,
                                                decoration: const BoxDecoration(
                                                  color: Colors.red,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          notif['message'] ?? '',
                                          style: TextStyle(
                                            color: isRead
                                                ? Colors.grey.shade500
                                                : Colors.blue.shade800,
                                            fontSize: 13,
                                            height: 1.4,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          DateFormat(
                                            'HH:mm - dd/MM/yyyy',
                                          ).format(createdAt),
                                          style: TextStyle(
                                            color: Colors.grey.shade400,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              // --- NÚT DUYỆT THANH TOÁN ---
                              // Chỉ hiện ra khi thông báo là loại payment, có mã hóa đơn và chưa bị đánh dấu đọc
                              if (type == 'payment' &&
                                  invoiceId != null &&
                                  !isRead) ...[
                                const SizedBox(height: 16),
                                const Divider(height: 1),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      onPressed: () {
                                        markAsReadFirebase(notif['id'], isRead);
                                      },
                                      child: const Text(
                                        'Bỏ qua',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton.icon(
                                      onPressed: () async {
                                        // 1. Chuyển hóa đơn thành Đã thanh toán (paid)
                                        await FirebaseFirestore.instance
                                            .collection('invoices')
                                            .doc(invoiceId)
                                            .update({'status': 'paid'});
                                        // 2. Đánh dấu thông báo đã đọc
                                        markAsReadFirebase(notif['id'], isRead);

                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Đã xác nhận thanh toán thành công!',
                                              ),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        }
                                      },
                                      icon: const Icon(
                                        Icons.check_circle,
                                        size: 18,
                                        color: Colors.white,
                                      ),
                                      label: const Text(
                                        'Xác nhận đã nhận tiền',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green.shade600,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
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

              // ==========================================
              // KHỐI 3: KẾT HỢP GIAO DIỆN
              // ==========================================
              if (contractCards.isEmpty && userNotifCards.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.notifications_active_outlined,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Tuyệt vời!',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Không có thông báo mới nào.',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  if (contractCards.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.only(left: 8, bottom: 12),
                      child: Text(
                        'CẢNH BÁO HỢP ĐỒNG',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.grey,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    ...contractCards,
                    const SizedBox(height: 16),
                  ],

                  if (userNotifCards.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.only(left: 8, bottom: 12),
                      child: Text(
                        'TỪ KHÁCH THUÊ',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.grey,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    ...userNotifCards,
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }

  // --- KHUNG GIAO DIỆN CHUẨN (CÓ XỬ LÝ GIAO DIỆN "ĐÃ ĐỌC") ---
  Widget _buildAlertCard({
    required BuildContext context,
    required WidgetRef ref,
    required RoomModel room,
    required bool isRead,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required String title,
    required String message,
    required String dateText,
  }) {
    final activeColor = isRead ? Colors.grey.shade400 : color;
    final activeBgColor = isRead ? Colors.grey.shade100 : bgColor;
    final activeTitleColor = isRead ? Colors.grey.shade700 : Colors.black87;
    final activeTextColor = isRead
        ? Colors.grey.shade500
        : Colors.grey.shade700;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRead ? Colors.transparent : color.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
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
          onTap: () {
            // Đánh dấu Đã đọc thông qua Notifier chuẩn mới
            ref.read(readContractAlertsProvider.notifier).markAsRead(room.id);

            // Chuyển sang trang chi tiết
            context.push('/admin/properties/detail', extra: room);
          },
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 6,
                  decoration: BoxDecoration(
                    color: activeColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: activeBgColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icon, color: activeColor, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: isRead
                                            ? FontWeight.w600
                                            : FontWeight.bold,
                                        color: activeTitleColor,
                                      ),
                                    ),
                                  ),
                                  if (!isRead)
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                message,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: activeTextColor,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  dateText,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ),
                            ],
                          ),
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
    );
  }
}
