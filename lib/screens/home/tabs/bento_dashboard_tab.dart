import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:excelia/l10n/app_localizations.dart';
import 'package:excelia/providers/app_provider.dart';
import 'package:excelia/models/recent_file.dart';
import 'package:excelia/models/app_document.dart';
import 'package:excelia/utils/constants.dart';

import '../widgets/quick_action_card.dart';
import '../widgets/recent_file_tile.dart';
import '../widgets/empty_state.dart';

class BentoDashboardTab extends StatefulWidget {
  final VoidCallback onPickFile;
  final void Function(DocumentType) onPickFileByType;
  final void Function(RecentFile) onOpenRecent;
  final void Function(RecentFile) onShareFile;
  final void Function(RecentFile) onOpenExternal;

  const BentoDashboardTab({
    super.key,
    required this.onPickFile,
    required this.onPickFileByType,
    required this.onOpenRecent,
    required this.onShareFile,
    required this.onOpenExternal,
  });

  @override
  State<BentoDashboardTab> createState() => _BentoDashboardTabState();
}

class _BentoDashboardTabState extends State<BentoDashboardTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _lowercaseQuery = '';
  int _activeChipIndex = 0;

  // Filter type map: 0=All, 1=Spreadsheet, 2=Document, 3=Presentation, 4=PDF
  static const List<DocumentType?> _chipTypeMap = [
    null, // All
    DocumentType.spreadsheet,
    DocumentType.pdf,
    DocumentType.document,
    DocumentType.presentation,
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Filtered recent files
  // ---------------------------------------------------------------------------

  List<RecentFile> _filteredFiles(List<RecentFile> allFiles) {
    if (_activeChipIndex == 0 && _searchQuery.isEmpty) return allFiles;

    final filterType = (_activeChipIndex > 0 && _activeChipIndex < _chipTypeMap.length)
        ? _chipTypeMap[_activeChipIndex]
        : null;

    return allFiles.where((f) {
      if (filterType != null && f.type != filterType) return false;
      if (_lowercaseQuery.isNotEmpty && !f.name.toLowerCase().contains(_lowercaseQuery)) return false;
      return true;
    }).toList();
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _lowercaseQuery = '';
      _activeChipIndex = 0;
    });
  }

  // ---------------------------------------------------------------------------
  // Open-file bottom sheet (FAB)
  //   Home quick actions handle "create new"; FAB handles "open existing".
  // ---------------------------------------------------------------------------

  void _showOpenFileSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.transparent,
      builder: (ctx) {
        final l = AppLocalizations.of(ctx)!;
        final bottomPad = MediaQuery.of(ctx).viewPadding.bottom;
        final isDarkSheet = Theme.of(ctx).brightness == Brightness.dark;

        final items = <_SheetItemData>[
          _SheetItemData(
            icon: LucideIcons.table,
            color: AppColors.spreadsheetGreen,
            label: l.spreadsheetOpen,
            type: DocumentType.spreadsheet,
          ),
          _SheetItemData(
            icon: LucideIcons.fileText,
            color: AppColors.pdfRed,
            label: l.pdfOpen,
            type: DocumentType.pdf,
          ),
          _SheetItemData(
            icon: LucideIcons.fileText,
            color: AppColors.documentBlue,
            label: l.documentOpenFile,
            type: DocumentType.document,
          ),
          _SheetItemData(
            icon: LucideIcons.presentation,
            color: AppColors.presentationOrange,
            label: l.presentationOpenTitle,
            type: DocumentType.presentation,
          ),
        ];

        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 20,
                bottom: bottomPad + 20,
              ),
              decoration: BoxDecoration(
                color: isDarkSheet
                    ? AppColors.glassDarkBg
                    : AppColors.glassLightBg,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(
                  top: BorderSide(
                    color: isDarkSheet
                        ? AppColors.glassDarkBorder
                        : AppColors.glassLightBorder,
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDarkSheet
                            ? AppColors.darkOutline
                            : AppColors.lightOutline,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Sheet title
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 16),
                    child: Text(
                      l.homeOpenFile,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDarkSheet
                            ? AppColors.darkOnSurface
                            : AppColors.lightOnSurface,
                      ),
                    ).animate().fadeIn(duration: 300.ms).slideX(
                          begin: -0.1,
                          end: 0,
                          duration: 300.ms,
                          curve: Curves.easeOutCubic,
                        ),
                  ),
                  // Stagger: each item slides up from below with a scale bounce
                  for (int i = 0; i < items.length; i++) ...[
                    _OpenFileItem(
                      icon: items[i].icon,
                      color: items[i].color,
                      label: items[i].label,
                      onTap: () {
                        Navigator.pop(ctx);
                        widget.onPickFileByType(items[i].type);
                      },
                    )
                        .animate(delay: (60 * i).ms)
                        .fadeIn(duration: 300.ms)
                        .slideY(
                          begin: 0.3,
                          end: 0,
                          duration: 320.ms,
                          curve: Curves.easeOutCubic,
                        )
                        .scale(
                          begin: const Offset(0.94, 0.94),
                          end: const Offset(1, 1),
                          duration: 320.ms,
                          curve: Curves.easeOutBack,
                        ),
                    if (i < items.length - 1) const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 16),
                  // Cancel
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: TextButton.styleFrom(
                        foregroundColor: isDarkSheet
                            ? AppColors.darkOnSurfaceAlt
                            : AppColors.lightOnSurfaceAlt,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(l.commonCancel),
                    ),
                  )
                      .animate(delay: (60 * items.length + 60).ms)
                      .fadeIn(duration: 280.ms),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Filter chips
  // ---------------------------------------------------------------------------

  Widget _buildFilterChips(AppLocalizations l, bool isDark) {
    final labels = [
      l.homeAll,
      l.typeSpreadsheet,
      l.typePdf,
      l.typeDocument,
      l.typePresentation,
    ];

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: labels.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final isActive = _activeChipIndex == index;
          final chip = ChoiceChip(
            label: Text(labels[index]),
            selected: isActive,
            onSelected: (_) => setState(() => _activeChipIndex = index),
            selectedColor: AppColors.primary.withValues(alpha: 0.15),
            labelStyle: TextStyle(
              color: isActive
                  ? AppColors.primary
                  : (isDark
                      ? AppColors.darkOnSurfaceAlt
                      : AppColors.lightOnSurfaceAlt),
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            ),
          );
          return chip
              .animate(delay: (50 * index + 200).ms)
              .fadeIn(duration: 300.ms)
              .slideX(
                begin: 0.2,
                end: 0,
                duration: 320.ms,
                curve: Curves.easeOutCubic,
              );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    final mutedColor =
        isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    final bool isFiltering =
        _searchQuery.isNotEmpty || _activeChipIndex != 0;

    return Stack(
      children: [
        // Animated aurora background (base layer)
        const _AuroraBackground(),

        // Content
        SafeArea(
          bottom: false,
          child: Consumer<AppProvider>(
            builder: (ctx, provider, _) {
              final allFiles = provider.recentFiles;
              final recentFiles = _filteredFiles(allFiles);

              return CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  // -- 1. Header: App name + subtitle --
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // App name with shimmer
                          Text(
                            l.appName,
                            style: textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.darkOnSurface
                                  : AppColors.lightOnSurface,
                            ),
                          )
                              .animate()
                              .fadeIn(duration: 400.ms)
                              .slideY(
                                begin: -0.2,
                                end: 0,
                                duration: 450.ms,
                                curve: Curves.easeOutCubic,
                              )
                              .shimmer(
                                delay: 600.ms,
                                duration: 1400.ms,
                                color: AppColors.primary.withValues(alpha: 0.5),
                              ),
                          const SizedBox(height: AppSizes.gap4),
                          Text(
                            l.appSubtitle,
                            style: textTheme.bodyMedium?.copyWith(
                              color: mutedColor,
                            ),
                          )
                              .animate(delay: 120.ms)
                              .fadeIn(duration: 400.ms)
                              .slideY(
                                begin: -0.15,
                                end: 0,
                                duration: 450.ms,
                                curve: Curves.easeOutCubic,
                              ),
                        ],
                      ),
                    ),
                  ),

                  // -- 2. Search bar --
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) => setState(() {
                          _searchQuery = v;
                          _lowercaseQuery = v.toLowerCase();
                        }),
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? AppColors.darkOnSurface
                              : AppColors.lightOnSurface,
                        ),
                        cursorColor: AppColors.primary,
                        decoration: InputDecoration(
                          hintText: l.homeSearchHint,
                          hintStyle: TextStyle(
                            color: isDark
                                ? AppColors.darkOnSurfaceAlt
                                : AppColors.lightTextMuted,
                          ),
                          prefixIcon: Icon(
                            LucideIcons.search,
                            color: isDark
                                ? AppColors.darkOnSurfaceAlt
                                : AppColors.lightOnSurfaceAlt,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    LucideIcons.x,
                                    color: isDark
                                        ? AppColors.darkOnSurfaceAlt
                                        : AppColors.lightOnSurfaceAlt,
                                  ),
                                  onPressed: _clearSearch,
                                )
                              : null,
                          filled: true,
                          fillColor: (isDark
                                  ? AppColors.darkSurface
                                  : AppColors.lightSurface)
                              .withValues(alpha: 0.82),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: isDark
                                  ? AppColors.darkOutline
                                  : AppColors.lightOutline,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: isDark
                                  ? AppColors.darkOutline
                                  : AppColors.lightOutline,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 1.6,
                            ),
                          ),
                        ),
                      )
                          .animate(delay: 180.ms)
                          .fadeIn(duration: 400.ms)
                          .slideY(
                            begin: 0.15,
                            end: 0,
                            duration: 420.ms,
                            curve: Curves.easeOutCubic,
                          ),
                    ),
                  ),

                  // -- 3. Filter chips (staggered inside) --
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: _buildFilterChips(l, isDark),
                    ),
                  ),

                  // -- 4. Quick Actions (only when NOT filtering) --
                  if (!isFiltering)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: SizedBox(
                          height: 120,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20),
                            children: [
                              _quickCard(
                                index: 0,
                                child: QuickActionCard(
                                  icon: LucideIcons.table,
                                  label: l.newSpreadsheet,
                                  color: AppColors.spreadsheetGreen,
                                  lightTint: AppColors.spreadsheetTintLight,
                                  darkTint: AppColors.spreadsheetTintDark,
                                  onTap: () {
                                    Navigator.pushNamed(
                                        ctx, '/spreadsheet');
                                  },
                                ),
                              ),
                              const SizedBox(width: AppSizes.gap12),
                              _quickCard(
                                index: 1,
                                child: QuickActionCard(
                                  icon: LucideIcons.fileSearch,
                                  label: l.pdfOpen,
                                  color: AppColors.pdfRed,
                                  lightTint: AppColors.pdfTintLight,
                                  darkTint: AppColors.pdfTintDark,
                                  onTap: () => widget
                                      .onPickFileByType(DocumentType.pdf),
                                ),
                              ),
                              const SizedBox(width: AppSizes.gap12),
                              _quickCard(
                                index: 2,
                                child: QuickActionCard(
                                  icon: LucideIcons.fileText,
                                  label: l.newDocument,
                                  color: AppColors.documentBlue,
                                  lightTint: AppColors.documentTintLight,
                                  darkTint: AppColors.documentTintDark,
                                  onTap: () {
                                    Navigator.pushNamed(ctx, '/document');
                                  },
                                ),
                              ),
                              const SizedBox(width: AppSizes.gap12),
                              _quickCard(
                                index: 3,
                                child: QuickActionCard(
                                  icon: LucideIcons.presentation,
                                  label: l.newPresentation,
                                  color: AppColors.presentationOrange,
                                  lightTint: AppColors.presentationTintLight,
                                  darkTint: AppColors.presentationTintDark,
                                  onTap: () {
                                    Navigator.pushNamed(
                                        ctx, '/presentation');
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // -- 5. Recent Files section header --
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                      child: Text(
                        l.homeRecentFiles,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkOnSurface
                              : AppColors.lightOnSurface,
                        ),
                      )
                          .animate(delay: 520.ms)
                          .fadeIn(duration: 400.ms)
                          .slideX(
                            begin: -0.1,
                            end: 0,
                            duration: 420.ms,
                            curve: Curves.easeOutCubic,
                          ),
                    ),
                  ),

                  // -- 6. Recent file list or empty state --
                  if (recentFiles.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyState(onTap: widget.onPickFile)
                          .animate(delay: 600.ms)
                          .fadeIn(duration: 500.ms)
                          .scale(
                            begin: const Offset(0.92, 0.92),
                            end: const Offset(1, 1),
                            duration: 500.ms,
                            curve: Curves.easeOutBack,
                          ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 4,
                          ),
                          child: RecentFileTile(
                            file: recentFiles[i],
                            onOpen: () =>
                                widget.onOpenRecent(recentFiles[i]),
                            onDelete: () {
                              ctx
                                  .read<AppProvider>()
                                  .removeRecentFile(recentFiles[i].path);
                            },
                            onShare: () =>
                                widget.onShareFile(recentFiles[i]),
                            onOpenExternal: () =>
                                widget.onOpenExternal(recentFiles[i]),
                          ),
                        )
                            .animate(delay: (540 + 50 * i).ms)
                            .fadeIn(duration: 350.ms)
                            .slideY(
                              begin: 0.15,
                              end: 0,
                              duration: 380.ms,
                              curve: Curves.easeOutCubic,
                            ),
                        childCount: recentFiles.length,
                      ),
                    ),

                  // -- Bottom spacing (extra for FAB) --
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height:
                          MediaQuery.of(ctx).viewPadding.bottom + 80,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        // -- FAB: Open existing file (with idle breathing glow) --
        Positioned(
          right: 20,
          bottom: MediaQuery.of(context).viewPadding.bottom + 16,
          child: _PulsingFab(
            onPressed: _showOpenFileSheet,
            tooltip: AppLocalizations.of(context)!.homeOpenFile,
          ),
        ),
      ],
    );
  }

  Widget _quickCard({required int index, required Widget child}) {
    return child
        .animate(delay: (260 + 90 * index).ms)
        .fadeIn(duration: 400.ms)
        .slideY(
          begin: 0.25,
          end: 0,
          duration: 440.ms,
          curve: Curves.easeOutCubic,
        )
        .scale(
          begin: const Offset(0.9, 0.9),
          end: const Offset(1, 1),
          duration: 440.ms,
          curve: Curves.easeOutBack,
        );
  }
}

// =============================================================================
// _OpenFileItem -- bottom sheet row item for "Open file" FAB
// =============================================================================

class _OpenFileItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _OpenFileItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.12 : 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: color.withValues(alpha: isDark ? 0.22 : 0.16),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: isDark ? 0.18 : 0.10),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color,
                    color.withValues(alpha: 0.78),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 10,
                    spreadRadius: -2,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Icon(icon, size: 18, color: AppColors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.darkOnSurface
                      : AppColors.lightOnSurface,
                ),
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: isDark
                  ? AppColors.darkOnSurfaceAlt
                  : AppColors.lightOnSurfaceAlt,
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// _SheetItemData -- internal record for sheet stagger iteration
// =============================================================================

class _SheetItemData {
  final IconData icon;
  final Color color;
  final String label;
  final DocumentType type;

  const _SheetItemData({
    required this.icon,
    required this.color,
    required this.label,
    required this.type,
  });
}

// =============================================================================
// _PulsingFab -- FAB with idle breathing glow (scale + halo pulse)
// =============================================================================

class _PulsingFab extends StatelessWidget {
  final VoidCallback onPressed;
  final String tooltip;

  const _PulsingFab({required this.onPressed, required this.tooltip});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      alignment: Alignment.center,
      children: [
        // Halo glow (breathing) — scale + opacity cycle via reverse
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withValues(alpha: isDark ? 0.30 : 0.22),
          ),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scale(
              begin: const Offset(0.80, 0.80),
              end: const Offset(1.22, 1.22),
              duration: 1800.ms,
              curve: Curves.easeInOut,
            )
            .fade(
              begin: 0.30,
              end: 0.95,
              duration: 1800.ms,
              curve: Curves.easeInOut,
            ),
        // Actual FAB
        FloatingActionButton(
          onPressed: onPressed,
          backgroundColor: AppColors.primary,
          tooltip: tooltip,
          elevation: 6,
          child: const Icon(LucideIcons.folderOpen, color: AppColors.white),
        )
            .animate()
            .scale(
              begin: const Offset(0, 0),
              end: const Offset(1, 1),
              duration: 500.ms,
              delay: 400.ms,
              curve: Curves.easeOutBack,
            )
            .fadeIn(duration: 400.ms, delay: 400.ms),
      ],
    );
  }
}

// =============================================================================
// _AuroraBackground -- animated mesh-gradient orbs (3 blobs drifting + blur)
//   Lightweight: pure Flutter, no shader package required.
//   RepaintBoundary isolates animation from scroll.
// =============================================================================

class _AuroraBackground extends StatefulWidget {
  const _AuroraBackground();

  @override
  State<_AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<_AuroraBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return RepaintBoundary(
      child: Stack(
        children: [
          // Base solid color
          Positioned.fill(
            child: ColoredBox(
              color: isDark
                  ? AppColors.darkBackground
                  : AppColors.lightBackground,
            ),
          ),
          // Animated orbs (blurred)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (context, _) {
                final t = _ctrl.value * 2 * math.pi;
                return ImageFiltered(
                  imageFilter:
                      ui.ImageFilter.blur(sigmaX: 90, sigmaY: 90),
                  child: Stack(
                    children: [
                      _orb(
                        color: (isDark
                                ? AppColors.liquidOrb2
                                : AppColors.accent)
                            .withValues(alpha: isDark ? 0.42 : 0.30),
                        alignment: Alignment(
                          -0.6 + 0.35 * math.sin(t),
                          -0.7 + 0.18 * math.cos(t),
                        ),
                        size: 320,
                      ),
                      _orb(
                        color: (isDark
                                ? AppColors.liquidOrb4
                                : AppColors.auroraPink)
                            .withValues(alpha: isDark ? 0.32 : 0.26),
                        alignment: Alignment(
                          0.7 + 0.28 * math.cos(t + 1.2),
                          0.1 + 0.22 * math.sin(t + 1.2),
                        ),
                        size: 360,
                      ),
                      _orb(
                        color: (isDark
                                ? AppColors.liquidOrb3
                                : AppColors.auroraGreen)
                            .withValues(alpha: isDark ? 0.26 : 0.22),
                        alignment: Alignment(
                          -0.3 + 0.30 * math.sin(t + 2.4),
                          0.8 + 0.15 * math.cos(t + 2.4),
                        ),
                        size: 300,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _orb({
    required Color color,
    required Alignment alignment,
    required double size,
  }) {
    return Align(
      alignment: alignment,
      child: SizedBox(
        width: size,
        height: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
      ),
    );
  }
}
