import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:excelia/utils/constants.dart';

/// Haptic intensity for user actions.
enum HapticLevel {
  none,
  light,   // 성공·가벼운 피드백 (저장 완료 등)
  medium,  // 기본 상호작용
  heavy,   // 경고·에러
}

/// Shows a styled SnackBar with optional undo action and haptic feedback.
///
/// [message] — the text content displayed in the snackbar.
/// [actionLabel] — optional button label (e.g. "Undo").
/// [onAction] — callback when the action button is pressed.
/// [haptic] — haptic intensity (default: medium).
/// [isError] — uses error background color if true.
/// [isSuccess] — uses success accent if true (higher priority than isError).
/// [duration] — custom duration. Defaults to 6s if action, else 3s.
void showExceliaSnackBar(
  BuildContext context, {
  required String message,
  String? actionLabel,
  VoidCallback? onAction,
  HapticLevel haptic = HapticLevel.medium,
  bool isError = false,
  bool isSuccess = false,
  Duration? duration,
  IconData? leadingIcon,
}) {
  switch (haptic) {
    case HapticLevel.none:
      break;
    case HapticLevel.light:
      HapticFeedback.lightImpact();
    case HapticLevel.medium:
      HapticFeedback.mediumImpact();
    case HapticLevel.heavy:
      HapticFeedback.heavyImpact();
  }

  final Color? bg = isSuccess
      ? AppColors.success
      : (isError ? AppColors.error : null);

  final Widget content = leadingIcon != null
      ? Row(
          children: [
            Icon(leadingIcon, size: 18, color: AppColors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: AppColors.white),
              ),
            ),
          ],
        )
      : Text(
          message,
          style: const TextStyle(color: AppColors.white),
        );

  final snackBar = SnackBar(
    content: content,
    backgroundColor: bg,
    behavior: SnackBarBehavior.floating,
    duration: duration ??
        (actionLabel != null
            ? const Duration(seconds: 6)
            : const Duration(seconds: 3)),
    action: actionLabel != null && onAction != null
        ? SnackBarAction(
            label: actionLabel,
            textColor: AppColors.white,
            onPressed: onAction,
          )
        : null,
  );

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(snackBar);
}

/// Lightweight haptic-only call (no SnackBar).
void exceliaHaptic([HapticLevel level = HapticLevel.light]) {
  switch (level) {
    case HapticLevel.none:
      break;
    case HapticLevel.light:
      HapticFeedback.lightImpact();
    case HapticLevel.medium:
      HapticFeedback.mediumImpact();
    case HapticLevel.heavy:
      HapticFeedback.heavyImpact();
  }
}
