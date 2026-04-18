// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appName => 'Excelia';

  @override
  String get appSubtitle => '모바일 오피스';

  @override
  String get appVersion => '버전 1.0.0';

  @override
  String get commonSave => '저장';

  @override
  String get commonCancel => '취소';

  @override
  String get commonDelete => '삭제';

  @override
  String get commonClear => '지우기';

  @override
  String get commonClose => '닫기';

  @override
  String get commonOpen => '열기';

  @override
  String get commonShare => '공유';

  @override
  String get commonContinue => '계속';

  @override
  String get commonAdd => '추가';

  @override
  String get commonMove => '이동';

  @override
  String get commonReset => '리셋';

  @override
  String get commonSettings => '설정';

  @override
  String get commonLoading => '로딩 중...';

  @override
  String get commonBack => '뒤로가기';

  @override
  String get commonUndo => '실행 취소';

  @override
  String get commonRedo => '다시 실행';

  @override
  String get commonMore => '더보기';

  @override
  String get commonSaving => '저장 중...';

  @override
  String get commonSaved => '저장됨';

  @override
  String get commonUnsavedChanges => '저장되지 않은 변경사항';

  @override
  String get commonSaveAs => '다른 이름으로 저장';

  @override
  String get commonDoNotSave => '저장 안 함';

  @override
  String get commonOn => '켜짐';

  @override
  String get commonOff => '꺼짐';

  @override
  String get homeTitle => '홈';

  @override
  String get homeFiles => '파일';

  @override
  String get homeFavorites => '즐겨찾기';

  @override
  String get homeCreateNew => '새로 만들기';

  @override
  String get homeRecentFiles => '최근 파일';

  @override
  String get homeClearAll => '모두 지우기';

  @override
  String get homeNoRecentFiles => '최근 파일이 없습니다';

  @override
  String get homeNoRecentFilesHint => '새 문서를 만들거나 파일을 열어보세요';

  @override
  String get homeClearRecentTitle => '최근 파일 지우기';

  @override
  String get homeClearRecentMessage => '최근 파일 목록을 모두 지우시겠습니까?';

  @override
  String get homeNoFiles => '파일이 없습니다';

  @override
  String get homeOpenFileHint => '파일을 열어보세요';

  @override
  String get homeFavoritesEmpty => '즐겨찾기가 비어있습니다';

  @override
  String get homeFavoritesHint => '자주 사용하는 파일을 즐겨찾기에 추가하세요';

  @override
  String get homeSearchFiles => '파일 검색...';

  @override
  String get homeSearchTitle => '파일 검색';

  @override
  String get homeSearchHint => '파일 이름으로 검색';

  @override
  String get homeNoSearchResults => '검색 결과가 없습니다';

  @override
  String get homeGeneral => '일반';

  @override
  String get homeDarkMode => '다크 모드';

  @override
  String get homeData => '데이터';

  @override
  String get homeRecentFileHistory => '최근 파일 기록';

  @override
  String get homeInfo => '정보';

  @override
  String get homeSupportedFormats => '지원 형식';

  @override
  String get homeSupportedFormatsDetail => 'xlsx, xls, docx, pptx, pdf';

  @override
  String get homeAll => '전체';

  @override
  String get fileOpen => '파일 열기';

  @override
  String fileOpenError(String error) {
    return '파일 열기 실패: $error';
  }

  @override
  String get fileNotFound => '파일을 찾을 수 없습니다';

  @override
  String fileNotFoundName(String name) {
    return '파일을 찾을 수 없습니다: $name';
  }

  @override
  String get filePermissionRequired => '파일에 접근하려면 저장소 권한이 필요합니다.';

  @override
  String get filePathError => '파일 경로를 가져올 수 없습니다. 다시 시도해 주세요.';

  @override
  String get fileReadError => '파일을 읽을 수 없습니다. 파일이 삭제되었거나 접근 권한이 없습니다.';

  @override
  String get fileUnsupportedFormat => '지원하지 않는 파일 형식입니다.';

  @override
  String fileShareError(String error) {
    return '공유 실패: $error';
  }

  @override
  String get fileDeleteTitle => '파일 삭제';

  @override
  String fileDeleteConfirm(String name) {
    return '\"$name\"을(를) 최근 파일 목록에서 삭제하시겠습니까?';
  }

  @override
  String fileCount(int count) {
    return '$count개 파일';
  }

  @override
  String fileLabelCount(String label, int count) {
    return '$label ($count)';
  }

  @override
  String fileLabelFileCount(String label, int count) {
    return '$label: $count개 파일';
  }

  @override
  String get fileLoading => '파일 불러오는 중...';

  @override
  String get fileSaved => '저장 완료';

  @override
  String get fileLoadRecentError => '최근 파일 목록 불러오기 실패';

  @override
  String get typeSpreadsheet => '스프레드시트';

  @override
  String get typeDocument => '문서';

  @override
  String get typePresentation => '프레젠테이션';

  @override
  String get typePdf => 'PDF';

  @override
  String get newSpreadsheet => '새 스프레드시트';

  @override
  String get newDocument => '새 문서';

  @override
  String get newPresentation => '새 프레젠테이션';

  @override
  String get pdfOpen => 'PDF 열기';

  @override
  String get spreadsheetOpen => '스프레드시트 열기';

  @override
  String get homeOpenFile => '파일 열기';

  @override
  String get openInExternalApp => '외부 앱으로 열기';

  @override
  String get legacyFormatTitle => '구형 파일 포맷';

  @override
  String legacyFormatBody(String ext) {
    return '$ext 파일은 Excelia에서 직접 열 수 없습니다. 설치된 오피스 앱(한컴, MS Office, WPS 등)으로 여시겠습니까?';
  }

  @override
  String get externalAppError => '외부 앱을 찾지 못했습니다. 오피스 앱을 설치해 주세요.';

  @override
  String externalAppOpenFailed(String error) {
    return '외부 앱으로 열기에 실패했습니다: $error';
  }

  @override
  String get parseFailedOpenExternal => '파일을 읽지 못했습니다. 외부 앱으로 열어보시겠습니까?';

  @override
  String get subtitleExcelCompat => 'Excel 호환';

  @override
  String get subtitleWordCompat => 'Word 호환';

  @override
  String get subtitlePptCompat => 'PPT 호환';

  @override
  String get subtitlePdfViewer => 'PDF 뷰어';

  @override
  String get spreadsheetOpenError =>
      '스프레드시트 파일을 열 수 없습니다. 파일이 손상되었거나 지원하지 않는 형식입니다.';

  @override
  String get spreadsheetSaveChanges => '변경사항을 저장하시겠습니까?';

  @override
  String get spreadsheetInsertRow => '행 삽입';

  @override
  String get spreadsheetDeleteRow => '행 삭제';

  @override
  String get spreadsheetInsertCol => '열 삽입';

  @override
  String get spreadsheetDeleteCol => '열 삭제';

  @override
  String get spreadsheetSortAsc => '오름차순 정렬';

  @override
  String get spreadsheetSortDesc => '내림차순 정렬';

  @override
  String get spreadsheetPrintPreview => '인쇄 미리보기';

  @override
  String get spreadsheetPrint => '인쇄';

  @override
  String get spreadsheetNoData => '데이터가 없습니다';

  @override
  String spreadsheetPrintPreviewTitle(String name) {
    return '인쇄 미리보기 - $name';
  }

  @override
  String spreadsheetZoomPercent(int percent) {
    return '$percent%';
  }

  @override
  String get sheetNew => '새 시트';

  @override
  String get sheetName => '시트 이름';

  @override
  String get sheetNameHint => '시트 이름을 입력하세요';

  @override
  String get sheetRename => '이름 변경';

  @override
  String get sheetDuplicate => '복제';

  @override
  String get sheetDeleteTitle => '시트 삭제';

  @override
  String sheetDeleteConfirm(String name) {
    return '\'$name\' 시트를 삭제하시겠습니까?';
  }

  @override
  String documentOpenError(String error) {
    return '문서 파일 열기 실패: $error';
  }

  @override
  String get documentExportPdf => 'PDF로 내보내기';

  @override
  String get documentPrintPreview => '인쇄 미리보기';

  @override
  String get documentPrint => '인쇄';

  @override
  String get documentPlaceholder => '여기에 내용을 입력하세요...';

  @override
  String documentWordCount(int count) {
    return '단어 $count개';
  }

  @override
  String documentCharCount(int count) {
    return '문자 $count자';
  }

  @override
  String documentPageEstimate(int count) {
    return '약 $count페이지';
  }

  @override
  String get documentSaveTitle => '문서 저장';

  @override
  String get documentSaved => '문서가 저장되었습니다';

  @override
  String documentSaveError(String error) {
    return '저장 실패: $error';
  }

  @override
  String documentExportDone(String path) {
    return 'PDF 내보내기 완료: $path';
  }

  @override
  String documentExportError(String error) {
    return 'PDF 내보내기 실패: $error';
  }

  @override
  String documentPrintPreviewTitle(String name) {
    return '인쇄 미리보기 - $name';
  }

  @override
  String documentPreviewError(String error) {
    return '미리보기 실패: $error';
  }

  @override
  String documentPrintError(String error) {
    return '인쇄 실패: $error';
  }

  @override
  String get documentOpenFile => '문서 열기';

  @override
  String get documentNew => '새 문서';

  @override
  String get documentNewConfirm => '저장하지 않은 변경사항이 있습니다. 계속하시겠습니까?';

  @override
  String get documentInsertDivider => '구분선 삽입';

  @override
  String get documentInsertImage => '이미지 삽입';

  @override
  String get documentSelectImage => '이미지 선택';

  @override
  String get documentClose => '문서 닫기';

  @override
  String get documentUnsavedChanges => '저장하지 않은 변경사항이 있습니다.';

  @override
  String presentationOpenError(String error) {
    return '프레젠테이션 파일 열기 실패: $error';
  }

  @override
  String get presentationSlideshow => '슬라이드쇼';

  @override
  String get presentationSlideList => '슬라이드 목록';

  @override
  String get presentationProperties => '속성 패널';

  @override
  String get presentationGridSnap => '격자 맞춤';

  @override
  String get presentationSlidePanel => '슬라이드 패널';

  @override
  String get presentationPrintPreview => '인쇄 미리보기';

  @override
  String get presentationPrint => '인쇄';

  @override
  String get presentationAddSlide => '슬라이드 추가';

  @override
  String get presentationNoSlides => '슬라이드가 없습니다';

  @override
  String get presentationElementProps => '요소 속성';

  @override
  String get presentationDeleteElement => '요소 삭제';

  @override
  String get presentationRectangle => '사각형';

  @override
  String get presentationCircle => '원';

  @override
  String get presentationTriangle => '삼각형';

  @override
  String get presentationArrow => '화살표';

  @override
  String get presentationBgColor => '슬라이드 배경색';

  @override
  String get presentationSaved => '프레젠테이션이 저장되었습니다';

  @override
  String presentationSaveError(String error) {
    return '저장 실패: $error';
  }

  @override
  String presentationPrintPreviewTitle(String name) {
    return '인쇄 미리보기 - $name';
  }

  @override
  String get presentationDuplicate => '슬라이드 복제';

  @override
  String get presentationDeleteSlide => '슬라이드 삭제';

  @override
  String get presentationMoveUp => '위로 이동';

  @override
  String get presentationMoveDown => '아래로 이동';

  @override
  String get presentationImagePlaceholder => '[이미지]';

  @override
  String get presentationSelectElement => '요소를 선택하면\n속성을 편집할 수 있습니다';

  @override
  String get presentationPosition => '위치';

  @override
  String get presentationSize => '크기';

  @override
  String get presentationFontSize => '글꼴 크기';

  @override
  String get presentationBold => '굵게';

  @override
  String get presentationAlignment => '정렬';

  @override
  String get presentationTextColor => '글자 색상';

  @override
  String get presentationBackgroundColor => '배경 색상';

  @override
  String get presentationText => '텍스트';

  @override
  String get presentationDefaultText => '텍스트를 입력하세요';

  @override
  String get presentationInsertShape => '도형 삽입';

  @override
  String get presentationShape => '도형';

  @override
  String get presentationImage => '이미지';

  @override
  String get presentationBgColorShort => '배경색';

  @override
  String get presentationSaveTitle => '프레젠테이션 저장';

  @override
  String get presentationOpenTitle => '프레젠테이션 열기';

  @override
  String get pdfViewer => 'PDF 뷰어';

  @override
  String get pdfFileNotFound => '파일을 찾을 수 없습니다';

  @override
  String get pdfOpenFile => 'PDF 파일 열기';

  @override
  String get pdfThumbnail => '썸네일';

  @override
  String get pdfDayMode => '주간 모드';

  @override
  String get pdfNightMode => '야간 모드';

  @override
  String get pdfOpenPrompt => 'PDF 파일을 열어주세요';

  @override
  String get pdfOpenHint => '파일을 선택하여 PDF 문서를 확인할 수 있습니다';

  @override
  String get pdfCannotOpen => 'PDF를 열 수 없습니다';

  @override
  String get pdfOpenAnother => '다른 파일 열기';

  @override
  String get pdfPageList => '페이지 목록';

  @override
  String get pdfPrevPage => '이전 페이지';

  @override
  String get pdfNextPage => '다음 페이지';

  @override
  String get pdfFirstPage => '첫 페이지';

  @override
  String get pdfLastPage => '마지막 페이지';

  @override
  String get pdfJumpToPage => '페이지 이동';

  @override
  String pdfPageNumber(int total) {
    return '페이지 번호 (1 ~ $total)';
  }

  @override
  String get pdfPrint => '인쇄';

  @override
  String get toolbarClose => '닫기';

  @override
  String get toolbarBold => '굵게';

  @override
  String get toolbarItalic => '기울임';

  @override
  String get toolbarUnderline => '밑줄';

  @override
  String get toolbarTextColor => '글자 색';

  @override
  String get toolbarBgColor => '배경 색';

  @override
  String get toolbarAlignLeft => '왼쪽 정렬';

  @override
  String get toolbarAlignCenter => '가운데 정렬';

  @override
  String get toolbarAlignRight => '오른쪽 정렬';

  @override
  String get toolbarWrapText => '텍스트 줄바꿈';

  @override
  String get toolbarFormatTools => '서식 도구';

  @override
  String get numberFormatGeneral => '일반';

  @override
  String get numberFormatNumber => '숫자';

  @override
  String get numberFormatCurrency => '통화';

  @override
  String get numberFormatPercent => '퍼센트';

  @override
  String get numberFormatDate => '날짜';

  @override
  String get pageSetupTitle => '페이지 설정';

  @override
  String get paperSize => '용지 크기';

  @override
  String get paperSizeA4 => 'A4';

  @override
  String get paperSizeA5 => 'A5';

  @override
  String get paperSizeLetter => 'Letter';

  @override
  String get paperSizeLegal => 'Legal';

  @override
  String get orientationLabel => '방향';

  @override
  String get orientationLandscape => '가로';

  @override
  String get orientationPortrait => '세로';

  @override
  String get marginsLabel => '여백';

  @override
  String get marginNormal => '보통';

  @override
  String get marginNarrow => '좁게';

  @override
  String get marginWide => '넓게';

  @override
  String get scaleLabel => '배율';

  @override
  String get scaleFitWidth => '너비 맞춤';

  @override
  String get scaleFitPage => '페이지 맞춤';

  @override
  String get scaleActual => '실제 크기';

  @override
  String get showGridlines => '격자선 표시';

  @override
  String get showFileName => '파일명 표시';

  @override
  String get showPageNumbers => '페이지 번호 표시';

  @override
  String get pageSetupApply => '적용';

  @override
  String get contextCut => '잘라내기';

  @override
  String get contextCopy => '복사';

  @override
  String get contextPaste => '붙여넣기';

  @override
  String get contextInsertRow => '행 삽입';

  @override
  String get contextInsertCol => '열 삽입';

  @override
  String get contextDeleteRow => '행 삭제';

  @override
  String get contextDeleteCol => '열 삭제';

  @override
  String get contextClearContent => '내용 지우기';

  @override
  String get mergeCells => '셀 병합';

  @override
  String get unmergeCells => '셀 병합 해제';

  @override
  String get fontSize => '글꼴 크기';

  @override
  String get findTitle => '찾기';

  @override
  String get findHint => '검색어 입력...';

  @override
  String get replaceHint => '바꿀 내용 입력...';

  @override
  String get replaceOne => '바꾸기';

  @override
  String get replaceAllBtn => '전체 바꾸기';

  @override
  String findMatchCount(int current, int total) {
    return '$current/$total';
  }

  @override
  String get findNoMatch => '결과 없음';

  @override
  String get freezePanes => '틀 고정';

  @override
  String get unfreezePanes => '틀 고정 해제';

  @override
  String get borderAll => '모든 테두리';

  @override
  String get borderOutside => '바깥쪽 테두리';

  @override
  String get borderBottom => '아래쪽 테두리';

  @override
  String get borderNone => '테두리 없음';

  @override
  String get formatPainter => '서식 복사';

  @override
  String get hideRow => '행 숨기기';

  @override
  String get hideCol => '열 숨기기';

  @override
  String get unhideAll => '숨기기 해제';

  @override
  String get addComment => '메모 추가';

  @override
  String get editComment => '메모 편집';

  @override
  String get deleteComment => '메모 삭제';

  @override
  String get commentHint => '메모를 입력하세요...';

  @override
  String get autoFilter => '자동 필터';

  @override
  String get clearAutoFilter => '필터 해제';

  @override
  String get filterValues => '필터 값';

  @override
  String get filterSelectAll => '전체 선택';

  @override
  String get filterClearAll => '전체 해제';

  @override
  String get conditionalFormat => '조건부 서식';

  @override
  String get conditionType => '조건 유형';

  @override
  String get condGreaterThan => '보다 큼';

  @override
  String get condLessThan => '보다 작음';

  @override
  String get condEqualTo => '같음';

  @override
  String get condBetween => '사이';

  @override
  String get condTextContains => '텍스트 포함';

  @override
  String get condIsEmpty => '비어 있음';

  @override
  String get condIsNotEmpty => '비어 있지 않음';

  @override
  String get condValue => '값';

  @override
  String get condValue2 => '값 2';

  @override
  String get condFormatStyle => '서식 스타일';

  @override
  String get condApply => '적용';

  @override
  String get condClearAll => '규칙 모두 지우기';

  @override
  String get insertChart => '차트 삽입';

  @override
  String get chartType => '차트 종류';

  @override
  String get chartBar => '막대 차트';

  @override
  String get chartLine => '꺾은선 차트';

  @override
  String get chartPie => '원형 차트';

  @override
  String get chartTitle => '차트 제목';

  @override
  String get chartDefaultTitle => '차트';

  @override
  String get chartCreate => '만들기';

  @override
  String get chartDataHint =>
      '차트를 삽입하기 전에 데이터가 있는 셀을 선택하세요. 첫 번째 열 = 라벨, 두 번째 열 = 값';

  @override
  String get chartScatter => '산점도';

  @override
  String get chartArea => '영역 차트';

  @override
  String get chartStackedBar => '누적 막대';

  @override
  String get chartDoughnut => '도넛 차트';

  @override
  String get chartRadar => '방사형 차트';

  @override
  String get chartCombo => '복합 차트';

  @override
  String get chartAxisX => 'X축 제목';

  @override
  String get chartAxisY => 'Y축 제목';

  @override
  String get chartGridlines => '격자선';

  @override
  String get chartLegend => '범례 위치';

  @override
  String get chartLegendNone => '없음';

  @override
  String get chartLegendTop => '위';

  @override
  String get chartLegendBottom => '아래';

  @override
  String get chartLegendLeft => '왼쪽';

  @override
  String get chartLegendRight => '오른쪽';

  @override
  String get chartCustomize => '차트 커스터마이즈';

  @override
  String get dataValidation => '데이터 유효성 검사';

  @override
  String get dataValidationType => '검증 유형';

  @override
  String get dataValidationTypeList => '목록';

  @override
  String get dataValidationTypeWholeNumber => '정수';

  @override
  String get dataValidationTypeDecimal => '소수';

  @override
  String get dataValidationTypeDate => '날짜';

  @override
  String get dataValidationTypeTextLength => '텍스트 길이';

  @override
  String get dataValidationTypeCustom => '사용자 지정';

  @override
  String get dataValidationOperator => '연산자';

  @override
  String get dataValidationOpBetween => '사이';

  @override
  String get dataValidationOpNotBetween => '사이가 아닌';

  @override
  String get dataValidationOpEqualTo => '같음';

  @override
  String get dataValidationOpNotEqualTo => '같지 않음';

  @override
  String get dataValidationOpGreaterThan => '보다 큼';

  @override
  String get dataValidationOpLessThan => '보다 작음';

  @override
  String get dataValidationOpGreaterOrEqual => '크거나 같음';

  @override
  String get dataValidationOpLessOrEqual => '작거나 같음';

  @override
  String get dataValidationListItems => '목록 항목';

  @override
  String get dataValidationListHint => '쉼표로 구분하여 항목 입력';

  @override
  String get dataValidationValue1 => '값 1';

  @override
  String get dataValidationValue2 => '값 2';

  @override
  String get dataValidationShowError => '유효하지 않은 입력 시 오류 표시';

  @override
  String get dataValidationFailed => '입력값이 유효성 검사 규칙에 맞지 않습니다';

  @override
  String get nameManager => '이름 관리자';

  @override
  String get namedRangeName => '이름';

  @override
  String get namedRangeRef => '범위 (예: A1:B5)';

  @override
  String get namedRangeEmpty => '정의된 명명 범위 없음';

  @override
  String get spreadsheetExportCsv => 'CSV로 내보내기';

  @override
  String get documentOpenDocx => 'DOCX 열기';

  @override
  String get documentSaveDocx => 'DOCX로 저장';

  @override
  String get documentExportDocx => 'DOCX로 내보내기';

  @override
  String get pptxOpen => 'PPTX 열기';

  @override
  String get pptxSave => 'PPTX로 저장';

  @override
  String get pptxExport => 'PPTX로 내보내기';

  @override
  String get slideTransition => '슬라이드 전환';

  @override
  String get transitionNone => '없음';

  @override
  String get transitionFade => '페이드';

  @override
  String get transitionPush => '밀기';

  @override
  String get transitionWipe => '닦기';

  @override
  String get transitionZoom => '확대/축소';

  @override
  String get transitionDuration => '지속 시간 (ms)';

  @override
  String get speakerNotes => '발표자 노트';

  @override
  String get speakerNotesHint => '발표자 노트 입력...';

  @override
  String get slideTemplate => '슬라이드 템플릿';

  @override
  String get templateTitle => '제목 슬라이드';

  @override
  String get templateTitleBody => '제목 + 본문';

  @override
  String get templateTwoColumn => '2단 비교';

  @override
  String get templateBlank => '빈 슬라이드';

  @override
  String get templateSection => '섹션 구분';

  @override
  String get templateImageText => '이미지 + 텍스트';

  @override
  String get elementAnimation => '요소 애니메이션';

  @override
  String get animationFadeIn => '페이드 인';

  @override
  String get animationFlyInLeft => '왼쪽에서 날아오기';

  @override
  String get animationFlyInRight => '오른쪽에서 날아오기';

  @override
  String get animationFlyInBottom => '아래에서 날아오기';

  @override
  String get animationZoomIn => '확대';

  @override
  String get animationTriggerClick => '클릭 시';

  @override
  String get animationTriggerWith => '이전 효과와 함께';

  @override
  String get animationTriggerAfter => '이전 효과 다음에';

  @override
  String get hyperlinkInsert => '하이퍼링크 삽입';

  @override
  String get hyperlinkUrl => 'URL';

  @override
  String get hyperlinkRemove => '하이퍼링크 제거';

  @override
  String get documentDocxLoaded => 'DOCX 파일을 불러왔습니다';

  @override
  String documentDocxSaved(String path) {
    return 'DOCX로 저장됨: $path';
  }

  @override
  String documentDocxError(String error) {
    return 'DOCX 오류: $error';
  }

  @override
  String get presentationPptxLoaded => 'PPTX 파일을 불러왔습니다';

  @override
  String presentationPptxSaved(String path) {
    return 'PPTX로 저장됨: $path';
  }

  @override
  String presentationPptxError(String error) {
    return 'PPTX 오류: $error';
  }

  @override
  String get pdfSearch => '검색';

  @override
  String get pdfSearchHint => '문서에서 검색...';

  @override
  String get pdfBookmark => '북마크';

  @override
  String get pdfNoBookmarks => '북마크 없음';

  @override
  String get pdfAnnotation => '주석';

  @override
  String get pdfAnnotationHighlight => '하이라이트';

  @override
  String get pdfAnnotationUnderline => '밑줄';

  @override
  String get pdfAnnotationStrikethrough => '취소선';

  @override
  String get pdfAnnotationOff => '끄기';

  @override
  String get pdfAnnotationColor => '색상';

  @override
  String get pdfAnnotationMode => '주석 모드';

  @override
  String pdfAnnotationActive(String mode) {
    return '활성: $mode';
  }

  @override
  String get documentInsertTable => '표 삽입';

  @override
  String get documentTableRows => '행';

  @override
  String get documentTableCols => '열';

  @override
  String get documentTableInsertTitle => '표 삽입';

  @override
  String get documentTableEditCell => '셀 편집';

  @override
  String get documentTableAddRow => '행 추가';

  @override
  String get documentTableAddCol => '열 추가';

  @override
  String get documentTableDeleteRow => '행 삭제';

  @override
  String get documentTableEditHeader => '헤더 편집';

  @override
  String get commonConfirm => '확인';

  @override
  String get documentImageLoaded => 'DOCX에서 이미지 로드됨';

  @override
  String documentImageError(String error) {
    return '이미지 로드 실패: $error';
  }

  @override
  String get pivotTable => '피벗 테이블';

  @override
  String get pivotTableCreate => '피벗 테이블 만들기';

  @override
  String get pivotDataRange => '데이터 범위';

  @override
  String get pivotRowField => '행 필드';

  @override
  String get pivotColField => '열 필드 (선택)';

  @override
  String get pivotValueField => '값 필드';

  @override
  String get pivotAggregateFunc => '집계 함수';

  @override
  String get pivotFuncSum => '합계';

  @override
  String get pivotFuncCount => '개수';

  @override
  String get pivotFuncAverage => '평균';

  @override
  String get pivotFuncMin => '최솟값';

  @override
  String get pivotFuncMax => '최댓값';

  @override
  String pivotCreated(String name) {
    return '\'\'$name\'\' 시트에 피벗 테이블이 생성됨';
  }

  @override
  String get pivotNoData => '피벗 테이블을 만들기 전에 데이터 범위를 선택하세요';

  @override
  String get presentationItalic => '기울임꼴';

  @override
  String get presentationUnderline => '밑줄';

  @override
  String get presentationStrikethrough => '취소선';

  @override
  String get presentationFontFamily => '글꼴';

  @override
  String get presentationFontSystem => '시스템';

  @override
  String get documentPageSetup => '페이지 설정';

  @override
  String get documentHeader => '머리글';

  @override
  String get documentFooter => '바닥글';

  @override
  String get documentHeaderHint => '머리글 텍스트 입력';

  @override
  String get documentFooterHint => '바닥글 텍스트 입력';

  @override
  String get documentPageSetupApplied => '페이지 설정이 적용됨';

  @override
  String get documentOutline => '개요';

  @override
  String get documentOutlineEmpty => '제목을 추가하면 개요가 표시됩니다';

  @override
  String get documentOutlineTitle => '문서 개요';

  @override
  String get presenterView => '발표자 보기';

  @override
  String get presenterElapsed => '경과 시간';

  @override
  String get presenterEndOfSlides => '프레젠테이션 종료';

  @override
  String get presenterNextSlide => '다음 슬라이드';

  @override
  String get documentInsertToc => '목차 삽입';

  @override
  String get documentTocInserted => '목차가 삽입되었습니다';

  @override
  String get documentTocTitle => '목차';

  @override
  String get documentTocEmpty => '제목이 없습니다. 먼저 제목을 추가하세요.';

  @override
  String get homeTemplates => '템플릿';

  @override
  String get templateGallery => '템플릿 갤러리';

  @override
  String get templateDocuments => '문서';

  @override
  String get templateSpreadsheets => '스프레드시트';

  @override
  String get templatePresentations => '프레젠테이션';

  @override
  String get templateLetter => '편지';

  @override
  String get templateReport => '보고서';

  @override
  String get templateResume => '이력서';

  @override
  String get templateBudget => '예산';

  @override
  String get templateSchedule => '일정';

  @override
  String get templateBlankDoc => '빈 문서';

  @override
  String get templateBlankSheet => '빈 스프레드시트';

  @override
  String get slideSorter => '슬라이드 정렬';

  @override
  String get slideSorterHint => '탭하여 편집, 길게 눌러 재정렬';

  @override
  String get autoSave => '자동 저장';

  @override
  String get autoSaveOn => '자동 저장 켜짐';

  @override
  String get autoSaveOff => '자동 저장 꺼짐';

  @override
  String autoSavedAt(String time) {
    return '$time에 자동 저장됨';
  }

  @override
  String get autoSaveNewFile => '자동 저장을 활성화하려면 먼저 저장하세요';

  @override
  String get autoSaving => '자동 저장 중...';

  @override
  String get autoSaveError => '자동 저장 실패';

  @override
  String get autoSaveDisabled => '자동 저장 비활성화';

  @override
  String get slideshowTapToAnimate => '탭하여 애니메이션 재생';

  @override
  String get slideshowAnimationsComplete => '모든 애니메이션 재생 완료';

  @override
  String get presentationBringToFront => '맨 앞으로';

  @override
  String get presentationSendToBack => '맨 뒤로';

  @override
  String get presentationBringForward => '앞으로';

  @override
  String get presentationSendBackward => '뒤로';

  @override
  String get presentationDuplicateElement => '요소 복제';

  @override
  String get presentationZOrder => '레이어 순서';

  @override
  String get keyboardShortcuts => '키보드 단축키';

  @override
  String get shortcutSave => '저장';

  @override
  String get shortcutFind => '찾기';

  @override
  String get shortcutDelete => '선택 삭제';

  @override
  String get shortcutDuplicate => '복제';

  @override
  String get shortcutNavigation => '셀 이동';

  @override
  String documentReadingTime(int count) {
    return '~$count분 읽기';
  }

  @override
  String savedAt(String time) {
    return '$time에 저장됨';
  }

  @override
  String lastSaved(String time) {
    return '마지막 저장: $time';
  }

  @override
  String get snackbarSlideDeleted => '슬라이드 삭제됨';

  @override
  String get snackbarElementDeleted => '요소 삭제됨';

  @override
  String get shortcutSectionCommon => '공통';

  @override
  String get shortcutSectionDocument => '문서';

  @override
  String get shortcutSectionPresentation => '프레젠테이션';

  @override
  String get shortcutSectionSpreadsheet => '스프레드시트';

  @override
  String get shortcutUndo => '실행 취소';

  @override
  String get shortcutRedo => '다시 실행';

  @override
  String get shortcutBold => '굵게';

  @override
  String get shortcutItalic => '기울임';

  @override
  String get shortcutUnderline => '밑줄';

  @override
  String get shortcutNextCell => '다음 셀';

  @override
  String get shortcutEditCell => '셀 편집';

  @override
  String get shortcutCopy => '복사';

  @override
  String get shortcutCut => '잘라내기';

  @override
  String get shortcutPaste => '붙여넣기';

  @override
  String get presentationEmptyTitle => '슬라이드가 없습니다';

  @override
  String get presentationEmptyHint => '슬라이드를 추가하여 프레젠테이션을 시작하세요';

  @override
  String get spreadsheetErrorTitle => '파일 로드 실패';

  @override
  String get spreadsheetErrorHint => '파일이 손상되었거나 지원하지 않는 형식입니다';

  @override
  String get commonRetry => '다시 시도';

  @override
  String get commonCreateNew => '새로 만들기';

  @override
  String a11yQuickAction(String label) {
    return '빠른 실행: $label';
  }

  @override
  String a11yRecentFile(String name) {
    return '최근 파일: $name';
  }

  @override
  String a11yDocumentStatus(int words, int chars, int pages) {
    return '단어 $words개, 문자 $chars자, $pages페이지';
  }

  @override
  String a11ySlideCount(int current, int total) {
    return '슬라이드 $current/$total';
  }

  @override
  String get a11yEditTitle => '제목 편집';

  @override
  String a11yColorSwatch(String color) {
    return '색상: $color';
  }

  @override
  String get homeTotalFiles => '총 파일';

  @override
  String get homeSeeAll => '모두 보기';

  @override
  String get homeStatsTab => '통계';

  @override
  String get homeSearchTab => '검색';

  @override
  String get homeProfileTab => '프로필';

  @override
  String get statsMonthlyActivity => '월별 활동';

  @override
  String get statsLive => '실시간';

  @override
  String get statsHoldings => '파일 현황';

  @override
  String get statsThisMonth => '이번 달';

  @override
  String get statsStorageUsed => '사용 중';

  @override
  String get statsStorageFree => '여유 공간';

  @override
  String get commandSearchPlaceholder => '파일, 명령어 검색...';

  @override
  String get commandRecentlyUsed => '최근 사용';

  @override
  String get commandFavorites => '즐겨찾기';

  @override
  String get commandAllFiles => '전체 파일';

  @override
  String get commandShortcutHint => '⌘K';

  @override
  String get profileStorageStatus => '저장소 현황';

  @override
  String get profileQuickSettings => '빠른 설정';

  @override
  String get profileActivityLog => '활동 기록';

  @override
  String get profileLanguage => '언어';

  @override
  String get profileExport => '내보내기';

  @override
  String get profileReset => '초기화';

  @override
  String get profileVersion => '버전';

  @override
  String get nowViewing => '현재 보는 중';

  @override
  String get noFilesYet => '아직 파일이 없습니다';

  @override
  String get tapToCreate => '탭하여 새 파일 만들기';

  @override
  String get homeTimeJustNow => '방금';

  @override
  String homeTimeMinutesAgo(int count) {
    return '$count분 전';
  }

  @override
  String homeTimeHoursAgo(int count) {
    return '$count시간 전';
  }

  @override
  String homeTimeDaysAgo(int count) {
    return '$count일 전';
  }

  @override
  String get selectLanguage => '언어 선택';

  @override
  String get languageKorean => '한국어';

  @override
  String get languageEnglish => 'English';

  @override
  String get profileResetConfirm => '최근 파일 기록이 모두 삭제됩니다. 계속하시겠습니까?';

  @override
  String get profileExportDesc => '최근 파일을 다른 앱으로 공유합니다';

  @override
  String get profileExportNoFiles => '내보낼 최근 파일이 없습니다';

  @override
  String get statsUpdated => '업데이트됨';

  @override
  String get documentUntitled => '제목 없는 문서';

  @override
  String get presentationUntitled => '제목 없는 프레젠테이션';

  @override
  String get spreadsheetUntitled => '새 스프레드시트';

  @override
  String get spreadsheetSaveDialog => '스프레드시트 저장';

  @override
  String get formulaError => '!오류';

  @override
  String get statsSum => '합계';

  @override
  String get statsAverage => '평균';

  @override
  String get statsCount => '개수';

  @override
  String get sheetCopySuffix => '사본';

  @override
  String sheetCopySuffixN(int cnt) {
    return '사본 $cnt';
  }

  @override
  String get slideTitleSlide => '제목 슬라이드';

  @override
  String get slidePresentationTitle => '프레젠테이션 제목';

  @override
  String get slideSubtitleHint => '부제목을 입력하세요';

  @override
  String get slideSubtitle => '부제목';

  @override
  String slideNumbered(int number) {
    return '슬라이드 $number';
  }

  @override
  String get slideTitleHint => '제목을 입력하세요';

  @override
  String get slideTitleBody => '제목 + 본문';

  @override
  String get slideBodyHint => '본문 내용을 입력하세요';

  @override
  String get slideTwoColumn => '2단 비교';

  @override
  String get slideComparisonTitle => '비교 제목';

  @override
  String get slideLeftContent => '왼쪽 내용';

  @override
  String get slideRightContent => '오른쪽 내용';

  @override
  String get slideSectionBreak => '섹션 구분';

  @override
  String get slideSectionTitle => '섹션 제목';

  @override
  String errorFileNotFound(String path) {
    return '파일을 찾을 수 없습니다: $path';
  }

  @override
  String get spreadsheetBudget => 'Budget';

  @override
  String get spreadsheetSchedule => 'Schedule';

  @override
  String get settingsAppearance => '외관';

  @override
  String get settingsFiles => '파일';

  @override
  String get settingsData => '데이터';

  @override
  String get settingsAbout => '정보';

  @override
  String get settingsTheme => '테마';

  @override
  String get settingsThemeSubtitle => '라이트, 다크 또는 시스템';

  @override
  String get settingsThemeSystem => '시스템';

  @override
  String get settingsThemeLight => '라이트';

  @override
  String get settingsThemeDark => '다크';

  @override
  String get settingsLanguageSubtitle => '앱 표시 언어';

  @override
  String get settingsAutoSaveSubtitle => '파일을 자동으로 저장';

  @override
  String get settingsKeyboardSubtitle => '모든 단축키 보기';

  @override
  String get settingsExportSubtitle => '최근 파일 공유';

  @override
  String get settingsResetSubtitle => '최근 파일 기록 삭제';

  @override
  String get settingsVersionSubtitle => '현재 앱 버전';

  @override
  String get settingsLicenses => '오픈소스 라이선스';

  @override
  String get settingsLicensesSubtitle => '서드파티 라이브러리';

  @override
  String get commonRestore => '되돌리기';

  @override
  String get commonTryAgain => '다시 시도';

  @override
  String get commonDismiss => '닫기';

  @override
  String fileDeletedWithUndo(String name) {
    return '\'$name\' 삭제됨';
  }

  @override
  String fileDeletedRestored(String name) {
    return '\'$name\' 복원됨';
  }

  @override
  String get saveCelebration => '깔끔하게 저장됐어요';

  @override
  String get saveCelebrationFirst => '첫 저장 완료 · Excelia에서 여정이 시작됐어요';

  @override
  String get emptyStateOpenFile => '파일 열기';

  @override
  String get emptyStateTrySample => '샘플 열어보기';

  @override
  String get sampleBudgetName => '가계부 샘플';

  @override
  String get sampleMeetingName => '회의노트 샘플';

  @override
  String get sampleTodoName => '오늘 할 일';

  @override
  String get sampleCreated => '샘플 파일을 만들었어요. 바로 탭해보세요.';

  @override
  String get savedJustNow => '방금 저장됨';

  @override
  String savedSecondsAgo(int seconds) {
    return '$seconds초 전 저장됨';
  }

  @override
  String a11ySheetTab(String name, int index) {
    return '$name 시트, $index번째';
  }

  @override
  String get a11yAddSheet => '시트 추가';
}
