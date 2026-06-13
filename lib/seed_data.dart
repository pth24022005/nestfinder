import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart'; // Đảm bảo bạn đã cấu hình Firebase

Future<void> main() async {
  // 1. Khởi tạo Firebase độc lập
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  print('\n=======================================');
  print('🚀 BẮT ĐẦU BƠM DỮ LIỆU PHÒNG MẪU LÊN FIREBASE...');
  print('=======================================\n');

  final firestore = FirebaseFirestore.instance;
  final batch = firestore.batch();

  // 2. Dữ liệu 10 phòng mẫu
  final sampleRooms = [
    {
      'name': 'P.101',
      'price': 3500000,
      'status': 'available',
      'area': 25.0,
      'furniture': 'Điều hòa, Nóng lạnh, Giường',
      'description': 'Phòng tầng 1, tiện đi lại',
    },
    {
      'name': 'P.102',
      'price': 3500000,
      'status': 'rented',
      'area': 25.0,
      'furniture': 'Full nội thất',
      'description': 'Khách ngoan, đóng tiền đúng hạn',
      'tenantName': 'Nguyễn Văn Tuấn',
      'tenantPhone': '0987654321',
      'tenantCCCD': '001201012345',
      'tenantAddress': 'Cầu Giấy, Hà Nội',
      'contractDeposit': 3500000.0,
      'contractStartDate': DateTime.now()
          .subtract(const Duration(days: 30))
          .toIso8601String(),
      'contractEndDate': DateTime.now()
          .add(const Duration(days: 150))
          .toIso8601String(),
    },
    {
      'name': 'P.103',
      'price': 3000000,
      'status': 'maintenance',
      'area': 20.0,
      'furniture': 'Trống',
      'description': 'Đang sửa vỡ ống nước nhà vệ sinh',
    },
    {
      'name': 'P.201',
      'price': 4000000,
      'status': 'rented',
      'area': 30.0,
      'furniture': 'Điều hòa, Tủ lạnh mini, Giường 1m6',
      'description': '',
      'tenantName': 'Trần Thu Hà',
      'tenantPhone': '0912345678',
      'tenantCCCD': '034199001122',
      'tenantAddress': 'Hải Hậu, Nam Định',
      'contractDeposit': 4000000.0,
      'contractStartDate': DateTime.now()
          .subtract(const Duration(days: 90))
          .toIso8601String(),
      'contractEndDate': DateTime.now()
          .add(const Duration(days: 90))
          .toIso8601String(),
    },
    {
      'name': 'P.202',
      'price': 3800000,
      'status': 'available',
      'area': 28.0,
      'furniture': 'Cơ bản',
      'description': 'Vừa sơn lại tường mới tinh',
    },
    {
      'name': 'P.203',
      'price': 3800000,
      'status': 'rented',
      'area': 28.0,
      'furniture': 'Cơ bản',
      'description': '',
      'tenantName': 'Lê Hoàng Phong',
      'tenantPhone': '0888999777',
      'tenantCCCD': '038095000111',
      'tenantAddress': 'Thanh Hóa',
      'contractDeposit': 3800000.0,
      'contractStartDate': DateTime.now()
          .subtract(const Duration(days: 10))
          .toIso8601String(),
      'contractEndDate': DateTime.now()
          .add(const Duration(days: 170))
          .toIso8601String(),
    },
    {
      'name': 'P.301 (Ban công)',
      'price': 4500000,
      'status': 'available',
      'area': 35.0,
      'furniture': 'Full nội thất, Máy giặt riêng',
      'description': 'Phòng VIP tầng 3, view thoáng',
    },
    {
      'name': 'P.302',
      'price': 4200000,
      'status': 'rented',
      'area': 32.0,
      'furniture': 'Điều hòa, Nóng lạnh',
      'description': 'Cho sinh viên thuê',
      'tenantName': 'Phạm Quang Dũng',
      'tenantPhone': '0707123123',
      'tenantCCCD': '001099000999',
      'tenantAddress': 'Ninh Bình',
      'contractDeposit': 4200000.0,
      'contractStartDate': DateTime.now()
          .subtract(const Duration(days: 60))
          .toIso8601String(),
      'contractEndDate': DateTime.now()
          .add(const Duration(days: 120))
          .toIso8601String(),
    },
    {
      'name': 'P.303',
      'price': 3500000,
      'status': 'maintenance',
      'area': 25.0,
      'furniture': 'Tủ quần áo, Giường',
      'description': 'Đang chờ thợ thay lại cửa sổ',
    },
    {
      'name': 'P.401 (Penthouse)',
      'price': 5500000,
      'status': 'rented',
      'area': 45.0,
      'furniture': 'Cao cấp, Bếp riêng',
      'description': 'Vợ chồng trẻ ở',
      'tenantName': 'Đặng Mai Phương',
      'tenantPhone': '0933444555',
      'tenantCCCD': '001192004444',
      'tenantAddress': 'Hoàn Kiếm, Hà Nội',
      'contractDeposit': 5500000.0,
      'contractStartDate': DateTime.now()
          .subtract(const Duration(days: 200))
          .toIso8601String(),
      'contractEndDate': DateTime.now()
          .add(const Duration(days: 160))
          .toIso8601String(),
    },
  ];

  // 3. Đẩy dữ liệu
  for (var roomData in sampleRooms) {
    final docRef = firestore.collection('rooms').doc();
    roomData['createdAt'] = FieldValue.serverTimestamp();
    batch.set(docRef, roomData);
  }

  await batch.commit();

  print('\n=======================================');
  print('✅ HOÀN TẤT! ĐÃ TẠO XONG 10 PHÒNG MẪU.');
  print('Vui lòng tắt trình chạy này và mở lại App chính.');
  print('=======================================\n');

  // Chạy một màn hình tạm thời báo hoàn thành để giữ máy ảo không bị crash
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Text(
            '✅ Đã bơm xong dữ liệu!\nBạn có thể đóng màn hình này lại.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ),
      ),
    ),
  );
}
