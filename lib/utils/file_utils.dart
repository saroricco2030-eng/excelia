import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:excelia/l10n/app_localizations.dart';
import 'package:excelia/models/app_document.dart';
import 'package:excelia/utils/constants.dart';

class FileUtils {
  FileUtils._();

  /// 레거시(구형) MS Office 바이너리 포맷 — Dart 파서로 열 수 없어 외부 앱 위임 필요
  static const Set<String> _legacyBinaryExtensions = {
    '.xls',   // Excel 97-2003
    '.doc',   // Word 97-2003
    '.ppt',   // PowerPoint 97-2003
  };

  /// 파일 경로의 확장자가 레거시 바이너리 포맷인지 확인
  static bool isLegacyBinaryFormat(String path) {
    final lower = path.toLowerCase();
    final dot = lower.lastIndexOf('.');
    if (dot < 0) return false;
    return _legacyBinaryExtensions.contains(lower.substring(dot));
  }

  /// 파일 경로에서 확장자(점 포함, 대문자) 추출
  static String getExtensionUpper(String path) {
    final dot = path.lastIndexOf('.');
    if (dot < 0) return '';
    return path.substring(dot).toUpperCase();
  }

  /// 파일 경로에서 확장자(점 없이, 소문자) 추출.
  /// `getDocumentTypeFromExtension`과 짝을 이룸.
  static String getExtensionLower(String path) {
    final dot = path.lastIndexOf('.');
    if (dot < 0 || dot == path.length - 1) return '';
    return path.substring(dot + 1).toLowerCase();
  }

  /// 플랫폼 구분자 유무에 관계없이 경로의 파일명만 추출.
  /// Android cache 경로는 `/`를, Windows 경로는 `\`를 쓰므로 둘 다 처리.
  static String basename(String path) {
    final slash = path.lastIndexOf('/');
    final backslash = path.lastIndexOf('\\');
    final idx = slash > backslash ? slash : backslash;
    return idx < 0 ? path : path.substring(idx + 1);
  }

  /// 시스템 기본 앱으로 파일 열기.
  /// 반환값: 성공 시 null, 실패 시 오류 메시지.
  static Future<String?> openWithExternalApp(String path) async {
    try {
      final result = await OpenFilex.open(path);
      switch (result.type) {
        case ResultType.done:
          return null;
        case ResultType.noAppToOpen:
        case ResultType.fileNotFound:
        case ResultType.permissionDenied:
        case ResultType.error:
          return result.message;
      }
    } catch (e) {
      return e.toString();
    }
  }

  /// 문서 유형에 맞는 아이콘 반환.
  /// 타입별로 서로 다른 실루엣을 사용 — 색상만이 아니라 형태로도 구분 가능해야 함
  /// (컬러 블라인드 접근성 / Don Norman Signifier 원칙).
  static IconData getFileIcon(DocumentType type) {
    switch (type) {
      case DocumentType.spreadsheet:
        return LucideIcons.table;                // 격자 실루엣
      case DocumentType.document:
        return LucideIcons.fileText;             // 텍스트 라인 문서
      case DocumentType.presentation:
        return LucideIcons.presentation;         // 프레젠테이션 스크린
      case DocumentType.pdf:
        return LucideIcons.fileType2;            // PDF 전용 형태
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
