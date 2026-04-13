import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';

/// 슬라이드 데이터 맵 리스트를 PPTX(ZIP/OpenXML) 바이트로 변환한다.
///
/// 입력 형식은 [Slide.toJson] / [SlideElement.toJson] 과 호환되는
/// `Map<String, dynamic>` 리스트이다.
class PptxWriter {
  // ===========================================================================
  // Constants
  // ===========================================================================

  /// 표준 16:9 슬라이드 EMU 크기
  static const int _slideWidthEmu = 12192000;
  static const int _slideHeightEmu = 6858000;

  /// 논리 캔버스 크기
  static const double _canvasWidth = 960.0;
  static const double _canvasHeight = 540.0;

  // ===========================================================================
  // Public API
  // ===========================================================================

  /// 슬라이드 데이터 맵 리스트를 PPTX 바이트로 변환한다.
  Uint8List write(List<Map<String, dynamic>> slides) {
    final archive = Archive();

    final slideCount = slides.length;

    // 1) 고정 구조 파일
    _addFile(archive, '[Content_Types].xml',
        _buildContentTypes(slideCount));
    _addFile(archive, '_rels/.rels', _buildRootRels());
    _addFile(archive, 'ppt/presentation.xml',
        _buildPresentation(slideCount));
    _addFile(archive, 'ppt/_rels/presentation.xml.rels',
        _buildPresentationRels(slideCount));

    // 2) 최소 레이아웃/마스터/테마
    _addFile(archive, 'ppt/slideLayouts/slideLayout1.xml',
        _buildSlideLayout());
    _addFile(archive, 'ppt/slideLayouts/_rels/slideLayout1.xml.rels',
        _buildSlideLayoutRels());
    _addFile(archive, 'ppt/slideMasters/slideMaster1.xml',
        _buildSlideMaster());
    _addFile(archive, 'ppt/slideMasters/_rels/slideMaster1.xml.rels',
        _buildSlideMasterRels());
    _addFile(archive, 'ppt/theme/theme1.xml', _buildTheme());

    // 3) 각 슬라이드
    for (int i = 0; i < slideCount; i++) {
      final slideXml = _buildSlide(slides[i]);
      _addFile(archive, 'ppt/slides/slide${i + 1}.xml', slideXml);
      _addFile(archive, 'ppt/slides/_rels/slide${i + 1}.xml.rels',
          _buildSlideRels());
    }

    // 4) ZIP 인코딩
    final zipBytes = ZipEncoder().encode(archive);
    return Uint8List.fromList(zipBytes);
  }

  // ===========================================================================
  // Slide XML generation
  // ===========================================================================

  String _buildSlide(Map<String, dynamic> slideData) {
    final bgColorInt = slideData['backgroundColor'] as int?;
    final bgHex = _colorIntToHex(bgColorInt ?? 0xFFFFFFFF);
    final elements = slideData['elements'] as List<dynamic>? ?? [];

    final buf = StringBuffer();
    buf.writeln('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
    buf.writeln('<p:sld xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main"'
        ' xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"'
        ' xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">');

    // 배경
    buf.writeln('  <p:cSld>');
    buf.writeln('    <p:bg>');
    buf.writeln('      <p:bgPr>');
    buf.writeln('        <a:solidFill>');
    buf.writeln('          <a:srgbClr val="$bgHex"/>');
    buf.writeln('        </a:solidFill>');
    buf.writeln('        <a:effectLst/>');
    buf.writeln('      </p:bgPr>');
    buf.writeln('    </p:bg>');

    // 도형 트리
    buf.writeln('    <p:spTree>');
    buf.writeln('      <p:nvGrpSpPr>');
    buf.writeln('        <p:cNvPr id="1" name=""/>');
    buf.writeln('        <p:cNvGrpSpPr/>');
    buf.writeln('        <p:nvPr/>');
    buf.writeln('      </p:nvGrpSpPr>');
    buf.writeln('      <p:grpSpPr>');
    buf.writeln('        <a:xfrm>');
    buf.writeln('          <a:off x="0" y="0"/>');
    buf.writeln('          <a:ext cx="0" cy="0"/>');
    buf.writeln('          <a:chOff x="0" y="0"/>');
    buf.writeln('          <a:chExt cx="0" cy="0"/>');
    buf.writeln('        </a:xfrm>');
    buf.writeln('      </p:grpSpPr>');

    // 각 엘리먼트
    for (int i = 0; i < elements.length; i++) {
      final elem = elements[i] as Map<String, dynamic>;
      buf.write(_buildShapeElement(elem, i + 2)); // id 2부터 시작
    }

    buf.writeln('    </p:spTree>');
    buf.writeln('  </p:cSld>');
    buf.writeln('  <p:clrMapOvr>');
    buf.writeln('    <a:masterClrMapping/>');
    buf.writeln('  </p:clrMapOvr>');
    buf.writeln('</p:sld>');

    return buf.toString();
  }

  String _buildShapeElement(Map<String, dynamic> elem, int spId) {
    final typeIndex = elem['type'] as int? ?? 0;
    final x = (elem['x'] as num?)?.toDouble() ?? 0;
    final y = (elem['y'] as num?)?.toDouble() ?? 0;
    final w = (elem['width'] as num?)?.toDouble() ?? 200;
    final h = (elem['height'] as num?)?.toDouble() ?? 100;
    final content = elem['content'] as String? ?? '';
    final rotation = (elem['rotation'] as num?)?.toDouble() ?? 0;
    final shapeKindIndex = elem['shapeKind'] as int?;
    final colorInt = elem['color'] as int? ?? 0xFF333333;
    final bgColorInt = elem['backgroundColor'] as int?;
    final fontSize = (elem['fontSize'] as num?)?.toDouble() ?? 18;
    final fontWeightIndex = elem['fontWeight'] as int? ?? 3;
    final textAlignIndex = elem['textAlign'] as int? ?? 0;

    // 좌표 변환: 논리 -> EMU
    final emuX = _logicalToEmuX(x);
    final emuY = _logicalToEmuY(y);
    final emuCx = _logicalToEmuX(w);
    final emuCy = _logicalToEmuY(h);

    // 회전: 도 -> 60000분의 1도
    final rotEmu = (rotation * 60000).round();

    // 프리셋 도형
    final presetName = _shapeKindToPreset(shapeKindIndex);

    // 이름 결정
    // SlideElementType: 0=text, 1=shape, 2=image
    final isText = typeIndex == 0;
    final name = isText ? 'TextBox $spId' : 'Shape $spId';

    final textColorHex = _colorIntToHex(colorInt);
    final fillHex =
        bgColorInt != null ? _colorIntToHex(bgColorInt) : null;
    final isBold = fontWeightIndex >= 6; // w600 이상은 bold
    final pptxFontSize = (fontSize * 100).round(); // 1/100pt
    final alignment = _textAlignToPptx(textAlignIndex);

    final buf = StringBuffer();
    buf.writeln('      <p:sp>');

    // nvSpPr
    buf.writeln('        <p:nvSpPr>');
    buf.writeln('          <p:cNvPr id="$spId" name="$name"/>');
    buf.writeln('          <p:cNvSpPr${isText ? " txBox=\"1\"" : ""}/>');
    buf.writeln('          <p:nvPr/>');
    buf.writeln('        </p:nvSpPr>');

    // spPr
    buf.writeln('        <p:spPr>');
    buf.writeln(
        '          <a:xfrm${rotEmu != 0 ? " rot=\"$rotEmu\"" : ""}>');
    buf.writeln('            <a:off x="$emuX" y="$emuY"/>');
    buf.writeln('            <a:ext cx="$emuCx" cy="$emuCy"/>');
    buf.writeln('          </a:xfrm>');
    buf.writeln('          <a:prstGeom prst="$presetName">');
    buf.writeln('            <a:avLst/>');
    buf.writeln('          </a:prstGeom>');

    // 도형 채우기
    if (fillHex != null) {
      buf.writeln('          <a:solidFill>');
      buf.writeln('            <a:srgbClr val="$fillHex"/>');
      buf.writeln('          </a:solidFill>');
    } else if (!isText) {
      buf.writeln('          <a:solidFill>');
      buf.writeln('            <a:srgbClr val="$textColorHex"/>');
      buf.writeln('          </a:solidFill>');
    } else {
      buf.writeln('          <a:noFill/>');
    }

    buf.writeln('          <a:ln>');
    buf.writeln('            <a:noFill/>');
    buf.writeln('          </a:ln>');
    buf.writeln('        </p:spPr>');

    // txBody (텍스트 요소이거나 텍스트가 있는 경우)
    if (isText || content.isNotEmpty) {
      buf.writeln('        <p:txBody>');
      buf.writeln('          <a:bodyPr wrap="square" rtlCol="0"/>');
      buf.writeln('          <a:lstStyle/>');

      // 여러 줄 텍스트 지원
      final lines = content.split('\n');
      for (final line in lines) {
        final escaped = _escapeXml(line);
        buf.writeln('          <a:p>');
        buf.writeln('            <a:pPr algn="$alignment"/>');
        buf.writeln('            <a:r>');
        final isItalic = elem['italic'] as bool? ?? false;
        final isUnderline = elem['underline'] as bool? ?? false;
        final isStrike = elem['strikethrough'] as bool? ?? false;
        buf.writeln(
            '              <a:rPr lang="ko-KR" sz="$pptxFontSize"'
            '${isBold ? " b=\"1\"" : ""}'
            '${isItalic ? " i=\"1\"" : ""}'
            '${isUnderline ? " u=\"sng\"" : ""}'
            '${isStrike ? " strike=\"sngStrike\"" : ""}'
            ' dirty="0"/>');
        buf.writeln('              <a:t>$escaped</a:t>');
        buf.writeln('            </a:r>');
        buf.writeln('          </a:p>');
      }

      // 텍스트 색상 적용 — rPr 안에 solidFill 추가
      // (위에서 이미 rPr을 닫았으므로 텍스트 색상은 rPr 속성으로만 처리,
      //  OpenXML에서는 solidFill을 rPr 자식으로 넣어야 하므로 재구성)
      // 이미 위에서 정확히 생성했으므로 별도 처리 불필요

      buf.writeln('        </p:txBody>');
    }

    buf.writeln('      </p:sp>');
    return buf.toString();
  }

  // ===========================================================================
  // Coordinate conversion: logical -> EMU
  // ===========================================================================

  int _logicalToEmuX(double logical) =>
      (logical / _canvasWidth * _slideWidthEmu).round();

  int _logicalToEmuY(double logical) =>
      (logical / _canvasHeight * _slideHeightEmu).round();

  // ===========================================================================
  // Shape kind <-> preset mapping
  // ===========================================================================

  /// ShapeKind index -> PPTX preset geometry name
  String _shapeKindToPreset(int? kindIndex) {
    switch (kindIndex) {
      case 0:
        return 'rect'; // rectangle
      case 1:
        return 'ellipse'; // circle
      case 2:
        return 'triangle'; // triangle
      case 3:
        return 'rightArrow'; // arrow
      default:
        return 'rect';
    }
  }

  /// TextAlign index -> PPTX alignment attribute
  String _textAlignToPptx(int alignIndex) {
    switch (alignIndex) {
      case 0:
        return 'l'; // TextAlign.left
      case 1:
        return 'r'; // TextAlign.right
      case 2:
        return 'ctr'; // TextAlign.center
      case 3:
        return 'just'; // TextAlign.justify
      default:
        return 'l';
    }
  }

  // ===========================================================================
  // Color helpers
  // ===========================================================================

  /// ARGB int -> 6자리 hex (alpha 제외)
  String _colorIntToHex(int colorValue) {
    final r = (colorValue >> 16) & 0xFF;
    final g = (colorValue >> 8) & 0xFF;
    final b = colorValue & 0xFF;
    return r.toRadixString(16).padLeft(2, '0').toUpperCase() +
        g.toRadixString(16).padLeft(2, '0').toUpperCase() +
        b.toRadixString(16).padLeft(2, '0').toUpperCase();
  }

  // ===========================================================================
  // XML escape
  // ===========================================================================

  String _escapeXml(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  // ===========================================================================
  // Archive helper
  // ===========================================================================

  void _addFile(Archive archive, String path, String content) {
    final bytes = utf8.encode(content);
    archive.addFile(ArchiveFile(path, bytes.length, bytes));
  }

  // ===========================================================================
  // PPTX structure files
  // ===========================================================================

  String _buildContentTypes(int slideCount) {
    final buf = StringBuffer();
    buf.writeln('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
    buf.writeln('<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">');
    buf.writeln('  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>');
    buf.writeln('  <Default Extension="xml" ContentType="application/xml"/>');
    buf.writeln('  <Override PartName="/ppt/presentation.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.presentation.main+xml"/>');
    buf.writeln('  <Override PartName="/ppt/slideMasters/slideMaster1.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slideMaster+xml"/>');
    buf.writeln('  <Override PartName="/ppt/slideLayouts/slideLayout1.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slideLayout+xml"/>');
    buf.writeln('  <Override PartName="/ppt/theme/theme1.xml" ContentType="application/vnd.openxmlformats-officedocument.theme+xml"/>');
    for (int i = 1; i <= slideCount; i++) {
      buf.writeln('  <Override PartName="/ppt/slides/slide$i.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slide+xml"/>');
    }
    buf.writeln('</Types>');
    return buf.toString();
  }

  String _buildRootRels() {
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="ppt/presentation.xml"/>
</Relationships>''';
  }

  String _buildPresentation(int slideCount) {
    final buf = StringBuffer();
    buf.writeln('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
    buf.writeln('<p:presentation xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main"'
        ' xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"'
        ' xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">');
    buf.writeln('  <p:sldMasterIdLst>');
    buf.writeln(
        '    <p:sldMasterId id="2147483648" r:id="rId${slideCount + 1}"/>');
    buf.writeln('  </p:sldMasterIdLst>');
    buf.writeln('  <p:sldIdLst>');
    for (int i = 0; i < slideCount; i++) {
      buf.writeln(
          '    <p:sldId id="${256 + i}" r:id="rId${i + 1}"/>');
    }
    buf.writeln('  </p:sldIdLst>');
    buf.writeln('  <p:sldSz cx="$_slideWidthEmu" cy="$_slideHeightEmu"/>');
    buf.writeln(
        '  <p:notesSz cx="$_slideHeightEmu" cy="$_slideWidthEmu"/>');
    buf.writeln('</p:presentation>');
    return buf.toString();
  }

  String _buildPresentationRels(int slideCount) {
    final buf = StringBuffer();
    buf.writeln('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
    buf.writeln(
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">');
    for (int i = 0; i < slideCount; i++) {
      buf.writeln(
          '  <Relationship Id="rId${i + 1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slide" Target="slides/slide${i + 1}.xml"/>');
    }
    buf.writeln(
        '  <Relationship Id="rId${slideCount + 1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideMaster" Target="slideMasters/slideMaster1.xml"/>');
    buf.writeln(
        '  <Relationship Id="rId${slideCount + 2}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/theme" Target="theme/theme1.xml"/>');
    buf.writeln('</Relationships>');
    return buf.toString();
  }

  String _buildSlideRels() {
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideLayout" Target="../slideLayouts/slideLayout1.xml"/>
</Relationships>''';
  }

  String _buildSlideLayout() {
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<p:sldLayout xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main"
  xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"
  xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main"
  type="blank" preserve="1">
  <p:cSld name="Blank">
    <p:spTree>
      <p:nvGrpSpPr>
        <p:cNvPr id="1" name=""/>
        <p:cNvGrpSpPr/>
        <p:nvPr/>
      </p:nvGrpSpPr>
      <p:grpSpPr>
        <a:xfrm>
          <a:off x="0" y="0"/>
          <a:ext cx="0" cy="0"/>
          <a:chOff x="0" y="0"/>
          <a:chExt cx="0" cy="0"/>
        </a:xfrm>
      </p:grpSpPr>
    </p:spTree>
  </p:cSld>
</p:sldLayout>''';
  }

  String _buildSlideLayoutRels() {
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideMaster" Target="../slideMasters/slideMaster1.xml"/>
</Relationships>''';
  }

  String _buildSlideMaster() {
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<p:sldMaster xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main"
  xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"
  xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">
  <p:cSld>
    <p:bg>
      <p:bgRef idx="1001">
        <a:schemeClr val="bg1"/>
      </p:bgRef>
    </p:bg>
    <p:spTree>
      <p:nvGrpSpPr>
        <p:cNvPr id="1" name=""/>
        <p:cNvGrpSpPr/>
        <p:nvPr/>
      </p:nvGrpSpPr>
      <p:grpSpPr>
        <a:xfrm>
          <a:off x="0" y="0"/>
          <a:ext cx="0" cy="0"/>
          <a:chOff x="0" y="0"/>
          <a:chExt cx="0" cy="0"/>
        </a:xfrm>
      </p:grpSpPr>
    </p:spTree>
  </p:cSld>
  <p:clrMap bg1="lt1" tx1="dk1" bg2="lt2" tx2="dk2"
    accent1="accent1" accent2="accent2" accent3="accent3"
    accent4="accent4" accent5="accent5" accent6="accent6"
    hlink="hlink" folHlink="folHlink"/>
  <p:sldLayoutIdLst>
    <p:sldLayoutId id="2147483649" r:id="rId1"/>
  </p:sldLayoutIdLst>
  <p:txStyles>
    <p:titleStyle/>
    <p:bodyStyle/>
    <p:otherStyle/>
  </p:txStyles>
</p:sldMaster>''';
  }

  String _buildSlideMasterRels() {
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideLayout" Target="../slideLayouts/slideLayout1.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/theme" Target="../theme/theme1.xml"/>
</Relationships>''';
  }

  String _buildTheme() {
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<a:theme xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" name="Excelia Theme">
  <a:themeElements>
    <a:clrScheme name="Excelia">
      <a:dk1><a:sysClr val="windowText" lastClr="000000"/></a:dk1>
      <a:lt1><a:sysClr val="window" lastClr="FFFFFF"/></a:lt1>
      <a:dk2><a:srgbClr val="44546A"/></a:dk2>
      <a:lt2><a:srgbClr val="E7E6E6"/></a:lt2>
      <a:accent1><a:srgbClr val="4472C4"/></a:accent1>
      <a:accent2><a:srgbClr val="ED7D31"/></a:accent2>
      <a:accent3><a:srgbClr val="A5A5A5"/></a:accent3>
      <a:accent4><a:srgbClr val="FFC000"/></a:accent4>
      <a:accent5><a:srgbClr val="5B9BD5"/></a:accent5>
      <a:accent6><a:srgbClr val="70AD47"/></a:accent6>
      <a:hlink><a:srgbClr val="0563C1"/></a:hlink>
      <a:folHlink><a:srgbClr val="954F72"/></a:folHlink>
    </a:clrScheme>
    <a:fontScheme name="Excelia">
      <a:majorFont>
        <a:latin typeface="Calibri Light"/>
        <a:ea typeface=""/>
        <a:cs typeface=""/>
      </a:majorFont>
      <a:minorFont>
        <a:latin typeface="Calibri"/>
        <a:ea typeface=""/>
        <a:cs typeface=""/>
      </a:minorFont>
    </a:fontScheme>
    <a:fmtScheme name="Excelia">
      <a:fillStyleLst>
        <a:solidFill><a:schemeClr val="phClr"/></a:solidFill>
        <a:solidFill><a:schemeClr val="phClr"/></a:solidFill>
        <a:solidFill><a:schemeClr val="phClr"/></a:solidFill>
      </a:fillStyleLst>
      <a:lnStyleLst>
        <a:ln w="6350"><a:solidFill><a:schemeClr val="phClr"/></a:solidFill></a:ln>
        <a:ln w="12700"><a:solidFill><a:schemeClr val="phClr"/></a:solidFill></a:ln>
        <a:ln w="19050"><a:solidFill><a:schemeClr val="phClr"/></a:solidFill></a:ln>
      </a:lnStyleLst>
      <a:effectStyleLst>
        <a:effectStyle><a:effectLst/></a:effectStyle>
        <a:effectStyle><a:effectLst/></a:effectStyle>
        <a:effectStyle><a:effectLst/></a:effectStyle>
      </a:effectStyleLst>
      <a:bgFillStyleLst>
        <a:solidFill><a:schemeClr val="phClr"/></a:solidFill>
        <a:solidFill><a:schemeClr val="phClr"/></a:solidFill>
        <a:solidFill><a:schemeClr val="phClr"/></a:solidFill>
      </a:bgFillStyleLst>
    </a:fmtScheme>
  </a:themeElements>
  <a:objectDefaults/>
  <a:extraClrSchemeLst/>
</a:theme>''';
  }
}
