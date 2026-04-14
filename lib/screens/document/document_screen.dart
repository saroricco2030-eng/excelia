import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:printing/printing.dart';
import 'package:excelia/l10n/app_localizations.dart';

import 'package:flutter/services.dart';
import 'package:excelia/providers/app_provider.dart';
import 'package:excelia/models/table_embed.dart';
import 'package:path_provider/path_provider.dart';
import 'package:excelia/screens/common/keyboard_shortcuts_dialog.dart';
import 'package:excelia/utils/snackbar_utils.dart';
import 'package:excelia/utils/file_utils.dart';
import 'package:excelia/providers/document_provider.dart';
import 'package:excelia/screens/document/widgets/page_setup_sheet.dart';
import 'package:excelia/screens/document/widgets/table_embed_builder.dart';
import 'package:excelia/screens/document/widgets/table_insert_dialog.dart';
import 'package:excelia/utils/constants.dart';

class DocumentScreen extends StatefulWidget {
  const DocumentScreen({super.key});

  @override
  State<DocumentScreen> createState() => _DocumentScreenState();
}

class _DocumentScreenState extends State<DocumentScreen> {
  late final DocumentProvider _provider;
  final FocusNode _editorFocusNode = FocusNode();
  final FocusNode _keyboardFocusNode = FocusNode();
  final ScrollController _editorScrollController = ScrollController();
  bool _isEditingTitle = false;
  late TextEditingController _titleController;
  bool _showFindBar = false;
  bool _showOutline = false;
  final TextEditingController _findCtrl = TextEditingController();
  final TextEditingController _replaceCtrl = TextEditingController();
  Timer? _autoSaveTimer;

  @override
  void initState() {
    super.initState();
    _provider = context.read<DocumentProvider>();
    _titleController = TextEditingController(text: _provider.title);

    // Sync the title controller whenever the provider notifies (e.g. after
    // createNew() or loadFromFile() resets the title).
    _provider.addListener(_onProviderChanged);

    // If a file path was passed as argument, load it; otherwise create new.
    // Always call createNew() for the no-file case so stale state from a
    // previous visit is cleared.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final arg = ModalRoute.of(context)?.settings.arguments as String?;
      if (arg != null && arg.startsWith('template:')) {
        final templateType = arg.substring('template:'.length);
        _provider.createNew();
        _provider.createFromTemplate(templateType);
      } else if (arg != null) {
        try {
          await _provider.loadFromFile(arg);
        } catch (e) {
          if (!mounted) return;
          final l = AppLocalizations.of(context)!;
          showExceliaSnackBar(context,
            message: l.documentOpenError(e.toString()),
            isError: true,
            actionLabel: l.openInExternalApp,
            onAction: () async {
              final err = await FileUtils.openWithExternalApp(arg);
              if (err != null && mounted) {
                showExceliaSnackBar(context,
                  message: err.toLowerCase().contains('no app')
                      ? l.externalAppError
                      : l.externalAppOpenFailed(err),
                  isError: true);
              }
            },
          );
          _provider.createNew();
        }
      } else {
        _provider.createNew();
      }
    });
  }

  void _onProviderChanged() {
    // Keep the title controller in sync when not actively editing.
    if (!_isEditingTitle && _titleController.text != _provider.title) {
      _titleController.text = _provider.title;
    }
    // Auto-save debounce
    _scheduleAutoSave();
  }

  void _scheduleAutoSave() {
    _autoSaveTimer?.cancel();
    if (!_provider.isDirty || _provider.filePath == null) return;
    final appProv = context.read<AppProvider>();
    if (!appProv.autoSaveEnabled) return;
    _autoSaveTimer = Timer(const Duration(seconds: 30), () async {
      if (!mounted || !_provider.isDirty || _provider.filePath == null) return;
      try {
        await _provider.saveToFile();
      } catch (e) {
        debugPrint('Document auto-save failed: $e');
      }
    });
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _provider.removeListener(_onProviderChanged);
    _keyboardFocusNode.dispose();
    _editorFocusNode.dispose();
    _editorScrollController.dispose();
    _titleController.dispose();
    _findCtrl.dispose();
    _replaceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DocumentProvider>(
      builder: (context, provider, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final isWide = MediaQuery.of(context).size.width > 900;
        return KeyboardListener(
          focusNode: _keyboardFocusNode,
          autofocus: false,
          onKeyEvent: (event) {
            if (event is KeyDownEvent) {
              final ctrl = HardwareKeyboard.instance.isControlPressed;
              if (ctrl && event.logicalKey == LogicalKeyboardKey.keyS) {
                _save(provider);
              } else if (ctrl && event.logicalKey == LogicalKeyboardKey.keyF) {
                setState(() => _showFindBar = !_showFindBar);
              }
            }
          },
          child: Scaffold(
          backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
          appBar: _buildAppBar(provider),
          body: Column(
            children: [
              if (_showFindBar) _buildDocumentFindBar(provider),
              _buildToolbar(provider),
              Expanded(
                child: Row(
                  children: [
                    if (_showOutline || isWide) ...[
                      _buildOutlinePanel(provider),
                      const VerticalDivider(width: 0.5, thickness: 0.5),
                    ],
                    Expanded(child: _buildEditorArea(provider)),
                  ],
                ),
              ),
              _buildBottomActionBar(provider),
              SafeArea(
                top: false, left: false, right: false,
                child: _buildStatusBar(provider),
              ),
            ],
          ),
        ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // AppBar
  // ---------------------------------------------------------------------------

  PreferredSizeWidget _buildAppBar(DocumentProvider provider) {
    final l = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppBar(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      foregroundColor: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(2),
        child: Container(color: AppColors.documentBlue, height: 2),
      ),
      leading: IconButton(
        icon: const Icon(LucideIcons.arrowLeft),
        onPressed: () => _handleBack(provider),
        tooltip: l.commonBack,
      ),
      title: _isEditingTitle
          ? TextField(
              controller: _titleController,
              autofocus: true,
              style: TextStyle(
                color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              onSubmitted: (value) {
                provider.setTitle(value);
                setState(() => _isEditingTitle = false);
              },
              onTapOutside: (_) {
                provider.setTitle(_titleController.text);
                setState(() => _isEditingTitle = false);
              },
            )
          : GestureDetector(
              onTap: () {
                _titleController.text = provider.title;
                setState(() => _isEditingTitle = true);
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      provider.title,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                  if (provider.isDirty) ...[
                    const SizedBox(width: 6),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.warningAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                  const SizedBox(width: 4),
                  Icon(LucideIcons.pencil, size: 14,
                      color: (isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface).withValues(alpha: 0.5)),
                ],
              ),
            ),
      actions: [
        IconButton(
          icon: const Icon(LucideIcons.save),
          onPressed: provider.isSaving ? null : () => _save(provider),
          tooltip: l.commonSave,
        ),
        PopupMenuButton<String>(
          icon: const Icon(LucideIcons.moreVertical),
          tooltip: l.commonMore,
          onSelected: (value) => _handleMenuAction(value, provider),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'page_setup',
              child: ListTile(
                leading: const Icon(LucideIcons.settings2),
                title: Text(l.documentPageSetup),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'insert_toc',
              child: ListTile(
                leading: const Icon(LucideIcons.listOrdered),
                title: Text(l.documentInsertToc),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'export_pdf',
              child: ListTile(
                leading: const Icon(LucideIcons.fileText),
                title: Text(l.documentExportPdf),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'share',
              child: ListTile(
                leading: const Icon(LucideIcons.share2),
                title: Text(l.commonShare),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'print_preview',
              child: ListTile(
                leading: const Icon(LucideIcons.eye),
                title: Text(l.documentPrintPreview),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'print',
              child: ListTile(
                leading: const Icon(LucideIcons.printer),
                title: Text(l.documentPrint),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'open',
              child: ListTile(
                leading: const Icon(LucideIcons.folderOpen),
                title: Text(l.fileOpen),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'open_docx',
              child: ListTile(
                leading: const Icon(LucideIcons.fileInput),
                title: Text(l.documentOpenDocx),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'save_docx',
              child: ListTile(
                leading: const Icon(LucideIcons.fileOutput),
                title: Text(l.documentSaveDocx),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'shortcuts',
              child: ListTile(
                leading: const Icon(LucideIcons.keyboard),
                title: Text(l.keyboardShortcuts),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'new',
              child: ListTile(
                leading: const Icon(LucideIcons.filePlus),
                title: Text(l.documentNew),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Formatting Toolbar
  // ---------------------------------------------------------------------------

  Widget _buildToolbar(DocumentProvider provider) {
    final l = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.toolbarDark : AppColors.toolbarLight,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
            width: isDark ? 0.5 : 1,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // --- Text style ---
            _quillBtn(
              quill.QuillToolbarToggleStyleButton(
                controller: provider.controller,
                attribute: quill.Attribute.bold,
              ),
            ),
            _quillBtn(
              quill.QuillToolbarToggleStyleButton(
                controller: provider.controller,
                attribute: quill.Attribute.italic,
              ),
            ),
            _quillBtn(
              quill.QuillToolbarToggleStyleButton(
                controller: provider.controller,
                attribute: quill.Attribute.underline,
              ),
            ),
            _quillBtn(
              quill.QuillToolbarToggleStyleButton(
                controller: provider.controller,
                attribute: quill.Attribute.strikeThrough,
              ),
            ),
            _sep(),

            // --- Font size ---
            _quillBtn(
              quill.QuillToolbarFontSizeButton(
                controller: provider.controller,
              ),
            ),
            _sep(),

            // --- Colors ---
            _quillBtn(
              quill.QuillToolbarColorButton(
                controller: provider.controller,
                isBackground: false,
              ),
            ),
            _quillBtn(
              quill.QuillToolbarColorButton(
                controller: provider.controller,
                isBackground: true,
              ),
            ),
            _sep(),

            // --- Headings ---
            _quillBtn(
              quill.QuillToolbarSelectHeaderStyleDropdownButton(
                controller: provider.controller,
              ),
            ),
            _sep(),

            // --- Lists ---
            _quillBtn(
              quill.QuillToolbarToggleStyleButton(
                controller: provider.controller,
                attribute: quill.Attribute.ul,
              ),
            ),
            _quillBtn(
              quill.QuillToolbarToggleStyleButton(
                controller: provider.controller,
                attribute: quill.Attribute.ol,
              ),
            ),
            _quillBtn(
              quill.QuillToolbarToggleCheckListButton(
                controller: provider.controller,
              ),
            ),
            _sep(),

            // --- Alignment ---
            _quillBtn(
              quill.QuillToolbarSelectAlignmentButton(
                controller: provider.controller,
              ),
            ),
            _sep(),

            // --- Block styles ---
            _quillBtn(
              quill.QuillToolbarToggleStyleButton(
                controller: provider.controller,
                attribute: quill.Attribute.codeBlock,
              ),
            ),
            _quillBtn(
              quill.QuillToolbarToggleStyleButton(
                controller: provider.controller,
                attribute: quill.Attribute.blockQuote,
              ),
            ),

            // Divider insert
            IconButton(
              icon: const Icon(LucideIcons.minus, size: 20),
              onPressed: () {
                final idx = provider.controller.selection.baseOffset;
                provider.controller.document.insert(idx, '\n---\n');
                provider.controller.updateSelection(
                  TextSelection.collapsed(offset: idx + 5),
                  quill.ChangeSource.local,
                );
              },
              tooltip: l.documentInsertDivider,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
            _sep(),

            // Image insert
            IconButton(
              icon: const Icon(LucideIcons.image, size: 20),
              onPressed: () => _insertImage(provider),
              tooltip: l.documentInsertImage,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),

            // Table insert
            IconButton(
              icon: const Icon(LucideIcons.table, size: 20),
              onPressed: () => _insertTable(provider),
              tooltip: l.documentInsertTable,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quillBtn(Widget child) =>
      SizedBox(height: 36, child: child);

  Widget _sep() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 0.5,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
    );
  }

  // ---------------------------------------------------------------------------
  // Editor Area
  // ---------------------------------------------------------------------------

  Widget _buildEditorArea(DocumentProvider provider) {
    final l = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWide = MediaQuery.of(context).size.width > 900;
    return Container(
      color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isWide ? 960 : 816),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.white,
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.06),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: quill.QuillEditor(
                controller: provider.controller,
                focusNode: _editorFocusNode,
                scrollController: _editorScrollController,
                config: quill.QuillEditorConfig(
                  padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 48),
                  placeholder: l.documentPlaceholder,
                  expands: true,
                  autoFocus: false,
                  embedBuilders: [TableEmbedBuilder()],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Status Bar
  // ---------------------------------------------------------------------------

  Widget _buildBottomActionBar(DocumentProvider provider) {
    final l = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(LucideIcons.undo2, size: 20),
            onPressed: provider.undo,
            tooltip: l.commonUndo,
          ),
          IconButton(
            icon: const Icon(LucideIcons.redo2, size: 20),
            onPressed: provider.redo,
            tooltip: l.commonRedo,
          ),
          const Spacer(),
          IconButton(
            icon: Icon(LucideIcons.search, size: 20,
              color: _showFindBar ? AppColors.documentBlue : null),
            onPressed: () => setState(() {
              _showFindBar = !_showFindBar;
              if (!_showFindBar) {
                provider.clearSearch();
                _findCtrl.clear();
                _replaceCtrl.clear();
              }
            }),
            tooltip: l.findTitle,
          ),
          IconButton(
            icon: Icon(LucideIcons.list, size: 20,
              color: _showOutline ? AppColors.documentBlue : null),
            onPressed: () => setState(() => _showOutline = !_showOutline),
            tooltip: l.documentOutline,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar(DocumentProvider provider) {
    final l = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusTextColor = isDark ? AppColors.darkOnSurfaceAlt : AppColors.grey600;
    return Semantics(
      label: l.a11yDocumentStatus(provider.wordCount, provider.characterCount, provider.pageEstimate),
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurfaceElevated,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
              width: isDark ? 0.5 : 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.fileText,
                size: 14, color: statusTextColor),
            const SizedBox(width: 6),
            Text(
              l.documentWordCount(provider.wordCount),
              style: TextStyle(fontSize: 12, color: statusTextColor),
            ),
            const SizedBox(width: 16),
            Text(
              l.documentCharCount(provider.characterCount),
              style: TextStyle(fontSize: 12, color: statusTextColor),
            ),
            const SizedBox(width: 16),
            Text(
              l.documentPageEstimate(provider.pageEstimate),
              style: TextStyle(fontSize: 12, color: statusTextColor),
            ),
            const SizedBox(width: 16),
            Icon(LucideIcons.clock, size: 12, color: statusTextColor),
            const SizedBox(width: 4),
            Text(
              l.documentReadingTime(provider.readingTimeMinutes),
              style: TextStyle(fontSize: 12, color: statusTextColor),
            ),
            const Spacer(),
            if (provider.isSaving)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 1.5),
                  ),
                  const SizedBox(width: 6),
                  Text(l.commonSaving,
                      style:
                          TextStyle(fontSize: 12, color: statusTextColor)),
                ],
              )
            else if (provider.isDirty)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.warning,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(l.commonUnsavedChanges,
                      style: const TextStyle(fontSize: 12, color: AppColors.warning)),
                ],
              )
            else if (provider.lastSavedAt != null)
              Text(
                l.savedAt('${provider.lastSavedAt!.hour.toString().padLeft(2, '0')}:${provider.lastSavedAt!.minute.toString().padLeft(2, '0')}'),
                style: TextStyle(fontSize: 12, color: statusTextColor),
              )
            else
              Text(l.commonSaved,
                  style:
                      const TextStyle(fontSize: 12, color: AppColors.grey600)),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _save(DocumentProvider provider) async {
    final l = AppLocalizations.of(context)!;
    try {
      String? path = provider.filePath;
      if (path == null) {
        try {
          path = await FilePicker.platform.saveFile(
            dialogTitle: l.documentSaveTitle,
            fileName: '${provider.title}.exdoc',
            allowedExtensions: ['exdoc'],
            type: FileType.custom,
          );
        } catch (e) {
          debugPrint('Document saveFile picker failed: $e');
        }
        // Fallback for mobile platforms
        if (path == null && (Platform.isAndroid || Platform.isIOS)) {
          final dir = await getApplicationDocumentsDirectory();
          final sanitized =
              provider.title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
          path = '${dir.path}${Platform.pathSeparator}$sanitized.exdoc';
        }
        if (path == null) return;
      }
      await provider.saveToFile(path);
      if (mounted) {
        showExceliaSnackBar(context, message: l.documentSaved);
      }
    } catch (e) {
      if (mounted) {
        showExceliaSnackBar(context,
          message: l.documentSaveError(e.toString()), isError: true);
      }
    }
  }

  Future<void> _handleMenuAction(
      String action, DocumentProvider provider) async {
    final l = AppLocalizations.of(context)!;
    switch (action) {
      case 'page_setup':
        _showPageSetupSheet(provider);
      case 'insert_toc':
        final entries = provider.getOutline();
        if (entries.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l.documentTocEmpty)),
            );
          }
        } else {
          provider.insertTableOfContents();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l.documentTocInserted)),
            );
          }
        }
      case 'export_pdf':
        try {
          final path = await provider.exportToPdf();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l.documentExportDone(path))),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l.documentExportError(e.toString()))),
            );
          }
        }
      case 'share':
        await provider.shareDocument();
      case 'print_preview':
        try {
          final pdfPath = await provider.exportToPdf();
          final file = File(pdfPath);
          final bytes = await file.readAsBytes();
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => Scaffold(
                  appBar: AppBar(
                    title: Text(l.documentPrintPreviewTitle(provider.title)),
                  ),
                  body: PdfPreview(
                    build: (_) => Future.value(bytes),
                    canChangeOrientation: true,
                    canChangePageFormat: true,
                    canDebug: false,
                  ),
                ),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l.documentPreviewError(e.toString()))),
            );
          }
        }
      case 'print':
        try {
          final pdfPath = await provider.exportToPdf();
          final file = File(pdfPath);
          final bytes = await file.readAsBytes();
          await Printing.layoutPdf(
            onLayout: (_) => Future.value(bytes),
            name: provider.title,
          );
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l.documentPrintError(e.toString()))),
            );
          }
        }
      case 'open':
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['exdoc'],
          dialogTitle: l.documentOpenFile,
        );
        if (result != null && result.files.single.path != null) {
          await provider.loadFromFile(result.files.single.path!);
        }
      case 'open_docx':
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['docx'],
          dialogTitle: l.documentOpenDocx,
        );
        if (result != null && result.files.single.path != null) {
          try {
            await provider.loadDocx(result.files.single.path!);
            _titleController.text = provider.title;
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l.documentDocxLoaded)),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l.documentDocxError(e.toString()))),
              );
            }
          }
        }
      case 'save_docx':
        try {
          final path = await provider.saveAsDocx();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l.documentDocxSaved(path))),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l.documentDocxError(e.toString()))),
            );
          }
        }
      case 'new':
        if (provider.isDirty) {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(l.documentNew),
              content: Text(l.documentNewConfirm),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(l.commonCancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(l.commonContinue),
                ),
              ],
            ),
          );
          if (confirm != true) return;
        }
        provider.createNew();
      case 'shortcuts':
        showKeyboardShortcutsDialog(context, 'document');
    }
  }

  Future<void> _insertImage(DocumentProvider provider) async {
    final l = AppLocalizations.of(context)!;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      dialogTitle: l.documentSelectImage,
    );
    if (result != null && result.files.single.path != null) {
      final idx = provider.controller.selection.baseOffset;
      provider.controller.document.insert(idx, '\n');
      provider.controller.replaceText(
        idx + 1,
        0,
        quill.BlockEmbed.image(result.files.single.path!),
        null,
      );
    }
  }

  Future<void> _insertTable(DocumentProvider provider) async {
    final result = await showDialog<TableData>(
      context: context,
      builder: (ctx) => const TableInsertDialog(),
    );
    if (result != null && mounted) {
      final idx = provider.controller.selection.baseOffset;
      provider.controller.document.insert(idx, '\n');
      provider.controller.replaceText(
        idx + 1,
        0,
        TableBlockEmbed.fromTableData(result),
        null,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Page Setup Sheet
  // ---------------------------------------------------------------------------

  void _showPageSetupSheet(DocumentProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DocumentPageSetupSheet(
        setup: provider.pageSetup,
        headerText: provider.headerText,
        footerText: provider.footerText,
        onApply: (setup, header, footer) {
          provider.setPageSetup(setup);
          provider.setHeaderText(header);
          provider.setFooterText(footer);
          Navigator.pop(ctx);
          final l = AppLocalizations.of(ctx)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l.documentPageSetupApplied)),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Outline Panel
  // ---------------------------------------------------------------------------

  Widget _buildOutlinePanel(DocumentProvider provider) {
    final l = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final entries = provider.getOutline();

    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          right: BorderSide(
            color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
            width: isDark ? 0.5 : 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(LucideIcons.list, size: 16, color: AppColors.documentBlue),
                const SizedBox(width: 8),
                Text(l.documentOutlineTitle,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: entries.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        l.documentOutlineEmpty,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.darkOnSurface.withValues(alpha: 0.5)
                              : AppColors.lightOnSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return InkWell(
                        onTap: () {
                          provider.navigateToOffset(entry.offset);
                          _editorFocusNode.requestFocus();
                        },
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: 12.0 + (entry.level - 1) * 16.0,
                            right: 12,
                            top: 6,
                            bottom: 6,
                          ),
                          child: Text(
                            entry.title,
                            style: TextStyle(
                              fontSize: entry.level <= 2 ? 13 : 12,
                              fontWeight: entry.level <= 2
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: AppColors.documentBlue,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Find / Replace Bar
  // ---------------------------------------------------------------------------

  Widget _buildDocumentFindBar(DocumentProvider provider) {
    final l = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.grey800 : AppColors.grey300;
    final matchText = provider.searchQuery.isEmpty
        ? ''
        : provider.hasSearchResults
            ? l.findMatchCount(
                provider.searchIndex + 1, provider.searchResultCount)
            : l.findNoMatch;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        border: Border(bottom: BorderSide(color: border, width: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Find row ──
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: TextField(
                    controller: _findCtrl,
                    decoration: InputDecoration(
                      hintText: l.findHint,
                      isDense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    style: const TextStyle(fontSize: 13),
                    onSubmitted: (v) => provider.findAll(v),
                    onChanged: (v) {
                      if (v.isNotEmpty) provider.findAll(v);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 4),
              if (matchText.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(matchText,
                      style:
                          const TextStyle(fontSize: 12, color: AppColors.grey600)),
                ),
              IconButton(
                icon: const Icon(LucideIcons.chevronUp, size: 18),
                onPressed: provider.findPrev,
                tooltip: l.findTitle,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              IconButton(
                icon: const Icon(LucideIcons.chevronDown, size: 18),
                onPressed: provider.findNext,
                tooltip: l.findTitle,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              IconButton(
                icon: const Icon(LucideIcons.x, size: 18),
                onPressed: () => setState(() {
                  _showFindBar = false;
                  provider.clearSearch();
                  _findCtrl.clear();
                  _replaceCtrl.clear();
                }),
                tooltip: l.commonClose,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // ── Replace row ──
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: TextField(
                    controller: _replaceCtrl,
                    decoration: InputDecoration(
                      hintText: l.replaceHint,
                      isDense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              TextButton(
                onPressed: () => provider.replaceOne(_replaceCtrl.text),
                child: Text(l.replaceOne, style: const TextStyle(fontSize: 12)),
              ),
              TextButton(
                onPressed: () =>
                    provider.replaceAllMatches(_replaceCtrl.text),
                child:
                    Text(l.replaceAllBtn, style: const TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleBack(DocumentProvider provider) async {
    final l = AppLocalizations.of(context)!;
    if (provider.isDirty) {
      final result = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l.documentClose),
          content: Text(l.documentUnsavedChanges),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'discard'),
              child: Text(l.commonDoNotSave),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'cancel'),
              child: Text(l.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, 'save'),
              child: Text(l.commonSave),
            ),
          ],
        ),
      );
      if (result == 'save') {
        await _save(provider);
        if (mounted) Navigator.pop(context);
      } else if (result == 'discard') {
        if (mounted) Navigator.pop(context);
      }
    } else {
      Navigator.pop(context);
    }
  }
}
