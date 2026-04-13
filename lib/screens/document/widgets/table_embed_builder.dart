import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:excelia/models/table_embed.dart';
import 'package:excelia/l10n/app_localizations.dart';
import 'package:excelia/utils/constants.dart';

/// EmbedBuilder that renders [TableBlockEmbed] as a Material3 DataTable.
class TableEmbedBuilder extends EmbedBuilder {
  @override
  String get key => TableBlockEmbed.tableType;

  @override
  Widget build(
    BuildContext context,
    EmbedContext embedContext,
  ) {
    final tableData = TableBlockEmbed(embedContext.node.value.data).tableData;

    return _TableEmbedWidget(
      tableData: tableData,
      controller: embedContext.controller,
      node: embedContext.node,
      readOnly: embedContext.readOnly,
    );
  }
}

class _TableEmbedWidget extends StatelessWidget {
  const _TableEmbedWidget({
    required this.tableData,
    required this.controller,
    required this.node,
    required this.readOnly,
  });

  final TableData tableData;
  final QuillController controller;
  final Embed node;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor =
        isDark ? AppColors.darkOutline : AppColors.lightOutline;
    final headerBg = isDark
        ? AppColors.darkSurfaceElevated
        : AppColors.lightSurfaceElevated;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(AppSizes.radiusSM),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radiusSM),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(headerBg),
                  border: TableBorder.all(color: borderColor, width: 0.5),
                  headingRowHeight: 48,
                  dataRowMinHeight: 48,
                  dataRowMaxHeight: 48,
                  columns: _buildColumns(context, l),
                  rows: _buildRows(context, l),
                ),
              ),
            ),
          ),
          if (!readOnly) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _addRow(context),
              icon: const Icon(LucideIcons.plus, size: 16),
              label: Text(l.documentTableAddRow),
            ),
          ],
        ],
      ),
    );
  }

  List<DataColumn> _buildColumns(BuildContext context, AppLocalizations l) {
    return List.generate(tableData.columnCount, (colIdx) {
      return DataColumn(
        label: GestureDetector(
          onTap: readOnly
              ? null
              : () => _editHeader(context, l, colIdx),
          child: Text(
            tableData.headers[colIdx],
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      );
    });
  }

  List<DataRow> _buildRows(BuildContext context, AppLocalizations l) {
    return List.generate(tableData.rowCount, (rowIdx) {
      return DataRow(
        cells: List.generate(tableData.columnCount, (colIdx) {
          return DataCell(
            Text(tableData.rows[rowIdx][colIdx]),
            onTap: readOnly
                ? null
                : () => _editCell(context, l, rowIdx, colIdx),
          );
        }),
      );
    });
  }

  /// Finds the offset of this embed node in the document.
  int? _findEmbedOffset() {
    int offset = 0;
    for (final child in controller.document.root.children) {
      if (child is Line) {
        for (final leafNode in child.children) {
          if (leafNode is Embed && leafNode.value.data == node.value.data) {
            return offset;
          }
          offset += leafNode.length;
        }
        // account for the newline at end of line
        offset += 1;
      } else if (child is Block) {
        for (final line in child.children) {
          if (line is Line) {
            for (final leafNode in line.children) {
              if (leafNode is Embed &&
                  leafNode.value.data == node.value.data) {
                return offset;
              }
              offset += leafNode.length;
            }
            offset += 1;
          }
        }
      }
    }
    return null;
  }

  /// Replaces the current embed with an updated TableData.
  void _updateEmbed(TableData newData) {
    final embedOffset = _findEmbedOffset();
    if (embedOffset == null) return;

    controller.replaceText(
      embedOffset,
      1,
      TableBlockEmbed.fromTableData(newData),
      null,
    );
  }

  Future<void> _editCell(
    BuildContext context,
    AppLocalizations l,
    int row,
    int col,
  ) async {
    final currentValue = tableData.rows[row][col];
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final cl = AppLocalizations.of(ctx)!;
        final editCtrl = TextEditingController(text: currentValue);
        return AlertDialog(
          title: Text(cl.documentTableEditCell),
          content: TextField(
            controller: editCtrl,
            autofocus: true,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(cl.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, editCtrl.text),
              child: Text(cl.commonConfirm),
            ),
          ],
        );
      },
    );

    if (result != null) {
      final newData = tableData.copyWithCell(row, col, result);
      _updateEmbed(newData);
    }
  }

  Future<void> _editHeader(
    BuildContext context,
    AppLocalizations l,
    int col,
  ) async {
    final currentValue = tableData.headers[col];
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final cl = AppLocalizations.of(ctx)!;
        final editCtrl = TextEditingController(text: currentValue);
        return AlertDialog(
          title: Text(cl.documentTableEditHeader),
          content: TextField(
            controller: editCtrl,
            autofocus: true,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(cl.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, editCtrl.text),
              child: Text(cl.commonConfirm),
            ),
          ],
        );
      },
    );

    if (result != null) {
      final newData = tableData.copyWithHeader(col, result);
      _updateEmbed(newData);
    }
  }

  void _addRow(BuildContext context) {
    final newData = tableData.addRow();
    _updateEmbed(newData);
  }
}
