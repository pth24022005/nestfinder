import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

void main() {
  // Gom nhóm các bài test liên quan đến tính năng Quản lý Phòng
  group('Kiểm thử tính năng Quản lý Phòng trọ (Room Management)', () {
    test(
      'Thêm thành công hàng loạt 10 phòng mẫu và kiểm định dữ liệu đầu ra',
      () async {
        // ==========================================
        // 1. ARRANGE (Chuẩn bị môi trường & Dữ liệu)
        // ==========================================
        // Khởi tạo một Firebase giả lập trên RAM để test (Không đụng chạm database thật)
        final fakeFirestore = FakeFirebaseFirestore();
        final batch = fakeFirestore.batch();

        final sampleRooms = [
          {
            'name': 'P.101',
            'price': 3500000,
            'status': 'available',
            'area': 25.0,
          },
          {
            'name': 'P.102',
            'price': 3500000,
            'status': 'rented',
            'tenantName': 'Nguyễn Văn Tuấn',
          },
          {
            'name': 'P.103',
            'price': 3000000,
            'status': 'maintenance',
            'area': 20.0,
          },
          {
            'name': 'P.201',
            'price': 4000000,
            'status': 'rented',
            'tenantName': 'Trần Thu Hà',
          },
          {
            'name': 'P.202',
            'price': 3800000,
            'status': 'available',
            'area': 28.0,
          },
          {
            'name': 'P.203',
            'price': 3800000,
            'status': 'rented',
            'tenantName': 'Lê Hoàng Phong',
          },
          {
            'name': 'P.301',
            'price': 4500000,
            'status': 'available',
            'area': 35.0,
          },
          {
            'name': 'P.302',
            'price': 4200000,
            'status': 'rented',
            'tenantName': 'Phạm Quang Dũng',
          },
          {
            'name': 'P.303',
            'price': 3500000,
            'status': 'maintenance',
            'area': 25.0,
          },
          {
            'name': 'P.401',
            'price': 5500000,
            'status': 'rented',
            'tenantName': 'Đặng Mai Phương',
          },
        ];

        // ==========================================
        // 2. ACT (Thực thi hành động)
        // ==========================================
        for (var roomData in sampleRooms) {
          // Dùng fakeFirestore thay vì FirebaseFirestore.instance
          final docRef = fakeFirestore.collection('rooms').doc();
          batch.set(docRef, roomData);
        }
        // Commit đẩy dữ liệu vào Database giả
        await batch.commit();

        // Lấy toàn bộ dữ liệu từ Database giả về để kiểm tra
        final snapshot = await fakeFirestore.collection('rooms').get();
        final savedRooms = snapshot.docs;

        // ==========================================
        // 3. ASSERT (Kiểm định kết quả)
        // ==========================================

        // Kiểm định 1: Xác nhận số lượng phòng được lưu chính xác là 10
        expect(
          savedRooms.length,
          10,
          reason: 'Hệ thống phải lưu chính xác 10 phòng vào cơ sở dữ liệu',
        );

        // Kiểm định 2: Xác nhận phòng đầu tiên có đúng tên và giá không
        final firstRoom = savedRooms.firstWhere(
          (doc) => doc['name'] == 'P.101',
        );
        expect(firstRoom.exists, true, reason: 'Phải tồn tại phòng tên P.101');
        expect(
          firstRoom['price'],
          3500000,
          reason: 'Giá phòng P.101 phải là 3,500,000',
        );
        expect(
          firstRoom['status'],
          'available',
          reason: 'Trạng thái phòng P.101 phải là available',
        );

        // Kiểm định 3: Xác nhận logic dữ liệu khách thuê (Phòng rented phải có tên khách)
        final rentedRoom = savedRooms.firstWhere(
          (doc) => doc['name'] == 'P.102',
        );
        expect(rentedRoom['status'], 'rented');
        expect(
          rentedRoom['tenantName'],
          'Nguyễn Văn Tuấn',
          reason: 'Phòng P.102 phải có khách tên Tuấn',
        );

        // Nếu code chạy qua được toàn bộ các hàm expect() này mà không báo lỗi
        // -> BÀI TEST PASS XUẤT SẮC!
      },
    );
  });
}
