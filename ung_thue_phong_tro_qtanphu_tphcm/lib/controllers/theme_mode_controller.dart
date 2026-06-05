import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode {
  light,
  dark;

  ThemeMode get themeMode {
    return switch (this) {
      AppThemeMode.light => ThemeMode.light,
      AppThemeMode.dark => ThemeMode.dark,
    };
  }

  String get label {
    return switch (this) {
      AppThemeMode.light => 'Sáng',
      AppThemeMode.dark => 'Tối',
    };
  }

  IconData get icon {
    return switch (this) {
      AppThemeMode.light => Icons.light_mode_outlined,
      AppThemeMode.dark => Icons.dark_mode_outlined,
    };
  }
}

final themeModeControllerProvider =
    StateNotifierProvider<ThemeModeController, AppThemeMode>((ref) {
  return ThemeModeController()..load();
});

class ThemeModeController extends StateNotifier<AppThemeMode> {
  ThemeModeController() : super(AppThemeMode.light);

  static const _prefsKey = 'app_theme_mode';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_prefsKey);
    final savedMode = AppThemeMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => AppThemeMode.light,
    );
    state = savedMode;
  }

  Future<void> setMode(AppThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, mode.name);
  }
}
