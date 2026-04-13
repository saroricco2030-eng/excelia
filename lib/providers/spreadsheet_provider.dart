import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' hide Column, Row, Border, Stack, DataValidation;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:excelia/utils/constants.dart';
import 'package:excelia/utils/xlsx_fallback_parser.dart';
import 'package:excelia/utils/formula_engine.dart';
import 'package:excelia/models/data_validation.dart';
import 'package:excelia/models/pivot_table.dart';

/// 셀 테두리 프리셋
enum BorderPreset { none, all, outside, bottom, top, leftRight }

/// 셀 테두리 데이터
class CellBorders {
  final bool top, bottom, left, right;
  final Color color;

  const CellBorders({
    this.top = false,
    this.bottom = false,
    this.left = false,
    this.right = false,
    this.color = AppColors.black,
  });

  const CellBorders.none()
      : top = false, bottom = false, left = false, right = false,
        color = AppColors.black;

  const CellBorders.all()
      : top = true, bottom = true, left = true, right = true,
        color = AppColors.black;

  const CellBorders.outside()
      : top = true, bottom = true, left = true, right = true,
        color = AppColors.black;

  bool get hasAny => top || bottom || left || right;

  CellBorders copyWith({bool? top, bool? bottom, bool? left, bool? right, Color? color}) =>
      CellBorders(
        top: top ?? this.top,
        bottom: bottom ?? this.bottom,
        left: left ?? this.left,
        right: right ?? this.right,
        color: color ?? this.color,
      );
}

/// 셀 서식 데이터
class CellFormat {
  bool bold;
  bool italic;
  bool underline;
  Color? textColor;
  Color? backgroundColor;
  TextAlign alignment;
  String numberFormat;
  bool wrapText;
  int? fontSize;
  String? fontFamily;
  CellBorders? borders;

  CellFormat({
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.textColor,
    this.backgroundColor,
    this.alignment = TextAlign.left,
    this.numberFormat = 'general',
    this.wrapText = false,
    this.fontSize,
    this.fontFamily,
    this.borders,
  });

  CellFormat copy() => CellFormat(
        bold: bold,
        italic: italic,
        underline: underline,
        textColor: textColor,
        backgroundColor: backgroundColor,
        alignment: alignment,
        numberFormat: numberFormat,
        wrapText: wrapText,
        fontSize: fontSize,
        fontFamily: fontFamily,
        borders: borders,
      );

  bool get hasStyle => bold || italic || underline ||
      textColor != null || backgroundColor != null ||
      alignment != TextAlign.left || numberFormat != 'general' ||
      wrapText || fontSize != null || fontFamily != null ||
      (borders != null && borders!.hasAny);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CellFormat &&
          bold == other.bold &&
          italic == other.italic &&
          underline == other.underline &&
          textColor == other.textColor &&
          backgroundColor == other.backgroundColor &&
          alignment == other.alignment &&
          numberFormat == other.numberFormat &&
          wrapText == other.wrapText &&
          fontSize == other.fontSize &&
          fontFamily == other.fontFamily;

  @override
  int get hashCode => Object.hash(
        bold, italic, underline, textColor, backgroundColor,
        alignment, numberFormat, wrapText, fontSize, fontFamily,
      );
}

/// 조건부 서식 규칙
enum ConditionType {
  greaterThan,
  lessThan,
  equalTo,
  between,
  textContains,
  isEmpty,
  isNotEmpty,
}

class ConditionalFormatRule {
  final String id;
  final ConditionType type;
  final String value1;
  final String value2; // between 용
  final Color? bgColor;
  final Color? textColor;
  final bool bold;
  final int startRow, startCol, endRow, endCol;

  ConditionalFormatRule({
    required this.id,
    required this.type,
    required this.value1,
    this.value2 = '',
    this.bgColor,
    this.textColor,
    this.bold = false,
    required this.startRow,
    required this.startCol,
    required this.endRow,
    required this.endCol,
  });

  /// 셀 값에 이 규칙이 적용되는지 확인
  bool matches(dynamic cellValue) {
    final s = cellValue?.toString() ?? '';
    switch (type) {
      case ConditionType.isEmpty:
        return s.isEmpty;
      case ConditionType.isNotEmpty:
        return s.isNotEmpty;
      case ConditionType.textContains:
        return s.toLowerCase().contains(value1.toLowerCase());
      case ConditionType.equalTo:
        final n = num.tryParse(s);
        final v = num.tryParse(value1);
        if (n != null && v != null) return n == v;
        return s == value1;
      case ConditionType.greaterThan:
        final n = num.tryParse(s);
        final v = num.tryParse(value1);
        return n != null && v != null && n > v;
      case ConditionType.lessThan:
        final n = num.tryParse(s);
        final v = num.tryParse(value1);
        return n != null && v != null && n < v;
      case ConditionType.between:
        final n = num.tryParse(s);
        final lo = num.tryParse(value1);
        final hi = num.tryParse(value2);
        return n != null && lo != null && hi != null && n >= lo && n <= hi;
    }
  }

  bool containsCell(int row, int col) =>
      row >= startRow && row <= endRow && col >= startCol && col <= endCol;
}

/// 셀 메모/댓글
class CellComment {
  final String text;
  final DateTime createdAt;

  CellComment({required this.text, DateTime? createdAt})
      : createdAt = createdAt ?? DateTime.now();
}

/// 자동 필터 상태
class AutoFilterState {
  final int headerRow; // 필터 헤더 행
  final int startCol;
  final int endCol;
  final Map<int, Set<String>> activeFilters; // col → 표시할 값 집합

  AutoFilterState({
    required this.headerRow,
    required this.startCol,
    required this.endCol,
    Map<int, Set<String>>? activeFilters,
  }) : activeFilters = activeFilters ?? {};

  bool isRowVisible(int row, Map<String, dynamic> cellData,
      String Function(int) getColName) {
    if (row <= headerRow) return true; // 헤더 행은 항상 표시
    for (final entry in activeFilters.entries) {
      final col = entry.key;
      final allowed = entry.value;
      if (allowed.isEmpty) continue; // 빈 필터는 스킵
      final key = '${getColName(col)}${row + 1}';
      final val = cellData[key]?.toString() ?? '';
      if (!allowed.contains(val)) return false;
    }
    return true;
  }

  AutoFilterState copyWith({Map<int, Set<String>>? activeFilters}) =>
      AutoFilterState(
        headerRow: headerRow,
        startCol: startCol,
        endCol: endCol,
        activeFilters: activeFilters ?? this.activeFilters,
      );
}

/// 실행 취소/다시 실행용 스냅샷
class _Snapshot {
  final String sheetName;
  final Map<String, dynamic> cellData;
  final Map<String, CellFormat> cellFormats;

  _Snapshot({
    required this.sheetName,
    required this.cellData,
    required this.cellFormats,
  });
}

/// 클립보드 데이터
class ClipboardData {
  final int startRow;
  final int startCol;
  final int endRow;
  final int endCol;
  final Map<String, dynamic> cells;
  final Map<String, CellFormat> formats;
  final bool isCut;

  ClipboardData({
    required this.startRow,
    required this.startCol,
    required this.endRow,
    required this.endCol,
    required this.cells,
    required this.formats,
    this.isCut = false,
  });
}

class SpreadsheetProvider extends ChangeNotifier {
  // ──────────────────────── 상태 버전 (shouldRepaint 최적화) ────────────────────────
  int _stateVersion = 0;
  int get stateVersion => _stateVersion;

  @override
  void notifyListeners() {
    _stateVersion++;
    super.notifyListeners();
  }

  // ──────────────────────── 프레임 단위 알림 병합 ────────────────────────
  bool _notifyScheduled = false;

  /// Coalesce multiple state changes in the same frame into a single rebuild.
  /// Use for high-frequency operations like drag-selection.
  void _scheduleNotify() {
    if (_notifyScheduled) return;
    _notifyScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyScheduled = false;
      notifyListeners();
    });
  }

  // ──────────────────────── 핵심 상태 ────────────────────────
  Workbook? _workbook;
  String _fileName = 'New Spreadsheet';
  String? _filePath;
  bool _isModified = false;
  DateTime? _lastSavedAt;

  // ──────────────────────── 시트 상태 ────────────────────────
  String _currentSheetName = 'Sheet1';
  List<String> _sheetNames = ['Sheet1'];

  // 시트별 셀 데이터 / 서식
  final Map<String, Map<String, dynamic>> _allCellData = {};
  final Map<String, Map<String, CellFormat>> _allCellFormats = {};

  // ──────────────────────── 그리드 크기 ────────────────────────
  int _totalRows = SpreadsheetDefaults.totalRows;
  int _totalCols = SpreadsheetDefaults.totalCols;
  static const double defaultColWidth = SpreadsheetDefaults.defaultColWidth;
  static const double defaultRowHeight = SpreadsheetDefaults.defaultRowHeight;

  final Map<String, Map<int, double>> _allColWidths = {};
  final Map<String, Map<int, double>> _allRowHeights = {};

  // Cached total dimensions (invalidated on width/height/sheet change)
  double? _cachedTotalWidth;
  double? _cachedTotalHeight;

  // ──────────────────────── 프리픽스 합 배열 (O(1) 위치 계산) ────────────────────────
  List<double> _colOffsets = [];  // _colOffsets[i] = sum of column widths 0..i-1
  List<double> _rowOffsets = [];  // _rowOffsets[i] = sum of row heights 0..i-1

  // 병합 셀: 시트별 병합 범위 리스트 [(startRow, startCol, endRow, endCol)]
  final Map<String, List<(int, int, int, int)>> _allMergedCells = {};

  // O(1) merge lookup cache — invalidated on merge/unmerge/sheet-switch/load
  Map<String, (int, int, int, int)>? _mergeIndex;

  Map<String, (int, int, int, int)> get _mergeMap {
    if (_mergeIndex != null) return _mergeIndex!;
    _mergeIndex = {};
    for (final m in mergedCells) {
      for (int r = m.$1; r <= m.$3; r++) {
        for (int c = m.$2; c <= m.$4; c++) {
          _mergeIndex!['$r,$c'] = m;
        }
      }
    }
    return _mergeIndex!;
  }

  // 숨김 행/열
  final Map<String, Set<int>> _allHiddenRows = {};
  final Map<String, Set<int>> _allHiddenCols = {};

  // 서식 복사
  CellFormat? _formatPainterSource;
  bool _isFormatPainterActive = false;

  // 조건부 서식
  final Map<String, List<ConditionalFormatRule>> _allCondRules = {};

  // 셀 메모
  final Map<String, Map<String, CellComment>> _allCellComments = {};

  // 자동 필터
  final Map<String, AutoFilterState?> _allAutoFilters = {};

  // 차트
  final Map<String, List<Map<String, dynamic>>> _allCharts = {};

  // 데이터 검증
  final Map<String, List<DataValidation>> _allValidations = {};

  // 명명 범위 (name → "Sheet1!A1:B5" 형태)
  final Map<String, String> _namedRanges = {};

  // 하이퍼링크
  final Map<String, Map<String, String>> _allHyperlinks = {};

  // 수식 캐싱
  final Map<String, Map<String, String>> _formulaCache = {};

  // ──────────────────────── 선택 ────────────────────────
  int _selectedRow = 0;
  int _selectedCol = 0;
  int _selStartRow = 0;
  int _selStartCol = 0;
  int _selEndRow = 0;
  int _selEndCol = 0;
  bool _hasRange = false;

  // ──────────────────────── 편집 ────────────────────────
  bool _isEditing = false;
  String _editValue = '';

  // ──────────────────────── 클립보드 ────────────────────────
  ClipboardData? _clipboard;

  // ──────────────────────── 실행 취소 / 다시 실행 ────────────────────────
  final List<_Snapshot> _undoStack = [];
  final List<_Snapshot> _redoStack = [];
  static const int _maxUndo = SpreadsheetDefaults.maxUndoStack;

  // ════════════════════════ 게터 ════════════════════════

  Workbook? get workbook => _workbook;
  String get fileName => _fileName;
  String? get filePath => _filePath;
  bool get isModified => _isModified;
  DateTime? get lastSavedAt => _lastSavedAt;
  String get currentSheetName => _currentSheetName;
  List<String> get sheetNames => List.unmodifiable(_sheetNames);
  int get totalRows => _totalRows;
  int get totalCols => _totalCols;

  double get totalWidth {
    if (_cachedTotalWidth != null) return _cachedTotalWidth!;
    if (_colOffsets.isNotEmpty) {
      _cachedTotalWidth = _colOffsets.last;
      return _cachedTotalWidth!;
    }
    double w = 0;
    for (int c = 0; c < _totalCols; c++) {
      w += getColumnWidth(c);
    }
    _cachedTotalWidth = w;
    return w;
  }

  double get totalHeight {
    if (_cachedTotalHeight != null) return _cachedTotalHeight!;
    if (_rowOffsets.isNotEmpty) {
      _cachedTotalHeight = _rowOffsets.last;
      return _cachedTotalHeight!;
    }
    double h = 0;
    for (int r = 0; r < _totalRows; r++) {
      h += getRowHeight(r);
    }
    _cachedTotalHeight = h;
    return h;
  }

  void _invalidateDimensionCache() {
    _cachedTotalWidth = null;
    _cachedTotalHeight = null;
    _rebuildOffsets();
  }

  /// Rebuild prefix sum arrays for O(1) position lookups.
  /// Called after any column/row width change, sheet switch, or grid resize.
  void _rebuildOffsets() {
    final cols = _totalCols;
    _colOffsets = List.filled(cols + 1, 0.0);
    for (int c = 0; c < cols; c++) {
      _colOffsets[c + 1] = _colOffsets[c] + getColumnWidth(c);
    }

    final rows = _totalRows;
    _rowOffsets = List.filled(rows + 1, 0.0);
    for (int r = 0; r < rows; r++) {
      _rowOffsets[r + 1] = _rowOffsets[r] + getRowHeight(r);
    }
  }

  /// Prefix sum column offsets (for binary search in viewport clipping)
  List<double> get colOffsets => _colOffsets;

  /// Prefix sum row offsets (for binary search in viewport clipping)
  List<double> get rowOffsets => _rowOffsets;

  int get selectedRow => _selectedRow;
  int get selectedCol => _selectedCol;
  int get selStartRow => _selStartRow;
  int get selStartCol => _selStartCol;
  int get selEndRow => _selEndRow;
  int get selEndCol => _selEndCol;
  bool get hasRange => _hasRange;

  bool get isEditing => _isEditing;
  String get editValue => _editValue;
  ClipboardData? get clipboard => _clipboard;
  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;
  bool get isFormatPainterActive => _isFormatPainterActive;

  List<ConditionalFormatRule> get condRules =>
      _allCondRules[_currentSheetName] ?? [];

  Map<String, CellComment> get currentComments =>
      _allCellComments[_currentSheetName] ?? {};

  AutoFilterState? get autoFilter =>
      _allAutoFilters[_currentSheetName];

  bool get hasAutoFilter => _allAutoFilters[_currentSheetName] != null;

  List<Map<String, dynamic>> get charts =>
      _allCharts[_currentSheetName] ?? [];

  Set<int> get hiddenRows => _allHiddenRows[_currentSheetName] ?? {};
  Set<int> get hiddenCols => _allHiddenCols[_currentSheetName] ?? {};
  bool isRowHidden(int row) => hiddenRows.contains(row);
  bool isColHidden(int col) => hiddenCols.contains(col);

  String get selectedCellAddress =>
      '${getColumnName(_selectedCol)}${_selectedRow + 1}';

  Map<String, dynamic> get currentCellData =>
      _allCellData[_currentSheetName] ?? {};

  Map<String, CellFormat> get currentCellFormats =>
      _allCellFormats[_currentSheetName] ?? {};

  Map<int, double> get columnWidths =>
      _allColWidths[_currentSheetName] ?? {};

  Map<int, double> get rowHeights =>
      _allRowHeights[_currentSheetName] ?? {};

  List<(int, int, int, int)> get mergedCells =>
      _allMergedCells[_currentSheetName] ?? [];

  /// 특정 셀이 병합의 일부인지 확인 — O(1) via _mergeMap
  (int, int, int, int)? getMergeForCell(int row, int col) {
    return _mergeMap['$row,$col'];
  }

  /// 병합 영역의 시작 셀인지 — O(1) via _mergeMap
  bool isMergeStart(int row, int col) {
    final m = _mergeMap['$row,$col'];
    if (m == null) return false;
    return m.$1 == row && m.$2 == col;
  }

  /// 병합의 시작 셀이 아닌 나머지 셀인지 (숨겨야 하는 셀)
  bool isMergeHidden(int row, int col) {
    final m = getMergeForCell(row, col);
    if (m == null) return false;
    return !(m.$1 == row && m.$2 == col);
  }

  // ════════════════════════ 초기화 ════════════════════════

  void createNew({String? defaultName}) {
    _workbook?.dispose();
    _workbook = Workbook();
    _fileName = defaultName ?? 'New Spreadsheet';
    _filePath = null;
    _isModified = false;

    _sheetNames = ['Sheet1'];
    _currentSheetName = 'Sheet1';

    _allCellData.clear();
    _allCellFormats.clear();
    _allColWidths.clear();
    _allRowHeights.clear();
    _allMergedCells.clear();
    _mergeIndex = null;
    for (final n in _sheetNames) {
      _allCellData[n] = {};
      _allCellFormats[n] = {};
      _allColWidths[n] = {};
      _allRowHeights[n] = {};
      _allMergedCells[n] = [];
    }

    _totalRows = SpreadsheetDefaults.totalRows;
    _totalCols = SpreadsheetDefaults.totalCols;
    _selectedRow = 0;
    _selectedCol = 0;
    _hasRange = false;
    _isEditing = false;
    _editValue = '';
    _undoStack.clear();
    _redoStack.clear();
    _clipboard = null;
    _invalidateDimensionCache();
    notifyListeners();
  }

  void createFromTemplate(String type) {
    switch (type) {
      case 'budget':
        // Column headers
        setCellValueDirect(0, 0, 'Category');
        setCellValueDirect(0, 1, 'Budget');
        setCellValueDirect(0, 2, 'Actual');
        setCellValueDirect(0, 3, 'Difference');
        // Sample data
        setCellValueDirect(1, 0, 'Housing');
        setCellValueDirect(1, 1, 1500);
        setCellValueDirect(1, 2, 1450);
        setCellValueDirect(1, 3, '=B2-C2');
        setCellValueDirect(2, 0, 'Food');
        setCellValueDirect(2, 1, 500);
        setCellValueDirect(2, 2, 530);
        setCellValueDirect(2, 3, '=B3-C3');
        setCellValueDirect(3, 0, 'Transport');
        setCellValueDirect(3, 1, 300);
        setCellValueDirect(3, 2, 280);
        setCellValueDirect(3, 3, '=B4-C4');
        setCellValueDirect(4, 0, 'Total');
        setCellValueDirect(4, 1, '=SUM(B2:B4)');
        setCellValueDirect(4, 2, '=SUM(C2:C4)');
        setCellValueDirect(4, 3, '=SUM(D2:D4)');
        _fileName = 'Budget';
      case 'schedule':
        // Time + weekday headers
        setCellValueDirect(0, 0, 'Time');
        setCellValueDirect(0, 1, 'Mon');
        setCellValueDirect(0, 2, 'Tue');
        setCellValueDirect(0, 3, 'Wed');
        setCellValueDirect(0, 4, 'Thu');
        setCellValueDirect(0, 5, 'Fri');
        // Time slots
        final times = ['09:00', '10:00', '11:00', '12:00', '13:00', '14:00', '15:00', '16:00', '17:00'];
        for (var i = 0; i < times.length; i++) {
          setCellValueDirect(i + 1, 0, times[i]);
        }
        _fileName = 'Schedule';
    }
    _invalidateDimensionCache();
    _isModified = true;
    notifyListeners();
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<bool> loadFile(File file) async {
    // 즉시 이전 데이터 완전 초기화 + 로딩 상태 표시
    _isLoading = true;
    _workbook?.dispose();
    _workbook = null;
    _allCellData.clear();
    _allCellFormats.clear();
    _allColWidths.clear();
    _allRowHeights.clear();
    _allMergedCells.clear();
    _mergeIndex = null;
    _undoStack.clear();
    _redoStack.clear();
    _clipboard = null;
    _sheetNames = ['Sheet1'];
    _currentSheetName = 'Sheet1';
    _selectedRow = 0;
    _selectedCol = 0;
    _hasRange = false;
    _isEditing = false;
    _editValue = '';
    _totalRows = SpreadsheetDefaults.totalRows;
    _totalCols = SpreadsheetDefaults.totalCols;
    _isModified = false;
    _fileName = file.path.split(Platform.pathSeparator).last;
    _filePath = file.path;
    notifyListeners();

    try {
      if (!await file.exists()) {
        _isLoading = false;
        notifyListeners();
        return false;
      }
      final bytes = await file.readAsBytes();

      // Syncfusion xlsio는 쓰기 전용이므로, 읽기는 fallback 파서 사용
      final fallback = XlsxFallbackParser();
      if (!fallback.parse(bytes)) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _workbook = null; // 저장 시 새로 생성
      _isModified = false;

      _sheetNames = fallback.sheetNames.isNotEmpty
          ? fallback.sheetNames
          : ['Sheet1'];
      _currentSheetName = _sheetNames.first;

      _totalRows = 100;
      _totalCols = 26;

      for (final name in _sheetNames) {
        _allCellData[name] = {};
        _allCellFormats[name] = {};
        _allColWidths[name] = {};
        _allRowHeights[name] = {};
        _allMergedCells[name] = [];

        final sheetData = fallback.sheets[name] ?? {};
        final sheetStyleData = fallback.sheetStyles[name] ?? {};
        final layout = fallback.sheetLayouts[name];
        int maxRow = 0;
        int maxCol = 0;

        // ── 셀 데이터 ──
        for (final entry in sheetData.entries) {
          _allCellData[name]![entry.key] = entry.value;
          final parsed = parseCellReference(entry.key);
          if (parsed != null) {
            if (parsed.$1 > maxRow) maxRow = parsed.$1;
            if (parsed.$2 > maxCol) maxCol = parsed.$2;
          }
        }

        // ── 서식 ──
        for (final entry in sheetStyleData.entries) {
          final s = entry.value;
          final fmt = CellFormat();
          bool hasAny = false;

          if (s.bold) { fmt.bold = true; hasAny = true; }
          if (s.italic) { fmt.italic = true; hasAny = true; }
          if (s.underline) { fmt.underline = true; hasAny = true; }
          if (s.fontSize != null) { fmt.fontSize = s.fontSize!.round(); hasAny = true; }
          if (s.fontFamily != null) { fmt.fontFamily = s.fontFamily; hasAny = true; }
          if (s.wrapText) { fmt.wrapText = true; hasAny = true; }

          if (s.fontColorHex != null) {
            final c = _hexToColor(s.fontColorHex!);
            if (c != null) { fmt.textColor = c; hasAny = true; }
          }
          if (s.bgColorHex != null) {
            final c = _hexToColor(s.bgColorHex!);
            if (c != null) { fmt.backgroundColor = c; hasAny = true; }
          }
          if (s.horizontalAlign != null) {
            switch (s.horizontalAlign) {
              case 'center': fmt.alignment = TextAlign.center; hasAny = true;
              case 'right': fmt.alignment = TextAlign.right; hasAny = true;
            }
          }

          if (hasAny) _allCellFormats[name]![entry.key] = fmt;
        }

        // ── 레이아웃 (열 너비, 행 높이, 병합 셀) ──
        if (layout != null) {
          // 기본 열 너비가 있으면 명시적으로 지정되지 않은 열에 적용
          if (layout.defaultColWidthPx != null) {
            for (int c = 0; c <= maxCol; c++) {
              if (!layout.colWidths.containsKey(c)) {
                _allColWidths[name]![c] = layout.defaultColWidthPx!;
              }
            }
          }
          _allColWidths[name]!.addAll(layout.colWidths);

          // 기본 행 높이가 있으면 명시적으로 지정되지 않은 행에 적용
          if (layout.defaultRowHeightPx != null) {
            for (int r = 0; r <= maxRow; r++) {
              if (!layout.rowHeights.containsKey(r)) {
                _allRowHeights[name]![r] = layout.defaultRowHeightPx!;
              }
            }
          }
          _allRowHeights[name]!.addAll(layout.rowHeights);

          _allMergedCells[name]!.addAll(layout.mergedCells);
        }

        if (maxRow + 20 > _totalRows) _totalRows = maxRow + 20;
        if (maxCol + 5 > _totalCols) _totalCols = maxCol + 5;
      }

      _isLoading = false;
      _invalidateDimensionCache();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('파일 로드 실패: $e');
      _isLoading = false;
      _invalidateDimensionCache();
      notifyListeners();
      return false;
    }
  }

  /// ARGB hex 문자열("FFRRGGBB" 또는 "RRGGBB")을 Color로 변환
  Color? _hexToColor(String hex) {
    try {
      String h = hex.replaceAll('#', '');
      if (h.length == 6) h = 'FF$h';
      if (h.length == 8) {
        final value = int.parse(h, radix: 16);
        if (value == 0xFF000000 || value == 0x00000000) return null;
        return Color(value);
      }
    } catch (_) { // Invalid hex color string — return null is expected
    }
    return null;
  }


  Future<String?> saveFile() async {
    if (_filePath == null) return saveAs();
    return _writeTo(_filePath!);
  }

  Future<String?> saveAs({String? dialogTitle}) async {
    final targetName =
        _fileName.endsWith('.xlsx') ? _fileName : '$_fileName.xlsx';

    String? result;
    try {
      result = await FilePicker.platform.saveFile(
        dialogTitle: dialogTitle ?? 'Save Spreadsheet',
        fileName: targetName,
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );
    } catch (e) {
      debugPrint('Spreadsheet saveFile picker failed: $e');
    }

    // Fallback for mobile platforms where saveFile returns null or is unsupported
    if (result == null &&
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      final dir = await getApplicationDocumentsDirectory();
      result = '${dir.path}${Platform.pathSeparator}$targetName';
    }

    if (result != null) {
      _filePath = result;
      _fileName = result.split(Platform.pathSeparator).last;
      return _writeTo(result);
    }
    return null;
  }

  Future<String?> _writeTo(String path) async {
    try {
      // 기존 workbook이 있으면 셀 데이터를 반영, 없으면 새로 생성
      _workbook ??= Workbook();

      for (int si = 0; si < _sheetNames.length; si++) {
        final sheetName = _sheetNames[si];
        Worksheet sheet;
        if (si < _workbook!.worksheets.count) {
          sheet = _workbook!.worksheets[si];
        } else {
          sheet = _workbook!.worksheets.addWithName(sheetName);
        }

        final data = _allCellData[sheetName] ?? {};
        final fmts = _allCellFormats[sheetName] ?? {};
        final cw = _allColWidths[sheetName] ?? {};
        final rh = _allRowHeights[sheetName] ?? {};

        // ── 셀 데이터 + 서식 저장 ──
        for (final entry in data.entries) {
          final parsed = parseCellReference(entry.key);
          if (parsed == null) continue;
          final r = parsed.$1 + 1; // 0-based → 1-based
          final c = parsed.$2 + 1;
          final range = sheet.getRangeByIndex(r, c);
          final v = entry.value;

          // 값 저장
          if (v is String && v.startsWith('=')) {
            range.formula = v;
          } else if (v is num) {
            range.number = v.toDouble();
          } else if (v != null) {
            final str = v.toString();
            final num? n = num.tryParse(str);
            if (n != null) {
              range.number = n.toDouble();
            } else {
              range.text = str;
            }
          }

          // 서식 저장
          final fmt = fmts[entry.key];
          if (fmt != null && fmt.hasStyle) {
            range.cellStyle.bold = fmt.bold;
            range.cellStyle.italic = fmt.italic;
            range.cellStyle.underline = fmt.underline;
            if (fmt.fontSize != null) range.cellStyle.fontSize = fmt.fontSize!.toDouble();
            if (fmt.fontFamily != null) range.cellStyle.fontName = fmt.fontFamily!;
            if (fmt.textColor != null) {
              range.cellStyle.fontColor = '#${fmt.textColor!.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
            }
            if (fmt.backgroundColor != null) {
              range.cellStyle.backColor = '#${fmt.backgroundColor!.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
            }
            if (fmt.alignment == TextAlign.center) {
              range.cellStyle.hAlign = HAlignType.center;
            } else if (fmt.alignment == TextAlign.right) {
              range.cellStyle.hAlign = HAlignType.right;
            }
            range.cellStyle.wrapText = fmt.wrapText;
          }
        }

        // ── 열 너비 저장 (픽셀) ──
        for (final e in cw.entries) {
          sheet.setColumnWidthInPixels(e.key + 1, e.value.toInt());
        }

        // ── 행 높이 저장 (포인트) ──
        for (final e in rh.entries) {
          sheet.getRangeByIndex(e.key + 1, 1).rowHeight = e.value / 1.33;
        }
      }

      final bytes = _workbook!.saveAsStream();
      await File(path).writeAsBytes(bytes);
      _isModified = false;
      notifyListeners();
      return path;
    } catch (e) {
      debugPrint('파일 저장 실패: $e');
      return null;
    }
  }

  // ════════════════════════ 셀 접근 ════════════════════════

  dynamic getCellValue(int row, int col) {
    final key = '${getColumnName(col)}${row + 1}';
    return _allCellData[_currentSheetName]?[key];
  }

  String getCellDisplay(int row, int col) {
    final raw = getCellValue(row, col);
    if (raw == null) return '';
    final s = raw.toString();
    final key = '${getColumnName(col)}${row + 1}';
    if (s.startsWith('=')) {
      return _evalFormula(s, key) ?? '!ERROR';
    }
    final fmt = _allCellFormats[_currentSheetName]?[key];
    if (fmt != null) return _applyNumFmt(s, fmt.numberFormat);
    return s;
  }

  String getCellRaw(int row, int col) {
    final raw = getCellValue(row, col);
    return raw?.toString() ?? '';
  }

  void setCellValue(int row, int col, dynamic value) {
    _pushUndo();
    final key = '${getColumnName(col)}${row + 1}';
    _allCellData[_currentSheetName] ??= {};
    if (value == null || (value is String && value.isEmpty)) {
      _allCellData[_currentSheetName]!.remove(key);
    } else {
      _allCellData[_currentSheetName]![key] = value;
    }
    _isModified = true;
    notifyListeners();
  }

  CellFormat getCellFormat(int row, int col) {
    final key = '${getColumnName(col)}${row + 1}';
    return _allCellFormats[_currentSheetName]?[key] ?? CellFormat();
  }

  void setCellFormat(int row, int col, CellFormat fmt) {
    final key = '${getColumnName(col)}${row + 1}';
    _allCellFormats[_currentSheetName] ??= {};
    _allCellFormats[_currentSheetName]![key] = fmt;
    _isModified = true;
    notifyListeners();
  }

  /// 현재 선택 영역에 서식 적용
  void applyFormatToSelection(CellFormat Function(CellFormat) modifier) {
    _pushUndo();
    int r0, r1, c0, c1;
    if (_hasRange) {
      r0 = min(_selStartRow, _selEndRow);
      r1 = max(_selStartRow, _selEndRow);
      c0 = min(_selStartCol, _selEndCol);
      c1 = max(_selStartCol, _selEndCol);
    } else {
      r0 = r1 = _selectedRow;
      c0 = c1 = _selectedCol;
    }
    for (int r = r0; r <= r1; r++) {
      for (int c = c0; c <= c1; c++) {
        final key = '${getColumnName(c)}${r + 1}';
        _allCellFormats[_currentSheetName] ??= {};
        final old = _allCellFormats[_currentSheetName]![key] ?? CellFormat();
        _allCellFormats[_currentSheetName]![key] = modifier(old);
      }
    }
    _isModified = true;
    notifyListeners();
  }

  // ════════════════════════ 선택 ════════════════════════

  void selectCell(int row, int col) {
    _selectedRow = row.clamp(0, _totalRows - 1);
    _selectedCol = col.clamp(0, _totalCols - 1);
    _selStartRow = _selectedRow;
    _selStartCol = _selectedCol;
    _selEndRow = _selectedRow;
    _selEndCol = _selectedCol;
    _hasRange = false;
    _isEditing = false;
    notifyListeners();
  }

  void selectRange(int startRow, int startCol, int endRow, int endCol) {
    _selStartRow = startRow.clamp(0, _totalRows - 1);
    _selStartCol = startCol.clamp(0, _totalCols - 1);
    _selEndRow = endRow.clamp(0, _totalRows - 1);
    _selEndCol = endCol.clamp(0, _totalCols - 1);
    _selectedRow = _selStartRow;
    _selectedCol = _selStartCol;
    _hasRange = true;
    notifyListeners();
  }

  void updateSelectionEnd(int endRow, int endCol) {
    _selEndRow = endRow.clamp(0, _totalRows - 1);
    _selEndCol = endCol.clamp(0, _totalCols - 1);
    _hasRange = true;
    _scheduleNotify();
  }

  bool isCellInSelection(int row, int col) {
    if (!_hasRange) return row == _selectedRow && col == _selectedCol;
    final minR = min(_selStartRow, _selEndRow);
    final maxR = max(_selStartRow, _selEndRow);
    final minC = min(_selStartCol, _selEndCol);
    final maxC = max(_selStartCol, _selEndCol);
    return row >= minR && row <= maxR && col >= minC && col <= maxC;
  }

  bool isCellActive(int row, int col) =>
      row == _selectedRow && col == _selectedCol;

  // ════════════════════════ 편집 모드 ════════════════════════

  void startEditing([String? initial]) {
    _isEditing = true;
    _editValue = initial ?? getCellRaw(_selectedRow, _selectedCol);
    notifyListeners();
  }

  void updateEditValue(String v) {
    _editValue = v;
  }

  void confirmEdit() {
    if (!_isEditing) return;
    _isEditing = false;
    // setCellValue already calls notifyListeners — no second call needed
    setCellValue(_selectedRow, _selectedCol, _editValue);
  }

  void cancelEdit() {
    _isEditing = false;
    _editValue = '';
    notifyListeners();
  }

  void moveSelection(int dr, int dc) {
    selectCell(_selectedRow + dr, _selectedCol + dc);
  }

  // ════════════════════════ 행/열 조작 ════════════════════════

  void insertRow(int index) {
    _pushUndo();
    _shiftCells(
      rowShift: 1,
      fromRow: index,
      fromCol: null,
    );
    _totalRows++;
    _invalidateDimensionCache();
    _isModified = true;
    notifyListeners();
  }

  void deleteRow(int index) {
    _pushUndo();
    // 해당 행 데이터 삭제 후 위로 당기기
    final data = _allCellData[_currentSheetName] ?? {};
    final fmts = _allCellFormats[_currentSheetName] ?? {};
    final newD = <String, dynamic>{};
    final newF = <String, CellFormat>{};
    for (final e in data.entries) {
      final p = parseCellReference(e.key);
      if (p == null) continue;
      if (p.$1 == index) continue;
      if (p.$1 > index) {
        newD['${getColumnName(p.$2)}${p.$1}'] = e.value;
      } else {
        newD[e.key] = e.value;
      }
    }
    for (final e in fmts.entries) {
      final p = parseCellReference(e.key);
      if (p == null) continue;
      if (p.$1 == index) continue;
      if (p.$1 > index) {
        newF['${getColumnName(p.$2)}${p.$1}'] = e.value;
      } else {
        newF[e.key] = e.value;
      }
    }
    _allCellData[_currentSheetName] = newD;
    _allCellFormats[_currentSheetName] = newF;
    if (_totalRows > 1) _totalRows--;
    _invalidateDimensionCache();
    _isModified = true;
    notifyListeners();
  }

  void insertColumn(int index) {
    _pushUndo();
    final data = _allCellData[_currentSheetName] ?? {};
    final fmts = _allCellFormats[_currentSheetName] ?? {};
    final newD = <String, dynamic>{};
    final newF = <String, CellFormat>{};
    for (final e in data.entries) {
      final p = parseCellReference(e.key);
      if (p == null) continue;
      if (p.$2 >= index) {
        newD['${getColumnName(p.$2 + 1)}${p.$1 + 1}'] = e.value;
      } else {
        newD[e.key] = e.value;
      }
    }
    for (final e in fmts.entries) {
      final p = parseCellReference(e.key);
      if (p == null) continue;
      if (p.$2 >= index) {
        newF['${getColumnName(p.$2 + 1)}${p.$1 + 1}'] = e.value;
      } else {
        newF[e.key] = e.value;
      }
    }
    _allCellData[_currentSheetName] = newD;
    _allCellFormats[_currentSheetName] = newF;
    _totalCols++;
    _invalidateDimensionCache();
    _isModified = true;
    notifyListeners();
  }

  void deleteColumn(int index) {
    _pushUndo();
    final data = _allCellData[_currentSheetName] ?? {};
    final fmts = _allCellFormats[_currentSheetName] ?? {};
    final newD = <String, dynamic>{};
    final newF = <String, CellFormat>{};
    for (final e in data.entries) {
      final p = parseCellReference(e.key);
      if (p == null) continue;
      if (p.$2 == index) continue;
      if (p.$2 > index) {
        newD['${getColumnName(p.$2 - 1)}${p.$1 + 1}'] = e.value;
      } else {
        newD[e.key] = e.value;
      }
    }
    for (final e in fmts.entries) {
      final p = parseCellReference(e.key);
      if (p == null) continue;
      if (p.$2 == index) continue;
      if (p.$2 > index) {
        newF['${getColumnName(p.$2 - 1)}${p.$1 + 1}'] = e.value;
      } else {
        newF[e.key] = e.value;
      }
    }
    _allCellData[_currentSheetName] = newD;
    _allCellFormats[_currentSheetName] = newF;
    if (_totalCols > 1) _totalCols--;
    _invalidateDimensionCache();
    _isModified = true;
    notifyListeners();
  }

  void _shiftCells({required int rowShift, required int? fromRow, int? fromCol}) {
    final data = _allCellData[_currentSheetName] ?? {};
    final fmts = _allCellFormats[_currentSheetName] ?? {};
    final newD = <String, dynamic>{};
    final newF = <String, CellFormat>{};
    for (final e in data.entries) {
      final p = parseCellReference(e.key);
      if (p == null) continue;
      if (fromRow != null && p.$1 >= fromRow) {
        // p.$1 is 0-based row, cell key needs 1-based row
        newD['${getColumnName(p.$2)}${p.$1 + 1 + rowShift}'] = e.value;
      } else {
        newD[e.key] = e.value;
      }
    }
    for (final e in fmts.entries) {
      final p = parseCellReference(e.key);
      if (p == null) continue;
      if (fromRow != null && p.$1 >= fromRow) {
        newF['${getColumnName(p.$2)}${p.$1 + 1 + rowShift}'] = e.value;
      } else {
        newF[e.key] = e.value;
      }
    }
    _allCellData[_currentSheetName] = newD;
    _allCellFormats[_currentSheetName] = newF;
  }

  // ════════════════════════ 시트 관리 ════════════════════════

  void addSheet(String name) {
    if (_sheetNames.contains(name)) return;
    _sheetNames.add(name);
    _allCellData[name] = {};
    _allCellFormats[name] = {};
    _allColWidths[name] = {};
    _allRowHeights[name] = {};
    _currentSheetName = name;
    _selectedRow = 0;
    _selectedCol = 0;
    _hasRange = false;
    _mergeIndex = null;
    _invalidateDimensionCache();
    _isModified = true;
    notifyListeners();
  }

  void deleteSheet(String name) {
    if (_sheetNames.length <= 1) return;
    _sheetNames.remove(name);
    _allCellData.remove(name);
    _allCellFormats.remove(name);
    _allColWidths.remove(name);
    _allRowHeights.remove(name);
    if (_currentSheetName == name) {
      _currentSheetName = _sheetNames.first;
      _selectedRow = 0;
      _selectedCol = 0;
      _hasRange = false;
    }
    _mergeIndex = null;
    _invalidateDimensionCache();
    _isModified = true;
    notifyListeners();
  }

  void renameSheet(String oldName, String newName) {
    if (!_sheetNames.contains(oldName) || _sheetNames.contains(newName)) return;
    final i = _sheetNames.indexOf(oldName);
    _sheetNames[i] = newName;
    _allCellData[newName] = _allCellData.remove(oldName) ?? {};
    _allCellFormats[newName] = _allCellFormats.remove(oldName) ?? {};
    _allColWidths[newName] = _allColWidths.remove(oldName) ?? {};
    _allRowHeights[newName] = _allRowHeights.remove(oldName) ?? {};
    _allMergedCells[newName] = _allMergedCells.remove(oldName) ?? [];
    if (_currentSheetName == oldName) _currentSheetName = newName;
    _mergeIndex = null;
    _isModified = true;
    notifyListeners();
  }

  void switchSheet(String name) {
    if (!_sheetNames.contains(name)) return;
    _currentSheetName = name;
    _selectedRow = 0;
    _selectedCol = 0;
    _hasRange = false;
    _isEditing = false;
    _mergeIndex = null;
    _invalidateDimensionCache();
    notifyListeners();
  }

  void duplicateSheet(String name, {String? copySuffix, String Function(int)? copySuffixN}) {
    String newName = '$name (${copySuffix ?? 'Copy'})';
    int cnt = 1;
    while (_sheetNames.contains(newName)) {
      cnt++;
      newName = '$name (${copySuffixN != null ? copySuffixN(cnt) : 'Copy $cnt'})';
    }
    _sheetNames.add(newName);
    _allCellData[newName] = Map.from(_allCellData[name] ?? {});
    _allCellFormats[newName] = Map.from(_allCellFormats[name] ?? {});
    _allColWidths[newName] = Map.from(_allColWidths[name] ?? {});
    _allRowHeights[newName] = Map.from(_allRowHeights[name] ?? {});
    _allMergedCells[newName] = List.from(_allMergedCells[name] ?? []);
    _currentSheetName = newName;
    _mergeIndex = null;
    _isModified = true;
    notifyListeners();
  }

  List<String> getSheetNames() => List.unmodifiable(_sheetNames);
  Map<String, dynamic> getCurrentSheetData() =>
      Map.unmodifiable(_allCellData[_currentSheetName] ?? {});

  // ════════════════════════ 클립보드 ════════════════════════

  void copy() {
    final r0 = _hasRange ? min(_selStartRow, _selEndRow) : _selectedRow;
    final r1 = _hasRange ? max(_selStartRow, _selEndRow) : _selectedRow;
    final c0 = _hasRange ? min(_selStartCol, _selEndCol) : _selectedCol;
    final c1 = _hasRange ? max(_selStartCol, _selEndCol) : _selectedCol;

    final cells = <String, dynamic>{};
    final fmts = <String, CellFormat>{};
    for (int r = r0; r <= r1; r++) {
      for (int c = c0; c <= c1; c++) {
        final key = '${getColumnName(c)}${r + 1}';
        final v = getCellValue(r, c);
        if (v != null) cells[key] = v;
        fmts[key] = getCellFormat(r, c).copy();
      }
    }
    _clipboard = ClipboardData(
      startRow: r0, startCol: c0, endRow: r1, endCol: c1,
      cells: cells, formats: fmts,
    );
    notifyListeners();
  }

  void cut() {
    copy();
    if (_clipboard != null) {
      _clipboard = ClipboardData(
        startRow: _clipboard!.startRow,
        startCol: _clipboard!.startCol,
        endRow: _clipboard!.endRow,
        endCol: _clipboard!.endCol,
        cells: _clipboard!.cells,
        formats: _clipboard!.formats,
        isCut: true,
      );
    }
    notifyListeners();
  }

  void paste() {
    if (_clipboard == null) return;
    _pushUndo();
    final dr = _selectedRow - _clipboard!.startRow;
    final dc = _selectedCol - _clipboard!.startCol;

    for (final e in _clipboard!.cells.entries) {
      final p = parseCellReference(e.key);
      if (p == null) continue;
      final nr = p.$1 + dr;
      final nc = p.$2 + dc;
      if (nr >= 0 && nr < _totalRows && nc >= 0 && nc < _totalCols) {
        final nk = '${getColumnName(nc)}${nr + 1}';
        _allCellData[_currentSheetName] ??= {};
        _allCellData[_currentSheetName]![nk] = e.value;
      }
    }
    for (final e in _clipboard!.formats.entries) {
      final p = parseCellReference(e.key);
      if (p == null) continue;
      final nr = p.$1 + dr;
      final nc = p.$2 + dc;
      if (nr >= 0 && nr < _totalRows && nc >= 0 && nc < _totalCols) {
        final nk = '${getColumnName(nc)}${nr + 1}';
        _allCellFormats[_currentSheetName] ??= {};
        _allCellFormats[_currentSheetName]![nk] = e.value;
      }
    }

    if (_clipboard!.isCut) {
      for (final k in _clipboard!.cells.keys) {
        _allCellData[_currentSheetName]?.remove(k);
      }
      for (final k in _clipboard!.formats.keys) {
        _allCellFormats[_currentSheetName]?.remove(k);
      }
      _clipboard = null;
    }
    _isModified = true;
    notifyListeners();
  }

  // ════════════════════════ 실행 취소 / 다시 실행 ════════════════════════

  void _pushUndo() {
    _undoStack.add(_Snapshot(
      sheetName: _currentSheetName,
      cellData: Map.from(_allCellData[_currentSheetName] ?? {}),
      cellFormats: Map.from(_allCellFormats[_currentSheetName] ?? {}),
    ));
    if (_undoStack.length > _maxUndo) _undoStack.removeAt(0);
    _redoStack.clear();
  }

  void undo() {
    if (_undoStack.isEmpty) return;
    _redoStack.add(_Snapshot(
      sheetName: _currentSheetName,
      cellData: Map.from(_allCellData[_currentSheetName] ?? {}),
      cellFormats: Map.from(_allCellFormats[_currentSheetName] ?? {}),
    ));
    final snap = _undoStack.removeLast();
    _allCellData[snap.sheetName] = snap.cellData;
    _allCellFormats[snap.sheetName] = snap.cellFormats;
    if (_currentSheetName != snap.sheetName) {
      _currentSheetName = snap.sheetName;
      _mergeIndex = null;
    }
    _isModified = true;
    notifyListeners();
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    _undoStack.add(_Snapshot(
      sheetName: _currentSheetName,
      cellData: Map.from(_allCellData[_currentSheetName] ?? {}),
      cellFormats: Map.from(_allCellFormats[_currentSheetName] ?? {}),
    ));
    final snap = _redoStack.removeLast();
    _allCellData[snap.sheetName] = snap.cellData;
    _allCellFormats[snap.sheetName] = snap.cellFormats;
    if (_currentSheetName != snap.sheetName) {
      _currentSheetName = snap.sheetName;
      _mergeIndex = null;
    }
    _isModified = true;
    notifyListeners();
  }

  // ════════════════════════ 열/행 크기 ════════════════════════

  double getColumnWidth(int col) =>
      _allColWidths[_currentSheetName]?[col] ?? defaultColWidth;

  double getRowHeight(int row) =>
      _allRowHeights[_currentSheetName]?[row] ?? defaultRowHeight;

  void setColumnWidth(int col, double w) {
    _allColWidths[_currentSheetName] ??= {};
    _allColWidths[_currentSheetName]![col] = w.clamp(30.0, 500.0);
    _invalidateDimensionCache();
    notifyListeners();
  }

  void setRowHeight(int row, double h) {
    _allRowHeights[_currentSheetName] ??= {};
    _allRowHeights[_currentSheetName]![row] = h.clamp(16.0, 300.0);
    _invalidateDimensionCache();
    notifyListeners();
  }

  // ════════════════════════ 정렬 ════════════════════════

  void sortColumn(int col, bool ascending) {
    _pushUndo();
    final data = _allCellData[_currentSheetName] ?? {};
    final colN = getColumnName(col);

    // 이 열에 데이터가 있는 행 수집
    final rows = <int>[];
    for (int r = 0; r < _totalRows; r++) {
      if (data.containsKey('$colN${r + 1}')) rows.add(r);
    }
    if (rows.isEmpty) return;

    rows.sort((a, b) {
      final va = data['$colN${a + 1}']?.toString() ?? '';
      final vb = data['$colN${b + 1}']?.toString() ?? '';
      final na = num.tryParse(va);
      final nb = num.tryParse(vb);
      int cmp;
      if (na != null && nb != null) {
        cmp = na.compareTo(nb);
      } else {
        cmp = va.compareTo(vb);
      }
      return ascending ? cmp : -cmp;
    });

    final minRow = rows.reduce(min);
    final newData = <String, dynamic>{};
    final fmts = _allCellFormats[_currentSheetName] ?? {};
    final newFmts = <String, CellFormat>{};

    // 정렬된 순서로 모든 열 재배치
    for (int i = 0; i < rows.length; i++) {
      final src = rows[i];
      final tgt = minRow + i;
      for (int c = 0; c < _totalCols; c++) {
        final sk = '${getColumnName(c)}${src + 1}';
        final tk = '${getColumnName(c)}${tgt + 1}';
        if (data.containsKey(sk)) newData[tk] = data[sk];
        if (fmts.containsKey(sk)) newFmts[tk] = fmts[sk]!;
      }
    }

    // 정렬 범위 밖 데이터 유지
    for (final e in data.entries) {
      if (!newData.containsKey(e.key)) {
        final p = parseCellReference(e.key);
        if (p != null && !rows.contains(p.$1)) newData[e.key] = e.value;
      }
    }

    _allCellData[_currentSheetName] = newData;
    _allCellFormats[_currentSheetName] = newFmts;
    _isModified = true;
    notifyListeners();
  }

  // ════════════════════════ 수식 평가 ════════════════════════

  FormulaEngine? _formulaEngine;

  FormulaEngine get _engine => _formulaEngine ??= FormulaEngine(
    getCellValue: getCellValue,
    getCellDisplay: getCellDisplay,
    parseCellRef: parseCellReference,
  );

  String? _evalFormula(String formula, [String? cellRef]) {
    final result = cellRef != null
        ? _engine.evaluateCell(cellRef, formula)
        : _engine.evaluate(formula);
    return result.isEmpty ? '0' : result;
  }

  String _fmtNum(num v) => v == v.toInt() ? v.toInt().toString() : v.toStringAsFixed(2);

  String _applyNumFmt(String value, String fmt) {
    final n = num.tryParse(value);
    if (n == null) return value;
    switch (fmt) {
      case 'number':
        return n.toStringAsFixed(2);
      case 'currency':
        final s = n.toStringAsFixed(0);
        final formatted = s.replaceAllMapped(
            RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
        return '\u20A9$formatted';
      case 'accounting':
        final abs = n.abs();
        final s = abs.toStringAsFixed(2);
        final formatted = s.replaceAllMapped(
            RegExp(r'(\d)(?=(\d{3})+\.)'), (m) => '${m[1]},');
        if (n < 0) return '(\u20A9$formatted)';
        return '\u20A9$formatted ';
      case 'percent':
        return '${(n * 100).toStringAsFixed(1)}%';
      case 'scientific':
        return n.toStringAsExponential(2).toUpperCase();
      case 'fraction':
        return _toFraction(n.toDouble());
      case 'time':
        // Interpret number as fraction of day (Excel style)
        final totalSeconds = (n.toDouble() * SpreadsheetDefaults.secondsPerDay).round();
        final h = (totalSeconds ~/ SpreadsheetDefaults.secondsPerHour) % 24;
        final m = (totalSeconds ~/ 60) % 60;
        final s2 = totalSeconds % 60;
        return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s2.toString().padLeft(2, '0')}';
      case 'date':
        return value;
      default:
        return value;
    }
  }

  /// 소수를 분수 문자열로 변환 (최대 분모 1000)
  String _toFraction(double val) {
    if (val == val.roundToDouble()) return '${val.round()}';
    final negative = val < 0;
    final abs = val.abs();
    final wholePart = abs.floor();
    final decimal = abs - wholePart;

    int bestNum = 0, bestDen = 1;
    double bestErr = 1.0;
    for (int den = 2; den <= 100; den++) {
      final num2 = (decimal * den).round();
      final err = (decimal - num2 / den).abs();
      if (err < bestErr) {
        bestErr = err;
        bestNum = num2;
        bestDen = den;
        if (err < 0.0001) break;
      }
    }

    final sign = negative ? '-' : '';
    if (bestNum == 0) return '$sign$wholePart';
    if (wholePart == 0) return '$sign$bestNum/$bestDen';
    return '$sign$wholePart $bestNum/$bestDen';
  }

  // ════════════════════════ 상태 표시줄 통계 ════════════════════════

  Map<String, String> getSelectionStats({
    String sumLabel = 'Sum',
    String avgLabel = 'Average',
    String countLabel = 'Count',
  }) {
    final r0 = _hasRange ? min(_selStartRow, _selEndRow) : _selectedRow;
    final r1 = _hasRange ? max(_selStartRow, _selEndRow) : _selectedRow;
    final c0 = _hasRange ? min(_selStartCol, _selEndCol) : _selectedCol;
    final c1 = _hasRange ? max(_selStartCol, _selEndCol) : _selectedCol;

    final nums = <num>[];
    int count = 0;
    for (int r = r0; r <= r1; r++) {
      for (int c = c0; c <= c1; c++) {
        final v = getCellValue(r, c);
        if (v != null && v.toString().isNotEmpty) {
          count++;
          final n = num.tryParse(v.toString());
          if (n != null) nums.add(n);
        }
      }
    }
    final stats = <String, String>{};
    if (nums.isNotEmpty) {
      final sum = nums.fold<num>(0, (a, b) => a + b);
      stats[sumLabel] = _fmtNum(sum);
      stats[avgLabel] = _fmtNum(sum / nums.length);
      stats[countLabel] = count.toString();
    } else if (count > 0) {
      stats[countLabel] = count.toString();
    }
    return stats;
  }

  // ════════════════════════ 유틸리티 ════════════════════════

  /// 0-기반 열 인덱스를 문자로 변환: 0=A, 25=Z, 26=AA ...
  String getColumnName(int index) {
    String result = '';
    int i = index;
    while (i >= 0) {
      result = String.fromCharCode(65 + (i % 26)) + result;
      i = (i ~/ 26) - 1;
    }
    return result;
  }

  /// "A1" → (row:0, col:0), "AA10" → (row:9, col:26)
  (int, int)? parseCellReference(String ref) {
    final m = RegExp(r'^([A-Za-z]+)(\d+)$').firstMatch(ref.trim());
    if (m == null) return null;
    final colStr = m.group(1)!.toUpperCase();
    final rowStr = m.group(2)!;
    int col = 0;
    for (int i = 0; i < colStr.length; i++) {
      col = col * 26 + (colStr.codeUnitAt(i) - 64);
    }
    col -= 1;
    final row = int.parse(rowStr) - 1;
    if (row < 0) return null;
    return (row, col);
  }

  /// 열의 누적 X 위치 — O(1) via prefix sum
  double getColumnX(int col) {
    if (_colOffsets.isEmpty) _rebuildOffsets();
    if (col < 0) return 0;
    if (col >= _colOffsets.length) return _colOffsets.last;
    return _colOffsets[col];
  }

  /// 행의 누적 Y 위치 — O(1) via prefix sum
  double getRowY(int row) {
    if (_rowOffsets.isEmpty) _rebuildOffsets();
    if (row < 0) return 0;
    if (row >= _rowOffsets.length) return _rowOffsets.last;
    return _rowOffsets[row];
  }

  /// X 좌표에서 열 인덱스 찾기 — O(log n) via binary search
  int getColumnAtX(double x) {
    if (_colOffsets.isEmpty) _rebuildOffsets();
    if (x <= 0) return 0;
    int lo = 0, hi = _colOffsets.length - 1;
    while (lo < hi) {
      final mid = (lo + hi) ~/ 2;
      if (_colOffsets[mid] < x) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    // lo points to the first offset >= x; the column is lo-1 (clamped)
    return (lo - 1).clamp(0, _totalCols - 1);
  }

  /// Y 좌표에서 행 인덱스 찾기 — O(log n) via binary search
  int getRowAtY(double y) {
    if (_rowOffsets.isEmpty) _rebuildOffsets();
    if (y <= 0) return 0;
    int lo = 0, hi = _rowOffsets.length - 1;
    while (lo < hi) {
      final mid = (lo + hi) ~/ 2;
      if (_rowOffsets[mid] < y) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    // lo points to the first offset >= y; the row is lo-1 (clamped)
    return (lo - 1).clamp(0, _totalRows - 1);
  }

  // ════════════════════════ 셀 병합/해제 ════════════════════════

  /// 현재 선택 범위가 이미 병합되어 있는지
  bool get isSelectionMerged {
    if (!_hasRange) return getMergeForCell(_selectedRow, _selectedCol) != null;
    final r0 = min(_selStartRow, _selEndRow);
    final c0 = min(_selStartCol, _selEndCol);
    return getMergeForCell(r0, c0) != null;
  }

  /// 선택 범위가 2셀 이상인지 (병합 가능 여부)
  bool get canMerge {
    if (!_hasRange) return false;
    final r0 = min(_selStartRow, _selEndRow);
    final r1 = max(_selStartRow, _selEndRow);
    final c0 = min(_selStartCol, _selEndCol);
    final c1 = max(_selStartCol, _selEndCol);
    return r0 != r1 || c0 != c1;
  }

  /// 선택 범위를 병합 (좌상단 값 보존, 나머지 클리어)
  void mergeCells() {
    if (!canMerge) return;
    _pushUndo();
    final r0 = min(_selStartRow, _selEndRow);
    final r1 = max(_selStartRow, _selEndRow);
    final c0 = min(_selStartCol, _selEndCol);
    final c1 = max(_selStartCol, _selEndCol);

    // 기존 병합과 겹치면 제거
    _allMergedCells[_currentSheetName]?.removeWhere((m) =>
        !(m.$3 < r0 || m.$1 > r1 || m.$4 < c0 || m.$2 > c1));

    // 좌상단 셀 값 보존, 나머지 클리어
    for (int r = r0; r <= r1; r++) {
      for (int c = c0; c <= c1; c++) {
        if (r == r0 && c == c0) continue;
        final key = '${getColumnName(c)}${r + 1}';
        _allCellData[_currentSheetName]?.remove(key);
      }
    }

    _allMergedCells[_currentSheetName] ??= [];
    _allMergedCells[_currentSheetName]!.add((r0, c0, r1, c1));
    _mergeIndex = null;
    _isModified = true;
    notifyListeners();
  }

  /// 선택 범위 내 병합 해제
  void unmergeCells() {
    _pushUndo();
    final r0 = _hasRange ? min(_selStartRow, _selEndRow) : _selectedRow;
    final r1 = _hasRange ? max(_selStartRow, _selEndRow) : _selectedRow;
    final c0 = _hasRange ? min(_selStartCol, _selEndCol) : _selectedCol;
    final c1 = _hasRange ? max(_selStartCol, _selEndCol) : _selectedCol;

    _allMergedCells[_currentSheetName]?.removeWhere((m) =>
        !(m.$3 < r0 || m.$1 > r1 || m.$4 < c0 || m.$2 > c1));
    _mergeIndex = null;
    _isModified = true;
    notifyListeners();
  }

  // ════════════════════════ 찾기 & 바꾸기 ════════════════════════

  List<(int, int)> _searchResults = [];
  int _searchIndex = -1;
  String _searchQuery = '';

  List<(int, int)> get searchResults => _searchResults;
  int get searchIndex => _searchIndex;
  String get searchQuery => _searchQuery;

  /// 현재 시트에서 검색
  void findAll(String query) {
    _searchQuery = query;
    if (query.isEmpty) {
      _searchResults = [];
      _searchIndex = -1;
      notifyListeners();
      return;
    }
    final q = query.toLowerCase();
    final results = <(int, int)>[];
    final data = _allCellData[_currentSheetName] ?? {};
    for (final entry in data.entries) {
      final ref = parseCellReference(entry.key);
      if (ref == null) continue;
      final display = getCellDisplay(ref.$1, ref.$2).toLowerCase();
      if (display.contains(q)) results.add(ref);
    }
    // 행 → 열 순으로 정렬
    results.sort((a, b) => a.$1 != b.$1 ? a.$1.compareTo(b.$1) : a.$2.compareTo(b.$2));
    _searchResults = results;
    _searchIndex = results.isNotEmpty ? 0 : -1;
    if (_searchIndex >= 0) {
      // Inline selection state to avoid double notifyListeners
      final pos = _searchResults[0];
      _selectedRow = pos.$1.clamp(0, _totalRows - 1);
      _selectedCol = pos.$2.clamp(0, _totalCols - 1);
      _selStartRow = _selectedRow;
      _selStartCol = _selectedCol;
      _selEndRow = _selectedRow;
      _selEndCol = _selectedCol;
      _hasRange = false;
      _isEditing = false;
    }
    notifyListeners();
  }

  /// 다음 검색 결과로 이동
  void findNext() {
    if (_searchResults.isEmpty) return;
    _searchIndex = (_searchIndex + 1) % _searchResults.length;
    final pos = _searchResults[_searchIndex];
    selectCell(pos.$1, pos.$2);
  }

  /// 이전 검색 결과로 이동
  void findPrev() {
    if (_searchResults.isEmpty) return;
    _searchIndex = (_searchIndex - 1 + _searchResults.length) % _searchResults.length;
    final pos = _searchResults[_searchIndex];
    selectCell(pos.$1, pos.$2);
  }

  /// 현재 매치 바꾸기
  void replaceOne(String query, String replacement) {
    if (_searchIndex < 0 || _searchIndex >= _searchResults.length) return;
    _pushUndo();
    final pos = _searchResults[_searchIndex];
    final raw = getCellRaw(pos.$1, pos.$2);
    if (!raw.startsWith('=')) {
      final newVal = raw.replaceAll(RegExp(RegExp.escape(query), caseSensitive: false), replacement);
      setCellValueDirect(pos.$1, pos.$2, newVal);
    }
    findAll(_searchQuery);
  }

  /// 전체 바꾸기
  void replaceAllMatches(String query, String replacement) {
    if (_searchResults.isEmpty) return;
    _pushUndo();
    for (final pos in _searchResults) {
      final raw = getCellRaw(pos.$1, pos.$2);
      if (!raw.startsWith('=')) {
        final newVal = raw.replaceAll(RegExp(RegExp.escape(query), caseSensitive: false), replacement);
        setCellValueDirect(pos.$1, pos.$2, newVal);
      }
    }
    findAll(_searchQuery);
  }

  /// 검색 초기화
  void clearSearch() {
    _searchResults = [];
    _searchIndex = -1;
    _searchQuery = '';
    notifyListeners();
  }

  /// undo 없이 셀 값 직접 설정 (일괄 바꾸기용)
  void setCellValueDirect(int row, int col, dynamic value) {
    final key = '${getColumnName(col)}${row + 1}';
    _allCellData[_currentSheetName] ??= {};
    if (value == null || (value is String && value.isEmpty)) {
      _allCellData[_currentSheetName]!.remove(key);
    } else {
      _allCellData[_currentSheetName]![key] = value;
    }
    _isModified = true;
  }

  // ════════════════════════ 틀 고정 ════════════════════════

  int _frozenRows = 0;
  int _frozenCols = 0;

  int get frozenRows => _frozenRows;
  int get frozenCols => _frozenCols;
  bool get hasFrozenPanes => _frozenRows > 0 || _frozenCols > 0;

  /// 현재 셀 기준으로 틀 고정 (해당 셀 위쪽 행 + 왼쪽 열 고정)
  void freezeAtCurrentCell() {
    _frozenRows = _selectedRow;
    _frozenCols = _selectedCol;
    notifyListeners();
  }

  /// 첫 행만 고정
  void freezeFirstRow() {
    _frozenRows = 1;
    _frozenCols = 0;
    notifyListeners();
  }

  /// 첫 열만 고정
  void freezeFirstCol() {
    _frozenRows = 0;
    _frozenCols = 1;
    notifyListeners();
  }

  /// 틀 고정 해제
  void unfreeze() {
    _frozenRows = 0;
    _frozenCols = 0;
    notifyListeners();
  }

  /// 고정 영역의 총 너비
  double get frozenWidth {
    double w = 0;
    for (int c = 0; c < _frozenCols; c++) {
      w += getColumnWidth(c);
    }
    return w;
  }

  /// 고정 영역의 총 높이
  double get frozenHeight {
    double h = 0;
    for (int r = 0; r < _frozenRows; r++) {
      h += getRowHeight(r);
    }
    return h;
  }

  // ════════════════════════ 내용 지우기 ════════════════════════

  /// 선택 영역의 내용만 지우기 (서식 유지)
  void clearSelectionContent() {
    _pushUndo();
    final r0 = _hasRange ? min(_selStartRow, _selEndRow) : _selectedRow;
    final r1 = _hasRange ? max(_selStartRow, _selEndRow) : _selectedRow;
    final c0 = _hasRange ? min(_selStartCol, _selEndCol) : _selectedCol;
    final c1 = _hasRange ? max(_selStartCol, _selEndCol) : _selectedCol;

    for (int r = r0; r <= r1; r++) {
      for (int c = c0; c <= c1; c++) {
        final key = '${getColumnName(c)}${r + 1}';
        _allCellData[_currentSheetName]?.remove(key);
      }
    }
    _isModified = true;
    notifyListeners();
  }

  // ════════════════════════ 행/열 숨기기 ════════════════════════

  void hideRow(int row) {
    _allHiddenRows[_currentSheetName] ??= {};
    _allHiddenRows[_currentSheetName]!.add(row);
    notifyListeners();
  }

  void unhideRow(int row) {
    _allHiddenRows[_currentSheetName]?.remove(row);
    notifyListeners();
  }

  void hideColumn(int col) {
    _allHiddenCols[_currentSheetName] ??= {};
    _allHiddenCols[_currentSheetName]!.add(col);
    notifyListeners();
  }

  void unhideColumn(int col) {
    _allHiddenCols[_currentSheetName]?.remove(col);
    notifyListeners();
  }

  /// 선택된 행 숨기기
  void hideSelectedRows() {
    final r0 = _hasRange ? min(_selStartRow, _selEndRow) : _selectedRow;
    final r1 = _hasRange ? max(_selStartRow, _selEndRow) : _selectedRow;
    _allHiddenRows[_currentSheetName] ??= {};
    for (int r = r0; r <= r1; r++) {
      _allHiddenRows[_currentSheetName]!.add(r);
    }
    notifyListeners();
  }

  /// 선택된 열 숨기기
  void hideSelectedCols() {
    final c0 = _hasRange ? min(_selStartCol, _selEndCol) : _selectedCol;
    final c1 = _hasRange ? max(_selStartCol, _selEndCol) : _selectedCol;
    _allHiddenCols[_currentSheetName] ??= {};
    for (int c = c0; c <= c1; c++) {
      _allHiddenCols[_currentSheetName]!.add(c);
    }
    notifyListeners();
  }

  /// 모든 숨긴 행 해제
  void unhideAllRows() {
    _allHiddenRows[_currentSheetName]?.clear();
    notifyListeners();
  }

  /// 모든 숨긴 열 해제
  void unhideAllCols() {
    _allHiddenCols[_currentSheetName]?.clear();
    notifyListeners();
  }

  // ════════════════════════ 서식 복사 (Format Painter) ════════════════════════

  void activateFormatPainter() {
    final fmt = getCellFormat(_selectedRow, _selectedCol);
    _formatPainterSource = fmt.copy();
    _isFormatPainterActive = true;
    notifyListeners();
  }

  void applyFormatPainter(int row, int col) {
    if (_formatPainterSource == null) return;
    _pushUndo();
    final key = '${getColumnName(col)}${row + 1}';
    _allCellFormats[_currentSheetName] ??= {};
    _allCellFormats[_currentSheetName]![key] = _formatPainterSource!.copy();
    _isFormatPainterActive = false;
    _formatPainterSource = null;
    _isModified = true;
    notifyListeners();
  }

  void cancelFormatPainter() {
    _isFormatPainterActive = false;
    _formatPainterSource = null;
    notifyListeners();
  }

  // ════════════════════════ 시트 순서 변경 ════════════════════════

  void reorderSheet(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex -= 1;
    final name = _sheetNames.removeAt(oldIndex);
    _sheetNames.insert(newIndex, name);
    _isModified = true;
    notifyListeners();
  }

  // ════════════════════════ 테두리 프리셋 적용 ════════════════════════

  void applyBorderPreset(BorderPreset preset) {
    _pushUndo();
    final r0 = _hasRange ? min(_selStartRow, _selEndRow) : _selectedRow;
    final r1 = _hasRange ? max(_selStartRow, _selEndRow) : _selectedRow;
    final c0 = _hasRange ? min(_selStartCol, _selEndCol) : _selectedCol;
    final c1 = _hasRange ? max(_selStartCol, _selEndCol) : _selectedCol;

    for (int r = r0; r <= r1; r++) {
      for (int c = c0; c <= c1; c++) {
        final key = '${getColumnName(c)}${r + 1}';
        _allCellFormats[_currentSheetName] ??= {};
        final old = _allCellFormats[_currentSheetName]![key] ?? CellFormat();

        CellBorders b;
        switch (preset) {
          case BorderPreset.none:
            b = const CellBorders.none();
          case BorderPreset.all:
            b = const CellBorders.all();
          case BorderPreset.outside:
            b = CellBorders(
              top: r == r0,
              bottom: r == r1,
              left: c == c0,
              right: c == c1,
            );
          case BorderPreset.bottom:
            b = CellBorders(bottom: r == r1);
          case BorderPreset.top:
            b = CellBorders(top: r == r0);
          case BorderPreset.leftRight:
            b = CellBorders(left: c == c0, right: c == c1);
        }

        _allCellFormats[_currentSheetName]![key] = old.copy()..borders = b;
      }
    }
    _isModified = true;
    notifyListeners();
  }

  // ════════════════════════ 조건부 서식 ════════════════════════

  /// 조건부 서식 규칙 추가 (현재 선택 영역에 적용)
  void addConditionalFormat(ConditionalFormatRule rule) {
    _allCondRules[_currentSheetName] ??= [];
    _allCondRules[_currentSheetName]!.add(rule);
    notifyListeners();
  }

  /// 조건부 서식 규칙 제거
  void removeConditionalFormat(String ruleId) {
    _allCondRules[_currentSheetName]?.removeWhere((r) => r.id == ruleId);
    notifyListeners();
  }

  /// 전체 조건부 서식 제거
  void clearConditionalFormats() {
    _allCondRules[_currentSheetName]?.clear();
    notifyListeners();
  }

  /// 셀에 적용될 조건부 서식 계산 (여러 규칙 중 첫 매치)
  CellFormat? getConditionalFormat(int row, int col) {
    final rules = _allCondRules[_currentSheetName];
    if (rules == null || rules.isEmpty) return null;
    final val = getCellValue(row, col);
    for (final rule in rules) {
      if (!rule.containsCell(row, col)) continue;
      if (rule.matches(val)) {
        return CellFormat(
          backgroundColor: rule.bgColor,
          textColor: rule.textColor,
          bold: rule.bold,
        );
      }
    }
    return null;
  }

  /// 데이터 바 비율 계산 (0.0~1.0, 숫자 셀 전용)
  /// 같은 열의 숫자 셀들 중 해당 셀의 상대적 위치를 반환.
  double? getDataBarInfo(int row, int col) {
    final val = getCellValue(row, col);
    final n = num.tryParse(val?.toString() ?? '');
    if (n == null) return null;

    // 같은 열의 모든 숫자 값을 수집
    final cells = _allCellData[_currentSheetName];
    if (cells == null) return null;
    final colName = getColumnName(col);
    double minVal = n.toDouble();
    double maxVal = n.toDouble();
    for (final key in cells.keys) {
      if (!key.startsWith(colName)) continue;
      final cv = cells[key];
      final cn = num.tryParse(cv?.toString() ?? '');
      if (cn == null) continue;
      if (cn < minVal) minVal = cn.toDouble();
      if (cn > maxVal) maxVal = cn.toDouble();
    }

    if (maxVal == minVal) return 1.0;
    return (n.toDouble() - minVal) / (maxVal - minVal);
  }

  // ════════════════════════ 셀 메모/댓글 ════════════════════════

  /// 셀에 메모가 있는지 확인
  bool hasComment(int row, int col) {
    final key = '${getColumnName(col)}${row + 1}';
    return _allCellComments[_currentSheetName]?.containsKey(key) ?? false;
  }

  /// 셀 메모 조회
  CellComment? getComment(int row, int col) {
    final key = '${getColumnName(col)}${row + 1}';
    return _allCellComments[_currentSheetName]?[key];
  }

  /// 셀 메모 추가/수정
  void setComment(int row, int col, String text) {
    final key = '${getColumnName(col)}${row + 1}';
    _allCellComments[_currentSheetName] ??= {};
    if (text.isEmpty) {
      _allCellComments[_currentSheetName]!.remove(key);
    } else {
      _allCellComments[_currentSheetName]![key] =
          CellComment(text: text);
    }
    _isModified = true;
    notifyListeners();
  }

  /// 셀 메모 삭제
  void removeComment(int row, int col) {
    final key = '${getColumnName(col)}${row + 1}';
    _allCellComments[_currentSheetName]?.remove(key);
    _isModified = true;
    notifyListeners();
  }

  // ════════════════════════ 자동 필터 ════════════════════════

  /// 자동 필터 설정 (현재 선택 행을 헤더로)
  void toggleAutoFilter() {
    if (_allAutoFilters[_currentSheetName] != null) {
      clearAutoFilter();
      return;
    }
    final c0 = _hasRange ? min(_selStartCol, _selEndCol) : 0;
    final c1 = _hasRange
        ? max(_selStartCol, _selEndCol)
        : _totalCols - 1;
    _allAutoFilters[_currentSheetName] = AutoFilterState(
      headerRow: _selectedRow,
      startCol: c0,
      endCol: c1,
    );
    notifyListeners();
  }

  /// 필터 해제
  void clearAutoFilter() {
    _allAutoFilters[_currentSheetName] = null;
    notifyListeners();
  }

  /// 특정 열의 필터 값 설정
  void setColumnFilter(int col, Set<String> values) {
    final filter = _allAutoFilters[_currentSheetName];
    if (filter == null) return;
    final newFilters = Map<int, Set<String>>.from(filter.activeFilters);
    if (values.isEmpty) {
      newFilters.remove(col);
    } else {
      newFilters[col] = values;
    }
    _allAutoFilters[_currentSheetName] =
        filter.copyWith(activeFilters: newFilters);
    notifyListeners();
  }

  /// 열의 고유 값 목록 (필터 UI용)
  List<String> getUniqueValuesForColumn(int col) {
    final data = _allCellData[_currentSheetName] ?? {};
    final filter = _allAutoFilters[_currentSheetName];
    final colName = getColumnName(col);
    final startRow = filter?.headerRow ?? 0;
    final values = <String>{};
    for (int r = startRow + 1; r < _totalRows; r++) {
      final key = '$colName${r + 1}';
      final val = data[key]?.toString() ?? '';
      if (val.isNotEmpty) values.add(val);
    }
    return values.toList()..sort();
  }

  /// 행이 현재 필터에 의해 표시되는지 확인
  bool isRowFilteredOut(int row) {
    final filter = _allAutoFilters[_currentSheetName];
    if (filter == null) return false;
    final data = _allCellData[_currentSheetName] ?? {};
    return !filter.isRowVisible(row, data, getColumnName);
  }

  // ════════════════════════ 차트 ════════════════════════

  /// 선택 영역에서 차트 데이터 추출 (라벨 + 값)
  /// 첫 열 = 라벨, 나머지 열 = 숫자 데이터
  (List<String>, List<double>) extractChartData() {
    final r0 = _hasRange ? min(_selStartRow, _selEndRow) : _selectedRow;
    final r1 = _hasRange ? max(_selStartRow, _selEndRow) : _selectedRow;
    final c0 = _hasRange ? min(_selStartCol, _selEndCol) : _selectedCol;
    final c1 = _hasRange ? max(_selStartCol, _selEndCol) : _selectedCol;

    final labels = <String>[];
    final values = <double>[];

    if (c1 > c0) {
      // 2열 이상: 첫 열 = 라벨, 두번째 열 = 값
      for (int r = r0; r <= r1; r++) {
        labels.add(getCellDisplay(r, c0));
        final v = num.tryParse(getCellRaw(r, c0 + 1));
        values.add(v?.toDouble() ?? 0);
      }
    } else {
      // 1열: 행 번호 = 라벨, 셀 값 = 값
      for (int r = r0; r <= r1; r++) {
        labels.add('${r + 1}');
        final v = num.tryParse(getCellRaw(r, c0));
        values.add(v?.toDouble() ?? 0);
      }
    }

    return (labels, values);
  }

  /// 차트 추가
  void addChart(Map<String, dynamic> chart) {
    _allCharts[_currentSheetName] ??= [];
    _allCharts[_currentSheetName]!.add(chart);
    _isModified = true;
    notifyListeners();
  }

  /// 차트 삭제
  void removeChart(String chartId) {
    _allCharts[_currentSheetName]
        ?.removeWhere((c) => c['id'] == chartId);
    _isModified = true;
    notifyListeners();
  }

  // ════════════════════════ 자동 채우기 (Auto Fill) ════════════════════════

  /// 현재 선택 영역을 소스로, targetRow/targetCol까지 자동 채우기
  void autoFill(int targetRow, int targetCol) {
    final r0 = _hasRange ? min(_selStartRow, _selEndRow) : _selectedRow;
    final r1 = _hasRange ? max(_selStartRow, _selEndRow) : _selectedRow;
    final c0 = _hasRange ? min(_selStartCol, _selEndCol) : _selectedCol;
    final c1 = _hasRange ? max(_selStartCol, _selEndCol) : _selectedCol;

    _pushUndo();

    if (targetRow > r1) {
      // ── 아래로 채우기 ──
      final srcRows = r1 - r0 + 1;
      for (int c = c0; c <= c1; c++) {
        // 소스 열 값 수집
        final srcVals = <dynamic>[];
        for (int r = r0; r <= r1; r++) {
          srcVals.add(getCellValue(r, c));
        }

        // 등차수열 감지
        final nums = srcVals
            .map((v) => num.tryParse(v?.toString() ?? ''))
            .toList();
        final allNum = nums.every((n) => n != null) && nums.isNotEmpty;
        double? delta;
        if (allNum && nums.length >= 2) {
          delta = (nums.last! - nums.first!) / (nums.length - 1);
          for (int i = 1; i < nums.length; i++) {
            if ((nums[i]! - nums[i - 1]! - delta!).abs() > SpreadsheetDefaults.floatEpsilon) {
              delta = null;
              break;
            }
          }
        }

        for (int r = r1 + 1; r <= targetRow; r++) {
          final idx = r - r1 - 1;
          dynamic val;
          if (delta != null && allNum) {
            final n = nums.last! + delta * (idx + 1);
            val = (n == n.roundToDouble()) ? n.toInt() : n;
          } else {
            val = srcVals[idx % srcRows];
          }
          setCellValueDirect(r, c, val);
          // 서식 복사
          final srcFmt = getCellFormat(r0 + (idx % srcRows), c);
          final key = '${getColumnName(c)}${r + 1}';
          _allCellFormats[_currentSheetName] ??= {};
          _allCellFormats[_currentSheetName]![key] = srcFmt.copy();
        }
      }
      // 선택 영역 확장
      _selEndRow = targetRow;
    } else if (targetCol > c1) {
      // ── 오른쪽으로 채우기 ──
      final srcCols = c1 - c0 + 1;
      for (int r = r0; r <= r1; r++) {
        final srcVals = <dynamic>[];
        for (int c = c0; c <= c1; c++) {
          srcVals.add(getCellValue(r, c));
        }

        final nums = srcVals
            .map((v) => num.tryParse(v?.toString() ?? ''))
            .toList();
        final allNum = nums.every((n) => n != null) && nums.isNotEmpty;
        double? delta;
        if (allNum && nums.length >= 2) {
          delta = (nums.last! - nums.first!) / (nums.length - 1);
          for (int i = 1; i < nums.length; i++) {
            if ((nums[i]! - nums[i - 1]! - delta!).abs() > SpreadsheetDefaults.floatEpsilon) {
              delta = null;
              break;
            }
          }
        }

        for (int c = c1 + 1; c <= targetCol; c++) {
          final idx = c - c1 - 1;
          dynamic val;
          if (delta != null && allNum) {
            final n = nums.last! + delta * (idx + 1);
            val = (n == n.roundToDouble()) ? n.toInt() : n;
          } else {
            val = srcVals[idx % srcCols];
          }
          setCellValueDirect(r, c, val);
          final srcFmt = getCellFormat(r, c0 + (idx % srcCols));
          final key = '${getColumnName(c)}${r + 1}';
          _allCellFormats[_currentSheetName] ??= {};
          _allCellFormats[_currentSheetName]![key] = srcFmt.copy();
        }
      }
      _selEndCol = targetCol;
    }

    _isModified = true;
    notifyListeners();
  }

  // ════════════════════════ 데이터 검증 ════════════════════════

  List<DataValidation> get validations =>
      List.unmodifiable(_allValidations[_currentSheetName] ?? []);

  /// 셀에 적용된 검증 규칙 조회
  DataValidation? getValidationForCell(int row, int col) {
    final rules = _allValidations[_currentSheetName];
    if (rules == null) return null;
    for (final v in rules) {
      if (v.containsCell(row, col)) return v;
    }
    return null;
  }

  /// 검증 규칙 추가
  void addValidation(DataValidation validation) {
    _allValidations[_currentSheetName] ??= [];
    // 기존에 동일 범위 규칙 제거
    _allValidations[_currentSheetName]!
        .removeWhere((v) => v.id == validation.id);
    _allValidations[_currentSheetName]!.add(validation);
    _isModified = true;
    notifyListeners();
  }

  /// 검증 규칙 삭제
  void removeValidation(String id) {
    _allValidations[_currentSheetName]?.removeWhere((v) => v.id == id);
    _isModified = true;
    notifyListeners();
  }

  /// 셀 값 설정 시 검증 (실패 시 false 반환)
  bool setCellValueWithValidation(int row, int col, dynamic value) {
    final rule = getValidationForCell(row, col);
    if (rule != null && !rule.validate(value)) {
      return false; // 검증 실패
    }
    setCellValue(row, col, value);
    return true;
  }

  // ════════════════════════ 명명 범위 ════════════════════════

  Map<String, String> get namedRanges => Map.unmodifiable(_namedRanges);

  /// 명명 범위 추가/수정
  void setNamedRange(String name, String range) {
    _namedRanges[name] = range;
    _isModified = true;
    notifyListeners();
  }

  /// 명명 범위 삭제
  void removeNamedRange(String name) {
    _namedRanges.remove(name);
    _isModified = true;
    notifyListeners();
  }

  /// 명명 범위 해석: 이름 → 범위 문자열
  String? resolveNamedRange(String name) => _namedRanges[name.toUpperCase()];

  // ════════════════════════ 하이퍼링크 ════════════════════════

  Map<String, String> get hyperlinks =>
      Map.unmodifiable(_allHyperlinks[_currentSheetName] ?? {});

  /// 하이퍼링크 설정
  void setHyperlink(int row, int col, String url) {
    final key = '${getColumnName(col)}${row + 1}';
    _allHyperlinks[_currentSheetName] ??= {};
    _allHyperlinks[_currentSheetName]![key] = url;
    _isModified = true;
    notifyListeners();
  }

  /// 하이퍼링크 삭제
  void removeHyperlink(int row, int col) {
    final key = '${getColumnName(col)}${row + 1}';
    _allHyperlinks[_currentSheetName]?.remove(key);
    _isModified = true;
    notifyListeners();
  }

  /// 하이퍼링크 조회
  String? getHyperlink(int row, int col) {
    final key = '${getColumnName(col)}${row + 1}';
    return _allHyperlinks[_currentSheetName]?[key];
  }

  // ════════════════════════ CSV 내보내기 ════════════════════════

  /// 현재 시트를 CSV 문자열로 변환
  String exportCsv() {
    final data = _allCellData[_currentSheetName] ?? {};
    if (data.isEmpty) return '';

    int maxRow = 0;
    int maxCol = 0;
    for (final key in data.keys) {
      final match = RegExp(r'^([A-Z]+)(\d+)$').firstMatch(key);
      if (match != null) {
        final col = _colNameToIndex(match.group(1)!);
        final row = int.parse(match.group(2)!) - 1;
        if (row > maxRow) maxRow = row;
        if (col > maxCol) maxCol = col;
      }
    }

    final sb = StringBuffer();
    for (int r = 0; r <= maxRow; r++) {
      final row = <String>[];
      for (int c = 0; c <= maxCol; c++) {
        final display = getCellDisplay(r, c);
        // CSV 이스케이프: 쉼표, 줄바꿈, 따옴표 포함 시 감싸기
        if (display.contains(',') || display.contains('\n') || display.contains('"')) {
          row.add('"${display.replaceAll('"', '""')}"');
        } else {
          row.add(display);
        }
      }
      sb.writeln(row.join(','));
    }
    return sb.toString();
  }

  int _colNameToIndex(String colName) {
    int result = 0;
    for (int i = 0; i < colName.length; i++) {
      result = result * 26 + (colName.codeUnitAt(i) - 64);
    }
    return result - 1;
  }

  // ════════════════════════ 수식 캐싱 ════════════════════════

  /// 캐시 무효화
  void invalidateFormulaCache() {
    _formulaCache[_currentSheetName]?.clear();
  }

  // ════════════════════════ 피벗 테이블 ════════════════════════

  /// 데이터가 있는 범위를 자동 감지
  (int startRow, int endRow, int startCol, int endCol) detectDataRange() {
    final data = _allCellData[_currentSheetName] ?? {};
    if (data.isEmpty) return (0, 0, 0, 0);
    int minR = 999999, maxR = 0, minC = 999999, maxC = 0;
    for (final key in data.keys) {
      // key format: "A1", "B2", "AA10" etc.
      final match = RegExp(r'^([A-Z]+)(\d+)$').firstMatch(key);
      if (match == null) continue;
      final colStr = match.group(1)!;
      final row = int.parse(match.group(2)!) - 1;
      int col = 0;
      for (int i = 0; i < colStr.length; i++) {
        col = col * 26 + (colStr.codeUnitAt(i) - 65 + 1);
      }
      col -= 1;
      if (row < minR) minR = row;
      if (row > maxR) maxR = row;
      if (col < minC) minC = col;
      if (col > maxC) maxC = col;
    }
    if (minR > maxR) return (0, 0, 0, 0);
    return (minR, maxR, minC, maxC);
  }

  /// 헤더 행의 열 이름을 추출
  List<String> getHeaderNames(int startRow, int startCol, int endCol) {
    return [
      for (int c = startCol; c <= endCol; c++) getCellDisplay(startRow, c),
    ];
  }

  /// 피벗 테이블 생성 → 새 시트에 결과 출력
  void createPivotTable(PivotTableConfig config) {
    final result = PivotEngine.calculate(
      config,
      _allCellData[_currentSheetName] ?? {},
      getColumnName,
    );

    // 고유 시트 이름 생성
    String pivotName = 'Pivot';
    int counter = 1;
    while (_sheetNames.contains('${pivotName}_$counter')) {
      counter++;
    }
    pivotName = '${pivotName}_$counter';

    // 새 시트 생성
    addSheet(pivotName);

    // 헤더 행 작성
    final headerLabel = getCellDisplay(config.startRow, config.rowField);
    _setCellDirect(0, 0, headerLabel);
    _setCellFormatDirect(0, 0, CellFormat(bold: true));
    for (int c = 0; c < result.columnHeaders.length; c++) {
      _setCellDirect(0, c + 1, result.columnHeaders[c]);
      _setCellFormatDirect(0, c + 1, CellFormat(bold: true));
    }

    // 데이터 행 작성
    for (int r = 0; r < result.rows.length; r++) {
      _setCellDirect(r + 1, 0, result.rows[r].label);
      for (int c = 0; c < result.rows[r].values.length; c++) {
        _setCellDirect(r + 1, c + 1, result.rows[r].values[c]);
      }
    }

    _isModified = true;
    notifyListeners();
  }

  /// 내부 헬퍼 — undo 없이 직접 셀 값 설정
  void _setCellDirect(int row, int col, dynamic value) {
    final key = '${getColumnName(col)}${row + 1}';
    _allCellData[_currentSheetName] ??= {};
    _allCellData[_currentSheetName]![key] = value;
  }

  /// 내부 헬퍼 — 직접 셀 서식 설정
  void _setCellFormatDirect(int row, int col, CellFormat fmt) {
    final key = '${getColumnName(col)}${row + 1}';
    _allCellFormats[_currentSheetName] ??= {};
    _allCellFormats[_currentSheetName]![key] = fmt;
  }

  @override
  void dispose() {
    _workbook?.dispose();
    super.dispose();
  }
}
