import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// =====================================================================
// 1. PROVIDER LẤY DỮ LIỆU SỰ CỐ TỪ FIREBASE
// =====================================================================
final tenantIncidentsProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, roomId) {
      return FirebaseFirestore.instance
          .collection('incidents')
          .where('roomId', isEqualTo: roomId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => {'id': doc.id, ...doc.data()})
                .toList(),
          );
    });

// =====================================================================
// 2. MÀN HÌNH DANH SÁCH SỰ CỐ
// =====================================================================
class TenantMaintenanceScreen extends HookConsumerWidget {
  final String roomId; // Nhận ID phòng từ màn hình Home truyền sang

  const TenantMaintenanceScreen({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incidentsAsync = ref.watch(tenantIncidentsProvider(roomId));

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        centerTitle: false,
        title: const Text(
          'Báo cáo sự cố',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 24,
            color: Colors.black87,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: incidentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Lỗi: $err')),
        data: (incidents) {
          if (incidents.isEmpty) {
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
                      Icons.handyman_outlined,
                      size: 64,
                      color: Colors.grey.shade300,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Mọi thứ đang hoạt động tốt!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Chưa có sự cố nào được ghi nhận.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: incidents.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final item = incidents[index];
              return _buildIncidentCard(item);
            },
          );
        },
      ),
      // --- NÚT BÁO CÁO MỚI ---
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateIncidentBottomSheet(context, roomId),
        backgroundColor: const Color(0xFF1C1C1E), // Đen nhám hiện đại
        elevation: 4,
        icon: const Icon(
          Icons.add_alert_rounded,
          color: Colors.white,
          size: 20,
        ),
        label: const Text(
          'BÁO SỰ CỐ',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  // Thẻ hiển thị một sự cố
  Widget _buildIncidentCard(Map<String, dynamic> data) {
    final dateFormat = DateFormat('HH:mm - dd/MM/yyyy');
    final createdAt =
        (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

    // Xử lý huy hiệu trạng thái
    final status = data['status'] ?? 'pending';
    String statusText = 'Chờ xử lý';
    Color statusColor = Colors.orange;
    Color statusBg = Colors.orange.shade50;
    IconData statusIcon = Icons.pending_actions;

    if (status == 'processing') {
      statusText = 'Đang sửa chữa';
      statusColor = Colors.blue.shade700;
      statusBg = Colors.blue.shade50;
      statusIcon = Icons.engineering_outlined;
    } else if (status == 'done') {
      statusText = 'Đã khắc phục';
      statusColor = Colors.green.shade700;
      statusBg = Colors.green.shade50;
      statusIcon = Icons.check_circle_outline;
    }

    return Container(
      padding: const EdgeInsets.all(20),
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  data['category'] ?? 'Khác',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            data['title'] ?? 'Không có tiêu đề',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            data['description'] ?? '',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: Colors.black12),
          ),
          Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                size: 14,
                color: Colors.grey.shade400,
              ),
              const SizedBox(width: 6),
              Text(
                'Gửi lúc: ${dateFormat.format(createdAt)}',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =====================================================================
  // 3. BOTTOM SHEET GỬI YÊU CẦU MỚI
  // =====================================================================
  void _showCreateIncidentBottomSheet(BuildContext context, String roomId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateIncidentForm(roomId: roomId),
    );
  }
}

class CreateIncidentForm extends HookWidget {
  final String roomId;
  const CreateIncidentForm({super.key, required this.roomId});

  @override
  Widget build(BuildContext context) {
    final titleController = useTextEditingController();
    final descController = useTextEditingController();
    final selectedCategory = useState<String>('Điện');
    final isLoading = useState<bool>(false);

    final categories = ['Điện', 'Nước', 'Nội thất', 'Mạng/Wifi', 'Khác'];

    Future<void> submitIncident() async {
      FocusScope.of(context).unfocus();
      if (titleController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng nhập tóm tắt sự cố'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      try {
        isLoading.value = true;
        final firestore = FirebaseFirestore.instance;

        // Sử dụng Batch để chạy 2 lệnh lưu cùng lúc
        final batch = firestore.batch();

        // 1. Tạo bản ghi Sự cố mới
        final incidentRef = firestore.collection('incidents').doc();
        batch.set(incidentRef, {
          'roomId': roomId,
          'category': selectedCategory.value,
          'title': titleController.text.trim(),
          'description': descController.text.trim(),
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        });

        // 2. Tạo Thông báo gửi cho Admin
        final notifRef = firestore.collection('notifications').doc();
        batch.set(notifRef, {
          'title': '🔧 Báo cáo sự cố mới',
          'message':
              'Phân loại: ${selectedCategory.value} - ${titleController.text.trim()}',
          'type': 'incident',
          'isRead': false, // Mặc định là chưa đọc
          'roomId': roomId,
          'referenceId':
              incidentRef.id, // Lưu ID sự cố để admin bấm vào xem chi tiết
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Thực thi toàn bộ lệnh trong Batch
        await batch.commit();

        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã gửi báo cáo sự cố đến quản lý!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
          );
      } finally {
        isLoading.value = false;
      }
    }

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const Text(
              'Báo cáo sự cố',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Quản lý sẽ nhận được thông báo và xử lý sớm nhất.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 24),

            // Chọn danh mục (Chips)
            const Text(
              'PHÂN LOẠI SỰ CỐ',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Colors.grey,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: categories.map((cat) {
                final isSelected = selectedCategory.value == cat;
                return InkWell(
                  onTap: () => selectedCategory.value = cat,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.orange.shade50
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? Colors.orange.shade400
                            : Colors.transparent,
                      ),
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.orange.shade800
                            : Colors.black87,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Nhập tiêu đề
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F5F7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: titleController,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Tóm tắt sự cố (VD: Vòi nước bị rỉ)',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Nhập chi tiết
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F5F7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: descController,
                maxLines: 4,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText:
                      'Mô tả chi tiết để thợ dễ chuẩn bị đồ (Không bắt buộc)...',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Nút Gửi
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading.value ? null : submitIncident,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1C1C1E),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: isLoading.value
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'GỬI YÊU CẦU',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
