import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:excelia/models/table_embed.dart';
import 'package:excelia/utils/constants.dart';

/// Quill Delta to DOCX writer.
///
/// Takes a list of Quill Delta operations and produces a valid DOCX file
/// (ZIP archive containing OpenXML) as bytes.
class DocxWriter {
  /// Tracked image files to embed in the DOCX archive.
  final List<_ImageEntry> _imageEntries = [];

  /// Next available relationship ID (rId1=styles, rId2=numbering → start at 3).
  int _nextRelId = 3;

  /// Converts Quill Delta JSON ops to DOCX bytes.
  ///
  /// [deltaJson] is the list of delta operations from flutter_quill.
  /// [title] is the document title embedded in the DOCX properties.
  /// Returns the DOCX file as [Uint8List], or throws on critical errors.
  /// Header/footer relationship IDs (assigned during write).
  String? _headerRId;
  String? _footerRId;

  Uint8List write(List<dynamic> deltaJson, String title, {
    String headerText = '',
    String footerText = '',
  }) {
    _imageEntries.clear();
    _nextRelId = 3;
    _headerRId = null;
    _footerRId = null;

    // Reserve rIds for header/footer if needed
    if (headerText.isNotEmpty) {
      _headerRId = 'rId${_nextRelId++}';
    }
    if (footerText.isNotEmpty) {
      _footerRId = 'rId${_nextRelId++}';
    }

    final paragraphs = _deltaToRuns(deltaJson);
    final bodyXml = _buildBodyXml(paragraphs);

    final archive = Archive();

    _addFile(archive, '[Content_Types].xml', _contentTypesXml());
    _addFile(archive, '_rels/.rels', _rootRelsXml());
    _addFile(archive, 'word/document.xml', _documentXml(bodyXml));
    _addFile(archive, 'word/_rels/document.xml.rels', _documentRelsXml());
    _addFile(archive, 'word/styles.xml', _stylesXml());
    _addFile(archive, 'word/numbering.xml', _numberingXml());

    // Add header/footer XML files
    if (_headerRId != null) {
      _addFile(archive, 'word/header1.xml', _headerXml(headerText));
    }
    if (_footerRId != null) {
      _addFile(archive, 'word/footer1.xml', _footerXml(footerText));
    }

    // Add image binary files to the archive
    for (final img in _imageEntries) {
      archive.addFile(
        ArchiveFile(img.archivePath, img.bytes.length, img.bytes),
      );
    }

    final encoded = ZipEncoder().encode(archive);
    return Uint8List.fromList(encoded);
  }

  /// Adds a UTF-8 text file to the archive.
  void _addFile(Archive archive, String path, String content) {
    final bytes = Uint8List.fromList(content.codeUnits);
    archive.addFile(ArchiveFile(path, bytes.length, bytes));
  }

  // ---------------------------------------------------------------------------
  // Delta → intermediate paragraph model
  // ---------------------------------------------------------------------------

  /// Converts Quill Delta ops into a list of [_Paragraph] objects.
  ///
  /// Delta ops use `\n` to delimit paragraphs. Attributes on a `\n` insert
  /// apply to the entire paragraph (header, align, list).
  List<_Paragraph> _deltaToRuns(List<dynamic> deltaJson) {
    final paragraphs = <_Paragraph>[];
    var currentRuns = <_Run>[];

    for (final op in deltaJson) {
      if (op is! Map) continue;
      final insert = op['insert'];

      // Handle table embed: insert is a Map with 'table' key
      if (insert is Map && insert.containsKey('table')) {
        // Flush any pending runs as a paragraph first
        if (currentRuns.isNotEmpty) {
          paragraphs.add(_Paragraph(
            runs: List.from(currentRuns),
            header: null,
            align: null,
            listType: null,
          ));
          currentRuns = [];
        }
        try {
          final tableData = TableData.fromJson(
            jsonDecode(insert['table'] as String) as Map<String, dynamic>,
          );
          paragraphs.add(_Paragraph(
            runs: [],
            header: null,
            align: null,
            listType: null,
            tableData: tableData,
          ));
        } catch (e) {
          debugPrint('DOCX write: malformed table embed skipped: $e');
        }
        continue;
      }

      // Handle image embed: insert is a Map with 'image' key
      if (insert is Map && insert.containsKey('image')) {
        final imagePath = insert['image'] as String?;
        if (imagePath != null) {
          currentRuns.add(_Run(text: '', attrs: {}, imagePath: imagePath));
        }
        continue;
      }

      if (insert is! String) continue;

      final attrs = op['attributes'] as Map<String, dynamic>? ?? {};

      if (insert == '\n') {
        // End of paragraph — paragraph-level attrs come from this op
        paragraphs.add(_Paragraph(
          runs: List.from(currentRuns),
          header: _intAttr(attrs, 'header'),
          align: attrs['align'] as String?,
          listType: attrs['list'] as String?,
        ));
        currentRuns = [];
      } else if (insert.contains('\n')) {
        // Text with embedded newlines — split into multiple paragraphs
        final parts = insert.split('\n');
        for (var i = 0; i < parts.length; i++) {
          if (parts[i].isNotEmpty) {
            currentRuns.add(_Run(text: parts[i], attrs: Map.from(attrs)));
          }
          if (i < parts.length - 1) {
            // Each \n ends a paragraph
            paragraphs.add(_Paragraph(
              runs: List.from(currentRuns),
              header: null,
              align: null,
              listType: null,
            ));
            currentRuns = [];
          }
        }
      } else {
        currentRuns.add(_Run(text: insert, attrs: Map.from(attrs)));
      }
    }

    // Remaining runs form the last paragraph
    if (currentRuns.isNotEmpty) {
      paragraphs.add(_Paragraph(
        runs: currentRuns,
        header: null,
        align: null,
        listType: null,
      ));
    }

    // Guarantee at least one paragraph
    if (paragraphs.isEmpty) {
      paragraphs.add(_Paragraph(runs: [], header: null, align: null, listType: null));
    }

    return paragraphs;
  }

  /// Safely extracts an int attribute value.
  int? _intAttr(Map<String, dynamic> attrs, String key) {
    final v = attrs[key];
    if (v is int) return v;
    if (v is String) return int.tryParse(v);
    return null;
  }

  // ---------------------------------------------------------------------------
  // Paragraph model → OpenXML body
  // ---------------------------------------------------------------------------

  /// Builds the `<w:body>` inner XML from paragraphs.
  String _buildBodyXml(List<_Paragraph> paragraphs) {
    final sb = StringBuffer();

    for (final para in paragraphs) {
      // If this paragraph is a table embed, output <w:tbl> instead
      if (para.tableData != null) {
        sb.write(_buildTableXml(para.tableData!));
        continue;
      }

      sb.write('<w:p>');

      // Paragraph properties
      final hasPProps = para.header != null ||
          para.align != null ||
          para.listType != null;

      if (hasPProps) {
        sb.write('<w:pPr>');

        if (para.header != null && para.header! >= 1 && para.header! <= 6) {
          sb.write('<w:pStyle w:val="Heading${para.header}"/>');
        }

        if (para.align != null) {
          final jcVal = _quillAlignToOoxml(para.align!);
          if (jcVal != null) {
            sb.write('<w:jc w:val="$jcVal"/>');
          }
        }

        if (para.listType != null) {
          final numId = para.listType == 'ordered' ? '1' : '2';
          sb.write('<w:numPr><w:ilvl w:val="0"/><w:numId w:val="$numId"/></w:numPr>');
        }

        sb.write('</w:pPr>');
      }

      // Runs
      for (final run in para.runs) {
        // Image run — generate <w:drawing> instead of text
        if (run.imagePath != null) {
          final imageXml = _buildImageRunXml(run.imagePath!);
          if (imageXml != null) {
            sb.write(imageXml);
          }
          continue;
        }

        sb.write('<w:r>');

        final runProps = _buildRunProperties(run.attrs);
        if (runProps.isNotEmpty) {
          sb.write('<w:rPr>$runProps</w:rPr>');
        }

        // Escape XML entities in text
        sb.write('<w:t xml:space="preserve">${_escapeXml(run.text)}</w:t>');
        sb.write('</w:r>');
      }

      sb.write('</w:p>');
    }

    return sb.toString();
  }

  /// Builds a `<w:tbl>` element from [TableData].
  ///
  /// The header row is rendered with bold text.
  String _buildTableXml(TableData table) {
    final sb = StringBuffer();
    sb.write('<w:tbl>');

    // Table properties with borders
    sb.write('<w:tblPr>');
    sb.write('<w:tblBorders>');
    for (final side in ['top', 'left', 'bottom', 'right', 'insideH', 'insideV']) {
      sb.write('<w:$side w:val="single" w:sz="4" w:space="0" w:color="auto"/>');
    }
    sb.write('</w:tblBorders>');
    sb.write('<w:tblW w:w="0" w:type="auto"/>');
    sb.write('</w:tblPr>');

    // Header row (bold)
    sb.write('<w:tr>');
    for (final header in table.headers) {
      sb.write('<w:tc>');
      sb.write('<w:p><w:r>');
      sb.write('<w:rPr><w:b/></w:rPr>');
      sb.write('<w:t xml:space="preserve">${_escapeXml(header)}</w:t>');
      sb.write('</w:r></w:p>');
      sb.write('</w:tc>');
    }
    sb.write('</w:tr>');

    // Data rows
    for (final row in table.rows) {
      sb.write('<w:tr>');
      for (final cell in row) {
        sb.write('<w:tc>');
        sb.write('<w:p><w:r>');
        sb.write('<w:t xml:space="preserve">${_escapeXml(cell)}</w:t>');
        sb.write('</w:r></w:p>');
        sb.write('</w:tc>');
      }
      sb.write('</w:tr>');
    }

    sb.write('</w:tbl>');
    return sb.toString();
  }

  /// Builds a `<w:r>` containing `<w:drawing>` for an inline image.
  ///
  /// Reads the image file, assigns a relationship ID, tracks it in
  /// [_imageEntries], and returns the complete run XML. Returns null
  /// if the image file cannot be read.
  String? _buildImageRunXml(String imagePath) {
    try {
      final file = File(imagePath);
      if (!file.existsSync()) return null;
      final bytes = file.readAsBytesSync();
      if (bytes.isEmpty) return null;

      final ext = imagePath.split('.').last.toLowerCase();
      final safeExt = const ['png', 'jpg', 'jpeg', 'gif', 'bmp', 'webp']
              .contains(ext)
          ? ext
          : 'png';

      final imgIdx = _imageEntries.length + 1;
      final rId = 'rId${_nextRelId++}';
      final archivePath = 'word/media/image$imgIdx.$safeExt';

      _imageEntries.add(_ImageEntry(
        rId: rId,
        archivePath: archivePath,
        bytes: Uint8List.fromList(bytes),
        extension: safeExt,
      ));

      // Default size: 5 inches wide × 3 inches tall (in EMU: 1 inch = 914400)
      const cx = DocxDefaults.defaultImageWidthEmu;
      const cy = DocxDefaults.defaultImageHeightEmu;

      return '<w:r>'
          '<w:drawing>'
          '<wp:inline distT="0" distB="0" distL="0" distR="0" '
          'xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing">'
          '<wp:extent cx="$cx" cy="$cy"/>'
          '<wp:docPr id="$imgIdx" name="Image$imgIdx"/>'
          '<a:graphic xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main">'
          '<a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/picture">'
          '<pic:pic xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture">'
          '<pic:nvPicPr>'
          '<pic:cNvPr id="$imgIdx" name="image$imgIdx.$safeExt"/>'
          '<pic:cNvPicPr/>'
          '</pic:nvPicPr>'
          '<pic:blipFill>'
          '<a:blip r:embed="$rId" '
          'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"/>'
          '<a:stretch><a:fillRect/></a:stretch>'
          '</pic:blipFill>'
          '<pic:spPr>'
          '<a:xfrm><a:off x="0" y="0"/><a:ext cx="$cx" cy="$cy"/></a:xfrm>'
          '<a:prstGeom prst="rect"><a:avLst/></a:prstGeom>'
          '</pic:spPr>'
          '</pic:pic>'
          '</a:graphicData>'
          '</a:graphic>'
          '</wp:inline>'
          '</w:drawing>'
          '</w:r>';
    } catch (e) {
      debugPrint('DOCX write: image inline failed: $e');
      return null;
    }
  }

  /// Builds run-level property XML from Quill attributes.
  String _buildRunProperties(Map<String, dynamic> attrs) {
    final sb = StringBuffer();

    if (attrs['bold'] == true) {
      sb.write('<w:b/>');
    }
    if (attrs['italic'] == true) {
      sb.write('<w:i/>');
    }
    if (attrs['underline'] == true) {
      sb.write('<w:u w:val="single"/>');
    }
    if (attrs['strike'] == true) {
      sb.write('<w:strike/>');
    }

    // Font size: Quill stores pt as string, OOXML uses half-points
    final size = attrs['size'];
    if (size != null) {
      final pt = int.tryParse(size.toString());
      if (pt != null) {
        sb.write('<w:sz w:val="${pt * 2}"/>');
        sb.write('<w:szCs w:val="${pt * 2}"/>');
      }
    }

    // Font color
    final color = attrs['color'];
    if (color is String && color.startsWith('#')) {
      final hex = color.substring(1).toUpperCase();
      sb.write('<w:color w:val="$hex"/>');
    }

    return sb.toString();
  }

  /// Maps Quill alignment to OOXML w:jc values.
  String? _quillAlignToOoxml(String align) {
    switch (align) {
      case 'center':
        return 'center';
      case 'right':
        return 'right';
      case 'justify':
        return 'both';
      default:
        return null;
    }
  }

  /// Escapes special XML characters.
  String _escapeXml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  /// Returns the MIME type for a given image file extension.
  String _imageMimeType(String ext) {
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'gif':
        return 'image/gif';
      case 'bmp':
        return 'image/bmp';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/png';
    }
  }

  // ---------------------------------------------------------------------------
  // DOCX XML templates
  // ---------------------------------------------------------------------------

  String _contentTypesXml() {
    final sb = StringBuffer()
      ..write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>')
      ..write('<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">')
      ..write('<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>')
      ..write('<Default Extension="xml" ContentType="application/xml"/>');

    // Add image content type defaults if images are present
    final exts = _imageEntries.map((e) => e.extension).toSet();
    for (final ext in exts) {
      final mime = _imageMimeType(ext);
      sb.write('<Default Extension="$ext" ContentType="$mime"/>');
    }

    sb
      ..write('<Override PartName="/word/document.xml" '
          'ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>')
      ..write('<Override PartName="/word/styles.xml" '
          'ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>')
      ..write('<Override PartName="/word/numbering.xml" '
          'ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.numbering+xml"/>');

    if (_headerRId != null) {
      sb.write('<Override PartName="/word/header1.xml" '
          'ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.header+xml"/>');
    }
    if (_footerRId != null) {
      sb.write('<Override PartName="/word/footer1.xml" '
          'ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.footer+xml"/>');
    }

    sb.write('</Types>');
    return sb.toString();
  }

  String _rootRelsXml() => '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
      '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" '
      'Target="word/document.xml"/>'
      '</Relationships>';

  String _documentXml(String bodyContent) {
    final sb = StringBuffer()
      ..write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>')
      ..write('<w:document xmlns:wpc="http://schemas.microsoft.com/office/word/2010/wordprocessingCanvas" '
          'xmlns:mo="http://schemas.microsoft.com/office/mac/office/2008/main" '
          'xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006" '
          'xmlns:mv="urn:schemas-microsoft-com:mac:vml" '
          'xmlns:o="urn:schemas-microsoft-com:office:office" '
          'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" '
          'xmlns:m="http://schemas.openxmlformats.org/officeDocument/2006/math" '
          'xmlns:v="urn:schemas-microsoft-com:vml" '
          'xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing" '
          'xmlns:w10="urn:schemas-microsoft-com:office:word" '
          'xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" '
          'xmlns:wne="http://schemas.microsoft.com/office/word/2006/wordml">')
      ..write('<w:body>')
      ..write(bodyContent)
      ..write('<w:sectPr>');

    // Header/footer references
    if (_headerRId != null) {
      sb.write('<w:headerReference w:type="default" r:id="$_headerRId"/>');
    }
    if (_footerRId != null) {
      sb.write('<w:footerReference w:type="default" r:id="$_footerRId"/>');
    }

    sb
      ..write('<w:pgSz w:w="12240" w:h="15840"/>')  // Letter size
      ..write('<w:pgMar w:top="1440" w:right="1440" w:bottom="1440" w:left="1440" '
          'w:header="720" w:footer="720" w:gutter="0"/>')
      ..write('</w:sectPr>')
      ..write('</w:body>')
      ..write('</w:document>');
    return sb.toString();
  }

  String _documentRelsXml() {
    final sb = StringBuffer()
      ..write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>')
      ..write('<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">')
      ..write('<Relationship Id="rId1" '
          'Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" '
          'Target="styles.xml"/>')
      ..write('<Relationship Id="rId2" '
          'Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/numbering" '
          'Target="numbering.xml"/>');

    // Add header/footer relationships
    if (_headerRId != null) {
      sb.write('<Relationship Id="$_headerRId" '
          'Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/header" '
          'Target="header1.xml"/>');
    }
    if (_footerRId != null) {
      sb.write('<Relationship Id="$_footerRId" '
          'Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/footer" '
          'Target="footer1.xml"/>');
    }

    // Add image relationships
    for (final img in _imageEntries) {
      // Target is relative to word/ directory
      final target = img.archivePath.replaceFirst('word/', '');
      sb.write('<Relationship Id="${img.rId}" '
          'Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" '
          'Target="$target"/>');
    }

    sb.write('</Relationships>');
    return sb.toString();
  }

  /// Generates word/header1.xml with a single paragraph.
  String _headerXml(String text) =>
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<w:hdr xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" '
      'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
      '<w:p><w:pPr><w:pStyle w:val="Header"/><w:jc w:val="left"/></w:pPr>'
      '<w:r><w:rPr><w:sz w:val="18"/><w:szCs w:val="18"/></w:rPr>'
      '<w:t xml:space="preserve">${_escapeXml(text)}</w:t></w:r>'
      '</w:p></w:hdr>';

  /// Generates word/footer1.xml with text and optional page number field.
  String _footerXml(String text) =>
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<w:ftr xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" '
      'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
      '<w:p><w:pPr><w:pStyle w:val="Footer"/><w:jc w:val="left"/></w:pPr>'
      '<w:r><w:rPr><w:sz w:val="18"/><w:szCs w:val="18"/></w:rPr>'
      '<w:t xml:space="preserve">${_escapeXml(text)}</w:t></w:r>'
      '<w:r><w:t xml:space="preserve"> </w:t></w:r>'
      '<w:r><w:fldChar w:fldCharType="begin"/></w:r>'
      '<w:r><w:instrText xml:space="preserve"> PAGE </w:instrText></w:r>'
      '<w:r><w:fldChar w:fldCharType="end"/></w:r>'
      '</w:p></w:ftr>';

  String _stylesXml() => '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">'
      // Default (Normal) style
      '<w:style w:type="paragraph" w:default="1" w:styleId="Normal">'
      '<w:name w:val="Normal"/>'
      '<w:qFormat/>'
      '<w:rPr><w:sz w:val="24"/><w:szCs w:val="24"/></w:rPr>'
      '</w:style>'
      // Heading 1
      '<w:style w:type="paragraph" w:styleId="Heading1">'
      '<w:name w:val="heading 1"/>'
      '<w:basedOn w:val="Normal"/>'
      '<w:next w:val="Normal"/>'
      '<w:qFormat/>'
      '<w:pPr><w:outlineLvl w:val="0"/></w:pPr>'
      '<w:rPr><w:b/><w:sz w:val="48"/><w:szCs w:val="48"/></w:rPr>'
      '</w:style>'
      // Heading 2
      '<w:style w:type="paragraph" w:styleId="Heading2">'
      '<w:name w:val="heading 2"/>'
      '<w:basedOn w:val="Normal"/>'
      '<w:next w:val="Normal"/>'
      '<w:qFormat/>'
      '<w:pPr><w:outlineLvl w:val="1"/></w:pPr>'
      '<w:rPr><w:b/><w:sz w:val="36"/><w:szCs w:val="36"/></w:rPr>'
      '</w:style>'
      // Heading 3
      '<w:style w:type="paragraph" w:styleId="Heading3">'
      '<w:name w:val="heading 3"/>'
      '<w:basedOn w:val="Normal"/>'
      '<w:next w:val="Normal"/>'
      '<w:qFormat/>'
      '<w:pPr><w:outlineLvl w:val="2"/></w:pPr>'
      '<w:rPr><w:b/><w:sz w:val="28"/><w:szCs w:val="28"/></w:rPr>'
      '</w:style>'
      // Heading 4
      '<w:style w:type="paragraph" w:styleId="Heading4">'
      '<w:name w:val="heading 4"/>'
      '<w:basedOn w:val="Normal"/>'
      '<w:next w:val="Normal"/>'
      '<w:qFormat/>'
      '<w:pPr><w:outlineLvl w:val="3"/></w:pPr>'
      '<w:rPr><w:b/><w:i/><w:sz w:val="24"/><w:szCs w:val="24"/></w:rPr>'
      '</w:style>'
      // Heading 5
      '<w:style w:type="paragraph" w:styleId="Heading5">'
      '<w:name w:val="heading 5"/>'
      '<w:basedOn w:val="Normal"/>'
      '<w:next w:val="Normal"/>'
      '<w:qFormat/>'
      '<w:pPr><w:outlineLvl w:val="4"/></w:pPr>'
      '<w:rPr><w:sz w:val="22"/><w:szCs w:val="22"/></w:rPr>'
      '</w:style>'
      // Heading 6
      '<w:style w:type="paragraph" w:styleId="Heading6">'
      '<w:name w:val="heading 6"/>'
      '<w:basedOn w:val="Normal"/>'
      '<w:next w:val="Normal"/>'
      '<w:qFormat/>'
      '<w:pPr><w:outlineLvl w:val="5"/></w:pPr>'
      '<w:rPr><w:i/><w:sz w:val="22"/><w:szCs w:val="22"/></w:rPr>'
      '</w:style>'
      '</w:styles>';

  String _numberingXml() => '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<w:numbering xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">'
      // Abstract numbering 0: ordered (decimal)
      '<w:abstractNum w:abstractNumId="0">'
      '<w:lvl w:ilvl="0">'
      '<w:start w:val="1"/>'
      '<w:numFmt w:val="decimal"/>'
      '<w:lvlText w:val="%1."/>'
      '<w:lvlJc w:val="left"/>'
      '<w:pPr><w:ind w:left="720" w:hanging="360"/></w:pPr>'
      '</w:lvl>'
      '</w:abstractNum>'
      // Abstract numbering 1: bullet
      '<w:abstractNum w:abstractNumId="1">'
      '<w:lvl w:ilvl="0">'
      '<w:start w:val="1"/>'
      '<w:numFmt w:val="bullet"/>'
      '<w:lvlText w:val="\u2022"/>'
      '<w:lvlJc w:val="left"/>'
      '<w:pPr><w:ind w:left="720" w:hanging="360"/></w:pPr>'
      '<w:rPr><w:rFonts w:ascii="Symbol" w:hAnsi="Symbol" w:hint="default"/></w:rPr>'
      '</w:lvl>'
      '</w:abstractNum>'
      // numId 1 → ordered (abstractNumId 0)
      '<w:num w:numId="1"><w:abstractNumId w:val="0"/></w:num>'
      // numId 2 → bullet (abstractNumId 1)
      '<w:num w:numId="2"><w:abstractNumId w:val="1"/></w:num>'
      '</w:numbering>';
}

/// Internal model for a paragraph with its runs and block-level attributes.
///
/// When [tableData] is non-null this paragraph represents a table embed
/// and [runs], [header], [align], [listType] are ignored.
class _Paragraph {
  final List<_Run> runs;
  final int? header;
  final String? align;
  final String? listType;
  final TableData? tableData;

  _Paragraph({
    required this.runs,
    required this.header,
    required this.align,
    required this.listType,
    this.tableData,
  });
}

/// Internal model for a text run with inline attributes.
///
/// When [imagePath] is non-null, this run represents an inline image.
class _Run {
  final String text;
  final Map<String, dynamic> attrs;
  final String? imagePath;

  _Run({required this.text, required this.attrs, this.imagePath});
}

/// Tracks an image file to be embedded in the DOCX archive.
class _ImageEntry {
  final String rId;
  final String archivePath;
  final Uint8List bytes;
  final String extension;

  _ImageEntry({
    required this.rId,
    required this.archivePath,
    required this.bytes,
    required this.extension,
  });
}
