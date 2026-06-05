import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../../config/app_palette.dart';
import '../../../config/constants.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/providers/room_provider.dart';
import '../../../controllers/providers/bill_provider.dart';
import '../../../controllers/providers/create_room_provider.dart';
import '../../widgets/cards/room_card.dart';
import '../../widgets/cards/stat_card.dart';
import '../../../models/entities/room.dart';
import '../../../models/entities/rental.dart';
import '../../../models/entities/bill.dart';
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
      data: (list) => list
          .where((r) =>
              r.landlordId == user?.id && r.status == RentalStatus.pending)
          .toList(),
      orElse: () => <Rental>[],
    );
    final pendingPaymentBills =
        ref.watch(pendingPaymentBillsProvider).maybeWhen(
              data: (list) => list,
              orElse: () => [],
            );
    final unreadCount = ref.watch(unreadChatsCountProvider);
    final palette = context.palette;

    // Lọc danh sách phòng của riêng chủ trọ hiện tại
    final rooms =
        roomState.rooms.where((r) => r.landlordId == user?.id).toList();
    final rentedCount =
        rooms.where((r) => r.status == RoomStatus.rented).length;
    final availableCount =
        rooms.where((r) => r.status == RoomStatus.available).length;
    final overdueCount =
        rooms.where((r) => r.status == RoomStatus.overdue).length;

    return Scaffold(
      backgroundColor: palette.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            // Firebase Stream automatically updates
            await Future.delayed(const Duration(milliseconds: 500));
          },
          color: palette.primary,
          child: CustomScrollView(
            slivers: [
              // ─── Top App Bar ───────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
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
                                    palette.primary.withValues(alpha: 0.14),
                                backgroundImage: user?.avatarUrl != null &&
                                        user!.avatarUrl!.isNotEmpty
                                    ? NetworkImage(user.avatarUrl!)
                                    : null,
                                child: user?.avatarUrl == null ||
                                        user!.avatarUrl!.isEmpty
                                    ? Text(
                                        user?.fullName.isNotEmpty == true
                                            ? user!.fullName[0].toUpperCase()
                                            : 'C',
                                        style: AppTypography.titleSM.copyWith(
                                          color: palette.primary,
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
                                      style: AppTypography.bodySM.copyWith(
                                        color: palette.onSurfaceVariant,
                                      ),
                                    ),
                                    Text(
                                      user?.fullName ?? 'Chủ trọ',
                                      style: AppTypography.titleSM.copyWith(
                                        color: palette.onSurface,
                                      ),
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
                      IconButton(
                        icon: const Icon(Icons.manage_search_outlined),
                        color: palette.primary,
                        tooltip: 'Chủ trọ AI Copilot',
                        onPressed: () => context.push('/landlord/ai-copilot'),
                      ),
                      Badge(
                        label: Text('$unreadCount'),
                        isLabelVisible: unreadCount > 0,
                        backgroundColor: palette.danger,
                        child: IconButton(
                          icon: const Icon(Icons.chat_bubble_outline),
                          color: palette.onSurfaceVariant,
                          onPressed: () => context.push('/chat-list'),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout),
                        color: palette.onSurfaceVariant,
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
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            palette.successContainer,
                            palette.successContainer.withValues(alpha: 0.74),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        border: Border.all(
                          color: palette.success.withValues(alpha: 0.45),
                        ),
                        boxShadow: const [AppShadows.card],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.verified_user,
                              color: palette.success, size: 28),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Có cọc giữ chỗ mới! 🔔',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: palette.success,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Khách ${pendingRentals.first.tenantName} đã cọc thành công 500k giữ phòng "${pendingRentals.first.roomTitle}".',
                                  style: TextStyle(
                                    color: palette.success,
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
                              backgroundColor: palette.success,
                              foregroundColor: palette.onSuccess,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              minimumSize: Size.zero,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.button),
                              ),
                            ),
                            child: const Text('Xem',
                                style: TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              if (pendingPaymentBills.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: palette.warningContainer,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        border: Border.all(
                          color: palette.warning.withValues(alpha: 0.45),
                        ),
                        boxShadow: const [AppShadows.card],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.payments_outlined,
                              color: palette.warning, size: 28),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Có thanh toán cần xác nhận',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: palette.warning,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${pendingPaymentBills.length} hóa đơn đang chờ duyệt. Gần nhất: ${pendingPaymentBills.first.tenantName} - ${pendingPaymentBills.first.roomTitle}.',
                                  style: TextStyle(
                                    color: palette.warning,
                                    fontSize: 11,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          ElevatedButton(
                            onPressed: () =>
                                _showPendingPaymentsBottomSheet(context, ref),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: palette.warning,
                              foregroundColor: palette.onWarning,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              minimumSize: Size.zero,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.button),
                              ),
                            ),
                            child: const Text('Duyệt',
                                style: TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.bold)),
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
                        iconColor: palette.primary,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      StatCard(
                        label: 'Đã thuê',
                        value: '$rentedCount',
                        icon: Icons.check_circle_outline,
                        iconColor: palette.success,
                        valueColor: palette.success,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      StatCard(
                        label: 'Còn trống',
                        value: '$availableCount',
                        icon: Icons.door_front_door_outlined,
                        iconColor: palette.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      StatCard(
                        label: 'Quá hạn',
                        value: '$overdueCount',
                        icon: Icons.warning_amber_outlined,
                        iconColor: palette.danger,
                        valueColor: palette.danger,
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        gradient: AppGradients.primaryButton,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),

              // ─── Mini chart ────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: palette.surfaceLowest,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      boxShadow: const [AppShadows.card],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Tỷ lệ lấp đầy',
                            style: AppTypography.titleSM),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 120,
                                child: rooms.isEmpty
                                    ? const Center(child: Text('Chưa có phòng'))
                                    : PieChart(
                                        PieChartData(
                                          sectionsSpace: 2,
                                          centerSpaceRadius: 35,
                                          sections: [
                                            PieChartSectionData(
                                              value: rentedCount.toDouble(),
                                              color: palette.primary,
                                              radius: 30,
                                              title: '',
                                            ),
                                            PieChartSectionData(
                                              value: availableCount.toDouble(),
                                              color: palette.success,
                                              radius: 30,
                                              title: '',
                                            ),
                                            if (overdueCount > 0)
                                              PieChartSectionData(
                                                value: overdueCount.toDouble(),
                                                color: palette.danger,
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _legendDot(palette.primary, 'Đã thuê'),
                                const SizedBox(height: 8),
                                _legendDot(palette.success, 'Còn trống'),
                                if (overdueCount > 0) ...[
                                  const SizedBox(height: 8),
                                  _legendDot(palette.danger, 'Quá hạn'),
                                ],
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        // Occupancy rate
                        LinearProgressIndicator(
                          value: rooms.isEmpty ? 0 : rentedCount / rooms.length,
                          backgroundColor: palette.surfaceHigh,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(palette.primary),
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
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),

              // ─── Room List Header ──────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.md),
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
                  ? SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: palette.primary,
                          ),
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md, 0, AppSpacing.md, AppSpacing.xxl),
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
                              onTap: () => context
                                  .push('/landlord/rooms/detail/${room.id}'),
                              onStatusToggle: () async {
                                final rentals = rentalsAsync.maybeWhen(
                                  data: (list) => list,
                                  orElse: () => <Rental>[],
                                );
                                final hasLockedRental = rentals.any((r) =>
                                    r.roomId == room.id &&
                                    (r.status == RentalStatus.active ||
                                        r.status == RentalStatus.pending));

                                if (room.status == RoomStatus.rented &&
                                    hasLockedRental) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text(
                                            'Không thể chuyển sang "Còn trống" vì phòng đang có hợp đồng thuê hoạt động!'),
                                        backgroundColor: palette.danger,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                  return;
                                }

                                final newStatus =
                                    room.status == RoomStatus.available
                                        ? RoomStatus.rented
                                        : RoomStatus.available;
                                try {
                                  await ref
                                      .read(roomRepositoryProvider)
                                      .updateRoomStatus(room.id, newStatus);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Đã cập nhật trạng thái phòng thành ${newStatus == RoomStatus.available ? "Còn trống" : "Đã thuê"}'),
                                        backgroundColor: palette.success,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content:
                                            Text('Lỗi cập nhật trạng thái: $e'),
                                        backgroundColor: palette.danger,
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

  void _showPendingPaymentsBottomSheet(BuildContext context, WidgetRef ref) {
    final palette = context.palette;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.72,
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
            border: Border.all(
              color: palette.outlineVariant.withValues(alpha: 0.32),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: palette.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Thanh toán chờ duyệt',
                style: AppTypography.titleMD.copyWith(
                  color: palette.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Kiểm tra giao dịch khách đã báo chuyển khoản',
                style: AppTypography.bodySM.copyWith(
                  color: palette.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Divider(height: 1),
              Expanded(
                child: Consumer(
                  builder: (context, ref, _) {
                    final pendingAsync = ref.watch(pendingPaymentBillsProvider);
                    return pendingAsync.when(
                      loading: () => Center(
                        child:
                            CircularProgressIndicator(color: palette.primary),
                      ),
                      error: (e, _) => Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Text(
                            'Lỗi tải hóa đơn chờ duyệt: $e',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodyMD.copyWith(
                              color: palette.danger,
                            ),
                          ),
                        ),
                      ),
                      data: (bills) {
                        if (bills.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.verified_outlined,
                                    size: 64,
                                    color: palette.success,
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    'Không còn hóa đơn chờ duyệt',
                                    style: AppTypography.titleSM.copyWith(
                                      color: palette.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Các giao dịch đã được xử lý hoặc khách chưa báo chuyển khoản.',
                                    textAlign: TextAlign.center,
                                    style: AppTypography.bodySM.copyWith(
                                      color: palette.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          itemCount: bills.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (context, index) {
                            return _buildPendingPaymentCard(
                              context,
                              ref,
                              bills[index],
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPendingPaymentCard(
    BuildContext context,
    WidgetRef ref,
    Bill bill,
  ) {
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: palette.surfaceLowest,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: palette.warning.withValues(alpha: 0.35),
        ),
        boxShadow: const [AppShadows.card],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: palette.warningContainer,
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
                child: Icon(
                  Icons.payments_outlined,
                  color: palette.warning,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bill.tenantName,
                      style: AppTypography.titleSM.copyWith(
                        color: palette.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      bill.roomTitle,
                      style: AppTypography.bodySM.copyWith(
                        color: palette.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: palette.surfaceLow,
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _pendingInfoRow(
                  context,
                  Icons.receipt_long_outlined,
                  'Hóa đơn tháng ${bill.billingMonth.month}/${bill.billingMonth.year}',
                ),
                const SizedBox(height: 6),
                _pendingInfoRow(
                  context,
                  Icons.schedule_outlined,
                  'Báo chuyển khoản lúc ${_fmtDateTime(bill.createdAt)}',
                ),
                const SizedBox(height: 6),
                _pendingInfoRow(
                  context,
                  Icons.account_balance_wallet_outlined,
                  'Tổng tiền: ${_formatCurrency(bill.totalAmount)}đ',
                  valueColor: palette.primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              OutlinedButton.icon(
                onPressed: () => _rejectPayment(context, ref, bill),
                icon: const Icon(Icons.close, size: 16),
                label: const Text('Từ chối'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: palette.danger,
                  side: BorderSide(
                    color: palette.danger.withValues(alpha: 0.45),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _approvePayment(context, ref, bill),
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Duyệt nhận tiền'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: palette.success,
                  foregroundColor: palette.onSuccess,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pendingInfoRow(
    BuildContext context,
    IconData icon,
    String text, {
    Color? valueColor,
  }) {
    final palette = context.palette;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: valueColor ?? palette.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodySM.copyWith(
              color: valueColor ?? palette.onSurfaceVariant,
              fontWeight:
                  valueColor == null ? FontWeight.w500 : FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _approvePayment(
    BuildContext context,
    WidgetRef ref,
    Bill bill,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận đã nhận tiền?'),
        content: Text(
          'Duyệt hóa đơn ${_formatCurrency(bill.totalAmount)}đ của ${bill.tenantName} cho phòng ${bill.roomTitle}? Hóa đơn sẽ chuyển sang trạng thái Đã thanh toán.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Duyệt nhận tiền'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseDatabase.instance.ref('bills/${bill.id}').update({
        'status': BillStatus.paid.name,
        'paymentSubmitted': false,
        'paidDate': DateTime.now().toIso8601String(),
      });
      _invalidateBillState(ref, bill);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Đã duyệt thanh toán thành công.'),
            backgroundColor: context.palette.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi duyệt thanh toán: $e'),
            backgroundColor: context.palette.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _rejectPayment(
    BuildContext context,
    WidgetRef ref,
    Bill bill,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Từ chối giao dịch?'),
        content: Text(
          'Từ chối báo chuyển khoản của ${bill.tenantName} cho phòng ${bill.roomTitle}? Hóa đơn sẽ quay lại trạng thái Chưa thanh toán để khách kiểm tra lại.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Từ chối'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseDatabase.instance.ref('bills/${bill.id}').update({
        'paymentSubmitted': false,
      });
      _invalidateBillState(ref, bill);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Đã từ chối giao dịch. Hóa đơn đã mở lại.'),
            backgroundColor: context.palette.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi từ chối giao dịch: $e'),
            backgroundColor: context.palette.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _invalidateBillState(WidgetRef ref, Bill bill) {
    final query = BillHistoryQuery(
      roomId: bill.roomId,
      tenantId: bill.tenantId,
      roomTitle: bill.roomTitle,
    );
    ref.invalidate(billsProvider(bill.tenantId));
    ref.invalidate(allBillsProvider);
    ref.invalidate(pendingPaymentBillsProvider);
    ref.invalidate(pendingPaymentBillsForRentalProvider(query));
    ref.invalidate(tenantBillsByRentalProvider(query));
    ref.invalidate(landlordBillHistoryProvider(query));
  }

  String _fmtDateTime(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} lúc ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
  }
}
