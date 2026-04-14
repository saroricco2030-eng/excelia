import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:excelia/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:excelia/providers/spreadsheet_provider.dart';
import 'package:excelia/utils/constants.dart';

/// 하단 시트 탭 바: 시트 전환, 추가, 이름 변경, 삭제, 복제
class SheetTabBar extends StatefulWidget {
  const SheetTabBar({super.key});

  @override
  State<SheetTabBar> createState() => _SheetTabBarState();
}

class _SheetTabBarState extends State<SheetTabBar> {
  String? _renamingSheet;
  late TextEditingController _renameController;

  @override
  void initState() {
    super.initState();
    _renameController = TextEditingController();
  }

  @override
  void dispose() {
    _renameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SpreadsheetProvider>(
      builder: (context, prov, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          height: 44,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            border: Border(
              top: BorderSide(
                color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
                width: isDark ? 0.5 : 1,
              ),
            ),
          ),
          child: Row(
            children: [
              // 시트 추가 버튼
              _buildAddButton(prov),
              VerticalDivider(width: 1,
                  color: isDark ? AppColors.darkOutline : AppColors.grey300),
              // 드래그로 순서 변경 가능한 시트 탭들
              Expanded(
                child: ReorderableListView.builder(
                  scrollDirection: Axis.horizontal,
                  buildDefaultDragHandles: false,
                  proxyDecorator: (child, index, animation) => Material(
                    elevation: 2,
                    color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    child: child,
                  ),
                  onReorder: (oldIndex, newIndex) =>
                      prov.reorderSheet(oldIndex, newIndex),
                  itemCount: prov.sheetNames.length,
                  itemBuilder: (_, i) => ReorderableDragStartListener(
                    key: ValueKey(prov.sheetNames[i]),
                    index: i,
                    child: _buildTab(prov.sheetNames[i], prov, isDark),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAddButton(SpreadsheetProvider prov) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () => _showAddSheetDialog(prov),
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        child: Icon(LucideIcons.plus, size: 18,
            color: isDark ? AppColors.darkOnSurfaceAlt : AppColors.grey600),
      ),
    );
  }

  Widget _buildTab(String name, SpreadsheetProvider prov, bool isDark) {
    final isActive = name == prov.currentSheetName;
    final isRenaming = _renamingSheet == name;

    return GestureDetector(
      onTap: () {
        if (!isRenaming) prov.switchSheet(name);
      },
      onDoubleTap: () => _startRename(name),
      onLongPressStart: (details) =>
          _showContextMenu(details.globalPosition, name, prov),
      child: Container(
        constraints: const BoxConstraints(minWidth: 72, maxWidth: 160, minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark ? AppColors.darkSurface : AppColors.lightSurface)
              : (isDark ? AppColors.darkSurfaceElevated : AppColors.grey100),
          border: Border(
            top: isActive
                ? const BorderSide(color: AppColors.spreadsheetGreen, width: 2)
                : BorderSide.none,
            right: BorderSide(
                color: isDark ? AppColors.darkOutline : AppColors.grey300,
                width: 0.5),
            bottom: isActive
                ? BorderSide.none
                : BorderSide(
                    color: isDark ? AppColors.darkOutline : AppColors.grey300,
                    width: 0.5),
          ),
        ),
        alignment: Alignment.center,
        child: isRenaming ? _buildRenameField(name, prov, isDark) : _buildTabLabel(name, isActive, isDark),
      ),
    );
  }

  Widget _buildTabLabel(String name, bool isActive, bool isDark) {
    return Text(
      name,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 12,
        fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
        color: isActive
            ? AppColors.spreadsheetGreen
            : (isDark ? AppColors.darkOnSurfaceAlt : AppColors.grey800),
      ),
    );
  }

  Widget _buildRenameField(String oldName, SpreadsheetProvider prov, bool isDark) {
    return SizedBox(
      width: 100,
      height: 36,
      child: TextField(
        controller: _renameController,
        autofocus: true,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
        ),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          border: const OutlineInputBorder(),
          filled: false,
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: isDark ? AppColors.darkOutlineHi : AppColors.lightOutlineHi,
            ),
          ),
        ),
        onSubmitted: (v) => _confirmRename(oldName, v, prov),
        onTapOutside: (_) =>
            _confirmRename(oldName, _renameController.text, prov),
      ),
    );
  }

  void _startRename(String name) {
    setState(() {
      _renamingSheet = name;
      _renameController.text = name;
      _renameController.selection =
          TextSelection(baseOffset: 0, extentOffset: name.length);
    });
  }

  void _confirmRename(
      String oldName, String newName, SpreadsheetProvider prov) {
    final trimmed = newName.trim();
    if (trimmed.isNotEmpty && trimmed != oldName) {
      prov.renameSheet(oldName, trimmed);
    }
    setState(() => _renamingSheet = null);
  }

  void _showAddSheetDialog(SpreadsheetProvider prov) {
    final controller =
        TextEditingController(text: 'Sheet${prov.sheetNames.length + 1}');
    showDialog(
      context: context,
      builder: (ctx) {
        final l = AppLocalizations.of(ctx)!;
        return AlertDialog(
          title: Text(l.sheetNew),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              labelText: l.sheetName,
              hintText: l.sheetNameHint,
            ),
            onSubmitted: (v) {
              final name = v.trim();
              if (name.isNotEmpty) prov.addSheet(name);
              Navigator.pop(ctx);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l.commonCancel),
            ),
            FilledButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) prov.addSheet(name);
                Navigator.pop(ctx);
              },
              child: Text(l.commonAdd),
            ),
          ],
        );
      },
    );
  }

  void _showContextMenu(
      Offset position, String name, SpreadsheetProvider prov) {
    final l = AppLocalizations.of(context)!;
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
          position.dx, position.dy, position.dx + 1, position.dy + 1),
      items: [
        PopupMenuItem(value: 'rename', child: Text(l.sheetRename)),
        PopupMenuItem(value: 'duplicate', child: Text(l.sheetDuplicate)),
        if (prov.sheetNames.length > 1)
          PopupMenuItem(value: 'delete', child: Text(l.commonDelete)),
      ],
    ).then((action) {
      if (action == null) return;
      switch (action) {
        case 'rename':
          _startRename(name);
        case 'duplicate':
          prov.duplicateSheet(name);
        case 'delete':
          _confirmDelete(name, prov);
      }
    });
  }

  void _confirmDelete(String name, SpreadsheetProvider prov) {
    showDialog(
      context: context,
      builder: (ctx) {
        final l = AppLocalizations.of(ctx)!;
        return AlertDialog(
          title: Text(l.sheetDeleteTitle),
          content: Text(l.sheetDeleteConfirm(name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l.commonCancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () {
                prov.deleteSheet(name);
                Navigator.pop(ctx);
              },
              child: Text(l.commonDelete),
            ),
          ],
        );
      },
    );
  }
}
