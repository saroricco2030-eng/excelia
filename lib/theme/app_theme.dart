import 'package:flutter/material.dart';
import 'package:excelia/utils/constants.dart';

const _fontFamily = 'NotoSansKR';

class AppTheme {
  AppTheme._();

  // ─── Light Theme ──────────────────────────────────────
  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);
    final textTheme = _buildTextTheme(AppColors.lightOnSurface);

    return base.copyWith(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.lightSurface,
        error: AppColors.error,
        onPrimary: AppColors.white,
        onSecondary: AppColors.white,
        onSurface: AppColors.lightOnSurface,
        onError: AppColors.white,
        outline: AppColors.lightOutline,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: AppColors.transparent,
        toolbarHeight: AppSizes.appBarHeight,
        backgroundColor: AppColors.lightBackground,
        foregroundColor: AppColors.lightOnSurface,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: const IconThemeData(color: AppColors.lightOnSurface, size: 22),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLG),
          side: const BorderSide(color: AppColors.lightOutline, width: 0.5),
        ),
        margin: EdgeInsets.zero,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.lightSurface,
        elevation: 0,
        height: 72,
        indicatorColor: AppColors.accentDimLight,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary, size: 24);
          }
          return IconThemeData(color: AppColors.lightOnSurfaceAlt, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final style = TextStyle(fontFamily: _fontFamily,fontSize: 12, height: 1.3);
          if (states.contains(WidgetState.selected)) {
            return style.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600);
          }
          return style.copyWith(color: AppColors.lightOnSurfaceAlt, fontWeight: FontWeight.w500);
        }),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.lightSurface,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        dragHandleColor: AppColors.lightOutlineHi,
        dragHandleSize: const Size(36, 4),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusXL),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMD),
          borderSide: BorderSide(color: AppColors.lightOutline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMD),
          borderSide: BorderSide(color: AppColors.lightOutline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMD),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusPill),
          ),
          textStyle: TextStyle(fontFamily: _fontFamily,fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 3,
        shape: const StadiumBorder(),
      ),
      listTileTheme: const ListTileThemeData(
        dense: true,
        visualDensity: VisualDensity.compact,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.lightOutline,
        thickness: 0.5,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.lightOnSurface,
        contentTextStyle: TextStyle(fontFamily: _fontFamily,color: AppColors.lightSurface, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMD)),
        behavior: SnackBarBehavior.floating,
      ),
      tooltipTheme: const TooltipThemeData(
        preferBelow: true,
        waitDuration: Duration(milliseconds: 500),
      ),
    );
  }

  // ─── Dark Theme ──────────────────────────────────────
  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = _buildTextTheme(AppColors.darkOnSurface);

    return base.copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.darkSurface,
        error: AppColors.error,
        onPrimary: AppColors.white,
        onSecondary: AppColors.white,
        onSurface: AppColors.darkOnSurface,
        onError: AppColors.white,
        outline: AppColors.darkOutline,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: AppColors.transparent,
        toolbarHeight: AppSizes.appBarHeight,
        backgroundColor: AppColors.darkBackground,
        foregroundColor: AppColors.darkOnSurface,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: const IconThemeData(color: AppColors.darkOnSurface, size: 22),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLG),
          side: const BorderSide(color: AppColors.darkOutline, width: 0.5),
        ),
        margin: EdgeInsets.zero,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        elevation: 0,
        height: 72,
        indicatorColor: AppColors.accentDim,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary, size: 24);
          }
          return IconThemeData(color: AppColors.darkOnSurfaceAlt, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final style = TextStyle(fontFamily: _fontFamily,fontSize: 12, height: 1.3);
          if (states.contains(WidgetState.selected)) {
            return style.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600);
          }
          return style.copyWith(color: AppColors.darkOnSurfaceAlt, fontWeight: FontWeight.w500);
        }),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.darkSurface,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        dragHandleColor: AppColors.darkOutlineHi,
        dragHandleSize: const Size(36, 4),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusXL),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMD),
          borderSide: BorderSide(color: AppColors.darkOutline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMD),
          borderSide: BorderSide(color: AppColors.darkOutline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMD),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusPill),
          ),
          textStyle: TextStyle(fontFamily: _fontFamily,fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 3,
        shape: const StadiumBorder(),
      ),
      listTileTheme: const ListTileThemeData(
        dense: true,
        visualDensity: VisualDensity.compact,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.darkOutline,
        thickness: 0.5,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.darkOnSurface,
        contentTextStyle: TextStyle(fontFamily: _fontFamily,color: AppColors.darkBackground, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMD)),
        behavior: SnackBarBehavior.floating,
      ),
      tooltipTheme: const TooltipThemeData(
        preferBelow: true,
        waitDuration: Duration(milliseconds: 500),
      ),
    );
  }

  // ─── Text Theme ──────────────────────────────────────
  static TextTheme _buildTextTheme(Color baseColor) {
    return TextTheme(
      displayLarge: TextStyle(fontFamily: _fontFamily,fontSize: 34, fontWeight: FontWeight.w800, color: baseColor, height: 1.2, letterSpacing: -0.3),
      displayMedium: TextStyle(fontFamily: _fontFamily,fontSize: 28, fontWeight: FontWeight.w700, color: baseColor, height: 1.2, letterSpacing: -0.2),
      displaySmall: TextStyle(fontFamily: _fontFamily,fontSize: 24, fontWeight: FontWeight.w700, color: baseColor, height: 1.25),
      headlineLarge: TextStyle(fontFamily: _fontFamily,fontSize: 22, fontWeight: FontWeight.w700, color: baseColor, height: 1.3),
      headlineMedium: TextStyle(fontFamily: _fontFamily,fontSize: 20, fontWeight: FontWeight.w600, color: baseColor, height: 1.3),
      headlineSmall: TextStyle(fontFamily: _fontFamily,fontSize: 17, fontWeight: FontWeight.w600, color: baseColor, height: 1.35),
      titleLarge: TextStyle(fontFamily: _fontFamily,fontSize: 18, fontWeight: FontWeight.w700, color: baseColor, height: 1.3),
      titleMedium: TextStyle(fontFamily: _fontFamily,fontSize: 15, fontWeight: FontWeight.w600, color: baseColor, height: 1.4),
      titleSmall: TextStyle(fontFamily: _fontFamily,fontSize: 13, fontWeight: FontWeight.w600, color: baseColor, height: 1.4),
      bodyLarge: TextStyle(fontFamily: _fontFamily,fontSize: 16, fontWeight: FontWeight.w400, color: baseColor, height: 1.5),
      bodyMedium: TextStyle(fontFamily: _fontFamily,fontSize: 14, fontWeight: FontWeight.w400, color: baseColor, height: 1.5),
      bodySmall: TextStyle(fontFamily: _fontFamily,fontSize: 12, fontWeight: FontWeight.w400, color: baseColor, height: 1.5),
      labelLarge: TextStyle(fontFamily: _fontFamily,fontSize: 15, fontWeight: FontWeight.w600, color: baseColor, height: 1.3),
      labelMedium: TextStyle(fontFamily: _fontFamily,fontSize: 13, fontWeight: FontWeight.w500, color: baseColor, height: 1.3),
      labelSmall: TextStyle(fontFamily: _fontFamily,fontSize: 11, fontWeight: FontWeight.w500, color: baseColor, height: 1.3),
    );
  }
}
