import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:excelia/l10n/app_localizations.dart';
import 'package:excelia/utils/constants.dart';

/// A clean empty-state widget shown when the recent-files list is empty.
///
/// Displays a large icon (64dp), a primary message, a secondary
/// hint in muted text, and a CTA button to open or create a file.
class EmptyState extends StatelessWidget {
  final VoidCallback? onTap;

  const EmptyState({super.key, this.onTap});

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

              // CTA button
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: onTap,
                  icon: const Icon(LucideIcons.folderOpen, size: 20),
                  label: Text(l.fileOpen),
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
          ],
        ),
      ),
    );
  }
}
