import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:excelia/l10n/app_localizations.dart';
import 'package:excelia/utils/constants.dart';

import 'package:excelia/models/recent_file.dart';
import 'package:excelia/utils/file_utils.dart';

/// A clean list tile for displaying a recent file.
///
/// Shows the document-type icon in a tinted circle, file name (w600),
/// date + file size in muted text, and a trailing popup menu.
/// Wraps in [Dismissible] for swipe-to-delete.
class RecentFileTile extends StatelessWidget {
  final RecentFile file;
  final VoidCallback onOpen;
  final VoidCallback onDelete;
  final VoidCallback onShare;
  final VoidCallback? onOpenExternal;

  const RecentFileTile({
    super.key,
    required this.file,
    required this.onOpen,
    required this.onDelete,
    required this.onShare,
    this.onOpenExternal,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final typeColor = FileUtils.getDocumentTypeColor(file.type);
    final typeIcon = FileUtils.getDocumentTypeIcon(file.type);
    final d = file.lastOpened;
    final dateStr =
        '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}  '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

    return RepaintBoundary(
      child: Semantics(
        button: true,
        label: l.a11yRecentFile(file.name),
        child: Dismissible(
        key: Key(file.path),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onDelete(),
        confirmDismiss: (_) async {
          return await showDialog<bool>(
                context: context,
                builder: (ctx) {
                  final dl = AppLocalizations.of(ctx)!;
                  return AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusXL),
                    ),
                    title: Text(dl.fileDeleteTitle),
                    content: Text(dl.fileDeleteConfirm(file.name)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(dl.commonCancel),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(
                          dl.commonDelete,
                          style: TextStyle(color: colorScheme.error),
                        ),
                      ),
                    ],
                  );
                },
              ) ??
              false;
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          decoration: BoxDecoration(
            color: colorScheme.error,
            borderRadius: BorderRadius.circular(AppSizes.radiusMD),
          ),
          child: const Icon(LucideIcons.trash2, color: AppColors.white, size: 24),
        ),
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
                width: 1,
              ),
            ),
          ),
          child: Material(
            color: AppColors.transparent,
            child: InkWell(
              onTap: onOpen,
              borderRadius: BorderRadius.circular(AppSizes.radiusMD),
              splashColor: typeColor.withValues(alpha: 0.08),
              highlightColor: typeColor.withValues(alpha: 0.04),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    // Leading: Module icon in tinted circle
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: isDark ? 0.20 : 0.10),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(typeIcon, color: typeColor, size: 20),
                    ),
                    const SizedBox(width: 16),

                    // Title + subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            file.name,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.darkOnSurface
                                  : AppColors.lightOnSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$dateStr  ${FileUtils.formatFileSize(file.sizeInBytes)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? AppColors.darkTextMuted
                                  : AppColors.lightTextMuted,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Trailing: More menu
                    PopupMenuButton<_TileAction>(
                      icon: Icon(
                        LucideIcons.moreVertical,
                        color: isDark
                            ? AppColors.darkOnSurfaceAlt
                            : AppColors.lightOnSurfaceAlt,
                        size: 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusMD),
                      ),
                      position: PopupMenuPosition.under,
                      onSelected: (action) {
                        switch (action) {
                          case _TileAction.open:
                            onOpen();
                          case _TileAction.openExternal:
                            onOpenExternal?.call();
                          case _TileAction.delete:
                            onDelete();
                          case _TileAction.share:
                            onShare();
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: _TileAction.open,
                          child: Row(
                            children: [
                              const Icon(LucideIcons.externalLink, size: 18),
                              const SizedBox(width: 10),
                              Text(l.commonOpen),
                            ],
                          ),
                        ),
                        if (onOpenExternal != null)
                          PopupMenuItem(
                            value: _TileAction.openExternal,
                            child: Row(
                              children: [
                                const Icon(LucideIcons.appWindow, size: 18),
                                const SizedBox(width: 10),
                                Text(l.openInExternalApp),
                              ],
                            ),
                          ),
                        PopupMenuItem(
                          value: _TileAction.share,
                          child: Row(
                            children: [
                              const Icon(LucideIcons.share2, size: 18),
                              const SizedBox(width: 10),
                              Text(l.commonShare),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: _TileAction.delete,
                          child: Row(
                            children: [
                              Icon(LucideIcons.trash2,
                                  size: 18, color: colorScheme.error),
                              const SizedBox(width: 10),
                              Text(l.commonDelete,
                                  style: TextStyle(color: colorScheme.error)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}

enum _TileAction { open, openExternal, delete, share }
