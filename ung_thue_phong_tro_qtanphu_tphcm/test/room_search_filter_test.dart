import 'package:flutter_test/flutter_test.dart';
import 'package:ung_thue_phong_tro_qtanphu_tphcm/controllers/providers/room_provider.dart';
import 'package:ung_thue_phong_tro_qtanphu_tphcm/models/entities/room.dart';

void main() {
  group('Room search and advanced filter', () {
    final room = Room(
      id: 'room_001',
      title: 'Phòng Ban Công Lớn',
      address: '452 Lũy Bán Bích',
      district: 'Tân Phú',
      area: 28,
      price: 3800000,
      status: RoomStatus.available,
      images: const [],
      amenities: const ['WiFi', 'Điều hòa'],
      description: 'Phòng sạch, thoáng mát',
      landlordId: 'landlord_001',
      createdAt: DateTime(2026),
    );

    test('matches keyword without case or Vietnamese accent sensitivity', () {
      expect(roomMatchesTextQuery(room, 'PHONG BAN CONG'), isTrue);
      expect(roomMatchesTextQuery(room, 'luy ban bich'), isTrue);
      expect(roomMatchesTextQuery(room, 'wifi'), isTrue);
    });

    test('matches district and amenities without case sensitivity', () {
      final state = RoomState(
        rooms: [room],
        filter: const RoomFilter(
          district: 'tân phú',
          amenities: ['wifi', 'điều hòa'],
        ),
      );

      expect(state.filteredRooms, [room]);
    });
  });
}
