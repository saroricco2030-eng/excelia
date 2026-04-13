import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:xml/xml.dart';
import 'package:excelia/models/table_embed.dart';

/// DOCX to Quill Delta parser.
///
/// Reads a DOCX file (ZIP archive containing OpenXML) and converts it to
/// a list of Quill Delta operations compatible with flutter_quill.
class DocxParser {
  static const _nsW = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main';
  static const _nsR = 'http://schemas.openxmlformats.org/officeDocument/2006/relationships';
  static const _nsA = 'http://schemas.openxmlformats.org/drawingml/2006/main';

  /// Tracks temporary image files created during parsing for later cleanup.
  final List<String> _tempFiles = [];

  /// Deletes temporary image files created during parsing.
  void cleanup() {
    for (final path in _tempFiles) {
      try {
        File(path).deleteSync();
      } catch (_) { // File may already be deleted
      }
    }
    _tempFiles.clear();
  }


  /// Parses header and footer text from a DOCX file.
  /// Returns (headerText, footerText) tuple.
  (String, String) parseHeaderFooter(Uint8List bytes) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final relsXml = _readArchiveFile(archive, 'word/_rels/document.xml.rels');

      String? headerPath;
      String? footerPath;

      if (relsXml != null) {
        final doc = XmlDocument.parse(relsXml);
        for (final rel in doc.rootElement.childElements) {
          final type = rel.getAttribute('Type') ?? '';
          final target = rel.getAttribute('Target') ?? '';
          if (type.contains('header')) {
            headerPath = 'word/$target';
          } else if (type.contains('footer')) {
            footerPath = 'word/$target';
          }
        }
      }

      final headerText = headerPath != null
          ? _extractPlainText(archive, headerPath)
          : '';
      final footerText = footerPath != null
          ? _extractPlainText(archive, footerPath)
          : '';

      return (headerText, footerText);
    } catch (e) {
      debugPrint('DOCX parseHeaderFooter failed: $e');
      return ('', '');
    }
  }

  /// Extracts plain text from a header/footer XML file.
  String _extractPlainText(Archive archive, String path) {
    final xml = _readArchiveFile(archive, path);
    if (xml == null) return '';

    try {
      final doc = XmlDocument.parse(xml);
      final buffer = StringBuffer();

      // Find all w:t elements and concatenate their text
      void extractText(XmlElement element) {
        for (final child in element.childElements) {
          if (_localName(child) == 't') {
            buffer.write(child.innerText);
          } else {
            extractText(child);
          }
        }
      }

      extractText(doc.rootElement);
      return buffer.toString().trim();
    } catch (e) {
      debugPrint('DOCX extractPlainText failed: $e');
      return '';
    }
  }

  /// Parses DOCX bytes and returns Quill Delta ops, or null on failure.
  List<Map<String, dynamic>>? parse(Uint8List bytes) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);

      final documentXml = _readArchiveFile(archive, 'word/document.xml');
      if (documentXml == null) return null;

      final stylesXml = _readArchiveFile(archive, 'word/styles.xml');
      final numberingXml = _readArchiveFile(archive, 'word/numbering.xml');
      final relsXml = _readArchiveFile(archive, 'word/_rels/document.xml.rels');

      final headingMap = _parseStyles(stylesXml);
      final numberingMap = _parseNumbering(numberingXml);
      final hyperlinkMap = _parseRelationships(relsXml);
      final imageRelMap = _parseImageRelationships(relsXml);

      return _parseDocument(
        documentXml, headingMap, numberingMap, hyperlinkMap,
        archive, imageRelMap,
      );
    } catch (e) {
      debugPrint('DOCX parse failed: $e');
      return null;
    }
  }

  /// Reads a file from the ZIP archive by path and returns its XML content.
  String? _readArchiveFile(Archive archive, String path) {
    final normalizedPath = path.replaceAll('\\', '/');
    for (final file in archive) {
      if (file.name.replaceAll('\\', '/') == normalizedPath && file.isFile) {
        final data = file.content as List<int>;
        return String.fromCharCodes(data);
      }
    }
    return null;
  }

  /// Parses word/styles.xml to map style IDs (e.g. "Heading1") to heading levels.
  Map<String, int> _parseStyles(String? xml) {
    final map = <String, int>{};
    if (xml == null) return map;

    try {
      final doc = XmlDocument.parse(xml);
      final styles = doc.findAllElements('w:style', namespace: _nsW);

      for (final style in styles) {
        final styleId = style.getAttribute('w:styleId') ??
            style.getAttribute('styleId');
        if (styleId == null) continue;

        // Check for heading via outlineLvl
        final outlineLvl = style.findAllElements('w:outlineLvl', namespace: _nsW);
        if (outlineLvl.isNotEmpty) {
          final val = outlineLvl.first.getAttribute('w:val') ??
              outlineLvl.first.getAttribute('val');
          if (val != null) {
            final level = int.tryParse(val);
            if (level != null && level >= 0 && level <= 5) {
              map[styleId] = level + 1; // outlineLvl 0 = Heading 1
            }
          }
          continue;
        }

        // Fallback: match by style ID name pattern
        final lower = styleId.toLowerCase();
        for (var i = 1; i <= 6; i++) {
          if (lower == 'heading$i' || lower == 'heading $i') {
            map[styleId] = i;
            break;
          }
        }
      }
    } catch (e) {
      debugPrint('DOCX XML parse partial: $e');
    }
    return map;
  }

  /// Parses word/numbering.xml to map abstract numbering IDs to list types.
  /// Returns a map of numId -> list type ("ordered" or "bullet").
  _NumberingInfo _parseNumbering(String? xml) {
    final info = _NumberingInfo();
    if (xml == null) return info;

    try {
      final doc = XmlDocument.parse(xml);

      // Parse abstract numbering definitions
      final abstractNums = doc.findAllElements('w:abstractNum', namespace: _nsW);
      for (final absNum in abstractNums) {
        final absNumId = absNum.getAttribute('w:abstractNumId') ??
            absNum.getAttribute('abstractNumId');
        if (absNumId == null) continue;

        // Check the first level (lvl 0) for format
        final levels = absNum.findAllElements('w:lvl', namespace: _nsW);
        for (final lvl in levels) {
          final ilvl = lvl.getAttribute('w:ilvl') ?? lvl.getAttribute('ilvl');
          if (ilvl != '0') continue;

          final numFmts = lvl.findAllElements('w:numFmt', namespace: _nsW);
          if (numFmts.isNotEmpty) {
            final val = numFmts.first.getAttribute('w:val') ??
                numFmts.first.getAttribute('val');
            if (val == 'bullet') {
              info.abstractNumTypes[absNumId] = 'bullet';
            } else if (val != null) {
              // decimal, lowerLetter, upperLetter, lowerRoman, upperRoman, etc.
              info.abstractNumTypes[absNumId] = 'ordered';
            }
          }
          break;
        }
      }

      // Map numId -> abstractNumId
      final nums = doc.findAllElements('w:num', namespace: _nsW);
      for (final num in nums) {
        final numId = num.getAttribute('w:numId') ?? num.getAttribute('numId');
        if (numId == null) continue;

        final absNumIdRef = num.findAllElements('w:abstractNumId', namespace: _nsW);
        if (absNumIdRef.isNotEmpty) {
          final refVal = absNumIdRef.first.getAttribute('w:val') ??
              absNumIdRef.first.getAttribute('val');
          if (refVal != null && info.abstractNumTypes.containsKey(refVal)) {
            info.numIdTypes[numId] = info.abstractNumTypes[refVal]!;
          }
        }
      }
    } catch (e) {
      debugPrint('DOCX XML parse partial: $e');
    }
    return info;
  }

  /// Parses word/_rels/document.xml.rels for hyperlink targets.
  Map<String, String> _parseRelationships(String? xml) {
    final map = <String, String>{};
    if (xml == null) return map;

    try {
      final doc = XmlDocument.parse(xml);
      final rels = doc.findAllElements('Relationship');

      for (final rel in rels) {
        final type = rel.getAttribute('Type') ?? '';
        if (type.contains('hyperlink')) {
          final id = rel.getAttribute('Id');
          final target = rel.getAttribute('Target');
          if (id != null && target != null) {
            map[id] = target;
          }
        }
      }
    } catch (e) {
      debugPrint('DOCX XML parse partial: $e');
    }
    return map;
  }

  /// Parses word/_rels/document.xml.rels for image relationship targets.
  Map<String, String> _parseImageRelationships(String? xml) {
    final map = <String, String>{};
    if (xml == null) return map;

    try {
      final doc = XmlDocument.parse(xml);
      final rels = doc.findAllElements('Relationship');

      for (final rel in rels) {
        final type = rel.getAttribute('Type') ?? '';
        if (type.contains('image')) {
          final id = rel.getAttribute('Id');
          final target = rel.getAttribute('Target');
          if (id != null && target != null) {
            map[id] = target;
          }
        }
      }
    } catch (e) {
      debugPrint('DOCX XML parse partial: $e');
    }
    return map;
  }

  /// Reads binary file from the ZIP archive by path.
  Uint8List? _readArchiveBinary(Archive archive, String path) {
    final normalizedPath = path.replaceAll('\\', '/');
    for (final file in archive) {
      if (file.name.replaceAll('\\', '/') == normalizedPath && file.isFile) {
        return Uint8List.fromList(file.content as List<int>);
      }
    }
    return null;
  }

  /// Parses the main document.xml and produces Quill Delta ops.
  List<Map<String, dynamic>> _parseDocument(
    String documentXml,
    Map<String, int> headingMap,
    _NumberingInfo numberingInfo,
    Map<String, String> hyperlinkMap,
    Archive archive,
    Map<String, String> imageRelMap,
  ) {
    final ops = <Map<String, dynamic>>[];
    final doc = XmlDocument.parse(documentXml);

    final body = doc.findAllElements('w:body', namespace: _nsW);
    if (body.isEmpty) return ops;

    // Iterate all direct children of <w:body> to handle both paragraphs and
    // tables in document order.
    for (final child in body.first.children) {
      if (child is! XmlElement) continue;
      final name = _localName(child);

      if (name == 'tbl') {
        // ── Table element ──
        final tableOps = _parseTable(child);
        ops.addAll(tableOps);
        continue;
      }

      if (name != 'p') continue;

      // ── Paragraph element ──
      final para = child;
      final paraAttrs = _parseParagraphProperties(para, headingMap, numberingInfo);
      var paragraphHasContent = false;

      // Process runs and hyperlinks within the paragraph
      for (final pChild in para.children) {
        if (pChild is! XmlElement) continue;

        if (_localName(pChild) == 'r') {
          // Regular run
          final runOps = _parseRun(pChild, null, archive, imageRelMap);
          if (runOps.isNotEmpty) {
            ops.addAll(runOps);
            paragraphHasContent = true;
          }
        } else if (_localName(pChild) == 'hyperlink') {
          // Hyperlink
          final rId = pChild.getAttribute('r:id') ??
              pChild.getAttribute('id', namespace: _nsR);
          final url = rId != null ? hyperlinkMap[rId] : null;

          final runs = pChild.findAllElements('w:r', namespace: _nsW);
          for (final run in runs) {
            final runOps = _parseRun(run, url, archive, imageRelMap);
            if (runOps.isNotEmpty) {
              ops.addAll(runOps);
              paragraphHasContent = true;
            }
          }
        }
      }

      // Always insert a newline at the end of each paragraph
      if (paraAttrs.isNotEmpty) {
        ops.add({'insert': '\n', 'attributes': paraAttrs});
      } else if (paragraphHasContent || ops.isEmpty) {
        ops.add({'insert': '\n'});
      } else {
        // Empty paragraph → blank line
        ops.add({'insert': '\n'});
      }
    }

    // Ensure document ends with a newline
    if (ops.isEmpty) {
      ops.add({'insert': '\n'});
    }

    return ops;
  }

  /// Parses a `<w:tbl>` element into a table embed delta op.
  ///
  /// Each `<w:tr>` becomes a row. The first row is treated as headers.
  /// Cell text is extracted from `<w:tc>` → `<w:p>` → `<w:r>` → `<w:t>`.
  List<Map<String, dynamic>> _parseTable(XmlElement tblElement) {
    final allRows = <List<String>>[];

    final trElements = tblElement.findAllElements('w:tr', namespace: _nsW);
    for (final tr in trElements) {
      final row = <String>[];
      final tcElements = tr.findAllElements('w:tc', namespace: _nsW);
      for (final tc in tcElements) {
        final sb = StringBuffer();
        final paragraphs = tc.findAllElements('w:p', namespace: _nsW);
        for (final p in paragraphs) {
          final runs = p.findAllElements('w:r', namespace: _nsW);
          for (final r in runs) {
            final texts = r.findAllElements('w:t', namespace: _nsW);
            for (final t in texts) {
              sb.write(t.innerText);
            }
          }
        }
        row.add(sb.toString());
      }
      allRows.add(row);
    }

    if (allRows.isEmpty) {
      return [{'insert': '\n'}];
    }

    final headers = allRows.first;
    final dataRows = allRows.length > 1 ? allRows.sublist(1) : <List<String>>[];

    // Normalize row widths to match header count
    final colCount = headers.length;
    final normalizedRows = dataRows.map((r) {
      if (r.length >= colCount) return r.sublist(0, colCount);
      return [...r, ...List<String>.filled(colCount - r.length, '')];
    }).toList();

    final tableData = TableData(headers: headers, rows: normalizedRows);
    return [
      {'insert': {'table': jsonEncode(tableData.toJson())}},
      {'insert': '\n'},
    ];
  }

  /// Extracts paragraph-level attributes (heading, alignment, list).
  Map<String, dynamic> _parseParagraphProperties(
    XmlElement para,
    Map<String, int> headingMap,
    _NumberingInfo numberingInfo,
  ) {
    final attrs = <String, dynamic>{};

    final pPr = para.findAllElements('w:pPr', namespace: _nsW);
    if (pPr.isEmpty) return attrs;
    final props = pPr.first;

    // Paragraph style → heading level
    final pStyle = props.findAllElements('w:pStyle', namespace: _nsW);
    if (pStyle.isNotEmpty) {
      final val = pStyle.first.getAttribute('w:val') ??
          pStyle.first.getAttribute('val');
      if (val != null && headingMap.containsKey(val)) {
        attrs['header'] = headingMap[val];
      }
    }

    // Alignment
    final jc = props.findAllElements('w:jc', namespace: _nsW);
    if (jc.isNotEmpty) {
      final val = jc.first.getAttribute('w:val') ??
          jc.first.getAttribute('val');
      if (val != null) {
        final align = _mapAlignment(val);
        if (align != null) {
          attrs['align'] = align;
        }
      }
    }

    // Numbering (lists)
    final numPr = props.findAllElements('w:numPr', namespace: _nsW);
    if (numPr.isNotEmpty) {
      final numIdEl = numPr.first.findAllElements('w:numId', namespace: _nsW);
      if (numIdEl.isNotEmpty) {
        final numId = numIdEl.first.getAttribute('w:val') ??
            numIdEl.first.getAttribute('val');
        if (numId != null) {
          final listType = numberingInfo.numIdTypes[numId] ?? 'bullet';
          attrs['list'] = listType;
        }
      }
    }

    return attrs;
  }

  /// Parses a single run element into Quill Delta ops.
  List<Map<String, dynamic>> _parseRun(
    XmlElement run,
    String? hyperlinkUrl,
    Archive archive,
    Map<String, String> imageRelMap,
  ) {
    final ops = <Map<String, dynamic>>[];
    final attrs = <String, dynamic>{};

    // Run properties
    final rPr = run.findAllElements('w:rPr', namespace: _nsW);
    if (rPr.isNotEmpty) {
      final props = rPr.first;

      // Bold
      if (_hasToggleProperty(props, 'b')) {
        attrs['bold'] = true;
      }

      // Italic
      if (_hasToggleProperty(props, 'i')) {
        attrs['italic'] = true;
      }

      // Underline
      final uEl = props.findAllElements('w:u', namespace: _nsW);
      if (uEl.isNotEmpty) {
        final val = uEl.first.getAttribute('w:val') ??
            uEl.first.getAttribute('val');
        if (val != 'none') {
          attrs['underline'] = true;
        }
      }

      // Strikethrough
      if (_hasToggleProperty(props, 'strike')) {
        attrs['strike'] = true;
      }

      // Font size: w:sz val is in half-points → divide by 2 for pt
      final sz = props.findAllElements('w:sz', namespace: _nsW);
      if (sz.isNotEmpty) {
        final val = sz.first.getAttribute('w:val') ??
            sz.first.getAttribute('val');
        if (val != null) {
          final halfPoints = int.tryParse(val);
          if (halfPoints != null) {
            attrs['size'] = '${halfPoints ~/ 2}';
          }
        }
      }

      // Font color
      final color = props.findAllElements('w:color', namespace: _nsW);
      if (color.isNotEmpty) {
        final val = color.first.getAttribute('w:val') ??
            color.first.getAttribute('val');
        if (val != null && val != 'auto') {
          attrs['color'] = '#$val';
        }
      }
    }

    // Hyperlink
    if (hyperlinkUrl != null) {
      attrs['link'] = hyperlinkUrl;
    }

    // Text content
    final textElements = run.findAllElements('w:t', namespace: _nsW);
    for (final t in textElements) {
      final text = t.innerText;
      if (text.isNotEmpty) {
        final op = <String, dynamic>{'insert': text};
        if (attrs.isNotEmpty) {
          op['attributes'] = Map<String, dynamic>.from(attrs);
        }
        ops.add(op);
      }
    }

    // Tab character
    final tabs = run.findAllElements('w:tab', namespace: _nsW);
    for (var i = 0; i < tabs.length; i++) {
      ops.add({'insert': '\t'});
    }

    // Line break
    final breaks = run.findAllElements('w:br', namespace: _nsW);
    for (final br in breaks) {
      final type = br.getAttribute('w:type') ?? br.getAttribute('type');
      if (type == 'page') {
        // Page break — insert newline
        ops.add({'insert': '\n'});
      } else {
        // Line break
        ops.add({'insert': '\n'});
      }
    }

    // Drawing (inline image)
    final drawings = run.findAllElements('w:drawing', namespace: _nsW);
    // Fallback: drawing without namespace prefix
    final allDrawings = drawings.isNotEmpty
        ? drawings
        : run.children.whereType<XmlElement>().where(
            (e) => _localName(e) == 'drawing');
    for (final drawing in allDrawings) {
      final imageOps = _parseDrawing(drawing, archive, imageRelMap);
      ops.addAll(imageOps);
    }

    return ops;
  }

  /// Parses a `<w:drawing>` element to extract an embedded image.
  ///
  /// Follows the chain: w:drawing → wp:inline/anchor → a:graphic →
  /// a:graphicData → pic:pic → pic:blipFill → a:blip r:embed.
  /// Reads the binary from the archive, saves to a temp file, and
  /// returns a Quill image embed op.
  List<Map<String, dynamic>> _parseDrawing(
    XmlElement drawing,
    Archive archive,
    Map<String, String> imageRelMap,
  ) {
    try {
      // Search for a:blip elements (may be deeply nested)
      Iterable<XmlElement> blips = drawing.findAllElements('a:blip', namespace: _nsA);
      // Fallback: try without strict namespace matching
      if (blips.isEmpty) {
        blips = drawing.descendants
            .whereType<XmlElement>()
            .where((e) => _localName(e) == 'blip');
      }

      for (final blip in blips) {
        final rId = blip.getAttribute('r:embed') ??
            blip.getAttribute('embed', namespace: _nsR) ??
            blip.getAttribute('embed');
        if (rId == null) continue;

        final target = imageRelMap[rId];
        if (target == null) continue;

        // Target is relative to word/ directory (e.g. "media/image1.png")
        final archivePath = target.startsWith('/')
            ? target.substring(1)
            : 'word/$target';

        final imageBytes = _readArchiveBinary(archive, archivePath);
        if (imageBytes == null) continue;

        // Save to temp directory
        final ext = target.split('.').last.toLowerCase();
        final safeExt = const ['png', 'jpg', 'jpeg', 'gif', 'bmp', 'webp']
                .contains(ext)
            ? ext
            : 'png';
        final tmpFile = File(
          '${Directory.systemTemp.path}/excelia_docx_'
          '${DateTime.now().millisecondsSinceEpoch}_${identityHashCode(blip)}'
          '.$safeExt',
        );
        tmpFile.writeAsBytesSync(imageBytes);
        _tempFiles.add(tmpFile.path);

        return [
          {'insert': {'image': tmpFile.path}},
        ];
      }
    } catch (e) {
      debugPrint('DOCX drawing parse skipped: $e');
    }
    return [];
  }

  /// Checks if a toggle property (like w:b, w:i, w:strike) is present and on.
  /// In OOXML, `<w:b/>` means true, `<w:b w:val="false"/>` or `<w:b w:val="0"/>` means false.
  bool _hasToggleProperty(XmlElement props, String name) {
    final elements = props.findAllElements('w:$name', namespace: _nsW);
    if (elements.isEmpty) return false;

    final el = elements.first;
    final val = el.getAttribute('w:val') ?? el.getAttribute('val');
    if (val == null) return true; // <w:b/> with no val means true
    return val != 'false' && val != '0';
  }

  /// Maps OOXML alignment values to Quill alignment strings.
  String? _mapAlignment(String val) {
    switch (val) {
      case 'center':
        return 'center';
      case 'right':
      case 'end':
        return 'right';
      case 'both':
      case 'distribute':
        return 'justify';
      case 'left':
      case 'start':
        return null; // Left is default in Quill, no attribute needed
      default:
        return null;
    }
  }

  /// Gets the local name of an XML element, ignoring namespace prefix.
  String _localName(XmlElement el) {
    return el.name.local;
  }
}

/// Internal helper to hold numbering info parsed from numbering.xml.
class _NumberingInfo {
  /// abstractNumId -> list type ("ordered" or "bullet")
  final Map<String, String> abstractNumTypes = {};

  /// numId -> list type ("ordered" or "bullet")
  final Map<String, String> numIdTypes = {};
}
