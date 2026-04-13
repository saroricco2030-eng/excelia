import 'package:flutter/material.dart';
import 'package:excelia/l10n/app_localizations.dart';
import 'package:excelia/utils/constants.dart';

/// A compact quick-action card for the horizontal action row.
///
/// Uses module-specific pastel tint backgrounds with a centered
/// icon + label layout. Touch target: 96 x 110 dp.
class QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color lightTint;
  final Color darkTint;
  final VoidCallback onTap;

  const QuickActionCard({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.lightTint,
    required this.darkTint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tintColor = isDark ? darkTint : lightTint;
    final textTheme = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;

    return Semantics(
      button: true,
      label: l.a11yQuickAction(label),
      child: SizedBox(
        width: 96,
        height: 110,
        child: Material(
          color: tintColor,
          borderRadius: BorderRadius.circular(AppSizes.radiusLG),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppSizes.radiusLG),
            splashColor: color.withValues(alpha: 0.12),
            highlightColor: color.withValues(alpha: 0.06),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 32, color: color),
                SizedBox(height: AppSizes.gap8),
                Text(
                  label,
                  style: textTheme.labelSmall?.copyWith(
                    color: isDark
                        ? AppColors.darkOnSurface
                        : AppColors.lightOnSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
