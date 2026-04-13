import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:excelia/utils/constants.dart';

/// 셀 위에 표시되는 인라인 편집기
/// Enter로 확인, Escape로 취소, Tab으로 다음 셀 이동
class CellEditor extends StatefulWidget {
  final double width;
  final double height;
  final String initialValue;
  final ValueChanged<String> onSubmit;
  final VoidCallback onCancel;
  final ValueChanged<String> onChanged;
  final void Function(bool forward) onTab;

  const CellEditor({
    super.key,
    required this.width,
    required this.height,
    required this.initialValue,
    required this.onSubmit,
    required this.onCancel,
    required this.onChanged,
    required this.onTab,
  });

  @override
  State<CellEditor> createState() => _CellEditorState();
}

class _CellEditorState extends State<CellEditor> {
  late final TextEditingController _controller;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focus = FocusNode();

    // 커서를 텍스트 끝으로 이동
    _controller.selection = TextSelection.collapsed(
      offset: _controller.text.length,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return KeyboardListener(
      focusNode: FocusNode(), // 부모 포커스 노드 (이벤트 전파용)
      onKeyEvent: _handleKey,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          border: Border.all(
            color: AppColors.spreadsheetGreen,
            width: 2,
          ),
        ),
        child: TextField(
          controller: _controller,
          focusNode: _focus,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
            fontFamily: 'NotoSansKR',
          ),
          cursorColor: AppColors.spreadsheetGreen,
          keyboardType: TextInputType.text,
          textAlign: TextAlign.left,
          maxLines: 1,
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            border: InputBorder.none,
          ),
          onChanged: widget.onChanged,
          onSubmitted: (_) => widget.onSubmit(_controller.text),
        ),
      ),
    );
  }

  void _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    if (event.logicalKey == LogicalKeyboardKey.enter) {
      widget.onSubmit(_controller.text);
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      widget.onCancel();
    } else if (event.logicalKey == LogicalKeyboardKey.tab) {
      final forward = !HardwareKeyboard.instance.isShiftPressed;
      widget.onTab(forward);
    }
  }
}
