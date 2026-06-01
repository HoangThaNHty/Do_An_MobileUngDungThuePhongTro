import 'package:flutter_test/flutter_test.dart';
import 'package:ung_thue_phong_tro_qtanphu_tphcm/controllers/review_controller.dart';

void main() {
  group('ReviewModel Unit Tests', () {
    test('1. ReviewModel serialization and deserialization', () {
      final now = DateTime.now();
      final review = ReviewModel(
        id: 'rev_123',
        landlordId: 'landlord_456',
        roomId: 'room_789',
        roomTitle: 'Phòng Trọ Đẹp',
        tenantId: 'tenant_101',
        tenantName: 'Nguyễn Văn Tenant',
        rating: 4.5,
        comment: 'Phòng sạch đẹp, chủ trọ thân thiện',
        type: 'Verified Tenant Review',
        createdAt: now,
      );

      final map = review.toMap();
      expect(map['id'], 'rev_123');
      expect(map['rating'], 4.5);
      expect(map['comment'], 'Phòng sạch đẹp, chủ trọ thân thiện');
      expect(map['type'], 'Verified Tenant Review');

      final parsed = ReviewModel.fromMap(map, 'rev_123');
      expect(parsed.id, 'rev_123');
      expect(parsed.rating, 4.5);
      expect(parsed.comment, 'Phòng sạch đẹp, chủ trọ thân thiện');
      expect(parsed.createdAt.day, now.day);
    });
  });
}
