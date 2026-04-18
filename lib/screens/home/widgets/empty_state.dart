import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:excelia/l10n/app_localizations.dart';
import 'package:excelia/utils/constants.dart';

/// A clean empty-state widget shown when the recent-files list is empty.
///
/// Displays a large icon (64dp), a primary message, a secondary
/// hint in muted text, and up to two CTAs (primary + secondary).
/// Hulick "First Mile Success" — first-time users should never face a
/// purely-empty dashboard. Give them both a high-commitment and a
/// low-commitment path.
class EmptyState extends StatelessWidget {
  final VoidCallback? onTap;
  final VoidCallback? onSampleTap;

  const EmptyState({super.key, this.onTap, this.onSampleTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Large icon
            Icon(
              LucideIcons.fileSearch,
              size: 64,
              color: isDark
                  ? AppColors.darkTextMuted
                  : AppColors.lightTextMuted,
            ),

            const SizedBox(height: AppSizes.gap24),

            // Title
            Text(
              l.homeNoRecentFiles,
              style: theme.textTheme.titleMedium?.copyWith(
                color: isDark
                    ? AppColors.darkOnSurface
                    : AppColors.lightOnSurface,
              ),
            ),

            const SizedBox(height: AppSizes.gap8),

            // Description
            Text(
              l.homeNoRecentFilesHint,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppColors.darkTextMuted
                    : AppColors.lightTextMuted,
                height: 1.5,
              ),
            ),

            if (onTap != null) ...[
              const SizedBox(height: AppSizes.gap24),

              // Primary CTA — open existing file
              SizedBox(
                height: 48,
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onTap,
                  icon: const Icon(LucideIcons.folderOpen, size: 20),
                  label: Text(l.emptyStateOpenFile),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMD),
                    ),
                  ),
                ),
              ),
            ],

            if (onSampleTap != null) ...[
              const SizedBox(height: AppSizes.gap12),

              // Secondary CTA — low-commitment exploration
              SizedBox(
                height: 48,
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onSampleTap,
                  icon: const Icon(LucideIcons.sparkles, size: 20),
                  label: Text(l.emptyStateTrySample),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(
                      color: isDark
                          ? AppColors.darkOutlineHi
                          : AppColors.lightOutlineHi,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMD),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
