import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/constants.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/providers/room_provider.dart';
import '../../widgets/cards/room_card.dart';
import '../../../models/entities/room.dart';

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

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () =>
              ref.read(roomProvider.notifier).loadRooms(),
          color: AppColors.primary,
          child: CustomScrollView(
            slivers: [
              // ─── App Bar ───────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md, AppSpacing.md,
                      AppSpacing.md, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Xin chào,',
                              style: AppTypography.bodyMD,
                            ),
                            Text(
                              user?.fullName.split(' ').last ??
                                  'Bạn ơi! 👋',
                              style: AppTypography.headlineMD,
                            ),
                          ],
                        ),
                      ),
                      // Avatar
                      GestureDetector(
                        onTap: () => _showProfileSheet(context),
                        child: CircleAvatar(
                          radius: 22,
                          backgroundColor: AppColors.primary.withOpacity(0.12),
                          backgroundImage: user?.avatarUrl != null
                              ? NetworkImage(user!.avatarUrl!)
                              : null,
                          child: user?.avatarUrl == null
                              ? Text(
                                  user?.fullName.isNotEmpty == true
                                      ? user!.fullName[0].toUpperCase()
                                      : 'U',
                                  style: AppTypography.titleSM.copyWith(
                                    color: AppColors.primary,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ─── Search Bar ────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(AppRadius.button),
                      boxShadow: const [AppShadows.card],
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: AppSpacing.md),
                        const Icon(
                          Icons.search,
                          color: AppColors.onSurfaceVariant,
                          size: 22,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            style: AppTypography.bodyMD.copyWith(
                              color: AppColors.onSurface,
                            ),
                            decoration: InputDecoration(
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
                          icon: const Icon(
                            Icons.tune_outlined,
                            color: AppColors.onSurfaceVariant,
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md),
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
                                    ? filter.copyWith(
                                        clearDistrict: true)
                                    : filter.copyWith(district: district),
                              );
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? AppGradients.primaryButton
                                : null,
                            color: isSelected
                                ? null
                                : AppColors.surfaceContainerLowest,
                            borderRadius:
                                BorderRadius.circular(AppRadius.chip),
                            boxShadow: isSelected
                                ? null
                                : const [AppShadows.card],
                          ),
                          child: Text(
                            district,
                            style: AppTypography.labelSM.copyWith(
                              color: isSelected
                                  ? AppColors.onPrimary
                                  : AppColors.onSurfaceVariant,
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
                      color: AppColors.surfaceContainerLow,
                      borderRadius:
                          BorderRadius.circular(AppRadius.card),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Phòng trống',
                                style: AppTypography.bodySM,
                              ),
                              Text(
                                '${roomState.rooms.where((r) => r.status == RoomStatus.available).length}',
                                style: AppTypography.headlineLG.copyWith(
                                  fontSize: 28,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 36,
                          color:
                              AppColors.outlineVariant.withOpacity(0.5),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(
                                left: AppSpacing.md),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
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
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                )
              else if (filteredRooms.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.search_off_outlined,
                          size: 64,
                          color: AppColors.outlineVariant,
                        ),
                        const SizedBox(height: AppSpacing.md),
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
                          padding: const EdgeInsets.only(
                              bottom: AppSpacing.md),
                          child: RoomCard(
                            room: room,
                            onTap: () =>
                                context.go('/tenant/room/${room.id}'),
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
    );
  }

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
              backgroundColor: AppColors.primary.withOpacity(0.12),
              child: Text(
                user?.fullName.isNotEmpty == true
                    ? user!.fullName[0].toUpperCase()
                    : 'U',
                style: AppTypography.headlineMD.copyWith(
                  color: AppColors.primary,
                ),
              ),
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
                context.go('/tenant/privacy');
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
