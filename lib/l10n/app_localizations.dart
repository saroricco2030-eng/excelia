import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko'),
  ];

  /// No description provided for @appName.
  ///
  /// In ko, this message translates to:
  /// **'Excelia'**
  String get appName;

  /// No description provided for @appSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'모바일 오피스'**
  String get appSubtitle;

  /// No description provided for @appVersion.
  ///
  /// In ko, this message translates to:
  /// **'버전 1.0.0'**
  String get appVersion;

  /// No description provided for @commonSave.
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get commonSave;

  /// No description provided for @commonCancel.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get commonCancel;

  /// No description provided for @commonDelete.
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get commonDelete;

  /// No description provided for @commonClear.
  ///
  /// In ko, this message translates to:
  /// **'지우기'**
  String get commonClear;

  /// No description provided for @commonClose.
  ///
  /// In ko, this message translates to:
  /// **'닫기'**
  String get commonClose;

  /// No description provided for @commonOpen.
  ///
  /// In ko, this message translates to:
  /// **'열기'**
  String get commonOpen;

  /// No description provided for @commonShare.
  ///
  /// In ko, this message translates to:
  /// **'공유'**
  String get commonShare;

  /// No description provided for @commonContinue.
  ///
  /// In ko, this message translates to:
  /// **'계속'**
  String get commonContinue;

  /// No description provided for @commonAdd.
  ///
  /// In ko, this message translates to:
  /// **'추가'**
  String get commonAdd;

  /// No description provided for @commonMove.
  ///
  /// In ko, this message translates to:
  /// **'이동'**
  String get commonMove;

  /// No description provided for @commonReset.
  ///
  /// In ko, this message translates to:
  /// **'리셋'**
  String get commonReset;

  /// No description provided for @commonSettings.
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get commonSettings;

  /// No description provided for @commonLoading.
  ///
  /// In ko, this message translates to:
  /// **'로딩 중...'**
  String get commonLoading;

  /// No description provided for @commonBack.
  ///
  /// In ko, this message translates to:
  /// **'뒤로가기'**
  String get commonBack;

  /// No description provided for @commonUndo.
  ///
  /// In ko, this message translates to:
  /// **'실행 취소'**
  String get commonUndo;

  /// No description provided for @commonRedo.
  ///
  /// In ko, this message translates to:
  /// **'다시 실행'**
  String get commonRedo;

  /// No description provided for @commonMore.
  ///
  /// In ko, this message translates to:
  /// **'더보기'**
  String get commonMore;

  /// No description provided for @commonSaving.
  ///
  /// In ko, this message translates to:
  /// **'저장 중...'**
  String get commonSaving;

  /// No description provided for @commonSaved.
  ///
  /// In ko, this message translates to:
  /// **'저장됨'**
  String get commonSaved;

  /// No description provided for @commonUnsavedChanges.
  ///
  /// In ko, this message translates to:
  /// **'저장되지 않은 변경사항'**
  String get commonUnsavedChanges;

  /// No description provided for @commonSaveAs.
  ///
  /// In ko, this message translates to:
  /// **'다른 이름으로 저장'**
  String get commonSaveAs;

  /// No description provided for @commonDoNotSave.
  ///
  /// In ko, this message translates to:
  /// **'저장 안 함'**
  String get commonDoNotSave;

  /// No description provided for @commonOn.
  ///
  /// In ko, this message translates to:
  /// **'켜짐'**
  String get commonOn;

  /// No description provided for @commonOff.
  ///
  /// In ko, this message translates to:
  /// **'꺼짐'**
  String get commonOff;

  /// No description provided for @homeTitle.
  ///
  /// In ko, this message translates to:
  /// **'홈'**
  String get homeTitle;

  /// No description provided for @homeFiles.
  ///
  /// In ko, this message translates to:
  /// **'파일'**
  String get homeFiles;

  /// No description provided for @homeFavorites.
  ///
  /// In ko, this message translates to:
  /// **'즐겨찾기'**
  String get homeFavorites;

  /// No description provided for @homeCreateNew.
  ///
  /// In ko, this message translates to:
  /// **'새로 만들기'**
  String get homeCreateNew;

  /// No description provided for @homeRecentFiles.
  ///
  /// In ko, this message translates to:
  /// **'최근 파일'**
  String get homeRecentFiles;

  /// No description provided for @homeClearAll.
  ///
  /// In ko, this message translates to:
  /// **'모두 지우기'**
  String get homeClearAll;

  /// No description provided for @homeNoRecentFiles.
  ///
  /// In ko, this message translates to:
  /// **'최근 파일이 없습니다'**
  String get homeNoRecentFiles;

  /// No description provided for @homeNoRecentFilesHint.
  ///
  /// In ko, this message translates to:
  /// **'새 문서를 만들거나 파일을 열어보세요'**
  String get homeNoRecentFilesHint;

  /// No description provided for @homeClearRecentTitle.
  ///
  /// In ko, this message translates to:
  /// **'최근 파일 지우기'**
  String get homeClearRecentTitle;

  /// No description provided for @homeClearRecentMessage.
  ///
  /// In ko, this message translates to:
  /// **'최근 파일 목록을 모두 지우시겠습니까?'**
  String get homeClearRecentMessage;

  /// No description provided for @homeNoFiles.
  ///
  /// In ko, this message translates to:
  /// **'파일이 없습니다'**
  String get homeNoFiles;

  /// No description provided for @homeOpenFileHint.
  ///
  /// In ko, this message translates to:
  /// **'파일을 열어보세요'**
  String get homeOpenFileHint;

  /// No description provided for @homeFavoritesEmpty.
  ///
  /// In ko, this message translates to:
  /// **'즐겨찾기가 비어있습니다'**
  String get homeFavoritesEmpty;

  /// No description provided for @homeFavoritesHint.
  ///
  /// In ko, this message translates to:
  /// **'자주 사용하는 파일을 즐겨찾기에 추가하세요'**
  String get homeFavoritesHint;

  /// No description provided for @homeSearchFiles.
  ///
  /// In ko, this message translates to:
  /// **'파일 검색...'**
  String get homeSearchFiles;

  /// No description provided for @homeSearchTitle.
  ///
  /// In ko, this message translates to:
  /// **'파일 검색'**
  String get homeSearchTitle;

  /// No description provided for @homeSearchHint.
  ///
  /// In ko, this message translates to:
  /// **'파일 이름으로 검색'**
  String get homeSearchHint;

  /// No description provided for @homeNoSearchResults.
  ///
  /// In ko, this message translates to:
  /// **'검색 결과가 없습니다'**
  String get homeNoSearchResults;

  /// No description provided for @homeGeneral.
  ///
  /// In ko, this message translates to:
  /// **'일반'**
  String get homeGeneral;

  /// No description provided for @homeDarkMode.
  ///
  /// In ko, this message translates to:
  /// **'다크 모드'**
  String get homeDarkMode;

  /// No description provided for @homeData.
  ///
  /// In ko, this message translates to:
  /// **'데이터'**
  String get homeData;

  /// No description provided for @homeRecentFileHistory.
  ///
  /// In ko, this message translates to:
  /// **'최근 파일 기록'**
  String get homeRecentFileHistory;

  /// No description provided for @homeInfo.
  ///
  /// In ko, this message translates to:
  /// **'정보'**
  String get homeInfo;

  /// No description provided for @homeSupportedFormats.
  ///
  /// In ko, this message translates to:
  /// **'지원 형식'**
  String get homeSupportedFormats;

  /// No description provided for @homeSupportedFormatsDetail.
  ///
  /// In ko, this message translates to:
  /// **'xlsx, xls, docx, pptx, pdf'**
  String get homeSupportedFormatsDetail;

  /// No description provided for @homeAll.
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get homeAll;

  /// No description provided for @fileOpen.
  ///
  /// In ko, this message translates to:
  /// **'파일 열기'**
  String get fileOpen;

  /// No description provided for @fileOpenError.
  ///
  /// In ko, this message translates to:
  /// **'파일 열기 실패: {error}'**
  String fileOpenError(String error);

  /// No description provided for @fileNotFound.
  ///
  /// In ko, this message translates to:
  /// **'파일을 찾을 수 없습니다'**
  String get fileNotFound;

  /// No description provided for @fileNotFoundName.
  ///
  /// In ko, this message translates to:
  /// **'파일을 찾을 수 없습니다: {name}'**
  String fileNotFoundName(String name);

  /// No description provided for @filePermissionRequired.
  ///
  /// In ko, this message translates to:
  /// **'파일에 접근하려면 저장소 권한이 필요합니다.'**
  String get filePermissionRequired;

  /// No description provided for @filePathError.
  ///
  /// In ko, this message translates to:
  /// **'파일 경로를 가져올 수 없습니다. 다시 시도해 주세요.'**
  String get filePathError;

  /// No description provided for @fileReadError.
  ///
  /// In ko, this message translates to:
  /// **'파일을 읽을 수 없습니다. 파일이 삭제되었거나 접근 권한이 없습니다.'**
  String get fileReadError;

  /// No description provided for @fileUnsupportedFormat.
  ///
  /// In ko, this message translates to:
  /// **'지원하지 않는 파일 형식입니다.'**
  String get fileUnsupportedFormat;

  /// No description provided for @fileShareError.
  ///
  /// In ko, this message translates to:
  /// **'공유 실패: {error}'**
  String fileShareError(String error);

  /// No description provided for @fileDeleteTitle.
  ///
  /// In ko, this message translates to:
  /// **'파일 삭제'**
  String get fileDeleteTitle;

  /// No description provided for @fileDeleteConfirm.
  ///
  /// In ko, this message translates to:
  /// **'\"{name}\"을(를) 최근 파일 목록에서 삭제하시겠습니까?'**
  String fileDeleteConfirm(String name);

  /// No description provided for @fileCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}개 파일'**
  String fileCount(int count);

  /// No description provided for @fileLabelCount.
  ///
  /// In ko, this message translates to:
  /// **'{label} ({count})'**
  String fileLabelCount(String label, int count);

  /// No description provided for @fileLabelFileCount.
  ///
  /// In ko, this message translates to:
  /// **'{label}: {count}개 파일'**
  String fileLabelFileCount(String label, int count);

  /// No description provided for @fileLoading.
  ///
  /// In ko, this message translates to:
  /// **'파일 불러오는 중...'**
  String get fileLoading;

  /// No description provided for @fileSaved.
  ///
  /// In ko, this message translates to:
  /// **'저장 완료'**
  String get fileSaved;

  /// No description provided for @fileLoadRecentError.
  ///
  /// In ko, this message translates to:
  /// **'최근 파일 목록 불러오기 실패'**
  String get fileLoadRecentError;

  /// No description provided for @typeSpreadsheet.
  ///
  /// In ko, this message translates to:
  /// **'스프레드시트'**
  String get typeSpreadsheet;

  /// No description provided for @typeDocument.
  ///
  /// In ko, this message translates to:
  /// **'문서'**
  String get typeDocument;

  /// No description provided for @typePresentation.
  ///
  /// In ko, this message translates to:
  /// **'프레젠테이션'**
  String get typePresentation;

  /// No description provided for @typePdf.
  ///
  /// In ko, this message translates to:
  /// **'PDF'**
  String get typePdf;

  /// No description provided for @newSpreadsheet.
  ///
  /// In ko, this message translates to:
  /// **'새 스프레드시트'**
  String get newSpreadsheet;

  /// No description provided for @newDocument.
  ///
  /// In ko, this message translates to:
  /// **'새 문서'**
  String get newDocument;

  /// No description provided for @newPresentation.
  ///
  /// In ko, this message translates to:
  /// **'새 프레젠테이션'**
  String get newPresentation;

  /// No description provided for @pdfOpen.
  ///
  /// In ko, this message translates to:
  /// **'PDF 열기'**
  String get pdfOpen;

  /// No description provided for @spreadsheetOpen.
  ///
  /// In ko, this message translates to:
  /// **'스프레드시트 열기'**
  String get spreadsheetOpen;

  /// No description provided for @homeOpenFile.
  ///
  /// In ko, this message translates to:
  /// **'파일 열기'**
  String get homeOpenFile;

  /// No description provided for @openInExternalApp.
  ///
  /// In ko, this message translates to:
  /// **'외부 앱으로 열기'**
  String get openInExternalApp;

  /// No description provided for @legacyFormatTitle.
  ///
  /// In ko, this message translates to:
  /// **'구형 파일 포맷'**
  String get legacyFormatTitle;

  /// No description provided for @legacyFormatBody.
  ///
  /// In ko, this message translates to:
  /// **'{ext} 파일은 Excelia에서 직접 열 수 없습니다. 설치된 오피스 앱(한컴, MS Office, WPS 등)으로 여시겠습니까?'**
  String legacyFormatBody(String ext);

  /// No description provided for @externalAppError.
  ///
  /// In ko, this message translates to:
  /// **'외부 앱을 찾지 못했습니다. 오피스 앱을 설치해 주세요.'**
  String get externalAppError;

  /// No description provided for @externalAppOpenFailed.
  ///
  /// In ko, this message translates to:
  /// **'외부 앱으로 열기에 실패했습니다: {error}'**
  String externalAppOpenFailed(String error);

  /// No description provided for @parseFailedOpenExternal.
  ///
  /// In ko, this message translates to:
  /// **'파일을 읽지 못했습니다. 외부 앱으로 열어보시겠습니까?'**
  String get parseFailedOpenExternal;

  /// No description provided for @subtitleExcelCompat.
  ///
  /// In ko, this message translates to:
  /// **'Excel 호환'**
  String get subtitleExcelCompat;

  /// No description provided for @subtitleWordCompat.
  ///
  /// In ko, this message translates to:
  /// **'Word 호환'**
  String get subtitleWordCompat;

  /// No description provided for @subtitlePptCompat.
  ///
  /// In ko, this message translates to:
  /// **'PPT 호환'**
  String get subtitlePptCompat;

  /// No description provided for @subtitlePdfViewer.
  ///
  /// In ko, this message translates to:
  /// **'PDF 뷰어'**
  String get subtitlePdfViewer;

  /// No description provided for @spreadsheetOpenError.
  ///
  /// In ko, this message translates to:
  /// **'스프레드시트 파일을 열 수 없습니다. 파일이 손상되었거나 지원하지 않는 형식입니다.'**
  String get spreadsheetOpenError;

  /// No description provided for @spreadsheetSaveChanges.
  ///
  /// In ko, this message translates to:
  /// **'변경사항을 저장하시겠습니까?'**
  String get spreadsheetSaveChanges;

  /// No description provided for @spreadsheetInsertRow.
  ///
  /// In ko, this message translates to:
  /// **'행 삽입'**
  String get spreadsheetInsertRow;

  /// No description provided for @spreadsheetDeleteRow.
  ///
  /// In ko, this message translates to:
  /// **'행 삭제'**
  String get spreadsheetDeleteRow;

  /// No description provided for @spreadsheetInsertCol.
  ///
  /// In ko, this message translates to:
  /// **'열 삽입'**
  String get spreadsheetInsertCol;

  /// No description provided for @spreadsheetDeleteCol.
  ///
  /// In ko, this message translates to:
  /// **'열 삭제'**
  String get spreadsheetDeleteCol;

  /// No description provided for @spreadsheetSortAsc.
  ///
  /// In ko, this message translates to:
  /// **'오름차순 정렬'**
  String get spreadsheetSortAsc;

  /// No description provided for @spreadsheetSortDesc.
  ///
  /// In ko, this message translates to:
  /// **'내림차순 정렬'**
  String get spreadsheetSortDesc;

  /// No description provided for @spreadsheetPrintPreview.
  ///
  /// In ko, this message translates to:
  /// **'인쇄 미리보기'**
  String get spreadsheetPrintPreview;

  /// No description provided for @spreadsheetPrint.
  ///
  /// In ko, this message translates to:
  /// **'인쇄'**
  String get spreadsheetPrint;

  /// No description provided for @spreadsheetNoData.
  ///
  /// In ko, this message translates to:
  /// **'데이터가 없습니다'**
  String get spreadsheetNoData;

  /// No description provided for @spreadsheetPrintPreviewTitle.
  ///
  /// In ko, this message translates to:
  /// **'인쇄 미리보기 - {name}'**
  String spreadsheetPrintPreviewTitle(String name);

  /// No description provided for @spreadsheetZoomPercent.
  ///
  /// In ko, this message translates to:
  /// **'{percent}%'**
  String spreadsheetZoomPercent(int percent);

  /// No description provided for @sheetNew.
  ///
  /// In ko, this message translates to:
  /// **'새 시트'**
  String get sheetNew;

  /// No description provided for @sheetName.
  ///
  /// In ko, this message translates to:
  /// **'시트 이름'**
  String get sheetName;

  /// No description provided for @sheetNameHint.
  ///
  /// In ko, this message translates to:
  /// **'시트 이름을 입력하세요'**
  String get sheetNameHint;

  /// No description provided for @sheetRename.
  ///
  /// In ko, this message translates to:
  /// **'이름 변경'**
  String get sheetRename;

  /// No description provided for @sheetDuplicate.
  ///
  /// In ko, this message translates to:
  /// **'복제'**
  String get sheetDuplicate;

  /// No description provided for @sheetDeleteTitle.
  ///
  /// In ko, this message translates to:
  /// **'시트 삭제'**
  String get sheetDeleteTitle;

  /// No description provided for @sheetDeleteConfirm.
  ///
  /// In ko, this message translates to:
  /// **'\'{name}\' 시트를 삭제하시겠습니까?'**
  String sheetDeleteConfirm(String name);

  /// No description provided for @documentOpenError.
  ///
  /// In ko, this message translates to:
  /// **'문서 파일 열기 실패: {error}'**
  String documentOpenError(String error);

  /// No description provided for @documentExportPdf.
  ///
  /// In ko, this message translates to:
  /// **'PDF로 내보내기'**
  String get documentExportPdf;

  /// No description provided for @documentPrintPreview.
  ///
  /// In ko, this message translates to:
  /// **'인쇄 미리보기'**
  String get documentPrintPreview;

  /// No description provided for @documentPrint.
  ///
  /// In ko, this message translates to:
  /// **'인쇄'**
  String get documentPrint;

  /// No description provided for @documentPlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'여기에 내용을 입력하세요...'**
  String get documentPlaceholder;

  /// No description provided for @documentWordCount.
  ///
  /// In ko, this message translates to:
  /// **'단어 {count}개'**
  String documentWordCount(int count);

  /// No description provided for @documentCharCount.
  ///
  /// In ko, this message translates to:
  /// **'문자 {count}자'**
  String documentCharCount(int count);

  /// No description provided for @documentPageEstimate.
  ///
  /// In ko, this message translates to:
  /// **'약 {count}페이지'**
  String documentPageEstimate(int count);

  /// No description provided for @documentSaveTitle.
  ///
  /// In ko, this message translates to:
  /// **'문서 저장'**
  String get documentSaveTitle;

  /// No description provided for @documentSaved.
  ///
  /// In ko, this message translates to:
  /// **'문서가 저장되었습니다'**
  String get documentSaved;

  /// No description provided for @documentSaveError.
  ///
  /// In ko, this message translates to:
  /// **'저장 실패: {error}'**
  String documentSaveError(String error);

  /// No description provided for @documentExportDone.
  ///
  /// In ko, this message translates to:
  /// **'PDF 내보내기 완료: {path}'**
  String documentExportDone(String path);

  /// No description provided for @documentExportError.
  ///
  /// In ko, this message translates to:
  /// **'PDF 내보내기 실패: {error}'**
  String documentExportError(String error);

  /// No description provided for @documentPrintPreviewTitle.
  ///
  /// In ko, this message translates to:
  /// **'인쇄 미리보기 - {name}'**
  String documentPrintPreviewTitle(String name);

  /// No description provided for @documentPreviewError.
  ///
  /// In ko, this message translates to:
  /// **'미리보기 실패: {error}'**
  String documentPreviewError(String error);

  /// No description provided for @documentPrintError.
  ///
  /// In ko, this message translates to:
  /// **'인쇄 실패: {error}'**
  String documentPrintError(String error);

  /// No description provided for @documentOpenFile.
  ///
  /// In ko, this message translates to:
  /// **'문서 열기'**
  String get documentOpenFile;

  /// No description provided for @documentNew.
  ///
  /// In ko, this message translates to:
  /// **'새 문서'**
  String get documentNew;

  /// No description provided for @documentNewConfirm.
  ///
  /// In ko, this message translates to:
  /// **'저장하지 않은 변경사항이 있습니다. 계속하시겠습니까?'**
  String get documentNewConfirm;

  /// No description provided for @documentInsertDivider.
  ///
  /// In ko, this message translates to:
  /// **'구분선 삽입'**
  String get documentInsertDivider;

  /// No description provided for @documentInsertImage.
  ///
  /// In ko, this message translates to:
  /// **'이미지 삽입'**
  String get documentInsertImage;

  /// No description provided for @documentSelectImage.
  ///
  /// In ko, this message translates to:
  /// **'이미지 선택'**
  String get documentSelectImage;

  /// No description provided for @documentClose.
  ///
  /// In ko, this message translates to:
  /// **'문서 닫기'**
  String get documentClose;

  /// No description provided for @documentUnsavedChanges.
  ///
  /// In ko, this message translates to:
  /// **'저장하지 않은 변경사항이 있습니다.'**
  String get documentUnsavedChanges;

  /// No description provided for @presentationOpenError.
  ///
  /// In ko, this message translates to:
  /// **'프레젠테이션 파일 열기 실패: {error}'**
  String presentationOpenError(String error);

  /// No description provided for @presentationSlideshow.
  ///
  /// In ko, this message translates to:
  /// **'슬라이드쇼'**
  String get presentationSlideshow;

  /// No description provided for @presentationSlideList.
  ///
  /// In ko, this message translates to:
  /// **'슬라이드 목록'**
  String get presentationSlideList;

  /// No description provided for @presentationProperties.
  ///
  /// In ko, this message translates to:
  /// **'속성 패널'**
  String get presentationProperties;

  /// No description provided for @presentationGridSnap.
  ///
  /// In ko, this message translates to:
  /// **'격자 맞춤'**
  String get presentationGridSnap;

  /// No description provided for @presentationSlidePanel.
  ///
  /// In ko, this message translates to:
  /// **'슬라이드 패널'**
  String get presentationSlidePanel;

  /// No description provided for @presentationPrintPreview.
  ///
  /// In ko, this message translates to:
  /// **'인쇄 미리보기'**
  String get presentationPrintPreview;

  /// No description provided for @presentationPrint.
  ///
  /// In ko, this message translates to:
  /// **'인쇄'**
  String get presentationPrint;

  /// No description provided for @presentationAddSlide.
  ///
  /// In ko, this message translates to:
  /// **'슬라이드 추가'**
  String get presentationAddSlide;

  /// No description provided for @presentationNoSlides.
  ///
  /// In ko, this message translates to:
  /// **'슬라이드가 없습니다'**
  String get presentationNoSlides;

  /// No description provided for @presentationElementProps.
  ///
  /// In ko, this message translates to:
  /// **'요소 속성'**
  String get presentationElementProps;

  /// No description provided for @presentationDeleteElement.
  ///
  /// In ko, this message translates to:
  /// **'요소 삭제'**
  String get presentationDeleteElement;

  /// No description provided for @presentationRectangle.
  ///
  /// In ko, this message translates to:
  /// **'사각형'**
  String get presentationRectangle;

  /// No description provided for @presentationCircle.
  ///
  /// In ko, this message translates to:
  /// **'원'**
  String get presentationCircle;

  /// No description provided for @presentationTriangle.
  ///
  /// In ko, this message translates to:
  /// **'삼각형'**
  String get presentationTriangle;

  /// No description provided for @presentationArrow.
  ///
  /// In ko, this message translates to:
  /// **'화살표'**
  String get presentationArrow;

  /// No description provided for @presentationBgColor.
  ///
  /// In ko, this message translates to:
  /// **'슬라이드 배경색'**
  String get presentationBgColor;

  /// No description provided for @presentationSaved.
  ///
  /// In ko, this message translates to:
  /// **'프레젠테이션이 저장되었습니다'**
  String get presentationSaved;

  /// No description provided for @presentationSaveError.
  ///
  /// In ko, this message translates to:
  /// **'저장 실패: {error}'**
  String presentationSaveError(String error);

  /// No description provided for @presentationPrintPreviewTitle.
  ///
  /// In ko, this message translates to:
  /// **'인쇄 미리보기 - {name}'**
  String presentationPrintPreviewTitle(String name);

  /// No description provided for @presentationDuplicate.
  ///
  /// In ko, this message translates to:
  /// **'슬라이드 복제'**
  String get presentationDuplicate;

  /// No description provided for @presentationDeleteSlide.
  ///
  /// In ko, this message translates to:
  /// **'슬라이드 삭제'**
  String get presentationDeleteSlide;

  /// No description provided for @presentationMoveUp.
  ///
  /// In ko, this message translates to:
  /// **'위로 이동'**
  String get presentationMoveUp;

  /// No description provided for @presentationMoveDown.
  ///
  /// In ko, this message translates to:
  /// **'아래로 이동'**
  String get presentationMoveDown;

  /// No description provided for @presentationImagePlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'[이미지]'**
  String get presentationImagePlaceholder;

  /// No description provided for @presentationSelectElement.
  ///
  /// In ko, this message translates to:
  /// **'요소를 선택하면\n속성을 편집할 수 있습니다'**
  String get presentationSelectElement;

  /// No description provided for @presentationPosition.
  ///
  /// In ko, this message translates to:
  /// **'위치'**
  String get presentationPosition;

  /// No description provided for @presentationSize.
  ///
  /// In ko, this message translates to:
  /// **'크기'**
  String get presentationSize;

  /// No description provided for @presentationFontSize.
  ///
  /// In ko, this message translates to:
  /// **'글꼴 크기'**
  String get presentationFontSize;

  /// No description provided for @presentationBold.
  ///
  /// In ko, this message translates to:
  /// **'굵게'**
  String get presentationBold;

  /// No description provided for @presentationAlignment.
  ///
  /// In ko, this message translates to:
  /// **'정렬'**
  String get presentationAlignment;

  /// No description provided for @presentationTextColor.
  ///
  /// In ko, this message translates to:
  /// **'글자 색상'**
  String get presentationTextColor;

  /// No description provided for @presentationBackgroundColor.
  ///
  /// In ko, this message translates to:
  /// **'배경 색상'**
  String get presentationBackgroundColor;

  /// No description provided for @presentationText.
  ///
  /// In ko, this message translates to:
  /// **'텍스트'**
  String get presentationText;

  /// No description provided for @presentationDefaultText.
  ///
  /// In ko, this message translates to:
  /// **'텍스트를 입력하세요'**
  String get presentationDefaultText;

  /// No description provided for @presentationInsertShape.
  ///
  /// In ko, this message translates to:
  /// **'도형 삽입'**
  String get presentationInsertShape;

  /// No description provided for @presentationShape.
  ///
  /// In ko, this message translates to:
  /// **'도형'**
  String get presentationShape;

  /// No description provided for @presentationImage.
  ///
  /// In ko, this message translates to:
  /// **'이미지'**
  String get presentationImage;

  /// No description provided for @presentationBgColorShort.
  ///
  /// In ko, this message translates to:
  /// **'배경색'**
  String get presentationBgColorShort;

  /// No description provided for @presentationSaveTitle.
  ///
  /// In ko, this message translates to:
  /// **'프레젠테이션 저장'**
  String get presentationSaveTitle;

  /// No description provided for @presentationOpenTitle.
  ///
  /// In ko, this message translates to:
  /// **'프레젠테이션 열기'**
  String get presentationOpenTitle;

  /// No description provided for @pdfViewer.
  ///
  /// In ko, this message translates to:
  /// **'PDF 뷰어'**
  String get pdfViewer;

  /// No description provided for @pdfFileNotFound.
  ///
  /// In ko, this message translates to:
  /// **'파일을 찾을 수 없습니다'**
  String get pdfFileNotFound;

  /// No description provided for @pdfOpenFile.
  ///
  /// In ko, this message translates to:
  /// **'PDF 파일 열기'**
  String get pdfOpenFile;

  /// No description provided for @pdfThumbnail.
  ///
  /// In ko, this message translates to:
  /// **'썸네일'**
  String get pdfThumbnail;

  /// No description provided for @pdfDayMode.
  ///
  /// In ko, this message translates to:
  /// **'주간 모드'**
  String get pdfDayMode;

  /// No description provided for @pdfNightMode.
  ///
  /// In ko, this message translates to:
  /// **'야간 모드'**
  String get pdfNightMode;

  /// No description provided for @pdfOpenPrompt.
  ///
  /// In ko, this message translates to:
  /// **'PDF 파일을 열어주세요'**
  String get pdfOpenPrompt;

  /// No description provided for @pdfOpenHint.
  ///
  /// In ko, this message translates to:
  /// **'파일을 선택하여 PDF 문서를 확인할 수 있습니다'**
  String get pdfOpenHint;

  /// No description provided for @pdfCannotOpen.
  ///
  /// In ko, this message translates to:
  /// **'PDF를 열 수 없습니다'**
  String get pdfCannotOpen;

  /// No description provided for @pdfOpenAnother.
  ///
  /// In ko, this message translates to:
  /// **'다른 파일 열기'**
  String get pdfOpenAnother;

  /// No description provided for @pdfPageList.
  ///
  /// In ko, this message translates to:
  /// **'페이지 목록'**
  String get pdfPageList;

  /// No description provided for @pdfPrevPage.
  ///
  /// In ko, this message translates to:
  /// **'이전 페이지'**
  String get pdfPrevPage;

  /// No description provided for @pdfNextPage.
  ///
  /// In ko, this message translates to:
  /// **'다음 페이지'**
  String get pdfNextPage;

  /// No description provided for @pdfFirstPage.
  ///
  /// In ko, this message translates to:
  /// **'첫 페이지'**
  String get pdfFirstPage;

  /// No description provided for @pdfLastPage.
  ///
  /// In ko, this message translates to:
  /// **'마지막 페이지'**
  String get pdfLastPage;

  /// No description provided for @pdfJumpToPage.
  ///
  /// In ko, this message translates to:
  /// **'페이지 이동'**
  String get pdfJumpToPage;

  /// No description provided for @pdfPageNumber.
  ///
  /// In ko, this message translates to:
  /// **'페이지 번호 (1 ~ {total})'**
  String pdfPageNumber(int total);

  /// No description provided for @pdfPrint.
  ///
  /// In ko, this message translates to:
  /// **'인쇄'**
  String get pdfPrint;

  /// No description provided for @toolbarClose.
  ///
  /// In ko, this message translates to:
  /// **'닫기'**
  String get toolbarClose;

  /// No description provided for @toolbarBold.
  ///
  /// In ko, this message translates to:
  /// **'굵게'**
  String get toolbarBold;

  /// No description provided for @toolbarItalic.
  ///
  /// In ko, this message translates to:
  /// **'기울임'**
  String get toolbarItalic;

  /// No description provided for @toolbarUnderline.
  ///
  /// In ko, this message translates to:
  /// **'밑줄'**
  String get toolbarUnderline;

  /// No description provided for @toolbarTextColor.
  ///
  /// In ko, this message translates to:
  /// **'글자 색'**
  String get toolbarTextColor;

  /// No description provided for @toolbarBgColor.
  ///
  /// In ko, this message translates to:
  /// **'배경 색'**
  String get toolbarBgColor;

  /// No description provided for @toolbarAlignLeft.
  ///
  /// In ko, this message translates to:
  /// **'왼쪽 정렬'**
  String get toolbarAlignLeft;

  /// No description provided for @toolbarAlignCenter.
  ///
  /// In ko, this message translates to:
  /// **'가운데 정렬'**
  String get toolbarAlignCenter;

  /// No description provided for @toolbarAlignRight.
  ///
  /// In ko, this message translates to:
  /// **'오른쪽 정렬'**
  String get toolbarAlignRight;

  /// No description provided for @toolbarWrapText.
  ///
  /// In ko, this message translates to:
  /// **'텍스트 줄바꿈'**
  String get toolbarWrapText;

  /// No description provided for @toolbarFormatTools.
  ///
  /// In ko, this message translates to:
  /// **'서식 도구'**
  String get toolbarFormatTools;

  /// No description provided for @numberFormatGeneral.
  ///
  /// In ko, this message translates to:
  /// **'일반'**
  String get numberFormatGeneral;

  /// No description provided for @numberFormatNumber.
  ///
  /// In ko, this message translates to:
  /// **'숫자'**
  String get numberFormatNumber;

  /// No description provided for @numberFormatCurrency.
  ///
  /// In ko, this message translates to:
  /// **'통화'**
  String get numberFormatCurrency;

  /// No description provided for @numberFormatPercent.
  ///
  /// In ko, this message translates to:
  /// **'퍼센트'**
  String get numberFormatPercent;

  /// No description provided for @numberFormatDate.
  ///
  /// In ko, this message translates to:
  /// **'날짜'**
  String get numberFormatDate;

  /// No description provided for @pageSetupTitle.
  ///
  /// In ko, this message translates to:
  /// **'페이지 설정'**
  String get pageSetupTitle;

  /// No description provided for @paperSize.
  ///
  /// In ko, this message translates to:
  /// **'용지 크기'**
  String get paperSize;

  /// No description provided for @paperSizeA4.
  ///
  /// In ko, this message translates to:
  /// **'A4'**
  String get paperSizeA4;

  /// No description provided for @paperSizeA5.
  ///
  /// In ko, this message translates to:
  /// **'A5'**
  String get paperSizeA5;

  /// No description provided for @paperSizeLetter.
  ///
  /// In ko, this message translates to:
  /// **'Letter'**
  String get paperSizeLetter;

  /// No description provided for @paperSizeLegal.
  ///
  /// In ko, this message translates to:
  /// **'Legal'**
  String get paperSizeLegal;

  /// No description provided for @orientationLabel.
  ///
  /// In ko, this message translates to:
  /// **'방향'**
  String get orientationLabel;

  /// No description provided for @orientationLandscape.
  ///
  /// In ko, this message translates to:
  /// **'가로'**
  String get orientationLandscape;

  /// No description provided for @orientationPortrait.
  ///
  /// In ko, this message translates to:
  /// **'세로'**
  String get orientationPortrait;

  /// No description provided for @marginsLabel.
  ///
  /// In ko, this message translates to:
  /// **'여백'**
  String get marginsLabel;

  /// No description provided for @marginNormal.
  ///
  /// In ko, this message translates to:
  /// **'보통'**
  String get marginNormal;

  /// No description provided for @marginNarrow.
  ///
  /// In ko, this message translates to:
  /// **'좁게'**
  String get marginNarrow;

  /// No description provided for @marginWide.
  ///
  /// In ko, this message translates to:
  /// **'넓게'**
  String get marginWide;

  /// No description provided for @scaleLabel.
  ///
  /// In ko, this message translates to:
  /// **'배율'**
  String get scaleLabel;

  /// No description provided for @scaleFitWidth.
  ///
  /// In ko, this message translates to:
  /// **'너비 맞춤'**
  String get scaleFitWidth;

  /// No description provided for @scaleFitPage.
  ///
  /// In ko, this message translates to:
  /// **'페이지 맞춤'**
  String get scaleFitPage;

  /// No description provided for @scaleActual.
  ///
  /// In ko, this message translates to:
  /// **'실제 크기'**
  String get scaleActual;

  /// No description provided for @showGridlines.
  ///
  /// In ko, this message translates to:
  /// **'격자선 표시'**
  String get showGridlines;

  /// No description provided for @showFileName.
  ///
  /// In ko, this message translates to:
  /// **'파일명 표시'**
  String get showFileName;

  /// No description provided for @showPageNumbers.
  ///
  /// In ko, this message translates to:
  /// **'페이지 번호 표시'**
  String get showPageNumbers;

  /// No description provided for @pageSetupApply.
  ///
  /// In ko, this message translates to:
  /// **'적용'**
  String get pageSetupApply;

  /// No description provided for @contextCut.
  ///
  /// In ko, this message translates to:
  /// **'잘라내기'**
  String get contextCut;

  /// No description provided for @contextCopy.
  ///
  /// In ko, this message translates to:
  /// **'복사'**
  String get contextCopy;

  /// No description provided for @contextPaste.
  ///
  /// In ko, this message translates to:
  /// **'붙여넣기'**
  String get contextPaste;

  /// No description provided for @contextInsertRow.
  ///
  /// In ko, this message translates to:
  /// **'행 삽입'**
  String get contextInsertRow;

  /// No description provided for @contextInsertCol.
  ///
  /// In ko, this message translates to:
  /// **'열 삽입'**
  String get contextInsertCol;

  /// No description provided for @contextDeleteRow.
  ///
  /// In ko, this message translates to:
  /// **'행 삭제'**
  String get contextDeleteRow;

  /// No description provided for @contextDeleteCol.
  ///
  /// In ko, this message translates to:
  /// **'열 삭제'**
  String get contextDeleteCol;

  /// No description provided for @contextClearContent.
  ///
  /// In ko, this message translates to:
  /// **'내용 지우기'**
  String get contextClearContent;

  /// No description provided for @mergeCells.
  ///
  /// In ko, this message translates to:
  /// **'셀 병합'**
  String get mergeCells;

  /// No description provided for @unmergeCells.
  ///
  /// In ko, this message translates to:
  /// **'셀 병합 해제'**
  String get unmergeCells;

  /// No description provided for @fontSize.
  ///
  /// In ko, this message translates to:
  /// **'글꼴 크기'**
  String get fontSize;

  /// No description provided for @findTitle.
  ///
  /// In ko, this message translates to:
  /// **'찾기'**
  String get findTitle;

  /// No description provided for @findHint.
  ///
  /// In ko, this message translates to:
  /// **'검색어 입력...'**
  String get findHint;

  /// No description provided for @replaceHint.
  ///
  /// In ko, this message translates to:
  /// **'바꿀 내용 입력...'**
  String get replaceHint;

  /// No description provided for @replaceOne.
  ///
  /// In ko, this message translates to:
  /// **'바꾸기'**
  String get replaceOne;

  /// No description provided for @replaceAllBtn.
  ///
  /// In ko, this message translates to:
  /// **'전체 바꾸기'**
  String get replaceAllBtn;

  /// No description provided for @findMatchCount.
  ///
  /// In ko, this message translates to:
  /// **'{current}/{total}'**
  String findMatchCount(int current, int total);

  /// No description provided for @findNoMatch.
  ///
  /// In ko, this message translates to:
  /// **'결과 없음'**
  String get findNoMatch;

  /// No description provided for @freezePanes.
  ///
  /// In ko, this message translates to:
  /// **'틀 고정'**
  String get freezePanes;

  /// No description provided for @unfreezePanes.
  ///
  /// In ko, this message translates to:
  /// **'틀 고정 해제'**
  String get unfreezePanes;

  /// No description provided for @borderAll.
  ///
  /// In ko, this message translates to:
  /// **'모든 테두리'**
  String get borderAll;

  /// No description provided for @borderOutside.
  ///
  /// In ko, this message translates to:
  /// **'바깥쪽 테두리'**
  String get borderOutside;

  /// No description provided for @borderBottom.
  ///
  /// In ko, this message translates to:
  /// **'아래쪽 테두리'**
  String get borderBottom;

  /// No description provided for @borderNone.
  ///
  /// In ko, this message translates to:
  /// **'테두리 없음'**
  String get borderNone;

  /// No description provided for @formatPainter.
  ///
  /// In ko, this message translates to:
  /// **'서식 복사'**
  String get formatPainter;

  /// No description provided for @hideRow.
  ///
  /// In ko, this message translates to:
  /// **'행 숨기기'**
  String get hideRow;

  /// No description provided for @hideCol.
  ///
  /// In ko, this message translates to:
  /// **'열 숨기기'**
  String get hideCol;

  /// No description provided for @unhideAll.
  ///
  /// In ko, this message translates to:
  /// **'숨기기 해제'**
  String get unhideAll;

  /// No description provided for @addComment.
  ///
  /// In ko, this message translates to:
  /// **'메모 추가'**
  String get addComment;

  /// No description provided for @editComment.
  ///
  /// In ko, this message translates to:
  /// **'메모 편집'**
  String get editComment;

  /// No description provided for @deleteComment.
  ///
  /// In ko, this message translates to:
  /// **'메모 삭제'**
  String get deleteComment;

  /// No description provided for @commentHint.
  ///
  /// In ko, this message translates to:
  /// **'메모를 입력하세요...'**
  String get commentHint;

  /// No description provided for @autoFilter.
  ///
  /// In ko, this message translates to:
  /// **'자동 필터'**
  String get autoFilter;

  /// No description provided for @clearAutoFilter.
  ///
  /// In ko, this message translates to:
  /// **'필터 해제'**
  String get clearAutoFilter;

  /// No description provided for @filterValues.
  ///
  /// In ko, this message translates to:
  /// **'필터 값'**
  String get filterValues;

  /// No description provided for @filterSelectAll.
  ///
  /// In ko, this message translates to:
  /// **'전체 선택'**
  String get filterSelectAll;

  /// No description provided for @filterClearAll.
  ///
  /// In ko, this message translates to:
  /// **'전체 해제'**
  String get filterClearAll;

  /// No description provided for @conditionalFormat.
  ///
  /// In ko, this message translates to:
  /// **'조건부 서식'**
  String get conditionalFormat;

  /// No description provided for @conditionType.
  ///
  /// In ko, this message translates to:
  /// **'조건 유형'**
  String get conditionType;

  /// No description provided for @condGreaterThan.
  ///
  /// In ko, this message translates to:
  /// **'보다 큼'**
  String get condGreaterThan;

  /// No description provided for @condLessThan.
  ///
  /// In ko, this message translates to:
  /// **'보다 작음'**
  String get condLessThan;

  /// No description provided for @condEqualTo.
  ///
  /// In ko, this message translates to:
  /// **'같음'**
  String get condEqualTo;

  /// No description provided for @condBetween.
  ///
  /// In ko, this message translates to:
  /// **'사이'**
  String get condBetween;

  /// No description provided for @condTextContains.
  ///
  /// In ko, this message translates to:
  /// **'텍스트 포함'**
  String get condTextContains;

  /// No description provided for @condIsEmpty.
  ///
  /// In ko, this message translates to:
  /// **'비어 있음'**
  String get condIsEmpty;

  /// No description provided for @condIsNotEmpty.
  ///
  /// In ko, this message translates to:
  /// **'비어 있지 않음'**
  String get condIsNotEmpty;

  /// No description provided for @condValue.
  ///
  /// In ko, this message translates to:
  /// **'값'**
  String get condValue;

  /// No description provided for @condValue2.
  ///
  /// In ko, this message translates to:
  /// **'값 2'**
  String get condValue2;

  /// No description provided for @condFormatStyle.
  ///
  /// In ko, this message translates to:
  /// **'서식 스타일'**
  String get condFormatStyle;

  /// No description provided for @condApply.
  ///
  /// In ko, this message translates to:
  /// **'적용'**
  String get condApply;

  /// No description provided for @condClearAll.
  ///
  /// In ko, this message translates to:
  /// **'규칙 모두 지우기'**
  String get condClearAll;

  /// No description provided for @insertChart.
  ///
  /// In ko, this message translates to:
  /// **'차트 삽입'**
  String get insertChart;

  /// No description provided for @chartType.
  ///
  /// In ko, this message translates to:
  /// **'차트 종류'**
  String get chartType;

  /// No description provided for @chartBar.
  ///
  /// In ko, this message translates to:
  /// **'막대 차트'**
  String get chartBar;

  /// No description provided for @chartLine.
  ///
  /// In ko, this message translates to:
  /// **'꺾은선 차트'**
  String get chartLine;

  /// No description provided for @chartPie.
  ///
  /// In ko, this message translates to:
  /// **'원형 차트'**
  String get chartPie;

  /// No description provided for @chartTitle.
  ///
  /// In ko, this message translates to:
  /// **'차트 제목'**
  String get chartTitle;

  /// No description provided for @chartDefaultTitle.
  ///
  /// In ko, this message translates to:
  /// **'차트'**
  String get chartDefaultTitle;

  /// No description provided for @chartCreate.
  ///
  /// In ko, this message translates to:
  /// **'만들기'**
  String get chartCreate;

  /// No description provided for @chartDataHint.
  ///
  /// In ko, this message translates to:
  /// **'차트를 삽입하기 전에 데이터가 있는 셀을 선택하세요. 첫 번째 열 = 라벨, 두 번째 열 = 값'**
  String get chartDataHint;

  /// No description provided for @chartScatter.
  ///
  /// In ko, this message translates to:
  /// **'산점도'**
  String get chartScatter;

  /// No description provided for @chartArea.
  ///
  /// In ko, this message translates to:
  /// **'영역 차트'**
  String get chartArea;

  /// No description provided for @chartStackedBar.
  ///
  /// In ko, this message translates to:
  /// **'누적 막대'**
  String get chartStackedBar;

  /// No description provided for @chartDoughnut.
  ///
  /// In ko, this message translates to:
  /// **'도넛 차트'**
  String get chartDoughnut;

  /// No description provided for @chartRadar.
  ///
  /// In ko, this message translates to:
  /// **'방사형 차트'**
  String get chartRadar;

  /// No description provided for @chartCombo.
  ///
  /// In ko, this message translates to:
  /// **'복합 차트'**
  String get chartCombo;

  /// No description provided for @chartAxisX.
  ///
  /// In ko, this message translates to:
  /// **'X축 제목'**
  String get chartAxisX;

  /// No description provided for @chartAxisY.
  ///
  /// In ko, this message translates to:
  /// **'Y축 제목'**
  String get chartAxisY;

  /// No description provided for @chartGridlines.
  ///
  /// In ko, this message translates to:
  /// **'격자선'**
  String get chartGridlines;

  /// No description provided for @chartLegend.
  ///
  /// In ko, this message translates to:
  /// **'범례 위치'**
  String get chartLegend;

  /// No description provided for @chartLegendNone.
  ///
  /// In ko, this message translates to:
  /// **'없음'**
  String get chartLegendNone;

  /// No description provided for @chartLegendTop.
  ///
  /// In ko, this message translates to:
  /// **'위'**
  String get chartLegendTop;

  /// No description provided for @chartLegendBottom.
  ///
  /// In ko, this message translates to:
  /// **'아래'**
  String get chartLegendBottom;

  /// No description provided for @chartLegendLeft.
  ///
  /// In ko, this message translates to:
  /// **'왼쪽'**
  String get chartLegendLeft;

  /// No description provided for @chartLegendRight.
  ///
  /// In ko, this message translates to:
  /// **'오른쪽'**
  String get chartLegendRight;

  /// No description provided for @chartCustomize.
  ///
  /// In ko, this message translates to:
  /// **'차트 커스터마이즈'**
  String get chartCustomize;

  /// No description provided for @dataValidation.
  ///
  /// In ko, this message translates to:
  /// **'데이터 유효성 검사'**
  String get dataValidation;

  /// No description provided for @dataValidationType.
  ///
  /// In ko, this message translates to:
  /// **'검증 유형'**
  String get dataValidationType;

  /// No description provided for @dataValidationTypeList.
  ///
  /// In ko, this message translates to:
  /// **'목록'**
  String get dataValidationTypeList;

  /// No description provided for @dataValidationTypeWholeNumber.
  ///
  /// In ko, this message translates to:
  /// **'정수'**
  String get dataValidationTypeWholeNumber;

  /// No description provided for @dataValidationTypeDecimal.
  ///
  /// In ko, this message translates to:
  /// **'소수'**
  String get dataValidationTypeDecimal;

  /// No description provided for @dataValidationTypeDate.
  ///
  /// In ko, this message translates to:
  /// **'날짜'**
  String get dataValidationTypeDate;

  /// No description provided for @dataValidationTypeTextLength.
  ///
  /// In ko, this message translates to:
  /// **'텍스트 길이'**
  String get dataValidationTypeTextLength;

  /// No description provided for @dataValidationTypeCustom.
  ///
  /// In ko, this message translates to:
  /// **'사용자 지정'**
  String get dataValidationTypeCustom;

  /// No description provided for @dataValidationOperator.
  ///
  /// In ko, this message translates to:
  /// **'연산자'**
  String get dataValidationOperator;

  /// No description provided for @dataValidationOpBetween.
  ///
  /// In ko, this message translates to:
  /// **'사이'**
  String get dataValidationOpBetween;

  /// No description provided for @dataValidationOpNotBetween.
  ///
  /// In ko, this message translates to:
  /// **'사이가 아닌'**
  String get dataValidationOpNotBetween;

  /// No description provided for @dataValidationOpEqualTo.
  ///
  /// In ko, this message translates to:
  /// **'같음'**
  String get dataValidationOpEqualTo;

  /// No description provided for @dataValidationOpNotEqualTo.
  ///
  /// In ko, this message translates to:
  /// **'같지 않음'**
  String get dataValidationOpNotEqualTo;

  /// No description provided for @dataValidationOpGreaterThan.
  ///
  /// In ko, this message translates to:
  /// **'보다 큼'**
  String get dataValidationOpGreaterThan;

  /// No description provided for @dataValidationOpLessThan.
  ///
  /// In ko, this message translates to:
  /// **'보다 작음'**
  String get dataValidationOpLessThan;

  /// No description provided for @dataValidationOpGreaterOrEqual.
  ///
  /// In ko, this message translates to:
  /// **'크거나 같음'**
  String get dataValidationOpGreaterOrEqual;

  /// No description provided for @dataValidationOpLessOrEqual.
  ///
  /// In ko, this message translates to:
  /// **'작거나 같음'**
  String get dataValidationOpLessOrEqual;

  /// No description provided for @dataValidationListItems.
  ///
  /// In ko, this message translates to:
  /// **'목록 항목'**
  String get dataValidationListItems;

  /// No description provided for @dataValidationListHint.
  ///
  /// In ko, this message translates to:
  /// **'쉼표로 구분하여 항목 입력'**
  String get dataValidationListHint;

  /// No description provided for @dataValidationValue1.
  ///
  /// In ko, this message translates to:
  /// **'값 1'**
  String get dataValidationValue1;

  /// No description provided for @dataValidationValue2.
  ///
  /// In ko, this message translates to:
  /// **'값 2'**
  String get dataValidationValue2;

  /// No description provided for @dataValidationShowError.
  ///
  /// In ko, this message translates to:
  /// **'유효하지 않은 입력 시 오류 표시'**
  String get dataValidationShowError;

  /// No description provided for @dataValidationFailed.
  ///
  /// In ko, this message translates to:
  /// **'입력값이 유효성 검사 규칙에 맞지 않습니다'**
  String get dataValidationFailed;

  /// No description provided for @nameManager.
  ///
  /// In ko, this message translates to:
  /// **'이름 관리자'**
  String get nameManager;

  /// No description provided for @namedRangeName.
  ///
  /// In ko, this message translates to:
  /// **'이름'**
  String get namedRangeName;

  /// No description provided for @namedRangeRef.
  ///
  /// In ko, this message translates to:
  /// **'범위 (예: A1:B5)'**
  String get namedRangeRef;

  /// No description provided for @namedRangeEmpty.
  ///
  /// In ko, this message translates to:
  /// **'정의된 명명 범위 없음'**
  String get namedRangeEmpty;

  /// No description provided for @spreadsheetExportCsv.
  ///
  /// In ko, this message translates to:
  /// **'CSV로 내보내기'**
  String get spreadsheetExportCsv;

  /// No description provided for @documentOpenDocx.
  ///
  /// In ko, this message translates to:
  /// **'DOCX 열기'**
  String get documentOpenDocx;

  /// No description provided for @documentSaveDocx.
  ///
  /// In ko, this message translates to:
  /// **'DOCX로 저장'**
  String get documentSaveDocx;

  /// No description provided for @documentExportDocx.
  ///
  /// In ko, this message translates to:
  /// **'DOCX로 내보내기'**
  String get documentExportDocx;

  /// No description provided for @pptxOpen.
  ///
  /// In ko, this message translates to:
  /// **'PPTX 열기'**
  String get pptxOpen;

  /// No description provided for @pptxSave.
  ///
  /// In ko, this message translates to:
  /// **'PPTX로 저장'**
  String get pptxSave;

  /// No description provided for @pptxExport.
  ///
  /// In ko, this message translates to:
  /// **'PPTX로 내보내기'**
  String get pptxExport;

  /// No description provided for @slideTransition.
  ///
  /// In ko, this message translates to:
  /// **'슬라이드 전환'**
  String get slideTransition;

  /// No description provided for @transitionNone.
  ///
  /// In ko, this message translates to:
  /// **'없음'**
  String get transitionNone;

  /// No description provided for @transitionFade.
  ///
  /// In ko, this message translates to:
  /// **'페이드'**
  String get transitionFade;

  /// No description provided for @transitionPush.
  ///
  /// In ko, this message translates to:
  /// **'밀기'**
  String get transitionPush;

  /// No description provided for @transitionWipe.
  ///
  /// In ko, this message translates to:
  /// **'닦기'**
  String get transitionWipe;

  /// No description provided for @transitionZoom.
  ///
  /// In ko, this message translates to:
  /// **'확대/축소'**
  String get transitionZoom;

  /// No description provided for @transitionDuration.
  ///
  /// In ko, this message translates to:
  /// **'지속 시간 (ms)'**
  String get transitionDuration;

  /// No description provided for @speakerNotes.
  ///
  /// In ko, this message translates to:
  /// **'발표자 노트'**
  String get speakerNotes;

  /// No description provided for @speakerNotesHint.
  ///
  /// In ko, this message translates to:
  /// **'발표자 노트 입력...'**
  String get speakerNotesHint;

  /// No description provided for @slideTemplate.
  ///
  /// In ko, this message translates to:
  /// **'슬라이드 템플릿'**
  String get slideTemplate;

  /// No description provided for @templateTitle.
  ///
  /// In ko, this message translates to:
  /// **'제목 슬라이드'**
  String get templateTitle;

  /// No description provided for @templateTitleBody.
  ///
  /// In ko, this message translates to:
  /// **'제목 + 본문'**
  String get templateTitleBody;

  /// No description provided for @templateTwoColumn.
  ///
  /// In ko, this message translates to:
  /// **'2단 비교'**
  String get templateTwoColumn;

  /// No description provided for @templateBlank.
  ///
  /// In ko, this message translates to:
  /// **'빈 슬라이드'**
  String get templateBlank;

  /// No description provided for @templateSection.
  ///
  /// In ko, this message translates to:
  /// **'섹션 구분'**
  String get templateSection;

  /// No description provided for @templateImageText.
  ///
  /// In ko, this message translates to:
  /// **'이미지 + 텍스트'**
  String get templateImageText;

  /// No description provided for @elementAnimation.
  ///
  /// In ko, this message translates to:
  /// **'요소 애니메이션'**
  String get elementAnimation;

  /// No description provided for @animationFadeIn.
  ///
  /// In ko, this message translates to:
  /// **'페이드 인'**
  String get animationFadeIn;

  /// No description provided for @animationFlyInLeft.
  ///
  /// In ko, this message translates to:
  /// **'왼쪽에서 날아오기'**
  String get animationFlyInLeft;

  /// No description provided for @animationFlyInRight.
  ///
  /// In ko, this message translates to:
  /// **'오른쪽에서 날아오기'**
  String get animationFlyInRight;

  /// No description provided for @animationFlyInBottom.
  ///
  /// In ko, this message translates to:
  /// **'아래에서 날아오기'**
  String get animationFlyInBottom;

  /// No description provided for @animationZoomIn.
  ///
  /// In ko, this message translates to:
  /// **'확대'**
  String get animationZoomIn;

  /// No description provided for @animationTriggerClick.
  ///
  /// In ko, this message translates to:
  /// **'클릭 시'**
  String get animationTriggerClick;

  /// No description provided for @animationTriggerWith.
  ///
  /// In ko, this message translates to:
  /// **'이전 효과와 함께'**
  String get animationTriggerWith;

  /// No description provided for @animationTriggerAfter.
  ///
  /// In ko, this message translates to:
  /// **'이전 효과 다음에'**
  String get animationTriggerAfter;

  /// No description provided for @hyperlinkInsert.
  ///
  /// In ko, this message translates to:
  /// **'하이퍼링크 삽입'**
  String get hyperlinkInsert;

  /// No description provided for @hyperlinkUrl.
  ///
  /// In ko, this message translates to:
  /// **'URL'**
  String get hyperlinkUrl;

  /// No description provided for @hyperlinkRemove.
  ///
  /// In ko, this message translates to:
  /// **'하이퍼링크 제거'**
  String get hyperlinkRemove;

  /// No description provided for @documentDocxLoaded.
  ///
  /// In ko, this message translates to:
  /// **'DOCX 파일을 불러왔습니다'**
  String get documentDocxLoaded;

  /// No description provided for @documentDocxSaved.
  ///
  /// In ko, this message translates to:
  /// **'DOCX로 저장됨: {path}'**
  String documentDocxSaved(String path);

  /// No description provided for @documentDocxError.
  ///
  /// In ko, this message translates to:
  /// **'DOCX 오류: {error}'**
  String documentDocxError(String error);

  /// No description provided for @presentationPptxLoaded.
  ///
  /// In ko, this message translates to:
  /// **'PPTX 파일을 불러왔습니다'**
  String get presentationPptxLoaded;

  /// No description provided for @presentationPptxSaved.
  ///
  /// In ko, this message translates to:
  /// **'PPTX로 저장됨: {path}'**
  String presentationPptxSaved(String path);

  /// No description provided for @presentationPptxError.
  ///
  /// In ko, this message translates to:
  /// **'PPTX 오류: {error}'**
  String presentationPptxError(String error);

  /// No description provided for @pdfSearch.
  ///
  /// In ko, this message translates to:
  /// **'검색'**
  String get pdfSearch;

  /// No description provided for @pdfSearchHint.
  ///
  /// In ko, this message translates to:
  /// **'문서에서 검색...'**
  String get pdfSearchHint;

  /// No description provided for @pdfBookmark.
  ///
  /// In ko, this message translates to:
  /// **'북마크'**
  String get pdfBookmark;

  /// No description provided for @pdfNoBookmarks.
  ///
  /// In ko, this message translates to:
  /// **'북마크 없음'**
  String get pdfNoBookmarks;

  /// No description provided for @pdfAnnotation.
  ///
  /// In ko, this message translates to:
  /// **'주석'**
  String get pdfAnnotation;

  /// No description provided for @pdfAnnotationHighlight.
  ///
  /// In ko, this message translates to:
  /// **'하이라이트'**
  String get pdfAnnotationHighlight;

  /// No description provided for @pdfAnnotationUnderline.
  ///
  /// In ko, this message translates to:
  /// **'밑줄'**
  String get pdfAnnotationUnderline;

  /// No description provided for @pdfAnnotationStrikethrough.
  ///
  /// In ko, this message translates to:
  /// **'취소선'**
  String get pdfAnnotationStrikethrough;

  /// No description provided for @pdfAnnotationOff.
  ///
  /// In ko, this message translates to:
  /// **'끄기'**
  String get pdfAnnotationOff;

  /// No description provided for @pdfAnnotationColor.
  ///
  /// In ko, this message translates to:
  /// **'색상'**
  String get pdfAnnotationColor;

  /// No description provided for @pdfAnnotationMode.
  ///
  /// In ko, this message translates to:
  /// **'주석 모드'**
  String get pdfAnnotationMode;

  /// No description provided for @pdfAnnotationActive.
  ///
  /// In ko, this message translates to:
  /// **'활성: {mode}'**
  String pdfAnnotationActive(String mode);

  /// No description provided for @documentInsertTable.
  ///
  /// In ko, this message translates to:
  /// **'표 삽입'**
  String get documentInsertTable;

  /// No description provided for @documentTableRows.
  ///
  /// In ko, this message translates to:
  /// **'행'**
  String get documentTableRows;

  /// No description provided for @documentTableCols.
  ///
  /// In ko, this message translates to:
  /// **'열'**
  String get documentTableCols;

  /// No description provided for @documentTableInsertTitle.
  ///
  /// In ko, this message translates to:
  /// **'표 삽입'**
  String get documentTableInsertTitle;

  /// No description provided for @documentTableEditCell.
  ///
  /// In ko, this message translates to:
  /// **'셀 편집'**
  String get documentTableEditCell;

  /// No description provided for @documentTableAddRow.
  ///
  /// In ko, this message translates to:
  /// **'행 추가'**
  String get documentTableAddRow;

  /// No description provided for @documentTableAddCol.
  ///
  /// In ko, this message translates to:
  /// **'열 추가'**
  String get documentTableAddCol;

  /// No description provided for @documentTableDeleteRow.
  ///
  /// In ko, this message translates to:
  /// **'행 삭제'**
  String get documentTableDeleteRow;

  /// No description provided for @documentTableEditHeader.
  ///
  /// In ko, this message translates to:
  /// **'헤더 편집'**
  String get documentTableEditHeader;

  /// No description provided for @commonConfirm.
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get commonConfirm;

  /// No description provided for @documentImageLoaded.
  ///
  /// In ko, this message translates to:
  /// **'DOCX에서 이미지 로드됨'**
  String get documentImageLoaded;

  /// No description provided for @documentImageError.
  ///
  /// In ko, this message translates to:
  /// **'이미지 로드 실패: {error}'**
  String documentImageError(String error);

  /// No description provided for @pivotTable.
  ///
  /// In ko, this message translates to:
  /// **'피벗 테이블'**
  String get pivotTable;

  /// No description provided for @pivotTableCreate.
  ///
  /// In ko, this message translates to:
  /// **'피벗 테이블 만들기'**
  String get pivotTableCreate;

  /// No description provided for @pivotDataRange.
  ///
  /// In ko, this message translates to:
  /// **'데이터 범위'**
  String get pivotDataRange;

  /// No description provided for @pivotRowField.
  ///
  /// In ko, this message translates to:
  /// **'행 필드'**
  String get pivotRowField;

  /// No description provided for @pivotColField.
  ///
  /// In ko, this message translates to:
  /// **'열 필드 (선택)'**
  String get pivotColField;

  /// No description provided for @pivotValueField.
  ///
  /// In ko, this message translates to:
  /// **'값 필드'**
  String get pivotValueField;

  /// No description provided for @pivotAggregateFunc.
  ///
  /// In ko, this message translates to:
  /// **'집계 함수'**
  String get pivotAggregateFunc;

  /// No description provided for @pivotFuncSum.
  ///
  /// In ko, this message translates to:
  /// **'합계'**
  String get pivotFuncSum;

  /// No description provided for @pivotFuncCount.
  ///
  /// In ko, this message translates to:
  /// **'개수'**
  String get pivotFuncCount;

  /// No description provided for @pivotFuncAverage.
  ///
  /// In ko, this message translates to:
  /// **'평균'**
  String get pivotFuncAverage;

  /// No description provided for @pivotFuncMin.
  ///
  /// In ko, this message translates to:
  /// **'최솟값'**
  String get pivotFuncMin;

  /// No description provided for @pivotFuncMax.
  ///
  /// In ko, this message translates to:
  /// **'최댓값'**
  String get pivotFuncMax;

  /// No description provided for @pivotCreated.
  ///
  /// In ko, this message translates to:
  /// **'\'\'{name}\'\' 시트에 피벗 테이블이 생성됨'**
  String pivotCreated(String name);

  /// No description provided for @pivotNoData.
  ///
  /// In ko, this message translates to:
  /// **'피벗 테이블을 만들기 전에 데이터 범위를 선택하세요'**
  String get pivotNoData;

  /// No description provided for @presentationItalic.
  ///
  /// In ko, this message translates to:
  /// **'기울임꼴'**
  String get presentationItalic;

  /// No description provided for @presentationUnderline.
  ///
  /// In ko, this message translates to:
  /// **'밑줄'**
  String get presentationUnderline;

  /// No description provided for @presentationStrikethrough.
  ///
  /// In ko, this message translates to:
  /// **'취소선'**
  String get presentationStrikethrough;

  /// No description provided for @presentationFontFamily.
  ///
  /// In ko, this message translates to:
  /// **'글꼴'**
  String get presentationFontFamily;

  /// No description provided for @presentationFontSystem.
  ///
  /// In ko, this message translates to:
  /// **'시스템'**
  String get presentationFontSystem;

  /// No description provided for @documentPageSetup.
  ///
  /// In ko, this message translates to:
  /// **'페이지 설정'**
  String get documentPageSetup;

  /// No description provided for @documentHeader.
  ///
  /// In ko, this message translates to:
  /// **'머리글'**
  String get documentHeader;

  /// No description provided for @documentFooter.
  ///
  /// In ko, this message translates to:
  /// **'바닥글'**
  String get documentFooter;

  /// No description provided for @documentHeaderHint.
  ///
  /// In ko, this message translates to:
  /// **'머리글 텍스트 입력'**
  String get documentHeaderHint;

  /// No description provided for @documentFooterHint.
  ///
  /// In ko, this message translates to:
  /// **'바닥글 텍스트 입력'**
  String get documentFooterHint;

  /// No description provided for @documentPageSetupApplied.
  ///
  /// In ko, this message translates to:
  /// **'페이지 설정이 적용됨'**
  String get documentPageSetupApplied;

  /// No description provided for @documentOutline.
  ///
  /// In ko, this message translates to:
  /// **'개요'**
  String get documentOutline;

  /// No description provided for @documentOutlineEmpty.
  ///
  /// In ko, this message translates to:
  /// **'제목을 추가하면 개요가 표시됩니다'**
  String get documentOutlineEmpty;

  /// No description provided for @documentOutlineTitle.
  ///
  /// In ko, this message translates to:
  /// **'문서 개요'**
  String get documentOutlineTitle;

  /// No description provided for @presenterView.
  ///
  /// In ko, this message translates to:
  /// **'발표자 보기'**
  String get presenterView;

  /// No description provided for @presenterElapsed.
  ///
  /// In ko, this message translates to:
  /// **'경과 시간'**
  String get presenterElapsed;

  /// No description provided for @presenterEndOfSlides.
  ///
  /// In ko, this message translates to:
  /// **'프레젠테이션 종료'**
  String get presenterEndOfSlides;

  /// No description provided for @presenterNextSlide.
  ///
  /// In ko, this message translates to:
  /// **'다음 슬라이드'**
  String get presenterNextSlide;

  /// No description provided for @documentInsertToc.
  ///
  /// In ko, this message translates to:
  /// **'목차 삽입'**
  String get documentInsertToc;

  /// No description provided for @documentTocInserted.
  ///
  /// In ko, this message translates to:
  /// **'목차가 삽입되었습니다'**
  String get documentTocInserted;

  /// No description provided for @documentTocTitle.
  ///
  /// In ko, this message translates to:
  /// **'목차'**
  String get documentTocTitle;

  /// No description provided for @documentTocEmpty.
  ///
  /// In ko, this message translates to:
  /// **'제목이 없습니다. 먼저 제목을 추가하세요.'**
  String get documentTocEmpty;

  /// No description provided for @homeTemplates.
  ///
  /// In ko, this message translates to:
  /// **'템플릿'**
  String get homeTemplates;

  /// No description provided for @templateGallery.
  ///
  /// In ko, this message translates to:
  /// **'템플릿 갤러리'**
  String get templateGallery;

  /// No description provided for @templateDocuments.
  ///
  /// In ko, this message translates to:
  /// **'문서'**
  String get templateDocuments;

  /// No description provided for @templateSpreadsheets.
  ///
  /// In ko, this message translates to:
  /// **'스프레드시트'**
  String get templateSpreadsheets;

  /// No description provided for @templatePresentations.
  ///
  /// In ko, this message translates to:
  /// **'프레젠테이션'**
  String get templatePresentations;

  /// No description provided for @templateLetter.
  ///
  /// In ko, this message translates to:
  /// **'편지'**
  String get templateLetter;

  /// No description provided for @templateReport.
  ///
  /// In ko, this message translates to:
  /// **'보고서'**
  String get templateReport;

  /// No description provided for @templateResume.
  ///
  /// In ko, this message translates to:
  /// **'이력서'**
  String get templateResume;

  /// No description provided for @templateBudget.
  ///
  /// In ko, this message translates to:
  /// **'예산'**
  String get templateBudget;

  /// No description provided for @templateSchedule.
  ///
  /// In ko, this message translates to:
  /// **'일정'**
  String get templateSchedule;

  /// No description provided for @templateBlankDoc.
  ///
  /// In ko, this message translates to:
  /// **'빈 문서'**
  String get templateBlankDoc;

  /// No description provided for @templateBlankSheet.
  ///
  /// In ko, this message translates to:
  /// **'빈 스프레드시트'**
  String get templateBlankSheet;

  /// No description provided for @slideSorter.
  ///
  /// In ko, this message translates to:
  /// **'슬라이드 정렬'**
  String get slideSorter;

  /// No description provided for @slideSorterHint.
  ///
  /// In ko, this message translates to:
  /// **'탭하여 편집, 길게 눌러 재정렬'**
  String get slideSorterHint;

  /// No description provided for @autoSave.
  ///
  /// In ko, this message translates to:
  /// **'자동 저장'**
  String get autoSave;

  /// No description provided for @autoSaveOn.
  ///
  /// In ko, this message translates to:
  /// **'자동 저장 켜짐'**
  String get autoSaveOn;

  /// No description provided for @autoSaveOff.
  ///
  /// In ko, this message translates to:
  /// **'자동 저장 꺼짐'**
  String get autoSaveOff;

  /// No description provided for @autoSavedAt.
  ///
  /// In ko, this message translates to:
  /// **'{time}에 자동 저장됨'**
  String autoSavedAt(String time);

  /// No description provided for @autoSaveNewFile.
  ///
  /// In ko, this message translates to:
  /// **'자동 저장을 활성화하려면 먼저 저장하세요'**
  String get autoSaveNewFile;

  /// No description provided for @autoSaving.
  ///
  /// In ko, this message translates to:
  /// **'자동 저장 중...'**
  String get autoSaving;

  /// No description provided for @autoSaveError.
  ///
  /// In ko, this message translates to:
  /// **'자동 저장 실패'**
  String get autoSaveError;

  /// No description provided for @autoSaveDisabled.
  ///
  /// In ko, this message translates to:
  /// **'자동 저장 비활성화'**
  String get autoSaveDisabled;

  /// No description provided for @slideshowTapToAnimate.
  ///
  /// In ko, this message translates to:
  /// **'탭하여 애니메이션 재생'**
  String get slideshowTapToAnimate;

  /// No description provided for @slideshowAnimationsComplete.
  ///
  /// In ko, this message translates to:
  /// **'모든 애니메이션 재생 완료'**
  String get slideshowAnimationsComplete;

  /// No description provided for @presentationBringToFront.
  ///
  /// In ko, this message translates to:
  /// **'맨 앞으로'**
  String get presentationBringToFront;

  /// No description provided for @presentationSendToBack.
  ///
  /// In ko, this message translates to:
  /// **'맨 뒤로'**
  String get presentationSendToBack;

  /// No description provided for @presentationBringForward.
  ///
  /// In ko, this message translates to:
  /// **'앞으로'**
  String get presentationBringForward;

  /// No description provided for @presentationSendBackward.
  ///
  /// In ko, this message translates to:
  /// **'뒤로'**
  String get presentationSendBackward;

  /// No description provided for @presentationDuplicateElement.
  ///
  /// In ko, this message translates to:
  /// **'요소 복제'**
  String get presentationDuplicateElement;

  /// No description provided for @presentationZOrder.
  ///
  /// In ko, this message translates to:
  /// **'레이어 순서'**
  String get presentationZOrder;

  /// No description provided for @keyboardShortcuts.
  ///
  /// In ko, this message translates to:
  /// **'키보드 단축키'**
  String get keyboardShortcuts;

  /// No description provided for @shortcutSave.
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get shortcutSave;

  /// No description provided for @shortcutFind.
  ///
  /// In ko, this message translates to:
  /// **'찾기'**
  String get shortcutFind;

  /// No description provided for @shortcutDelete.
  ///
  /// In ko, this message translates to:
  /// **'선택 삭제'**
  String get shortcutDelete;

  /// No description provided for @shortcutDuplicate.
  ///
  /// In ko, this message translates to:
  /// **'복제'**
  String get shortcutDuplicate;

  /// No description provided for @shortcutNavigation.
  ///
  /// In ko, this message translates to:
  /// **'셀 이동'**
  String get shortcutNavigation;

  /// No description provided for @documentReadingTime.
  ///
  /// In ko, this message translates to:
  /// **'~{count}분 읽기'**
  String documentReadingTime(int count);

  /// No description provided for @savedAt.
  ///
  /// In ko, this message translates to:
  /// **'{time}에 저장됨'**
  String savedAt(String time);

  /// No description provided for @lastSaved.
  ///
  /// In ko, this message translates to:
  /// **'마지막 저장: {time}'**
  String lastSaved(String time);

  /// No description provided for @snackbarSlideDeleted.
  ///
  /// In ko, this message translates to:
  /// **'슬라이드 삭제됨'**
  String get snackbarSlideDeleted;

  /// No description provided for @snackbarElementDeleted.
  ///
  /// In ko, this message translates to:
  /// **'요소 삭제됨'**
  String get snackbarElementDeleted;

  /// No description provided for @shortcutSectionCommon.
  ///
  /// In ko, this message translates to:
  /// **'공통'**
  String get shortcutSectionCommon;

  /// No description provided for @shortcutSectionDocument.
  ///
  /// In ko, this message translates to:
  /// **'문서'**
  String get shortcutSectionDocument;

  /// No description provided for @shortcutSectionPresentation.
  ///
  /// In ko, this message translates to:
  /// **'프레젠테이션'**
  String get shortcutSectionPresentation;

  /// No description provided for @shortcutSectionSpreadsheet.
  ///
  /// In ko, this message translates to:
  /// **'스프레드시트'**
  String get shortcutSectionSpreadsheet;

  /// No description provided for @shortcutUndo.
  ///
  /// In ko, this message translates to:
  /// **'실행 취소'**
  String get shortcutUndo;

  /// No description provided for @shortcutRedo.
  ///
  /// In ko, this message translates to:
  /// **'다시 실행'**
  String get shortcutRedo;

  /// No description provided for @shortcutBold.
  ///
  /// In ko, this message translates to:
  /// **'굵게'**
  String get shortcutBold;

  /// No description provided for @shortcutItalic.
  ///
  /// In ko, this message translates to:
  /// **'기울임'**
  String get shortcutItalic;

  /// No description provided for @shortcutUnderline.
  ///
  /// In ko, this message translates to:
  /// **'밑줄'**
  String get shortcutUnderline;

  /// No description provided for @shortcutNextCell.
  ///
  /// In ko, this message translates to:
  /// **'다음 셀'**
  String get shortcutNextCell;

  /// No description provided for @shortcutEditCell.
  ///
  /// In ko, this message translates to:
  /// **'셀 편집'**
  String get shortcutEditCell;

  /// No description provided for @shortcutCopy.
  ///
  /// In ko, this message translates to:
  /// **'복사'**
  String get shortcutCopy;

  /// No description provided for @shortcutCut.
  ///
  /// In ko, this message translates to:
  /// **'잘라내기'**
  String get shortcutCut;

  /// No description provided for @shortcutPaste.
  ///
  /// In ko, this message translates to:
  /// **'붙여넣기'**
  String get shortcutPaste;

  /// No description provided for @presentationEmptyTitle.
  ///
  /// In ko, this message translates to:
  /// **'슬라이드가 없습니다'**
  String get presentationEmptyTitle;

  /// No description provided for @presentationEmptyHint.
  ///
  /// In ko, this message translates to:
  /// **'슬라이드를 추가하여 프레젠테이션을 시작하세요'**
  String get presentationEmptyHint;

  /// No description provided for @spreadsheetErrorTitle.
  ///
  /// In ko, this message translates to:
  /// **'파일 로드 실패'**
  String get spreadsheetErrorTitle;

  /// No description provided for @spreadsheetErrorHint.
  ///
  /// In ko, this message translates to:
  /// **'파일이 손상되었거나 지원하지 않는 형식입니다'**
  String get spreadsheetErrorHint;

  /// No description provided for @commonRetry.
  ///
  /// In ko, this message translates to:
  /// **'다시 시도'**
  String get commonRetry;

  /// No description provided for @commonCreateNew.
  ///
  /// In ko, this message translates to:
  /// **'새로 만들기'**
  String get commonCreateNew;

  /// No description provided for @a11yQuickAction.
  ///
  /// In ko, this message translates to:
  /// **'빠른 실행: {label}'**
  String a11yQuickAction(String label);

  /// No description provided for @a11yRecentFile.
  ///
  /// In ko, this message translates to:
  /// **'최근 파일: {name}'**
  String a11yRecentFile(String name);

  /// No description provided for @a11yDocumentStatus.
  ///
  /// In ko, this message translates to:
  /// **'단어 {words}개, 문자 {chars}자, {pages}페이지'**
  String a11yDocumentStatus(int words, int chars, int pages);

  /// No description provided for @a11ySlideCount.
  ///
  /// In ko, this message translates to:
  /// **'슬라이드 {current}/{total}'**
  String a11ySlideCount(int current, int total);

  /// No description provided for @a11yEditTitle.
  ///
  /// In ko, this message translates to:
  /// **'제목 편집'**
  String get a11yEditTitle;

  /// No description provided for @a11yColorSwatch.
  ///
  /// In ko, this message translates to:
  /// **'색상: {color}'**
  String a11yColorSwatch(String color);

  /// No description provided for @homeTotalFiles.
  ///
  /// In ko, this message translates to:
  /// **'총 파일'**
  String get homeTotalFiles;

  /// No description provided for @homeSeeAll.
  ///
  /// In ko, this message translates to:
  /// **'모두 보기'**
  String get homeSeeAll;

  /// No description provided for @homeStatsTab.
  ///
  /// In ko, this message translates to:
  /// **'통계'**
  String get homeStatsTab;

  /// No description provided for @homeSearchTab.
  ///
  /// In ko, this message translates to:
  /// **'검색'**
  String get homeSearchTab;

  /// No description provided for @homeProfileTab.
  ///
  /// In ko, this message translates to:
  /// **'프로필'**
  String get homeProfileTab;

  /// No description provided for @statsMonthlyActivity.
  ///
  /// In ko, this message translates to:
  /// **'월별 활동'**
  String get statsMonthlyActivity;

  /// No description provided for @statsLive.
  ///
  /// In ko, this message translates to:
  /// **'실시간'**
  String get statsLive;

  /// No description provided for @statsHoldings.
  ///
  /// In ko, this message translates to:
  /// **'파일 현황'**
  String get statsHoldings;

  /// No description provided for @statsThisMonth.
  ///
  /// In ko, this message translates to:
  /// **'이번 달'**
  String get statsThisMonth;

  /// No description provided for @statsStorageUsed.
  ///
  /// In ko, this message translates to:
  /// **'사용 중'**
  String get statsStorageUsed;

  /// No description provided for @statsStorageFree.
  ///
  /// In ko, this message translates to:
  /// **'여유 공간'**
  String get statsStorageFree;

  /// No description provided for @commandSearchPlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'파일, 명령어 검색...'**
  String get commandSearchPlaceholder;

  /// No description provided for @commandRecentlyUsed.
  ///
  /// In ko, this message translates to:
  /// **'최근 사용'**
  String get commandRecentlyUsed;

  /// No description provided for @commandFavorites.
  ///
  /// In ko, this message translates to:
  /// **'즐겨찾기'**
  String get commandFavorites;

  /// No description provided for @commandAllFiles.
  ///
  /// In ko, this message translates to:
  /// **'전체 파일'**
  String get commandAllFiles;

  /// No description provided for @commandShortcutHint.
  ///
  /// In ko, this message translates to:
  /// **'⌘K'**
  String get commandShortcutHint;

  /// No description provided for @profileStorageStatus.
  ///
  /// In ko, this message translates to:
  /// **'저장소 현황'**
  String get profileStorageStatus;

  /// No description provided for @profileQuickSettings.
  ///
  /// In ko, this message translates to:
  /// **'빠른 설정'**
  String get profileQuickSettings;

  /// No description provided for @profileActivityLog.
  ///
  /// In ko, this message translates to:
  /// **'활동 기록'**
  String get profileActivityLog;

  /// No description provided for @profileLanguage.
  ///
  /// In ko, this message translates to:
  /// **'언어'**
  String get profileLanguage;

  /// No description provided for @profileExport.
  ///
  /// In ko, this message translates to:
  /// **'내보내기'**
  String get profileExport;

  /// No description provided for @profileReset.
  ///
  /// In ko, this message translates to:
  /// **'초기화'**
  String get profileReset;

  /// No description provided for @profileVersion.
  ///
  /// In ko, this message translates to:
  /// **'버전'**
  String get profileVersion;

  /// No description provided for @nowViewing.
  ///
  /// In ko, this message translates to:
  /// **'현재 보는 중'**
  String get nowViewing;

  /// No description provided for @noFilesYet.
  ///
  /// In ko, this message translates to:
  /// **'아직 파일이 없습니다'**
  String get noFilesYet;

  /// No description provided for @tapToCreate.
  ///
  /// In ko, this message translates to:
  /// **'탭하여 새 파일 만들기'**
  String get tapToCreate;

  /// No description provided for @homeTimeJustNow.
  ///
  /// In ko, this message translates to:
  /// **'방금'**
  String get homeTimeJustNow;

  /// No description provided for @homeTimeMinutesAgo.
  ///
  /// In ko, this message translates to:
  /// **'{count}분 전'**
  String homeTimeMinutesAgo(int count);

  /// No description provided for @homeTimeHoursAgo.
  ///
  /// In ko, this message translates to:
  /// **'{count}시간 전'**
  String homeTimeHoursAgo(int count);

  /// No description provided for @homeTimeDaysAgo.
  ///
  /// In ko, this message translates to:
  /// **'{count}일 전'**
  String homeTimeDaysAgo(int count);

  /// No description provided for @selectLanguage.
  ///
  /// In ko, this message translates to:
  /// **'언어 선택'**
  String get selectLanguage;

  /// No description provided for @languageKorean.
  ///
  /// In ko, this message translates to:
  /// **'한국어'**
  String get languageKorean;

  /// No description provided for @languageEnglish.
  ///
  /// In ko, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @profileResetConfirm.
  ///
  /// In ko, this message translates to:
  /// **'최근 파일 기록이 모두 삭제됩니다. 계속하시겠습니까?'**
  String get profileResetConfirm;

  /// No description provided for @profileExportDesc.
  ///
  /// In ko, this message translates to:
  /// **'최근 파일을 다른 앱으로 공유합니다'**
  String get profileExportDesc;

  /// No description provided for @profileExportNoFiles.
  ///
  /// In ko, this message translates to:
  /// **'내보낼 최근 파일이 없습니다'**
  String get profileExportNoFiles;

  /// No description provided for @statsUpdated.
  ///
  /// In ko, this message translates to:
  /// **'업데이트됨'**
  String get statsUpdated;

  /// No description provided for @documentUntitled.
  ///
  /// In ko, this message translates to:
  /// **'제목 없는 문서'**
  String get documentUntitled;

  /// No description provided for @presentationUntitled.
  ///
  /// In ko, this message translates to:
  /// **'제목 없는 프레젠테이션'**
  String get presentationUntitled;

  /// No description provided for @spreadsheetUntitled.
  ///
  /// In ko, this message translates to:
  /// **'새 스프레드시트'**
  String get spreadsheetUntitled;

  /// No description provided for @spreadsheetSaveDialog.
  ///
  /// In ko, this message translates to:
  /// **'스프레드시트 저장'**
  String get spreadsheetSaveDialog;

  /// No description provided for @formulaError.
  ///
  /// In ko, this message translates to:
  /// **'!오류'**
  String get formulaError;

  /// No description provided for @statsSum.
  ///
  /// In ko, this message translates to:
  /// **'합계'**
  String get statsSum;

  /// No description provided for @statsAverage.
  ///
  /// In ko, this message translates to:
  /// **'평균'**
  String get statsAverage;

  /// No description provided for @statsCount.
  ///
  /// In ko, this message translates to:
  /// **'개수'**
  String get statsCount;

  /// No description provided for @sheetCopySuffix.
  ///
  /// In ko, this message translates to:
  /// **'사본'**
  String get sheetCopySuffix;

  /// No description provided for @sheetCopySuffixN.
  ///
  /// In ko, this message translates to:
  /// **'사본 {cnt}'**
  String sheetCopySuffixN(int cnt);

  /// No description provided for @slideTitleSlide.
  ///
  /// In ko, this message translates to:
  /// **'제목 슬라이드'**
  String get slideTitleSlide;

  /// No description provided for @slidePresentationTitle.
  ///
  /// In ko, this message translates to:
  /// **'프레젠테이션 제목'**
  String get slidePresentationTitle;

  /// No description provided for @slideSubtitleHint.
  ///
  /// In ko, this message translates to:
  /// **'부제목을 입력하세요'**
  String get slideSubtitleHint;

  /// No description provided for @slideSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'부제목'**
  String get slideSubtitle;

  /// No description provided for @slideNumbered.
  ///
  /// In ko, this message translates to:
  /// **'슬라이드 {number}'**
  String slideNumbered(int number);

  /// No description provided for @slideTitleHint.
  ///
  /// In ko, this message translates to:
  /// **'제목을 입력하세요'**
  String get slideTitleHint;

  /// No description provided for @slideTitleBody.
  ///
  /// In ko, this message translates to:
  /// **'제목 + 본문'**
  String get slideTitleBody;

  /// No description provided for @slideBodyHint.
  ///
  /// In ko, this message translates to:
  /// **'본문 내용을 입력하세요'**
  String get slideBodyHint;

  /// No description provided for @slideTwoColumn.
  ///
  /// In ko, this message translates to:
  /// **'2단 비교'**
  String get slideTwoColumn;

  /// No description provided for @slideComparisonTitle.
  ///
  /// In ko, this message translates to:
  /// **'비교 제목'**
  String get slideComparisonTitle;

  /// No description provided for @slideLeftContent.
  ///
  /// In ko, this message translates to:
  /// **'왼쪽 내용'**
  String get slideLeftContent;

  /// No description provided for @slideRightContent.
  ///
  /// In ko, this message translates to:
  /// **'오른쪽 내용'**
  String get slideRightContent;

  /// No description provided for @slideSectionBreak.
  ///
  /// In ko, this message translates to:
  /// **'섹션 구분'**
  String get slideSectionBreak;

  /// No description provided for @slideSectionTitle.
  ///
  /// In ko, this message translates to:
  /// **'섹션 제목'**
  String get slideSectionTitle;

  /// No description provided for @errorFileNotFound.
  ///
  /// In ko, this message translates to:
  /// **'파일을 찾을 수 없습니다: {path}'**
  String errorFileNotFound(String path);

  /// No description provided for @spreadsheetBudget.
  ///
  /// In ko, this message translates to:
  /// **'Budget'**
  String get spreadsheetBudget;

  /// No description provided for @spreadsheetSchedule.
  ///
  /// In ko, this message translates to:
  /// **'Schedule'**
  String get spreadsheetSchedule;

  /// No description provided for @settingsAppearance.
  ///
  /// In ko, this message translates to:
  /// **'외관'**
  String get settingsAppearance;

  /// No description provided for @settingsFiles.
  ///
  /// In ko, this message translates to:
  /// **'파일'**
  String get settingsFiles;

  /// No description provided for @settingsData.
  ///
  /// In ko, this message translates to:
  /// **'데이터'**
  String get settingsData;

  /// No description provided for @settingsAbout.
  ///
  /// In ko, this message translates to:
  /// **'정보'**
  String get settingsAbout;

  /// No description provided for @settingsTheme.
  ///
  /// In ko, this message translates to:
  /// **'테마'**
  String get settingsTheme;

  /// No description provided for @settingsThemeSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'라이트, 다크 또는 시스템'**
  String get settingsThemeSubtitle;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In ko, this message translates to:
  /// **'시스템'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In ko, this message translates to:
  /// **'라이트'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In ko, this message translates to:
  /// **'다크'**
  String get settingsThemeDark;

  /// No description provided for @settingsLanguageSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'앱 표시 언어'**
  String get settingsLanguageSubtitle;

  /// No description provided for @settingsAutoSaveSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'파일을 자동으로 저장'**
  String get settingsAutoSaveSubtitle;

  /// No description provided for @settingsKeyboardSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'모든 단축키 보기'**
  String get settingsKeyboardSubtitle;

  /// No description provided for @settingsExportSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'최근 파일 공유'**
  String get settingsExportSubtitle;

  /// No description provided for @settingsResetSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'최근 파일 기록 삭제'**
  String get settingsResetSubtitle;

  /// No description provided for @settingsVersionSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'현재 앱 버전'**
  String get settingsVersionSubtitle;

  /// No description provided for @settingsLicenses.
  ///
  /// In ko, this message translates to:
  /// **'오픈소스 라이선스'**
  String get settingsLicenses;

  /// No description provided for @settingsLicensesSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'서드파티 라이브러리'**
  String get settingsLicensesSubtitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
