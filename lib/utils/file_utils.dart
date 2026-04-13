import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excelia/l10n/app_localizations.dart';
import 'package:excelia/models/app_document.dart';
import 'package:excelia/utils/constants.dart';

class FileUtils {
  FileUtils._();

  /// 문서 유형에 맞는 아이콘 반환
  static IconData getFileIcon(DocumentType type) {
    switch (type) {
      case DocumentType.spreadsheet:
        return LucideIcons.table;
      case DocumentType.document:
        return LucideIcons.fileText;
      case DocumentType.presentation:
        return LucideIcons.presentation;
      case DocumentType.pdf:
        return LucideIcons.fileText;
    }
  }

  /// [getFileIcon]의 별칭 (하위 호환성)
  static IconData getDocumentTypeIcon(DocumentType type) => getFileIcon(type);

  /// 문서 유형에 맞는 브랜드 색상 반환
  static Color getFileColor(DocumentType type) {
    switch (type) {
      case DocumentType.spreadsheet:
        return AppColors.spreadsheetGreen;
      case DocumentType.document:
        return AppColors.documentBlue;
      case DocumentType.presentation:
        return AppColors.presentationOrange;
      case DocumentType.pdf:
        return AppColors.pdfRed;
    }
  }

  /// [getFileColor]의 별칭 (하위 호환성)
  static Color getDocumentTypeColor(DocumentType type) => getFileColor(type);

  /// 파일 크기를 사람이 읽기 쉬운 형식으로 변환
  static String formatFileSize(int bytes) {
    if (bytes < 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      final kb = bytes / 1024;
      return '${kb.toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      final mb = bytes / (1024 * 1024);
      return '${mb.toStringAsFixed(1)} MB';
    }
    final gb = bytes / (1024 * 1024 * 1024);
    return '${gb.toStringAsFixed(2)} GB';
  }

  /// 문서 유형에 맞는 기본 파일 확장자 반환
  static String getFileExtension(DocumentType type) {
    switch (type) {
      case DocumentType.spreadsheet:
        return '.xlsx';
      case DocumentType.document:
        return '.docx';
      case DocumentType.presentation:
        return '.pptx';
      case DocumentType.pdf:
        return '.pdf';
    }
  }

  /// 파일 확장자로 문서 유형 판별
  static DocumentType? getDocumentTypeFromExtension(String ext) {
    final normalized = ext.toLowerCase().trim();
    final extension = normalized.startsWith('.') ? normalized : '.$normalized';

    switch (extension) {
      case '.xlsx':
      case '.xls':
      case '.csv':
        return DocumentType.spreadsheet;
      case '.docx':
      case '.doc':
      case '.txt':
      case '.rtf':
        return DocumentType.document;
      case '.pptx':
      case '.ppt':
        return DocumentType.presentation;
      case '.pdf':
        return DocumentType.pdf;
      default:
        return null;
    }
  }

  /// 문서 유형의 로컬라이즈 이름 반환
  static String getDocumentTypeName(DocumentType type, BuildContext context) {
    final l = AppLocalizations.of(context)!;
    switch (type) {
      case DocumentType.spreadsheet:
        return l.typeSpreadsheet;
      case DocumentType.document:
        return l.typeDocument;
      case DocumentType.presentation:
        return l.typePresentation;
      case DocumentType.pdf:
        return l.typePdf;
    }
  }

  /// file_picker를 사용하여 해당 문서 유형의 파일 선택
  static Future<FilePickerResult?> pickFile(DocumentType type) async {
    final List<String> extensions;
    switch (type) {
      case DocumentType.spreadsheet:
        extensions = ['xlsx', 'xls', 'csv'];
      case DocumentType.document:
        extensions = ['docx', 'doc', 'txt', 'rtf'];
      case DocumentType.presentation:
        extensions = ['pptx', 'ppt'];
      case DocumentType.pdf:
        extensions = ['pdf'];
    }

    return FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: extensions,
    );
  }

  /// 모든 지원 파일 유형을 선택할 수 있는 파일 피커
  static Future<FilePickerResult?> pickAnyFile() async {
    return FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'xlsx', 'xls', 'csv',
        'docx', 'doc', 'txt', 'rtf',
        'pptx', 'ppt',
        'pdf',
      ],
    );
  }
}
