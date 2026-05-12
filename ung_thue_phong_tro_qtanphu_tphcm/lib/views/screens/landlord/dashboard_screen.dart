import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../config/constants.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/providers/room_provider.dart';
import '../../../controllers/providers/bill_provider.dart';
import '../../widgets/cards/room_card.dart';
import '../../widgets/cards/stat_card.dart';
import '../../../models/entities/room.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final roomState = ref.watch(roomProvider);
    final statsAsync = ref.watch(dashboardStatsProvider);

    final rooms = roomState.rooms;
    final rentedCount =
        rooms.where((r) => r.status == RoomStatus.rented).length;
    final availableCount =
        rooms.where((r) => r.status == RoomStatus.available).length;
    final overdueCount =
        rooms.where((r) => r.status == RoomStatus.overdue).length;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(roomProvider.notifier).loadRooms(),
          color: AppColors.primary,
          child: CustomScrollView(
            slivers: [
              // ─── Top App Bar ───────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md, AppSpacing.md,
                      AppSpacing.md, 0),
                  child: Row(
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 22,
                        backgroundColor:
                            AppColors.primary.withOpacity(0.12),
                        backgroundImage: user?.avatarUrl != null
                            ? NetworkImage(user!.avatarUrl!)
                            : null,
                        child: user?.avatarUrl == null
                            ? Text(
                                user?.fullName.isNotEmpty == true
                                    ? user!.fullName[0].toUpperCase()
                                    : 'C',
                                style: AppTypography.titleSM.copyWith(
                                  color: AppColors.primary,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Xin chào chủ trọ,',
                              style: AppTypography.bodySM,
                            ),
                            Text(
                              user?.fullName ?? 'Chủ trọ',
                              style: AppTypography.titleSM,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout),
                        color: AppColors.onSurfaceVariant,
                        onPressed: () =>
                            ref.read(authControllerProvider.notifier).logout(),
                      ),
                    ],
                  ),
                ),
              ),

              // ─── Title ─────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
                  child: Text(
                    'Phòng của tôi',
                    style: AppTypography.headlineMD,
                  ),
                ),
              ),

              // ─── Stats Horizontal Scroll ───────────
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 120,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    children: [
                      StatCard(
                        label: 'Tổng phòng',
                        value: '${rooms.length}',
                        icon: Icons.apartment_outlined,
                        iconColor: AppColors.primary,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      StatCard(
                        label: 'Đã thuê',
                        value: '$rentedCount',
                        icon: Icons.check_circle_outline,
                        iconColor: const Color(0xFF2E7D32),
                        valueColor: const Color(0xFF2E7D32),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      StatCard(
                        label: 'Còn trống',
                        value: '$availableCount',
                        icon: Icons.door_front_door_outlined,
                        iconColor: AppColors.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      StatCard(
                        label: 'Quá hạn',
                        value: '$overdueCount',
                        icon: Icons.warning_amber_outlined,
                        iconColor: AppColors.onOverdue,
                        valueColor: AppColors.onOverdue,
                      ),
                    ],
                  ),
                ),
              ),

              // ─── Revenue Card ──────────────────────
              SliverToBoxAdapter(
                child: statsAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (stats) => Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        gradient: AppGradients.primaryButton,
                        borderRadius:
                            BorderRadius.circular(AppRadius.card),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Doanh thu tháng này',
                                  style: AppTypography.bodyMD.copyWith(
                                    color: AppColors.onPrimary
                                        .withOpacity(0.8),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_formatCurrency(stats['monthlyRevenue'] ?? 0)}đ',
                                  style: AppTypography.headlineLG.copyWith(
                                    color: AppColors.onPrimary,
                                    fontSize: 26,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.trending_up,
                            color: AppColors.onPrimary,
                            size: 40,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.md)),

              // ─── Mini chart ────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius:
                          BorderRadius.circular(AppRadius.card),
                      boxShadow: const [AppShadows.card],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tỷ lệ lấp đầy', style: AppTypography.titleSM),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 120,
                                child: rooms.isEmpty
                                    ? const Center(
                                        child: Text('Chưa có phòng'))
                                    : PieChart(
                                        PieChartData(
                                          sectionsSpace: 2,
                                          centerSpaceRadius: 35,
                                          sections: [
                                            PieChartSectionData(
                                              value:
                                                  rentedCount.toDouble(),
                                              color: AppColors.primary,
                                              radius: 30,
                                              title: '',
                                            ),
                                            PieChartSectionData(
                                              value: availableCount
                                                  .toDouble(),
                                              color: AppColors.available,
                                              radius: 30,
                                              title: '',
                                            ),
                                            if (overdueCount > 0)
                                              PieChartSectionData(
                                                value: overdueCount
                                                    .toDouble(),
                                                color: AppColors.overdue,
                                                radius: 30,
                                                title: '',
                                              ),
                                          ],
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                _legendDot(AppColors.primary, 'Đã thuê'),
                                const SizedBox(height: 8),
                                _legendDot(
                                    AppColors.available, 'Còn trống'),
                                if (overdueCount > 0) ...[
                                  const SizedBox(height: 8),
                                  _legendDot(
                                      AppColors.overdue, 'Quá hạn'),
                                ],
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        // Occupancy rate
                        LinearProgressIndicator(
                          value: rooms.isEmpty
                              ? 0
                              : rentedCount / rooms.length,
                          backgroundColor:
                              AppColors.surfaceContainerHigh,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.primary),
                          borderRadius: BorderRadius.circular(4),
                          minHeight: 6,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tỷ lệ lấp đầy: ${rooms.isEmpty ? 0 : (rentedCount * 100 / rooms.length).toStringAsFixed(0)}%',
                          style: AppTypography.bodySM,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.md)),

              // ─── Room List Header ──────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Danh sách phòng',
                          style: AppTypography.titleMD),
                      TextButton(
                        onPressed: () {},
                        child: const Text(AppStrings.viewAll),
                      ),
                    ],
                  ),
                ),
              ),

              // ─── Room Grid ────────────────────────
              roomState.isLoading
                  ? const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.xl),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md, 0,
                          AppSpacing.md, AppSpacing.xxl),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: AppSpacing.md,
                          crossAxisSpacing: AppSpacing.md,
                          childAspectRatio: 0.78,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final room = rooms[index];
                            return LandlordRoomCard(
                              room: room,
                              onTap: () {},
                              onStatusToggle: () {},
                            );
                          },
                          childCount: rooms.length,
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTypography.bodySM),
      ],
    );
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }
}
