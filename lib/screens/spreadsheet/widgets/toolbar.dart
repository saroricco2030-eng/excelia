import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:excelia/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:excelia/providers/spreadsheet_provider.dart';
import 'package:excelia/utils/constants.dart';

/// 서식 도구 모음 (볼드, 이탤릭, 밑줄, 글자색, 배경색, 정렬, 숫자 형식 등)
class SpreadsheetToolbar extends StatelessWidget {
  const SpreadsheetToolbar({super.key});

  static const List<Color> _presetColors = AppColors.cellColors;

  static const List<String> _numberFormatKeys = [
    'general',
    'number',
    'currency',
    'percent',
    'date',
  ];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    // Selector rebuilds only when the toolbar-relevant state changes
    // (cell format, merge state, format painter state, selected cell)
    return Selector<SpreadsheetProvider, ({
      CellFormat fmt,
      bool isMerged,
      bool canMerge,
      bool isFormatPainter,
      int selectedRow,
      int selectedCol,
    })>(
      selector: (_, prov) => (
        fmt: prov.getCellFormat(prov.selectedRow, prov.selectedCol),
        isMerged: prov.isSelectionMerged,
        canMerge: prov.canMerge,
        isFormatPainter: prov.isFormatPainterActive,
        selectedRow: prov.selectedRow,
        selectedCol: prov.selectedCol,
      ),
      builder: (context, state, _) {
        final prov = context.read<SpreadsheetProvider>();
        final fmt = state.fmt;

        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          height: 48,
          decoration: BoxDecoration(
            color: isDark ? AppColors.toolbarDark : AppColors.toolbarLight,
            border: Border(
              bottom: BorderSide(
                color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
                width: isDark ? 0.5 : 1,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // ── B I U ──
                _ToggleIcon(
                  icon: LucideIcons.bold,
                  tooltip: l.toolbarBold,
                  isActive: fmt.bold,
                  onTap: () => prov.applyFormatToSelection(
                      (f) => f.copy()..bold = !f.bold),
                ),
                _ToggleIcon(
                  icon: LucideIcons.italic,
                  tooltip: l.toolbarItalic,
                  isActive: fmt.italic,
                  onTap: () => prov.applyFormatToSelection(
                      (f) => f.copy()..italic = !f.italic),
                ),
                _ToggleIcon(
                  icon: LucideIcons.underline,
                  tooltip: l.toolbarUnderline,
                  isActive: fmt.underline,
                  onTap: () => prov.applyFormatToSelection(
                      (f) => f.copy()..underline = !f.underline),
                ),

                _divider(),

                // ── 글자색 ──
                _ColorButton(
                  icon: LucideIcons.type,
                  tooltip: l.toolbarTextColor,
                  currentColor: fmt.textColor ?? AppColors.black,
                  onColorSelected: (c) => prov.applyFormatToSelection(
                      (f) => f.copy()..textColor = c),
                ),
                // ── 배경색 ──
                _ColorButton(
                  icon: LucideIcons.paintBucket,
                  tooltip: l.toolbarBgColor,
                  currentColor: fmt.backgroundColor ?? AppColors.white,
                  onColorSelected: (c) => prov.applyFormatToSelection(
                      (f) => f.copy()..backgroundColor = c),
                ),

                _divider(),

                // ── 정렬 ──
                _ToggleIcon(
                  icon: LucideIcons.alignLeft,
                  tooltip: l.toolbarAlignLeft,
                  isActive: fmt.alignment == TextAlign.left,
                  onTap: () => prov.applyFormatToSelection(
                      (f) => f.copy()..alignment = TextAlign.left),
                ),
                _ToggleIcon(
                  icon: LucideIcons.alignCenter,
                  tooltip: l.toolbarAlignCenter,
                  isActive: fmt.alignment == TextAlign.center,
                  onTap: () => prov.applyFormatToSelection(
                      (f) => f.copy()..alignment = TextAlign.center),
                ),
                _ToggleIcon(
                  icon: LucideIcons.alignRight,
                  tooltip: l.toolbarAlignRight,
                  isActive: fmt.alignment == TextAlign.right,
                  onTap: () => prov.applyFormatToSelection(
                      (f) => f.copy()..alignment = TextAlign.right),
                ),

                _divider(),

                // ── 숫자 형식 ──
                _NumberFormatDropdown(
                  current: fmt.numberFormat,
                  onChanged: (nf) => prov.applyFormatToSelection(
                      (f) => f.copy()..numberFormat = nf),
                ),

                _divider(),

                // ── 텍스트 줄바꿈 ──
                _ToggleIcon(
                  icon: LucideIcons.wrapText,
                  tooltip: l.toolbarWrapText,
                  isActive: fmt.wrapText,
                  onTap: () => prov.applyFormatToSelection(
                      (f) => f.copy()..wrapText = !f.wrapText),
                ),

                _divider(),

                // ── 글꼴 크기 ──
                _FontSizeControl(
                  currentSize: fmt.fontSize ?? 13,
                  onChanged: (size) => prov.applyFormatToSelection(
                      (f) => f.copy()..fontSize = size),
                ),

                _divider(),

                // ── 셀 병합 ──
                _ToggleIcon(
                  icon: LucideIcons.merge,
                  tooltip: state.isMerged ? l.unmergeCells : l.mergeCells,
                  isActive: state.isMerged,
                  onTap: () {
                    if (state.isMerged) {
                      prov.unmergeCells();
                    } else if (state.canMerge) {
                      prov.mergeCells();
                    }
                  },
                ),

                _divider(),

                // ── 테두리 ──
                _BorderButton(
                  onPresetSelected: (preset) => prov.applyBorderPreset(preset),
                ),

                _divider(),

                // ── 서식 복사 ──
                _ToggleIcon(
                  icon: LucideIcons.paintbrush2,
                  tooltip: l.formatPainter,
                  isActive: state.isFormatPainter,
                  onTap: () {
                    if (state.isFormatPainter) {
                      prov.cancelFormatPainter();
                    } else {
                      prov.activateFormatPainter();
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _divider() {
    return const SizedBox(width: 8);
  }
}

// ─────────────────── 토글 아이콘 버튼 ───────────────────

class _ToggleIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool isActive;
  final VoidCallback onTap;

  const _ToggleIcon({
    required this.icon,
    required this.tooltip,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusSM),
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary.withValues(alpha: 0.10)
                : AppColors.transparent,
            borderRadius: BorderRadius.circular(AppSizes.radiusSM),
          ),
          child: Icon(
            icon,
            size: 18,
            color: isActive
                ? AppColors.primary
                : (isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface),
          ),
        ),
      ),
    );
  }
}

// ─────────────────── 색상 선택 버튼 ───────────────────

class _ColorButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color currentColor;
  final ValueChanged<Color> onColorSelected;

  const _ColorButton({
    required this.icon,
    required this.tooltip,
    required this.currentColor,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () => _showColorPicker(context),
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface),
              Container(
                width: 16,
                height: 3,
                decoration: BoxDecoration(
                  color: currentColor,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showColorPicker(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tooltip),
        contentPadding: const EdgeInsets.all(16),
        content: SizedBox(
          width: 240,
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            children: SpreadsheetToolbar._presetColors.map((c) {
              return GestureDetector(
                onTap: () {
                  onColorSelected(c);
                  Navigator.pop(ctx);
                },
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: c,
                    border: Border.all(
                      color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: c == currentColor
                      ? Icon(LucideIcons.check,
                          size: 14,
                          color: c.computeLuminance() > 0.5
                              ? AppColors.black
                              : AppColors.white)
                      : null,
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.toolbarClose),
          ),
        ],
      ),
    );
  }
}

// ─────────────────── 숫자 형식 드롭다운 ───────────────────

class _NumberFormatDropdown extends StatelessWidget {
  final String current;
  final ValueChanged<String> onChanged;

  const _NumberFormatDropdown({
    required this.current,
    required this.onChanged,
  });

  static String _localizedFormatName(BuildContext context, String key) {
    final l = AppLocalizations.of(context)!;
    switch (key) {
      case 'general':
        return l.numberFormatGeneral;
      case 'number':
        return l.numberFormatNumber;
      case 'currency':
        return l.numberFormatCurrency;
      case 'percent':
        return l.numberFormatPercent;
      case 'date':
        return l.numberFormatDate;
      default:
        return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        border: Border.all(
          color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
        ),
        borderRadius: BorderRadius.circular(4),
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: current,
          isDense: true,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
          ),
          icon: Icon(
            LucideIcons.chevronDown,
            size: 16,
            color: isDark ? AppColors.darkOnSurfaceAlt : AppColors.lightOnSurfaceAlt,
          ),
          items: SpreadsheetToolbar._numberFormatKeys
              .map((key) => DropdownMenuItem(
                    value: key,
                    child: Text(_localizedFormatName(context, key)),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

// ─────────────────── 글꼴 크기 컨트롤 ───────────────────

class _FontSizeControl extends StatelessWidget {
  final int currentSize;
  final ValueChanged<int> onChanged;

  const _FontSizeControl({
    required this.currentSize,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final disabledColor = isDark ? AppColors.darkOnSurfaceAlt : AppColors.lightTextMuted;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: currentSize > 8
              ? () => onChanged(currentSize - 1)
              : null,
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            width: 28,
            height: 28,
            child: Icon(
              LucideIcons.minus,
              size: 14,
              color: currentSize > 8 ? activeColor : disabledColor,
            ),
          ),
        ),
        Container(
          width: 32,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(
              color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
            ),
            borderRadius: BorderRadius.circular(4),
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          ),
          child: Text(
            '$currentSize',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
            ),
          ),
        ),
        InkWell(
          onTap: currentSize < 72
              ? () => onChanged(currentSize + 1)
              : null,
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            width: 28,
            height: 28,
            child: Icon(
              LucideIcons.plus,
              size: 14,
              color: currentSize < 72 ? activeColor : disabledColor,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────── 테두리 버튼 ───────────────────

class _BorderButton extends StatelessWidget {
  final ValueChanged<BorderPreset> onPresetSelected;

  const _BorderButton({required this.onPresetSelected});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PopupMenuButton<BorderPreset>(
      onSelected: onPresetSelected,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        child: Icon(
          LucideIcons.grid,
          size: 18,
          color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
        ),
      ),
      itemBuilder: (_) => [
        PopupMenuItem(
          value: BorderPreset.all,
          child: Row(children: [
            const Icon(LucideIcons.grid, size: 16),
            const SizedBox(width: 8),
            Text(l.borderAll),
          ]),
        ),
        PopupMenuItem(
          value: BorderPreset.outside,
          child: Row(children: [
            const Icon(LucideIcons.square, size: 16),
            const SizedBox(width: 8),
            Text(l.borderOutside),
          ]),
        ),
        PopupMenuItem(
          value: BorderPreset.bottom,
          child: Row(children: [
            const Icon(LucideIcons.arrowDownToLine, size: 16),
            const SizedBox(width: 8),
            Text(l.borderBottom),
          ]),
        ),
        PopupMenuItem(
          value: BorderPreset.none,
          child: Row(children: [
            const Icon(LucideIcons.x, size: 16),
            const SizedBox(width: 8),
            Text(l.borderNone),
          ]),
        ),
      ],
    );
  }
}
