import 'dart:convert';
import 'dart:ui';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:xml/xml.dart';
import 'package:excelia/utils/constants.dart';

/// PPTX 파일을 파싱하여 슬라이드 데이터 맵 리스트로 변환한다.
///
/// 반환 형식은 [Slide.fromJson] / [SlideElement.fromJson] 과 호환되는
/// `Map<String, dynamic>` 리스트이다.
class PptxParser {
  // ===========================================================================
  // Constants
  // ===========================================================================

  /// 표준 16:9 슬라이드 EMU 크기
  static const int _slideWidthEmu = 12192000;
  static const int _slideHeightEmu = 6858000;

  /// 논리 캔버스 크기
  static const double _canvasWidth = 960.0;
  static const double _canvasHeight = 540.0;

  /// OpenXML 네임스페이스
  static const _nsA =
      'http://schemas.openxmlformats.org/drawingml/2006/main';
  static const _nsP =
      'http://schemas.openxmlformats.org/presentationml/2006/main';
  static const _nsR =
      'http://schemas.openxmlformats.org/officeDocument/2006/relationships';
  /// PPTX preset geometry name -> ShapeKind index 매핑
  /// (presentation_provider.dart 의 ShapeKind enum 순서 기준)
  ///   0: rectangle, 1: circle, 2: triangle, 3: arrow
  static const Map<String, int> _presetToShapeKind = {
    'rect': 0,
    'roundRect': 0,
    'snip1Rect': 0,
    'snip2SameRect': 0,
    'ellipse': 1,
    'triangle': 2,
    'rtTriangle': 2,
    'rightArrow': 3,
    'leftArrow': 3,
    'upArrow': 3,
    'downArrow': 3,
    'leftRightArrow': 3,
    'upDownArrow': 3,
    'bentArrow': 3,
    'curvedRightArrow': 3,
    'notchedRightArrow': 3,
    'stripedRightArrow': 3,
    'chevron': 3,
  };

  // ===========================================================================
  // Public API
  // ===========================================================================

  /// PPTX 바이트를 파싱하여 슬라이드 데이터 맵 리스트를 반환한다.
  /// 실패 시 `null` 을 반환한다.
  List<Map<String, dynamic>>? parse(Uint8List bytes) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);

      // 1) 슬라이드 순서 결정 (presentation.xml + rels)
      final slideTargets = _resolveSlideOrder(archive);
      if (slideTargets.isEmpty) return null;

      // 2) 각 슬라이드 파싱
      final slides = <Map<String, dynamic>>[];
      for (int i = 0; i < slideTargets.length; i++) {
        final slideMap = _parseSlideFile(archive, slideTargets[i], i + 1);
        if (slideMap != null) {
          slides.add(slideMap);
        }
      }

      return slides.isEmpty ? null : slides;
    } catch (e) {
      debugPrint('PPTX parse failed: $e');
      return null;
    }
  }

  // ===========================================================================
  // Slide order resolution
  // ===========================================================================

  /// presentation.xml 의 sldIdLst 와 rels 를 조합하여 슬라이드 파일 경로를
  /// 올바른 순서로 반환한다.
  List<String> _resolveSlideOrder(Archive archive) {
    final targets = <String>[];

    try {
      // presentation.xml.rels 파싱 → rId -> target
      final relsMap =
          _parseRels(archive, 'ppt/_rels/presentation.xml.rels');

      // presentation.xml 파싱 → sldIdLst 순서대로 rId 수집
      final presFile = _findFile(archive, 'ppt/presentation.xml');
      if (presFile == null) return _fallbackSlideOrder(archive);

      final presDoc = XmlDocument.parse(_readXml(presFile));
      final root = presDoc.rootElement;

      final sldIdLst = _findElement(root, 'sldIdLst', _nsP);
      if (sldIdLst == null) return _fallbackSlideOrder(archive);

      for (final sldId in sldIdLst.childElements) {
        if (sldId.localName != 'sldId') continue;
        final rId = sldId.getAttribute('id', namespace: _nsR) ??
            sldId.getAttribute('r:id') ??
            '';
        final target = relsMap[rId];
        if (target != null) {
          final path = target.startsWith('/')
              ? target.substring(1)
              : 'ppt/$target';
          targets.add(path);
        }
      }
    } catch (e) {
      debugPrint('PPTX slide order resolution failed: $e');
    }

    return targets.isEmpty ? _fallbackSlideOrder(archive) : targets;
  }

  /// presentation.xml 파싱 실패 시 파일명 순서로 폴백
  List<String> _fallbackSlideOrder(Archive archive) {
    final paths = <String>[];
    for (int i = 1; i <= 100; i++) {
      final path = 'ppt/slides/slide$i.xml';
      if (_findFile(archive, path) != null) {
        paths.add(path);
      } else {
        break;
      }
    }
    return paths;
  }

  // ===========================================================================
  // Slide file parsing
  // ===========================================================================

  Map<String, dynamic>? _parseSlideFile(
      Archive archive, String slidePath, int slideNumber) {
    try {
      final file = _findFile(archive, slidePath);
      if (file == null) return null;

      final doc = XmlDocument.parse(_readXml(file));
      final root = doc.rootElement;

      // 배경색 추출
      final bgColor = _parseSlideBackground(root);

      // 엘리먼트 파싱
      final elements = <Map<String, dynamic>>[];

      // <p:cSld> 아래 <p:spTree> 의 <p:sp> 들을 순회
      final cSld = _findElement(root, 'cSld', _nsP);
      if (cSld != null) {
        final spTree = _findElement(cSld, 'spTree', _nsP);
        if (spTree != null) {
          for (final child in spTree.childElements) {
            if (child.localName == 'sp') {
              final elem = _parseShape(child);
              if (elem != null) elements.add(elem);
            }
          }
        }
      }

      return {
        'title': 'Slide $slideNumber',
        'backgroundColor': bgColor.toARGB32(),
        'elements': elements,
      };
    } catch (e) {
      debugPrint('PPTX slide parse failed: $e');
      return null;
    }
  }

  // ===========================================================================
  // Background
  // ===========================================================================

  Color _parseSlideBackground(XmlElement root) {
    try {
      final cSld = _findElement(root, 'cSld', _nsP);
      if (cSld == null) return Colors.white;

      final bg = _findElement(cSld, 'bg', _nsP);
      if (bg == null) return Colors.white;

      final bgPr = _findElement(bg, 'bgPr', _nsP);
      if (bgPr != null) {
        final solidFill = _findElement(bgPr, 'solidFill', _nsA);
        if (solidFill != null) {
          return _parseFillColor(solidFill) ?? Colors.white;
        }
      }

      // bgRef 에서도 시도
      final bgRef = _findElement(bg, 'bgRef', _nsP);
      if (bgRef != null) {
        final srgbClr = _findElement(bgRef, 'srgbClr', _nsA);
        if (srgbClr != null) {
          return _parseHexColor(srgbClr.getAttribute('val')) ?? Colors.white;
        }
      }
    } catch (e) {
      debugPrint('PPTX slide background parse failed: $e');
    }
    return Colors.white;
  }

  // ===========================================================================
  // Shape parsing (<p:sp>)
  // ===========================================================================

  Map<String, dynamic>? _parseShape(XmlElement sp) {
    try {
      final spPr = _findElement(sp, 'spPr', _nsP);
      if (spPr == null) return null;

      // 위치 · 크기 (xfrm)
      final xfrm = _findElement(spPr, 'xfrm', _nsA);
      double x = 0, y = 0, width = 200, height = 100;
      double rotation = 0;

      if (xfrm != null) {
        final off = _findElement(xfrm, 'off', _nsA);
        final ext = _findElement(xfrm, 'ext', _nsA);

        if (off != null) {
          x = _emuToLogicalX(
              int.tryParse(off.getAttribute('x') ?? '') ?? 0);
          y = _emuToLogicalY(
              int.tryParse(off.getAttribute('y') ?? '') ?? 0);
        }
        if (ext != null) {
          width = _emuToLogicalX(
              int.tryParse(ext.getAttribute('cx') ?? '') ?? 0);
          height = _emuToLogicalY(
              int.tryParse(ext.getAttribute('cy') ?? '') ?? 0);
        }

        // 회전: EMU 단위의 60000분의 1도
        final rotAttr = xfrm.getAttribute('rot');
        if (rotAttr != null) {
          final rotEmu = int.tryParse(rotAttr) ?? 0;
          rotation = rotEmu / PptxDefaults.emuRotationDivisor;
        }
      }

      // 최소 크기 보정
      if (width < 1) width = 200;
      if (height < 1) height = 100;

      // 타입 · 도형 종류 결정
      final hasText = _findElement(sp, 'txBody', _nsP) != null;
      final prstGeom = _findElement(spPr, 'prstGeom', _nsA);
      final presetName = prstGeom?.getAttribute('prst');
      final shapeKindIndex = presetName != null
          ? _presetToShapeKind[presetName]
          : null;

      // 텍스트 추출
      String content = '';
      double fontSize = 18;
      int fontWeightIndex = 3; // FontWeight.normal
      int textAlignIndex = 0; // TextAlign.left
      bool italic = false;
      bool underline = false;
      bool strikethrough = false;

      final txBody = _findElement(sp, 'txBody', _nsP);
      if (txBody != null) {
        final textResult = _parseTextBody(txBody);
        content = textResult.text;
        fontSize = textResult.fontSize;
        fontWeightIndex = textResult.fontWeightIndex;
        textAlignIndex = textResult.textAlignIndex;
        italic = textResult.italic;
        underline = textResult.underline;
        strikethrough = textResult.strikethrough;
      }

      // 타입 결정: 텍스트가 있으면 text (0), 도형이면 shape (1)
      int typeIndex;
      if (hasText && content.isNotEmpty) {
        typeIndex = 0; // SlideElementType.text
      } else if (shapeKindIndex != null) {
        typeIndex = 1; // SlideElementType.shape
      } else if (content.isNotEmpty) {
        typeIndex = 0;
      } else {
        typeIndex = 1;
      }

      // 색상
      Color color = const Color(0xFF333333);
      Color? backgroundColor;

      // 채우기 색상 (도형 배경)
      final solidFill = _findElement(spPr, 'solidFill', _nsA);
      if (solidFill != null) {
        backgroundColor = _parseFillColor(solidFill);
      }

      // 텍스트 색상
      if (txBody != null) {
        final textColor = _extractTextColor(txBody);
        if (textColor != null) {
          color = textColor;
        }
      }

      return {
        'type': typeIndex,
        'x': x,
        'y': y,
        'width': width,
        'height': height,
        'content': content,
        'shapeKind': shapeKindIndex,
        'color': color.toARGB32(),
        'backgroundColor': backgroundColor?.toARGB32(),
        'fontSize': fontSize,
        'fontWeight': fontWeightIndex,
        'italic': italic,
        'underline': underline,
        'strikethrough': strikethrough,
        'textAlign': textAlignIndex,
        'borderRadius': 0.0,
        'rotation': rotation,
      };
    } catch (e) {
      debugPrint('PPTX shape parse failed: $e');
      return null;
    }
  }

  // ===========================================================================
  // Text body parsing (<p:txBody>)
  // ===========================================================================

  _TextParseResult _parseTextBody(XmlElement txBody) {
    final buffer = StringBuffer();
    double fontSize = 18;
    int fontWeightIndex = 3; // FontWeight.normal (index 3)
    int textAlignIndex = 0; // TextAlign.left
    bool italic = false;
    bool underline = false;
    bool strikethrough = false;

    bool firstParagraph = true;
    bool fontInfoExtracted = false;

    for (final p in txBody.childElements) {
      if (p.localName != 'p') continue;

      if (!firstParagraph) buffer.write('\n');
      firstParagraph = false;

      // 단락 정렬: <a:pPr algn="ctr"/>
      final pPr = _findElement(p, 'pPr', _nsA);
      if (pPr != null && !fontInfoExtracted) {
        final algn = pPr.getAttribute('algn');
        textAlignIndex = _mapAlignment(algn);
      }

      for (final r in p.childElements) {
        if (r.localName == 'r') {
          // <a:t> 텍스트
          final t = _findElement(r, 't', _nsA);
          if (t != null) buffer.write(t.innerText);

          // <a:rPr> 런 속성 (첫 번째 런에서만 추출)
          if (!fontInfoExtracted) {
            final rPr = _findElement(r, 'rPr', _nsA);
            if (rPr != null) {
              // 폰트 크기: sz 속성 (1/100pt 단위)
              final sz = rPr.getAttribute('sz');
              if (sz != null) {
                final hundredthsPt = int.tryParse(sz);
                if (hundredthsPt != null && hundredthsPt > 0) {
                  fontSize = hundredthsPt / PptxDefaults.hundredthsPointDivisor;
                }
              }

              // 볼드
              final b = rPr.getAttribute('b');
              if (b == '1' || b == 'true') {
                fontWeightIndex = 7; // FontWeight.bold (index 7)
              }

              // 이탤릭
              final iAttr = rPr.getAttribute('i');
              if (iAttr == '1' || iAttr == 'true') {
                italic = true;
              }

              // 밑줄
              final uAttr = rPr.getAttribute('u');
              if (uAttr == 'sng' || uAttr == 'dbl' || uAttr == 'heavy') {
                underline = true;
              }

              // 취소선
              final strikeAttr = rPr.getAttribute('strike');
              if (strikeAttr == 'sngStrike' || strikeAttr == 'dblStrike') {
                strikethrough = true;
              }

              fontInfoExtracted = true;
            }
          }
        } else if (r.localName == 'br') {
          buffer.write('\n');
        }
      }
    }

    return _TextParseResult(
      text: buffer.toString(),
      fontSize: fontSize,
      fontWeightIndex: fontWeightIndex,
      textAlignIndex: textAlignIndex,
      italic: italic,
      underline: underline,
      strikethrough: strikethrough,
    );
  }

  /// 텍스트 바디에서 첫 번째 런의 텍스트 색상 추출
  Color? _extractTextColor(XmlElement txBody) {
    try {
      for (final p in txBody.childElements) {
        if (p.localName != 'p') continue;
        for (final r in p.childElements) {
          if (r.localName != 'r') continue;
          final rPr = _findElement(r, 'rPr', _nsA);
          if (rPr == null) continue;

          final solidFill = _findElement(rPr, 'solidFill', _nsA);
          if (solidFill != null) {
            return _parseFillColor(solidFill);
          }
        }
      }
    } catch (e) {
      debugPrint('PPTX text color parse failed: $e');
    }
    return null;
  }

  /// PPTX 정렬 속성값 -> TextAlign index 매핑
  int _mapAlignment(String? algn) {
    switch (algn) {
      case 'l':
        return 0; // TextAlign.left
      case 'ctr':
        return 2; // TextAlign.center
      case 'r':
        return 1; // TextAlign.right
      case 'just':
        return 3; // TextAlign.justify
      default:
        return 0;
    }
  }

  // ===========================================================================
  // Color parsing
  // ===========================================================================

  /// `solidFill` 아래 srgbClr 또는 schemeClr 로부터 Color 추출
  Color? _parseFillColor(XmlElement solidFill) {
    // srgbClr: 직접 지정된 RGB
    final srgbClr = _findElement(solidFill, 'srgbClr', _nsA);
    if (srgbClr != null) {
      return _parseHexColor(srgbClr.getAttribute('val'));
    }

    // schemeClr: 테마 색상 — 정확한 해석에는 theme.xml 파싱이 필요하지만,
    // 대표적인 scheme 이름에 대한 폴백 매핑 제공
    final schemeClr = _findElement(solidFill, 'schemeClr', _nsA);
    if (schemeClr != null) {
      return _schemeColorFallback(schemeClr.getAttribute('val'));
    }

    return null;
  }

  /// 6자리 hex 문자열 -> Color
  Color? _parseHexColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    // 6자리 또는 8자리 hex 모두 처리
    final clean = hex.replaceAll('#', '');
    final value = int.tryParse(clean, radix: 16);
    if (value == null) return null;
    if (clean.length == 6) {
      return Color(0xFF000000 | value);
    } else if (clean.length == 8) {
      return Color(value);
    }
    return null;
  }

  /// 테마 scheme 색상 폴백 (theme.xml 파싱 없이 대략적 매핑)
  Color? _schemeColorFallback(String? scheme) {
    switch (scheme) {
      case 'tx1':
      case 'dk1':
        return const Color(0xFF000000);
      case 'tx2':
      case 'dk2':
        return const Color(0xFF44546A);
      case 'bg1':
      case 'lt1':
        return const Color(0xFFFFFFFF);
      case 'bg2':
      case 'lt2':
        return const Color(0xFFE7E6E6);
      case 'accent1':
        return const Color(0xFF4472C4);
      case 'accent2':
        return const Color(0xFFED7D31);
      case 'accent3':
        return const Color(0xFFA5A5A5);
      case 'accent4':
        return const Color(0xFFFFC000);
      case 'accent5':
        return const Color(0xFF5B9BD5);
      case 'accent6':
        return const Color(0xFF70AD47);
      default:
        return null;
    }
  }

  // ===========================================================================
  // EMU <-> logical coordinate conversion
  // ===========================================================================

  double _emuToLogicalX(int emu) => emu / _slideWidthEmu * _canvasWidth;
  double _emuToLogicalY(int emu) => emu / _slideHeightEmu * _canvasHeight;

  // ===========================================================================
  // Rels parsing
  // ===========================================================================

  Map<String, String> _parseRels(Archive archive, String relsPath) {
    final map = <String, String>{};
    final file = _findFile(archive, relsPath);
    if (file == null) return map;

    try {
      final doc = XmlDocument.parse(_readXml(file));
      for (final rel in doc.rootElement.childElements) {
        if (rel.localName != 'Relationship') continue;
        final id = rel.getAttribute('Id') ?? '';
        final target = rel.getAttribute('Target') ?? '';
        if (id.isNotEmpty && target.isNotEmpty) {
          map[id] = target;
        }
      }
    } catch (e) {
      debugPrint('PPTX rels parse failed: $e');
    }
    return map;
  }

  // ===========================================================================
  // XML / Archive helpers
  // ===========================================================================

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

  /// 네임스페이스를 고려한 자식 엘리먼트 검색
  XmlElement? _findElement(
      XmlElement parent, String localName, String namespace) {
    // 정확한 네임스페이스 매칭 시도
    for (final child in parent.childElements) {
      if (child.localName == localName &&
          child.name.namespaceUri == namespace) {
        return child;
      }
    }
    // 네임스페이스 없이 localName 만으로 폴백
    for (final child in parent.childElements) {
      if (child.localName == localName) {
        return child;
      }
    }
    return null;
  }
}

// =============================================================================
// Internal data class
// =============================================================================

class _TextParseResult {
  final String text;
  final double fontSize;
  final int fontWeightIndex;
  final int textAlignIndex;
  final bool italic;
  final bool underline;
  final bool strikethrough;

  const _TextParseResult({
    required this.text,
    required this.fontSize,
    required this.fontWeightIndex,
    required this.textAlignIndex,
    this.italic = false,
    this.underline = false,
    this.strikethrough = false,
  });
}
