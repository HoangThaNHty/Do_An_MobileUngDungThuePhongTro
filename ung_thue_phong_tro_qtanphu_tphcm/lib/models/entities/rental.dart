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
  });

  bool get isActive => status == RentalStatus.active;
  bool get isExpired => status == RentalStatus.expired;

  int get remainingDays => endDate.difference(DateTime.now()).inDays;
}
