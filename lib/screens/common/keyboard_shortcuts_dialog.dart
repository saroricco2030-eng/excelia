import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:excelia/l10n/app_localizations.dart';
import 'package:excelia/utils/constants.dart';

/// Shows keyboard shortcuts dialog for the given [module].
/// [module] can be 'document', 'presentation', or 'spreadsheet'.
void showKeyboardShortcutsDialog(BuildContext context, String module) {
  showDialog(
    context: context,
    builder: (ctx) {
      final l = AppLocalizations.of(ctx)!;
      return _KeyboardShortcutsDialog(module: module, l: l);
    },
  );
}

class _KeyboardShortcutsDialog extends StatelessWidget {
  const _KeyboardShortcutsDialog({
    required this.module,
    required this.l,
  });

  final String module;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(LucideIcons.keyboard, size: 20),
          const SizedBox(width: 8),
          Text(l.keyboardShortcuts),
        ],
      ),
      content: SizedBox(
        width: 320,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Common shortcuts
              _sectionHeader(context, l.shortcutSectionCommon),
              _shortcutRow('Ctrl + S', l.shortcutSave),
              _shortcutRow('Ctrl + Z', l.shortcutUndo),
              _shortcutRow('Ctrl + Y', l.shortcutRedo),
              _shortcutRow('Ctrl + F', l.shortcutFind),
              const SizedBox(height: 16),
              // Module-specific
              if (module == 'document') ...[
                _sectionHeader(context, l.shortcutSectionDocument),
                _shortcutRow('Ctrl + B', l.shortcutBold),
                _shortcutRow('Ctrl + I', l.shortcutItalic),
                _shortcutRow('Ctrl + U', l.shortcutUnderline),
              ],
              if (module == 'presentation') ...[
                _sectionHeader(context, l.shortcutSectionPresentation),
                _shortcutRow('Delete', l.shortcutDelete),
                _shortcutRow('Ctrl + D', l.shortcutDuplicate),
              ],
              if (module == 'spreadsheet') ...[
                _sectionHeader(context, l.shortcutSectionSpreadsheet),
                _shortcutRow('Arrow Keys', l.shortcutNavigation),
                _shortcutRow('Tab', l.shortcutNextCell),
                _shortcutRow('F2', l.shortcutEditCell),
                _shortcutRow('Delete', l.shortcutDelete),
                _shortcutRow('Ctrl + C', l.shortcutCopy),
                _shortcutRow('Ctrl + X', l.shortcutCut),
                _shortcutRow('Ctrl + V', l.shortcutPaste),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.commonClose),
        ),
      ],
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: isDark ? AppColors.darkOnSurfaceAlt : AppColors.grey600,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _shortcutRow(String keys, String description) {
    return Builder(builder: (context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceElevated : AppColors.grey100,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isDark ? AppColors.darkOutline : AppColors.grey300,
                  width: 0.5,
                ),
              ),
              child: Text(
                keys,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'monospace',
                  color: isDark ? AppColors.darkOnSurface : AppColors.grey800,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.darkOnSurfaceAlt : AppColors.grey600,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
