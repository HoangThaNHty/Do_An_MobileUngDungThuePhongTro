import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/constants.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/providers/bill_provider.dart';
import '../../widgets/common/status_chips.dart';
import '../../../models/entities/rental.dart';

class MyRentalsScreen extends ConsumerWidget {
  const MyRentalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final rentalsAsync = ref.watch(
      rentalsProvider(user?.id ?? ''),
    );

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Phòng đang thuê'),
        automaticallyImplyLeading: false,
      ),
      body: rentalsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (rentals) {
          if (rentals.isEmpty) {
            return _buildEmpty();
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: rentals.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              final rental = rentals[index];
              return _RentalCard(
                rental: rental,
                onViewBills: () =>
                    context.go('/tenant/rentals/bills/${rental.id}'),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.home_outlined,
            size: 72,
            color: AppColors.outlineVariant,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Bạn chưa thuê phòng nào',
            style: AppTypography.titleSM.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Hãy tìm kiếm và liên hệ chủ trọ để thuê phòng',
            style: AppTypography.bodyMD,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _RentalCard extends StatelessWidget {
  final Rental rental;
  final VoidCallback onViewBills;

  const _RentalCard({
    required this.rental,
    required this.onViewBills,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = rental.status == RentalStatus.active
        ? AppColors.available
        : AppColors.overdue;
    final statusText =
        rental.status == RentalStatus.active ? 'ĐANG THUÊ' : 'ĐÃ HẾT HẠN';
    final daysLeft = rental.remainingDays;

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
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primaryContainer,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.card),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.home_work_outlined,
                    color: AppColors.onPrimary, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    rental.roomTitle,
                    style: AppTypography.titleSM.copyWith(
                      color: AppColors.onPrimary,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.onPrimary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                  ),
                  child: Text(
                    statusText,
                    style: AppTypography.labelSM.copyWith(
                      color: AppColors.onPrimary,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                _infoRow(Icons.location_on_outlined, rental.roomAddress),
                const SizedBox(height: AppSpacing.xs),
                _infoRow(
                  Icons.calendar_today_outlined,
                  'Từ ${_fmtDate(rental.startDate)} đến ${_fmtDate(rental.endDate)}',
                ),
                const SizedBox(height: AppSpacing.xs),
                _infoRow(
                  Icons.payments_outlined,
                  '${_formatCurrency(rental.monthlyRent)}đ/tháng',
                  valueColor: AppColors.primary,
                ),
                if (rental.isActive) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: daysLeft < 30
                          ? AppColors.overdue
                          : AppColors.available.withOpacity(0.3),
                      borderRadius:
                          BorderRadius.circular(AppRadius.button),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 14,
                          color: daysLeft < 30
                              ? AppColors.onOverdue
                              : AppColors.onAvailable,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Còn $daysLeft ngày đến hạn hợp đồng',
                          style: AppTypography.labelSM.copyWith(
                            color: daysLeft < 30
                                ? AppColors.onOverdue
                                : AppColors.onAvailable,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                // View bills button
                GestureDetector(
                  onTap: onViewBills,
                  child: Container(
                    width: double.infinity,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.receipt_long_outlined,
                            size: 18, color: AppColors.primary),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Xem hóa đơn',
                          style: AppTypography.button.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, {Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.onSurfaceVariant),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodyMD.copyWith(color: valueColor),
          ),
        ),
      ],
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
