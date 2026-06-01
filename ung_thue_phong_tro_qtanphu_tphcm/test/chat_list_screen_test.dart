import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ung_thue_phong_tro_qtanphu_tphcm/models/entities/user.dart';
import 'package:ung_thue_phong_tro_qtanphu_tphcm/views/screens/shared/chat_list_screen.dart';
import 'package:ung_thue_phong_tro_qtanphu_tphcm/controllers/chat_controller.dart';
import 'package:ung_thue_phong_tro_qtanphu_tphcm/controllers/auth_controller.dart';

void main() {
  group('ChatListScreen Headless Robot Simulation Test', () {
    testWidgets('1. Happy Path - Displays active chat conversations successfully', (WidgetTester tester) async {
      final mockTenant = AppUser(
        id: 'tenant_001',
        fullName: 'Lê Hoàng Nam',
        email: 'namle@email.com',
        phone: '0901234567',
        role: UserRole.tenant,
        createdAt: DateTime.now(),
      );

      final mockChatRoom = ChatRoom(
        id: 'tenant_001_landlord_001',
        tenantId: 'tenant_001',
        landlordId: 'landlord_001',
        tenantName: 'Lê Hoàng Nam',
        landlordName: 'Nguyễn Văn An',
        lastMessage: 'Chào bạn, tôi muốn hẹn lịch xem phòng trọ.',
        lastMessageTime: DateTime.now().subtract(const Duration(minutes: 5)),
        unreadByTenant: 1,
        unreadByLandlord: 0,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWithValue(mockTenant),
            myChatsProvider.overrideWith((ref) => Stream.value([mockChatRoom])),
          ],
          child: const MaterialApp(
            home: ChatListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Khi mình là Tenant thì tên đối phương hiển thị phải là LandlordName (Nguyễn Văn An)
      expect(find.text('Nguyễn Văn An'), findsOneWidget);
      expect(find.text('Chào bạn, tôi muốn hẹn lịch xem phòng trọ.'), findsOneWidget);
      // Có 1 tin nhắn chưa đọc đối với Tenant, xác minh Badge 1 hiển thị
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('2. Empty State - Displays descriptive message when chat list is empty', (WidgetTester tester) async {
      final mockTenant = AppUser(
        id: 'tenant_001',
        fullName: 'Lê Hoàng Nam',
        email: 'namle@email.com',
        phone: '0901234567',
        role: UserRole.tenant,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWithValue(mockTenant),
            myChatsProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: const MaterialApp(
            home: ChatListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Xác minh UI thông báo trống hiển thị
      expect(find.text('Chưa có cuộc trò chuyện nào'), findsOneWidget);
      expect(find.text('Hãy liên hệ chủ nhà để trao đổi về phòng!'), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
    });
  });
}
