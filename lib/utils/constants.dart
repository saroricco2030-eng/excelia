import 'package:flutter/material.dart';

// =============================================================================
// App Colors — Lavender Pastel + Soft Glassmorphism (2026 redesign)
// =============================================================================

class AppColors {
  AppColors._();

  // ── Base ──
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color transparent = Color(0x00000000);

  /// Indigo 400 — app brand color
  static const Color primary = Color(0xFF818CF8);
  /// Violet 400 — secondary accent
  static const Color accent = Color(0xFFA78BFA);

  // ── Light Theme Pastel ──
  static const Color lightBackground = Color(0xFFF3F0F9);       // lavender tint bg
  static const Color lightSurface = Color(0xFFFFFFFF);           // pure white card
  static const Color lightSurfaceElevated = Color(0xFFF8F6FC);   // light lavender surface
  static const Color lightOnSurface = Color(0xFF1E1B2E);         // deep purple-black
  static const Color lightOnSurfaceAlt = Color(0xFF6B6580);      // medium purple-gray
  static const Color lightTextMuted = Color(0xFF6B6380);         // WCAG AA 4.8:1 on lightBackground
  static const Color lightOutline = Color(0xFFE4DFF0);           // soft lavender border
  static const Color lightOutlineHi = Color(0xFFD0C9E2);         // strong lavender border

  // ── Dark Theme ──
  static const Color darkBackground = Color(0xFF0F0D15);         // deep purple-black
  static const Color darkSurface = Color(0xFF1A1726);             // purple surface
  static const Color darkSurfaceElevated = Color(0xFF242033);     // lighter purple surface
  static const Color darkOnSurface = Color(0xFFF0EDF5);           // light lavender-white
  static const Color darkOnSurfaceAlt = Color(0xFFA9A1BC);        // medium purple
  static const Color darkTextMuted = Color(0xFF9088A8);           // WCAG AA 5.5:1 on darkBackground
  static const Color darkOutline = Color(0xFF302B42);             // purple border
  static const Color darkOutlineHi = Color(0xFF433D5C);           // strong purple border
  static const Color darkCardBackground = Color(0xFF1A1726);      // same as surface

  // ── Neutral ──
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);

  // ── Status / Feedback (pastel versions) ──
  static const Color warning = Color(0xFFFBBF24);
  static const Color warningAccent = Color(0xFFFFAB40);
  static const Color error = Color(0xFFF87171);
  static const Color success = Color(0xFF34D399);
  static const Color info = Color(0xFF60A5FA);

  // ── Module brand colors (PASTEL) ──
  static const Color spreadsheetGreen = Color(0xFF4ADE80);
  static const Color documentBlue = Color(0xFF60A5FA);
  static const Color presentationOrange = Color(0xFFFB923C);
  static const Color pdfRed = Color(0xFFF87171);

  // ── Module tints (Light) ──
  static const Color spreadsheetTintLight = Color(0xFFECFDF5);
  static const Color documentTintLight = Color(0xFFEFF6FF);
  static const Color presentationTintLight = Color(0xFFFFF7ED);
  static const Color pdfTintLight = Color(0xFFFEF2F2);

  // ── Module tints (Dark) ──
  static const Color spreadsheetTintDark = Color(0xFF0D2818);
  static const Color documentTintDark = Color(0xFF0F1D2E);
  static const Color presentationTintDark = Color(0xFF2E1A0D);
  static const Color pdfTintDark = Color(0xFF2E1010);

  // ── Header Gradient (Light) — soft lavender ──
  static const Color headerLight1 = Color(0xFF2D1B69);
  static const Color headerLight2 = Color(0xFF4338CA);
  static const Color headerLight3 = primary;

  // ── Header Gradient (Dark) — deep purple ──
  static const Color headerDark1 = Color(0xFF0F0D15);
  static const Color headerDark2 = Color(0xFF1A1040);
  static const Color headerDark3 = Color(0xFF312E81);

  // ── Interactive / Selection ──
  static const Color selectionBlue = Color(0xFF818CF8);    // use primary
  static const Color shapeDefault = Color(0xFF818CF8);

  // ── Grid ──
  static const Color gridLine = Color(0xFFE4DFF0);         // use lavender outline

  // ── Accent glow ──
  static const Color accentGlow = Color(0x26818CF8);       // 15% indigo
  static const Color accentDim = Color(0x1F818CF8);        // 12% indigo
  static const Color accentDimLight = Color(0xFFE8E5FF);   // solid light indigo bg

  // ── Gradient pairs ──
  static const Color gradientStart = primary;
  static const Color gradientEnd = accent;

  // ── Glass tokens ──
  static const Color glassLightBg = Color(0xB3FFFFFF);     // 70% white
  static const Color glassLightBorder = Color(0x80FFFFFF);  // 50% white
  static const Color glassDarkBg = Color(0xBF1A1726);       // 75% dark surface
  static const Color glassDarkBorder = Color(0x14FFFFFF);    // 8% white
  static const Color glassWhite = Color(0x12FFFFFF);
  static const Color glassBorder = Color(0x1AFFFFFF);
  static const Color glassHighlight = Color(0x0DFFFFFF);

  // ── Toolbar ──
  static const Color toolbarDark = Color(0xCC1A1726);       // 80% dark surface
  static const Color toolbarLight = Color(0xE6F8F6FC);      // 90% light surface

  // ── Hyperlink ──
  static const Color hyperlinkBlue = Color(0xFF60A5FA);     // pastel blue

  // ── Search ──
  static const Color searchHighlight = Color(0x40FFEB3B);

  // ── Annotations ──
  static const Color annotationYellow = Color(0xFFFBBF24);
  static const Color annotationGreen = Color(0xFF34D399);
  static const Color annotationBlue = Color(0xFF60A5FA);
  static const Color annotationRed = Color(0xFFF87171);
  static const Color annotationOrange = Color(0xFFFB923C);

  // ── Spreadsheet Cell Color Palette ──
  static const List<Color> cellColors = [
    Color(0xFF000000), Color(0xFF434343), Color(0xFF666666),
    Color(0xFF999999), Color(0xFFB7B7B7), Color(0xFFCCCCCC),
    Color(0xFFD9D9D9), Color(0xFFFFFFFF),
    Color(0xFF980000), Color(0xFFFF0000), Color(0xFFFF9900),
    Color(0xFFFFFF00), Color(0xFF00FF00), Color(0xFF00FFFF),
    Color(0xFF4A86E8), Color(0xFF0000FF), Color(0xFF9900FF),
    Color(0xFFFF00FF),
  ];

  static const List<Color> cellBackgrounds = [
    Color(0xFFE6B8AF), Color(0xFFF4CCCC), Color(0xFFFCE5CD),
    Color(0xFFFFF2CC), Color(0xFFD9EAD3), Color(0xFFD0E0E3),
    Color(0xFFC9DAF8), Color(0xFFCFE2F3), Color(0xFFD9D2E9),
    Color(0xFFEAD1DC),
  ];

  // ── Presentation color presets ──
  static const Color red = Color(0xFFF44336);
  static const Color orange = Color(0xFFFF9800);
  static const Color amber = Color(0xFFFFC107);
  static const Color green = Color(0xFF4CAF50);
  static const Color blue = Color(0xFF2196F3);
  static const Color indigo = Color(0xFF3F51B5);
  static const Color purple = Color(0xFF9C27B0);

  // ── Shape default fills ──
  static const Color shapeBlue = Color(0xFFBBDEFB);
  static const Color shapeGreen = Color(0xFFC8E6C9);
  static const Color shapeOrange = Color(0xFFFFE0B2);
  static const Color shapeGrey = Color(0xFFE0E0E0);

  // ── Slide content defaults (document format — persists in .pptx) ──
  // Not theme-dependent; these are content colors embedded in the file.
  static const Color slideTitleText = Color(0xFF333333);     // dark gray — title default
  static const Color slideSubtitleText = Color(0xFF666666);  // medium gray — subtitle/body
  static const Color slideSectionBg = Color(0xFF2C3E50);     // section break dark bg

  // ── Slide background presets ──
  static const List<Color> slideBackgrounds = [
    white,
    Color(0xFFF5F5F5), Color(0xFF1B1B1F), Color(0xFF1A237E),
    Color(0xFF0D47A1), Color(0xFF004D40), Color(0xFF880E4F),
    Color(0xFFFFF3E0), Color(0xFFE3F2FD), Color(0xFFE8F5E9),
  ];

  // ── Hero card gradients ──
  static const Color heroGradientDark1 = Color(0xFF1A1030);
  static const Color heroGradientDark2 = Color(0xFF0F1628);
  static const Color heroGradientLight1 = Color(0xFF4338CA);

  // ── Tab backgrounds ──
  static const Color liquidBg = Color(0xFF0F0D15);
  static const Color liquidOrb1 = Color(0xFF4F46E5);
  static const Color liquidOrb2 = Color(0xFF7C3AED);
  static const Color liquidOrb3 = Color(0xFF0EA5E9);
  static const Color liquidOrb4 = Color(0xFFEC4899);

  static const Color neonRed = Color(0xFFFF2D20);
  static const Color neonGreen = Color(0xFF34D399);

  static const Color commandBg = Color(0xFF0F0D15);
  static const Color commandInput = Color(0xFF1A1726);
  static const Color commandBorder = Color(0xFF302B42);

  static const Color auroraBg = Color(0xFFF3F0F9);
  static const Color auroraText = Color(0xFF1E1B2E);
  static const Color auroraPink = Color(0xFFF472B6);
  static const Color auroraGreen = Color(0xFF34D399);
  static const Color auroraAmber = Color(0xFFFBBF24);
}

/// Alias so UI code can reference [ExceliaColors.spreadsheetGreen] etc.
typedef ExceliaColors = AppColors;

// =============================================================================
// App Sizes
// =============================================================================

class AppSizes {
  AppSizes._();

  // Padding / Margin
  static const double paddingXS = 4.0;
  static const double paddingSM = 8.0;
  static const double paddingMD = 12.0;
  static const double paddingLG = 16.0;
  static const double paddingXL = 24.0;
  static const double paddingXXL = 32.0;

  // Spacing gaps (for SizedBox usage)
  static const double gap2 = 2.0;
  static const double gap4 = 4.0;
  static const double gap6 = 6.0;
  static const double gap8 = 8.0;
  static const double gap10 = 10.0;
  static const double gap12 = 12.0;
  static const double gap16 = 16.0;
  static const double gap20 = 20.0;
  static const double gap24 = 24.0;
  static const double gap32 = 32.0;
  static const double gap40 = 40.0;
  static const double gap48 = 48.0;

  // Border radius
  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 20.0;
  static const double radiusXXL = 24.0;
  static const double radiusPill = 999.0;

  // Icon
  static const double iconSM = 18.0;
  static const double iconMD = 24.0;
  static const double iconLG = 32.0;
  static const double iconXL = 48.0;

  // AppBar
  static const double appBarHeight = 48.0;

  // Bottom Nav
  static const double bottomNavHeight = 64.0;

  // Quick action card
  static const double quickActionCardWidth = 110.0;
  static const double quickActionCardHeight = 110.0;

  // Recent file tile
  static const double recentFileIconSize = 42.0;

  // Max recent files stored
  static const int maxRecentFiles = 50;
}

// =============================================================================
// App Shadows — Pastel-tinted
// =============================================================================

class AppShadows {
  AppShadows._();

  static List<BoxShadow> get cardShadow => const [
    BoxShadow(
      color: Color(0x0D1E1B2E),       // purple-tinted shadow
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get elevatedShadow => const [
    BoxShadow(
      color: Color(0x1A1E1B2E),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get glowIndigo => const [
    BoxShadow(
      color: AppColors.accentGlow,
      blurRadius: 24,
      spreadRadius: -4,
    ),
  ];
}

// =============================================================================
// Domain Constants
// =============================================================================

class SpreadsheetDefaults {
  SpreadsheetDefaults._();

  static const int totalRows = 100;
  static const int totalCols = 26;
  static const double defaultColWidth = 100.0;
  static const double defaultRowHeight = 28.0;
  static const int maxUndoStack = 50;
  static const int secondsPerDay = 86400;
  static const int secondsPerHour = 3600;
  static const double floatEpsilon = 1e-9;
}

class DocumentDefaults {
  DocumentDefaults._();

  static const int wordsPerPage = 500;
  static const int wordsPerMinute = 200;
  static const int linesPerPage = 45;
  static const int maxPages = 9999;
}

class XlsxParserDefaults {
  XlsxParserDefaults._();

  static const double colWidthToPixel = 7.5;
  static const double rowHeightToPixel = 1.33;
  static const double minColWidthPx = 30.0;
  static const double maxColWidthPx = 500.0;
  static const double minRowHeightPx = 16.0;
  static const double maxRowHeightPx = 300.0;
  static const int maxColumns = 200;
}

class DocxDefaults {
  DocxDefaults._();

  static const int defaultImageWidthEmu = 4572000;
  static const int defaultImageHeightEmu = 2743200;
}

class PptxDefaults {
  PptxDefaults._();

  static const double emuRotationDivisor = 60000.0;
  static const double hundredthsPointDivisor = 100.0;
}
