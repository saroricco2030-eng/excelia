import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:excelia/l10n/app_localizations.dart';
import 'package:excelia/providers/app_provider.dart';
import 'package:excelia/screens/common/keyboard_shortcuts_dialog.dart';
import 'package:excelia/utils/snackbar_utils.dart';
import 'package:excelia/utils/file_utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:excelia/providers/presentation_provider.dart';
import 'package:excelia/screens/presentation/widgets/presenter_view.dart';
import 'package:excelia/screens/presentation/widgets/slide_canvas.dart';
import 'package:excelia/screens/presentation/widgets/slide_thumbnail.dart';
import 'package:excelia/screens/presentation/widgets/slideshow_element_builder.dart';
import 'package:excelia/utils/constants.dart';
import 'package:excelia/widgets/aurora_accent_bar.dart';

class PresentationScreen extends StatefulWidget {
  const PresentationScreen({super.key});

  @override
  State<PresentationScreen> createState() => _PresentationScreenState();
}

class _PresentationScreenState extends State<PresentationScreen> {
  bool _isEditingTitle = false;
  bool _showSlidePanel = true;
  bool _showFindBar = false;
  bool _showNotesPanel = false;
  bool _slideSorterMode = false;
  int _lastNotesSlideIndex = -1;
  late TextEditingController _titleController;
  final TextEditingController _findCtrl = TextEditingController();
  final TextEditingController _replaceCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();
  Timer? _autoSaveTimer;
  PresentationProvider? _presProvider;
  final FocusNode _keyboardFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _presProvider = context.read<PresentationProvider>();
    _presProvider!.addListener(_onProviderChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = _presProvider!;
      final arg = ModalRoute.of(context)?.settings.arguments as String?;
      if (arg != null && arg.startsWith('template:')) {
        provider.createNew();
        final templateType = arg.substring('template:'.length);
        provider.applyTemplate(templateType);
        _titleController.text = provider.title;
      } else if (arg != null) {
        try {
          await provider.loadFromFile(arg);
          _titleController.text = provider.title;
        } catch (e) {
          if (!mounted) return;
          final l = AppLocalizations.of(context)!;
          showExceliaSnackBar(context,
            message: l.presentationOpenError(e.toString()),
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
          provider.createNew();
          _titleController.text = provider.title;
        }
      } else {
        provider.createNew();
        _titleController.text = provider.title;
      }
    });
  }

  void _onProviderChanged() {
    _scheduleAutoSave();
  }

  void _scheduleAutoSave() {
    _autoSaveTimer?.cancel();
    final provider = _presProvider;
    if (provider == null || !provider.isDirty || provider.filePath == null) return;
    final appProv = context.read<AppProvider>();
    if (!appProv.autoSaveEnabled) return;
    _autoSaveTimer = Timer(const Duration(seconds: 30), () async {
      if (!mounted) return;
      final p = _presProvider;
      if (p == null || !p.isDirty || p.filePath == null) return;
      try {
        await p.saveToFile();
      } catch (e) {
        debugPrint('Presentation auto-save failed: $e');
      }
    });
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _presProvider?.removeListener(_onProviderChanged);
    _keyboardFocusNode.dispose();
    _titleController.dispose();
    _findCtrl.dispose();
    _replaceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrow = screenWidth < 600;
    final isWide = screenWidth > 900;

    return Consumer<PresentationProvider>(
      builder: (context, provider, _) {
        // Sync notes panel when slide index changes
        if (_showNotesPanel && provider.currentIndex != _lastNotesSlideIndex) {
          _lastNotesSlideIndex = provider.currentIndex;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _notesCtrl.text = provider.getSlideNotes(provider.currentIndex);
            }
          });
        }
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return KeyboardListener(
          focusNode: _keyboardFocusNode,
          autofocus: false,
          onKeyEvent: (event) {
            if (event is KeyDownEvent) {
              final ctrl = HardwareKeyboard.instance.isControlPressed;
              if (ctrl && event.logicalKey == LogicalKeyboardKey.keyS) {
                _save(provider);
              } else if (ctrl && event.logicalKey == LogicalKeyboardKey.keyZ) {
                provider.undo();
              } else if (ctrl && event.logicalKey == LogicalKeyboardKey.keyY) {
                provider.redo();
              } else if (ctrl && event.logicalKey == LogicalKeyboardKey.keyD) {
                final sel = provider.selectedElementId;
                if (sel != null) {
                  provider.duplicateElement(provider.currentIndex, sel);
                }
              } else if (event.logicalKey == LogicalKeyboardKey.delete) {
                final sel = provider.selectedElementId;
                if (sel != null) {
                  final slideIdx = provider.currentIndex;
                  final slide = provider.slides[slideIdx];
                  final elIdx = slide.elements.indexWhere((e) => e.id == sel);
                  final deleted = slide.elements.firstWhere((e) => e.id == sel);
                  provider.deleteElement(slideIdx, sel);
                  final l2 = AppLocalizations.of(context)!;
                  showExceliaSnackBar(
                    context,
                    message: l2.snackbarElementDeleted,
                    actionLabel: l2.commonUndo,
                    onAction: () => provider.insertElement(slideIdx, elIdx, deleted),
                  );
                }
              }
            }
          },
          child: Scaffold(
          backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
          appBar: _buildAppBar(provider),
          body: Column(
            children: [
              if (_showFindBar) _buildPresentationFindBar(provider),
              Expanded(
                child: Row(
                  children: [
                    // Left sidebar – slide thumbnails
                    if (_showSlidePanel && !isNarrow)
                      _buildSlidePanel(provider, panelWidth: isWide ? 220 : 180),

                    // Main canvas area or slide sorter grid
                    Expanded(
                      child: _slideSorterMode
                          ? _buildSlideSorterGrid(provider)
                          : _buildMainArea(provider),
                    ),

                    // Right sidebar – properties (show both panels on wide screens)
                    if ((provider.showPropertiesPanel || isWide) && !isNarrow)
                      _buildPropertiesPanel(provider),
                  ],
                ),
              ),
              if (_showNotesPanel)
                _buildInlineNotesPanel(provider),
              _buildBottomActionBar(provider),
              SafeArea(
                top: false, left: false, right: false,
                child: _buildBottomToolbar(provider),
              ),
            ],
          ),
          // On narrow screens, show slide panel as a drawer
          drawer: isNarrow
              ? Drawer(
                  child: SafeArea(
                    child: _buildSlidePanel(provider),
                  ),
                )
              : null,
          endDrawer: isNarrow
              ? Drawer(
                  child: SafeArea(
                    child: _buildPropertiesPanel(provider),
                  ),
                )
              : null,
        ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // AppBar
  // ---------------------------------------------------------------------------

  PreferredSizeWidget _buildAppBar(PresentationProvider provider) {
    final l = AppLocalizations.of(context)!;
    final isNarrow = MediaQuery.of(context).size.width < 600;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppBar(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      foregroundColor: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(2),
        child: AuroraAccentBar(
          colors: [
            AppColors.presentationOrange,
            AppColors.auroraAmber,
            AppColors.auroraPink,
            AppColors.primary,
            AppColors.presentationOrange,
          ],
        ),
      ),
      leading: IconButton(
        icon: const Icon(LucideIcons.arrowLeft),
        onPressed: () => Navigator.pop(context),
        tooltip: l.commonBack,
      ),
      title: _isEditingTitle
          ? TextField(
              controller: _titleController,
              autofocus: true,
              style: TextStyle(
                  color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w500),
              decoration: const InputDecoration(
                border: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              onSubmitted: (v) {
                provider.setTitle(v);
                setState(() => _isEditingTitle = false);
              },
              onTapOutside: (_) {
                provider.setTitle(_titleController.text);
                setState(() => _isEditingTitle = false);
              },
            )
          : Semantics(
              button: true,
              label: l.a11yEditTitle,
              child: GestureDetector(
                onTap: () {
                  _titleController.text = provider.title;
                  setState(() => _isEditingTitle = true);
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(provider.title,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 18))
                          .animate(
                            onPlay: (c) => c.repeat(
                              period: const Duration(seconds: 5),
                            ),
                          )
                          .shimmer(
                            duration: 1600.ms,
                            color: AppColors.presentationOrange
                                .withValues(alpha: 0.55),
                          ),
                    ),
                    if (provider.isDirty) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                            color: AppColors.warningAccent,
                            shape: BoxShape.circle),
                      ),
                    ],
                    const SizedBox(width: 4),
                    Icon(LucideIcons.pencil, size: 14,
                        color: (isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface).withValues(alpha: 0.5)),
                  ],
                ),
              ),
            ),
      actions: [
        IconButton(
          icon: const Icon(LucideIcons.save),
          onPressed: () => _save(provider),
          tooltip: l.commonSave,
        ),
        if (isNarrow)
          IconButton(
            icon: const Icon(LucideIcons.layoutGrid),
            onPressed: () => Scaffold.of(context).openDrawer(),
            tooltip: l.presentationSlideList,
          ),
        PopupMenuButton<String>(
          icon: const Icon(LucideIcons.moreVertical),
          tooltip: l.commonMore,
          onSelected: (v) => _handleMenu(v, provider),
          itemBuilder: (_) => [
            PopupMenuItem(
                value: 'open',
                child: ListTile(
                    leading: const Icon(LucideIcons.folderOpen),
                    title: Text(l.fileOpen),
                    dense: true,
                    contentPadding: EdgeInsets.zero)),
            PopupMenuItem(
                value: 'new',
                child: ListTile(
                    leading: const Icon(LucideIcons.filePlus),
                    title: Text(l.newPresentation),
                    dense: true,
                    contentPadding: EdgeInsets.zero)),
            PopupMenuItem(
                value: 'grid',
                child: ListTile(
                    leading: const Icon(LucideIcons.grid),
                    title: Text(l.presentationGridSnap),
                    dense: true,
                    contentPadding: EdgeInsets.zero)),
            if (!isNarrow)
              PopupMenuItem(
                  value: 'toggleSlides',
                  child: ListTile(
                      leading: const Icon(LucideIcons.layoutGrid),
                      title: Text(l.presentationSlidePanel),
                      dense: true,
                      contentPadding: EdgeInsets.zero)),
            PopupMenuItem(
                value: 'open_pptx',
                child: ListTile(
                    leading: const Icon(LucideIcons.fileInput),
                    title: Text(l.pptxOpen),
                    dense: true,
                    contentPadding: EdgeInsets.zero)),
            PopupMenuItem(
                value: 'save_pptx',
                child: ListTile(
                    leading: const Icon(LucideIcons.fileOutput),
                    title: Text(l.pptxSave),
                    dense: true,
                    contentPadding: EdgeInsets.zero)),
            const PopupMenuDivider(),
            PopupMenuItem(
                value: 'transition',
                child: ListTile(
                    leading: const Icon(LucideIcons.repeat),
                    title: Text(l.slideTransition),
                    dense: true,
                    contentPadding: EdgeInsets.zero)),
            PopupMenuItem(
                value: 'notes',
                child: ListTile(
                    leading: const Icon(LucideIcons.stickyNote),
                    title: Text(l.speakerNotes),
                    dense: true,
                    contentPadding: EdgeInsets.zero)),
            PopupMenuItem(
                value: 'presenter_view',
                child: ListTile(
                    leading: const Icon(LucideIcons.monitor),
                    title: Text(l.presenterView),
                    dense: true,
                    contentPadding: EdgeInsets.zero)),
            PopupMenuItem(
                value: 'slide_sorter',
                child: ListTile(
                    leading: Icon(LucideIcons.grid),
                    title: Text(l.slideSorter),
                    dense: true,
                    contentPadding: EdgeInsets.zero)),
            PopupMenuItem(
                value: 'template',
                child: ListTile(
                    leading: const Icon(LucideIcons.layout),
                    title: Text(l.slideTemplate),
                    dense: true,
                    contentPadding: EdgeInsets.zero)),
            const PopupMenuDivider(),
            PopupMenuItem(
                value: 'shortcuts',
                child: ListTile(
                    leading: const Icon(LucideIcons.keyboard),
                    title: Text(l.keyboardShortcuts),
                    dense: true,
                    contentPadding: EdgeInsets.zero)),
            const PopupMenuDivider(),
            PopupMenuItem(
                value: 'print_preview',
                child: ListTile(
                    leading: const Icon(LucideIcons.eye),
                    title: Text(l.presentationPrintPreview),
                    dense: true,
                    contentPadding: EdgeInsets.zero)),
            PopupMenuItem(
                value: 'print',
                child: ListTile(
                    leading: const Icon(LucideIcons.printer),
                    title: Text(l.presentationPrint),
                    dense: true,
                    contentPadding: EdgeInsets.zero)),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Find & Replace bar
  // ---------------------------------------------------------------------------

  Widget _buildPresentationFindBar(PresentationProvider provider) {
    final l = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final matchText = provider.searchResultCount == 0
        ? (provider.searchQuery.isNotEmpty ? l.findNoMatch : '')
        : l.findMatchCount(provider.searchIndex + 1, provider.searchResultCount);
    return Container(
      color: isDark ? AppColors.darkSurfaceElevated : AppColors.grey100,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 찾기 행
          Row(
            children: [
              const Icon(LucideIcons.search, size: 18, color: AppColors.grey600),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 32,
                  child: TextField(
                    controller: _findCtrl,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: l.findHint,
                      hintStyle: const TextStyle(fontSize: 13, color: AppColors.grey500),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                      isDense: true,
                    ),
                    onChanged: (v) => provider.findAll(v),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              if (matchText.isNotEmpty)
                Text(matchText, style: const TextStyle(fontSize: 11, color: AppColors.grey600)),
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
          // 바꾸기 행
          Row(
            children: [
              const Icon(LucideIcons.replace, size: 18, color: AppColors.grey600),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 32,
                  child: TextField(
                    controller: _replaceCtrl,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: l.replaceHint,
                      hintStyle: const TextStyle(fontSize: 13, color: AppColors.grey500),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                      isDense: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              TextButton(
                onPressed: () => provider.replaceOne(_replaceCtrl.text),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 32),
                ),
                child: Text(l.replaceOne, style: const TextStyle(fontSize: 12)),
              ),
              TextButton(
                onPressed: () => provider.replaceAllMatches(_replaceCtrl.text),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 32),
                ),
                child: Text(l.replaceAllBtn, style: const TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Slide thumbnail panel (left)
  // ---------------------------------------------------------------------------

  Widget _buildSlidePanel(PresentationProvider provider, {double panelWidth = 180}) {
    final l = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: panelWidth,
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
        children: [
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: provider.slides.length,
              onReorder: (from, to) {
                if (to > from) to--;
                provider.reorderSlide(from, to);
              },
              itemBuilder: (context, index) {
                return SlideThumbnail(
                  key: ValueKey(provider.slides[index].id),
                  slide: provider.slides[index],
                  index: index,
                  isSelected: index == provider.currentIndex,
                  onTap: () => provider.setCurrentSlide(index),
                  onDuplicate: () => provider.duplicateSlide(index),
                  onDelete: provider.slides.length > 1
                      ? () {
                          final deleted = provider.slides[index];
                          provider.deleteSlide(index);
                          final l2 = AppLocalizations.of(context)!;
                          showExceliaSnackBar(
                            context,
                            message: l2.snackbarSlideDeleted,
                            actionLabel: l2.commonUndo,
                            onAction: () => provider.insertSlide(index, deleted),
                          );
                        }
                      : null,
                  onMoveUp: index > 0
                      ? () => provider.reorderSlide(index, index - 1)
                      : null,
                  onMoveDown: index < provider.slides.length - 1
                      ? () => provider.reorderSlide(index, index + 1)
                      : null,
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: provider.addSlide,
                icon: const Icon(LucideIcons.plus, size: 18),
                label: Text(l.presentationAddSlide),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.presentationOrange,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  textStyle: const TextStyle(fontSize: 13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Main canvas area
  // ---------------------------------------------------------------------------

  Widget _buildMainArea(PresentationProvider provider) {
    final l = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (provider.currentSlide == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.presentation,
                size: 64, color: AppColors.presentationOrange.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(l.presentationEmptyTitle,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface)),
            const SizedBox(height: 8),
            Text(l.presentationEmptyHint,
                style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppColors.darkOnSurfaceAlt : AppColors.grey600)),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: provider.addSlide,
              icon: const Icon(LucideIcons.plus, size: 18),
              label: Text(l.presentationAddSlide),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.presentationOrange,
              ),
            ),
          ],
        ),
      );
    }
    return GestureDetector(
      onTap: () => provider.selectElement(null),
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        padding: const EdgeInsets.all(24),
        child: Center(
          child: SlideCanvas(
            slide: provider.currentSlide!,
            selectedElementId: provider.selectedElementId,
            gridSnap: provider.gridSnap,
            onSelectElement: provider.selectElement,
            onMoveElement: provider.moveElement,
            onResizeElement: provider.resizeElement,
            onEditText: (elementId, newText) {
              provider.updateElement(
                provider.currentIndex,
                elementId,
                (el) => el.copyWith(content: newText),
              );
            },
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Slide sorter grid
  // ---------------------------------------------------------------------------

  Widget _buildSlideSorterGrid(PresentationProvider provider) {
    final l = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWide = MediaQuery.of(context).size.width > 900;
    final slides = provider.slides;
    if (slides.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.layoutGrid,
                size: 48, color: AppColors.presentationOrange.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(l.presentationEmptyTitle,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface)),
            const SizedBox(height: 8),
            Text(l.presentationEmptyHint,
                style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.darkOnSurfaceAlt : AppColors.grey600)),
          ],
        ),
      );
    }
    return Container(
      color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              l.slideSorterHint,
              style: TextStyle(
                color: AppColors.grey500,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isWide ? 4 : 3,
                childAspectRatio: 16 / 9,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemCount: slides.length,
              itemBuilder: (context, idx) {
                final slide = slides[idx];
                final isCurrent = idx == provider.currentIndex;
                return GestureDetector(
                  onTap: () {
                    provider.setCurrentSlide(idx);
                    setState(() => _slideSorterMode = false);
                  },
                  onLongPress: () =>
                      _showSlideSorterContextMenu(context, provider, idx),
                  child: Container(
                    decoration: BoxDecoration(
                      color: slide.backgroundColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isCurrent
                            ? AppColors.presentationOrange
                            : AppColors.grey300,
                        width: isCurrent ? 3 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        // Slide content preview
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final scaleX = constraints.maxWidth / 960;
                            final scaleY = constraints.maxHeight / 540;
                            return Stack(
                              children: slide.elements.map((el) {
                                return Positioned(
                                  left: el.x * scaleX,
                                  top: el.y * scaleY,
                                  width: el.width * scaleX,
                                  height: el.height * scaleY,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.topLeft,
                                    child: buildSlideshowElement(el),
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                        // Slide number badge
                        Positioned(
                          right: 4,
                          bottom: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.black.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${idx + 1}',
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
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

  void _showSlideSorterContextMenu(
    BuildContext context,
    PresentationProvider provider,
    int index,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        final l = AppLocalizations.of(ctx)!;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(LucideIcons.copy),
                title: Text(l.presentationDuplicate),
                onTap: () {
                  Navigator.of(ctx).pop();
                  provider.duplicateSlide(index);
                },
              ),
              ListTile(
                leading: const Icon(LucideIcons.trash2),
                title: Text(l.presentationDeleteSlide),
                onTap: () {
                  Navigator.of(ctx).pop();
                  final deleted = provider.slides[index];
                  provider.deleteSlide(index);
                  showExceliaSnackBar(
                    context,
                    message: l.snackbarSlideDeleted,
                    actionLabel: l.commonUndo,
                    onAction: () => provider.insertSlide(index, deleted),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Properties panel (right)
  // ---------------------------------------------------------------------------

  Widget _buildPropertiesPanel(PresentationProvider provider) {
    final l = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final el = provider.selectedElement;
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          left: BorderSide(
            color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
            width: isDark ? 0.5 : 1,
          ),
        ),
      ),
      child: el == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  l.presentationSelectElement,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.grey600, fontSize: 13),
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(l.presentationElementProps,
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 16),

                // Position
                _propLabel(l.presentationPosition),
                Row(
                  children: [
                    Expanded(
                        child: _propField('X', el.x, (v) {
                      provider.updateElement(provider.currentIndex,
                          el.id, (e) => e.copyWith(x: v));
                    })),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _propField('Y', el.y, (v) {
                      provider.updateElement(provider.currentIndex,
                          el.id, (e) => e.copyWith(y: v));
                    })),
                  ],
                ),
                const SizedBox(height: 12),

                // Size
                _propLabel(l.presentationSize),
                Row(
                  children: [
                    Expanded(
                        child: _propField('W', el.width, (v) {
                      provider.updateElement(provider.currentIndex,
                          el.id, (e) => e.copyWith(width: v));
                    })),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _propField('H', el.height, (v) {
                      provider.updateElement(provider.currentIndex,
                          el.id, (e) => e.copyWith(height: v));
                    })),
                  ],
                ),
                const SizedBox(height: 12),

                if (el.type == SlideElementType.text) ...[
                  _propLabel(l.presentationFontSize),
                  Slider(
                    value: el.fontSize.clamp(8, 96),
                    min: 8,
                    max: 96,
                    divisions: 88,
                    label: '${el.fontSize.round()}',
                    onChanged: (v) {
                      provider.updateElement(provider.currentIndex,
                          el.id, (e) => e.copyWith(fontSize: v));
                    },
                  ),
                  const SizedBox(height: 8),
                  _propLabel(l.presentationBold),
                  Switch(
                    value: el.fontWeight == FontWeight.bold,
                    onChanged: (v) {
                      provider.updateElement(
                        provider.currentIndex,
                        el.id,
                        (e) => e.copyWith(
                            fontWeight:
                                v ? FontWeight.bold : FontWeight.normal),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  _propLabel(l.presentationItalic),
                  Switch(
                    value: el.italic,
                    onChanged: (v) {
                      provider.updateElement(
                        provider.currentIndex,
                        el.id,
                        (e) => e.copyWith(italic: v),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  _propLabel(l.presentationUnderline),
                  Switch(
                    value: el.underline,
                    onChanged: (v) {
                      provider.updateElement(
                        provider.currentIndex,
                        el.id,
                        (e) => e.copyWith(underline: v),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  _propLabel(l.presentationStrikethrough),
                  Switch(
                    value: el.strikethrough,
                    onChanged: (v) {
                      provider.updateElement(
                        provider.currentIndex,
                        el.id,
                        (e) => e.copyWith(strikethrough: v),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  _propLabel(l.presentationFontFamily),
                  DropdownButtonFormField<String?>(
                    initialValue: el.fontFamily,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      isDense: true,
                    ),
                    items: [
                      DropdownMenuItem(value: null, child: Text(l.presentationFontSystem)),
                      const DropdownMenuItem(value: 'NotoSansKR', child: Text('Noto Sans KR')),
                      const DropdownMenuItem(value: 'Roboto', child: Text('Roboto')),
                      const DropdownMenuItem(value: 'JetBrains Mono', child: Text('JetBrains Mono')),
                      const DropdownMenuItem(value: 'Serif', child: Text('Serif')),
                    ],
                    onChanged: (v) {
                      provider.updateElement(
                        provider.currentIndex,
                        el.id,
                        (e) => e.copyWith(fontFamily: v),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  _propLabel(l.presentationAlignment),
                  SegmentedButton<TextAlign>(
                    segments: const [
                      ButtonSegment(
                          value: TextAlign.left,
                          icon: Icon(LucideIcons.alignLeft, size: 18)),
                      ButtonSegment(
                          value: TextAlign.center,
                          icon:
                              Icon(LucideIcons.alignCenter, size: 18)),
                      ButtonSegment(
                          value: TextAlign.right,
                          icon:
                              Icon(LucideIcons.alignRight, size: 18)),
                    ],
                    selected: {el.textAlign},
                    onSelectionChanged: (v) {
                      provider.updateElement(provider.currentIndex,
                          el.id, (e) => e.copyWith(textAlign: v.first));
                    },
                  ),
                ],

                const SizedBox(height: 12),
                _propLabel(l.presentationTextColor),
                _colorRow(el.color, (c) {
                  provider.updateElement(provider.currentIndex, el.id,
                      (e) => e.copyWith(color: c));
                }),

                const SizedBox(height: 12),
                _propLabel(l.presentationBackgroundColor),
                _colorRow(el.backgroundColor ?? AppColors.transparent, (c) {
                  provider.updateElement(provider.currentIndex, el.id,
                      (e) => e.copyWith(backgroundColor: c));
                }),

                const SizedBox(height: 16),
                _propLabel(l.presentationZOrder),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _zOrderBtn(LucideIcons.arrowDownToLine,
                        l.presentationSendToBack, () {
                      provider.sendToBack(provider.currentIndex, el.id);
                    }),
                    _zOrderBtn(LucideIcons.arrowDown,
                        l.presentationSendBackward, () {
                      provider.sendBackward(provider.currentIndex, el.id);
                    }),
                    _zOrderBtn(LucideIcons.arrowUp,
                        l.presentationBringForward, () {
                      provider.bringForward(provider.currentIndex, el.id);
                    }),
                    _zOrderBtn(LucideIcons.arrowUpToLine,
                        l.presentationBringToFront, () {
                      provider.bringToFront(provider.currentIndex, el.id);
                    }),
                    _zOrderBtn(LucideIcons.copy,
                        l.presentationDuplicateElement, () {
                      provider.duplicateElement(provider.currentIndex, el.id);
                    }),
                  ],
                ),

                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () {
                    final slideIdx = provider.currentIndex;
                    final elIdx = provider.slides[slideIdx].elements
                        .indexWhere((e) => e.id == el.id);
                    final deleted = el;
                    provider.deleteElement(slideIdx, el.id);
                    showExceliaSnackBar(
                      context,
                      message: l.snackbarElementDeleted,
                      actionLabel: l.commonUndo,
                      onAction: () => provider.insertElement(
                          slideIdx, elIdx, deleted),
                    );
                  },
                  icon: const Icon(LucideIcons.trash2, size: 18),
                  label: Text(l.presentationDeleteElement),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error),
                ),
              ],
            ),
    );
  }

  Widget _propLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(text,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.grey600)),
      );

  Widget _zOrderBtn(IconData icon, String tooltip, VoidCallback onTap) {
    return Expanded(
      child: IconButton(
        icon: Icon(icon, size: 18),
        tooltip: tooltip,
        onPressed: onTap,
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      ),
    );
  }

  Widget _propField(
      String label, double value, ValueChanged<double> onChanged) {
    final ctrl =
        TextEditingController(text: value.toStringAsFixed(0));
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
      style: const TextStyle(fontSize: 13),
      onSubmitted: (v) {
        final parsed = double.tryParse(v);
        if (parsed != null) onChanged(parsed);
      },
    );
  }

  Widget _colorRow(Color current, ValueChanged<Color> onPick) {
    final l = AppLocalizations.of(context)!;
    const presets = [
      AppColors.black,
      AppColors.white,
      AppColors.red,
      AppColors.orange,
      AppColors.amber,
      AppColors.green,
      AppColors.blue,
      AppColors.indigo,
      AppColors.purple,
      AppColors.grey500,
    ];
    const presetNames = [
      'Black', 'White', 'Red', 'Orange', 'Amber',
      'Green', 'Blue', 'Indigo', 'Purple', 'Grey',
    ];
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: List.generate(presets.length, (i) {
        final c = presets[i];
        final selected = c.toARGB32() == current.toARGB32();
        return Semantics(
          button: true,
          label: l.a11yColorSwatch(presetNames[i]),
          child: GestureDetector(
            onTap: () => onPick(c),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? AppColors.presentationOrange
                      : AppColors.grey300,
                  width: selected ? 2.5 : 1,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom toolbar
  // ---------------------------------------------------------------------------

  Widget _buildBottomActionBar(PresentationProvider provider) {
    final l = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isNarrow = MediaQuery.of(context).size.width < 600;
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
            icon: Icon(LucideIcons.undo2, size: 20,
              color: provider.canUndo ? null : (isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface).withValues(alpha: 0.3)),
            onPressed: provider.canUndo ? provider.undo : null,
            tooltip: l.commonUndo,
          ),
          IconButton(
            icon: Icon(LucideIcons.redo2, size: 20,
              color: provider.canRedo ? null : (isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface).withValues(alpha: 0.3)),
            onPressed: provider.canRedo ? provider.redo : null,
            tooltip: l.commonRedo,
          ),
          const Spacer(),
          IconButton(
            icon: Icon(LucideIcons.search, size: 20,
              color: _showFindBar ? AppColors.presentationOrange : null),
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
            icon: const Icon(LucideIcons.play, size: 20),
            onPressed: () => _startSlideshow(provider),
            tooltip: l.presentationSlideshow,
          ),
          if (!isNarrow)
            IconButton(
              icon: Icon(
                _showSlidePanel ? LucideIcons.panelLeftClose : LucideIcons.panelLeftOpen,
                size: 20,
                color: _showSlidePanel ? AppColors.presentationOrange : null,
              ),
              onPressed: () => setState(() => _showSlidePanel = !_showSlidePanel),
              tooltip: l.presentationSlidePanel,
            ),
          IconButton(
            icon: Icon(LucideIcons.stickyNote, size: 20,
              color: _showNotesPanel ? AppColors.presentationOrange : null),
            onPressed: () {
              setState(() => _showNotesPanel = !_showNotesPanel);
              if (_showNotesPanel) {
                final notes = provider.getSlideNotes(provider.currentIndex);
                _notesCtrl.text = notes;
              }
            },
            tooltip: l.speakerNotes,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomToolbar(PresentationProvider provider) {
    final l = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: isDark ? Color(0xCC161618) : Color(0xF2FFFFFF),
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
            width: isDark ? 0.5 : 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _toolBtn(LucideIcons.type, l.presentationText, () {
              provider.addElement(
                provider.currentIndex,
                SlideElement(
                  type: SlideElementType.text,
                  x: 100,
                  y: 200,
                  width: 300,
                  height: 60,
                  content: l.presentationDefaultText,
                  fontSize: 20,
                ),
              );
            }),
            const SizedBox(width: 4),

            // Shape submenu
            PopupMenuButton<ShapeKind>(
              tooltip: l.presentationInsertShape,
              onSelected: (kind) => _insertShape(provider, kind),
              itemBuilder: (_) => [
                PopupMenuItem(
                    value: ShapeKind.rectangle,
                    child: ListTile(
                        leading: const Icon(LucideIcons.square),
                        title: Text(l.presentationRectangle),
                        dense: true,
                        contentPadding: EdgeInsets.zero)),
                PopupMenuItem(
                    value: ShapeKind.circle,
                    child: ListTile(
                        leading: const Icon(LucideIcons.circle),
                        title: Text(l.presentationCircle),
                        dense: true,
                        contentPadding: EdgeInsets.zero)),
                PopupMenuItem(
                    value: ShapeKind.triangle,
                    child: ListTile(
                        leading: const Icon(LucideIcons.triangle),
                        title: Text(l.presentationTriangle),
                        dense: true,
                        contentPadding: EdgeInsets.zero)),
                PopupMenuItem(
                    value: ShapeKind.arrow,
                    child: ListTile(
                        leading: const Icon(LucideIcons.arrowRight),
                        title: Text(l.presentationArrow),
                        dense: true,
                        contentPadding: EdgeInsets.zero)),
              ],
              child: _toolChip(LucideIcons.shapes, l.presentationShape),
            ),
            const SizedBox(width: 4),
            _toolBtn(LucideIcons.image, l.presentationImage, () => _insertImage(provider)),
            const SizedBox(width: 4),
            _toolBtn(LucideIcons.paintBucket, l.presentationBgColorShort, () => _pickBackground(provider)),
            const SizedBox(width: 16),

            // Slide counter
            Text(
              '${provider.currentIndex + 1} / ${provider.slides.length}',
              style: const TextStyle(
                  fontSize: 13, color: AppColors.grey600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toolBtn(IconData icon, String tooltip, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: AppColors.grey800),
              const SizedBox(width: 4),
              Text(tooltip,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.grey800)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toolChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: AppColors.grey800),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.grey800)),
          const Icon(LucideIcons.chevronDown,
              size: 16, color: AppColors.grey600),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  void _insertShape(PresentationProvider provider, ShapeKind kind) {
    Color bg;
    switch (kind) {
      case ShapeKind.rectangle:
        bg = AppColors.shapeBlue;
      case ShapeKind.circle:
        bg = AppColors.shapeGreen;
      case ShapeKind.triangle:
        bg = AppColors.shapeOrange;
      case ShapeKind.arrow:
        bg = AppColors.shapeGrey;
      case ShapeKind.star:
        bg = AppColors.warning;
      case ShapeKind.hexagon:
        bg = AppColors.purple;
      case ShapeKind.diamond:
        bg = AppColors.info;
      case ShapeKind.pentagon:
        bg = AppColors.success;
    }
    provider.addElement(
      provider.currentIndex,
      SlideElement(
        type: SlideElementType.shape,
        x: 160,
        y: 160,
        width: 160,
        height: 120,
        shapeKind: kind,
        backgroundColor: bg,
        color: AppColors.black.withValues(alpha: 0.54),
      ),
    );
  }

  Future<void> _insertImage(PresentationProvider provider) async {
    final l = AppLocalizations.of(context)!;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      dialogTitle: l.documentSelectImage,
    );
    if (result != null && result.files.single.path != null) {
      provider.addElement(
        provider.currentIndex,
        SlideElement(
          type: SlideElementType.image,
          x: 120,
          y: 100,
          width: 320,
          height: 240,
          content: result.files.single.path!,
        ),
      );
    }
  }

  void _pickBackground(PresentationProvider provider) {
    const colors = AppColors.slideBackgrounds;
    showDialog(
      context: context,
      builder: (ctx) {
        final l = AppLocalizations.of(ctx)!;
        return AlertDialog(
          title: Text(l.presentationBgColor),
          content: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: colors.map((c) {
              return GestureDetector(
                onTap: () {
                  provider.setSlideBackground(provider.currentIndex, c);
                  Navigator.pop(ctx);
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.grey300),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Future<void> _save(PresentationProvider provider) async {
    final l = AppLocalizations.of(context)!;
    try {
      String? path = provider.filePath;
      if (path == null) {
        try {
          path = await FilePicker.platform.saveFile(
            dialogTitle: l.presentationSaveTitle,
            fileName: '${provider.title}.expres',
            allowedExtensions: ['expres'],
            type: FileType.custom,
          );
        } catch (e) {
          debugPrint('Presentation saveFile picker failed: $e');
        }
        // Fallback for mobile platforms
        if (path == null && (Platform.isAndroid || Platform.isIOS)) {
          final dir = await getApplicationDocumentsDirectory();
          final sanitized =
              provider.title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
          path = '${dir.path}${Platform.pathSeparator}$sanitized.expres';
        }
        if (path == null) return;
      }
      await provider.saveToFile(path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.presentationSaved)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.presentationSaveError(e.toString()))),
        );
      }
    }
  }

  void _startSlideshow(PresentationProvider provider) {
    if (provider.slides.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _SlideshowScreen(slides: provider.slides),
      ),
    );
  }

  Future<void> _handleMenu(
      String action, PresentationProvider provider) async {
    final l = AppLocalizations.of(context)!;
    switch (action) {
      case 'open':
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['expres'],
          dialogTitle: l.presentationOpenTitle,
        );
        if (result != null && result.files.single.path != null) {
          await provider.loadFromFile(result.files.single.path!);
        }
      case 'new':
        provider.createNew();
      case 'grid':
        provider.toggleGridSnap();
      case 'toggleSlides':
        setState(() => _showSlidePanel = !_showSlidePanel);
      case 'open_pptx':
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pptx'],
          dialogTitle: l.pptxOpen,
        );
        if (result != null && result.files.single.path != null) {
          try {
            await provider.loadPptx(result.files.single.path!);
            _titleController.text = provider.title;
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l.presentationPptxLoaded)),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l.presentationPptxError(e.toString()))),
              );
            }
          }
        }
      case 'save_pptx':
        try {
          final path = await provider.savePptx();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l.presentationPptxSaved(path))),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l.presentationPptxError(e.toString()))),
            );
          }
        }
      case 'transition':
        _showTransitionPicker(provider);
      case 'notes':
        _showNotesBottomSheet(provider);
      case 'presenter_view':
        if (provider.slides.isNotEmpty) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PresenterView(
                slides: provider.slides,
                startIndex: provider.currentIndex,
              ),
            ),
          );
        }
      case 'slide_sorter':
        setState(() => _slideSorterMode = !_slideSorterMode);
      case 'template':
        _showTemplatePicker(provider);
      case 'shortcuts':
        showKeyboardShortcutsDialog(context, 'presentation');
      case 'print_preview':
        _showPrintPreview(provider);
      case 'print':
        _printPresentation(provider);
    }
  }

  void _showTransitionPicker(PresentationProvider provider) {
    final slide = provider.currentSlide;
    if (slide == null) return;

    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        final sl = AppLocalizations.of(ctx)!;
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom +
                  MediaQuery.of(ctx).viewPadding.bottom + 16,
              top: 16, left: 16, right: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sl.slideTransition,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: SlideTransitionType.values.map((t) {
                    final isSelected = slide.transition == t;
                    return ChoiceChip(
                      label: Text(_transitionLabel(t, sl)),
                      selected: isSelected,
                      onSelected: (_) {
                        provider.setSlideTransition(provider.currentIndex, t);
                        Navigator.pop(ctx);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  String _transitionLabel(SlideTransitionType t, AppLocalizations l) {
    switch (t) {
      case SlideTransitionType.none:
        return l.transitionNone;
      case SlideTransitionType.fade:
        return l.transitionFade;
      case SlideTransitionType.push:
        return l.transitionPush;
      case SlideTransitionType.wipe:
        return l.transitionWipe;
      case SlideTransitionType.zoom:
        return l.transitionZoom;
    }
  }

  void _showNotesBottomSheet(PresentationProvider provider) {
    final notes = provider.getSlideNotes(provider.currentIndex);
    final ctrl = TextEditingController(text: notes);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final sl = AppLocalizations.of(ctx)!;
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom +
                  MediaQuery.of(ctx).viewPadding.bottom + 16,
              top: 16, left: 16, right: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(sl.speakerNotes,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () {
                        provider.setSlideNotes(provider.currentIndex, ctrl.text);
                        Navigator.pop(ctx);
                      },
                      child: Text(sl.commonSave),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: ctrl,
                  maxLines: 6,
                  decoration: InputDecoration(
                    hintText: sl.speakerNotesHint,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Inline Notes Panel (bottom of canvas)
  // ---------------------------------------------------------------------------

  Widget _buildInlineNotesPanel(PresentationProvider provider) {
    final l = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? AppColors.darkOnSurfaceAlt : AppColors.grey600;
    // Sync notes controller when slide changes
    // Notes are synced from build via _syncNotesIfNeeded()
    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurfaceElevated,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
            width: isDark ? 0.5 : 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.stickyNote, size: 14, color: labelColor),
              const SizedBox(width: 4),
              Text(l.speakerNotes,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: labelColor)),
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            child: TextField(
              controller: _notesCtrl,
              maxLines: null,
              expands: true,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: l.speakerNotesHint,
                hintStyle: const TextStyle(fontSize: 13, color: AppColors.grey500),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                isDense: true,
              ),
              onChanged: (text) {
                provider.setSlideNotes(provider.currentIndex, text);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showTemplatePicker(PresentationProvider provider) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        final sl = AppLocalizations.of(ctx)!;
        final templates = [
          ('title', sl.templateTitle, LucideIcons.type),
          ('titleBody', sl.templateTitleBody, LucideIcons.alignLeft),
          ('twoColumn', sl.templateTwoColumn, LucideIcons.columns),
          ('section', sl.templateSection, LucideIcons.hash),
        ];
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewPadding.bottom + 16,
              top: 16, left: 16, right: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sl.slideTemplate,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 2.5,
                  children: templates.map((t) {
                    return InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        provider.addSlideFromTemplate(t.$1);
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.grey300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(t.$3, size: 24, color: AppColors.presentationOrange),
                            const SizedBox(height: 4),
                            Text(t.$2, style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  pw.Font? _krFont;
  pw.Font? _krFontBold;

  Future<pw.Document> _buildSlidePdf(PresentationProvider provider) async {
    final l = AppLocalizations.of(context)!;
    if (_krFont == null) {
      final fontData = await rootBundle.load('assets/fonts/NotoSansKR.ttf');
      _krFont = pw.Font.ttf(fontData);
      _krFontBold = _krFont;
    }
    final pdf = pw.Document();
    for (final slide in provider.slides) {
      pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context ctx) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              color: PdfColor.fromInt(slide.backgroundColor.toARGB32()),
              border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
            ),
            width: double.infinity,
            height: double.infinity,
            child: pw.Stack(
              children: slide.elements.map((el) {
                // 960x540 슬라이드 → A4 가로(약 770x520) 비율 조정
                final scaleX = (PdfPageFormat.a4.landscape.availableWidth - 64) / 960;
                final scaleY = (PdfPageFormat.a4.landscape.availableHeight - 64) / 540;

                return pw.Positioned(
                  left: el.x * scaleX,
                  top: el.y * scaleY,
                  child: pw.SizedBox(
                    width: el.width * scaleX,
                    height: el.height * scaleY,
                    child: _buildPdfElement(el, scaleX, l),
                  ),
                );
              }).toList(),
            ),
          );
        },
      ));
    }
    if (provider.slides.isEmpty) {
      pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (_) => pw.Center(child: pw.Text(l.presentationNoSlides,
            style: pw.TextStyle(font: _krFont))),
      ));
    }
    return pdf;
  }

  pw.Widget _buildPdfElement(SlideElement el, double scale, AppLocalizations l) {
    switch (el.type) {
      case SlideElementType.text:
        pw.TextAlign align;
        switch (el.textAlign) {
          case TextAlign.center:
            align = pw.TextAlign.center;
          case TextAlign.right:
            align = pw.TextAlign.right;
          default:
            align = pw.TextAlign.left;
        }
        return pw.Text(
          el.content,
          style: pw.TextStyle(
            font: (el.fontWeight == FontWeight.bold) ? _krFontBold : _krFont,
            fontBold: _krFontBold,
            fontSize: el.fontSize * scale,
            fontWeight: el.fontWeight == FontWeight.bold
                ? pw.FontWeight.bold
                : pw.FontWeight.normal,
            color: PdfColor.fromInt(el.color.toARGB32()),
          ),
          textAlign: align,
        );
      case SlideElementType.shape:
        return pw.Container(
          decoration: pw.BoxDecoration(
            color: PdfColor.fromInt(
                (el.backgroundColor ?? AppColors.shapeBlue).toARGB32()),
            border: pw.Border.all(
                color: PdfColor.fromInt(el.color.toARGB32()), width: 1),
          ),
        );
      case SlideElementType.image:
        return pw.Container(
          color: PdfColors.grey200,
          child: pw.Center(
            child: pw.Text(l.presentationImagePlaceholder, style: pw.TextStyle(font: _krFont, fontSize: 10)),
          ),
        );
    }
  }

  void _showPrintPreview(PresentationProvider provider) async {
    final l = AppLocalizations.of(context)!;
    final pdf = await _buildSlidePdf(provider);
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: Text(l.presentationPrintPreviewTitle(provider.title)),
          ),
          body: PdfPreview(
            build: (_) => pdf.save(),
            canChangeOrientation: true,
            canChangePageFormat: true,
            canDebug: false,
          ),
        ),
      ),
    );
  }

  Future<void> _printPresentation(PresentationProvider provider) async {
    final pdf = await _buildSlidePdf(provider);
    await Printing.layoutPdf(
      onLayout: (_) => pdf.save(),
      name: provider.title,
    );
  }
}

// =============================================================================
// Full-screen slideshow
// =============================================================================

class _SlideshowScreen extends StatefulWidget {
  final List<Slide> slides;
  const _SlideshowScreen({required this.slides});

  @override
  State<_SlideshowScreen> createState() => _SlideshowScreenState();
}

class _SlideshowScreenState extends State<_SlideshowScreen>
    with TickerProviderStateMixin {
  int _index = 0;

  // Animation state
  final Map<String, AnimationController> _animControllers = {};
  final Set<String> _visibleElements = {};
  List<ElementAnimation> _animQueue = [];
  int _animStep = 0;

  @override
  void initState() {
    super.initState();
    _setupSlideAnimations(_index);
  }

  @override
  void dispose() {
    for (final c in _animControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _setupSlideAnimations(int slideIndex) {
    // Dispose old controllers
    for (final c in _animControllers.values) {
      c.dispose();
    }
    _animControllers.clear();
    _visibleElements.clear();
    _animStep = 0;

    final slide = widget.slides[slideIndex];
    final anims = slide.animations;
    final animatedIds = anims.map((a) => a.elementId).toSet();

    // Elements without animations are immediately visible
    for (final el in slide.elements) {
      if (!animatedIds.contains(el.id)) {
        _visibleElements.add(el.id);
      }
    }

    // Build animation queue (onClick-triggered batches)
    _animQueue = List.from(anims);

    // Create controllers for each animated element
    for (final anim in anims) {
      if (!_animControllers.containsKey(anim.elementId)) {
        _animControllers[anim.elementId] = AnimationController(
          vsync: this,
          duration: Duration(milliseconds: anim.durationMs),
        );
      }
    }

    // Auto-play withPrevious/afterPrevious animations at slide start
    _playInitialAnimations();
  }

  void _playInitialAnimations() {
    // Play all animations until we hit an onClick trigger
    while (_animStep < _animQueue.length) {
      final anim = _animQueue[_animStep];
      if (anim.trigger == AnimationTrigger.onClick && _animStep > 0) break;
      if (anim.trigger == AnimationTrigger.onClick && _animStep == 0) break;
      _playOneAnimation(anim);
      _animStep++;
    }
  }

  void _onTap() {
    if (_animStep < _animQueue.length) {
      // Play next animation batch
      _playNextBatch();
    } else {
      // All animations done — advance slide
      if (_index < widget.slides.length - 1) {
        setState(() {
          _index++;
          _setupSlideAnimations(_index);
        });
      } else {
        Navigator.pop(context);
      }
    }
  }

  void _playNextBatch() {
    if (_animStep >= _animQueue.length) return;

    // Play the current onClick animation
    final first = _animQueue[_animStep];
    _playOneAnimation(first);
    _animStep++;

    // Play all following withPrevious/afterPrevious animations
    _playContinuationAnims();

    setState(() {});
  }

  void _playContinuationAnims() {
    while (_animStep < _animQueue.length) {
      final next = _animQueue[_animStep];
      if (next.trigger == AnimationTrigger.onClick) break;

      if (next.trigger == AnimationTrigger.afterPrevious) {
        // Chain after previous animation completes
        final prevStep = _animStep - 1;
        if (prevStep >= 0) {
          final prevAnim = _animQueue[prevStep];
          final prevCtrl = _animControllers[prevAnim.elementId];
          final capturedStep = _animStep;
          if (prevCtrl != null) {
            void listener(AnimationStatus status) {
              if (status == AnimationStatus.completed) {
                prevCtrl.removeStatusListener(listener);
                if (!mounted) return;
                final anim = _animQueue[capturedStep];
                _playOneAnimation(anim);
                setState(() {});
              }
            }
            prevCtrl.addStatusListener(listener);
            _animStep++;
            break; // Wait for previous to complete
          }
        }
        // Fallback: play immediately if no previous controller
        _playOneAnimation(next);
      } else {
        // withPrevious — play simultaneously
        _playOneAnimation(next);
      }
      _animStep++;
    }
  }

  void _playOneAnimation(ElementAnimation anim) {
    final controller = _animControllers[anim.elementId];
    if (controller == null) return;

    _visibleElements.add(anim.elementId);
    controller.duration = Duration(milliseconds: anim.durationMs);

    if (anim.delayMs > 0) {
      Future.delayed(Duration(milliseconds: anim.delayMs), () {
        if (mounted) controller.forward(from: 0);
      });
    } else {
      controller.forward(from: 0);
    }
  }

  Widget _wrapWithAnimation(SlideElement el, Widget child) {
    if (!_visibleElements.contains(el.id)) {
      return const SizedBox.shrink();
    }

    final controller = _animControllers[el.id];
    if (controller == null) return child;

    // Find the animation type for this element
    final anim = _animQueue.where((a) => a.elementId == el.id).firstOrNull;
    if (anim == null) return child;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = controller.value;
        switch (anim.type) {
          case AnimationType.fadeIn:
            return Opacity(opacity: t, child: child);
          case AnimationType.fadeOut:
            return Opacity(opacity: 1 - t, child: child);
          case AnimationType.flyInLeft:
            return Transform.translate(
              offset: Offset(-200 * (1 - t), 0),
              child: Opacity(opacity: t, child: child),
            );
          case AnimationType.flyInRight:
            return Transform.translate(
              offset: Offset(200 * (1 - t), 0),
              child: Opacity(opacity: t, child: child),
            );
          case AnimationType.flyInBottom:
            return Transform.translate(
              offset: Offset(0, 200 * (1 - t)),
              child: Opacity(opacity: t, child: child),
            );
          case AnimationType.zoomIn:
            return Transform.scale(
              scale: t,
              child: Opacity(opacity: t, child: child),
            );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final slide = widget.slides[_index];
    return Scaffold(
      backgroundColor: slide.backgroundColor,
      body: GestureDetector(
        onTap: _onTap,
        onHorizontalDragEnd: (d) {
          if (d.primaryVelocity == null) return;
          if (d.primaryVelocity! < 0) {
            _onTap(); // Swipe left = advance
          } else if (d.primaryVelocity! > 0 && _index > 0) {
            setState(() {
              _index--;
              _setupSlideAnimations(_index);
            });
          }
        },
        child: Stack(
          children: [
            // Slide content with animations
            ...slide.elements.map((el) {
              final child = buildSlideshowElement(el);
              return Positioned(
                left: el.x,
                top: el.y,
                width: el.width,
                height: el.height,
                child: _visibleElements.contains(el.id)
                    ? _wrapWithAnimation(el, child)
                    : const SizedBox.shrink(),
              );
            }),
            // Close button
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: Icon(LucideIcons.x,
                    color: AppColors.white.withValues(alpha: 0.7)),
                onPressed: () => Navigator.pop(context),
                tooltip: l.commonClose,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.black.withValues(alpha: 0.26),
                ),
              ),
            ),
            // Page indicator
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.black.withValues(alpha: 0.38),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_index + 1} / ${widget.slides.length}',
                    style: const TextStyle(
                        color: AppColors.white, fontSize: 14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
