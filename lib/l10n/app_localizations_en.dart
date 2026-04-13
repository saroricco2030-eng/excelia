// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Excelia';

  @override
  String get appSubtitle => 'Mobile Office';

  @override
  String get appVersion => 'Version 1.0.0';

  @override
  String get commonSave => 'Save';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonClear => 'Clear';

  @override
  String get commonClose => 'Close';

  @override
  String get commonOpen => 'Open';

  @override
  String get commonShare => 'Share';

  @override
  String get commonContinue => 'Continue';

  @override
  String get commonAdd => 'Add';

  @override
  String get commonMove => 'Go';

  @override
  String get commonReset => 'Reset';

  @override
  String get commonSettings => 'Settings';

  @override
  String get commonLoading => 'Loading...';

  @override
  String get commonBack => 'Back';

  @override
  String get commonUndo => 'Undo';

  @override
  String get commonRedo => 'Redo';

  @override
  String get commonMore => 'More';

  @override
  String get commonSaving => 'Saving...';

  @override
  String get commonSaved => 'Saved';

  @override
  String get commonUnsavedChanges => 'Unsaved changes';

  @override
  String get commonSaveAs => 'Save As';

  @override
  String get commonDoNotSave => 'Don\'t Save';

  @override
  String get commonOn => 'On';

  @override
  String get commonOff => 'Off';

  @override
  String get homeTitle => 'Home';

  @override
  String get homeFiles => 'Files';

  @override
  String get homeFavorites => 'Favorites';

  @override
  String get homeCreateNew => 'Create New';

  @override
  String get homeRecentFiles => 'Recent Files';

  @override
  String get homeClearAll => 'Clear All';

  @override
  String get homeNoRecentFiles => 'No recent files';

  @override
  String get homeNoRecentFilesHint => 'Create a new document or open a file';

  @override
  String get homeClearRecentTitle => 'Clear Recent Files';

  @override
  String get homeClearRecentMessage => 'Clear all recent file history?';

  @override
  String get homeNoFiles => 'No files';

  @override
  String get homeOpenFileHint => 'Try opening a file';

  @override
  String get homeFavoritesEmpty => 'No favorites yet';

  @override
  String get homeFavoritesHint => 'Add frequently used files to favorites';

  @override
  String get homeSearchFiles => 'Search files...';

  @override
  String get homeSearchTitle => 'Search Files';

  @override
  String get homeSearchHint => 'Search by file name';

  @override
  String get homeNoSearchResults => 'No results found';

  @override
  String get homeGeneral => 'General';

  @override
  String get homeDarkMode => 'Dark Mode';

  @override
  String get homeData => 'Data';

  @override
  String get homeRecentFileHistory => 'Recent File History';

  @override
  String get homeInfo => 'About';

  @override
  String get homeSupportedFormats => 'Supported Formats';

  @override
  String get homeSupportedFormatsDetail => 'xlsx, xls, docx, pptx, pdf';

  @override
  String get homeAll => 'All';

  @override
  String get fileOpen => 'Open File';

  @override
  String fileOpenError(String error) {
    return 'Failed to open file: $error';
  }

  @override
  String get fileNotFound => 'File not found';

  @override
  String fileNotFoundName(String name) {
    return 'File not found: $name';
  }

  @override
  String get filePermissionRequired =>
      'Storage permission is required to access files.';

  @override
  String get filePathError => 'Unable to get file path. Please try again.';

  @override
  String get fileReadError =>
      'Cannot read file. The file may be deleted or access denied.';

  @override
  String get fileUnsupportedFormat => 'Unsupported file format.';

  @override
  String fileShareError(String error) {
    return 'Share failed: $error';
  }

  @override
  String get fileDeleteTitle => 'Delete File';

  @override
  String fileDeleteConfirm(String name) {
    return 'Remove \"$name\" from recent files?';
  }

  @override
  String fileCount(int count) {
    return '$count files';
  }

  @override
  String fileLabelCount(String label, int count) {
    return '$label ($count)';
  }

  @override
  String fileLabelFileCount(String label, int count) {
    return '$label: $count files';
  }

  @override
  String get fileLoading => 'Loading file...';

  @override
  String get fileSaved => 'Saved';

  @override
  String get fileLoadRecentError => 'Failed to load recent files';

  @override
  String get typeSpreadsheet => 'Spreadsheet';

  @override
  String get typeDocument => 'Document';

  @override
  String get typePresentation => 'Presentation';

  @override
  String get typePdf => 'PDF';

  @override
  String get newSpreadsheet => 'New Spreadsheet';

  @override
  String get newDocument => 'New Document';

  @override
  String get newPresentation => 'New Presentation';

  @override
  String get pdfOpen => 'Open PDF';

  @override
  String get subtitleExcelCompat => 'Excel compatible';

  @override
  String get subtitleWordCompat => 'Word compatible';

  @override
  String get subtitlePptCompat => 'PPT compatible';

  @override
  String get subtitlePdfViewer => 'PDF Viewer';

  @override
  String get spreadsheetOpenError =>
      'Cannot open spreadsheet. The file may be corrupted or unsupported.';

  @override
  String get spreadsheetSaveChanges => 'Save changes?';

  @override
  String get spreadsheetInsertRow => 'Insert Row';

  @override
  String get spreadsheetDeleteRow => 'Delete Row';

  @override
  String get spreadsheetInsertCol => 'Insert Column';

  @override
  String get spreadsheetDeleteCol => 'Delete Column';

  @override
  String get spreadsheetSortAsc => 'Sort Ascending';

  @override
  String get spreadsheetSortDesc => 'Sort Descending';

  @override
  String get spreadsheetPrintPreview => 'Print Preview';

  @override
  String get spreadsheetPrint => 'Print';

  @override
  String get spreadsheetNoData => 'No data';

  @override
  String spreadsheetPrintPreviewTitle(String name) {
    return 'Print Preview - $name';
  }

  @override
  String spreadsheetZoomPercent(int percent) {
    return '$percent%';
  }

  @override
  String get sheetNew => 'New Sheet';

  @override
  String get sheetName => 'Sheet Name';

  @override
  String get sheetNameHint => 'Enter sheet name';

  @override
  String get sheetRename => 'Rename';

  @override
  String get sheetDuplicate => 'Duplicate';

  @override
  String get sheetDeleteTitle => 'Delete Sheet';

  @override
  String sheetDeleteConfirm(String name) {
    return 'Delete sheet \'$name\'?';
  }

  @override
  String documentOpenError(String error) {
    return 'Failed to open document: $error';
  }

  @override
  String get documentExportPdf => 'Export as PDF';

  @override
  String get documentPrintPreview => 'Print Preview';

  @override
  String get documentPrint => 'Print';

  @override
  String get documentPlaceholder => 'Type here...';

  @override
  String documentWordCount(int count) {
    return '$count words';
  }

  @override
  String documentCharCount(int count) {
    return '$count characters';
  }

  @override
  String documentPageEstimate(int count) {
    return '~$count pages';
  }

  @override
  String get documentSaveTitle => 'Save Document';

  @override
  String get documentSaved => 'Document saved';

  @override
  String documentSaveError(String error) {
    return 'Save failed: $error';
  }

  @override
  String documentExportDone(String path) {
    return 'PDF exported: $path';
  }

  @override
  String documentExportError(String error) {
    return 'PDF export failed: $error';
  }

  @override
  String documentPrintPreviewTitle(String name) {
    return 'Print Preview - $name';
  }

  @override
  String documentPreviewError(String error) {
    return 'Preview failed: $error';
  }

  @override
  String documentPrintError(String error) {
    return 'Print failed: $error';
  }

  @override
  String get documentOpenFile => 'Open Document';

  @override
  String get documentNew => 'New Document';

  @override
  String get documentNewConfirm => 'You have unsaved changes. Continue?';

  @override
  String get documentInsertDivider => 'Insert Divider';

  @override
  String get documentInsertImage => 'Insert Image';

  @override
  String get documentSelectImage => 'Select Image';

  @override
  String get documentClose => 'Close Document';

  @override
  String get documentUnsavedChanges => 'You have unsaved changes.';

  @override
  String presentationOpenError(String error) {
    return 'Failed to open presentation: $error';
  }

  @override
  String get presentationSlideshow => 'Slideshow';

  @override
  String get presentationSlideList => 'Slide List';

  @override
  String get presentationProperties => 'Properties Panel';

  @override
  String get presentationGridSnap => 'Grid Snap';

  @override
  String get presentationSlidePanel => 'Slide Panel';

  @override
  String get presentationPrintPreview => 'Print Preview';

  @override
  String get presentationPrint => 'Print';

  @override
  String get presentationAddSlide => 'Add Slide';

  @override
  String get presentationNoSlides => 'No slides';

  @override
  String get presentationElementProps => 'Element Properties';

  @override
  String get presentationDeleteElement => 'Delete Element';

  @override
  String get presentationRectangle => 'Rectangle';

  @override
  String get presentationCircle => 'Circle';

  @override
  String get presentationTriangle => 'Triangle';

  @override
  String get presentationArrow => 'Arrow';

  @override
  String get presentationBgColor => 'Slide Background Color';

  @override
  String get presentationSaved => 'Presentation saved';

  @override
  String presentationSaveError(String error) {
    return 'Save failed: $error';
  }

  @override
  String presentationPrintPreviewTitle(String name) {
    return 'Print Preview - $name';
  }

  @override
  String get presentationDuplicate => 'Duplicate Slide';

  @override
  String get presentationDeleteSlide => 'Delete Slide';

  @override
  String get presentationMoveUp => 'Move Up';

  @override
  String get presentationMoveDown => 'Move Down';

  @override
  String get presentationImagePlaceholder => '[Image]';

  @override
  String get presentationSelectElement =>
      'Select an element\nto edit its properties';

  @override
  String get presentationPosition => 'Position';

  @override
  String get presentationSize => 'Size';

  @override
  String get presentationFontSize => 'Font Size';

  @override
  String get presentationBold => 'Bold';

  @override
  String get presentationAlignment => 'Alignment';

  @override
  String get presentationTextColor => 'Text Color';

  @override
  String get presentationBackgroundColor => 'Background Color';

  @override
  String get presentationText => 'Text';

  @override
  String get presentationDefaultText => 'Enter text here';

  @override
  String get presentationInsertShape => 'Insert Shape';

  @override
  String get presentationShape => 'Shape';

  @override
  String get presentationImage => 'Image';

  @override
  String get presentationBgColorShort => 'Background';

  @override
  String get presentationSaveTitle => 'Save Presentation';

  @override
  String get presentationOpenTitle => 'Open Presentation';

  @override
  String get pdfViewer => 'PDF Viewer';

  @override
  String get pdfFileNotFound => 'File not found';

  @override
  String get pdfOpenFile => 'Open PDF File';

  @override
  String get pdfThumbnail => 'Thumbnails';

  @override
  String get pdfDayMode => 'Day Mode';

  @override
  String get pdfNightMode => 'Night Mode';

  @override
  String get pdfOpenPrompt => 'Please open a PDF file';

  @override
  String get pdfOpenHint => 'Select a file to view PDF documents';

  @override
  String get pdfCannotOpen => 'Cannot open PDF';

  @override
  String get pdfOpenAnother => 'Open Another File';

  @override
  String get pdfPageList => 'Pages';

  @override
  String get pdfPrevPage => 'Previous Page';

  @override
  String get pdfNextPage => 'Next Page';

  @override
  String get pdfFirstPage => 'First Page';

  @override
  String get pdfLastPage => 'Last Page';

  @override
  String get pdfJumpToPage => 'Go to Page';

  @override
  String pdfPageNumber(int total) {
    return 'Page number (1 ~ $total)';
  }

  @override
  String get pdfPrint => 'Print';

  @override
  String get toolbarClose => 'Close';

  @override
  String get toolbarBold => 'Bold';

  @override
  String get toolbarItalic => 'Italic';

  @override
  String get toolbarUnderline => 'Underline';

  @override
  String get toolbarTextColor => 'Text Color';

  @override
  String get toolbarBgColor => 'Background Color';

  @override
  String get toolbarAlignLeft => 'Align Left';

  @override
  String get toolbarAlignCenter => 'Align Center';

  @override
  String get toolbarAlignRight => 'Align Right';

  @override
  String get toolbarWrapText => 'Wrap Text';

  @override
  String get toolbarFormatTools => 'Format Tools';

  @override
  String get numberFormatGeneral => 'General';

  @override
  String get numberFormatNumber => 'Number';

  @override
  String get numberFormatCurrency => 'Currency';

  @override
  String get numberFormatPercent => 'Percent';

  @override
  String get numberFormatDate => 'Date';

  @override
  String get pageSetupTitle => 'Page Setup';

  @override
  String get paperSize => 'Paper Size';

  @override
  String get paperSizeA4 => 'A4';

  @override
  String get paperSizeA5 => 'A5';

  @override
  String get paperSizeLetter => 'Letter';

  @override
  String get paperSizeLegal => 'Legal';

  @override
  String get orientationLabel => 'Orientation';

  @override
  String get orientationLandscape => 'Landscape';

  @override
  String get orientationPortrait => 'Portrait';

  @override
  String get marginsLabel => 'Margins';

  @override
  String get marginNormal => 'Normal';

  @override
  String get marginNarrow => 'Narrow';

  @override
  String get marginWide => 'Wide';

  @override
  String get scaleLabel => 'Scale';

  @override
  String get scaleFitWidth => 'Fit to Width';

  @override
  String get scaleFitPage => 'Fit to Page';

  @override
  String get scaleActual => 'Actual Size';

  @override
  String get showGridlines => 'Show Gridlines';

  @override
  String get showFileName => 'Show File Name';

  @override
  String get showPageNumbers => 'Show Page Numbers';

  @override
  String get pageSetupApply => 'Apply';

  @override
  String get contextCut => 'Cut';

  @override
  String get contextCopy => 'Copy';

  @override
  String get contextPaste => 'Paste';

  @override
  String get contextInsertRow => 'Insert Row';

  @override
  String get contextInsertCol => 'Insert Column';

  @override
  String get contextDeleteRow => 'Delete Row';

  @override
  String get contextDeleteCol => 'Delete Column';

  @override
  String get contextClearContent => 'Clear Content';

  @override
  String get mergeCells => 'Merge Cells';

  @override
  String get unmergeCells => 'Unmerge Cells';

  @override
  String get fontSize => 'Font Size';

  @override
  String get findTitle => 'Find';

  @override
  String get findHint => 'Search...';

  @override
  String get replaceHint => 'Replace with...';

  @override
  String get replaceOne => 'Replace';

  @override
  String get replaceAllBtn => 'Replace All';

  @override
  String findMatchCount(int current, int total) {
    return '$current/$total';
  }

  @override
  String get findNoMatch => 'No results';

  @override
  String get freezePanes => 'Freeze Panes';

  @override
  String get unfreezePanes => 'Unfreeze Panes';

  @override
  String get borderAll => 'All Borders';

  @override
  String get borderOutside => 'Outside Borders';

  @override
  String get borderBottom => 'Bottom Border';

  @override
  String get borderNone => 'No Border';

  @override
  String get formatPainter => 'Format Painter';

  @override
  String get hideRow => 'Hide Row';

  @override
  String get hideCol => 'Hide Column';

  @override
  String get unhideAll => 'Unhide All';

  @override
  String get addComment => 'Add Comment';

  @override
  String get editComment => 'Edit Comment';

  @override
  String get deleteComment => 'Delete Comment';

  @override
  String get commentHint => 'Enter comment...';

  @override
  String get autoFilter => 'Auto Filter';

  @override
  String get clearAutoFilter => 'Clear Filter';

  @override
  String get filterValues => 'Filter Values';

  @override
  String get filterSelectAll => 'Select All';

  @override
  String get filterClearAll => 'Clear All';

  @override
  String get conditionalFormat => 'Conditional Formatting';

  @override
  String get conditionType => 'Condition Type';

  @override
  String get condGreaterThan => 'Greater Than';

  @override
  String get condLessThan => 'Less Than';

  @override
  String get condEqualTo => 'Equal To';

  @override
  String get condBetween => 'Between';

  @override
  String get condTextContains => 'Text Contains';

  @override
  String get condIsEmpty => 'Is Empty';

  @override
  String get condIsNotEmpty => 'Is Not Empty';

  @override
  String get condValue => 'Value';

  @override
  String get condValue2 => 'Value 2';

  @override
  String get condFormatStyle => 'Format Style';

  @override
  String get condApply => 'Apply';

  @override
  String get condClearAll => 'Clear All Rules';

  @override
  String get insertChart => 'Insert Chart';

  @override
  String get chartType => 'Chart Type';

  @override
  String get chartBar => 'Bar Chart';

  @override
  String get chartLine => 'Line Chart';

  @override
  String get chartPie => 'Pie Chart';

  @override
  String get chartTitle => 'Chart Title';

  @override
  String get chartDefaultTitle => 'Chart';

  @override
  String get chartCreate => 'Create';

  @override
  String get chartDataHint =>
      'Select cells with data before inserting a chart. First column = labels, second column = values.';

  @override
  String get chartScatter => 'Scatter Chart';

  @override
  String get chartArea => 'Area Chart';

  @override
  String get chartStackedBar => 'Stacked Bar';

  @override
  String get chartDoughnut => 'Doughnut Chart';

  @override
  String get chartRadar => 'Radar Chart';

  @override
  String get chartCombo => 'Combo Chart';

  @override
  String get chartAxisX => 'X Axis Title';

  @override
  String get chartAxisY => 'Y Axis Title';

  @override
  String get chartGridlines => 'Gridlines';

  @override
  String get chartLegend => 'Legend Position';

  @override
  String get chartLegendNone => 'None';

  @override
  String get chartLegendTop => 'Top';

  @override
  String get chartLegendBottom => 'Bottom';

  @override
  String get chartLegendLeft => 'Left';

  @override
  String get chartLegendRight => 'Right';

  @override
  String get chartCustomize => 'Customize Chart';

  @override
  String get dataValidation => 'Data Validation';

  @override
  String get dataValidationType => 'Validation Type';

  @override
  String get dataValidationTypeList => 'List';

  @override
  String get dataValidationTypeWholeNumber => 'Whole Number';

  @override
  String get dataValidationTypeDecimal => 'Decimal';

  @override
  String get dataValidationTypeDate => 'Date';

  @override
  String get dataValidationTypeTextLength => 'Text Length';

  @override
  String get dataValidationTypeCustom => 'Custom';

  @override
  String get dataValidationOperator => 'Operator';

  @override
  String get dataValidationOpBetween => 'Between';

  @override
  String get dataValidationOpNotBetween => 'Not Between';

  @override
  String get dataValidationOpEqualTo => 'Equal To';

  @override
  String get dataValidationOpNotEqualTo => 'Not Equal To';

  @override
  String get dataValidationOpGreaterThan => 'Greater Than';

  @override
  String get dataValidationOpLessThan => 'Less Than';

  @override
  String get dataValidationOpGreaterOrEqual => 'Greater or Equal';

  @override
  String get dataValidationOpLessOrEqual => 'Less or Equal';

  @override
  String get dataValidationListItems => 'List Items';

  @override
  String get dataValidationListHint => 'Enter items separated by commas';

  @override
  String get dataValidationValue1 => 'Value 1';

  @override
  String get dataValidationValue2 => 'Value 2';

  @override
  String get dataValidationShowError => 'Show error on invalid input';

  @override
  String get dataValidationFailed => 'Input does not match validation rule';

  @override
  String get nameManager => 'Name Manager';

  @override
  String get namedRangeName => 'Name';

  @override
  String get namedRangeRef => 'Range (e.g. A1:B5)';

  @override
  String get namedRangeEmpty => 'No named ranges defined';

  @override
  String get spreadsheetExportCsv => 'Export as CSV';

  @override
  String get documentOpenDocx => 'Open DOCX';

  @override
  String get documentSaveDocx => 'Save as DOCX';

  @override
  String get documentExportDocx => 'Export as DOCX';

  @override
  String get pptxOpen => 'Open PPTX';

  @override
  String get pptxSave => 'Save as PPTX';

  @override
  String get pptxExport => 'Export as PPTX';

  @override
  String get slideTransition => 'Slide Transition';

  @override
  String get transitionNone => 'None';

  @override
  String get transitionFade => 'Fade';

  @override
  String get transitionPush => 'Push';

  @override
  String get transitionWipe => 'Wipe';

  @override
  String get transitionZoom => 'Zoom';

  @override
  String get transitionDuration => 'Duration (ms)';

  @override
  String get speakerNotes => 'Speaker Notes';

  @override
  String get speakerNotesHint => 'Enter speaker notes...';

  @override
  String get slideTemplate => 'Slide Template';

  @override
  String get templateTitle => 'Title Slide';

  @override
  String get templateTitleBody => 'Title + Body';

  @override
  String get templateTwoColumn => 'Two Columns';

  @override
  String get templateBlank => 'Blank';

  @override
  String get templateSection => 'Section Divider';

  @override
  String get templateImageText => 'Image + Text';

  @override
  String get elementAnimation => 'Element Animation';

  @override
  String get animationFadeIn => 'Fade In';

  @override
  String get animationFlyInLeft => 'Fly In Left';

  @override
  String get animationFlyInRight => 'Fly In Right';

  @override
  String get animationFlyInBottom => 'Fly In Bottom';

  @override
  String get animationZoomIn => 'Zoom In';

  @override
  String get animationTriggerClick => 'On Click';

  @override
  String get animationTriggerWith => 'With Previous';

  @override
  String get animationTriggerAfter => 'After Previous';

  @override
  String get hyperlinkInsert => 'Insert Hyperlink';

  @override
  String get hyperlinkUrl => 'URL';

  @override
  String get hyperlinkRemove => 'Remove Hyperlink';

  @override
  String get documentDocxLoaded => 'DOCX file loaded';

  @override
  String documentDocxSaved(String path) {
    return 'Saved as DOCX: $path';
  }

  @override
  String documentDocxError(String error) {
    return 'DOCX error: $error';
  }

  @override
  String get presentationPptxLoaded => 'PPTX file loaded';

  @override
  String presentationPptxSaved(String path) {
    return 'Saved as PPTX: $path';
  }

  @override
  String presentationPptxError(String error) {
    return 'PPTX error: $error';
  }

  @override
  String get pdfSearch => 'Search';

  @override
  String get pdfSearchHint => 'Search in document...';

  @override
  String get pdfBookmark => 'Bookmarks';

  @override
  String get pdfNoBookmarks => 'No bookmarks';

  @override
  String get pdfAnnotation => 'Annotations';

  @override
  String get pdfAnnotationHighlight => 'Highlight';

  @override
  String get pdfAnnotationUnderline => 'Underline';

  @override
  String get pdfAnnotationStrikethrough => 'Strikethrough';

  @override
  String get pdfAnnotationOff => 'Turn Off';

  @override
  String get pdfAnnotationColor => 'Color';

  @override
  String get pdfAnnotationMode => 'Annotation Mode';

  @override
  String pdfAnnotationActive(String mode) {
    return 'Active: $mode';
  }

  @override
  String get documentInsertTable => 'Insert Table';

  @override
  String get documentTableRows => 'Rows';

  @override
  String get documentTableCols => 'Columns';

  @override
  String get documentTableInsertTitle => 'Insert Table';

  @override
  String get documentTableEditCell => 'Edit Cell';

  @override
  String get documentTableAddRow => 'Add Row';

  @override
  String get documentTableAddCol => 'Add Column';

  @override
  String get documentTableDeleteRow => 'Delete Row';

  @override
  String get documentTableEditHeader => 'Edit Header';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get documentImageLoaded => 'Image loaded from DOCX';

  @override
  String documentImageError(String error) {
    return 'Failed to load image: $error';
  }

  @override
  String get pivotTable => 'Pivot Table';

  @override
  String get pivotTableCreate => 'Create Pivot Table';

  @override
  String get pivotDataRange => 'Data Range';

  @override
  String get pivotRowField => 'Row Field';

  @override
  String get pivotColField => 'Column Field (optional)';

  @override
  String get pivotValueField => 'Value Field';

  @override
  String get pivotAggregateFunc => 'Aggregate Function';

  @override
  String get pivotFuncSum => 'SUM';

  @override
  String get pivotFuncCount => 'COUNT';

  @override
  String get pivotFuncAverage => 'AVERAGE';

  @override
  String get pivotFuncMin => 'MIN';

  @override
  String get pivotFuncMax => 'MAX';

  @override
  String pivotCreated(String name) {
    return 'Pivot table created in \'\'$name\'\'';
  }

  @override
  String get pivotNoData => 'Select data range before creating pivot table';

  @override
  String get presentationItalic => 'Italic';

  @override
  String get presentationUnderline => 'Underline';

  @override
  String get presentationStrikethrough => 'Strikethrough';

  @override
  String get presentationFontFamily => 'Font';

  @override
  String get documentPageSetup => 'Page Setup';

  @override
  String get documentHeader => 'Header';

  @override
  String get documentFooter => 'Footer';

  @override
  String get documentHeaderHint => 'Enter header text';

  @override
  String get documentFooterHint => 'Enter footer text';

  @override
  String get documentPageSetupApplied => 'Page setup applied';

  @override
  String get documentOutline => 'Outline';

  @override
  String get documentOutlineEmpty => 'Add headings to see the outline';

  @override
  String get documentOutlineTitle => 'Document Outline';

  @override
  String get presenterView => 'Presenter View';

  @override
  String get presenterElapsed => 'Elapsed';

  @override
  String get presenterEndOfSlides => 'End of presentation';

  @override
  String get presenterNextSlide => 'Next Slide';

  @override
  String get documentInsertToc => 'Insert Table of Contents';

  @override
  String get documentTocInserted => 'Table of contents inserted';

  @override
  String get documentTocTitle => 'Table of Contents';

  @override
  String get documentTocEmpty => 'No headings found. Add headings first.';

  @override
  String get homeTemplates => 'Templates';

  @override
  String get templateGallery => 'Template Gallery';

  @override
  String get templateDocuments => 'Documents';

  @override
  String get templateSpreadsheets => 'Spreadsheets';

  @override
  String get templatePresentations => 'Presentations';

  @override
  String get templateLetter => 'Letter';

  @override
  String get templateReport => 'Report';

  @override
  String get templateResume => 'Resume';

  @override
  String get templateBudget => 'Budget';

  @override
  String get templateSchedule => 'Schedule';

  @override
  String get templateBlankDoc => 'Blank Document';

  @override
  String get templateBlankSheet => 'Blank Spreadsheet';

  @override
  String get slideSorter => 'Slide Sorter';

  @override
  String get slideSorterHint => 'Tap to edit, long-press to reorder';

  @override
  String get autoSave => 'Auto-save';

  @override
  String get autoSaveOn => 'Auto-save is on';

  @override
  String get autoSaveOff => 'Auto-save is off';

  @override
  String autoSavedAt(String time) {
    return 'Auto-saved at $time';
  }

  @override
  String get autoSaveNewFile => 'Save once to enable auto-save';

  @override
  String get autoSaving => 'Auto-saving...';

  @override
  String get autoSaveError => 'Auto-save failed';

  @override
  String get autoSaveDisabled => 'Auto-save disabled';

  @override
  String get slideshowTapToAnimate => 'Tap to play animation';

  @override
  String get slideshowAnimationsComplete => 'All animations played';

  @override
  String get presentationBringToFront => 'Bring to Front';

  @override
  String get presentationSendToBack => 'Send to Back';

  @override
  String get presentationBringForward => 'Bring Forward';

  @override
  String get presentationSendBackward => 'Send Backward';

  @override
  String get presentationDuplicateElement => 'Duplicate Element';

  @override
  String get presentationZOrder => 'Layer Order';

  @override
  String get keyboardShortcuts => 'Keyboard Shortcuts';

  @override
  String get shortcutSave => 'Save';

  @override
  String get shortcutFind => 'Find';

  @override
  String get shortcutDelete => 'Delete selected';

  @override
  String get shortcutDuplicate => 'Duplicate';

  @override
  String get shortcutNavigation => 'Navigate cells';

  @override
  String documentReadingTime(int count) {
    return '~$count min read';
  }

  @override
  String savedAt(String time) {
    return 'Saved at $time';
  }

  @override
  String lastSaved(String time) {
    return 'Last saved: $time';
  }

  @override
  String get snackbarSlideDeleted => 'Slide deleted';

  @override
  String get snackbarElementDeleted => 'Element deleted';

  @override
  String get shortcutSectionCommon => 'Common';

  @override
  String get shortcutSectionDocument => 'Document';

  @override
  String get shortcutSectionPresentation => 'Presentation';

  @override
  String get shortcutSectionSpreadsheet => 'Spreadsheet';

  @override
  String get shortcutUndo => 'Undo';

  @override
  String get shortcutRedo => 'Redo';

  @override
  String get shortcutBold => 'Bold';

  @override
  String get shortcutItalic => 'Italic';

  @override
  String get shortcutUnderline => 'Underline';

  @override
  String get shortcutNextCell => 'Next cell';

  @override
  String get shortcutEditCell => 'Edit cell';

  @override
  String get shortcutCopy => 'Copy';

  @override
  String get shortcutCut => 'Cut';

  @override
  String get shortcutPaste => 'Paste';

  @override
  String get presentationEmptyTitle => 'No slides yet';

  @override
  String get presentationEmptyHint => 'Add a slide to start your presentation';

  @override
  String get spreadsheetErrorTitle => 'Failed to load file';

  @override
  String get spreadsheetErrorHint =>
      'The file may be corrupted or in an unsupported format';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonCreateNew => 'Create New';

  @override
  String a11yQuickAction(String label) {
    return 'Quick action: $label';
  }

  @override
  String a11yRecentFile(String name) {
    return 'Recent file: $name';
  }

  @override
  String a11yDocumentStatus(int words, int chars, int pages) {
    return '$words words, $chars characters, $pages pages';
  }

  @override
  String a11ySlideCount(int current, int total) {
    return 'Slide $current of $total';
  }

  @override
  String get a11yEditTitle => 'Edit title';

  @override
  String a11yColorSwatch(String color) {
    return 'Color: $color';
  }

  @override
  String get homeTotalFiles => 'Total Files';

  @override
  String get homeSeeAll => 'See All';

  @override
  String get homeStatsTab => 'Stats';

  @override
  String get homeSearchTab => 'Search';

  @override
  String get homeProfileTab => 'Profile';

  @override
  String get statsMonthlyActivity => 'Monthly Activity';

  @override
  String get statsLive => 'Live';

  @override
  String get statsHoldings => 'File Holdings';

  @override
  String get statsThisMonth => 'This Month';

  @override
  String get statsStorageUsed => 'Used';

  @override
  String get statsStorageFree => 'Free';

  @override
  String get commandSearchPlaceholder => 'Search files, commands...';

  @override
  String get commandRecentlyUsed => 'Recently Used';

  @override
  String get commandFavorites => 'Favorites';

  @override
  String get commandAllFiles => 'All Files';

  @override
  String get commandShortcutHint => '⌘K';

  @override
  String get profileStorageStatus => 'Storage Status';

  @override
  String get profileQuickSettings => 'Quick Settings';

  @override
  String get profileActivityLog => 'Activity Log';

  @override
  String get profileLanguage => 'Language';

  @override
  String get profileExport => 'Export';

  @override
  String get profileReset => 'Reset';

  @override
  String get profileVersion => 'Version';

  @override
  String get nowViewing => 'Now Viewing';

  @override
  String get noFilesYet => 'No files yet';

  @override
  String get tapToCreate => 'Tap to create a new file';

  @override
  String get homeTimeJustNow => 'Just now';

  @override
  String homeTimeMinutesAgo(int count) {
    return '${count}m ago';
  }

  @override
  String homeTimeHoursAgo(int count) {
    return '${count}h ago';
  }

  @override
  String homeTimeDaysAgo(int count) {
    return '${count}d ago';
  }

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get languageKorean => 'Korean';

  @override
  String get languageEnglish => 'English';

  @override
  String get profileResetConfirm =>
      'This will clear all recent file history. Continue?';

  @override
  String get profileExportDesc => 'Share your recent files with other apps';

  @override
  String get profileExportNoFiles => 'No recent files to export';

  @override
  String get statsUpdated => 'Updated';

  @override
  String get documentUntitled => 'Untitled Document';

  @override
  String get presentationUntitled => 'Untitled Presentation';

  @override
  String get spreadsheetUntitled => 'New Spreadsheet';

  @override
  String get spreadsheetSaveDialog => 'Save Spreadsheet';

  @override
  String get formulaError => '!ERROR';

  @override
  String get statsSum => 'Sum';

  @override
  String get statsAverage => 'Average';

  @override
  String get statsCount => 'Count';

  @override
  String get sheetCopySuffix => 'Copy';

  @override
  String sheetCopySuffixN(int cnt) {
    return 'Copy $cnt';
  }

  @override
  String get slideTitleSlide => 'Title Slide';

  @override
  String get slidePresentationTitle => 'Presentation Title';

  @override
  String get slideSubtitleHint => 'Enter subtitle';

  @override
  String get slideSubtitle => 'Subtitle';

  @override
  String slideNumbered(int number) {
    return 'Slide $number';
  }

  @override
  String get slideTitleHint => 'Enter title';

  @override
  String get slideTitleBody => 'Title + Body';

  @override
  String get slideBodyHint => 'Enter body text';

  @override
  String get slideTwoColumn => 'Two Column';

  @override
  String get slideComparisonTitle => 'Comparison Title';

  @override
  String get slideLeftContent => 'Left Content';

  @override
  String get slideRightContent => 'Right Content';

  @override
  String get slideSectionBreak => 'Section Break';

  @override
  String get slideSectionTitle => 'Section Title';

  @override
  String errorFileNotFound(String path) {
    return 'File not found: $path';
  }

  @override
  String get spreadsheetBudget => 'Budget';

  @override
  String get spreadsheetSchedule => 'Schedule';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsFiles => 'Files';

  @override
  String get settingsData => 'Data';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeSubtitle => 'Light, dark, or system';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsLanguageSubtitle => 'App display language';

  @override
  String get settingsAutoSaveSubtitle => 'Save files automatically';

  @override
  String get settingsKeyboardSubtitle => 'View all shortcuts';

  @override
  String get settingsExportSubtitle => 'Share most recent file';

  @override
  String get settingsResetSubtitle => 'Clear recent file history';

  @override
  String get settingsVersionSubtitle => 'Current app version';

  @override
  String get settingsLicenses => 'Open-Source Licenses';

  @override
  String get settingsLicensesSubtitle => 'Third-party libraries';
}
