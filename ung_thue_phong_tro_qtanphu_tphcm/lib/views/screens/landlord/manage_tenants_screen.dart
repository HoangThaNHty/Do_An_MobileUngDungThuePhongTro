import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/constants.dart';
import '../../../controllers/providers/bill_provider.dart';
import '../../widgets/common/status_chips.dart';
import '../../../models/entities/rental.dart';
import '../../../models/datasources/mock_data.dart';

class ManageTenantsScreen extends ConsumerWidget {
  const ManageTenantsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rentalsAsync = ref.watch(allRentalsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Quản lý người thuê'),
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
          return Column(
            children: [
              // Summary bar
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                color: AppColors.surfaceContainerLow,
                child: Row(
                  children: [
                    const Icon(Icons.people_outline,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '${rentals.length} người đang thuê',
                      style: AppTypography.bodyMD
                          .copyWith(color: AppColors.primary),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: rentals.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    return _TenantCard(rental: rentals[index]);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 72, color: AppColors.outlineVariant),
          SizedBox(height: AppSpacing.md),
          Text('Chưa có người thuê', style: AppTypography.titleSM),
        ],
      ),
    );
  }
}

class _TenantCard extends StatelessWidget {
  final Rental rental;

  const _TenantCard({required this.rental});

  @override
  Widget build(BuildContext context) {
    // Find user from mock data
    final user = MockData.users.where((u) => u.id == rental.tenantId).firstOrNull;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: const [AppShadows.card],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              backgroundImage: user?.avatarUrl != null
                  ? NetworkImage(user!.avatarUrl!)
                  : null,
              child: user?.avatarUrl == null
                  ? Text(
                      rental.tenantName.isNotEmpty
                          ? rental.tenantName[0].toUpperCase()
                          : 'N',
                      style: AppTypography.titleMD.copyWith(
                        color: AppColors.primary,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: AppSpacing.md),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          rental.tenantName,
                          style: AppTypography.titleSM,
                        ),
                      ),
                      // Status
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: rental.status == RentalStatus.active
                              ? AppColors.available
                              : AppColors.overdue,
                          borderRadius:
                              BorderRadius.circular(AppRadius.chip),
                        ),
                        child: Text(
                          rental.status == RentalStatus.active
                              ? 'ĐANG THUÊ'
                              : 'HẾT HẠN',
                          style: AppTypography.labelSM.copyWith(
                            fontSize: 9,
                            color: rental.status == RentalStatus.active
                                ? AppColors.onAvailable
                                : AppColors.onOverdue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    rental.roomTitle,
                    style: AppTypography.bodyMD.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 12, color: AppColors.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        'Hết hạn: ${_fmtDate(rental.endDate)}',
                        style: AppTypography.bodySM,
                      ),
                      const Spacer(),
                      if (user?.phone != null)
                        Text(
                          user!.phone,
                          style: AppTypography.bodySM,
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // Rent info
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius:
                                BorderRadius.circular(AppRadius.button),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.payments_outlined,
                                  size: 13, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text(
                                '${_formatCurrency(rental.monthlyRent)}đ/tháng',
                                style: AppTypography.bodySM.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      // Remaining days badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm, vertical: 4),
                        decoration: BoxDecoration(
                          color: rental.remainingDays < 30
                              ? AppColors.overdue
                              : AppColors.surfaceContainerLow,
                          borderRadius:
                              BorderRadius.circular(AppRadius.button),
                        ),
                        child: Text(
                          '${rental.remainingDays} ngày',
                          style: AppTypography.bodySM.copyWith(
                            color: rental.remainingDays < 30
                                ? AppColors.onOverdue
                                : AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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
