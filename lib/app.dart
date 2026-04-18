import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:excelia/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:excelia/theme/app_theme.dart';
import 'package:excelia/providers/app_provider.dart';
import 'package:excelia/providers/spreadsheet_provider.dart';
import 'package:excelia/providers/document_provider.dart';
import 'package:excelia/providers/presentation_provider.dart';
import 'package:excelia/screens/home/home_screen.dart';
import 'package:excelia/screens/spreadsheet/spreadsheet_screen.dart';
import 'package:excelia/screens/document/document_screen.dart';
import 'package:excelia/screens/presentation/presentation_screen.dart';
import 'package:excelia/screens/pdf/pdf_viewer_screen.dart';

class ExceliaApp extends StatelessWidget {
  const ExceliaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()..loadRecentFiles()),
        ChangeNotifierProvider(create: (_) => SpreadsheetProvider(), lazy: true),
        ChangeNotifierProvider(create: (_) => DocumentProvider(), lazy: true),
        ChangeNotifierProvider(create: (_) => PresentationProvider(), lazy: true),
      ],
      child: Consumer<AppProvider>(
        builder: (context, appProvider, _) {
          return MaterialApp(
            title: 'Excelia',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: appProvider.themeMode,
            // Clamp text scale to prevent layout overflow at extreme sizes
            // while still honoring user's system preference up to 130%.
            builder: (context, child) {
              final mq = MediaQuery.of(context);
              final scaler = mq.textScaler.clamp(
                minScaleFactor: 1.0,
                maxScaleFactor: 1.3,
              );
              return MediaQuery(
                data: mq.copyWith(textScaler: scaler),
                child: child ?? const SizedBox.shrink(),
              );
            },
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              FlutterQuillLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            initialRoute: '/',
            routes: {
              '/': (context) => const HomeScreen(),
              '/spreadsheet': (context) => const SpreadsheetScreen(),
              '/document': (context) => const DocumentScreen(),
              '/presentation': (context) => const PresentationScreen(),
              '/pdf': (context) => const PdfViewerScreen(),
            },
          );
        },
      ),
    );
  }
}
