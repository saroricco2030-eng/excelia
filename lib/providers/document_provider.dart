import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:excelia/models/print_setup.dart';
import 'package:excelia/utils/constants.dart';
import 'package:excelia/utils/docx_parser.dart';
import 'package:excelia/utils/docx_writer.dart';

class DocumentProvider extends ChangeNotifier {
  quill.QuillController _controller = quill.QuillController.basic();
  StreamSubscription? _changesSub;
  String _title = 'Untitled Document';
  String? _filePath;
  bool _isDirty = false;
  bool _isSaving = false;
  DateTime? _lastSavedAt;

  // Page setup + headers/footers
  PrintSetup _pageSetup = const PrintSetup(isLandscape: false);
  String _headerText = '';
  String _footerText = '';

  // Cached computed values (invalidated on change)
  String? _cachedPlainText;
  int? _cachedWordCount;
  int? _cachedCharCount;

  // Getters
  quill.QuillController get controller => _controller;
  String get title => _title;
  PrintSetup get pageSetup => _pageSetup;
  String get headerText => _headerText;
  String get footerText => _footerText;
  String? get filePath => _filePath;
  bool get isDirty => _isDirty;
  bool get isSaving => _isSaving;
  DateTime? get lastSavedAt => _lastSavedAt;

  String get plainText => _cachedPlainText ??= _controller.document.toPlainText();

  int get wordCount => _cachedWordCount ??= _computeWordCount();

  int _computeWordCount() {
    final text = plainText.trim();
    if (text.isEmpty) return 0;
    // Count both Korean characters and space-separated words
    final korean = RegExp(r'[\uAC00-\uD7AF]');
    final koreanCount = korean.allMatches(text).length;
    final nonKorean = text.replaceAll(korean, ' ').trim();
    final wordList =
        nonKorean.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    return koreanCount + wordList.length;
  }

  int get characterCount => _cachedCharCount ??= plainText.replaceAll('\n', '').length;

  int get characterCountWithSpaces => plainText.length;

  int get pageEstimate => (wordCount / DocumentDefaults.wordsPerPage).ceil().clamp(1, 999);

  int get readingTimeMinutes {
    final wc = wordCount;
    if (wc == 0) return 0;
    return (wc / DocumentDefaults.wordsPerMinute).ceil().clamp(1, 999);
  }

  void _invalidateCache() {
    _cachedPlainText = null;
    _cachedWordCount = null;
    _cachedCharCount = null;
  }

  // Methods

  void createNew({String? defaultTitle}) {
    _controller.dispose();
    _controller = quill.QuillController.basic();
    _title = defaultTitle ?? 'Untitled Document';
    _filePath = null;
    _isDirty = false;
    _invalidateCache();
    _setupListener();
    notifyListeners();
  }

  void createFromTemplate(String type) {
    switch (type) {
      case 'letter':
        _title = 'Letter';
        final date = DateTime.now();
        final dateStr =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        final content = '$dateStr\n\nDear Recipient,\n\n'
            'I am writing to inform you about...\n\n'
            'Sincerely,\nYour Name\n';
        _controller.document.insert(0, content);
      case 'report':
        _title = 'Report';
        const content = 'Report Title\n\n'
            'Introduction\n'
            'Provide background information and purpose of this report.\n\n'
            'Findings\n'
            'Describe the main findings and analysis.\n\n'
            'Conclusion\n'
            'Summarize results and recommendations.\n';
        _controller.document.insert(0, content);
        // Apply heading formats
        _controller.document.format(0, 'Report Title'.length, quill.Attribute.h1);
        _controller.document.format(
            'Report Title\n\n'.length, 'Introduction'.length, quill.Attribute.h2);
        _controller.document.format(
            'Report Title\n\nIntroduction\nProvide background information and purpose of this report.\n\n'
                    .length,
            'Findings'.length,
            quill.Attribute.h2);
        _controller.document.format(
            'Report Title\n\nIntroduction\nProvide background information and purpose of this report.\n\nFindings\nDescribe the main findings and analysis.\n\n'
                    .length,
            'Conclusion'.length,
            quill.Attribute.h2);
      case 'resume':
        _title = 'Resume';
        const content = 'Your Name\n'
            'email@example.com | (000) 000-0000\n\n'
            'Experience\n'
            'Company Name — Position\n'
            'Description of role and achievements.\n\n'
            'Education\n'
            'University Name — Degree\n'
            'Graduation year and relevant details.\n\n'
            'Skills\n'
            'List your key skills here.\n';
        _controller.document.insert(0, content);
        _controller.document.format(0, 'Your Name'.length, quill.Attribute.h1);
        _controller.document.format(
            'Your Name\nemail@example.com | (000) 000-0000\n\n'.length,
            'Experience'.length,
            quill.Attribute.h2);
        _controller.document.format(
            'Your Name\nemail@example.com | (000) 000-0000\n\nExperience\nCompany Name — Position\nDescription of role and achievements.\n\n'
                    .length,
            'Education'.length,
            quill.Attribute.h2);
        _controller.document.format(
            'Your Name\nemail@example.com | (000) 000-0000\n\nExperience\nCompany Name — Position\nDescription of role and achievements.\n\nEducation\nUniversity Name — Degree\nGraduation year and relevant details.\n\n'
                    .length,
            'Skills'.length,
            quill.Attribute.h2);
    }
    _invalidateCache();
    _isDirty = true;
    notifyListeners();
  }

  void _setupListener() {
    _changesSub?.cancel();
    _changesSub = _controller.document.changes.listen((_) {
      _invalidateCache();
      if (!_isDirty) {
        _isDirty = true;
        notifyListeners();
      }
    });
  }

  void setTitle(String newTitle) {
    if (newTitle.trim().isEmpty) return;
    _title = newTitle.trim();
    _isDirty = true;
    notifyListeners();
  }

  Future<void> loadFromFile(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        throw Exception('File not found: $path');
      }
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;

      _controller.dispose();
      final doc = quill.Document.fromJson(json['content'] as List<dynamic>);
      _controller = quill.QuillController(
        document: doc,
        selection: const TextSelection.collapsed(offset: 0),
      );
      _title = json['title'] as String? ?? 'Untitled Document';
      _filePath = path;
      _isDirty = false;
      _invalidateCache();
      _setupListener();
      notifyListeners();
    } catch (e) {
      debugPrint('문서 로드 실패: $e');
      rethrow;
    }
  }

  Future<String> saveToFile([String? path]) async {
    _isSaving = true;
    notifyListeners();

    try {
      final savePath = path ?? _filePath ?? await _getDefaultPath();
      final json = {
        'title': _title,
        'content': _controller.document.toDelta().toJson(),
        'modified': DateTime.now().toIso8601String(),
      };
      final file = File(savePath);
      await file.writeAsString(jsonEncode(json));
      _filePath = savePath;
      _isDirty = false;
      _lastSavedAt = DateTime.now();
      return savePath;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<String> _getDefaultPath() async {
    final dir = await getApplicationDocumentsDirectory();
    final sanitized = _title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    return '${dir.path}/$sanitized.exdoc';
  }

  void setPageSetup(PrintSetup setup) {
    _pageSetup = setup;
    notifyListeners();
  }

  void setHeaderText(String text) {
    _headerText = text;
    notifyListeners();
  }

  void setFooterText(String text) {
    _footerText = text;
    notifyListeners();
  }

  Future<String> exportToPdf() async {
    final fontData = await rootBundle.load('assets/fonts/NotoSansKR.ttf');
    final font = pw.Font.ttf(fontData);
    final fontBold = font;

    final pdf = pw.Document();
    final text = plainText;
    final lines = text.split('\n');

    final pdfFormat = _pageSetup.pageFormat;
    final margin = _pageSetup.marginValue;

    // Compute header/footer text with placeholder support
    String resolveHeaderFooter(String template, int pageNum, int totalPages) {
      return template
          .replaceAll('{page}', '$pageNum')
          .replaceAll('{pages}', '$totalPages')
          .replaceAll('{title}', _title)
          .replaceAll('{date}', DateTime.now().toString().substring(0, 10));
    }

    const linesPerPage = DocumentDefaults.linesPerPage;
    final totalPages = ((lines.length) / linesPerPage).ceil().clamp(1, DocumentDefaults.maxPages);

    for (var i = 0; i < lines.length; i += linesPerPage) {
      final pageNum = (i ~/ linesPerPage) + 1;
      final pageLines =
          lines.sublist(i, (i + linesPerPage).clamp(0, lines.length));
      pdf.addPage(
        pw.Page(
          pageFormat: pdfFormat,
          margin: pw.EdgeInsets.all(margin),
          build: (pw.Context context) {
            final headerResolved = resolveHeaderFooter(_headerText, pageNum, totalPages);
            final footerResolved = resolveHeaderFooter(_footerText, pageNum, totalPages);
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (headerResolved.isNotEmpty)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 8),
                    child: pw.Text(
                      headerResolved,
                      style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey600),
                    ),
                  ),
                if (i == 0)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 16),
                    child: pw.Text(
                      _title,
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: pageLines.map(
                      (line) => pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 4),
                        child: pw.Text(
                          line,
                          style: pw.TextStyle(font: font, fontSize: 11),
                        ),
                      ),
                    ).toList(),
                  ),
                ),
                if (footerResolved.isNotEmpty || _pageSetup.showPageNumbers)
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        footerResolved,
                        style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey600),
                      ),
                      if (_pageSetup.showPageNumbers)
                        pw.Text(
                          '$pageNum / $totalPages',
                          style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey600),
                        ),
                    ],
                  ),
              ],
            );
          },
        ),
      );
    }

    final dir = await getApplicationDocumentsDirectory();
    final sanitized = _title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    final pdfPath = '${dir.path}/$sanitized.pdf';
    final file = File(pdfPath);
    await file.writeAsBytes(await pdf.save());
    return pdfPath;
  }

  Future<void> shareDocument() async {
    final path = await exportToPdf();
    await Share.shareXFiles([XFile(path)]);
  }

  // ---------------------------------------------------------------------------
  // DOCX 읽기/쓰기
  // ---------------------------------------------------------------------------

  Future<void> loadDocx(String path) async {
    final parser = DocxParser();
    try {
      final file = File(path);
      if (!await file.exists()) throw Exception('DOCX file not found: $path');
      final bytes = await file.readAsBytes();
      final deltaOps = parser.parse(bytes);
      if (deltaOps == null || deltaOps.isEmpty) throw Exception('Failed to parse DOCX');

      // Extract header/footer text
      final (header, footer) = parser.parseHeaderFooter(bytes);
      _headerText = header;
      _footerText = footer;

      _controller.dispose();
      final doc = quill.Document.fromJson(deltaOps);
      _controller = quill.QuillController(
        document: doc,
        selection: const TextSelection.collapsed(offset: 0),
      );
      _title = path.split(RegExp(r'[/\\]')).last.replaceAll('.docx', '');
      _filePath = path;
      _isDirty = false;
      _invalidateCache();
      _setupListener();
      notifyListeners();
    } catch (e) {
      debugPrint('DOCX 로드 실패: $e');
      rethrow;
    } finally {
      parser.cleanup();
    }
  }

  Future<String> saveAsDocx([String? path]) async {
    final savePath = path ?? await _getDocxPath();
    final delta = _controller.document.toDelta().toJson();
    final writer = DocxWriter();
    final Uint8List bytes = writer.write(
      delta,
      _title,
      headerText: _headerText,
      footerText: _footerText,
    );

    final file = File(savePath);
    await file.writeAsBytes(bytes);
    return savePath;
  }

  Future<String> _getDocxPath() async {
    final dir = await getApplicationDocumentsDirectory();
    final sanitized = _title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    return '${dir.path}/$sanitized.docx';
  }

  // ---------------------------------------------------------------------------
  // 문서 개요 (Outline Navigation)
  // ---------------------------------------------------------------------------

  List<DocumentOutlineEntry> getOutline() {
    final entries = <DocumentOutlineEntry>[];
    final delta = _controller.document.toDelta();
    final ops = delta.toList();
    int offset = 0;

    for (var i = 0; i < ops.length; i++) {
      final op = ops[i];
      final data = op.data;
      if (data is String) {
        // Check for header attribute on newline characters
        final attrs = op.attributes;
        if (attrs != null && attrs.containsKey('header') && data.contains('\n')) {
          final level = attrs['header'] as int? ?? 0;
          if (level >= 1 && level <= 6) {
            // Gather preceding text (heading title)
            String headingText = '';
            // Look backwards for the text content of this heading
            for (var j = i - 1; j >= 0; j--) {
              final prevOp = ops[j];
              if (prevOp.data is String) {
                final prevText = prevOp.data as String;
                if (prevText.contains('\n')) {
                  // Take only text after the last newline
                  final afterNewline = prevText.split('\n').last;
                  headingText = afterNewline + headingText;
                  break;
                }
                headingText = prevText + headingText;
              } else {
                break;
              }
            }
            if (headingText.trim().isNotEmpty) {
              // Calculate the offset of the heading text start
              final headingOffset = offset - headingText.length;
              entries.add(DocumentOutlineEntry(
                title: headingText.trim(),
                level: level,
                offset: headingOffset.clamp(0, _controller.document.length - 1),
              ));
            }
          }
        }
        offset += data.length;
      } else {
        offset += 1; // embed
      }
    }
    return entries;
  }

  void insertTableOfContents() {
    final entries = getOutline();
    if (entries.isEmpty) return;

    final idx = _controller.selection.baseOffset;
    final sb = StringBuffer();
    // "목차" 제목 줄
    sb.write('Table of Contents\n');

    for (final entry in entries) {
      final indent = '  ' * (entry.level - 1);
      sb.write('$indent${entry.title}\n');
    }

    final tocText = sb.toString();
    _controller.document.insert(idx, tocText);

    // H2 포맷 적용 (첫 줄 "Table of Contents")
    _controller.document.format(
      idx,
      'Table of Contents'.length,
      quill.Attribute.h2,
    );

    // Bold 적용 level 1~2 항목
    int currentOffset = idx + 'Table of Contents\n'.length;
    for (final entry in entries) {
      final indent = '  ' * (entry.level - 1);
      final lineText = '$indent${entry.title}';
      if (entry.level <= 2) {
        _controller.document.format(
          currentOffset,
          lineText.length,
          quill.Attribute.bold,
        );
      }
      currentOffset += lineText.length + 1; // +1 for \n
    }

    _isDirty = true;
    notifyListeners();
  }

  void navigateToOffset(int offset) {
    final clampedOffset = offset.clamp(0, _controller.document.length - 1);
    _controller.updateSelection(
      TextSelection.collapsed(offset: clampedOffset),
      quill.ChangeSource.local,
    );
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // 찾기 / 바꾸기
  // ---------------------------------------------------------------------------

  String _searchQuery = '';
  List<int> _searchOffsets = [];
  int _searchIndex = -1;

  String get searchQuery => _searchQuery;
  List<int> get searchOffsets => _searchOffsets;
  int get searchIndex => _searchIndex;
  bool get hasSearchResults => _searchOffsets.isNotEmpty;
  int get searchResultCount => _searchOffsets.length;

  void findAll(String query) {
    _searchQuery = query;
    if (query.isEmpty) {
      _searchOffsets = [];
      _searchIndex = -1;
      notifyListeners();
      return;
    }
    final text = _controller.document.toPlainText().toLowerCase();
    final q = query.toLowerCase();
    final offsets = <int>[];
    int start = 0;
    while (true) {
      final idx = text.indexOf(q, start);
      if (idx == -1) break;
      offsets.add(idx);
      start = idx + 1;
    }
    _searchOffsets = offsets;
    _searchIndex = offsets.isNotEmpty ? 0 : -1;
    if (_searchIndex >= 0) {
      _controller.updateSelection(
        TextSelection(
          baseOffset: offsets[0],
          extentOffset: offsets[0] + query.length,
        ),
        quill.ChangeSource.local,
      );
    }
    notifyListeners();
  }

  void findNext() {
    if (_searchOffsets.isEmpty) return;
    _searchIndex = (_searchIndex + 1) % _searchOffsets.length;
    final off = _searchOffsets[_searchIndex];
    _controller.updateSelection(
      TextSelection(baseOffset: off, extentOffset: off + _searchQuery.length),
      quill.ChangeSource.local,
    );
    notifyListeners();
  }

  void findPrev() {
    if (_searchOffsets.isEmpty) return;
    _searchIndex =
        (_searchIndex - 1 + _searchOffsets.length) % _searchOffsets.length;
    final off = _searchOffsets[_searchIndex];
    _controller.updateSelection(
      TextSelection(baseOffset: off, extentOffset: off + _searchQuery.length),
      quill.ChangeSource.local,
    );
    notifyListeners();
  }

  void replaceOne(String replacement) {
    if (_searchOffsets.isEmpty || _searchIndex < 0) return;
    final off = _searchOffsets[_searchIndex];
    _controller.replaceText(off, _searchQuery.length, replacement, null);
    // re-search
    findAll(_searchQuery);
  }

  void replaceAllMatches(String replacement) {
    if (_searchOffsets.isEmpty) return;
    // Replace in reverse order to preserve earlier offsets
    for (int i = _searchOffsets.length - 1; i >= 0; i--) {
      _controller.replaceText(
          _searchOffsets[i], _searchQuery.length, replacement, null);
    }
    findAll(_searchQuery);
  }

  void clearSearch() {
    _searchQuery = '';
    _searchOffsets = [];
    _searchIndex = -1;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------

  void undo() {
    _controller.undo();
    notifyListeners();
  }

  void redo() {
    _controller.redo();
    notifyListeners();
  }

  @override
  void dispose() {
    _changesSub?.cancel();
    _controller.dispose();
    super.dispose();
  }
}

/// Document outline entry for heading navigation.
class DocumentOutlineEntry {
  final String title;
  final int level; // 1-6
  final int offset;

  const DocumentOutlineEntry({
    required this.title,
    required this.level,
    required this.offset,
  });
}
