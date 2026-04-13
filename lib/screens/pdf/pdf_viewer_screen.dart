import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excelia/l10n/app_localizations.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import 'package:excelia/utils/constants.dart';

/// Syncfusion 기반 PDF 뷰어 — 텍스트 검색, 북마크, 주석, 핀치 줌 지원.
class PdfViewerScreen extends StatefulWidget {
  const PdfViewerScreen({super.key});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  String? _filePath;
  String? _fileName;
  bool _isLoading = false;
  bool _nightMode = false;
  bool _showThumbnails = false;
  bool _showSearch = false;
  String? _errorMessage;

  final PdfViewerController _pdfController = PdfViewerController();
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  PdfTextSearchResult _searchResult = PdfTextSearchResult();
  final TextEditingController _searchCtrl = TextEditingController();

  int _currentPage = 1;
  int _totalPages = 0;

  PdfAnnotationMode _annotationMode = PdfAnnotationMode.none;
  Color _annotationColor = AppColors.annotationYellow;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final path = ModalRoute.of(context)?.settings.arguments as String?;
      if (path != null) {
        _loadFile(path);
      }
    });
  }

  @override
  void dispose() {
    _searchResult.removeListener(_onSearchResultChanged);
    _searchResult.clear();
    _pdfController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // File loading
  // ---------------------------------------------------------------------------

  Future<void> _loadFile(String path) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final l = AppLocalizations.of(context)!;
      final file = File(path);
      if (!await file.exists()) {
        throw Exception(l.pdfFileNotFound);
      }

      // Verify the file is actually readable
      final stat = await file.stat();
      debugPrint('PDF file: $path (${stat.size} bytes)');

      // Step 1: Show file name in AppBar while loading indicator is still visible
      setState(() {
        _fileName = path.split(RegExp(r'[/\\]')).last;
      });

      // Step 2: Let the loading indicator render before heavy Syncfusion init
      await Future.delayed(const Duration(milliseconds: 50));
      if (!mounted) return;

      // Step 3: Set file path — triggers SfPdfViewer creation
      setState(() {
        _filePath = path;
        _currentPage = 1;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '$e';
      });
      if (mounted) {
        final l = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.fileOpenError(e.toString()))),
        );
      }
    }
  }

  Future<void> _openFilePicker() async {
    final l = AppLocalizations.of(context)!;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      dialogTitle: l.pdfOpenFile,
    );
    if (result != null && result.files.single.path != null) {
      _loadFile(result.files.single.path!);
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          _nightMode ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filePath == null
              ? _errorMessage != null
                  ? _buildErrorState()
                  : _buildEmptyState()
              : Column(
                  children: [
                    if (_showSearch) _buildSearchBar(),
                    if (_annotationMode != PdfAnnotationMode.none)
                      _buildAnnotationColorBar(),
                    Expanded(
                      child: Row(
                        children: [
                          if (_showThumbnails) _buildThumbnailSidebar(),
                          Expanded(child: _buildViewer()),
                        ],
                      ),
                    ),
                    SafeArea(
                      top: false, left: false, right: false,
                      child: _buildBottomBar(),
                    ),
                  ],
                ),
    );
  }

  // ---------------------------------------------------------------------------
  // AppBar
  // ---------------------------------------------------------------------------

  PreferredSizeWidget _buildAppBar() {
    final l = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppBar(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      foregroundColor: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(2),
        child: Container(color: AppColors.pdfRed, height: 2),
      ),
      title: Text(
        _fileName ?? l.pdfViewer,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 17),
      ),
      actions: [
        if (_filePath != null) ...[
          PopupMenuButton<String>(
            icon: Icon(
              _annotationMode != PdfAnnotationMode.none
                  ? LucideIcons.highlighter
                  : LucideIcons.penTool,
              size: 20,
              color: _annotationMode != PdfAnnotationMode.none
                  ? AppColors.primary
                  : null,
            ),
            tooltip: l.pdfAnnotation,
            onSelected: _handleAnnotationMode,
            itemBuilder: (_) => [
              PopupMenuItem(
                  value: 'highlight',
                  child: Text(l.pdfAnnotationHighlight)),
              PopupMenuItem(
                  value: 'underline',
                  child: Text(l.pdfAnnotationUnderline)),
              PopupMenuItem(
                  value: 'strikethrough',
                  child: Text(l.pdfAnnotationStrikethrough)),
              const PopupMenuDivider(),
              PopupMenuItem(
                  value: 'none', child: Text(l.pdfAnnotationOff)),
            ],
          ),
          IconButton(
            icon: const Icon(LucideIcons.search),
            onPressed: () => setState(() {
              _showSearch = !_showSearch;
              if (!_showSearch) {
                _searchResult.clear();
                _searchCtrl.clear();
              }
            }),
            tooltip: l.pdfSearch,
          ),
          PopupMenuButton<String>(
            icon: const Icon(LucideIcons.moreVertical, size: 20),
            tooltip: l.commonMore,
            onSelected: (action) {
              switch (action) {
                case 'bookmark':
                  _pdfViewerKey.currentState?.openBookmarkView();
                case 'thumbnail':
                  setState(() => _showThumbnails = !_showThumbnails);
                case 'nightMode':
                  setState(() => _nightMode = !_nightMode);
                case 'print':
                  _print();
                case 'share':
                  _share();
                case 'open':
                  _openFilePicker();
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'bookmark',
                child: Row(
                  children: [
                    const Icon(LucideIcons.bookmark, size: 18),
                    const SizedBox(width: 12),
                    Text(l.pdfBookmark),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'thumbnail',
                child: Row(
                  children: [
                    Icon(_showThumbnails
                        ? LucideIcons.panelLeftClose
                        : LucideIcons.panelLeftOpen, size: 18),
                    const SizedBox(width: 12),
                    Text(l.pdfThumbnail),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'nightMode',
                child: Row(
                  children: [
                    Icon(_nightMode ? LucideIcons.sun : LucideIcons.moon,
                        size: 18),
                    const SizedBox(width: 12),
                    Text(_nightMode ? l.pdfDayMode : l.pdfNightMode),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'print',
                child: Row(
                  children: [
                    const Icon(LucideIcons.printer, size: 18),
                    const SizedBox(width: 12),
                    Text(l.pdfPrint),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    const Icon(LucideIcons.share2, size: 18),
                    const SizedBox(width: 12),
                    Text(l.commonShare),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'open',
                child: Row(
                  children: [
                    const Icon(LucideIcons.folderOpen, size: 18),
                    const SizedBox(width: 12),
                    Text(l.pdfOpenFile),
                  ],
                ),
              ),
            ],
          ),
        ],
        if (_filePath == null)
          IconButton(
            icon: const Icon(LucideIcons.folderOpen),
            onPressed: _openFilePicker,
            tooltip: l.pdfOpenFile,
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Search bar
  // ---------------------------------------------------------------------------

  Widget _buildSearchBar() {
    final l = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _nightMode ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          bottom: BorderSide(
            color: _nightMode ? AppColors.darkOutline : AppColors.lightOutline,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: l.pdfSearchHint,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixIcon: const Icon(LucideIcons.search, size: 18),
              ),
              onSubmitted: (_) => _performSearch(),
            ),
          ),
          const SizedBox(width: 8),
          if (_searchResult.hasResult) ...[
            Text(
              '${_searchResult.currentInstanceIndex}/${_searchResult.totalInstanceCount}',
              style: TextStyle(
                fontSize: 12,
                color: _nightMode ? AppColors.darkOnSurfaceAlt : AppColors.lightOnSurfaceAlt,
              ),
            ),
            IconButton(
              icon: const Icon(LucideIcons.chevronUp, size: 20),
              onPressed: () {
                _searchResult.previousInstance();
                setState(() {});
              },
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            ),
            IconButton(
              icon: const Icon(LucideIcons.chevronDown, size: 20),
              onPressed: () {
                _searchResult.nextInstance();
                setState(() {});
              },
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            ),
          ],
          IconButton(
            icon: const Icon(LucideIcons.x, size: 20),
            onPressed: () {
              _searchResult.clear();
              _searchCtrl.clear();
              setState(() => _showSearch = false);
            },
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          ),
        ],
      ),
    );
  }

  void _onSearchResultChanged() {
    if (mounted) setState(() {});
  }

  void _performSearch() {
    if (_searchCtrl.text.isEmpty) return;
    _searchResult.removeListener(_onSearchResultChanged);
    _searchResult = _pdfController.searchText(_searchCtrl.text);
    _searchResult.addListener(_onSearchResultChanged);
  }

  // ---------------------------------------------------------------------------
  // Annotation mode
  // ---------------------------------------------------------------------------

  void _handleAnnotationMode(String mode) {
    setState(() {
      switch (mode) {
        case 'highlight':
          _annotationMode = PdfAnnotationMode.highlight;
        case 'underline':
          _annotationMode = PdfAnnotationMode.underline;
        case 'strikethrough':
          _annotationMode = PdfAnnotationMode.strikethrough;
        case 'none':
        default:
          _annotationMode = PdfAnnotationMode.none;
      }
      _pdfController.annotationMode = _annotationMode;
      _applyAnnotationColor();
    });
  }

  void _applyAnnotationColor() {
    _pdfController.annotationSettings.highlight.color = _annotationColor;
    _pdfController.annotationSettings.underline.color = _annotationColor;
    _pdfController.annotationSettings.strikethrough.color = _annotationColor;
  }

  Widget _buildAnnotationColorBar() {
    final l = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const colors = [
      AppColors.annotationYellow,
      AppColors.annotationGreen,
      AppColors.annotationBlue,
      AppColors.annotationRed,
      AppColors.annotationOrange,
    ];
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.grey100,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkOutline : AppColors.grey300,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(l.pdfAnnotationColor,
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(width: 12),
          ...colors.map((c) => GestureDetector(
                onTap: () {
                  setState(() => _annotationColor = c);
                  _applyAnnotationColor();
                },
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _annotationColor == c
                              ? AppColors.primary
                              : (isDark
                                  ? AppColors.darkOnSurfaceAlt
                                  : AppColors.grey500),
                          width: _annotationColor == c ? 2.5 : 1,
                        ),
                      ),
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Empty / Error states
  // ---------------------------------------------------------------------------

  Widget _buildEmptyState() {
    final l = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.fileText,
            size: 80,
            color: AppColors.pdfRed.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 24),
          Text(l.pdfOpenPrompt,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600,
                  color: AppColors.grey600)),
          const SizedBox(height: 8),
          Text(l.pdfOpenHint,
              style: const TextStyle(fontSize: 14, color: AppColors.grey600)),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: _openFilePicker,
            icon: const Icon(LucideIcons.folderOpen),
            label: Text(l.pdfOpenFile),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.pdfRed,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              textStyle: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    final l = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.alertCircle, size: 64,
                color: AppColors.pdfRed.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(l.pdfCannotOpen,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(_errorMessage ?? '',
                style: const TextStyle(fontSize: 13, color: AppColors.grey600),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _openFilePicker,
              icon: const Icon(LucideIcons.folderOpen),
              label: Text(l.pdfOpenAnother),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.pdfRed,
                foregroundColor: AppColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PDF Viewer (Syncfusion)
  // ---------------------------------------------------------------------------

  Widget _buildViewer() {
    if (_filePath == null) return const SizedBox.shrink();

    final viewer = SfPdfViewer.file(
      File(_filePath!),
      key: _pdfViewerKey,
      controller: _pdfController,
      pageLayoutMode: PdfPageLayoutMode.single,
      canShowTextSelectionMenu: true,
      canShowScrollHead: false,
      canShowScrollStatus: false,
      canShowPaginationDialog: false,
      enableTextSelection: true,
      enableDocumentLinkAnnotation: true,
      onDocumentLoaded: (PdfDocumentLoadedDetails details) {
        setState(() {
          _totalPages = details.document.pages.count;
        });
      },
      onPageChanged: (PdfPageChangedDetails details) {
        setState(() {
          _currentPage = details.newPageNumber;
        });
      },
      onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
        debugPrint('PDF load failed: ${details.error} — ${details.description}');
        setState(() {
          _errorMessage = details.description;
          _filePath = null;
        });
      },
    );

    return ColorFiltered(
      colorFilter: _nightMode
          ? const ColorFilter.matrix(<double>[
              -1, 0, 0, 0, 255,
              0, -1, 0, 0, 255,
              0, 0, -1, 0, 255,
              0, 0, 0, 1, 0,
            ])
          : const ColorFilter.mode(AppColors.transparent, BlendMode.dst),
      child: viewer,
    );
  }

  // ---------------------------------------------------------------------------
  // Thumbnail sidebar
  // ---------------------------------------------------------------------------

  Widget _buildThumbnailSidebar() {
    final l = AppLocalizations.of(context)!;
    return Container(
      width: 140,
      color: _nightMode ? AppColors.darkSurface : AppColors.lightSurface,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            child: Text(l.pdfPageList,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                    color: _nightMode ? AppColors.darkOnSurfaceAlt : AppColors.lightOnSurfaceAlt)),
          ),
          const Divider(height: 1),
          Expanded(
            child: _totalPages > 0
                ? ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _totalPages,
                    itemBuilder: (context, index) {
                      final pageNum = index + 1;
                      final isActive = pageNum == _currentPage;
                      return GestureDetector(
                        onTap: () {
                          _pdfController.jumpToPage(pageNum);
                          setState(() => _currentPage = pageNum);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isActive
                                  ? AppColors.pdfRed
                                  : (_nightMode ? AppColors.darkOutline : AppColors.lightOutline),
                              width: isActive ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Column(
                            children: [
                              AspectRatio(
                                aspectRatio: 210 / 297,
                                child: Container(
                                  color: _nightMode
                                      ? AppColors.grey800
                                      : AppColors.grey100,
                                  child: Center(
                                    child: Text('$pageNum',
                                        style: TextStyle(fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: isActive
                                                ? AppColors.pdfRed
                                                : (_nightMode ? AppColors.darkTextMuted : AppColors.lightOnSurfaceAlt))),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  )
                : Center(
                    child: Text(l.commonLoading,
                        style: TextStyle(fontSize: 12,
                            color: _nightMode ? AppColors.darkTextMuted : AppColors.lightOnSurfaceAlt)),
                  ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom bar
  // ---------------------------------------------------------------------------

  Widget _buildBottomBar() {
    final l = AppLocalizations.of(context)!;
    final textColor = _nightMode ? AppColors.darkOnSurfaceAlt : AppColors.lightOnSurface;
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _nightMode ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          top: BorderSide(
            color: _nightMode ? AppColors.darkOutline : AppColors.lightOutline,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // 이전 페이지
          IconButton(
            icon: Icon(LucideIcons.chevronLeft, color: textColor, size: 22),
            onPressed: _currentPage > 1
                ? () => _pdfController.previousPage()
                : null,
            tooltip: l.pdfPrevPage,
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          ),

          // 페이지 표시
          GestureDetector(
            onTap: _showPageJumpDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: _nightMode ? AppColors.darkSurfaceElevated : AppColors.grey100,
              ),
              child: Text(
                _totalPages > 0 ? '$_currentPage / $_totalPages' : '- / -',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                    color: textColor),
              ),
            ),
          ),

          // 다음 페이지
          IconButton(
            icon: Icon(LucideIcons.chevronRight, color: textColor, size: 22),
            onPressed: _currentPage < _totalPages
                ? () => _pdfController.nextPage()
                : null,
            tooltip: l.pdfNextPage,
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          ),

          const Spacer(),

          // 첫/마지막 페이지
          IconButton(
            icon: Icon(LucideIcons.chevronsLeft, color: textColor, size: 20),
            onPressed: () => _pdfController.jumpToPage(1),
            tooltip: l.pdfFirstPage,
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          ),
          IconButton(
            icon: Icon(LucideIcons.chevronsRight, color: textColor, size: 20),
            onPressed: () => _pdfController.jumpToPage(_totalPages),
            tooltip: l.pdfLastPage,
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Page jump dialog
  // ---------------------------------------------------------------------------

  void _showPageJumpDialog() {
    if (_totalPages <= 0) return;
    final ctrl = TextEditingController(text: _currentPage.toString());
    showDialog(
      context: context,
      builder: (ctx) {
        final dl = AppLocalizations.of(ctx)!;
        return AlertDialog(
          title: Text(dl.pdfJumpToPage),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: dl.pdfPageNumber(_totalPages),
            ),
            onSubmitted: (v) {
              _jumpToPage(v);
              Navigator.pop(ctx);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(dl.commonCancel),
            ),
            FilledButton(
              onPressed: () {
                _jumpToPage(ctrl.text);
                Navigator.pop(ctx);
              },
              child: Text(dl.commonMove),
            ),
          ],
        );
      },
    );
  }

  void _jumpToPage(String value) {
    final page = int.tryParse(value);
    if (page != null && page >= 1 && page <= _totalPages) {
      _pdfController.jumpToPage(page);
    }
  }

  // ---------------------------------------------------------------------------
  // Print / Share
  // ---------------------------------------------------------------------------

  Future<void> _print() async {
    if (_filePath == null) return;
    final bytes = await File(_filePath!).readAsBytes();
    await Printing.layoutPdf(
      onLayout: (_) => Future.value(bytes),
      name: _fileName ?? '',
    );
  }

  Future<void> _share() async {
    if (_filePath == null) return;
    await Share.shareXFiles([XFile(_filePath!)]);
  }
}
