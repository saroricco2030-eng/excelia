import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:excelia/l10n/app_localizations.dart';

import 'package:excelia/providers/app_provider.dart';
import 'package:excelia/providers/spreadsheet_provider.dart';
import 'package:excelia/models/app_document.dart';
import 'package:excelia/models/recent_file.dart';
import 'package:excelia/utils/file_utils.dart';
import 'package:excelia/utils/intent_handler.dart';
import 'package:excelia/utils/permission_utils.dart';
import 'package:excelia/utils/constants.dart';
import 'package:excelia/utils/snackbar_utils.dart';
import 'package:permission_handler/permission_handler.dart';

import 'tabs/bento_dashboard_tab.dart';
import 'tabs/aurora_settings_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    // 핫 스타트 콜백을 await 이전에 등록해 native가 먼저 발사해도 놓치지 않는다.
    IntentHandler.setOnNewFile((path) {
      if (mounted) _openFromPath(context, path);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      context.read<AppProvider>().loadRecentFiles();
      final initialPath = await IntentHandler.getInitialPath();
      if (initialPath != null && mounted) {
        _openFromPath(context, initialPath);
      }
    });
  }

  @override
  void dispose() {
    IntentHandler.clearOnNewFile();
    super.dispose();
  }

  /// 세 가지 진입점(파일 피커 / 최근 파일 / 파일 매니저 intent) 공통 꼬리:
  /// validateFileAccess → 확장자 판별 → 레거시 위임 → 최근 파일 기록 → 라우팅.
  ///
  /// [displayName] — 사용자에게 보일 파일명. null이면 경로에서 유도.
  /// [knownSize]   — 이미 아는 파일 크기. null이면 stat.
  /// [notFoundMessage] — validateFileAccess 실패 시 표시할 커스텀 메시지
  ///   (최근 파일 흐름에서 "{name}을 찾을 수 없습니다" 같이 이름 포함).
  Future<void> _openFromPath(
    BuildContext context,
    String filePath, {
    String? displayName,
    int? knownSize,
    String? notFoundMessage,
  }) async {
    if (!context.mounted) return;
    final l = AppLocalizations.of(context)!;

    if (!await validateFileAccess(filePath)) {
      if (!context.mounted) return;
      showExceliaSnackBar(
        context,
        message: notFoundMessage ?? l.fileReadError,
        isError: true,
      );
      return;
    }

    final docType = FileUtils.getDocumentTypeFromExtension(
      FileUtils.getExtensionLower(filePath),
    );
    if (docType == null) {
      if (!context.mounted) return;
      showExceliaSnackBar(
        context,
        message: l.fileUnsupportedFormat,
        isError: true,
      );
      return;
    }

    // 레거시 바이너리(.xls/.doc/.ppt) — Dart 파서 불가 → 외부 앱 위임
    if (FileUtils.isLegacyBinaryFormat(filePath)) {
      if (!context.mounted) return;
      await _promptOpenExternal(context, filePath);
      return;
    }

    final name = displayName ?? FileUtils.basename(filePath);
    int size = knownSize ?? 0;
    if (knownSize == null) {
      try {
        size = await File(filePath).length();
      } catch (_) {
        // cache 복사본이 사라졌거나 권한 문제 — 크기 0으로 계속
      }
    }
    if (!context.mounted) return;
    context.read<AppProvider>().addRecentFile(
      RecentFile(
        name: name,
        path: filePath,
        type: docType,
        lastOpened: DateTime.now(),
        sizeInBytes: size,
      ),
    );
    _navigateToEditor(context, docType, filePath);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      body: _buildActiveTab(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTab,
        onDestinationSelected: (i) => setState(() => _currentTab = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(LucideIcons.home),
            selectedIcon: const Icon(LucideIcons.home),
            label: l.homeTitle,
          ),
          NavigationDestination(
            icon: const Icon(LucideIcons.settings),
            selectedIcon: const Icon(LucideIcons.settings),
            label: l.commonSettings,
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTab() {
    switch (_currentTab) {
      case 0:
        return BentoDashboardTab(
          onPickFile: () => _pickAndOpenFile(context),
          onPickFileByType: (type) => _pickAndOpenFile(context, filterType: type),
          onOpenRecent: (f) => _openRecentFile(context, f),
          onShareFile: _shareFile,
          onOpenExternal: (f) => _openExternalApp(context, f.path),
          onTrySample: () => _showSampleSheet(context),
        );
      case 1:
        return AuroraSettingsTab(
          onOpenRecent: (f) => _openRecentFile(context, f),
        );
      default:
        return BentoDashboardTab(
          onPickFile: () => _pickAndOpenFile(context),
          onPickFileByType: (type) => _pickAndOpenFile(context, filterType: type),
          onOpenRecent: (f) => _openRecentFile(context, f),
          onShareFile: _shareFile,
          onOpenExternal: (f) => _openExternalApp(context, f.path),
          onTrySample: () => _showSampleSheet(context),
        );
    }
  }

  // ═══════════════════════════════════════════════════
  // Sample content (Hulick first-mile)
  // ═══════════════════════════════════════════════════

  void _showSampleSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor:
          isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final sl = AppLocalizations.of(ctx)!;
        final sIsDark = Theme.of(ctx).brightness == Brightness.dark;
        return Padding(
          padding: EdgeInsets.only(
            top: 12,
            left: 16,
            right: 16,
            bottom: MediaQuery.of(ctx).viewPadding.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: sIsDark
                      ? AppColors.darkOutlineHi
                      : AppColors.lightOutlineHi,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                sl.emptyStateTrySample,
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 16),
              _SampleOption(
                icon: LucideIcons.wallet,
                color: AppColors.spreadsheetGreen,
                label: sl.sampleBudgetName,
                onTap: () {
                  Navigator.pop(ctx);
                  _openSampleSpreadsheet(context, 'budget', sl.sampleBudgetName);
                },
              ),
              const SizedBox(height: 8),
              _SampleOption(
                icon: LucideIcons.calendarDays,
                color: AppColors.documentBlue,
                label: sl.sampleTodoName,
                onTap: () {
                  Navigator.pop(ctx);
                  _openSampleSpreadsheet(context, 'schedule', sl.sampleTodoName);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _openSampleSpreadsheet(
      BuildContext context, String templateKey, String displayName) {
    final provider = context.read<SpreadsheetProvider>();
    provider.createNew(defaultName: displayName);
    provider.createFromTemplate(templateKey);
    context.read<AppProvider>().markLaunched();
    Navigator.pushNamed(context, '/spreadsheet');
  }

  // ═══════════════════════════════════════════════════
  // File Actions (shared across all tabs)
  // ═══════════════════════════════════════════════════

  Future<void> _pickAndOpenFile(BuildContext context,
      {DocumentType? filterType}) async {
    final l = AppLocalizations.of(context)!;
    final hasPermission = await requestStoragePermission();
    if (!hasPermission) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.filePermissionRequired),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          action: SnackBarAction(
            label: l.commonSettings,
            onPressed: () => openAppSettings(),
          ),
        ),
      );
      return;
    }

    final List<String> allowedExtensions;
    switch (filterType) {
      case DocumentType.spreadsheet:
        allowedExtensions = ['xlsx', 'xls', 'csv'];
      case DocumentType.document:
        allowedExtensions = ['docx', 'doc', 'txt', 'rtf'];
      case DocumentType.presentation:
        allowedExtensions = ['pptx', 'ppt'];
      case DocumentType.pdf:
        allowedExtensions = ['pdf'];
      case null:
        allowedExtensions = [
          'xlsx', 'xls', 'csv',
          'docx', 'doc', 'txt', 'rtf',
          'pptx', 'ppt',
          'pdf',
        ];
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
    );

    if (result == null || result.files.isEmpty) return;
    if (!context.mounted) return;

    final pickedFile = result.files.first;
    final filePath = pickedFile.path;
    if (filePath == null) {
      if (!context.mounted) return;
      showExceliaSnackBar(context, message: l.filePathError, isError: true);
      return;
    }
    if (!context.mounted) return;
    await _openFromPath(
      context,
      filePath,
      displayName: pickedFile.name,
      knownSize: pickedFile.size,
    );
  }

  Future<void> _openRecentFile(BuildContext context, RecentFile file) async {
    final l = AppLocalizations.of(context)!;
    await _openFromPath(
      context,
      file.path,
      displayName: file.name,
      knownSize: file.sizeInBytes,
      notFoundMessage: l.fileNotFoundName(file.name),
    );
  }

  void _navigateToEditor(
      BuildContext context, DocumentType docType, String filePath) {
    switch (docType) {
      case DocumentType.spreadsheet:
        Navigator.pushNamed(context, '/spreadsheet', arguments: filePath);
      case DocumentType.document:
        Navigator.pushNamed(context, '/document', arguments: filePath);
      case DocumentType.presentation:
        Navigator.pushNamed(context, '/presentation', arguments: filePath);
      case DocumentType.pdf:
        Navigator.pushNamed(context, '/pdf', arguments: filePath);
    }
  }

  /// 레거시 포맷 또는 파싱 실패 시 — "외부 앱으로 열기" 확인 다이얼로그
  Future<void> _promptOpenExternal(BuildContext context, String filePath) async {
    final ext = FileUtils.getExtensionUpper(filePath);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final l = AppLocalizations.of(ctx)!;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(l.legacyFormatTitle),
          content: Text(l.legacyFormatBody(ext)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l.openInExternalApp),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) return;
    await _openExternalApp(context, filePath);
  }

  Future<void> _openExternalApp(BuildContext context, String filePath) async {
    final l = AppLocalizations.of(context)!;
    final error = await FileUtils.openWithExternalApp(filePath);
    if (!context.mounted || error == null) return;
    // "No APP found to open this file" 계열 메시지일 때 friendlier 메시지
    final message = error.toLowerCase().contains('no app')
        ? l.externalAppError
        : l.externalAppOpenFailed(error);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _shareFile(RecentFile file) async {
    final l = AppLocalizations.of(context)!;
    try {
      final f = File(file.path);
      if (await f.exists()) {
        await Share.shareXFiles([XFile(file.path)], text: file.name);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.fileNotFound)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.fileShareError(e.toString()))),
      );
    }
  }
}

class _SampleOption extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _SampleOption({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusMD),
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.20 : 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: isDark
                    ? AppColors.darkTextMuted
                    : AppColors.lightTextMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
