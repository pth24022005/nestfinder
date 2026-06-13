import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'properties_screen.dart';
import 'data/room_repository.dart';

class CreateContractScreen extends HookConsumerWidget {
  final RoomModel room;

  const CreateContractScreen({super.key, required this.room});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // --- THÔNG MINH HÓA CONTROLLER: Nếu là gia hạn, điền sẵn thông tin cũ ---
    final tenantNameController = useTextEditingController(
      text: room.tenantName,
    );
    final tenantPhoneController = useTextEditingController(
      text: room.tenantPhone,
    );
    final cccdController = useTextEditingController(text: room.tenantCCCD);
    final addressController = useTextEditingController(
      text: room.tenantAddress,
    );

    final depositController = useTextEditingController(
      text: room.contractDeposit != null
          ? room.contractDeposit!.toInt().toString()
          : '',
    );

    // Ngày bắt đầu: Nếu gia hạn thì lấy ngày hết hạn cũ làm mốc bắt đầu mới, ngược lại lấy ngày hôm nay
    final startDate = useState<DateTime>(
      room.contractEndDate ?? DateTime.now(),
    );
    // Ngày kết thúc: Tự động cộng thêm 180 ngày (6 tháng)
    final endDate = useState<DateTime>(
      (room.contractEndDate ?? DateTime.now()).add(const Duration(days: 180)),
    );

    final isLoading = useState<bool>(false);
    final dateFormat = DateFormat('dd/MM/yyyy');
    final isRenewing =
        room.status ==
        RoomStatus
            .rented; // Biến kiểm tra xem có phải đang đi luồng gia hạn không

    Future<void> _selectDate(
      BuildContext context,
      ValueNotifier<DateTime> dateState, {
      bool isStart = true,
    }) async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: dateState.value,
        firstDate: isStart ? DateTime(2020) : startDate.value,
        lastDate: DateTime(2035),
      );
      if (picked != null && picked != dateState.value) {
        dateState.value = picked;
        if (isStart && picked.isAfter(endDate.value)) {
          endDate.value = picked.add(const Duration(days: 180));
        }
      }
    }

    Future<void> _submitContract() async {
      final name = tenantNameController.text.trim();
      final phone = tenantPhoneController.text.trim();
      final cccd = cccdController.text.trim();
      final address = addressController.text.trim();
      final depositText = depositController.text.trim();

      if (name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng nhập tên khách thuê'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (phone.isEmpty || phone.length < 9) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Số điện thoại không hợp lệ'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      double deposit = 0;
      if (depositText.isNotEmpty) {
        final rawDeposit = depositText.replaceAll(RegExp(r'[., ]'), '');
        deposit = double.tryParse(rawDeposit) ?? 0;
      }

      try {
        isLoading.value = true;

        final updateData = {
          'status': 'rented',
          'tenantName': name,
          'tenantPhone': phone,
          'tenantCCCD': cccd,
          'tenantAddress': address,
          'contractDeposit': deposit,
          'contractStartDate': startDate.value.toIso8601String(),
          'contractEndDate': endDate.value.toIso8601String(),
          'extendedAt': isRenewing
              ? FieldValue.serverTimestamp()
              : null, // Nhật ký ghi nhận thời gian gia hạn
        };

        await ref.read(roomRepositoryProvider).updateRoom(room.id, updateData);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isRenewing
                    ? 'Gia hạn hợp đồng thành công!'
                    : 'Tạo hợp đồng thành công!',
              ),
              backgroundColor: Colors.green,
            ),
          );
          context.pop();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        isLoading.value = false;
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          isRenewing
              ? 'Gia hạn hợp đồng - ${room.name}'
              : 'Tạo hợp đồng - ${room.name}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hồ sơ khách thuê',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: tenantNameController,
              label: 'Họ và tên người đại diện',
              icon: Icons.person,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: tenantPhoneController,
              label: 'Số điện thoại',
              icon: Icons.phone,
              isNumber: true,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: cccdController,
              label: 'Số CCCD/CMND',
              icon: Icons.badge,
              isNumber: true,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: addressController,
              label: 'Địa chỉ thường trú',
              icon: Icons.location_on,
              maxLines: 2,
            ),
            const SizedBox(height: 32),

            const Text(
              'Thông tin hợp đồng mới',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: depositController,
              label: 'Tiền cọc mới (VNĐ)',
              icon: Icons.monetization_on,
              isNumber: true,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: InkWell(
                    // NẾU LÀ GIA HẠN -> KHÓA BẤM (null), NẾU LÀ TẠO MỚI -> CHO CHỌN NGÀY
                    onTap: isRenewing
                        ? null
                        : () => _selectDate(context, startDate, isStart: true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                        // Nếu bị khóa thì đổi nền sang màu xám nhạt cho người dùng biết
                        color: isRenewing
                            ? Colors.grey.shade100
                            : Colors.grey.shade50,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Đổi nhãn thông báo trực quan
                          Text(
                            isRenewing
                                ? 'Ngày bắt đầu (Cố định theo HĐ cũ)'
                                : 'Ngày bắt đầu',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: isRenewing ? Colors.grey : Colors.blue,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                dateFormat.format(startDate.value),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  // Đổi màu chữ xám nếu bị khóa
                                  color: isRenewing
                                      ? Colors.grey.shade600
                                      : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, endDate, isStart: false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey.shade50,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ngày kết thúc mới',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.event_available,
                                size: 16,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                dateFormat.format(endDate.value),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: isLoading.value ? null : _submitContract,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isLoading.value
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      isRenewing ? 'Xác nhận gia hạn' : 'Xác nhận cho thuê',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isNumber = false,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Padding(
          padding: EdgeInsets.only(bottom: maxLines > 1 ? 24 : 0),
          child: Icon(icon),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }
}
