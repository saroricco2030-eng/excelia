import 'package:flutter/material.dart';
import 'package:excelia/models/table_embed.dart';
import 'package:excelia/l10n/app_localizations.dart';
import 'package:excelia/utils/constants.dart';

/// Dialog that lets the user pick row/column counts before inserting a table.
class TableInsertDialog extends StatefulWidget {
  const TableInsertDialog({super.key});

  @override
  State<TableInsertDialog> createState() => _TableInsertDialogState();
}

class _TableInsertDialogState extends State<TableInsertDialog> {
  int _rows = 3;
  int _cols = 3;

  static const _defaultHeaders = [
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J',
  ];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;

    return AlertDialog(
      title: Text(l.documentTableInsertTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row count
          Row(
            children: [
              Expanded(
                child: Text(
                  l.documentTableRows,
                  style: TextStyle(color: textColor),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 80,
                child: DropdownButtonFormField<int>(
                  initialValue: _rows,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(),
                  ),
                  items: List.generate(20, (i) => i + 1)
                      .map(
                        (v) => DropdownMenuItem(
                          value: v,
                          child: Text('$v'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _rows = v);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Column count
          Row(
            children: [
              Expanded(
                child: Text(
                  l.documentTableCols,
                  style: TextStyle(color: textColor),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 80,
                child: DropdownButtonFormField<int>(
                  initialValue: _cols,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(),
                  ),
                  items: List.generate(10, (i) => i + 1)
                      .map(
                        (v) => DropdownMenuItem(
                          value: v,
                          child: Text('$v'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _cols = v);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.commonCancel),
        ),
        FilledButton(
          onPressed: () {
            final headers = _defaultHeaders.sublist(0, _cols);
            final rows = List.generate(
              _rows,
              (_) => List<String>.filled(_cols, ''),
            );
            final tableData = TableData(headers: headers, rows: rows);
            Navigator.pop(context, tableData);
          },
          child: Text(l.documentInsertTable),
        ),
      ],
    );
  }
}
