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
  });

  int get totalAmount =>
      rentAmount +
      electricityAmount +
      waterAmount +
      internetAmount +
      trashAmount +
      otherAmount;
}
