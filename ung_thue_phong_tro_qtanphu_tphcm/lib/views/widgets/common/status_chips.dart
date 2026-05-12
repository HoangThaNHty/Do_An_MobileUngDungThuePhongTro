import 'package:flutter/material.dart';
import '../../../config/constants.dart';
import '../../../models/entities/room.dart';
import '../../../models/entities/bill.dart';

// ═══════════════════════════════════════════
// ROOM STATUS CHIP
// ═══════════════════════════════════════════
class RoomStatusChip extends StatelessWidget {
  final RoomStatus status;
  final double fontSize;

  const RoomStatusChip({
    super.key,
    required this.status,
    this.fontSize = 10,
  });

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = _resolveStyle(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: fg,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  static (Color, Color, String) _resolveStyle(RoomStatus status) {
    switch (status) {
      case RoomStatus.available:
        return (AppColors.available, AppColors.onAvailable, AppStrings.available);
      case RoomStatus.rented:
        return (AppColors.rented, AppColors.onRented, AppStrings.rented);
      case RoomStatus.overdue:
        return (AppColors.overdue, AppColors.onOverdue, AppStrings.overdue);
      case RoomStatus.pending:
        return (AppColors.overdue, AppColors.onOverdue, AppStrings.pending);
    }
  }
}

// ═══════════════════════════════════════════
// BILL STATUS CHIP
// ═══════════════════════════════════════════
class BillStatusChip extends StatelessWidget {
  final BillStatus status;

  const BillStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = switch (status) {
      BillStatus.paid => (
          AppColors.available,
          AppColors.onAvailable,
          AppStrings.paid,
        ),
      BillStatus.unpaid => (
          AppColors.surfaceContainerHigh,
          AppColors.onSurfaceVariant,
          AppStrings.unpaid,
        ),
      BillStatus.overdue => (
          AppColors.overdue,
          AppColors.onOverdue,
          'QUÁ HẠN',
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: fg,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
