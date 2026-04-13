import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdfx/pdfx.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import 'package:excelia/l10n/app_localizations.dart';
import 'package:excelia/utils/constants.dart';

/// Native PDF viewer using pdfx (Android PdfRenderer / iOS CGPDFDocument).
class PdfViewerScreen extends StatefulWidget {
  const PdfViewerScreen({super.key});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  String? _filePath;
  String? _fileName;
  bool _nightMode = false;
  String? _errorMessage;

  PdfControllerPinch? _pdfController;
  int _currentPage = 1;
  int _totalPages = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final path = ModalRoute.of(context)?.settings.arguments as String?;
      if (path != null) _loadFile(path);
    });
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // File loading
  // ---------------------------------------------------------------------------

  Future<void> _loadFile(String path) async {
    try {
      final l = AppLocalizations.of(context)!;
      if (!await File(path).exists()) {
        throw Exception(l.pdfFileNotFound);
      }

      _pdfController?.dispose();

      final doc = PdfDocument.openFile(path);
      final controller = PdfControllerPinch(document: doc);

      setState(() {
        _filePath = path;
        _fileName = path.split(RegExp(r'[/\\]')).last;
        _pdfController = controller;
        _errorMessage = null;
        _currentPage = 1;
      });
    } catch (e) {
      setState(() => _errorMessage = '$e');
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          _nightMode ? AppColors.darkBackground : (isDark ? AppColors.darkBackground : AppColors.lightBackground),
      appBar: _buildAppBar(),
      body: _pdfController == null
          ? _errorMessage != null
              ? _buildErrorState()
              : _buildEmptyState()
          : Column(
              children: [
                Expanded(child: _buildViewer()),
                SafeArea(
                  top: false,
                  left: false,
                  right: false,
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
      foregroundColor:
          isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
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
        if (_filePath != null)
          PopupMenuButton<String>(
            icon: const Icon(LucideIcons.moreVertical, size: 20),
            tooltip: l.commonMore,
            onSelected: (action) {
              switch (action) {
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
  // Empty / Error states
  // ---------------------------------------------------------------------------

  Widget _buildEmptyState() {
    final l = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.fileText, size: 80,
              color: AppColors.pdfRed.withValues(alpha: 0.3)),
          const SizedBox(height: 24),
          Text(l.pdfOpenPrompt,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
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
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(_errorMessage ?? '',
                style:
                    const TextStyle(fontSize: 13, color: AppColors.grey600),
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
  // PDF Viewer (pdfx — native renderer)
  // ---------------------------------------------------------------------------

  Widget _buildViewer() {
    if (_pdfController == null) return const SizedBox.shrink();

    final viewer = PdfViewPinch(
      controller: _pdfController!,
      padding: 8,
      onDocumentLoaded: (doc) {
        setState(() => _totalPages = doc.pagesCount);
      },
      onPageChanged: (page) {
        setState(() => _currentPage = page);
      },
    );

    if (!_nightMode) return viewer;

    return ColorFiltered(
      colorFilter: const ColorFilter.matrix(<double>[
        -1, 0, 0, 0, 255,
        0, -1, 0, 0, 255,
        0, 0, -1, 0, 255,
        0, 0, 0, 1, 0,
      ]),
      child: viewer,
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom bar
  // ---------------------------------------------------------------------------

  Widget _buildBottomBar() {
    final l = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        _nightMode ? AppColors.darkOnSurfaceAlt : (isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface);

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _nightMode
            ? AppColors.darkSurface
            : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
        border: Border(
          top: BorderSide(
            color: _nightMode
                ? AppColors.darkOutline
                : (isDark ? AppColors.darkOutline : AppColors.lightOutline),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(LucideIcons.chevronLeft, color: textColor, size: 22),
            onPressed: _currentPage > 1
                ? () => _pdfController?.previousPage(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                    )
                : null,
            tooltip: l.pdfPrevPage,
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          ),
          GestureDetector(
            onTap: _showPageJumpDialog,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: _nightMode
                    ? AppColors.darkSurfaceElevated
                    : (isDark ? AppColors.darkSurfaceElevated : AppColors.grey100),
              ),
              child: Text(
                _totalPages > 0 ? '$_currentPage / $_totalPages' : '- / -',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: textColor),
              ),
            ),
          ),
          IconButton(
            icon: Icon(LucideIcons.chevronRight, color: textColor, size: 22),
            onPressed: _currentPage < _totalPages
                ? () => _pdfController?.nextPage(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                    )
                : null,
            tooltip: l.pdfNextPage,
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(LucideIcons.chevronsLeft, color: textColor, size: 20),
            onPressed: () => _pdfController?.jumpToPage(1),
            tooltip: l.pdfFirstPage,
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          ),
          IconButton(
            icon:
                Icon(LucideIcons.chevronsRight, color: textColor, size: 20),
            onPressed: () => _pdfController?.jumpToPage(_totalPages),
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
      _pdfController?.jumpToPage(page);
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
