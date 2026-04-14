import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:excelia/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:excelia/providers/app_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excelia/models/print_setup.dart';
import 'package:excelia/providers/spreadsheet_provider.dart';
import 'package:excelia/screens/common/keyboard_shortcuts_dialog.dart';
import 'package:excelia/utils/constants.dart';
import 'package:excelia/utils/snackbar_utils.dart';
import 'package:excelia/utils/file_utils.dart';
import 'widgets/spreadsheet_grid.dart';
import 'widgets/formula_bar.dart';
import 'widgets/toolbar.dart';
import 'widgets/sheet_tab_bar.dart';
import 'widgets/chart_widget.dart';
import 'widgets/data_validation_dialog.dart';
import 'widgets/name_manager_dialog.dart';
import 'widgets/pivot_table_dialog.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

class SpreadsheetScreen extends StatefulWidget {
  const SpreadsheetScreen({super.key});

  @override
  State<SpreadsheetScreen> createState() => _SpreadsheetScreenState();
}

class _SpreadsheetScreenState extends State<SpreadsheetScreen> {
  bool _toolbarVisible = true;
  bool _showFindBar = false;
  final TextEditingController _findCtrl = TextEditingController();
  final TextEditingController _replaceCtrl = TextEditingController();
  Timer? _autoSaveTimer;
  SpreadsheetProvider? _spreadsheetProvider;

  @override
  void initState() {
    super.initState();
    _spreadsheetProvider = context.read<SpreadsheetProvider>();
    _spreadsheetProvider!.addListener(_onProviderChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prov = _spreadsheetProvider!;
      final arg = ModalRoute.of(context)?.settings.arguments as String?;
      if (arg != null && arg.startsWith('template:')) {
        prov.createNew();
        prov.createFromTemplate(arg.substring('template:'.length));
      } else if (arg != null && arg.isNotEmpty) {
        final ok = await prov.loadFile(File(arg));
        if (!ok && mounted) {
          final l = AppLocalizations.of(context)!;
          showExceliaSnackBar(context,
            message: l.spreadsheetOpenError,
            isError: true,
            actionLabel: l.openInExternalApp,
            onAction: () async {
              final err = await FileUtils.openWithExternalApp(arg);
              if (err != null && mounted) {
                showExceliaSnackBar(context,
                  message: err.toLowerCase().contains('no app')
                      ? l.externalAppError
                      : l.externalAppOpenFailed(err),
                  isError: true);
              }
            },
          );
        }
      } else {
        prov.createNew();
      }
    });
  }

  void _onProviderChanged() {
    _scheduleAutoSave();
  }

  void _scheduleAutoSave() {
    _autoSaveTimer?.cancel();
    final provider = _spreadsheetProvider;
    if (provider == null || !provider.isModified || provider.filePath == null) return;
    final appProv = context.read<AppProvider>();
    if (!appProv.autoSaveEnabled) return;
    _autoSaveTimer = Timer(const Duration(seconds: 30), () async {
      if (!mounted) return;
      final p = _spreadsheetProvider;
      if (p == null || !p.isModified || p.filePath == null) return;
      try {
        await p.saveFile();
      } catch (e) {
        debugPrint('Spreadsheet auto-save failed: $e');
      }
    });
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _spreadsheetProvider?.removeListener(_onProviderChanged);
    _findCtrl.dispose();
    _replaceCtrl.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    final l = AppLocalizations.of(context)!;
    final prov = context.read<SpreadsheetProvider>();
    if (!prov.isModified) return true;
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.commonUnsavedChanges),
        content: Text(l.spreadsheetSaveChanges),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 0), // 취소
            child: Text(l.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 1), // 저장 안 함
            child: Text(l.commonDoNotSave),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 2), // 저장
            child: Text(l.commonSave),
          ),
        ],
      ),
    );
    if (result == null || result == 0) return false;
    if (result == 2) await prov.saveFile();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (!context.mounted) return;
        if (shouldPop) Navigator.of(context).pop();
      },
      child: Consumer<SpreadsheetProvider>(
        builder: (context, prov, _) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Scaffold(
            backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
            appBar: _buildAppBar(prov),
            body: prov.isLoading
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: AppColors.spreadsheetGreen),
                        const SizedBox(height: 16),
                        Text(l.fileLoading, style: const TextStyle(color: AppColors.grey500)),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      // 찾기 & 바꾸기 바
                      if (_showFindBar) _buildFindBar(prov),
                      // 수식 입력줄
                      const FormulaBar(),
                      // 서식 도구 모음
                      if (_toolbarVisible) const SpreadsheetToolbar(),
                      Divider(height: 1, color: isDark ? AppColors.darkOutline : AppColors.lightOutline),
                      // 스프레드시트 그리드
                      const Expanded(child: SpreadsheetGrid()),
                      // 하단 액션 바 (undo/redo/search/toolbar)
                      _buildBottomActionBar(prov),
                      // 시트 탭 + 상태 표시줄
                      SafeArea(
                        top: false,
                        left: false,
                        right: false,
                        child: _buildBottomBar(prov),
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(SpreadsheetProvider prov) {
    final l = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppBar(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      foregroundColor: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
      elevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(2),
        child: Container(color: AppColors.spreadsheetGreen, height: 2),
      ),
      titleSpacing: 0,
      title: GestureDetector(
        onTap: () => _showRenameDialog(prov),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                prov.fileName + (prov.isModified ? ' *' : ''),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
      actions: [
        // 저장
        IconButton(
          icon: const Icon(LucideIcons.save, size: 20),
          tooltip: l.commonSave,
          onPressed: () async {
            final path = await prov.saveFile();
            if (path != null && mounted) {
              showExceliaSnackBar(context, message: l.fileSaved);
            }
          },
        ),
        // 더보기 메뉴
        PopupMenuButton<String>(
          icon: const Icon(LucideIcons.moreVertical, size: 20),
          onSelected: (v) => _handleMenu(v, prov),
          itemBuilder: (_) => [
            PopupMenuItem(value: 'save_as', child: Text(l.commonSaveAs)),
            PopupMenuItem(value: 'insert_row', child: Text(l.spreadsheetInsertRow)),
            PopupMenuItem(value: 'delete_row', child: Text(l.spreadsheetDeleteRow)),
            PopupMenuItem(value: 'insert_col', child: Text(l.spreadsheetInsertCol)),
            PopupMenuItem(value: 'delete_col', child: Text(l.spreadsheetDeleteCol)),
            const PopupMenuDivider(),
            PopupMenuItem(value: 'sort_asc', child: Text(l.spreadsheetSortAsc)),
            PopupMenuItem(value: 'sort_desc', child: Text(l.spreadsheetSortDesc)),
            const PopupMenuDivider(),
            if (!prov.hasFrozenPanes)
              PopupMenuItem(value: 'freeze', child: Text(l.freezePanes))
            else
              PopupMenuItem(value: 'unfreeze', child: Text(l.unfreezePanes)),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'auto_filter',
              child: Text(prov.hasAutoFilter
                  ? l.clearAutoFilter
                  : l.autoFilter),
            ),
            PopupMenuItem(
              value: 'cond_format',
              child: Text(l.conditionalFormat),
            ),
            PopupMenuItem(
              value: 'insert_chart',
              child: Text(l.insertChart),
            ),
            PopupMenuItem(
              value: 'pivot_table',
              child: Text(l.pivotTable),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'data_validation',
              child: Text(l.dataValidation),
            ),
            PopupMenuItem(
              value: 'name_manager',
              child: Text(l.nameManager),
            ),
            PopupMenuItem(
              value: 'export_csv',
              child: Text(l.spreadsheetExportCsv),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(value: 'shortcuts', child: Text(l.keyboardShortcuts)),
            const PopupMenuDivider(),
            PopupMenuItem(value: 'print_preview', child: Text(l.spreadsheetPrintPreview)),
            PopupMenuItem(value: 'print', child: Text(l.spreadsheetPrint)),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomActionBar(SpreadsheetProvider prov) {
    final l = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(LucideIcons.undo2, size: 20),
            onPressed: prov.canUndo ? prov.undo : null,
            tooltip: l.commonUndo,
          ),
          IconButton(
            icon: const Icon(LucideIcons.redo2, size: 20),
            onPressed: prov.canRedo ? prov.redo : null,
            tooltip: l.commonRedo,
          ),
          const Spacer(),
          IconButton(
            icon: Icon(LucideIcons.search, size: 20,
              color: _showFindBar ? AppColors.spreadsheetGreen : null),
            onPressed: () => setState(() {
              _showFindBar = !_showFindBar;
              if (!_showFindBar) {
                prov.clearSearch();
                _findCtrl.clear();
                _replaceCtrl.clear();
              }
            }),
            tooltip: l.findTitle,
          ),
          IconButton(
            icon: Icon(
              _toolbarVisible ? LucideIcons.panelTopClose : LucideIcons.panelTop,
              size: 20,
              color: _toolbarVisible ? AppColors.spreadsheetGreen : null,
            ),
            onPressed: () => setState(() => _toolbarVisible = !_toolbarVisible),
            tooltip: l.toolbarFormatTools,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(SpreadsheetProvider prov) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stats = prov.getSelectionStats();
    return Container(
      color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 시트 탭
          const SheetTabBar(),
          // 상태 표시줄
          Container(
            height: 24,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurfaceElevated,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
                  width: isDark ? 0.5 : 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Text(
                  prov.selectedCellAddress,
                  style: TextStyle(
                    color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                ...stats.entries.map((e) => Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Text(
                        '${e.key}: ${e.value}',
                        style: TextStyle(
                          color: isDark ? AppColors.darkOnSurfaceAlt : AppColors.lightOnSurfaceAlt,
                          fontSize: 11,
                        ),
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFindBar(SpreadsheetProvider prov) {
    final l = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final matchText = prov.searchResults.isEmpty
        ? (prov.searchQuery.isNotEmpty ? l.findNoMatch : '')
        : l.findMatchCount(prov.searchIndex + 1, prov.searchResults.length);
    return Container(
      color: isDark ? AppColors.darkSurfaceElevated : AppColors.grey100,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 찾기 행
          Row(
            children: [
              const Icon(LucideIcons.search, size: 18, color: AppColors.grey600),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 32,
                  child: TextField(
                    controller: _findCtrl,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: l.findHint,
                      hintStyle: const TextStyle(fontSize: 13, color: AppColors.grey500),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                      isDense: true,
                    ),
                    onChanged: (v) => prov.findAll(v),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              if (matchText.isNotEmpty)
                Text(matchText, style: const TextStyle(fontSize: 11, color: AppColors.grey600)),
              IconButton(
                icon: const Icon(LucideIcons.chevronUp, size: 18),
                onPressed: prov.findPrev,
                tooltip: l.findTitle,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              IconButton(
                icon: const Icon(LucideIcons.chevronDown, size: 18),
                onPressed: prov.findNext,
                tooltip: l.findTitle,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              IconButton(
                icon: const Icon(LucideIcons.x, size: 18),
                onPressed: () => setState(() {
                  _showFindBar = false;
                  prov.clearSearch();
                  _findCtrl.clear();
                  _replaceCtrl.clear();
                }),
                tooltip: l.commonClose,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // 바꾸기 행
          Row(
            children: [
              const Icon(LucideIcons.replace, size: 18, color: AppColors.grey600),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 32,
                  child: TextField(
                    controller: _replaceCtrl,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: l.replaceHint,
                      hintStyle: const TextStyle(fontSize: 13, color: AppColors.grey500),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                      isDense: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              TextButton(
                onPressed: () => prov.replaceOne(_findCtrl.text, _replaceCtrl.text),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 32),
                ),
                child: Text(l.replaceOne, style: const TextStyle(fontSize: 12)),
              ),
              TextButton(
                onPressed: () => prov.replaceAllMatches(_findCtrl.text, _replaceCtrl.text),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 32),
                ),
                child: Text(l.replaceAllBtn, style: const TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleMenu(String action, SpreadsheetProvider prov) {
    switch (action) {
      case 'save_as':
        prov.saveAs();
      case 'insert_row':
        prov.insertRow(prov.selectedRow);
      case 'delete_row':
        prov.deleteRow(prov.selectedRow);
      case 'insert_col':
        prov.insertColumn(prov.selectedCol);
      case 'delete_col':
        prov.deleteColumn(prov.selectedCol);
      case 'sort_asc':
        prov.sortColumn(prov.selectedCol, true);
      case 'sort_desc':
        prov.sortColumn(prov.selectedCol, false);
      case 'freeze':
        prov.freezeAtCurrentCell();
      case 'unfreeze':
        prov.unfreeze();
      case 'print_preview':
        _showPrintPreview(prov);
      case 'print':
        _printSpreadsheet(prov);
      case 'auto_filter':
        prov.toggleAutoFilter();
      case 'cond_format':
        _showConditionalFormatDialog(prov);
      case 'insert_chart':
        _showInsertChartDialog(prov);
      case 'pivot_table':
        showDialog(
            context: context,
            builder: (ctx) => const PivotTableDialog());
      case 'data_validation':
        _showDataValidationDialog();
      case 'name_manager':
        _showNameManagerDialog();
      case 'export_csv':
        _exportCsv(prov);
      case 'shortcuts':
        showKeyboardShortcutsDialog(context, 'spreadsheet');
    }
  }

  void _showDataValidationDialog() {
    showDialog(
      context: context,
      builder: (ctx) => const DataValidationDialog(),
    );
  }

  void _showNameManagerDialog() {
    showDialog(
      context: context,
      builder: (ctx) => const NameManagerDialog(),
    );
  }

  void _exportCsv(SpreadsheetProvider prov) async {
    final csv = prov.exportCsv();
    if (csv.isEmpty) return;
    final l = AppLocalizations.of(context)!;
    try {
      String? result;
      try {
        result = await FilePicker.platform.saveFile(
          dialogTitle: l.spreadsheetExportCsv,
          fileName: '${prov.fileName.replaceAll(RegExp(r'\.[^.]+$'), '')}.csv',
          type: FileType.custom,
          allowedExtensions: ['csv'],
          bytes: Uint8List.fromList(csv.codeUnits),
        );
      } catch (e) {
        debugPrint('CSV saveFile picker failed: $e');
      }
      // Fallback for mobile platforms
      if (result == null && (Platform.isAndroid || Platform.isIOS)) {
        final dir = await getApplicationDocumentsDirectory();
        final csvName =
            '${prov.fileName.replaceAll(RegExp(r'\.[^.]+$'), '')}.csv';
        result = '${dir.path}${Platform.pathSeparator}$csvName';
      }
      if (result != null) {
        final file = File(result);
        await file.writeAsString(csv);
      }
    } catch (e) {
      debugPrint('CSV export failed: $e');
    }
  }

  // ══════════════════════ 조건부 서식 다이얼로그 ══════════════════════

  void _showConditionalFormatDialog(SpreadsheetProvider prov) {
    final l = AppLocalizations.of(context)!;
    ConditionType selectedType = ConditionType.greaterThan;
    final value1Ctrl = TextEditingController();
    final value2Ctrl = TextEditingController();
    Color selectedBg = AppColors.error.withValues(alpha: 0.2);
    Color selectedText = AppColors.error;

    final r0 = prov.hasRange
        ? min(prov.selStartRow, prov.selEndRow)
        : prov.selectedRow;
    final r1 = prov.hasRange
        ? max(prov.selStartRow, prov.selEndRow)
        : prov.selectedRow;
    final c0 = prov.hasRange
        ? min(prov.selStartCol, prov.selEndCol)
        : prov.selectedCol;
    final c1 = prov.hasRange
        ? max(prov.selStartCol, prov.selEndCol)
        : prov.selectedCol;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l.conditionalFormat),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 조건 타입 선택
                DropdownButtonFormField<ConditionType>(
                  initialValue: selectedType,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l.conditionType,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: ConditionType.greaterThan,
                      child: Text(l.condGreaterThan),
                    ),
                    DropdownMenuItem(
                      value: ConditionType.lessThan,
                      child: Text(l.condLessThan),
                    ),
                    DropdownMenuItem(
                      value: ConditionType.equalTo,
                      child: Text(l.condEqualTo),
                    ),
                    DropdownMenuItem(
                      value: ConditionType.between,
                      child: Text(l.condBetween),
                    ),
                    DropdownMenuItem(
                      value: ConditionType.textContains,
                      child: Text(l.condTextContains),
                    ),
                    DropdownMenuItem(
                      value: ConditionType.isEmpty,
                      child: Text(l.condIsEmpty),
                    ),
                    DropdownMenuItem(
                      value: ConditionType.isNotEmpty,
                      child: Text(l.condIsNotEmpty),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      setDialogState(() => selectedType = v);
                    }
                  },
                ),
                const SizedBox(height: 12),
                // 값 입력
                if (selectedType != ConditionType.isEmpty &&
                    selectedType != ConditionType.isNotEmpty) ...[
                  TextField(
                    controller: value1Ctrl,
                    decoration: InputDecoration(
                      labelText: l.condValue,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  if (selectedType == ConditionType.between) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: value2Ctrl,
                      decoration: InputDecoration(
                        labelText: l.condValue2,
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 16),
                // 서식 프리셋
                Text(l.condFormatStyle,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _condPresetChip(
                      ctx,
                      AppColors.error.withValues(alpha: 0.15),
                      AppColors.error,
                      selectedBg == AppColors.error.withValues(alpha: 0.15),
                      () => setDialogState(() {
                        selectedBg =
                            AppColors.error.withValues(alpha: 0.15);
                        selectedText = AppColors.error;
                      }),
                    ),
                    _condPresetChip(
                      ctx,
                      AppColors.warning.withValues(alpha: 0.15),
                      AppColors.warning,
                      selectedBg ==
                          AppColors.warning.withValues(alpha: 0.15),
                      () => setDialogState(() {
                        selectedBg =
                            AppColors.warning.withValues(alpha: 0.15);
                        selectedText = AppColors.warning;
                      }),
                    ),
                    _condPresetChip(
                      ctx,
                      AppColors.success.withValues(alpha: 0.15),
                      AppColors.success,
                      selectedBg ==
                          AppColors.success.withValues(alpha: 0.15),
                      () => setDialogState(() {
                        selectedBg =
                            AppColors.success.withValues(alpha: 0.15);
                        selectedText = AppColors.success;
                      }),
                    ),
                    _condPresetChip(
                      ctx,
                      AppColors.info.withValues(alpha: 0.15),
                      AppColors.info,
                      selectedBg == AppColors.info.withValues(alpha: 0.15),
                      () => setDialogState(() {
                        selectedBg =
                            AppColors.info.withValues(alpha: 0.15);
                        selectedText = AppColors.info;
                      }),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            // 기존 규칙 초기화
            if (prov.condRules.isNotEmpty)
              TextButton(
                onPressed: () {
                  prov.clearConditionalFormats();
                  Navigator.pop(ctx);
                },
                child: Text(l.condClearAll),
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l.commonCancel),
            ),
            FilledButton(
              onPressed: () {
                prov.addConditionalFormat(ConditionalFormatRule(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  type: selectedType,
                  value1: value1Ctrl.text,
                  value2: value2Ctrl.text,
                  bgColor: selectedBg,
                  textColor: selectedText,
                  startRow: r0,
                  startCol: c0,
                  endRow: r1,
                  endCol: c1,
                ));
                Navigator.pop(ctx);
              },
              child: Text(l.condApply),
            ),
          ],
        ),
      ),
    );
  }

  Widget _condPresetChip(BuildContext ctx, Color bg, Color text,
      bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 32,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? text : AppColors.grey300,
            width: isSelected ? 2 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          'Aa',
          style: TextStyle(
            color: text,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  // ══════════════════════ 차트 삽입 ══════════════════════

  void _showInsertChartDialog(SpreadsheetProvider prov) {
    final l = AppLocalizations.of(context)!;
    ChartType selectedType = ChartType.bar;
    final titleCtrl = TextEditingController(text: l.chartDefaultTitle);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l.insertChart),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 차트 타입 선택
              DropdownButtonFormField<ChartType>(
                initialValue: selectedType,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l.chartType,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  DropdownMenuItem(
                    value: ChartType.bar,
                    child: Text(l.chartBar),
                  ),
                  DropdownMenuItem(
                    value: ChartType.line,
                    child: Text(l.chartLine),
                  ),
                  DropdownMenuItem(
                    value: ChartType.pie,
                    child: Text(l.chartPie),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) {
                    setDialogState(() => selectedType = v);
                  }
                },
              ),
              const SizedBox(height: 12),
              // 제목
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(
                  labelText: l.chartTitle,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              // 데이터 범위 안내
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(ctx).brightness == Brightness.dark
                      ? AppColors.darkSurfaceElevated
                      : AppColors.grey100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        size: 16, color: AppColors.grey600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l.chartDataHint,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.grey600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l.commonCancel),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                final (labels, values) = prov.extractChartData();
                if (values.isEmpty) return;
                final chartData = ChartData(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  type: selectedType,
                  title: titleCtrl.text.trim().isEmpty
                      ? l.chartDefaultTitle
                      : titleCtrl.text.trim(),
                  labels: labels,
                  values: values,
                );
                // 차트 데이터 저장
                prov.addChart({
                  'id': chartData.id,
                  'type': selectedType.name,
                  'title': chartData.title,
                  'labels': labels,
                  'values': values,
                });
                // 차트 뷰어 열기
                showDialog(
                  context: context,
                  builder: (_) => ChartViewerDialog(data: chartData),
                );
              },
              child: Text(l.chartCreate),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════ PDF / 인쇄 ══════════════════════

  pw.Font? _krFont;

  Future<void> _ensureFont() async {
    if (_krFont != null) return;
    final fd = await rootBundle.load('assets/fonts/NotoSansKR.ttf');
    _krFont = pw.Font.ttf(fd);
  }

  /// Flutter Color -> pdf PdfColor (0-1 범위 RGBA)
  PdfColor _toPdfColor(Color c) => PdfColor(c.r, c.g, c.b, c.a);

  /// 데이터가 존재하는 최대 (row, col) 범위 계산
  (int, int) _calcDataRange(SpreadsheetProvider prov) {
    int maxRow = -1, maxCol = -1;
    for (final key in prov.currentCellData.keys) {
      final p = prov.parseCellReference(key);
      if (p != null) {
        maxRow = max(maxRow, p.$1);
        maxCol = max(maxCol, p.$2);
      }
    }
    for (final key in prov.currentCellFormats.keys) {
      final p = prov.parseCellReference(key);
      if (p != null) {
        maxRow = max(maxRow, p.$1);
        maxCol = max(maxCol, p.$2);
      }
    }
    for (final c in prov.columnWidths.keys) {
      maxCol = max(maxCol, c);
    }
    for (final r in prov.rowHeights.keys) {
      maxRow = max(maxRow, r);
    }
    for (final m in prov.mergedCells) {
      maxRow = max(maxRow, m.$3);
      maxCol = max(maxCol, m.$4);
    }
    return (maxRow, maxCol);
  }

  /// CellFormat.alignment -> pw.TextAlign 변환
  pw.TextAlign _toPwTextAlign(CellFormat? fmt) {
    if (fmt == null) return pw.TextAlign.left;
    switch (fmt.alignment) {
      case TextAlign.center:
        return pw.TextAlign.center;
      case TextAlign.right:
      case TextAlign.end:
        return pw.TextAlign.right;
      default:
        return pw.TextAlign.left;
    }
  }

  /// CellFormat.alignment -> pw.Alignment 변환 (수직 중앙 고정)
  pw.Alignment _toPwCellAlign(CellFormat? fmt) {
    if (fmt == null) return pw.Alignment.centerLeft;
    switch (fmt.alignment) {
      case TextAlign.center:
        return pw.Alignment.center;
      case TextAlign.right:
      case TextAlign.end:
        return pw.Alignment.centerRight;
      default:
        return pw.Alignment.centerLeft;
    }
  }

  /// 셀 하나의 그려야 할 실제 너비/높이 계산 (병합 셀 반영)
  /// 반환: (cellWidth, cellHeight) -- 이미 scale 적용됨
  (double, double) _calcCellSize({
    required int row,
    required int col,
    required (int, int, int, int)? merge,
    required int maxRow,
    required int maxCol,
    required List<double> colWidths,
    required List<double> rowHeights,
    required double scale,
  }) {
    if (merge != null && merge.$1 == row && merge.$2 == col) {
      double w = 0;
      for (int mc = merge.$2; mc <= min(merge.$4, maxCol); mc++) {
        w += colWidths[mc];
      }
      double h = 0;
      for (int mr = merge.$1; mr <= min(merge.$3, maxRow); mr++) {
        h += rowHeights[mr];
      }
      return (w * scale, h * scale);
    }
    return (colWidths[col] * scale, rowHeights[row] * scale);
  }

  Future<pw.Document> _buildPdf(SpreadsheetProvider prov, PrintSetup setup) async {
    final l = AppLocalizations.of(context)!;
    await _ensureFont();
    final pdf = pw.Document();
    final font = _krFont!;

    final pdfTheme = pw.ThemeData.withFont(
      base: font,
      bold: font,
      italic: font,
      boldItalic: font,
    );

    final (maxRow, maxCol) = _calcDataRange(prov);

    final pageFormat = setup.pageFormat;

    if (maxRow < 0 || maxCol < 0) {
      pdf.addPage(pw.Page(
        pageFormat: pageFormat,
        theme: pdfTheme,
        build: (_) => pw.Center(child: pw.Text(l.spreadsheetNoData)),
      ));
      return pdf;
    }

    // -- 열/행 크기 목록 --
    final colWidths = List.generate(maxCol + 1, (c) => prov.getColumnWidth(c));
    final rowHeights = List.generate(maxRow + 1, (r) => prov.getRowHeight(r));
    final totalDataW = colWidths.fold<double>(0, (a, b) => a + b);
    final totalDataH = rowHeights.fold<double>(0, (a, b) => a + b);

    // -- 페이지 레이아웃 (PrintSetup 반영) --
    final pdfMargin = setup.marginValue;
    final showHeader = setup.showFileName || setup.showPageNumbers;
    final headerHeight = showHeader ? 16.0 : 0.0;
    final headerGap = showHeader ? 8.0 : 0.0;
    final pageW = pageFormat.width - pdfMargin * 2;
    final pageH = pageFormat.height - pdfMargin * 2 - headerHeight - headerGap;

    // -- 배율 계산 (scaleMode 반영) --
    double scale;
    switch (setup.scaleMode) {
      case ScaleMode.fitPage:
        final scaleW = totalDataW > pageW ? pageW / totalDataW : 1.0;
        final scaleH = totalDataH > pageH ? pageH / totalDataH : 1.0;
        scale = min(scaleW, scaleH);
      case ScaleMode.actual:
        scale = 1.0;
      case ScaleMode.fitWidth:
        scale = totalDataW > pageW ? pageW / totalDataW : 1.0;
    }
    final scaledTotalW = totalDataW * scale;

    // -- 셀 내 여백 (scale 비례) --
    final cellPadH = max(4.0 * scale, 2.0);
    final cellPadV = max(2.0 * scale, 1.0);

    // -- 기본 폰트 크기 --
    const baseFontSize = 10.0;

    // -- 병합 셀 숨김 룩업 (String 키로 충돌 방지) --
    final Set<String> mergeHidden = {};
    for (final m in prov.mergedCells) {
      for (int r = m.$1; r <= m.$3; r++) {
        for (int c = m.$2; c <= m.$4; c++) {
          if (r != m.$1 || c != m.$2) mergeHidden.add('$r,$c');
        }
      }
    }

    // -- 행 기준 페이지 분할 --
    final List<(int, int)> pageRows = [];
    double accH = 0;
    int startRow = 0;
    for (int r = 0; r <= maxRow; r++) {
      final rh = rowHeights[r] * scale;
      if (accH + rh > pageH && r > startRow) {
        pageRows.add((startRow, r - 1));
        startRow = r;
        accH = rh;
      } else {
        accH += rh;
      }
    }
    pageRows.add((startRow, maxRow));

    // -- 셀 서식 캐시 --
    final cellFormats = prov.currentCellFormats;

    // 테두리 색/굵기
    const borderColor = PdfColors.grey400;
    const borderWidth = 0.5;

    for (int pageIdx = 0; pageIdx < pageRows.length; pageIdx++) {
      final (pgStart, pgEnd) = pageRows[pageIdx];

      pdf.addPage(pw.Page(
        pageFormat: pageFormat,
        margin: pw.EdgeInsets.all(pdfMargin),
        theme: pdfTheme,
        build: (pw.Context ctx) {
          final children = <pw.Widget>[];
          double y = 0;

          for (int r = pgStart; r <= pgEnd; r++) {
            final rh = rowHeights[r] * scale;
            double x = 0;

            for (int c = 0; c <= maxCol; c++) {
              final cw = colWidths[c] * scale;

              // 병합 영역의 숨겨진 셀은 건너뜀
              if (mergeHidden.contains('$r,$c')) {
                x += cw;
                continue;
              }

              // 병합 셀 크기 계산
              final merge = prov.getMergeForCell(r, c);
              final (cellW, cellH) = _calcCellSize(
                row: r,
                col: c,
                merge: merge,
                maxRow: maxRow,
                maxCol: maxCol,
                colWidths: colWidths,
                rowHeights: rowHeights,
                scale: scale,
              );

              // 병합 셀이 현재 페이지를 넘어가면 높이를 페이지에 맞게 클리핑
              final maxAvailH = pageH - y;
              final clippedH = min(cellH, maxAvailH);

              final cellKey = '${prov.getColumnName(c)}${r + 1}';
              final fmt = cellFormats[cellKey];
              final display = prov.getCellDisplay(r, c);

              // 셀 배경색
              PdfColor? bgColor;
              if (fmt?.backgroundColor != null) {
                bgColor = _toPdfColor(fmt!.backgroundColor!);
              }

              // 텍스트 위젯
              pw.Widget? textWidget;
              if (display.isNotEmpty) {
                double fontSize = baseFontSize * scale;
                if (fmt?.fontSize != null && fmt!.fontSize! > 0) {
                  fontSize = fmt.fontSize!.toDouble() * scale;
                }
                fontSize = max(fontSize, 4.0);

                PdfColor textColor = PdfColors.black;
                if (fmt?.textColor != null) {
                  textColor = _toPdfColor(fmt!.textColor!);
                }

                // pw.TextDecoration
                pw.TextDecoration textDeco = pw.TextDecoration.none;
                if (fmt?.underline == true) {
                  textDeco = pw.TextDecoration.underline;
                }

                // fontStyle: italic 지원
                final fontStyle = fmt?.italic == true
                    ? pw.FontStyle.italic
                    : pw.FontStyle.normal;
                final fontWeight = fmt?.bold == true
                    ? pw.FontWeight.bold
                    : pw.FontWeight.normal;

                textWidget = pw.Text(
                  display,
                  style: pw.TextStyle(
                    font: font,
                    fontBold: font,
                    fontItalic: font,
                    fontBoldItalic: font,
                    fontSize: fontSize,
                    color: textColor,
                    fontWeight: fontWeight,
                    fontStyle: fontStyle,
                    decoration: textDeco,
                  ),
                  textAlign: _toPwTextAlign(fmt),
                  maxLines: fmt?.wrapText == true ? null : 1,
                  overflow: pw.TextOverflow.clip,
                );
              }

              // 테두리 -- setup.showGridlines에 따라 조건부 렌더링
              final pw.Border? border;
              if (setup.showGridlines) {
                border = pw.Border(
                  top: r == pgStart
                      ? const pw.BorderSide(
                          color: borderColor, width: borderWidth)
                      : pw.BorderSide.none,
                  left: c == 0
                      ? const pw.BorderSide(
                          color: borderColor, width: borderWidth)
                      : pw.BorderSide.none,
                  right: const pw.BorderSide(
                      color: borderColor, width: borderWidth),
                  bottom: const pw.BorderSide(
                      color: borderColor, width: borderWidth),
                );
              } else {
                border = null;
              }

              children.add(pw.Positioned(
                left: x,
                top: y,
                child: pw.SizedBox(
                  width: cellW,
                  height: clippedH,
                  child: pw.Container(
                    padding: pw.EdgeInsets.symmetric(
                      horizontal: cellPadH,
                      vertical: cellPadV,
                    ),
                    alignment: _toPwCellAlign(fmt),
                    decoration: pw.BoxDecoration(
                      color: bgColor,
                      border: border,
                    ),
                    child: textWidget != null
                        ? pw.ClipRect(child: textWidget)
                        : null,
                  ),
                ),
              ));

              x += cw;
            }
            y += rh;
          }

          // 페이지 헤더: 파일명 + 페이지 번호 (setup 옵션에 따라)
          final headerStyle = pw.TextStyle(
            font: font,
            fontSize: 8,
            color: PdfColors.grey600,
          );
          final headerChildren = <pw.Widget>[];
          if (setup.showFileName) {
            headerChildren.add(pw.Text(prov.fileName, style: headerStyle));
          } else {
            headerChildren.add(pw.SizedBox.shrink());
          }
          if (setup.showPageNumbers) {
            headerChildren.add(
              pw.Text('${pageIdx + 1} / ${pageRows.length}', style: headerStyle),
            );
          }

          final columnChildren = <pw.Widget>[];
          if (showHeader && headerChildren.isNotEmpty) {
            columnChildren.add(pw.Container(
              width: scaledTotalW,
              height: headerHeight,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: headerChildren,
              ),
            ));
            columnChildren.add(pw.SizedBox(height: headerGap));
          }
          columnChildren.add(pw.SizedBox(
            width: pageW,
            height: pageH,
            child: pw.Stack(children: children),
          ));

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: columnChildren,
          );
        },
      ));
    }

    return pdf;
  }

  void _showPrintPreview(SpreadsheetProvider prov) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _PrintPreviewScreen(
          prov: prov,
          buildPdf: _buildPdf,
          ensureFont: _ensureFont,
        ),
      ),
    );
  }

  Future<void> _printSpreadsheet(SpreadsheetProvider prov) async {
    final pdf = await _buildPdf(prov, const PrintSetup());
    final pdfBytes = await pdf.save();
    await Printing.layoutPdf(
      onLayout: (_) async => pdfBytes,
      name: prov.fileName,
    );
  }

  void _showRenameDialog(SpreadsheetProvider prov) {
    prov.saveAs();
  }
}

// ═══════════════════════════════════════════════════════════════
// 인쇄 미리보기 화면 — 페이지 설정 반영 + 실시간 PDF 재생성
// ═══════════════════════════════════════════════════════════════

class _PrintPreviewScreen extends StatefulWidget {
  final SpreadsheetProvider prov;
  final Future<pw.Document> Function(SpreadsheetProvider, PrintSetup) buildPdf;
  final Future<void> Function() ensureFont;

  const _PrintPreviewScreen({
    required this.prov,
    required this.buildPdf,
    required this.ensureFont,
  });

  @override
  State<_PrintPreviewScreen> createState() => _PrintPreviewScreenState();
}

class _PrintPreviewScreenState extends State<_PrintPreviewScreen> {
  PrintSetup _setup = const PrintSetup();
  Uint8List? _pdfBytes;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _regeneratePdf();
  }

  Future<void> _regeneratePdf() async {
    setState(() => _loading = true);
    final pdf = await widget.buildPdf(widget.prov, _setup);
    final bytes = await pdf.save();
    if (mounted) {
      setState(() {
        _pdfBytes = bytes;
        _loading = false;
      });
    }
  }

  void _openPageSetup() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final dl = AppLocalizations.of(ctx)!;
        return _PageSetupSheet(
          setup: _setup,
          l: dl,
          onApply: (newSetup) {
            Navigator.pop(ctx);
            setState(() => _setup = newSetup);
            _regeneratePdf();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.spreadsheetPrintPreviewTitle(widget.prov.fileName)),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.settings, size: 20),
            tooltip: l.pageSetupTitle,
            onPressed: _openPageSetup,
          ),
        ],
      ),
      body: _loading || _pdfBytes == null
          ? const Center(child: CircularProgressIndicator())
          : PdfPreview(
              build: (_) async => _pdfBytes!,
              canChangeOrientation: false,
              canChangePageFormat: false,
              canDebug: false,
            ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 페이지 설정 바텀시트
// ═══════════════════════════════════════════════════════════════

class _PageSetupSheet extends StatefulWidget {
  final PrintSetup setup;
  final AppLocalizations l;
  final ValueChanged<PrintSetup> onApply;

  const _PageSetupSheet({
    required this.setup,
    required this.l,
    required this.onApply,
  });

  @override
  State<_PageSetupSheet> createState() => _PageSetupSheetState();
}

class _PageSetupSheetState extends State<_PageSetupSheet> {
  late PrintSetup _draft;

  @override
  void initState() {
    super.initState();
    _draft = widget.setup;
  }

  String _paperLabel(PaperSize key) {
    switch (key) {
      case PaperSize.a4: return widget.l.paperSizeA4;
      case PaperSize.a5: return widget.l.paperSizeA5;
      case PaperSize.letter: return widget.l.paperSizeLetter;
      case PaperSize.legal: return widget.l.paperSizeLegal;
    }
  }

  String _marginLabel(MarginPreset key) {
    switch (key) {
      case MarginPreset.normal: return widget.l.marginNormal;
      case MarginPreset.narrow: return widget.l.marginNarrow;
      case MarginPreset.wide: return widget.l.marginWide;
    }
  }

  String _scaleLabel(ScaleMode key) {
    switch (key) {
      case ScaleMode.fitWidth: return widget.l.scaleFitWidth;
      case ScaleMode.fitPage: return widget.l.scaleFitPage;
      case ScaleMode.actual: return widget.l.scaleActual;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.l;
    final bottomPad = MediaQuery.of(context).viewInsets.bottom
        + MediaQuery.of(context).viewPadding.bottom + 16;

    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24, bottom: bottomPad,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 타이틀
            Center(
              child: Text(
                l.pageSetupTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 24),

            // ── 용지 크기 ──
            Text(l.paperSize, style: const TextStyle(
              fontWeight: FontWeight.w600, color: AppColors.grey800)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: PrintSetup.paperSizes.map((s) => ChoiceChip(
                label: Text(_paperLabel(s)),
                selected: _draft.paperSize == s,
                onSelected: (_) =>
                    setState(() => _draft = _draft.copyWith(paperSize: s)),
              )).toList(),
            ),
            const SizedBox(height: 16),

            // ── 방향 ──
            Text(l.orientationLabel, style: const TextStyle(
              fontWeight: FontWeight.w600, color: AppColors.grey800)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: Text(l.orientationLandscape),
                  selected: _draft.isLandscape,
                  onSelected: (_) =>
                      setState(() => _draft = _draft.copyWith(isLandscape: true)),
                ),
                ChoiceChip(
                  label: Text(l.orientationPortrait),
                  selected: !_draft.isLandscape,
                  onSelected: (_) =>
                      setState(() => _draft = _draft.copyWith(isLandscape: false)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── 여백 ──
            Text(l.marginsLabel, style: const TextStyle(
              fontWeight: FontWeight.w600, color: AppColors.grey800)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: PrintSetup.marginPresets.map((m) => ChoiceChip(
                label: Text(_marginLabel(m)),
                selected: _draft.marginPreset == m,
                onSelected: (_) =>
                    setState(() => _draft = _draft.copyWith(marginPreset: m)),
              )).toList(),
            ),
            const SizedBox(height: 16),

            // ── 배율 ──
            Text(l.scaleLabel, style: const TextStyle(
              fontWeight: FontWeight.w600, color: AppColors.grey800)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: PrintSetup.scaleModes.map((s) => ChoiceChip(
                label: Text(_scaleLabel(s)),
                selected: _draft.scaleMode == s,
                onSelected: (_) =>
                    setState(() => _draft = _draft.copyWith(scaleMode: s)),
              )).toList(),
            ),
            const SizedBox(height: 16),

            // ── 토글 옵션 ──
            const Divider(),
            SwitchListTile(
              title: Text(l.showGridlines),
              value: _draft.showGridlines,
              onChanged: (v) =>
                  setState(() => _draft = _draft.copyWith(showGridlines: v)),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: Text(l.showFileName),
              value: _draft.showFileName,
              onChanged: (v) =>
                  setState(() => _draft = _draft.copyWith(showFileName: v)),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: Text(l.showPageNumbers),
              value: _draft.showPageNumbers,
              onChanged: (v) =>
                  setState(() => _draft = _draft.copyWith(showPageNumbers: v)),
              contentPadding: EdgeInsets.zero,
            ),

            const SizedBox(height: 16),

            // ── 적용 버튼 ──
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () => widget.onApply(_draft),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.spreadsheetGreen,
                ),
                child: Text(l.pageSetupApply),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
