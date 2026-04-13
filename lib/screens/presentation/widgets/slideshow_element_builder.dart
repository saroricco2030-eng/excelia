import 'dart:io' as io;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:excelia/providers/presentation_provider.dart';
import 'package:excelia/utils/constants.dart';

/// Shared builder for rendering slide elements in slideshow / presenter view.
Widget buildSlideshowElement(SlideElement el) {
  switch (el.type) {
    case SlideElementType.text:
      return Text(
        el.content,
        style: TextStyle(
          fontSize: el.fontSize,
          fontWeight: el.fontWeight,
          fontStyle: el.italic ? FontStyle.italic : FontStyle.normal,
          decoration: TextDecoration.combine([
            if (el.underline) TextDecoration.underline,
            if (el.strikethrough) TextDecoration.lineThrough,
          ]),
          fontFamily: el.fontFamily,
          color: el.color,
        ),
        textAlign: el.textAlign,
      );
    case SlideElementType.shape:
      return SlideshowShapeWidget(element: el);
    case SlideElementType.image:
      return Image.file(
        io.File(el.content),
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => const Icon(LucideIcons.imageOff),
      );
  }
}

class SlideshowShapeWidget extends StatelessWidget {
  final SlideElement element;
  const SlideshowShapeWidget({super.key, required this.element});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ShapePainter(
        kind: element.shapeKind ?? ShapeKind.rectangle,
        fillColor:
            element.backgroundColor ?? AppColors.selectionBlue.withValues(alpha: 0.4),
        strokeColor: element.color,
      ),
    );
  }
}

class _ShapePainter extends CustomPainter {
  final ShapeKind kind;
  final Color fillColor;
  final Color strokeColor;

  _ShapePainter({
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
      ..strokeWidth = 2;

    switch (kind) {
      case ShapeKind.rectangle:
        final rect = Rect.fromLTWH(0, 0, size.width, size.height);
        canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(4)), fill);
        canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(4)), stroke);
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
      final angle = -3.14159 / 2 + (3.14159 * 2 * i / 10);
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
      final angle = -3.14159 / 2 + (3.14159 * 2 * i / sides);
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
  bool shouldRepaint(covariant _ShapePainter old) =>
      old.kind != kind ||
      old.fillColor != fillColor ||
      old.strokeColor != strokeColor;
}
