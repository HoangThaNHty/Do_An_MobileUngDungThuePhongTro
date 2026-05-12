import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/constants.dart';

// ═══════════════════════════════════════════
// LANDLORD SCAFFOLD — Bottom navigation bar cho chủ trọ
// ═══════════════════════════════════════════
class LandlordScaffold extends StatelessWidget {
  final Widget child;

  const LandlordScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final currentIndex = _getIndex(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          boxShadow: [AppShadows.bottomSheet],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 68,
            child: Row(
              children: [
                _navItem(
                  context: context,
                  icon: Icons.home_work_outlined,
                  activeIcon: Icons.home_work,
                  label: 'Tổng quan',
                  isActive: currentIndex == 0,
                  onTap: () => context.go('/landlord'),
                ),
                _navItem(
                  context: context,
                  icon: Icons.meeting_room_outlined,
                  activeIcon: Icons.meeting_room,
                  label: 'Phòng trọ',
                  isActive: currentIndex == 1,
                  onTap: () => context.go('/landlord/rooms'),
                ),
                // FAB — Thêm phòng
                Expanded(
                  child: Center(
                    child: GestureDetector(
                      onTap: () => context.go('/landlord/create-room/step1'),
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: AppGradients.primaryFab,
                          borderRadius: BorderRadius.circular(AppRadius.chip),
                          boxShadow: const [AppShadows.fab],
                        ),
                        child: const Icon(
                          Icons.add,
                          color: AppColors.onPrimary,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ),
                _navItem(
                  context: context,
                  icon: Icons.people_outline,
                  activeIcon: Icons.people,
                  label: 'Người thuê',
                  isActive: currentIndex == 3,
                  onTap: () => context.go('/landlord/tenants'),
                ),
                _navItem(
                  context: context,
                  icon: Icons.receipt_long_outlined,
                  activeIcon: Icons.receipt_long,
                  label: 'Hóa đơn',
                  isActive: currentIndex == 4,
                  onTap: () => context.go('/landlord/create-bill'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _getIndex(String location) {
    if (location == '/landlord') return 0;
    if (location.startsWith('/landlord/rooms')) return 1;
    if (location.startsWith('/landlord/tenants')) return 3;
    if (location.startsWith('/landlord/create-bill')) return 4;
    if (location.startsWith('/landlord/create-room')) return 2;
    return 0;
  }

  Widget _navItem({
    required BuildContext context,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? AppColors.primary : AppColors.onSurfaceVariant,
              size: 24,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: AppTypography.labelSM.copyWith(
                fontSize: 10,
                color:
                    isActive ? AppColors.primary : AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
