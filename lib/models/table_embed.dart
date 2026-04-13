import 'dart:convert';
import 'package:flutter_quill/flutter_quill.dart';

/// Custom block embed for tables in the document editor.
class TableBlockEmbed extends CustomBlockEmbed {
  static const String tableType = 'table';

  const TableBlockEmbed(String data) : super(tableType, data);

  factory TableBlockEmbed.fromTableData(TableData tableData) {
    return TableBlockEmbed(jsonEncode(tableData.toJson()));
  }

  TableData get tableData => TableData.fromJson(jsonDecode(data));
}

/// Table data model stored inside the embed.
class TableData {
  final List<String> headers;
  final List<List<String>> rows;

  const TableData({required this.headers, required this.rows});

  factory TableData.fromJson(Map<String, dynamic> json) {
    return TableData(
      headers: (json['headers'] as List<dynamic>?)?.cast<String>() ?? [],
      rows: (json['rows'] as List<dynamic>?)
              ?.map((r) => (r as List<dynamic>).cast<String>())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'headers': headers,
        'rows': rows,
      };

  int get columnCount =>
      headers.isNotEmpty
          ? headers.length
          : (rows.isNotEmpty ? rows.first.length : 0);

  int get rowCount => rows.length;

  /// Return a copy with one cell changed.
  TableData copyWithCell(int row, int col, String value) {
    final newRows = rows.map((r) => List<String>.from(r)).toList();
    if (row >= 0 &&
        row < newRows.length &&
        col >= 0 &&
        col < newRows[row].length) {
      newRows[row][col] = value;
    }
    return TableData(headers: List.from(headers), rows: newRows);
  }

  /// Return a copy with one header changed.
  TableData copyWithHeader(int col, String value) {
    final newHeaders = List<String>.from(headers);
    if (col >= 0 && col < newHeaders.length) {
      newHeaders[col] = value;
    }
    return TableData(headers: newHeaders, rows: rows);
  }

  /// Append an empty row.
  TableData addRow() {
    final newRow = List<String>.filled(columnCount, '');
    return TableData(
        headers: List.from(headers), rows: [...rows, newRow]);
  }

  /// Append a column.
  TableData addColumn(String headerName) {
    final newHeaders = [...headers, headerName];
    final newRows = rows.map((r) => [...r, '']).toList();
    return TableData(headers: newHeaders, rows: newRows);
  }

  /// Remove the last row.
  TableData removeLastRow() {
    if (rows.isEmpty) return this;
    return TableData(
        headers: List.from(headers),
        rows: rows.sublist(0, rows.length - 1));
  }
}
