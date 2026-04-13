import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:excelia/providers/spreadsheet_provider.dart';
import 'package:excelia/utils/constants.dart';

/// 수식 입력줄: 셀 주소 표시 + fx 아이콘 + 수식/값 편집 필드
class FormulaBar extends StatefulWidget {
  const FormulaBar({super.key});

  @override
  State<FormulaBar> createState() => _FormulaBarState();
}

class _FormulaBarState extends State<FormulaBar> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _valueController = TextEditingController();
  final FocusNode _addressFocus = FocusNode();
  final FocusNode _valueFocus = FocusNode();
  bool _editingAddress = false;

  @override
  void dispose() {
    _addressController.dispose();
    _valueController.dispose();
    _addressFocus.dispose();
    _valueFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Selector rebuilds only when the formula bar-relevant state changes
    // (selected cell address, raw cell value, editing state)
    return Selector<SpreadsheetProvider, ({
      String address,
      String rawValue,
      bool isEditing,
      int selectedRow,
      int selectedCol,
    })>(
      selector: (_, prov) => (
        address: prov.selectedCellAddress,
        rawValue: prov.getCellRaw(prov.selectedRow, prov.selectedCol),
        isEditing: prov.isEditing,
        selectedRow: prov.selectedRow,
        selectedCol: prov.selectedCol,
      ),
      builder: (context, state, _) {
        final prov = context.read<SpreadsheetProvider>();
        final isDark = Theme.of(context).brightness == Brightness.dark;
        // 셀 주소와 원시 값을 컨트롤러에 동기화
        if (!_editingAddress) {
          _addressController.text = state.address;
        }
        if (!_valueFocus.hasFocus) {
          _valueController.text = state.rawValue;
        }

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
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              // ── 셀 주소 (터치 타겟 44dp) ──
              SizedBox(
                width: 64,
                height: 44,
                child: GestureDetector(
                  onTap: () {
                    setState(() => _editingAddress = true);
                    _addressFocus.requestFocus();
                    _addressController.selection = TextSelection(
                      baseOffset: 0,
                      extentOffset: _addressController.text.length,
                    );
                  },
                  child: Center(
                    child: Container(
                      width: 64,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.grey300),
                        borderRadius: BorderRadius.circular(3),
                        color: isDark ? AppColors.darkSurfaceElevated : AppColors.grey100,
                      ),
                      child: _editingAddress
                          ? TextField(
                              controller: _addressController,
                              focusNode: _addressFocus,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                                border: InputBorder.none,
                              ),
                              onSubmitted: (v) => _goToAddress(v, prov),
                              onTapOutside: (_) {
                                setState(() => _editingAddress = false);
                              },
                            )
                          : Text(
                              state.address,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.grey800,
                              ),
                            ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 4),

              // ── fx 아이콘 (터치 타겟 44x44) ──
              SizedBox(
                width: 44,
                height: 44,
                child: Center(
                  child: Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.grey300),
                      borderRadius: BorderRadius.circular(3),
                      color: isDark ? AppColors.darkSurfaceElevated : AppColors.grey100,
                    ),
                    child: const Text(
                      'fx',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                        color: AppColors.grey600,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 4),

              // ── 수식/값 입력 필드 (높이 44dp) ──
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.grey300),
                    borderRadius: BorderRadius.circular(3),
                    color: isDark ? AppColors.darkSurface : AppColors.white,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: TextField(
                    controller: _valueController,
                    focusNode: _valueFocus,
                    style: const TextStyle(fontSize: 13),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                      border: InputBorder.none,
                    ),
                    onTap: () {
                      if (!state.isEditing) {
                        prov.startEditing(state.rawValue);
                      }
                    },
                    onChanged: (v) {
                      prov.updateEditValue(v);
                    },
                    onSubmitted: (v) {
                      prov.updateEditValue(v);
                      prov.confirmEdit();
                      // 포커스를 수식 입력줄에서 제거
                      _valueFocus.unfocus();
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _goToAddress(String address, SpreadsheetProvider prov) {
    setState(() => _editingAddress = false);
    _addressFocus.unfocus();
    final parsed = prov.parseCellReference(address.trim().toUpperCase());
    if (parsed != null) {
      prov.selectCell(parsed.$1, parsed.$2);
    }
  }
}
