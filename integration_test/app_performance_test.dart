import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
// Import file main của ứng dụng bạn vào đây
import 'package:room_rental_app/main.dart' as app;

void main() {
  // Khởi tạo engine đo lường tích hợp
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Kiểm định Delay App @ 60 FPS', () {
    testWidgets('Kiểm tra độ mượt (Jank) khi cuộn danh sách', (
      WidgetTester tester,
    ) async {
      // Khởi chạy toàn bộ ứng dụng
      app.main();
      await tester.pumpAndSettle(); // Đợi app load xong giao diện ban đầu

      // Theo dõi hiệu năng (Timeline) trong quá trình thực hiện hành động
      await binding.traceAction(() async {
        // GIẢ LẬP HÀNH ĐỘNG: Tìm một danh sách cuộn được (ví dụ ListView) và cuộn nó
        // Lưu ý: Thay 'ListView' bằng kiểu widget danh sách bạn đang dùng nếu cần
        final listFinder = find.byType(Scrollable).first;

        // Nếu tìm thấy danh sách, thực hiện vuốt lên xuống để đo FPS
        if (listFinder.evaluate().isNotEmpty) {
          // Vuốt xuống 3 lần
          for (int i = 0; i < 3; i++) {
            await tester.fling(listFinder, const Offset(0, -300), 1000);
            await tester.pumpAndSettle();
          }
          // Vuốt lên 3 lần
          for (int i = 0; i < 3; i++) {
            await tester.fling(listFinder, const Offset(0, 300), 1000);
            await tester.pumpAndSettle();
          }
        }
      }, reportKey: 'scrolling_timeline');

      // Tóm tắt kết quả
      // File kết quả sẽ được lưu lại, bạn có thể phân tích xem frame time có < 16ms khô
    });
  });
}
