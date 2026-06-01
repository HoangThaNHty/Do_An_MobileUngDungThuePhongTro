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
  final String? videoUrl;   // Link video giới thiệu phòng trọ (Cloudinary)
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
    this.videoUrl,
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
    String? videoUrl,
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
      videoUrl: videoUrl ?? this.videoUrl,
      amenities: amenities ?? this.amenities,
      description: description ?? this.description,
      landlordId: landlordId ?? this.landlordId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      viewCount: viewCount ?? this.viewCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'address': address,
      'district': district,
      'area': area,
      'price': price,
      'status': status.name,
      'images': images,
      'videoUrl': videoUrl,
      'amenities': amenities,
      'description': description,
      'landlordId': landlordId,
      'latitude': latitude,
      'longitude': longitude,
      'viewCount': viewCount,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Room.fromMap(Map<String, dynamic> map, String documentId) {
    return Room(
      id: documentId,
      title: map['title'] ?? '',
      address: map['address'] ?? '',
      district: map['district'] ?? '',
      area: (map['area'] ?? 0).toDouble(),
      price: map['price'] ?? 0,
      status: RoomStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => RoomStatus.available,
      ),
      images: List<String>.from(map['images'] ?? []),
      videoUrl: map['videoUrl'],
      amenities: List<String>.from(map['amenities'] ?? []),
      description: map['description'] ?? '',
      landlordId: map['landlordId'] ?? '',
      latitude: map['latitude'] != null ? (map['latitude'] as num).toDouble() : null,
      longitude: map['longitude'] != null ? (map['longitude'] as num).toDouble() : null,
      viewCount: map['viewCount'] ?? 0,
      createdAt: map['createdAt'] != null 
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
