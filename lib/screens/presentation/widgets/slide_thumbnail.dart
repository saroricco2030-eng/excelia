import 'dart:io' as io;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:excelia/l10n/app_localizations.dart';
import 'package:excelia/providers/presentation_provider.dart';
import 'package:excelia/utils/constants.dart';

/// A miniature preview of a single slide, shown in the left sidebar.
class SlideThumbnail extends StatelessWidget {
  final Slide slide;
  final int index;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDuplicate;
  final VoidCallback? onDelete;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  const SlideThumbnail({
    super.key,
    required this.slide,
    required this.index,
    required this.isSelected,
    required this.onTap,
    required this.onDuplicate,
    this.onDelete,
    this.onMoveUp,
    this.onMoveDown,
  });

  // Logical slide size used in the provider / canvas.
  static const double _logicalW = 960;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPressStart: (details) =>
          _showContextMenu(context, details.globalPosition),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Slide number
            SizedBox(
              width: 22,
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '${index + 1}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected
                        ? AppColors.presentationOrange
                        : AppColors.grey600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),

            // Thumbnail
            Expanded(
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  decoration: BoxDecoration(
                    color: slide.backgroundColor,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.presentationOrange
                          : AppColors.grey300,
                      width: isSelected ? 2.5 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.presentationOrange
                                  .withValues(alpha: 0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final scale = constraints.maxWidth / _logicalW;
                        return Stack(
                          children: slide.elements
                              .map((el) => _buildMiniElement(el, scale))
                              .toList(),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Mini element rendering (simplified for thumbnail)
  // ---------------------------------------------------------------------------

  Widget _buildMiniElement(SlideElement el, double scale) {
    return Positioned(
      left: el.x * scale,
      top: el.y * scale,
      width: el.width * scale,
      height: el.height * scale,
      child: _buildMiniContent(el, scale),
    );
  }

  Widget _buildMiniContent(SlideElement el, double scale) {
    switch (el.type) {
      case SlideElementType.text:
        return Text(
          el.content,
          style: TextStyle(
            fontSize: (el.fontSize * scale).clamp(2.0, 24.0),
            fontWeight: el.fontWeight,
            color: el.color,
            height: 1.1,
          ),
          textAlign: el.textAlign,
          overflow: TextOverflow.clip,
          maxLines: 3,
        );

      case SlideElementType.shape:
        return CustomPaint(
          painter: _MiniShapePainter(
            kind: el.shapeKind ?? ShapeKind.rectangle,
            fillColor: el.backgroundColor ?? AppColors.selectionBlue.withValues(alpha: 0.4),
            strokeColor: el.color,
          ),
        );

      case SlideElementType.image:
        return Image.file(
          io.File(el.content),
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        );
    }
  }

  // ---------------------------------------------------------------------------
  // Context menu
  // ---------------------------------------------------------------------------

  void _showContextMenu(BuildContext context, Offset position) {
    final l = AppLocalizations.of(context)!;
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
          position.dx, position.dy, position.dx, position.dy),
      items: [
        PopupMenuItem(
          value: 'duplicate',
          child: ListTile(
            leading: const Icon(LucideIcons.copy, size: 20),
            title: Text(l.presentationDuplicate),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
        if (onDelete != null)
          PopupMenuItem(
            value: 'delete',
            child: ListTile(
              leading: const Icon(LucideIcons.trash2, size: 20, color: AppColors.error),
              title:
                  Text(l.presentationDeleteSlide, style: const TextStyle(color: AppColors.error)),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        if (onMoveUp != null)
          PopupMenuItem(
            value: 'up',
            child: ListTile(
              leading: const Icon(LucideIcons.arrowUp, size: 20),
              title: Text(l.presentationMoveUp),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        if (onMoveDown != null)
          PopupMenuItem(
            value: 'down',
            child: ListTile(
              leading: const Icon(LucideIcons.arrowDown, size: 20),
              title: Text(l.presentationMoveDown),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
      ],
    ).then((value) {
      switch (value) {
        case 'duplicate':
          onDuplicate();
        case 'delete':
          onDelete?.call();
        case 'up':
          onMoveUp?.call();
        case 'down':
          onMoveDown?.call();
      }
    });
  }
}

// =============================================================================
// Simplified shape painter for thumbnails
// =============================================================================

class _MiniShapePainter extends CustomPainter {
  final ShapeKind kind;
  final Color fillColor;
  final Color strokeColor;

  _MiniShapePainter({
    required this.kind,
    required this.fillColor,
    required this.strokeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    switch (kind) {
      case ShapeKind.rectangle:
        final rect = Rect.fromLTWH(0, 0, size.width, size.height);
        canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(2)), fill);
        canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(2)),
            stroke);
      case ShapeKind.circle:
        final center = Offset(size.width / 2, size.height / 2);
        final radius = size.shortestSide / 2;
        canvas.drawCircle(center, radius, fill);
        canvas.drawCircle(center, radius, stroke);
      case ShapeKind.triangle:
        final path = Path()
          ..moveTo(size.width / 2, 0)
          ..lineTo(size.width, size.height)
          ..lineTo(0, size.height)
          ..close();
        canvas.drawPath(path, fill);
        canvas.drawPath(path, stroke);
      case ShapeKind.arrow:
        final path = Path()
          ..moveTo(0, size.height * 0.35)
          ..lineTo(size.width * 0.65, size.height * 0.35)
          ..lineTo(size.width * 0.65, 0)
          ..lineTo(size.width, size.height / 2)
          ..lineTo(size.width * 0.65, size.height)
          ..lineTo(size.width * 0.65, size.height * 0.65)
          ..lineTo(0, size.height * 0.65)
          ..close();
        canvas.drawPath(path, fill);
        canvas.drawPath(path, stroke);
      case ShapeKind.star:
        final path = _starPath(size);
        canvas.drawPath(path, fill);
        canvas.drawPath(path, stroke);
      case ShapeKind.hexagon:
        final path = _polygonPath(size, 6);
        canvas.drawPath(path, fill);
        canvas.drawPath(path, stroke);
      case ShapeKind.diamond:
        final path = Path()
          ..moveTo(size.width / 2, 0)
          ..lineTo(size.width, size.height / 2)
          ..lineTo(size.width / 2, size.height)
          ..lineTo(0, size.height / 2)
          ..close();
        canvas.drawPath(path, fill);
        canvas.drawPath(path, stroke);
      case ShapeKind.pentagon:
        final path = _polygonPath(size, 5);
        canvas.drawPath(path, fill);
        canvas.drawPath(path, stroke);
    }
  }

  Path _starPath(Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final outerR = size.shortestSide / 2;
    final innerR = outerR * 0.4;
    final path = Path();
    for (int i = 0; i < 10; i++) {
      final r = i.isEven ? outerR : innerR;
      final angle = -math.pi / 2 + (math.pi * 2 * i / 10);
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  Path _polygonPath(Size size, int sides) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.shortestSide / 2;
    final path = Path();
    for (int i = 0; i < sides; i++) {
      final angle = -math.pi / 2 + (math.pi * 2 * i / sides);
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _MiniShapePainter old) =>
      old.kind != kind ||
      old.fillColor != fillColor ||
      old.strokeColor != strokeColor;
}
