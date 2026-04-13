import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:excelia/l10n/app_localizations.dart';
import 'package:excelia/providers/app_provider.dart';
import 'package:excelia/models/recent_file.dart';
import 'package:excelia/utils/constants.dart';
import 'package:excelia/screens/common/keyboard_shortcuts_dialog.dart';

// =============================================================================
// Tab 5 — Settings (clean grouped list layout)
// =============================================================================

class AuroraSettingsTab extends StatelessWidget {
  final void Function(RecentFile)? onOpenRecent;

  const AuroraSettingsTab({super.key, this.onOpenRecent});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appProv = context.watch<AppProvider>();

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(context).viewPadding.bottom + 80,
          ),
          children: [
            // ── App Info Header ──
            _buildAppInfo(context, l, isDark),
            const SizedBox(height: 24),

            // ── Appearance ──
            _buildSectionHeader(context, l.settingsAppearance),
            const SizedBox(height: 8),
            _buildSettingsCard(context, isDark, [
              _buildThemeTile(context, l, isDark, appProv),
              _buildDivider(isDark),
              _buildLanguageTile(context, l, isDark),
            ]),
            const SizedBox(height: 24),

            // ── Files ──
            _buildSectionHeader(context, l.settingsFiles),
            const SizedBox(height: 8),
            _buildSettingsCard(context, isDark, [
              _buildAutoSaveTile(context, l, isDark, appProv),
              _buildDivider(isDark),
              _buildKeyboardShortcutsTile(context, l, isDark),
            ]),
            const SizedBox(height: 24),

            // ── Data ──
            _buildSectionHeader(context, l.settingsData),
            const SizedBox(height: 8),
            _buildSettingsCard(context, isDark, [
              _buildExportTile(context, l, isDark, appProv),
              _buildDivider(isDark),
              _buildResetTile(context, l, isDark),
            ]),
            const SizedBox(height: 24),

            // ── About ──
            _buildSectionHeader(context, l.settingsAbout),
            const SizedBox(height: 8),
            _buildSettingsCard(context, isDark, [
              _buildVersionTile(context, l, isDark),
              _buildDivider(isDark),
              _buildLicensesTile(context, l, isDark),
            ]),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // App Info Header
  // ---------------------------------------------------------------------------

  Widget _buildAppInfo(
      BuildContext context, AppLocalizations l, bool isDark) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: Text(
              'E',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          l.appName,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: isDark ? AppColors.white : AppColors.lightOnSurface,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          l.appSubtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppColors.darkTextMuted
                    : AppColors.lightTextMuted,
              ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Section header
  // ---------------------------------------------------------------------------

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Settings card container
  // ---------------------------------------------------------------------------

  Widget _buildSettingsCard(
      BuildContext context, bool isDark, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLG),
        border: Border.all(
          color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
          width: 0.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 0.5,
      indent: 56,
      color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
    );
  }

  // ---------------------------------------------------------------------------
  // Theme tile
  // ---------------------------------------------------------------------------

  Widget _buildThemeTile(BuildContext context, AppLocalizations l, bool isDark,
      AppProvider appProv) {
    String themeName;
    switch (appProv.themeMode) {
      case ThemeMode.system:
        themeName = l.settingsThemeSystem;
      case ThemeMode.light:
        themeName = l.settingsThemeLight;
      case ThemeMode.dark:
        themeName = l.settingsThemeDark;
    }

    return ListTile(
      leading: Icon(
        LucideIcons.palette,
        color: isDark ? AppColors.darkOnSurfaceAlt : AppColors.lightOnSurfaceAlt,
        size: 22,
      ),
      title: Text(
        l.settingsTheme,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: isDark ? AppColors.white : AppColors.lightOnSurface,
        ),
      ),
      subtitle: Text(
        l.settingsThemeSubtitle,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: isDark ? 0.12 : 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          themeName,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      minVerticalPadding: 12,
      onTap: () => _showThemeDialog(context, l, isDark, appProv),
    );
  }

  void _showThemeDialog(BuildContext context, AppLocalizations l, bool isDark,
      AppProvider appProv) {
    showDialog(
      context: context,
      builder: (ctx) {
        final isDarkDialog = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDarkDialog
              ? AppColors.darkSurface
              : AppColors.lightSurface,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Text(
            l.settingsTheme,
            style: TextStyle(
              color: isDarkDialog ? AppColors.white : AppColors.lightOnSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ThemeOption(
                label: l.settingsThemeSystem,
                icon: LucideIcons.monitor,
                isSelected: appProv.themeMode == ThemeMode.system,
                isDark: isDarkDialog,
                onTap: () {
                  appProv.setThemeMode(ThemeMode.system);
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 8),
              _ThemeOption(
                label: l.settingsThemeLight,
                icon: LucideIcons.sun,
                isSelected: appProv.themeMode == ThemeMode.light,
                isDark: isDarkDialog,
                onTap: () {
                  appProv.setThemeMode(ThemeMode.light);
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 8),
              _ThemeOption(
                label: l.settingsThemeDark,
                icon: LucideIcons.moon,
                isSelected: appProv.themeMode == ThemeMode.dark,
                isDark: isDarkDialog,
                onTap: () {
                  appProv.setThemeMode(ThemeMode.dark);
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Language tile
  // ---------------------------------------------------------------------------

  Widget _buildLanguageTile(
      BuildContext context, AppLocalizations l, bool isDark) {
    final currentLocale = Localizations.localeOf(context).languageCode;
    final langLabel = currentLocale == 'ko' ? l.languageKorean : l.languageEnglish;

    return ListTile(
      leading: Icon(
        LucideIcons.languages,
        color: isDark ? AppColors.darkOnSurfaceAlt : AppColors.lightOnSurfaceAlt,
        size: 22,
      ),
      title: Text(
        l.profileLanguage,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: isDark ? AppColors.white : AppColors.lightOnSurface,
        ),
      ),
      subtitle: Text(
        l.settingsLanguageSubtitle,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            langLabel,
            style: TextStyle(
              fontSize: 13,
              color:
                  isDark ? AppColors.darkOnSurfaceAlt : AppColors.lightOnSurfaceAlt,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            LucideIcons.chevronRight,
            size: 16,
            color:
                isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          ),
        ],
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      minVerticalPadding: 12,
      onTap: () => _showLanguageSheet(context),
    );
  }

  void _showLanguageSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.transparent,
      builder: (ctx) {
        final l = AppLocalizations.of(ctx)!;
        final bottomPad = MediaQuery.of(ctx).viewPadding.bottom;
        final isDarkSheet = Theme.of(ctx).brightness == Brightness.dark;
        final currentLocale = Localizations.localeOf(ctx).languageCode;

        return Container(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 24,
            bottom: bottomPad + 20,
          ),
          decoration: BoxDecoration(
            color: isDarkSheet
                ? AppColors.darkSurface
                : AppColors.lightSurface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDarkSheet
                      ? AppColors.darkOutline
                      : AppColors.lightOutline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l.selectLanguage,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkSheet
                      ? AppColors.white
                      : AppColors.lightOnSurface,
                ),
              ),
              const SizedBox(height: 16),
              _LanguageOption(
                label: l.languageKorean,
                code: 'ko',
                isSelected: currentLocale == 'ko',
                isDark: isDarkSheet,
                onTap: () => Navigator.pop(ctx),
              ),
              const SizedBox(height: 8),
              _LanguageOption(
                label: l.languageEnglish,
                code: 'en',
                isSelected: currentLocale == 'en',
                isDark: isDarkSheet,
                onTap: () => Navigator.pop(ctx),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Auto-save tile
  // ---------------------------------------------------------------------------

  Widget _buildAutoSaveTile(BuildContext context, AppLocalizations l,
      bool isDark, AppProvider appProv) {
    return ListTile(
      leading: Icon(
        LucideIcons.save,
        color: isDark ? AppColors.darkOnSurfaceAlt : AppColors.lightOnSurfaceAlt,
        size: 22,
      ),
      title: Text(
        l.autoSave,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: isDark ? AppColors.white : AppColors.lightOnSurface,
        ),
      ),
      subtitle: Text(
        l.settingsAutoSaveSubtitle,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
        ),
      ),
      trailing: Switch.adaptive(
        value: appProv.autoSaveEnabled,
        onChanged: (_) => appProv.toggleAutoSave(),
        activeTrackColor: AppColors.primary,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      minVerticalPadding: 12,
      onTap: () => appProv.toggleAutoSave(),
    );
  }

  // ---------------------------------------------------------------------------
  // Keyboard shortcuts tile
  // ---------------------------------------------------------------------------

  Widget _buildKeyboardShortcutsTile(
      BuildContext context, AppLocalizations l, bool isDark) {
    return ListTile(
      leading: Icon(
        LucideIcons.keyboard,
        color: isDark ? AppColors.darkOnSurfaceAlt : AppColors.lightOnSurfaceAlt,
        size: 22,
      ),
      title: Text(
        l.keyboardShortcuts,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: isDark ? AppColors.white : AppColors.lightOnSurface,
        ),
      ),
      subtitle: Text(
        l.settingsKeyboardSubtitle,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
        ),
      ),
      trailing: Icon(
        LucideIcons.chevronRight,
        size: 16,
        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      minVerticalPadding: 12,
      onTap: () => showKeyboardShortcutsDialog(context, 'spreadsheet'),
    );
  }

  // ---------------------------------------------------------------------------
  // Export tile
  // ---------------------------------------------------------------------------

  Widget _buildExportTile(BuildContext context, AppLocalizations l,
      bool isDark, AppProvider appProv) {
    return ListTile(
      leading: Icon(
        LucideIcons.download,
        color: isDark ? AppColors.darkOnSurfaceAlt : AppColors.lightOnSurfaceAlt,
        size: 22,
      ),
      title: Text(
        l.profileExport,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: isDark ? AppColors.white : AppColors.lightOnSurface,
        ),
      ),
      subtitle: Text(
        l.settingsExportSubtitle,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
        ),
      ),
      trailing: Icon(
        LucideIcons.chevronRight,
        size: 16,
        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      minVerticalPadding: 12,
      onTap: () => _showExportDialog(context),
    );
  }

  void _showExportDialog(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final provider = context.read<AppProvider>();
    final recentFiles = provider.recentFiles;

    if (recentFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.profileExportNoFiles),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    // Share the most recent file
    final file = recentFiles.first;
    _shareFile(context, file);
  }

  Future<void> _shareFile(BuildContext context, RecentFile file) async {
    final l = AppLocalizations.of(context)!;
    try {
      final f = File(file.path);
      if (await f.exists()) {
        await Share.shareXFiles([XFile(file.path)], text: file.name);
      } else {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.fileNotFound)),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.fileShareError(e.toString()))),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Reset tile
  // ---------------------------------------------------------------------------

  Widget _buildResetTile(
      BuildContext context, AppLocalizations l, bool isDark) {
    return ListTile(
      leading: const Icon(
        LucideIcons.trash2,
        color: AppColors.error,
        size: 22,
      ),
      title: Text(
        l.profileReset,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.error,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      minVerticalPadding: 12,
      onTap: () => _showResetDialog(context),
    );
  }

  void _showResetDialog(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor:
              isDark ? AppColors.darkSurface : AppColors.lightSurface,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Text(
            l.homeClearRecentTitle,
            style: TextStyle(
              color: isDark ? AppColors.white : AppColors.lightOnSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            l.profileResetConfirm,
            style: TextStyle(
              color: isDark
                  ? AppColors.darkOnSurfaceAlt
                  : AppColors.lightOnSurfaceAlt,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                l.commonCancel,
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkOnSurfaceAlt
                      : AppColors.lightOnSurfaceAlt,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                context.read<AppProvider>().clearRecentFiles();
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l.homeClearRecentTitle),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
              child: Text(
                l.commonConfirm,
                style: const TextStyle(color: AppColors.pdfRed),
              ),
            ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Version tile
  // ---------------------------------------------------------------------------

  Widget _buildVersionTile(
      BuildContext context, AppLocalizations l, bool isDark) {
    return ListTile(
      leading: Icon(
        LucideIcons.info,
        color: isDark ? AppColors.darkOnSurfaceAlt : AppColors.lightOnSurfaceAlt,
        size: 22,
      ),
      title: Text(
        l.profileVersion,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: isDark ? AppColors.white : AppColors.lightOnSurface,
        ),
      ),
      subtitle: Text(
        l.settingsVersionSubtitle,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
        ),
      ),
      trailing: Text(
        l.appVersion,
        style: TextStyle(
          fontSize: 13,
          color:
              isDark ? AppColors.darkOnSurfaceAlt : AppColors.lightOnSurfaceAlt,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      minVerticalPadding: 12,
    );
  }

  // ---------------------------------------------------------------------------
  // Licenses tile
  // ---------------------------------------------------------------------------

  Widget _buildLicensesTile(
      BuildContext context, AppLocalizations l, bool isDark) {
    return ListTile(
      leading: Icon(
        LucideIcons.fileText,
        color: isDark ? AppColors.darkOnSurfaceAlt : AppColors.lightOnSurfaceAlt,
        size: 22,
      ),
      title: Text(
        l.settingsLicenses,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: isDark ? AppColors.white : AppColors.lightOnSurface,
        ),
      ),
      subtitle: Text(
        l.settingsLicensesSubtitle,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
        ),
      ),
      trailing: Icon(
        LucideIcons.chevronRight,
        size: 16,
        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      minVerticalPadding: 12,
      onTap: () => showLicensePage(
        context: context,
        applicationName: l.appName,
        applicationVersion: l.appVersion,
      ),
    );
  }
}

// =============================================================================
// _ThemeOption — dialog row item
// =============================================================================

class _ThemeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.3)
                : (isDark ? AppColors.darkOutline : AppColors.lightOutline),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? AppColors.primary
                  : (isDark
                      ? AppColors.darkOnSurfaceAlt
                      : AppColors.lightOnSurfaceAlt),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? AppColors.white : AppColors.lightOnSurface),
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(
                LucideIcons.check,
                size: 20,
                color: AppColors.primary,
              ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// _LanguageOption — bottom sheet row item
// =============================================================================

class _LanguageOption extends StatelessWidget {
  final String label;
  final String code;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.label,
    required this.code,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.3)
                : (isDark ? AppColors.darkOutline : AppColors.lightOutline),
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? AppColors.white : AppColors.lightOnSurface),
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(
                LucideIcons.check,
                size: 20,
                color: AppColors.primary,
              ),
          ],
        ),
      ),
    );
  }
}
