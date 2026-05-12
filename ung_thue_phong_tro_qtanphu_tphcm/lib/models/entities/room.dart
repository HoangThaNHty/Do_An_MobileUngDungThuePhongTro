// ═══════════════════════════════════════════
// ROOM ENTITY
// ═══════════════════════════════════════════
enum RoomStatus { available, rented, overdue, pending }

class Room {
  final String id;
  final String title;
  final String address;
  final String district;
  final double area;        // m²
  final int price;          // VND/month
  final RoomStatus status;
  final List<String> images;
  final List<String> amenities;
  final String description;
  final String landlordId;
  final double? latitude;
  final double? longitude;
  final int viewCount;
  final DateTime createdAt;

  const Room({
    required this.id,
    required this.title,
    required this.address,
    required this.district,
    required this.area,
    required this.price,
    required this.status,
    required this.images,
    required this.amenities,
    required this.description,
    required this.landlordId,
    this.latitude,
    this.longitude,
    this.viewCount = 0,
    required this.createdAt,
  });

  Room copyWith({
    String? id,
    String? title,
    String? address,
    String? district,
    double? area,
    int? price,
    RoomStatus? status,
    List<String>? images,
    List<String>? amenities,
    String? description,
    String? landlordId,
    double? latitude,
    double? longitude,
    int? viewCount,
    DateTime? createdAt,
  }) {
    return Room(
      id: id ?? this.id,
      title: title ?? this.title,
      address: address ?? this.address,
      district: district ?? this.district,
      area: area ?? this.area,
      price: price ?? this.price,
      status: status ?? this.status,
      images: images ?? this.images,
      amenities: amenities ?? this.amenities,
      description: description ?? this.description,
      landlordId: landlordId ?? this.landlordId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      viewCount: viewCount ?? this.viewCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
