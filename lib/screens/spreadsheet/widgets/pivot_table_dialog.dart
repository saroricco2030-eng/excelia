import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:excelia/l10n/app_localizations.dart';
import 'package:excelia/providers/spreadsheet_provider.dart';
import 'package:excelia/models/pivot_table.dart';
import 'package:excelia/utils/constants.dart';

class PivotTableDialog extends StatefulWidget {
  const PivotTableDialog({super.key});

  @override
  State<PivotTableDialog> createState() => _PivotTableDialogState();
}

class _PivotTableDialogState extends State<PivotTableDialog> {
  int? _rowField;
  int? _colField; // null = 없음
  int? _valueField;
  AggregateFunction _aggregateFunc = AggregateFunction.sum;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textColor =
        isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final subTextColor = textColor.withValues(alpha: 0.7);

    return Consumer<SpreadsheetProvider>(
      builder: (context, prov, _) {
        final range = prov.detectDataRange();
        final (startRow, endRow, startCol, endCol) = range;
        final hasData = endRow > startRow || endCol > startCol;
        final headers = hasData
            ? prov.getHeaderNames(startRow, startCol, endCol)
            : <String>[];

        // 범위 표시 텍스트: "A1:D20"
        final rangeText = hasData
            ? '${prov.getColumnName(startCol)}${startRow + 1}'
                ':${prov.getColumnName(endCol)}${endRow + 1}'
            : '-';

        return Dialog(
          backgroundColor: bgColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400, maxHeight: 520),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── 제목 ──
                  Row(
                    children: [
                      Icon(LucideIcons.table2,
                          size: 24, color: AppColors.spreadsheetGreen),
                      const SizedBox(width: 8),
                      Text(
                        l.pivotTableCreate,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── 데이터 범위 ──
                  Text(
                    '${l.pivotDataRange}: $rangeText',
                    style: TextStyle(fontSize: 13, color: subTextColor),
                  ),
                  const SizedBox(height: 16),

                  // ── 행 필드 ──
                  _buildLabel(l.pivotRowField, subTextColor),
                  const SizedBox(height: 8),
                  _buildFieldDropdown(
                    value: _rowField,
                    headers: headers,
                    startCol: startCol,
                    bgColor: bgColor,
                    textColor: textColor,
                    includeNone: false,
                    noneLabel: '',
                    onChanged: (v) => setState(() => _rowField = v),
                  ),
                  const SizedBox(height: 12),

                  // ── 열 필드 (선택) ──
                  _buildLabel(l.pivotColField, subTextColor),
                  const SizedBox(height: 8),
                  _buildFieldDropdown(
                    value: _colField,
                    headers: headers,
                    startCol: startCol,
                    bgColor: bgColor,
                    textColor: textColor,
                    includeNone: true,
                    noneLabel: l.chartLegendNone,
                    onChanged: (v) => setState(() => _colField = v),
                  ),
                  const SizedBox(height: 12),

                  // ── 값 필드 ──
                  _buildLabel(l.pivotValueField, subTextColor),
                  const SizedBox(height: 8),
                  _buildFieldDropdown(
                    value: _valueField,
                    headers: headers,
                    startCol: startCol,
                    bgColor: bgColor,
                    textColor: textColor,
                    includeNone: false,
                    noneLabel: '',
                    onChanged: (v) => setState(() => _valueField = v),
                  ),
                  const SizedBox(height: 12),

                  // ── 집계 함수 ──
                  _buildLabel(l.pivotAggregateFunc, subTextColor),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<AggregateFunction>(
                    initialValue: _aggregateFunc,
                    decoration: InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    dropdownColor: bgColor,
                    items: AggregateFunction.values
                        .map((f) => DropdownMenuItem(
                              value: f,
                              child: Text(
                                _aggLabel(f, l),
                                style:
                                    TextStyle(color: textColor, fontSize: 14),
                              ),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _aggregateFunc = v);
                    },
                  ),

                  const Spacer(),

                  // ── 버튼 ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(l.commonCancel),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: hasData
                            ? () => _create(context, prov, range)
                            : null,
                        child: Text(l.chartCreate),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLabel(String text, Color color) {
    return Text(text, style: TextStyle(fontSize: 13, color: color));
  }

  Widget _buildFieldDropdown({
    required int? value,
    required List<String> headers,
    required int startCol,
    required Color bgColor,
    required Color textColor,
    required bool includeNone,
    required String noneLabel,
    required ValueChanged<int?> onChanged,
  }) {
    final items = <DropdownMenuItem<int?>>[];
    if (includeNone) {
      items.add(DropdownMenuItem<int?>(
        value: null,
        child: Text(noneLabel, style: TextStyle(color: textColor, fontSize: 14)),
      ));
    }
    for (int i = 0; i < headers.length; i++) {
      final colIdx = startCol + i;
      items.add(DropdownMenuItem<int?>(
        value: colIdx,
        child: Text(
          headers[i].isEmpty ? _colLetter(colIdx) : headers[i],
          style: TextStyle(color: textColor, fontSize: 14),
        ),
      ));
    }

    return DropdownButtonFormField<int?>(
      initialValue: value,
      decoration: InputDecoration(
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      dropdownColor: bgColor,
      items: items,
      onChanged: (v) => onChanged(v),
    );
  }

  String _colLetter(int index) {
    String result = '';
    int i = index;
    while (i >= 0) {
      result = String.fromCharCode(65 + (i % 26)) + result;
      i = (i ~/ 26) - 1;
    }
    return result;
  }

  String _aggLabel(AggregateFunction f, AppLocalizations l) {
    switch (f) {
      case AggregateFunction.sum:
        return l.pivotFuncSum;
      case AggregateFunction.count:
        return l.pivotFuncCount;
      case AggregateFunction.average:
        return l.pivotFuncAverage;
      case AggregateFunction.min:
        return l.pivotFuncMin;
      case AggregateFunction.max:
        return l.pivotFuncMax;
    }
  }

  void _create(
    BuildContext ctx,
    SpreadsheetProvider prov,
    (int, int, int, int) range,
  ) {
    final l = AppLocalizations.of(ctx)!;
    final (startRow, endRow, startCol, endCol) = range;

    if (_rowField == null || _valueField == null) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text(l.pivotNoData)),
      );
      return;
    }

    final config = PivotTableConfig(
      rowField: _rowField!,
      colField: _colField,
      valueField: _valueField!,
      aggregateFunction: _aggregateFunc,
      startRow: startRow,
      endRow: endRow,
      startCol: startCol,
      endCol: endCol,
    );

    prov.createPivotTable(config);

    Navigator.pop(ctx);

    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(content: Text(l.pivotCreated(prov.currentSheetName))),
    );
  }
}
