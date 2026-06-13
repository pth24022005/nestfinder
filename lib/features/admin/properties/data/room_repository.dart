import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../properties_screen.dart';

// Cung cấp Repository
final roomRepositoryProvider = Provider<RoomRepository>((ref) {
  return RoomRepository();
});

// StreamProvider: Lắng nghe sự thay đổi của Database 24/7
final roomListStreamProvider = StreamProvider<List<RoomModel>>((ref) {
  final repo = ref.read(roomRepositoryProvider);
  return repo.streamRooms();
});

class RoomRepository {
  // Gọi trực tiếp đến kho lưu trữ của Firebase
  final _db = FirebaseFirestore.instance;

  // 1. Hàm lắng nghe danh sách phòng từ Collection 'rooms'
  Stream<List<RoomModel>> streamRooms() {
    return _db
        .collection('rooms')
        .orderBy('createdAt', descending: true) // Sắp xếp phòng mới tạo lên đầu
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();

            // Chuyển đổi trạng thái
            RoomStatus parsedStatus = RoomStatus.available;
            if (data['status'] == 'rented') parsedStatus = RoomStatus.rented;
            if (data['status'] == 'maintenance')
              parsedStatus = RoomStatus.maintenance;

            return RoomModel(
              id: doc.id,
              name: data['name'] ?? 'Phòng trống',
              status: parsedStatus,
              price: double.tryParse(data['price'].toString()) ?? 0.0,
              area: double.tryParse(data['area'].toString()),
              furniture: data['furniture'],
              description: data['description'],

              // --- KÉO DỮ LIỆU KHÁCH THUÊ VỀ ---
              tenantName: data['tenantName'],
              tenantPhone: data['tenantPhone'],
              tenantCCCD: data['tenantCCCD'],
              tenantAddress: data['tenantAddress'],
              contractDeposit: double.tryParse(
                data['contractDeposit'].toString(),
              ),
              contractStartDate: data['contractStartDate'] != null
                  ? DateTime.tryParse(data['contractStartDate'].toString())
                  : null,
              contractEndDate: data['contractEndDate'] != null
                  ? DateTime.tryParse(data['contractEndDate'].toString())
                  : null,
            );
          }).toList();
        });
  }

  // 2. Hàm Xóa phòng
  Future<void> deleteRoom(String roomId) async {
    try {
      await _db.collection('rooms').doc(roomId).delete();
    } catch (e) {
      throw Exception('Không thể xóa phòng: $e');
    }
  }

  // 3. Hàm Cập nhật thông tin phòng (Đã được đặt vào đúng vị trí bên trong class)
  Future<void> updateRoom(String roomId, Map<String, dynamic> data) async {
    try {
      await _db.collection('rooms').doc(roomId).update(data);
    } catch (e) {
      throw Exception('Không thể cập nhật phòng: $e');
    }
  }
}
