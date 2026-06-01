import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ung_thue_phong_tro_qtanphu_tphcm/models/entities/room.dart';
import 'package:ung_thue_phong_tro_qtanphu_tphcm/views/widgets/cards/room_card.dart';

void main() {
  group('RoomCard Headless Robot Simulation Test', () {
    testWidgets('1. Happy Path - Renders complete Room details successfully', (WidgetTester tester) async {
      final happyRoom = Room(
        id: 'room_tanphu_001',
        title: 'Phòng Trọ Ban Công Lớn',
        address: '452 Lũy Bán Bích, Quận Tân Phú',
        district: 'Quận Tân Phú',
        area: 28.0,
        price: 3800000,
        status: RoomStatus.available,
        images: ['https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=600&q=80'],
        amenities: ['Điều hòa', 'WiFi'],
        description: 'Mô tả phòng mẫu',
        landlordId: 'landlord_001',
        latitude: 10.781682,
        longitude: 106.637821,
        createdAt: DateTime.now(),
      );

      // Build the RoomCard inside a Material skeleton
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoomCard(room: happyRoom),
          ),
        ),
      );

      // Verify basic widgets render
      expect(find.text('Phòng Trọ Ban Công Lớn'), findsOneWidget);
      expect(find.text('452 Lũy Bán Bích, Quận Tân Phú'), findsOneWidget);
      expect(find.text('28 m²'), findsOneWidget);
      expect(find.text('3.800.000đ/tháng'), findsOneWidget);
      expect(find.byType(CachedNetworkImage), findsOneWidget);
    });

    testWidgets('2. Fallback UI - Renders fallback icon when images list is empty', (WidgetTester tester) async {
      final edgeNoImageRoom = Room(
        id: 'room_edge_no_images',
        title: 'Phòng Trọ Không Ảnh',
        address: '99 Hòa Bình, Quận Tân Phú',
        district: 'Quận Tân Phú',
        area: 18.0,
        price: 2000000,
        status: RoomStatus.available,
        images: [], // Empty array to test fallback
        amenities: ['WiFi'],
        description: 'Mô tả test fallback',
        landlordId: 'landlord_001',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoomCard(room: edgeNoImageRoom),
          ),
        ),
      );

      // Verify the title is correct
      expect(find.text('Phòng Trọ Không Ảnh'), findsOneWidget);
      // Verify no CachedNetworkImage is built since images list is empty
      expect(find.byType(CachedNetworkImage), findsNothing);
      // Verify fallback icon Home icon renders
      expect(find.byIcon(Icons.home_outlined), findsOneWidget);
    });

    testWidgets('3. Boundary Value - Price formatting and layout co-ordination test', (WidgetTester tester) async {
      final edgePriceRoom = Room(
        id: 'room_edge_abnormal_price',
        title: 'Căn Hộ Siêu Tưởng Giá Siêu Rẻ',
        address: '1 Lũy Bán Bích, Quận Tân Phú',
        district: 'Quận Tân Phú',
        area: 120.0,
        price: 10000, // Very small price to check layout
        status: RoomStatus.available,
        images: ['https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=600&q=80'],
        amenities: ['WiFi'],
        description: 'Test price size',
        landlordId: 'landlord_002',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoomCard(room: edgePriceRoom),
          ),
        ),
      );

      // Verify correct price formatting: 10000 should format to 10.000đ/tháng
      expect(find.text('10.000đ/tháng'), findsOneWidget);
    });
  });
}
