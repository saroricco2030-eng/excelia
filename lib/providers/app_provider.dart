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
  bool _hasLaunchedBefore = false;
  bool _hasSavedFirstFile = false;

  /// Soft-deleted files within the Undo window. Key = filePath.
  final Map<String, _PendingDelete> _pendingDeletes = {};

  static const String _recentFilesKey = 'recent_files';
  static const String _themeModeKey = 'theme_mode';
  static const String _autoSaveKey = 'auto_save_enabled';
  static const String _firstLaunchKey = 'has_launched_before';
  static const String _firstSaveKey = 'has_saved_first_file';

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  /// Visible recent files — excludes soft-deleted.
  List<RecentFile> get recentFiles => List.unmodifiable(
        _recentFiles.where((f) => !_pendingDeletes.containsKey(f.path)),
      );
  AppDocument? get currentDocument => _currentDocument;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get autoSaveEnabled => _autoSaveEnabled;
  bool get hasLaunchedBefore => _hasLaunchedBefore;
  bool get hasSavedFirstFile => _hasSavedFirstFile;

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

  /// Soft-delete: hide from UI but retain for Undo within the window.
  /// Returns the removed file (null if not found) so the caller can surface
  /// a SnackBar with the file name.
  RecentFile? softRemoveRecentFile(String filePath,
      {Duration window = const Duration(seconds: 6)}) {
    final index = _recentFiles.indexWhere((f) => f.path == filePath);
    if (index < 0) return null;
    final file = _recentFiles[index];
    _pendingDeletes[filePath] = _PendingDelete(
      file: file,
      originalIndex: index,
      expiresAt: DateTime.now().add(window),
    );
    notifyListeners();
    // Commit once the window expires (if still pending).
    Future.delayed(window, () => _commitPendingDelete(filePath));
    return file;
  }

  /// Restore a soft-deleted file if the Undo window has not expired.
  bool undoRemoveRecentFile(String filePath) {
    final pending = _pendingDeletes.remove(filePath);
    if (pending == null) return false;
    notifyListeners();
    return true;
  }

  void _commitPendingDelete(String filePath) {
    final pending = _pendingDeletes[filePath];
    if (pending == null) return;
    _pendingDeletes.remove(filePath);
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

    // First-run / first-save flags
    _hasLaunchedBefore = prefs.getBool(_firstLaunchKey) ?? false;
    _hasSavedFirstFile = prefs.getBool(_firstSaveKey) ?? false;

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

  /// Mark first launch as completed (called after showing onboarding / sample).
  Future<void> markLaunched() async {
    if (_hasLaunchedBefore) return;
    _hasLaunchedBefore = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_firstLaunchKey, true);
  }

  /// Mark first save as completed (used to show celebration banner once).
  Future<void> markFirstSave() async {
    if (_hasSavedFirstFile) return;
    _hasSavedFirstFile = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_firstSaveKey, true);
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

class _PendingDelete {
  final RecentFile file;
  final int originalIndex;
  final DateTime expiresAt;

  _PendingDelete({
    required this.file,
    required this.originalIndex,
    required this.expiresAt,
  });
}
