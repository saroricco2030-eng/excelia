import 'package:pdf/pdf.dart';

// =============================================================================
// Print Setup Enums
// =============================================================================

enum PaperSize { a4, a5, letter, legal }

enum MarginPreset { normal, narrow, wide }

enum ScaleMode { fitWidth, fitPage, actual }

/// 인쇄 페이지 설정 — 스프레드시트 PDF 생성 시 참조
class PrintSetup {
  final PaperSize paperSize;
  final bool isLandscape;
  final MarginPreset marginPreset;
  final ScaleMode scaleMode;
  final bool showGridlines;
  final bool showFileName;
  final bool showPageNumbers;

  const PrintSetup({
    this.paperSize = PaperSize.a4,
    this.isLandscape = true,
    this.marginPreset = MarginPreset.normal,
    this.scaleMode = ScaleMode.fitWidth,
    this.showGridlines = true,
    this.showFileName = true,
    this.showPageNumbers = true,
  });

  PrintSetup copyWith({
    PaperSize? paperSize,
    bool? isLandscape,
    MarginPreset? marginPreset,
    ScaleMode? scaleMode,
    bool? showGridlines,
    bool? showFileName,
    bool? showPageNumbers,
  }) {
    return PrintSetup(
      paperSize: paperSize ?? this.paperSize,
      isLandscape: isLandscape ?? this.isLandscape,
      marginPreset: marginPreset ?? this.marginPreset,
      scaleMode: scaleMode ?? this.scaleMode,
      showGridlines: showGridlines ?? this.showGridlines,
      showFileName: showFileName ?? this.showFileName,
      showPageNumbers: showPageNumbers ?? this.showPageNumbers,
    );
  }

  /// 용지 크기 → PdfPageFormat (방향 적용)
  PdfPageFormat get pageFormat {
    PdfPageFormat base;
    switch (paperSize) {
      case PaperSize.a5:
        base = PdfPageFormat.a5;
      case PaperSize.letter:
        base = PdfPageFormat.letter;
      case PaperSize.legal:
        base = PdfPageFormat.legal;
      case PaperSize.a4:
        base = PdfPageFormat.a4;
    }
    return isLandscape ? base.landscape : base.portrait;
  }

  /// 여백 프리셋 → 포인트 값 (상하좌우 동일)
  double get marginValue {
    switch (marginPreset) {
      case MarginPreset.narrow:
        return 12.0;
      case MarginPreset.wide:
        return 36.0;
      case MarginPreset.normal:
        return 24.0;
    }
  }

  /// 용지 크기 enum 목록
  static const List<PaperSize> paperSizes = PaperSize.values;

  /// 여백 프리셋 enum 목록
  static const List<MarginPreset> marginPresets = MarginPreset.values;

  /// 배율 모드 enum 목록
  static const List<ScaleMode> scaleModes = ScaleMode.values;
}
