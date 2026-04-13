import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:excelia/l10n/app_localizations.dart';
import 'package:excelia/models/data_validation.dart';
import 'package:excelia/providers/spreadsheet_provider.dart';
import 'package:excelia/utils/constants.dart';

class DataValidationDialog extends StatefulWidget {
  const DataValidationDialog({super.key});

  @override
  State<DataValidationDialog> createState() => _DataValidationDialogState();
}

class _DataValidationDialogState extends State<DataValidationDialog> {
  ValidationType _type = ValidationType.list;
  ValidationOperator _operator = ValidationOperator.between;
  final _value1Controller = TextEditingController();
  final _value2Controller = TextEditingController();
  final _listController = TextEditingController();
  final _errorTitleController = TextEditingController();
  final _errorMsgController = TextEditingController();
  bool _showError = true;

  @override
  void dispose() {
    _value1Controller.dispose();
    _value2Controller.dispose();
    _listController.dispose();
    _errorTitleController.dispose();
    _errorMsgController.dispose();
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
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 560),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.dataValidation,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textColor)),
              const SizedBox(height: 16),
              // 검증 유형
              Text(l.dataValidationType,
                  style: TextStyle(
                      fontSize: 13,
                      color: textColor.withValues(alpha: 0.7))),
              const SizedBox(height: 8),
              DropdownButtonFormField<ValidationType>(
                initialValue: _type,
                decoration: InputDecoration(
                  isDense: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                dropdownColor: bgColor,
                items: ValidationType.values
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(_typeLabel(t, l),
                              style: TextStyle(color: textColor, fontSize: 14)),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _type = v);
                },
              ),
              const SizedBox(height: 12),
              // 리스트 타입이면 아이템 입력
              if (_type == ValidationType.list) ...[
                Text(l.dataValidationListItems,
                    style: TextStyle(
                        fontSize: 13,
                        color: textColor.withValues(alpha: 0.7))),
                const SizedBox(height: 8),
                TextField(
                  controller: _listController,
                  maxLines: 3,
                  style: TextStyle(color: textColor, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: l.dataValidationListHint,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ] else ...[
                // 연산자
                if (_type != ValidationType.custom) ...[
                  Text(l.dataValidationOperator,
                      style: TextStyle(
                          fontSize: 13,
                          color: textColor.withValues(alpha: 0.7))),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<ValidationOperator>(
                    initialValue: _operator,
                    decoration: InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    dropdownColor: bgColor,
                    items: ValidationOperator.values
                        .map((op) => DropdownMenuItem(
                              value: op,
                              child: Text(_operatorLabel(op, l),
                                  style: TextStyle(
                                      color: textColor, fontSize: 14)),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _operator = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  // 값 1
                  TextField(
                    controller: _value1Controller,
                    style: TextStyle(color: textColor, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: l.dataValidationValue1,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                  ),
                  // 값 2 (between/notBetween만)
                  if (_operator == ValidationOperator.between ||
                      _operator == ValidationOperator.notBetween) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: _value2Controller,
                      style: TextStyle(color: textColor, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: l.dataValidationValue2,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ],
              ],
              const SizedBox(height: 12),
              // 에러 표시
              Row(
                children: [
                  Checkbox(
                    value: _showError,
                    onChanged: (v) => setState(() => _showError = v ?? true),
                  ),
                  Text(l.dataValidationShowError,
                      style: TextStyle(color: textColor, fontSize: 14)),
                ],
              ),
              const Spacer(),
              // 버튼
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l.commonCancel),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => _apply(context),
                    child: Text(l.condApply),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _apply(BuildContext ctx) {
    final prov = ctx.read<SpreadsheetProvider>();
    final startRow = prov.selStartRow;
    final startCol = prov.selStartCol;
    final endRow = prov.selEndRow;
    final endCol = prov.selEndCol;

    List<String>? listItems;
    if (_type == ValidationType.list) {
      listItems = _listController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }

    final validation = DataValidation(
      id: 'dv_${DateTime.now().millisecondsSinceEpoch}',
      type: _type,
      operator: _operator,
      value1: _value1Controller.text,
      value2: _value2Controller.text,
      listItems: listItems,
      showDropdown: true,
      showError: _showError,
      errorTitle: _errorTitleController.text,
      errorMessage: _errorMsgController.text,
      startRow: startRow,
      startCol: startCol,
      endRow: endRow,
      endCol: endCol,
    );

    prov.addValidation(validation);
    Navigator.pop(ctx);
  }

  String _typeLabel(ValidationType t, AppLocalizations l) {
    switch (t) {
      case ValidationType.list:
        return l.dataValidationTypeList;
      case ValidationType.wholeNumber:
        return l.dataValidationTypeWholeNumber;
      case ValidationType.decimal:
        return l.dataValidationTypeDecimal;
      case ValidationType.date:
        return l.dataValidationTypeDate;
      case ValidationType.textLength:
        return l.dataValidationTypeTextLength;
      case ValidationType.custom:
        return l.dataValidationTypeCustom;
    }
  }

  String _operatorLabel(ValidationOperator op, AppLocalizations l) {
    switch (op) {
      case ValidationOperator.between:
        return l.dataValidationOpBetween;
      case ValidationOperator.notBetween:
        return l.dataValidationOpNotBetween;
      case ValidationOperator.equalTo:
        return l.dataValidationOpEqualTo;
      case ValidationOperator.notEqualTo:
        return l.dataValidationOpNotEqualTo;
      case ValidationOperator.greaterThan:
        return l.dataValidationOpGreaterThan;
      case ValidationOperator.lessThan:
        return l.dataValidationOpLessThan;
      case ValidationOperator.greaterOrEqual:
        return l.dataValidationOpGreaterOrEqual;
      case ValidationOperator.lessOrEqual:
        return l.dataValidationOpLessOrEqual;
    }
  }
}
