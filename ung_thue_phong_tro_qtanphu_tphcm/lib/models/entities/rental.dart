// ═══════════════════════════════════════════
// RENTAL ENTITY
// ═══════════════════════════════════════════
enum RentalStatus { active, pending, expired, cancelled }

class Rental {
  final String id;
  final String roomId;
  final String roomTitle;
  final String roomAddress;
  final String tenantId;
  final String tenantName;
  final String landlordId;
  final int monthlyRent;
  final DateTime startDate;
  final DateTime endDate;
  final RentalStatus status;
  final String? contractUrl;
  final DateTime createdAt;

  final bool showToLandlord;
  final bool showToTenant;

  const Rental({
    required this.id,
    required this.roomId,
    required this.roomTitle,
    required this.roomAddress,
    required this.tenantId,
    required this.tenantName,
    required this.landlordId,
    required this.monthlyRent,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.contractUrl,
    required this.createdAt,
    this.showToLandlord = true,
    this.showToTenant = true,
  });

  bool get isActive => status == RentalStatus.active;
  bool get isExpired => status == RentalStatus.expired;

  int get remainingDays => endDate.difference(DateTime.now()).inDays;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'roomId': roomId,
      'roomTitle': roomTitle,
      'roomAddress': roomAddress,
      'tenantId': tenantId,
      'tenantName': tenantName,
      'landlordId': landlordId,
      'monthlyRent': monthlyRent,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'status': status.name,
      'contractUrl': contractUrl,
      'createdAt': createdAt.toIso8601String(),
      'showToLandlord': showToLandlord,
      'showToTenant': showToTenant,
    };
  }

  factory Rental.fromMap(Map<String, dynamic> map, String docId) {
    return Rental(
      id: docId,
      roomId: map['roomId'] ?? '',
      roomTitle: map['roomTitle'] ?? '',
      roomAddress: map['roomAddress'] ?? '',
      tenantId: map['tenantId'] ?? '',
      tenantName: map['tenantName'] ?? '',
      landlordId: map['landlordId'] ?? '',
      monthlyRent: map['monthlyRent'] ?? 0,
      startDate: DateTime.tryParse(map['startDate'] ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(map['endDate'] ?? '') ?? DateTime.now(),
      status: RentalStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => RentalStatus.pending,
      ),
      contractUrl: map['contractUrl'],
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      showToLandlord: map['showToLandlord'] ?? true,
      showToTenant: map['showToTenant'] ?? true,
    );
  }
}
