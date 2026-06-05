import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/app_palette.dart';
import '../../../config/constants.dart';
import '../../../controllers/providers/bill_provider.dart';

// ═══════════════════════════════════════════
// LANDLORD SCAFFOLD — Bottom navigation bar cho chủ trọ
// ═══════════════════════════════════════════
class LandlordScaffold extends ConsumerWidget {
  final Widget child;

  const LandlordScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    final currentIndex = _getIndex(location);
    final pendingPaymentCount = ref
        .watch(pendingPaymentBillsProvider)
        .maybeWhen(data: (bills) => bills.length, orElse: () => 0);
    final palette = context.palette;

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: palette.surfaceLowest,
          boxShadow: const [AppShadows.bottomSheet],
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
                  palette: palette,
                  onTap: () => context.go('/landlord'),
                ),
                _navItem(
                  context: context,
                  icon: Icons.meeting_room_outlined,
                  activeIcon: Icons.meeting_room,
                  label: 'Phòng trọ',
                  isActive: currentIndex == 1,
                  palette: palette,
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
                          gradient: LinearGradient(
                            colors: [
                              palette.primary,
                              palette.primaryContainer,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(AppRadius.chip),
                          boxShadow: const [AppShadows.fab],
                        ),
                        child: Icon(
                          Icons.add,
                          color: palette.onPrimary,
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
                  badgeCount: pendingPaymentCount,
                  palette: palette,
                  onTap: () => context.go('/landlord/tenants'),
                ),
                _navItem(
                  context: context,
                  icon: Icons.receipt_long_outlined,
                  activeIcon: Icons.receipt_long,
                  label: 'Hóa đơn',
                  isActive: currentIndex == 4,
                  palette: palette,
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
    required AppPalette palette,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Badge(
              label: Text('$badgeCount'),
              isLabelVisible: badgeCount > 0,
              backgroundColor: palette.danger,
              child: Icon(
                isActive ? activeIcon : icon,
                color: isActive ? palette.primary : palette.onSurfaceVariant,
                size: 24,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: AppTypography.labelSM.copyWith(
                fontSize: 10,
                color: isActive ? palette.primary : palette.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
