import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/app_palette.dart';
import '../../../config/constants.dart';

// ═══════════════════════════════════════════
// TENANT SCAFFOLD — Bottom navigation bar cho người thuê
// ═══════════════════════════════════════════
class TenantScaffold extends StatelessWidget {
  final Widget child;

  const TenantScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final currentIndex = _getIndex(location);
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
                  icon: Icons.explore_outlined,
                  activeIcon: Icons.explore,
                  label: AppStrings.explore,
                  isActive: currentIndex == 0,
                  palette: palette,
                  onTap: () => context.go('/tenant'),
                ),
                _navItem(
                  context: context,
                  icon: Icons.search_outlined,
                  activeIcon: Icons.search,
                  label: 'Tìm kiếm',
                  isActive: currentIndex == 1,
                  palette: palette,
                  onTap: () => context.go('/tenant/search'),
                ),
                // FAB center
                Expanded(
                  child: Center(
                    child: GestureDetector(
                      onTap: () => context.go('/tenant/map'),
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
                          Icons.map_outlined,
                          color: palette.onPrimary,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
                _navItem(
                  context: context,
                  icon: Icons.calendar_month_outlined,
                  activeIcon: Icons.calendar_month,
                  label: AppStrings.rentals,
                  isActive: currentIndex == 3,
                  palette: palette,
                  onTap: () => context.go('/tenant/rentals'),
                ),
                _navItem(
                  context: context,
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: AppStrings.profile,
                  isActive: currentIndex == 4,
                  palette: palette,
                  onTap: () => context.go('/tenant/profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _getIndex(String location) {
    if (location == '/tenant') return 0;
    if (location.startsWith('/tenant/search')) return 1;
    if (location.startsWith('/tenant/map')) return 2;
    if (location.startsWith('/tenant/rentals')) return 3;
    if (location.startsWith('/tenant/profile')) return 4;
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
              color: isActive ? palette.primary : palette.onSurfaceVariant,
              size: 24,
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
