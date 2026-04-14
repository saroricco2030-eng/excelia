import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:excelia/l10n/app_localizations.dart';

import 'package:excelia/providers/app_provider.dart';
import 'package:excelia/models/app_document.dart';
import 'package:excelia/models/recent_file.dart';
import 'package:excelia/utils/file_utils.dart';
import 'package:excelia/utils/permission_utils.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().loadRecentFiles();
    });
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
        );
    }
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.filePathError),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    if (!await validateFileAccess(filePath)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.fileReadError),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final extension = filePath.split('.').last.toLowerCase();
    final docType = FileUtils.getDocumentTypeFromExtension(extension);
    if (docType == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.fileUnsupportedFormat),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    // 레거시 바이너리 포맷(xls/doc/ppt) — Dart 파서 불가 → 외부 앱 위임
    if (FileUtils.isLegacyBinaryFormat(filePath)) {
      if (!context.mounted) return;
      await _promptOpenExternal(context, filePath);
      return;
    }

    final recentFile = RecentFile(
      name: pickedFile.name,
      path: filePath,
      type: docType,
      lastOpened: DateTime.now(),
      sizeInBytes: pickedFile.size,
    );
    if (!context.mounted) return;
    context.read<AppProvider>().addRecentFile(recentFile);
    _navigateToEditor(context, docType, filePath);
  }

  Future<void> _openRecentFile(BuildContext context, RecentFile file) async {
    final l = AppLocalizations.of(context)!;
    if (!await validateFileAccess(file.path)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.fileNotFoundName(file.name)),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    if (!context.mounted) return;

    // 레거시 바이너리 포맷 — 외부 앱 위임
    if (FileUtils.isLegacyBinaryFormat(file.path)) {
      await _promptOpenExternal(context, file.path);
      return;
    }

    final updatedFile = file.copyWith(lastOpened: DateTime.now());
    context.read<AppProvider>().addRecentFile(updatedFile);
    _navigateToEditor(context, file.type, file.path);
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
