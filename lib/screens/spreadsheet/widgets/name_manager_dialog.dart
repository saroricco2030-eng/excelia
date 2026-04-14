import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:excelia/l10n/app_localizations.dart';
import 'package:excelia/providers/spreadsheet_provider.dart';
import 'package:excelia/utils/constants.dart';

class NameManagerDialog extends StatefulWidget {
  const NameManagerDialog({super.key});

  @override
  State<NameManagerDialog> createState() => _NameManagerDialogState();
}

class _NameManagerDialogState extends State<NameManagerDialog> {
  final _nameController = TextEditingController();
  final _rangeController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _rangeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textColor = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;

    return Dialog(
      backgroundColor: bgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 500),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.nameManager,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textColor)),
              const SizedBox(height: 16),
              // 새 이름 추가 폼
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _nameController,
                      style: TextStyle(color: textColor, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: l.namedRangeName,
                        isDense: true,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _rangeController,
                      style: TextStyle(color: textColor, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: l.namedRangeRef,
                        isDense: true,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 40,
                    child: FilledButton(
                      onPressed: () => _addRange(context),
                      child: Text(l.commonAdd),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 기존 목록
              Expanded(
                child: Consumer<SpreadsheetProvider>(
                  builder: (ctx, prov, _) {
                    final ranges = prov.namedRanges;
                    if (ranges.isEmpty) {
                      return Center(
                        child: Text(l.namedRangeEmpty,
                            style: TextStyle(
                                color: textColor.withValues(alpha: 0.5),
                                fontSize: 14)),
                      );
                    }
                    return ListView.separated(
                      itemCount: ranges.length,
                      separatorBuilder: (_, _) => Divider(
                          color: textColor.withValues(alpha: 0.1), height: 1),
                      itemBuilder: (ctx, i) {
                        final name = ranges.keys.elementAt(i);
                        final ref = ranges[name]!;
                        return ListTile(
                          dense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 4),
                          title: Text(name,
                              style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14)),
                          subtitle: Text(ref,
                              style: TextStyle(
                                  color: textColor.withValues(alpha: 0.6),
                                  fontSize: 12)),
                          trailing: IconButton(
                            icon: Icon(LucideIcons.trash2,
                                color: textColor.withValues(alpha: 0.5),
                                size: 20),
                            onPressed: () {
                              prov.removeNamedRange(name);
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l.commonClose),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addRange(BuildContext ctx) {
    final name = _nameController.text.trim().toUpperCase();
    final range = _rangeController.text.trim().toUpperCase();

    if (name.isEmpty || range.isEmpty) return;

    // 유효 이름 검사: 알파벳으로 시작, 알파+숫자+_만 허용
    if (!RegExp(r'^[A-Z_][A-Z0-9_]*$').hasMatch(name)) return;

    ctx.read<SpreadsheetProvider>().setNamedRange(name, range);
    _nameController.clear();
    _rangeController.clear();
  }
}
