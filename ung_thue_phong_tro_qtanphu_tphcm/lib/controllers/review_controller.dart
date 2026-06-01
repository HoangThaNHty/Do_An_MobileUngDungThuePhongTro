import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReviewModel {
  final String id;
  final String landlordId;
  final String roomId;
  final String roomTitle;
  final String tenantId;
  final String tenantName;
  final double rating;
  final String comment;
  final String type; // "Verified Tenant Review" or "Cancelled Booking Review"
  final DateTime createdAt;

  const ReviewModel({
    required this.id,
    required this.landlordId,
    required this.roomId,
    required this.roomTitle,
    required this.tenantId,
    required this.tenantName,
    required this.rating,
    required this.comment,
    required this.type,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'landlordId': landlordId,
      'roomId': roomId,
      'roomTitle': roomTitle,
      'tenantId': tenantId,
      'tenantName': tenantName,
      'rating': rating,
      'comment': comment,
      'type': type,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ReviewModel.fromMap(Map<String, dynamic> map, String docId) {
    return ReviewModel(
      id: docId,
      landlordId: map['landlordId'] ?? '',
      roomId: map['roomId'] ?? '',
      roomTitle: map['roomTitle'] ?? '',
      tenantId: map['tenantId'] ?? '',
      tenantName: map['tenantName'] ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 5.0,
      comment: map['comment'] ?? '',
      type: map['type'] ?? 'Verified Tenant Review',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class ReviewController {
  FirebaseDatabase get _db => FirebaseDatabase.instance;

  ReviewController();

  /// Đẩy đánh giá lên Firebase Realtime Database
  Future<void> submitReview({
    required String landlordId,
    required String roomId,
    required String roomTitle,
    required String tenantId,
    required String tenantName,
    required double rating,
    required String comment,
    required String type,
  }) async {
    final reviewId = 'review_${DateTime.now().millisecondsSinceEpoch}';
    final review = ReviewModel(
      id: reviewId,
      landlordId: landlordId,
      roomId: roomId,
      roomTitle: roomTitle,
      tenantId: tenantId,
      tenantName: tenantName,
      rating: rating,
      comment: comment,
      type: type,
      createdAt: DateTime.now(),
    );

    // 1. Lưu đánh giá mới vào node reviews/$landlordId/$reviewId
    await _db.ref('reviews/$landlordId/$reviewId').set(review.toMap());

    // 2. Tính lại trung bình cộng và lưu vào users/$landlordId/averageRating
    await _recalculateAverageRating(landlordId);
  }

  /// Tính toán động trung bình cộng của chủ trọ và lưu lại
  Future<void> _recalculateAverageRating(String landlordId) async {
    final snapshot = await _db.ref('reviews/$landlordId').get();
    if (!snapshot.exists) {
      // Nếu chưa có review nào, mặc định là 5.0 hoặc xóa field
      await _db.ref('users/$landlordId').update({'averageRating': 5.0});
      return;
    }

    final data = snapshot.value as Map<dynamic, dynamic>;
    double totalStars = 0;
    int reviewCount = 0;

    data.forEach((key, value) {
      final reviewMap = Map<String, dynamic>.from(value as Map);
      final rRating = (reviewMap['rating'] as num?)?.toDouble() ?? 5.0;
      totalStars += rRating;
      reviewCount++;
    });

    if (reviewCount > 0) {
      final average = double.parse((totalStars / reviewCount).toStringAsFixed(1));
      await _db.ref('users/$landlordId').update({'averageRating': average});
    }
  }

  /// Lắng nghe danh sách đánh giá của một landlord cụ thể
  Stream<List<ReviewModel>> watchLandlordReviews(String landlordId) {
    return _db.ref('reviews/$landlordId').onValue.map((event) {
      final snapshot = event.snapshot;
      if (!snapshot.exists) return [];

      final data = snapshot.value as Map<dynamic, dynamic>;
      final list = <ReviewModel>[];

      data.forEach((key, value) {
        final map = Map<String, dynamic>.from(value as Map);
        list.add(ReviewModel.fromMap(map, key.toString()));
      });

      // Sắp xếp review mới nhất lên đầu
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }
}

// Providers
final reviewControllerProvider = Provider<ReviewController>((ref) {
  return ReviewController();
});

// Stream reviews của một chủ trọ cụ thể
final landlordReviewsProvider = StreamProvider.family<List<ReviewModel>, String>((ref, landlordId) {
  return ref.watch(reviewControllerProvider).watchLandlordReviews(landlordId);
});
