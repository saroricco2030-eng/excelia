import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:xml/xml.dart';
import 'package:excelia/utils/constants.dart';

/// 셀 서식 정보
class FallbackCellStyle {
  final bool bold;
  final bool italic;
  final bool underline;
  final double? fontSize;
  final String? fontFamily;
  final String? fontColorHex;   // "FF0000" 등
  final String? bgColorHex;
  final String? horizontalAlign; // "left", "center", "right"
  final bool wrapText;

  const FallbackCellStyle({
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.fontSize,
    this.fontFamily,
    this.fontColorHex,
    this.bgColorHex,
    this.horizontalAlign,
    this.wrapText = false,
  });
}

/// 시트별 레이아웃 정보
class FallbackSheetLayout {
  final Map<int, double> colWidths;   // 0-based col → pixel width
  final Map<int, double> rowHeights;  // 0-based row → pixel height
  final List<(int, int, int, int)> mergedCells; // (startRow, startCol, endRow, endCol)
  double? defaultColWidthPx;   // Excel 파일에 지정된 기본 열 너비 (픽셀)
  double? defaultRowHeightPx;  // Excel 파일에 지정된 기본 행 높이 (픽셀)

  FallbackSheetLayout()
      : colWidths = {},
        rowHeights = {},
        mergedCells = [];
}

/// excel 패키지가 파싱에 실패했을 때 사용하는 fallback 파서.
/// xlsx(ZIP/XML) 구조에서 셀 데이터 + 서식 + 레이아웃을 직접 추출한다.
class XlsxFallbackParser {
  final Map<String, Map<String, String>> sheets = {};
  final Map<String, Map<String, FallbackCellStyle>> sheetStyles = {};
  final Map<String, FallbackSheetLayout> sheetLayouts = {};
  final List<String> sheetNames = [];

  /// bytes 로부터 xlsx 데이터를 파싱한다.
  bool parse(Uint8List bytes) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final sharedStrings = _parseSharedStrings(archive);
      final styles = _parseStyles(archive);
      final sheetEntries = _parseWorkbook(archive);

      for (final entry in sheetEntries) {
        final sheetName = entry.name;
        sheetNames.add(sheetName);

        final result = _parseSheet(archive, entry.path, sharedStrings, styles);
        sheets[sheetName] = result.cells;
        sheetStyles[sheetName] = result.styles;
        sheetLayouts[sheetName] = result.layout;
      }

      return sheetNames.isNotEmpty;
    } catch (e) {
      debugPrint('XLSX parse failed: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // Shared Strings
  // ═══════════════════════════════════════════════════════════════════

  List<String> _parseSharedStrings(Archive archive) {
    final strings = <String>[];
    final file = _findFile(archive, 'xl/sharedStrings.xml');
    if (file == null) return strings;

    try {
      final content = _readXml(file);
      final doc = XmlDocument.parse(content);
      final ns = doc.rootElement.name.namespaceUri ?? '';

      for (final si in doc.rootElement.findAllElements('si', namespace: ns)) {
        final buf = StringBuffer();
        for (final t in si.findAllElements('t', namespace: ns)) {
          buf.write(t.innerText);
        }
        strings.add(buf.toString());
      }
    } catch (e) {
      debugPrint('XLSX shared strings parse failed: $e');
    }
    return strings;
  }

  // ═══════════════════════════════════════════════════════════════════
  // Styles (xl/styles.xml)
  // ═══════════════════════════════════════════════════════════════════

  _StyleTable _parseStyles(Archive archive) {
    final table = _StyleTable();
    final file = _findFile(archive, 'xl/styles.xml');
    if (file == null) return table;

    try {
      final content = _readXml(file);
      final doc = XmlDocument.parse(content);
      final ns = doc.rootElement.name.namespaceUri ?? '';

      // ── fonts ──
      final fontsNode = doc.rootElement.findAllElements('fonts', namespace: ns).firstOrNull;
      if (fontsNode != null) {
        for (final font in fontsNode.findAllElements('font', namespace: ns)) {
          final f = _FontInfo();
          f.bold = font.findAllElements('b', namespace: ns).isNotEmpty;
          f.italic = font.findAllElements('i', namespace: ns).isNotEmpty;
          f.underline = font.findAllElements('u', namespace: ns).isNotEmpty;

          final sz = font.findAllElements('sz', namespace: ns).firstOrNull;
          if (sz != null) f.size = double.tryParse(sz.getAttribute('val') ?? '');

          final name = font.findAllElements('name', namespace: ns).firstOrNull;
          if (name != null) f.family = name.getAttribute('val');

          final color = font.findAllElements('color', namespace: ns).firstOrNull;
          if (color != null) {
            f.colorHex = color.getAttribute('rgb');
            // theme / indexed 색상은 복잡하므로 rgb만 처리
          }

          table.fonts.add(f);
        }
      }

      // ── fills ──
      final fillsNode = doc.rootElement.findAllElements('fills', namespace: ns).firstOrNull;
      if (fillsNode != null) {
        for (final fill in fillsNode.findAllElements('fill', namespace: ns)) {
          String? bgHex;
          final patternFill = fill.findAllElements('patternFill', namespace: ns).firstOrNull;
          if (patternFill != null) {
            final fgColor = patternFill.findAllElements('fgColor', namespace: ns).firstOrNull;
            final bgColor = patternFill.findAllElements('bgColor', namespace: ns).firstOrNull;
            bgHex = fgColor?.getAttribute('rgb') ?? bgColor?.getAttribute('rgb');
          }
          table.fillColors.add(bgHex);
        }
      }

      // ── numFmts (커스텀 날짜 포맷 감지) ──
      final numFmtsNode = doc.rootElement.findAllElements('numFmts', namespace: ns).firstOrNull;
      if (numFmtsNode != null) {
        for (final nf in numFmtsNode.findAllElements('numFmt', namespace: ns)) {
          final id = int.tryParse(nf.getAttribute('numFmtId') ?? '') ?? 0;
          final code = (nf.getAttribute('formatCode') ?? '').toLowerCase();
          // 날짜/시간 관련 토큰이 있으면 날짜 포맷으로 판단
          if (code.contains('y') || code.contains('m') || code.contains('d') ||
              code.contains('h') || code.contains('s') ||
              code.contains('am') || code.contains('pm')) {
            // 'm'이 숫자 포맷(#,##0)에서도 나올 수 있으므로 'd' 또는 'y'가 동반되는지 체크
            if (code.contains('y') || code.contains('d') || code.contains('h') || code.contains('s')) {
              table.dateNumFmtIds.add(id);
            }
          }
        }
      }

      // ── cellXfs (셀 서식 인덱스 → font/fill/alignment/numFmt 매핑) ──
      final cellXfs = doc.rootElement.findAllElements('cellXfs', namespace: ns).firstOrNull;
      if (cellXfs != null) {
        for (final xf in cellXfs.findAllElements('xf', namespace: ns)) {
          final cxf = _CellXf();
          cxf.fontId = int.tryParse(xf.getAttribute('fontId') ?? '') ?? 0;
          cxf.fillId = int.tryParse(xf.getAttribute('fillId') ?? '') ?? 0;
          cxf.numFmtId = int.tryParse(xf.getAttribute('numFmtId') ?? '') ?? 0;

          final alignment = xf.findAllElements('alignment', namespace: ns).firstOrNull;
          if (alignment != null) {
            cxf.horizontal = alignment.getAttribute('horizontal');
            cxf.wrapText = alignment.getAttribute('wrapText') == '1';
          }

          table.cellXfs.add(cxf);
        }
      }
    } catch (e) {
      debugPrint('XLSX styles parse failed: $e');
    }
    return table;
  }

  // ═══════════════════════════════════════════════════════════════════
  // Workbook
  // ═══════════════════════════════════════════════════════════════════

  List<_SheetEntry> _parseWorkbook(Archive archive) {
    final entries = <_SheetEntry>[];
    final wbFile = _findFile(archive, 'xl/workbook.xml');
    if (wbFile == null) return entries;

    try {
      final content = _readXml(wbFile);
      final doc = XmlDocument.parse(content);
      final ns = doc.rootElement.name.namespaceUri ?? '';
      final relsMap = _parseRels(archive, 'xl/_rels/workbook.xml.rels');

      for (final sheet in doc.rootElement.findAllElements('sheet', namespace: ns)) {
        final name = sheet.getAttribute('name') ?? 'Sheet';
        final rId = sheet.getAttribute('id',
                namespace: 'http://schemas.openxmlformats.org/officeDocument/2006/relationships')
            ?? sheet.getAttribute('r:id')
            ?? '';

        final target = relsMap[rId];
        if (target != null) {
          final path = target.startsWith('/') ? target.substring(1) : 'xl/$target';
          entries.add(_SheetEntry(name, path));
        }
      }
    } catch (e) {
      debugPrint('XLSX workbook parse failed: $e');
    }

    if (entries.isEmpty) {
      for (int i = 1; i <= 10; i++) {
        final path = 'xl/worksheets/sheet$i.xml';
        if (_findFile(archive, path) != null) {
          entries.add(_SheetEntry('Sheet$i', path));
        }
      }
    }

    return entries;
  }

  Map<String, String> _parseRels(Archive archive, String relsPath) {
    final map = <String, String>{};
    final file = _findFile(archive, relsPath);
    if (file == null) return map;

    try {
      final content = _readXml(file);
      final doc = XmlDocument.parse(content);
      for (final rel in doc.rootElement.findAllElements('Relationship')) {
        final id = rel.getAttribute('Id') ?? '';
        final target = rel.getAttribute('Target') ?? '';
        if (id.isNotEmpty && target.isNotEmpty) {
          map[id] = target;
        }
      }
    } catch (e) {
      debugPrint('XLSX rels parse failed: $e');
    }
    return map;
  }

  // ═══════════════════════════════════════════════════════════════════
  // Sheet (셀 데이터 + 서식 + 열너비/행높이/병합)
  // ═══════════════════════════════════════════════════════════════════

  _SheetResult _parseSheet(
      Archive archive, String sheetPath, List<String> sharedStrings, _StyleTable styleTable) {
    final cells = <String, String>{};
    final styles = <String, FallbackCellStyle>{};
    final layout = FallbackSheetLayout();

    final file = _findFile(archive, sheetPath);
    if (file == null) return _SheetResult(cells, styles, layout);

    try {
      final content = _readXml(file);
      final doc = XmlDocument.parse(content);
      final ns = doc.rootElement.name.namespaceUri ?? '';

      // ── 기본 열/행 크기: <sheetFormatPr defaultColWidth="..." defaultRowHeight="..."/> ──
      final sheetFmt = doc.rootElement.findAllElements('sheetFormatPr', namespace: ns).firstOrNull;
      if (sheetFmt != null) {
        final defColW = double.tryParse(sheetFmt.getAttribute('defaultColWidth') ?? '');
        if (defColW != null && defColW > 0) {
          layout.defaultColWidthPx = (defColW * XlsxParserDefaults.colWidthToPixel).clamp(XlsxParserDefaults.minColWidthPx, XlsxParserDefaults.maxColWidthPx);
        }
        final defRowH = double.tryParse(sheetFmt.getAttribute('defaultRowHeight') ?? '');
        if (defRowH != null && defRowH > 0) {
          layout.defaultRowHeightPx = (defRowH * XlsxParserDefaults.rowHeightToPixel).clamp(XlsxParserDefaults.minRowHeightPx, XlsxParserDefaults.maxRowHeightPx);
        }
      }

      // ── 열 너비: <cols><col min="1" max="3" width="15.5" .../></cols> ──
      for (final cols in doc.rootElement.findAllElements('cols', namespace: ns)) {
        for (final col in cols.findAllElements('col', namespace: ns)) {
          final minCol = int.tryParse(col.getAttribute('min') ?? '') ?? 0;
          final maxCol = int.tryParse(col.getAttribute('max') ?? '') ?? minCol;
          final width = double.tryParse(col.getAttribute('width') ?? '');
          if (width != null && width > 0) {
            final pixelWidth = (width * XlsxParserDefaults.colWidthToPixel).clamp(XlsxParserDefaults.minColWidthPx, XlsxParserDefaults.maxColWidthPx);
            for (int c = minCol; c <= maxCol && c <= XlsxParserDefaults.maxColumns; c++) {
              layout.colWidths[c - 1] = pixelWidth; // XML은 1-based
            }
          }
        }
      }

      // ── 병합 셀: <mergeCells><mergeCell ref="A1:C3"/></mergeCells> ──
      for (final mc in doc.rootElement.findAllElements('mergeCells', namespace: ns)) {
        for (final cell in mc.findAllElements('mergeCell', namespace: ns)) {
          final ref = cell.getAttribute('ref') ?? '';
          final parts = ref.split(':');
          if (parts.length == 2) {
            final s = _parseCellRef(parts[0]);
            final e = _parseCellRef(parts[1]);
            if (s != null && e != null) {
              layout.mergedCells.add((s.$1, s.$2, e.$1, e.$2));
            }
          }
        }
      }

      // ── 행/셀 데이터 ──
      for (final row in doc.rootElement.findAllElements('row', namespace: ns)) {
        // 행 높이: <row r="1" ht="25.5" customHeight="1">
        final rowNum = int.tryParse(row.getAttribute('r') ?? '') ?? 0;
        final ht = double.tryParse(row.getAttribute('ht') ?? '');
        if (ht != null && ht > 0 && rowNum > 0) {
          layout.rowHeights[rowNum - 1] = (ht * XlsxParserDefaults.rowHeightToPixel).clamp(XlsxParserDefaults.minRowHeightPx, XlsxParserDefaults.maxRowHeightPx);
        }

        for (final c in row.findAllElements('c', namespace: ns)) {
          final ref = c.getAttribute('r') ?? '';
          if (ref.isEmpty) continue;

          // ── 값 추출 ──
          final type = c.getAttribute('t') ?? '';
          final vNode = c.findElements('v', namespace: ns).firstOrNull;
          final isNode = c.findElements('is', namespace: ns).firstOrNull;

          String value = '';
          if (type == 's' && vNode != null) {
            final idx = int.tryParse(vNode.innerText) ?? -1;
            if (idx >= 0 && idx < sharedStrings.length) {
              value = sharedStrings[idx];
            }
          } else if (type == 'inlineStr' && isNode != null) {
            final buf = StringBuffer();
            for (final t in isNode.findAllElements('t', namespace: ns)) {
              buf.write(t.innerText);
            }
            value = buf.toString();
          } else if (vNode != null) {
            value = vNode.innerText;
          }

          // ── 날짜 변환: 숫자값 + 날짜 포맷이면 serial → 날짜 문자열 ──
          final styleIdx = int.tryParse(c.getAttribute('s') ?? '');
          if (value.isNotEmpty && type != 's' && type != 'inlineStr' && styleIdx != null) {
            final numVal = double.tryParse(value);
            if (numVal != null && styleIdx < styleTable.cellXfs.length) {
              final numFmtId = styleTable.cellXfs[styleIdx].numFmtId;
              if (styleTable.isDateFormat(numFmtId)) {
                value = _excelSerialToDate(numVal);
              }
            }
          }

          if (value.isNotEmpty) {
            cells[ref] = value;
          }

          // ── 서식 추출: s 속성 → cellXfs 인덱스 ──
          if (styleIdx != null && styleIdx < styleTable.cellXfs.length) {
            final xf = styleTable.cellXfs[styleIdx];
            final font = xf.fontId < styleTable.fonts.length
                ? styleTable.fonts[xf.fontId]
                : null;
            final bgHex = xf.fillId < styleTable.fillColors.length
                ? styleTable.fillColors[xf.fillId]
                : null;

            if (font != null || bgHex != null || xf.horizontal != null || xf.wrapText) {
              styles[ref] = FallbackCellStyle(
                bold: font?.bold ?? false,
                italic: font?.italic ?? false,
                underline: font?.underline ?? false,
                fontSize: font?.size,
                fontFamily: font?.family,
                fontColorHex: font?.colorHex,
                bgColorHex: bgHex,
                horizontalAlign: xf.horizontal,
                wrapText: xf.wrapText,
              );
            }
          }
        }
      }
    } catch (e) {
      debugPrint('XLSX sheet parse failed: $e');
    }
    return _SheetResult(cells, styles, layout);
  }

  // ═══════════════════════════════════════════════════════════════════
  // Helpers
  // ═══════════════════════════════════════════════════════════════════

  /// Excel serial number → "YYYY-MM-DD" (또는 시간 포함 시 "YYYY-MM-DD HH:mm")
  static String _excelSerialToDate(double serial) {
    // Excel epoch: 1899-12-30 (1900 날짜 시스템, 1900-02-29 버그 포함)
    final days = serial.truncate();
    final timeFraction = serial - days;

    // 1900-02-29 버그 보정: serial 60 이하는 1일 보정 불필요, 초과면 -1
    final correctedDays = days > 59 ? days - 1 : days;
    final epoch = DateTime(1899, 12, 30);
    final date = epoch.add(Duration(days: correctedDays));

    final y = date.year.toString();
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');

    if (timeFraction > 0.0001) {
      final totalMinutes = (timeFraction * 24 * 60).round();
      final h = (totalMinutes ~/ 60).toString().padLeft(2, '0');
      final min = (totalMinutes % 60).toString().padLeft(2, '0');
      return '$y-$m-$d $h:$min';
    }
    return '$y-$m-$d';
  }

  String _readXml(ArchiveFile file) {
    return utf8.decode(file.content as List<int>, allowMalformed: true);
  }

  ArchiveFile? _findFile(Archive archive, String path) {
    final normalized = path.replaceAll('\\', '/').toLowerCase();
    for (final file in archive.files) {
      if (file.name.replaceAll('\\', '/').toLowerCase() == normalized) {
        return file;
      }
    }
    return null;
  }

  /// "A1" → (row: 0, col: 0), "C12" → (row: 11, col: 2)
  static (int, int)? _parseCellRef(String ref) {
    final match = RegExp(r'^([A-Z]+)(\d+)$').firstMatch(ref.toUpperCase());
    if (match == null) return null;
    final letters = match.group(1)!;
    final row = int.parse(match.group(2)!) - 1;
    int col = 0;
    for (int i = 0; i < letters.length; i++) {
      col = col * 26 + (letters.codeUnitAt(i) - 64);
    }
    return (row, col - 1);
  }
}

// ─── Internal data classes ─────────────────────────────────────────

class _SheetEntry {
  final String name;
  final String path;
  _SheetEntry(this.name, this.path);
}

class _SheetResult {
  final Map<String, String> cells;
  final Map<String, FallbackCellStyle> styles;
  final FallbackSheetLayout layout;
  _SheetResult(this.cells, this.styles, this.layout);
}

class _StyleTable {
  final List<_FontInfo> fonts = [];
  final List<String?> fillColors = []; // ARGB hex or null
  final List<_CellXf> cellXfs = [];
  final Set<int> dateNumFmtIds = {};  // 날짜 형식 numFmtId 집합

  /// 빌트인 Excel 날짜 포맷 ID (14~22, 27~36, 45~47, 50~58)
  static const _builtinDateFmtIds = <int>{
    14, 15, 16, 17, 18, 19, 20, 21, 22,
    27, 28, 29, 30, 31, 32, 33, 34, 35, 36,
    45, 46, 47, 50, 51, 52, 53, 54, 55, 56, 57, 58,
  };

  bool isDateFormat(int numFmtId) {
    return _builtinDateFmtIds.contains(numFmtId) || dateNumFmtIds.contains(numFmtId);
  }
}

class _FontInfo {
  bool bold = false;
  bool italic = false;
  bool underline = false;
  double? size;
  String? family;
  String? colorHex; // ARGB hex
}

class _CellXf {
  int fontId = 0;
  int fillId = 0;
  int numFmtId = 0;
  String? horizontal; // "left", "center", "right"
  bool wrapText = false;
}
