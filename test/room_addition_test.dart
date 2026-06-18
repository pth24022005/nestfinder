import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

void main() {
  group('Kiểm thử logic Firestore (Unit Test) - NestFinder', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      // Khởi tạo Database giả lập trước mỗi test case
      fakeFirestore = FakeFirebaseFirestore();
    });

    test('Thêm thành công 10 phòng và kiểm tra dữ liệu P.101, P.102', () async {
      // 1. Arrange: Chuẩn bị dữ liệu
      final batch = fakeFirestore.batch();
      final roomsCollection = fakeFirestore.collection('rooms');

      for (int i = 1; i <= 10; i++) {
        final docRef = roomsCollection.doc('room_$i');
        batch.set(docRef, {
          'name': 'P.10$i',
          'price': 3500000 + (i * 100000),
          'status': i % 2 == 0 ? 'rented' : 'available',
          'tenantName': i % 2 == 0 ? 'Khách thuê $i' : null,
        });
      }

      // 2. Act: Thực thi hành động ghi vào Database
      await batch.commit();

      // 3. Assert: Kiểm định kết quả
      final snapshot = await roomsCollection.get();

      // Kiểm tra xem đã tạo đủ 10 phòng chưa
      expect(snapshot.docs.length, 10);

      // Lấy dữ liệu phòng P.101 (Phòng số 1 - available)
      final room101 = snapshot.docs.firstWhere((doc) => doc['name'] == 'P.101');
      expect(room101['status'], 'available');
      expect(room101['tenantName'], isNull); // Phòng trống không có khách

      // Lấy dữ liệu phòng P.102 (Phòng số 2 - rented)
      final room102 = snapshot.docs.firstWhere((doc) => doc['name'] == 'P.102');
      expect(room102['status'], 'rented');
      expect(room102['tenantName'], 'Khách thuê 2'); // Đã có khách
      expect(room102['price'], 3700000);
    });
  });
}
