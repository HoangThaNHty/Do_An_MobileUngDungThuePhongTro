import 'package:flutter/material.dart';
import '../../../config/app_palette.dart';
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
    final (bg, fg, label) = _resolveStyle(status, context.palette);
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

  static (Color, Color, String) _resolveStyle(
    RoomStatus status,
    AppPalette palette,
  ) {
    switch (status) {
      case RoomStatus.available:
        return (
          palette.successContainer,
          palette.success,
          AppStrings.available,
        );
      case RoomStatus.rented:
        return (
          palette.rentedContainer,
          palette.onRentedContainer,
          AppStrings.rented,
        );
      case RoomStatus.overdue:
        return (palette.dangerContainer, palette.danger, AppStrings.overdue);
      case RoomStatus.pending:
        return (palette.warningContainer, palette.warning, AppStrings.pending);
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
    final palette = context.palette;
    final (bg, fg, label) = switch (status) {
      BillStatus.paid => (
          palette.successContainer,
          palette.success,
          AppStrings.paid,
        ),
      BillStatus.unpaid => (
          palette.surfaceHigh,
          palette.onSurfaceVariant,
          AppStrings.unpaid,
        ),
      BillStatus.overdue => (
          palette.dangerContainer,
          palette.danger,
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
