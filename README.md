# room_rental_app
# Ứng dụng Quản lý Phòng trọ - NestFinder

A new Flutter project.
Đây là một dự án ứng dụng di động được xây dựng bằng Flutter, nhằm mục đích đơn giản hóa và tự động hóa việc quản lý phòng trọ cho cả chủ nhà (Admin) và khách thuê (Tenant). Ứng dụng cung cấp hai giao diện riêng biệt với các chức năng được tối ưu hóa cho từng vai trò.

## Getting Started
## ✨ Tính năng nổi bật

This project is a starting point for a Flutter application.
### 👨‍💼 Dành cho Chủ trọ (Admin)

A few resources to get you started if this is your first Flutter project:
*   **🔑 Quản lý phòng:** Thêm, sửa, xóa phòng với đầy đủ thông tin (diện tích, giá, nội thất, trạng thái).
*   **📊 Dashboard tổng quan:** (Dự kiến) Hiển thị các số liệu quan trọng như doanh thu, số phòng trống, số phòng đã thuê.
*   **📂 Quản lý khách thuê:** Lưu trữ thông tin khách thuê, xem danh bạ và công nợ hiện tại của từng khách.
*   **📝 Quản lý hợp đồng:** Tạo hợp đồng mới khi có khách vào, gia hạn hợp đồng khi sắp hết hạn.
*   **⚡️ Chốt điện nước & Hóa đơn:** Ghi chỉ số điện, nước cuối tháng và tự động tạo hóa đơn chi tiết cho khách thuê.
*   **🔔 Hệ thống thông báo thông minh:**
    *   Nhận cảnh báo khi hợp đồng của khách sắp hết hạn hoặc đã quá hạn.
    *   Nhận yêu cầu báo cáo sự cố (hỏng điện, nước,...) từ khách thuê.
    *   Nhận yêu cầu xác nhận thanh toán khi khách báo đã chuyển khoản.
*   **✅ Xác nhận thanh toán:** Duyệt các yêu cầu thanh toán từ khách thuê, tự động cập nhật trạng thái hóa đơn.
*   **🔍 Tìm kiếm & Lọc:** Dễ dàng tìm kiếm phòng, khách thuê và lọc danh sách phòng theo trạng thái hoặc giá.

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)
### 🧍 Dành cho Khách thuê (Tenant)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
*   **📄 Xem thông tin:** Xem chi tiết thông tin phòng, hợp đồng thuê và các chi phí dịch vụ.
*   **🧾 Lịch sử hóa đơn:** Theo dõi tất cả các hóa đơn tiền nhà hàng tháng.
*   **🛠 Báo cáo sự cố:** Gửi yêu cầu sửa chữa (điện, nước, nội thất, wifi,...) trực tiếp đến chủ nhà kèm mô tả chi tiết.
*   **💳 Thanh toán QR:** Thanh toán tiền phòng tiện lợi và an toàn thông qua mã QR động (VietQR) được tạo tự động với đúng số tiền và nội dung chuyển khoản.
*   **📬 Gửi xác nhận:** Sau khi chuyển khoản, khách thuê có thể bấm nút "Tôi đã chuyển khoản" để gửi thông báo tức thì đến cho chủ nhà.

## 🚀 Công nghệ sử dụng

*   **Framework:** [Flutter](https://flutter.dev/)
*   **Ngôn ngữ:** [Dart](https://dart.dev/)
*   **Backend & Database:** [Firebase (Cloud Firestore)](https://firebase.google.com/products/firestore)
*   **State Management:** [Riverpod](https://riverpod.dev/) (kết hợp `flutter_riverpod`, `hooks_riverpod`)
*   **Routing:** GoRouter
*   **UI/State Hooks:** Flutter Hooks
*   **Formatting:** Intl
*   **Kiến trúc:** Feature-First (Tách biệt code theo từng chức năng và vai trò người dùng).

## 📂 Cấu trúc thư mục

Dự án được tổ chức theo kiến trúc `Feature-First`, giúp dễ dàng bảo trì và mở rộng.

```
lib
├── core/                  # Các thành phần cốt lõi, dùng chung
│   ├── router/            # Cấu hình GoRouter
│   └── ...
│
├── features/              # Thư mục chính chứa các tính năng
│   ├── admin/             # Các tính năng của Admin
│   │   ├── dashboard/
│   │   ├── properties/    # Quản lý phòng
│   │   ├── tenants/       # Quản lý khách thuê
│   │   └── ...
│   │
│   ├── auth/              # Xác thực (Login)
│   │
│   └── tenant/            # Các tính năng của Khách thuê
│       ├── home/
│       ├── invoices/
│       └── maintenance/
│
└── main.dart              # Entry point của ứng dụng
```

## 🏁 Bắt đầu

Để chạy dự án trên máy của bạn, hãy làm theo các bước sau:

1.  **Clone a repository:**
    ```sh
    git clone https://your-repository-url.git
    cd room_rental_app
    ```

2.  **Cài đặt Flutter và cấu hình Firebase:**
    *   Đảm bảo bạn đã cài đặt Flutter SDK.
    *   Tạo một dự án mới trên Firebase Console.
    *   Thêm ứng dụng Android và/hoặc iOS vào dự án Firebase.
    *   Tải file cấu hình `google-services.json` (cho Android) và đặt vào thư mục `android/app/`.
    *   Tải file `GoogleService-Info.plist` (cho iOS) và đặt vào thư mục `ios/Runner/` thông qua Xcode.
    *   Trong Firebase Console, vào mục **Firestore Database** và tạo một cơ sở dữ liệu mới ở chế độ test hoặc production.

3.  **Cài đặt các dependencies:**
    ```sh
    flutter pub get
    ```

4.  **Chạy ứng dụng:**
    ```sh
    flutter run
    ```
