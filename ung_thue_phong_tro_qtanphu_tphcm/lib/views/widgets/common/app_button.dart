import 'package:flutter/material.dart';
import '../../../config/constants.dart';

// ═══════════════════════════════════════════
// APP BUTTON — Primary (Gradient) / Secondary / Tertiary
// ═══════════════════════════════════════════
enum AppButtonType { primary, secondary, tertiary }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;
  final double? height;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = AppButtonType.primary,
    this.icon,
    this.isLoading = false,
    this.fullWidth = true,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final btnHeight = height ?? AppSpacing.buttonHeight;
    final minSize = fullWidth
        ? Size(double.infinity, btnHeight)
        : Size(0, btnHeight);

    final content = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                type == AppButtonType.primary
                    ? AppColors.onPrimary
                    : AppColors.primary,
              ),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(text),
            ],
          );

    switch (type) {
      case AppButtonType.primary:
        return Container(
          width: fullWidth ? double.infinity : null,
          height: btnHeight,
          decoration: BoxDecoration(
            gradient: AppGradients.primaryButton,
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isLoading ? null : onPressed,
              borderRadius: BorderRadius.circular(AppRadius.button),
              child: Container(
                alignment: Alignment.center,
                child: DefaultTextStyle(
                  style: AppTypography.button,
                  child: content,
                ),
              ),
            ),
          ),
        );

      case AppButtonType.secondary:
        return SizedBox(
          width: fullWidth ? double.infinity : null,
          height: btnHeight,
          child: OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            style: OutlinedButton.styleFrom(
              backgroundColor: AppColors.surfaceContainerHigh,
              foregroundColor: AppColors.primary,
              minimumSize: minSize,
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
              textStyle: const TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: content,
          ),
        );

      case AppButtonType.tertiary:
        return TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            minimumSize: minSize,
            textStyle: const TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: content,
        );
    }
  }
}
