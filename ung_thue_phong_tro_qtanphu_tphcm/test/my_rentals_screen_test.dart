import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ung_thue_phong_tro_qtanphu_tphcm/models/entities/rental.dart';
import 'package:ung_thue_phong_tro_qtanphu_tphcm/views/screens/tenant/my_rentals_screen.dart';
import 'package:ung_thue_phong_tro_qtanphu_tphcm/controllers/booking_controller.dart';
import 'package:ung_thue_phong_tro_qtanphu_tphcm/controllers/providers/bill_provider.dart';

void main() {
  group('MyRentalsScreen Headless Robot Simulation Test', () {
    testWidgets('1. Happy Path - Displays active rental contracts correctly', (WidgetTester tester) async {
      final activeRental = Rental(
        id: 'rental_001',
        roomId: 'room_001',
        roomTitle: 'Phòng Trọ VIP 1',
        roomAddress: '123 Lũy Bán Bích, Tân Phú',
        tenantId: 'tenant_001',
        tenantName: 'Lê Hoàng Nam',
        landlordId: 'landlord_001',
        monthlyRent: 3500000,
        startDate: DateTime.now().subtract(const Duration(days: 10)),
        endDate: DateTime.now().add(const Duration(days: 170, hours: 2)),
        status: RentalStatus.active,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tenantRentalsProvider.overrideWith((ref) => Stream.value([activeRental])),
            billsProvider.overrideWith((ref, tenantId) => Stream.value([])),
          ],
          child: const MaterialApp(
            home: MyRentalsScreen(),
          ),
        ),
      );

      // Cho phép stream phát ra dữ liệu và widget rebuild
      await tester.pumpAndSettle();

      // Verify active rental details display
      expect(find.text('Phòng Trọ VIP 1'), findsOneWidget);
      expect(find.text('123 Lũy Bán Bích, Tân Phú'), findsOneWidget);
      expect(find.text('ĐANG THUÊ'), findsOneWidget);
      expect(find.text('3.500.000đ/tháng'), findsOneWidget);
      expect(find.text('Còn 170 ngày đến hạn hợp đồng'), findsOneWidget);
    });

    testWidgets('2. Escrow Scenario - Displays platform escrow banner and buttons on pending', (WidgetTester tester) async {
      final pendingRental = Rental(
        id: 'rental_002',
        roomId: 'room_002',
        roomTitle: 'Phòng Trọ VIP 2',
        roomAddress: '456 Hòa Bình, Tân Phú',
        tenantId: 'tenant_001',
        tenantName: 'Lê Hoàng Nam',
        landlordId: 'landlord_001',
        monthlyRent: 4000000,
        startDate: DateTime.now().add(const Duration(days: 2)),
        endDate: DateTime.now().add(const Duration(days: 182)),
        status: RentalStatus.pending,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tenantRentalsProvider.overrideWith((ref) => Stream.value([pendingRental])),
            billsProvider.overrideWith((ref, tenantId) => Stream.value([])),
          ],
          child: const MaterialApp(
            home: MyRentalsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify pending/escrow components display
      expect(find.text('Phòng Trọ VIP 2'), findsOneWidget);
      expect(find.text('CỌC GIỮ CHỖ'), findsOneWidget);
      expect(find.text('Đang được Bảo lãnh bởi Platform'), findsOneWidget);
      expect(find.text('Hủy cọc'), findsOneWidget);
      expect(find.text('Xác nhận thuê'), findsOneWidget);
    });

    testWidgets('3. Empty Scenario - Displays beautiful empty state when no rentals exist', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tenantRentalsProvider.overrideWith((ref) => Stream.value([])),
            billsProvider.overrideWith((ref, tenantId) => Stream.value([])),
          ],
          child: const MaterialApp(
            home: MyRentalsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify empty text and icons
      expect(find.text('Bạn chưa thuê phòng nào'), findsOneWidget);
      expect(find.byIcon(Icons.home_outlined), findsOneWidget);
    });

    testWidgets('4. Verified Reviews - Displays review button and opens review bottom sheet', (WidgetTester tester) async {
      final activeRental = Rental(
        id: 'rental_001',
        roomId: 'room_001',
        roomTitle: 'Phòng Trọ VIP 1',
        roomAddress: '123 Lũy Bán Bích, Tân Phú',
        tenantId: 'tenant_001',
        tenantName: 'Lê Hoàng Nam',
        landlordId: 'landlord_001',
        monthlyRent: 3500000,
        startDate: DateTime.now().subtract(const Duration(days: 10)),
        endDate: DateTime.now().add(const Duration(days: 170, hours: 2)),
        status: RentalStatus.active,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tenantRentalsProvider.overrideWith((ref) => Stream.value([activeRental])),
            billsProvider.overrideWith((ref, tenantId) => Stream.value([])),
          ],
          child: const MaterialApp(
            home: MyRentalsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify the review button exists
      expect(find.text('Đánh giá chủ trọ'), findsOneWidget);

      // Tap on the review button
      await tester.tap(find.text('Đánh giá chủ trọ'));
      await tester.pumpAndSettle();

      // Verify bottom sheet title is visible
      expect(find.text('Đánh giá Chủ trọ'), findsOneWidget);
      expect(find.text('Nhận xét của bạn về trải nghiệm tại "Phòng Trọ VIP 1"'), findsOneWidget);
      expect(find.text('Gửi đánh giá ngay'), findsOneWidget);
    });

    testWidgets('5. Clean Up Scenario - Displays Xóa giao dịch button on cancelled status and opens confirmation dialog', (WidgetTester tester) async {
      final cancelledRental = Rental(
        id: 'rental_003',
        roomId: 'room_003',
        roomTitle: 'Phòng Trọ VIP 3',
        roomAddress: '789 Trường Chinh, Tân Phú',
        tenantId: 'tenant_001',
        tenantName: 'Lê Hoàng Nam',
        landlordId: 'landlord_001',
        monthlyRent: 3200000,
        startDate: DateTime.now().subtract(const Duration(days: 5)),
        endDate: DateTime.now().add(const Duration(days: 25)),
        status: RentalStatus.cancelled,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tenantRentalsProvider.overrideWith((ref) => Stream.value([cancelledRental])),
            billsProvider.overrideWith((ref, tenantId) => Stream.value([])),
          ],
          child: const MaterialApp(
            home: MyRentalsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify card details and cancelled status
      expect(find.text('Phòng Trọ VIP 3'), findsOneWidget);
      expect(find.text('ĐÃ HỦY'), findsOneWidget);
      
      // Verify delete button is visible
      expect(find.text('Xóa giao dịch'), findsOneWidget);

      // Tap delete button
      await tester.tap(find.text('Xóa giao dịch'));
      await tester.pumpAndSettle();

      // Verify confirmation dialog shows up
      expect(find.text('Xóa lịch sử giao dịch?'), findsOneWidget);
      expect(find.text('Hủy'), findsOneWidget);
      expect(find.text('Xóa vĩnh viễn'), findsOneWidget);
    });
  });
}
