import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:excelia/models/app_document.dart';
import 'package:excelia/models/recent_file.dart';
import 'package:excelia/utils/constants.dart';

class AppProvider extends ChangeNotifier {
  List<RecentFile> _recentFiles = [];
  AppDocument? _currentDocument;
  ThemeMode _themeMode = ThemeMode.system;
  bool _autoSaveEnabled = true;

  static const String _recentFilesKey = 'recent_files';
  static const String _themeModeKey = 'theme_mode';
  static const String _autoSaveKey = 'auto_save_enabled';

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  List<RecentFile> get recentFiles => List.unmodifiable(_recentFiles);
  AppDocument? get currentDocument => _currentDocument;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get autoSaveEnabled => _autoSaveEnabled;

  // ---------------------------------------------------------------------------
  // Current document
  // ---------------------------------------------------------------------------

  void setCurrentDocument(AppDocument? doc) {
    _currentDocument = doc;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Theme
  // ---------------------------------------------------------------------------

  void toggleThemeMode() {
    switch (_themeMode) {
      case ThemeMode.system:
        _themeMode = ThemeMode.dark;
      case ThemeMode.dark:
        _themeMode = ThemeMode.light;
      case ThemeMode.light:
        _themeMode = ThemeMode.system;
    }
    notifyListeners();
    _saveThemeMode();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
    _saveThemeMode();
  }

  // ---------------------------------------------------------------------------
  // Auto-save
  // ---------------------------------------------------------------------------

  void toggleAutoSave() {
    _autoSaveEnabled = !_autoSaveEnabled;
    notifyListeners();
    _saveAutoSave();
  }

  Future<void> _saveAutoSave() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoSaveKey, _autoSaveEnabled);
  }

  // ---------------------------------------------------------------------------
  // Recent files
  // ---------------------------------------------------------------------------

  void addRecentFile(RecentFile file) {
    _recentFiles.removeWhere((f) => f.path == file.path);
    _recentFiles.insert(0, file);
    if (_recentFiles.length > AppSizes.maxRecentFiles) {
      _recentFiles = _recentFiles.sublist(0, AppSizes.maxRecentFiles);
    }
    notifyListeners();
    _saveRecentFiles();
  }

  void removeRecentFile(String filePath) {
    _recentFiles.removeWhere((f) => f.path == filePath);
    notifyListeners();
    _saveRecentFiles();
  }

  void clearRecentFiles() {
    _recentFiles.clear();
    notifyListeners();
    _saveRecentFiles();
  }

  /// 특정 문서 유형의 최근 파일만 필터링
  List<RecentFile> recentFilesByType(DocumentType type) {
    return _recentFiles.where((f) => f.type == type).toList();
  }

  // ---------------------------------------------------------------------------
  // Persistence
  // ---------------------------------------------------------------------------

  Future<void> loadRecentFiles() async {
    final prefs = await SharedPreferences.getInstance();

    // 테마 모드 복원
    final themeModeIndex = prefs.getInt(_themeModeKey);
    if (themeModeIndex != null && themeModeIndex < ThemeMode.values.length) {
      _themeMode = ThemeMode.values[themeModeIndex];
    }

    // 자동 저장 설정 복원
    _autoSaveEnabled = prefs.getBool(_autoSaveKey) ?? true;

    // 최근 파일 복원
    final jsonString = prefs.getString(_recentFilesKey);
    if (jsonString != null) {
      try {
        final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;
        _recentFiles = jsonList
            .map((item) => RecentFile.fromJson(item as Map<String, dynamic>))
            .toList();
      } catch (e) {
        debugPrint('Failed to load recent files: $e');
        _recentFiles = [];
      }
    }

    notifyListeners();
  }

  Future<void> _saveRecentFiles() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(
      _recentFiles.map((f) => f.toJson()).toList(),
    );
    await prefs.setString(_recentFilesKey, jsonString);
  }

  Future<void> _saveThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, _themeMode.index);
  }
}
