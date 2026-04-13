import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:excelia/utils/constants.dart';

// =============================================================================
// Glass Decoration — Light & Dark Soft Glassmorphism
// =============================================================================

class GlassDecoration {
  GlassDecoration._();

  static const double _blurSigma = 8.0;

  /// Card glass effect
  static BoxDecoration card(bool isDark) => BoxDecoration(
    color: isDark ? AppColors.glassDarkBg : AppColors.glassLightBg,
    borderRadius: BorderRadius.circular(AppSizes.radiusLG),
    border: Border.all(
      color: isDark ? AppColors.glassDarkBorder : AppColors.glassLightBorder,
      width: 0.5,
    ),
  );

  /// Toolbar glass effect
  static BoxDecoration toolbar(bool isDark) => BoxDecoration(
    color: isDark ? AppColors.toolbarDark : AppColors.toolbarLight,
    border: Border(
      bottom: BorderSide(
        color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
        width: 0.5,
      ),
    ),
  );

  /// Panel glass effect
  static BoxDecoration panel(bool isDark) => BoxDecoration(
    color: isDark ? AppColors.glassDarkBg : AppColors.glassLightBg,
    borderRadius: BorderRadius.circular(AppSizes.radiusMD),
    border: Border.all(
      color: isDark ? AppColors.glassDarkBorder : AppColors.glassLightBorder,
      width: 0.5,
    ),
  );

  /// Dialog glass effect
  static BoxDecoration dialog(bool isDark) => BoxDecoration(
    color: isDark
        ? AppColors.darkSurface.withValues(alpha: 0.95)
        : AppColors.lightSurface.withValues(alpha: 0.95),
    borderRadius: BorderRadius.circular(AppSizes.radiusXL),
    border: Border.all(
      color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
      width: 0.5,
    ),
  );

  /// Bottom sheet glass effect
  static BoxDecoration bottomSheet(bool isDark) => BoxDecoration(
    color: isDark
        ? AppColors.darkSurface.withValues(alpha: 0.95)
        : AppColors.lightSurface.withValues(alpha: 0.95),
    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
    border: Border(
      top: BorderSide(
        color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
        width: 0.5,
      ),
    ),
  );

  /// Status bar glass effect
  static BoxDecoration statusBar(bool isDark) => BoxDecoration(
    color: isDark ? AppColors.toolbarDark : AppColors.toolbarLight,
    border: Border(
      top: BorderSide(
        color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
        width: 0.5,
      ),
    ),
  );

  /// Standard blur filter
  static ImageFilter get blurFilter =>
      ImageFilter.blur(sigmaX: _blurSigma, sigmaY: _blurSigma);
}

/// Reusable glass card widget with backdrop blur.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius,
    this.padding,
    this.margin,
    this.enableBlur = false,
  });

  final Widget child;
  final double? borderRadius;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final bool enableBlur;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = borderRadius ?? AppSizes.radiusLG;

    Widget content = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? AppColors.glassDarkBg : AppColors.glassLightBg,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: isDark ? AppColors.glassDarkBorder : AppColors.glassLightBorder,
          width: 0.5,
        ),
      ),
      child: child,
    );

    if (enableBlur) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: GlassDecoration.blurFilter,
          child: content,
        ),
      );
    }

    return content;
  }
}
