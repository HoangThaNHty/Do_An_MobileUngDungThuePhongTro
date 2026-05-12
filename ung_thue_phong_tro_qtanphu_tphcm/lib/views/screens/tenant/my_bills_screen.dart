import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/constants.dart';
import '../../../controllers/providers/bill_provider.dart';
import '../../widgets/common/status_chips.dart';
import '../../../models/entities/bill.dart';

class MyBillsScreen extends ConsumerWidget {
  final String rentalId;

  const MyBillsScreen({super.key, required this.rentalId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // For mock: load all bills
    final billsAsync = ref.watch(allBillsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Hóa đơn'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/tenant/rentals'),
        ),
      ),
      body: billsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (bills) {
          if (bills.isEmpty) {
            return const Center(child: Text('Chưa có hóa đơn'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: bills.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              return _BillCard(bill: bills[index]);
            },
          );
        },
      ),
    );
  }
}

class _BillCard extends StatelessWidget {
  final Bill bill;

  const _BillCard({required this.bill});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: const [AppShadows.card],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.card),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(bill.roomTitle, style: AppTypography.titleSM),
                      Text(
                        'Tháng ${bill.billingMonth.month}/${bill.billingMonth.year}',
                        style: AppTypography.bodySM,
                      ),
                    ],
                  ),
                ),
                BillStatusChip(status: bill.status),
              ],
            ),
          ),
          // Items
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                _billRow('Tiền thuê', bill.rentAmount),
                _billRow(
                    'Điện (${bill.electricityUsage} kWh)',
                    bill.electricityAmount),
                _billRow(
                    'Nước (${bill.waterUsage} m³)', bill.waterAmount),
                _billRow('Internet', bill.internetAmount),
                _billRow('Rác', bill.trashAmount),
                if (bill.otherAmount > 0)
                  _billRow('Khác', bill.otherAmount),
                const SizedBox(height: AppSpacing.sm),
                const Divider(
                    color: AppColors.outlineVariant, thickness: 0.5),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TỔNG CỘNG',
                      style: AppTypography.labelSM.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${_formatCurrency(bill.totalAmount)}đ',
                      style: AppTypography.titleMD.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                // Due date
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: bill.status == BillStatus.overdue
                        ? AppColors.overdue
                        : AppColors.surfaceContainerLow,
                    borderRadius:
                        BorderRadius.circular(AppRadius.button),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: bill.status == BillStatus.overdue
                            ? AppColors.onOverdue
                            : AppColors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Hạn thanh toán: ${_fmtDate(bill.dueDate)}',
                        style: AppTypography.labelSM.copyWith(
                          color: bill.status == BillStatus.overdue
                              ? AppColors.onOverdue
                              : AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _billRow(String label, int amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodyMD),
          Text(
            '${_formatCurrency(amount)}đ',
            style: AppTypography.bodyMD.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }
}
