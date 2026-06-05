import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_palette.dart';
import '../../../config/constants.dart';
import '../../../controllers/theme_mode_controller.dart';

class ThemeModeSelector extends ConsumerWidget {
  const ThemeModeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final selectedMode = ref.watch(themeModeControllerProvider);
    const modes = [AppThemeMode.light, AppThemeMode.dark];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: palette.surfaceLowest,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: palette.outlineVariant),
        boxShadow: const [AppShadows.card],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.contrast_outlined, color: palette.primary, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Giao diện',
                style: AppTypography.titleSM.copyWith(
                  color: palette.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SegmentedButton<AppThemeMode>(
            showSelectedIcon: false,
            segments: modes.map((mode) {
              return ButtonSegment<AppThemeMode>(
                value: mode,
                icon: Icon(mode.icon, size: 18),
                label: Text(mode.label),
              );
            }).toList(),
            selected: {selectedMode},
            onSelectionChanged: (selection) {
              ref
                  .read(themeModeControllerProvider.notifier)
                  .setMode(selection.first);
            },
          ),
        ],
      ),
    );
  }
}
