import 'package:flutter/material.dart';
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
  final void Function(RecentFile) onOpenRecent;
  final void Function(RecentFile) onShareFile;

  const BentoDashboardTab({
    super.key,
    required this.onPickFile,
    required this.onOpenRecent,
    required this.onShareFile,
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
  // Create-new bottom sheet
  // ---------------------------------------------------------------------------

  void _showCreateNewSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.transparent,
      builder: (ctx) {
        final l = AppLocalizations.of(ctx)!;
        final bottomPad = MediaQuery.of(ctx).viewPadding.bottom;
        final isDarkSheet = Theme.of(ctx).brightness == Brightness.dark;

        return Container(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 24,
            bottom: bottomPad + 20,
          ),
          decoration: BoxDecoration(
            color: isDarkSheet
                ? AppColors.darkSurface
                : AppColors.lightSurface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(
              top: BorderSide(
                color: isDarkSheet
                    ? AppColors.darkOutline
                    : AppColors.lightOutline,
                width: 1,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDarkSheet
                      ? AppColors.darkOutline
                      : AppColors.lightOutline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              // Spreadsheet (primary)
              _CreateNewItem(
                icon: LucideIcons.table,
                color: AppColors.spreadsheetGreen,
                label: l.newSpreadsheet,
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, '/spreadsheet');
                },
              ),
              const SizedBox(height: 8),
              // PDF open (secondary)
              _CreateNewItem(
                icon: LucideIcons.fileSearch,
                color: AppColors.pdfRed,
                label: l.pdfOpen,
                onTap: () {
                  Navigator.pop(ctx);
                  widget.onPickFile();
                },
              ),
              const SizedBox(height: 8),
              // Document
              _CreateNewItem(
                icon: LucideIcons.fileText,
                color: AppColors.documentBlue,
                label: l.newDocument,
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, '/document');
                },
              ),
              const SizedBox(height: 8),
              // Presentation
              _CreateNewItem(
                icon: LucideIcons.presentation,
                color: AppColors.presentationOrange,
                label: l.newPresentation,
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, '/presentation');
                },
              ),
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
              ),
            ],
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
          return ChoiceChip(
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
        Container(
          color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
          child: SafeArea(
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
                            Text(
                              l.appName,
                              style: textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.darkOnSurface
                                    : AppColors.lightOnSurface,
                              ),
                            ),
                            const SizedBox(height: AppSizes.gap4),
                            Text(
                              l.appSubtitle,
                              style: textTheme.bodyMedium?.copyWith(
                                color: mutedColor,
                              ),
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
                            fillColor: isDark
                                ? AppColors.darkSurface
                                : AppColors.lightSurface,
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
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // -- 3. Filter chips --
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
                                QuickActionCard(
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
                                const SizedBox(width: AppSizes.gap12),
                                QuickActionCard(
                                  icon: LucideIcons.fileSearch,
                                  label: l.pdfOpen,
                                  color: AppColors.pdfRed,
                                  lightTint: AppColors.pdfTintLight,
                                  darkTint: AppColors.pdfTintDark,
                                  onTap: widget.onPickFile,
                                ),
                                const SizedBox(width: AppSizes.gap12),
                                QuickActionCard(
                                  icon: LucideIcons.fileText,
                                  label: l.newDocument,
                                  color: AppColors.documentBlue,
                                  lightTint: AppColors.documentTintLight,
                                  darkTint: AppColors.documentTintDark,
                                  onTap: () {
                                    Navigator.pushNamed(ctx, '/document');
                                  },
                                ),
                                const SizedBox(width: AppSizes.gap12),
                                QuickActionCard(
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
                        ),
                      ),
                    ),

                    // -- 6. Recent file list or empty state --
                    if (recentFiles.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: EmptyState(onTap: widget.onPickFile),
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
                            ),
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
        ),
        // -- FAB: New file --
        Positioned(
          right: 20,
          bottom: MediaQuery.of(context).viewPadding.bottom + 16,
          child: FloatingActionButton(
            onPressed: _showCreateNewSheet,
            backgroundColor: AppColors.primary,
            child: const Icon(LucideIcons.plus, color: AppColors.white),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// _CreateNewItem -- bottom sheet row item
// =============================================================================

class _CreateNewItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _CreateNewItem({
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
          color: color.withValues(alpha: isDark ? 0.08 : 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: isDark ? 0.15 : 0.12),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
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
              LucideIcons.plus,
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
