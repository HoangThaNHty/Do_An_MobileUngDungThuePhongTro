import 'package:flutter/material.dart';

@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final Color primary;
  final Color onPrimary;
  final Color primaryContainer;
  final Color surface;
  final Color surfaceLow;
  final Color surfaceLowest;
  final Color surfaceHigh;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color outline;
  final Color outlineVariant;
  final Color success;
  final Color onSuccess;
  final Color successContainer;
  final Color warning;
  final Color onWarning;
  final Color warningContainer;
  final Color danger;
  final Color onDanger;
  final Color dangerContainer;
  final Color rentedContainer;
  final Color onRentedContainer;
  final Color shadow;
  final Color qrSurface;

  const AppPalette({
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.surface,
    required this.surfaceLow,
    required this.surfaceLowest,
    required this.surfaceHigh,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.outline,
    required this.outlineVariant,
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.warning,
    required this.onWarning,
    required this.warningContainer,
    required this.danger,
    required this.onDanger,
    required this.dangerContainer,
    required this.rentedContainer,
    required this.onRentedContainer,
    required this.shadow,
    required this.qrSurface,
  });

  static const light = AppPalette(
    primary: Color(0xFF005DAC),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFF1976D2),
    surface: Color(0xFFF9F9F9),
    surfaceLow: Color(0xFFF3F3F3),
    surfaceLowest: Color(0xFFFFFFFF),
    surfaceHigh: Color(0xFFE8E8E8),
    onSurface: Color(0xFF1A1C1C),
    onSurfaceVariant: Color(0xFF414752),
    outline: Color(0xFF717783),
    outlineVariant: Color(0xFFC1C6D4),
    success: Color(0xFF2E7D32),
    onSuccess: Color(0xFFFFFFFF),
    successContainer: Color(0xFFE8F5E9),
    warning: Color(0xFFE65100),
    onWarning: Color(0xFFFFFFFF),
    warningContainer: Color(0xFFFFF8E1),
    danger: Color(0xFFC62828),
    onDanger: Color(0xFFFFFFFF),
    dangerContainer: Color(0xFFFFEBEE),
    rentedContainer: Color(0xFFE3E2E2),
    onRentedContainer: Color(0xFF646464),
    shadow: Color(0x10005DAC),
    qrSurface: Color(0xFFFFFFFF),
  );

  static const dark = AppPalette(
    primary: Color(0xFF64B5F6),
    onPrimary: Color(0xFF001E34),
    primaryContainer: Color(0xFF0D47A1),
    surface: Color(0xFF101314),
    surfaceLow: Color(0xFF1A1F21),
    surfaceLowest: Color(0xFF202529),
    surfaceHigh: Color(0xFF2B3236),
    onSurface: Color(0xFFE9EEF0),
    onSurfaceVariant: Color(0xFFB6C0C7),
    outline: Color(0xFF87939B),
    outlineVariant: Color(0xFF3D474D),
    success: Color(0xFF81C784),
    onSuccess: Color(0xFF05210A),
    successContainer: Color(0xFF143A1A),
    warning: Color(0xFFFFB74D),
    onWarning: Color(0xFF3A2100),
    warningContainer: Color(0xFF4A3208),
    danger: Color(0xFFFF8A80),
    onDanger: Color(0xFF3B0604),
    dangerContainer: Color(0xFF4F1815),
    rentedContainer: Color(0xFF363B40),
    onRentedContainer: Color(0xFFD0D6DB),
    shadow: Color(0x55000000),
    qrSurface: Color(0xFFFFFFFF),
  );

  @override
  AppPalette copyWith({
    Color? primary,
    Color? onPrimary,
    Color? primaryContainer,
    Color? surface,
    Color? surfaceLow,
    Color? surfaceLowest,
    Color? surfaceHigh,
    Color? onSurface,
    Color? onSurfaceVariant,
    Color? outline,
    Color? outlineVariant,
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? warning,
    Color? onWarning,
    Color? warningContainer,
    Color? danger,
    Color? onDanger,
    Color? dangerContainer,
    Color? rentedContainer,
    Color? onRentedContainer,
    Color? shadow,
    Color? qrSurface,
  }) {
    return AppPalette(
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      primaryContainer: primaryContainer ?? this.primaryContainer,
      surface: surface ?? this.surface,
      surfaceLow: surfaceLow ?? this.surfaceLow,
      surfaceLowest: surfaceLowest ?? this.surfaceLowest,
      surfaceHigh: surfaceHigh ?? this.surfaceHigh,
      onSurface: onSurface ?? this.onSurface,
      onSurfaceVariant: onSurfaceVariant ?? this.onSurfaceVariant,
      outline: outline ?? this.outline,
      outlineVariant: outlineVariant ?? this.outlineVariant,
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      successContainer: successContainer ?? this.successContainer,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      warningContainer: warningContainer ?? this.warningContainer,
      danger: danger ?? this.danger,
      onDanger: onDanger ?? this.onDanger,
      dangerContainer: dangerContainer ?? this.dangerContainer,
      rentedContainer: rentedContainer ?? this.rentedContainer,
      onRentedContainer: onRentedContainer ?? this.onRentedContainer,
      shadow: shadow ?? this.shadow,
      qrSurface: qrSurface ?? this.qrSurface,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      primaryContainer:
          Color.lerp(primaryContainer, other.primaryContainer, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceLow: Color.lerp(surfaceLow, other.surfaceLow, t)!,
      surfaceLowest: Color.lerp(surfaceLowest, other.surfaceLowest, t)!,
      surfaceHigh: Color.lerp(surfaceHigh, other.surfaceHigh, t)!,
      onSurface: Color.lerp(onSurface, other.onSurface, t)!,
      onSurfaceVariant:
          Color.lerp(onSurfaceVariant, other.onSurfaceVariant, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      outlineVariant: Color.lerp(outlineVariant, other.outlineVariant, t)!,
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      successContainer:
          Color.lerp(successContainer, other.successContainer, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      warningContainer:
          Color.lerp(warningContainer, other.warningContainer, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      onDanger: Color.lerp(onDanger, other.onDanger, t)!,
      dangerContainer: Color.lerp(dangerContainer, other.dangerContainer, t)!,
      rentedContainer: Color.lerp(rentedContainer, other.rentedContainer, t)!,
      onRentedContainer:
          Color.lerp(onRentedContainer, other.onRentedContainer, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      qrSurface: Color.lerp(qrSurface, other.qrSurface, t)!,
    );
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get palette {
    final theme = Theme.of(this);
    return theme.extension<AppPalette>() ??
        (theme.brightness == Brightness.dark
            ? AppPalette.dark
            : AppPalette.light);
  }
}
