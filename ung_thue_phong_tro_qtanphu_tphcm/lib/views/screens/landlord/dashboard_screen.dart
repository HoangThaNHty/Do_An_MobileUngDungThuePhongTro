import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../config/constants.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/providers/room_provider.dart';
import '../../../controllers/providers/bill_provider.dart';
import '../../../controllers/providers/create_room_provider.dart';
import '../../widgets/cards/room_card.dart';
import '../../widgets/cards/stat_card.dart';
import '../../../models/entities/room.dart';
import '../../../models/entities/rental.dart';
import '../../../repositories/room_repository.dart';
import '../../../controllers/chat_controller.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final roomState = ref.watch(roomProvider);
    final statsAsync = ref.watch(dashboardStatsProvider);

    // Lắng nghe cọc giữ phòng realtime để hiển thị Banner thông báo
    final rentalsAsync = ref.watch(allRentalsProvider);
    final pendingRentals = rentalsAsync.maybeWhen(
      data: (list) => list.where((r) => r.landlordId == user?.id && r.status == RentalStatus.pending).toList(),
      orElse: () => <Rental>[],
    );
    final unreadCount = ref.watch(unreadChatsCountProvider);

    // Lọc danh sách phòng của riêng chủ trọ hiện tại
    final rooms = roomState.rooms.where((r) => r.landlordId == user?.id).toList();
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
          onRefresh: () async {
            // Firebase Stream automatically updates
            await Future.delayed(const Duration(milliseconds: 500));
          },
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
                      // Bọc Avatar và Chào hỏi để điều hướng tới Hồ sơ cá nhân
                      Expanded(
                        child: GestureDetector(
                          onTap: () => context.push('/landlord/profile'),
                          behavior: HitTestBehavior.opaque,
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor:
                                    AppColors.primary.withValues(alpha: 0.12),
                                backgroundImage: user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty
                                    ? NetworkImage(user.avatarUrl!)
                                    : null,
                                child: user?.avatarUrl == null || user!.avatarUrl!.isEmpty
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
                                    const Text(
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
                            ],
                          ),
                        ),
                      ),
                      Badge(
                        label: Text('$unreadCount'),
                        isLabelVisible: unreadCount > 0,
                        backgroundColor: AppColors.error,
                        child: IconButton(
                          icon: const Icon(Icons.chat_bubble_outline),
                          color: AppColors.onSurfaceVariant,
                          onPressed: () => context.push('/chat-list'),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout),
                        color: AppColors.onSurfaceVariant,
                        onPressed: () {
                          ref.read(createRoomProvider.notifier).reset();
                          ref.read(authControllerProvider.notifier).logout();
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Banner thông báo cọc giữ chỗ realtime cho chủ trọ
              if (pendingRentals.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        border: Border.all(color: const Color(0xFF81C784)),
                        boxShadow: const [AppShadows.card],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified_user, color: Color(0xFF2E7D32), size: 28),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Có cọc giữ chỗ mới! 🔔',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1B5E20),
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Khách ${pendingRentals.first.tenantName} đã cọc thành công 500k giữ phòng "${pendingRentals.first.roomTitle}".',
                                  style: const TextStyle(
                                    color: Color(0xFF2E7D32),
                                    fontSize: 11,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          ElevatedButton(
                            onPressed: () => context.go('/landlord/tenants'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              minimumSize: Size.zero,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppRadius.button),
                              ),
                            ),
                            child: const Text('Xem', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // ─── Title ─────────────────────────────
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
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
                                        .withValues(alpha: 0.8),
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
                        const Text('Tỷ lệ lấp đầy', style: AppTypography.titleSM),
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
                      const Text('Danh sách phòng',
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
                          childAspectRatio: 0.62,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final room = rooms[index];
                            return LandlordRoomCard(
                              room: room,
                              onTap: () => context.push('/landlord/rooms/detail/${room.id}'),
                              onStatusToggle: () async {
                                final rentals = rentalsAsync.maybeWhen(
                                  data: (list) => list,
                                  orElse: () => <Rental>[],
                                );
                                final hasActiveContract = rentals.any((r) => r.roomId == room.id && r.status == RentalStatus.active);
                                
                                if (room.status == RoomStatus.rented && hasActiveContract) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Không thể chuyển sang "Còn trống" vì phòng đang có hợp đồng thuê hoạt động!'),
                                        backgroundColor: AppColors.error,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                  return;
                                }

                                final newStatus = room.status == RoomStatus.available
                                    ? RoomStatus.rented
                                    : RoomStatus.available;
                                try {
                                  await ref.read(roomRepositoryProvider).updateRoomStatus(room.id, newStatus);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Đã cập nhật trạng thái phòng thành ${newStatus == RoomStatus.available ? "Còn trống" : "Đã thuê"}'),
                                        backgroundColor: const Color(0xFF2E7D32),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Lỗi cập nhật trạng thái: $e'),
                                        backgroundColor: AppColors.error,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                }
                              },
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
