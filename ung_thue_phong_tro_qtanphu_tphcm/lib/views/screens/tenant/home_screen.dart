import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/app_palette.dart';
import '../../../config/constants.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/booking_controller.dart';
import '../../../controllers/providers/bill_provider.dart';
import '../../../controllers/providers/room_provider.dart';
import '../../../controllers/providers/create_room_provider.dart';
import '../../widgets/cards/room_card.dart';
import '../../../models/entities/bill.dart';
import '../../../models/entities/room.dart';
import '../../../controllers/chat_controller.dart';
import 'package:shimmer/shimmer.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchCtrl = TextEditingController();
  String _selectedDistrict = 'Tất cả';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roomState = ref.watch(roomProvider);
    final filteredRooms = ref.watch(filteredRoomsProvider);
    final districts = ref.watch(districtsProvider);
    final user = ref.watch(currentUserProvider);
    final unreadCount = ref.watch(unreadChatsCountProvider);
    final tenantBills = ref.watch(tenantBillsProvider).maybeWhen(
          data: (bills) => bills,
          orElse: () => const <Bill>[],
        );
    final payableBills = tenantBills
        .where((bill) =>
            bill.status == BillStatus.unpaid &&
            !bill.paymentSubmitted &&
            !isDepositBill(bill))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final waitingApprovalBills = tenantBills
        .where((bill) =>
            bill.status == BillStatus.unpaid &&
            bill.paymentSubmitted &&
            !isDepositBill(bill))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final palette = context.palette;

    return Scaffold(
      backgroundColor: palette.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.delayed(const Duration(milliseconds: 500));
          },
          color: palette.primary,
          child: CustomScrollView(
            slivers: [
              // ─── App Bar ───────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Xin chào,',
                              style: AppTypography.bodyMD,
                            ),
                            Text(
                              user?.fullName.split(' ').last ?? 'Bạn ơi! 👋',
                              style: AppTypography.headlineMD,
                            ),
                          ],
                        ),
                      ),
                      // Hộp thư tin nhắn
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
                      const SizedBox(width: AppSpacing.xs),
                      // Avatar
                      GestureDetector(
                        onTap: () => _showProfileSheet(context),
                        child: CircleAvatar(
                          radius: 22,
                          backgroundColor:
                              palette.primary.withValues(alpha: 0.12),
                          backgroundImage: user?.avatarUrl != null &&
                                  user!.avatarUrl!.isNotEmpty
                              ? NetworkImage(user.avatarUrl!)
                              : null,
                          child: user?.avatarUrl == null ||
                                  user!.avatarUrl!.isEmpty
                              ? Text(
                                  user?.fullName.isNotEmpty == true
                                      ? user!.fullName[0].toUpperCase()
                                      : 'U',
                                  style: AppTypography.titleSM.copyWith(
                                    color: palette.primary,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (payableBills.isNotEmpty)
                SliverToBoxAdapter(
                  child: _buildBillNotice(
                    context,
                    bill: payableBills.first,
                    count: payableBills.length,
                    isWaitingApproval: false,
                  ),
                )
              else if (waitingApprovalBills.isNotEmpty)
                SliverToBoxAdapter(
                  child: _buildBillNotice(
                    context,
                    bill: waitingApprovalBills.first,
                    count: waitingApprovalBills.length,
                    isWaitingApproval: true,
                  ),
                ),

              // ─── Search Bar ────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: palette.surfaceLowest,
                      borderRadius: BorderRadius.circular(AppRadius.button),
                      boxShadow: const [AppShadows.card],
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: AppSpacing.md),
                        Icon(
                          Icons.search,
                          color: palette.onSurfaceVariant,
                          size: 22,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            style: AppTypography.bodyMD.copyWith(
                              color: palette.onSurface,
                            ),
                            decoration: const InputDecoration(
                              hintText: AppStrings.search,
                              hintStyle: AppTypography.bodyMD,
                              border: InputBorder.none,
                              filled: false,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: (v) =>
                                ref.read(roomProvider.notifier).search(v),
                          ),
                        ),
                        if (_searchCtrl.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              ref.read(roomProvider.notifier).search('');
                            },
                          ),
                        // Filter icon
                        IconButton(
                          icon: Icon(
                            Icons.tune_outlined,
                            color: palette.onSurfaceVariant,
                            size: 22,
                          ),
                          onPressed: () => context.go('/tenant/search'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ─── Filter Chips ──────────────────────
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    itemCount: districts.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final district = districts[index];
                      final isSelected = _selectedDistrict == district;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedDistrict = district);
                          final filter = roomState.filter;
                          ref.read(roomProvider.notifier).applyFilter(
                                district == 'Tất cả'
                                    ? filter.copyWith(clearDistrict: true)
                                    : filter.copyWith(district: district),
                              );
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            gradient:
                                isSelected ? AppGradients.primaryButton : null,
                            color: isSelected ? null : palette.surfaceLowest,
                            borderRadius: BorderRadius.circular(AppRadius.chip),
                            boxShadow:
                                isSelected ? null : const [AppShadows.card],
                          ),
                          child: Text(
                            district,
                            style: AppTypography.labelSM.copyWith(
                              color: isSelected
                                  ? AppColors.onPrimary
                                  : palette.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // ─── Stats Row ─────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: palette.surfaceLow,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Phòng trống',
                                style: AppTypography.bodySM,
                              ),
                              Text(
                                '${roomState.rooms.where((r) => r.status == RoomStatus.available).length}',
                                style: AppTypography.headlineLG.copyWith(
                                  fontSize: 28,
                                  color: palette.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 36,
                          color:
                              AppColors.outlineVariant.withValues(alpha: 0.5),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: AppSpacing.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Tổng phòng',
                                  style: AppTypography.bodySM,
                                ),
                                Text(
                                  '${roomState.rooms.length}',
                                  style: AppTypography.headlineLG
                                      .copyWith(fontSize: 28),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.trending_up,
                          color: AppColors.available,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ─── Section Header ───────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        AppStrings.roomList,
                        style: AppTypography.titleMD,
                      ),
                      TextButton(
                        onPressed: () => context.go('/tenant/search'),
                        child: const Text(AppStrings.viewAll),
                      ),
                    ],
                  ),
                ),
              ),

              // ─── Room List ────────────────────────
              if (roomState.isLoading)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md, 0, AppSpacing.md, AppSpacing.xxl),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: Shimmer.fromColors(
                          baseColor: palette.surfaceLow,
                          highlightColor: palette.surfaceLowest,
                          child: Container(
                            height: 112,
                            decoration: BoxDecoration(
                              color: palette.surfaceLowest,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.card),
                            ),
                          ),
                        ),
                      ),
                      childCount: 3,
                    ),
                  ),
                )
              else if (filteredRooms.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      children: [
                        Icon(
                          Icons.search_off_outlined,
                          size: 64,
                          color: AppColors.outlineVariant,
                        ),
                        SizedBox(height: AppSpacing.md),
                        Text(
                          'Không tìm thấy phòng phù hợp',
                          style: AppTypography.bodyMD,
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md, 0, AppSpacing.md, AppSpacing.xxl),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final room = filteredRooms[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: RoomCard(
                            room: room,
                            onTap: () => context.go('/tenant/room/${room.id}'),
                          ),
                        );
                      },
                      childCount: filteredRooms.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/tenant/ai-copilot'),
        backgroundColor: context.palette.primary,
        icon: const Icon(Icons.psychology, color: AppColors.onPrimary),
        label: const Text(
          'AI Copilot',
          style: TextStyle(
            color: AppColors.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 4,
      ),
    );
  }

  Widget _buildBillNotice(
    BuildContext context, {
    required Bill bill,
    required int count,
    required bool isWaitingApproval,
  }) {
    final palette = context.palette;
    final accent = isWaitingApproval ? palette.warning : palette.danger;
    final container =
        isWaitingApproval ? palette.warningContainer : palette.dangerContainer;
    final title = isWaitingApproval
        ? 'Đang chờ chủ trọ duyệt thanh toán'
        : 'Có hóa đơn mới cần thanh toán';
    final message = isWaitingApproval
        ? 'Bạn đã báo chuyển khoản ${bill.totalAmount.toVnd()}đ cho phòng ${bill.roomTitle}.'
        : '${count > 1 ? '$count hóa đơn chưa thanh toán. Gần nhất: ' : ''}${bill.roomTitle} - ${bill.totalAmount.toVnd()}đ, hạn ${_fmtDate(bill.dueDate)}.';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: container,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: accent.withValues(alpha: 0.45)),
          boxShadow: const [AppShadows.card],
        ),
        child: Row(
          children: [
            Icon(
              isWaitingApproval
                  ? Icons.hourglass_top_outlined
                  : Icons.receipt_long_outlined,
              color: accent,
              size: 26,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyMD.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: AppTypography.bodySM.copyWith(
                      color: accent,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            ElevatedButton(
              onPressed: () => context.go('/tenant/rentals'),
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor:
                    isWaitingApproval ? palette.onWarning : palette.onDanger,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: Size.zero,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
              ),
              child: Text(
                isWaitingApproval ? 'Xem' : 'Thanh toán',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  void _showProfileSheet(BuildContext context) {
    final user = ref.read(currentUserProvider);
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: context.palette.primary.withValues(alpha: 0.12),
              backgroundImage:
                  user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty
                      ? NetworkImage(user.avatarUrl!)
                      : null,
              child: user?.avatarUrl == null || user!.avatarUrl!.isEmpty
                  ? Text(
                      user?.fullName.isNotEmpty == true
                          ? user!.fullName[0].toUpperCase()
                          : 'U',
                      style: AppTypography.headlineMD.copyWith(
                        color: context.palette.primary,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              user?.fullName ?? '',
              style: AppTypography.titleMD,
            ),
            Text(
              user?.email ?? '',
              style: AppTypography.bodyMD,
            ),
            const SizedBox(height: AppSpacing.lg),
            ListTile(
              leading: const Icon(Icons.policy_outlined),
              title: const Text('Chính sách'),
              onTap: () {
                Navigator.pop(context);
                context.push('/tenant/privacy');
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.logout,
                color: AppColors.error,
              ),
              title: const Text(
                'Đăng xuất',
                style: TextStyle(color: AppColors.error),
              ),
              onTap: () {
                Navigator.pop(context);
                ref.read(createRoomProvider.notifier).reset();
                ref.read(authControllerProvider.notifier).logout();
              },
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}
