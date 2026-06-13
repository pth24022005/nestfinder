import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../properties/properties_screen.dart'; // Lấy RoomModel
import '../properties/data/room_repository.dart';

class NotificationsScreen extends HookConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsyncValue = ref.watch(roomListStreamProvider);
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Thông báo hệ thống',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: roomsAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Lỗi: $err')),
        data: (rooms) {
          final today = DateTime.now();
          // Danh sách chứa các thẻ thông báo UI
          List<Widget> notificationCards = [];

          for (var room in rooms) {
            // Chỉ kiểm tra những phòng đang có người thuê và có ngày kết thúc HĐ
            if (room.status == RoomStatus.rented &&
                room.contractEndDate != null) {
              // Tính số ngày còn lại (Chỉ tính mốc 0h để không bị sai lệch giờ)
              final endDate = DateTime(
                room.contractEndDate!.year,
                room.contractEndDate!.month,
                room.contractEndDate!.day,
              );
              final currentDate = DateTime(today.year, today.month, today.day);
              final daysLeft = endDate.difference(currentDate).inDays;

              // TÍNH TỔNG THỜI HẠN GỐC CỦA HỢP ĐỒNG NÀY (Đề phòng trường hợp hợp đồng thiếu ngày bắt đầu)
              int totalDuration = 365; // Gán mặc định là 1 năm
              if (room.contractStartDate != null) {
                totalDuration = room.contractEndDate!
                    .difference(room.contractStartDate!)
                    .inDays;
              }

              Widget? card;

              // Logic phân loại thông báo
              if (daysLeft < 0) {
                // 1. ĐÃ QUÁ HẠN
                card = _buildAlertCard(
                  context: context,
                  room: room,
                  icon: Icons.warning_amber_rounded,
                  color: Colors.red.shade700,
                  bgColor: Colors.red.shade50,
                  title: 'Hợp đồng đã quá hạn!',
                  message:
                      'Phòng ${room.name} (${room.tenantName}) đã quá hạn hợp đồng ${daysLeft.abs()} ngày. Vui lòng xử lý ngay!',
                  dateText:
                      'Hết hạn từ: ${dateFormat.format(room.contractEndDate!)}',
                );
              } else if (daysLeft <= 3) {
                // 2. GẤP: CÒN 0, 1, 2, 3 NGÀY
                card = _buildAlertCard(
                  context: context,
                  room: room,
                  icon: Icons.notification_important,
                  color: Colors.deepOrange,
                  bgColor: Colors.orange.shade50,
                  title: daysLeft == 0
                      ? 'Hết hạn hợp đồng HÔM NAY'
                      : 'Sắp hết hạn hợp đồng: Còn $daysLeft ngày',
                  message:
                      'Hợp đồng của ${room.tenantName} tại ${room.name} sắp kết thúc. Hãy liên hệ khách để gia hạn hoặc làm thủ tục trả phòng.',
                  dateText:
                      'Ngày hết hạn: ${dateFormat.format(room.contractEndDate!)}',
                );
              } else if (daysLeft <= 30) {
                // 3. NHẮC NHỞ: DƯỚI 1 THÁNG (<= 30 ngày)
                card = _buildAlertCard(
                  context: context,
                  room: room,
                  icon: Icons.calendar_month,
                  color: Colors.blue.shade600,
                  bgColor: Colors.blue.shade50,
                  title: 'Đến hạn nhắc gia hạn hợp đồng',
                  message:
                      'Hợp đồng phòng ${room.name} (${room.tenantName}) sẽ hết hạn trong $daysLeft ngày nữa.',
                  dateText:
                      'Ngày hết hạn: ${dateFormat.format(room.contractEndDate!)}',
                );
              } else if (totalDuration <= 31) {
                // 4. LOGIC MỚI: HỢP ĐỒNG NGẮN HÀN THEO THÁNG
                card = _buildAlertCard(
                  context: context,
                  room: room,
                  icon: Icons.access_time_rounded,
                  color: Colors.purple.shade600,
                  bgColor: Colors.purple.shade50,
                  title: 'Hợp đồng ngắn hạn (Theo tháng)',
                  message:
                      'Phòng ${room.name} (${room.tenantName}) đang áp dụng gia hạn ngắn hạn 1 tháng. Còn $daysLeft ngày là đến hạn chu kỳ.',
                  dateText:
                      'Hạn kế tiếp: ${dateFormat.format(room.contractEndDate!)}',
                );
              }

              if (card != null) {
                notificationCards.add(card);
              }
            }
          }

          if (notificationCards.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_active_outlined,
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Tuyệt vời!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Không có hợp đồng nào sắp hết hạn.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: notificationCards,
          );
        },
      ),
    );
  }

  // Khung giao diện chuẩn cho một thẻ thông báo
  Widget _buildAlertCard({
    required BuildContext context,
    required RoomModel room,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required String title,
    required String message,
    required String dateText,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Bấm vào thông báo sẽ nhảy thẳng vào màn hình Chi tiết phòng đó
            context.push('/admin/properties/detail', extra: room);
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: bgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        message,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          dateText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
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
      ),
    );
  }
}
