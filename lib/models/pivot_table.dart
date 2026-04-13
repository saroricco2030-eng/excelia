import 'dart:math' as math;

/// Aggregate functions for pivot tables.
enum AggregateFunction { sum, count, average, min, max }

/// Configuration for a pivot table calculation.
class PivotTableConfig {
  final int rowField;
  final int? colField;
  final int valueField;
  final AggregateFunction aggregateFunction;
  final int startRow;
  final int endRow;
  final int startCol;
  final int endCol;

  const PivotTableConfig({
    required this.rowField,
    this.colField,
    required this.valueField,
    this.aggregateFunction = AggregateFunction.sum,
    required this.startRow,
    required this.endRow,
    required this.startCol,
    required this.endCol,
  });
}

/// Result of a pivot table calculation.
class PivotResult {
  final List<String> columnHeaders;
  final List<PivotRow> rows;

  const PivotResult({required this.columnHeaders, required this.rows});
}

/// A single row in the pivot result.
class PivotRow {
  final String label;
  final List<double> values;

  const PivotRow({required this.label, required this.values});
}

/// Engine that computes pivot table results from spreadsheet cell data.
class PivotEngine {
  /// Main calculation entry point.
  static PivotResult calculate(
    PivotTableConfig config,
    Map<String, dynamic> cellData,
    String Function(int) getColumnName,
  ) {
    // ── 1. Extract source data rows (skip header row) ──
    final dataRows = <List<String>>[];
    for (int r = config.startRow + 1; r <= config.endRow; r++) {
      final row = <String>[];
      for (int c = config.startCol; c <= config.endCol; c++) {
        final key = '${getColumnName(c)}${r + 1}';
        row.add(cellData[key]?.toString() ?? '');
      }
      dataRows.add(row);
    }

    if (dataRows.isEmpty) {
      return const PivotResult(columnHeaders: ['Total'], rows: []);
    }

    // Relative column indices within the extracted rows
    final rIdx = config.rowField - config.startCol;
    final vIdx = config.valueField - config.startCol;
    final cIdx = config.colField != null
        ? config.colField! - config.startCol
        : null;

    if (cIdx == null) {
      // ── Simple 1D pivot (row field only) ──
      final groups = <String, List<double>>{};
      for (final row in dataRows) {
        if (rIdx < 0 || rIdx >= row.length) continue;
        final rowLabel = row[rIdx];
        final val = vIdx >= 0 && vIdx < row.length
            ? double.tryParse(row[vIdx]) ?? 0.0
            : 0.0;
        groups.putIfAbsent(rowLabel, () => []).add(val);
      }

      final pivotRows = groups.entries.map((e) {
        return PivotRow(
          label: e.key,
          values: [_aggregate(e.value, config.aggregateFunction)],
        );
      }).toList()
        ..sort((a, b) => a.label.compareTo(b.label));

      return PivotResult(
        columnHeaders: ['Total'],
        rows: pivotRows,
      );
    } else {
      // ── 2D pivot (row field × column field) ──
      final colValues = <String>{};
      final groups = <String, Map<String, List<double>>>{};

      for (final row in dataRows) {
        if (rIdx < 0 || rIdx >= row.length) continue;
        if (cIdx < 0 || cIdx >= row.length) continue;
        final rowLabel = row[rIdx];
        final colLabel = row[cIdx];
        final val = vIdx >= 0 && vIdx < row.length
            ? double.tryParse(row[vIdx]) ?? 0.0
            : 0.0;
        colValues.add(colLabel);
        groups
            .putIfAbsent(rowLabel, () => {})
            .putIfAbsent(colLabel, () => [])
            .add(val);
      }

      final sortedCols = colValues.toList()..sort();

      final pivotRows = groups.entries.map((e) {
        final vals = sortedCols.map((col) {
          final list = e.value[col];
          return list != null
              ? _aggregate(list, config.aggregateFunction)
              : 0.0;
        }).toList();
        return PivotRow(label: e.key, values: vals);
      }).toList()
        ..sort((a, b) => a.label.compareTo(b.label));

      return PivotResult(
        columnHeaders: sortedCols,
        rows: pivotRows,
      );
    }
  }

  static double _aggregate(List<double> values, AggregateFunction func) {
    if (values.isEmpty) return 0.0;
    switch (func) {
      case AggregateFunction.sum:
        return values.fold(0.0, (a, b) => a + b);
      case AggregateFunction.count:
        return values.length.toDouble();
      case AggregateFunction.average:
        return values.fold(0.0, (a, b) => a + b) / values.length;
      case AggregateFunction.min:
        return values.reduce(math.min);
      case AggregateFunction.max:
        return values.reduce(math.max);
    }
  }
}
