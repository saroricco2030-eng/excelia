import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:excelia/utils/constants.dart';

/// Shows a styled SnackBar with optional undo action and haptic feedback.
///
/// [message] — the text content displayed in the snackbar.
/// [actionLabel] — optional button label (e.g. "Undo").
/// [onAction] — callback when the action button is pressed.
/// [haptic] — whether to trigger haptic feedback (default: true).
/// [isError] — uses error background color if true.
void showExceliaSnackBar(
  BuildContext context, {
  required String message,
  String? actionLabel,
  VoidCallback? onAction,
  bool haptic = true,
  bool isError = false,
}) {
  if (haptic) {
    HapticFeedback.mediumImpact();
  }

  final snackBar = SnackBar(
    content: Text(
      message,
      style: const TextStyle(color: AppColors.white),
    ),
    backgroundColor: isError ? AppColors.error : null,
    behavior: SnackBarBehavior.floating,
    duration: actionLabel != null
        ? const Duration(seconds: 5)
        : const Duration(seconds: 3),
    action: actionLabel != null && onAction != null
        ? SnackBarAction(
            label: actionLabel,
            textColor: isError ? AppColors.white : null,
            onPressed: onAction,
          )
        : null,
  );

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(snackBar);
}
