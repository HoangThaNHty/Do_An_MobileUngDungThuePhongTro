// ═══════════════════════════════════════════
// BILL ENTITY
// ═══════════════════════════════════════════
enum BillStatus { unpaid, paid, overdue }

class Bill {
  final String id;
  final String roomId;
  final String roomTitle;
  final String tenantId;
  final String tenantName;
  final int rentAmount;
  final int electricityAmount;
  final int waterAmount;
  final int internetAmount;
  final int trashAmount;
  final int otherAmount;
  final int electricityUsage;  // kWh
  final int waterUsage;        // m³
  final BillStatus status;
  final DateTime billingMonth;
  final DateTime dueDate;
  final DateTime? paidDate;
  final DateTime createdAt;

  final bool paymentSubmitted;

  const Bill({
    required this.id,
    required this.roomId,
    required this.roomTitle,
    required this.tenantId,
    required this.tenantName,
    required this.rentAmount,
    required this.electricityAmount,
    required this.waterAmount,
    required this.internetAmount,
    required this.trashAmount,
    required this.otherAmount,
    required this.electricityUsage,
    required this.waterUsage,
    required this.status,
    required this.billingMonth,
    required this.dueDate,
    this.paidDate,
    required this.createdAt,
    this.paymentSubmitted = false,
  });

  int get totalAmount =>
      rentAmount +
      electricityAmount +
      waterAmount +
      internetAmount +
      trashAmount +
      otherAmount;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'roomId': roomId,
      'roomTitle': roomTitle,
      'tenantId': tenantId,
      'tenantName': tenantName,
      'rentAmount': rentAmount,
      'electricityAmount': electricityAmount,
      'waterAmount': waterAmount,
      'internetAmount': internetAmount,
      'trashAmount': trashAmount,
      'otherAmount': otherAmount,
      'electricityUsage': electricityUsage,
      'waterUsage': waterUsage,
      'status': status.name,
      'billingMonth': billingMonth.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'paidDate': paidDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'paymentSubmitted': paymentSubmitted,
    };
  }

  factory Bill.fromMap(Map<String, dynamic> map, String docId) {
    return Bill(
      id: docId,
      roomId: map['roomId'] ?? '',
      roomTitle: map['roomTitle'] ?? '',
      tenantId: map['tenantId'] ?? '',
      tenantName: map['tenantName'] ?? '',
      rentAmount: map['rentAmount'] ?? 0,
      electricityAmount: map['electricityAmount'] ?? 0,
      waterAmount: map['waterAmount'] ?? 0,
      internetAmount: map['internetAmount'] ?? 0,
      trashAmount: map['trashAmount'] ?? 0,
      otherAmount: map['otherAmount'] ?? 0,
      electricityUsage: map['electricityUsage'] ?? 0,
      waterUsage: map['waterUsage'] ?? 0,
      status: BillStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => BillStatus.unpaid,
      ),
      billingMonth: DateTime.tryParse(map['billingMonth'] ?? '') ?? DateTime.now(),
      dueDate: DateTime.tryParse(map['dueDate'] ?? '') ?? DateTime.now(),
      paidDate: map['paidDate'] != null ? DateTime.tryParse(map['paidDate']) : null,
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      paymentSubmitted: map['paymentSubmitted'] ?? false,
    );
  }
}
