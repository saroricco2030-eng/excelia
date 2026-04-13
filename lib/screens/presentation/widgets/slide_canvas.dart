import 'dart:io' as io;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:excelia/providers/presentation_provider.dart';
import 'package:excelia/utils/constants.dart';

/// The main slide editing canvas. Maintains 16:9 aspect ratio, renders all
/// elements, and handles selection / drag / resize / inline text editing.
class SlideCanvas extends StatefulWidget {
  final Slide slide;
  final String? selectedElementId;
  final bool gridSnap;
  final ValueChanged<String?> onSelectElement;
  final void Function(String elementId, double dx, double dy) onMoveElement;
  final void Function(String elementId, double w, double h) onResizeElement;
  final void Function(String elementId, String newText) onEditText;

  const SlideCanvas({
    super.key,
    required this.slide,
    required this.selectedElementId,
    required this.gridSnap,
    required this.onSelectElement,
    required this.onMoveElement,
    required this.onResizeElement,
    required this.onEditText,
  });

  @override
  State<SlideCanvas> createState() => _SlideCanvasState();
}

class _SlideCanvasState extends State<SlideCanvas> {
  // The logical slide size is 960 x 540 (16:9).
  static const double _logicalW = 960;

  String? _editingElementId;
  late TextEditingController _textCtrl;

  @override
  void initState() {
    super.initState();
    _textCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scale = constraints.maxWidth / _logicalW;
          return Container(
            decoration: BoxDecoration(
              color: widget.slide.backgroundColor,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.18),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Stack(
                children: [
                  // Grid overlay (when snap is on)
                  if (widget.gridSnap)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _GridPainter(
                          gridSize: PresentationProvider.gridSize * scale,
                        ),
                      ),
                    ),

                  // Elements
                  ...widget.slide.elements.map(
                    (el) => _buildElement(el, scale),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Element rendering
  // ---------------------------------------------------------------------------

  Widget _buildElement(SlideElement el, double scale) {
    final isSelected = el.id == widget.selectedElementId;
    final isEditing = el.id == _editingElementId;

    return Positioned(
      left: el.x * scale,
      top: el.y * scale,
      width: el.width * scale,
      height: el.height * scale,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => widget.onSelectElement(el.id),
        onDoubleTap: el.type == SlideElementType.text
            ? () => _startEditing(el)
            : null,
        onPanUpdate: (details) {
          widget.onMoveElement(
            el.id,
            details.delta.dx / scale,
            details.delta.dy / scale,
          );
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Content
            Positioned.fill(child: _buildContent(el, scale, isEditing)),

            // Selection border + handles
            if (isSelected) ...[
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.selectionBlue,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
              // 8 resize handles
              ..._buildHandles(el, scale),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContent(SlideElement el, double scale, bool isEditing) {
    switch (el.type) {
      case SlideElementType.text:
        if (isEditing) {
          return Container(
            color: AppColors.white.withValues(alpha: 0.9),
            child: TextField(
              controller: _textCtrl,
              autofocus: true,
              maxLines: null,
              expands: true,
              style: TextStyle(
                fontSize: el.fontSize * scale,
                fontWeight: el.fontWeight,
                color: el.color,
              ),
              textAlign: el.textAlign,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(4),
                isDense: true,
              ),
              onTapOutside: (_) => _finishEditing(el),
            ),
          );
        }
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: el.backgroundColor != null
              ? BoxDecoration(
                  color: el.backgroundColor,
                  borderRadius: BorderRadius.circular(el.borderRadius),
                )
              : null,
          alignment: _alignmentFromTextAlign(el.textAlign),
          child: Text(
            el.content,
            style: TextStyle(
              fontSize: el.fontSize * scale,
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
            overflow: TextOverflow.clip,
          ),
        );

      case SlideElementType.shape:
        return CustomPaint(
          painter: _CanvasShapePainter(
            kind: el.shapeKind ?? ShapeKind.rectangle,
            fillColor: el.backgroundColor ?? AppColors.selectionBlue.withValues(alpha: 0.4),
            strokeColor: el.color,
            borderRadius: el.borderRadius,
          ),
        );

      case SlideElementType.image:
        return ClipRRect(
          borderRadius: BorderRadius.circular(el.borderRadius),
          child: Image.file(
            io.File(el.content),
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => Container(
              color: AppColors.grey200,
              child: const Center(
                child:
                    Icon(LucideIcons.imageOff, color: AppColors.grey500, size: 32),
              ),
            ),
          ),
        );
    }
  }

  Alignment _alignmentFromTextAlign(TextAlign align) {
    switch (align) {
      case TextAlign.center:
        return Alignment.center;
      case TextAlign.right:
      case TextAlign.end:
        return Alignment.centerRight;
      default:
        return Alignment.centerLeft;
    }
  }

  // ---------------------------------------------------------------------------
  // Inline text editing
  // ---------------------------------------------------------------------------

  void _startEditing(SlideElement el) {
    setState(() {
      _editingElementId = el.id;
      _textCtrl.text = el.content;
    });
  }

  void _finishEditing(SlideElement el) {
    final newText = _textCtrl.text;
    widget.onEditText(el.id, newText);
    setState(() => _editingElementId = null);
  }

  // ---------------------------------------------------------------------------
  // Resize handles
  // ---------------------------------------------------------------------------

  List<Widget> _buildHandles(SlideElement el, double scale) {
    const handleSize = 10.0;
    const half = handleSize / 2;

    Widget handle(Alignment alignment,
        {required void Function(DragUpdateDetails) onDrag}) {
      double? left, top, right, bottom;
      if (alignment.x == -1) left = -half;
      if (alignment.x == 0) left = (el.width * scale) / 2 - half;
      if (alignment.x == 1) right = -half;
      if (alignment.y == -1) top = -half;
      if (alignment.y == 0) top = (el.height * scale) / 2 - half;
      if (alignment.y == 1) bottom = -half;

      return Positioned(
        left: left,
        top: top,
        right: right,
        bottom: bottom,
        child: GestureDetector(
          onPanUpdate: onDrag,
          child: Container(
            width: handleSize,
            height: handleSize,
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border.all(color: AppColors.selectionBlue, width: 1.5),
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      );
    }

    return [
      // corners
      handle(Alignment.topLeft, onDrag: (d) {
        widget.onMoveElement(el.id, d.delta.dx / scale, d.delta.dy / scale);
        widget.onResizeElement(
          el.id,
          el.width - d.delta.dx / scale,
          el.height - d.delta.dy / scale,
        );
      }),
      handle(Alignment.topRight, onDrag: (d) {
        widget.onMoveElement(el.id, 0, d.delta.dy / scale);
        widget.onResizeElement(
          el.id,
          el.width + d.delta.dx / scale,
          el.height - d.delta.dy / scale,
        );
      }),
      handle(Alignment.bottomLeft, onDrag: (d) {
        widget.onMoveElement(el.id, d.delta.dx / scale, 0);
        widget.onResizeElement(
          el.id,
          el.width - d.delta.dx / scale,
          el.height + d.delta.dy / scale,
        );
      }),
      handle(Alignment.bottomRight, onDrag: (d) {
        widget.onResizeElement(
          el.id,
          el.width + d.delta.dx / scale,
          el.height + d.delta.dy / scale,
        );
      }),
      // edges
      handle(Alignment.topCenter, onDrag: (d) {
        widget.onMoveElement(el.id, 0, d.delta.dy / scale);
        widget.onResizeElement(
            el.id, el.width, el.height - d.delta.dy / scale);
      }),
      handle(Alignment.bottomCenter, onDrag: (d) {
        widget.onResizeElement(
            el.id, el.width, el.height + d.delta.dy / scale);
      }),
      handle(Alignment.centerLeft, onDrag: (d) {
        widget.onMoveElement(el.id, d.delta.dx / scale, 0);
        widget.onResizeElement(
            el.id, el.width - d.delta.dx / scale, el.height);
      }),
      handle(Alignment.centerRight, onDrag: (d) {
        widget.onResizeElement(
            el.id, el.width + d.delta.dx / scale, el.height);
      }),
    ];
  }
}

// =============================================================================
// Grid painter
// =============================================================================

class _GridPainter extends CustomPainter {
  final double gridSize;
  _GridPainter({required this.gridSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.black.withValues(alpha: 0.06)
      ..strokeWidth = 0.5;
    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter old) =>
      old.gridSize != gridSize;
}

// =============================================================================
// Shape painter (reused for canvas elements)
// =============================================================================

class _CanvasShapePainter extends CustomPainter {
  final ShapeKind kind;
  final Color fillColor;
  final Color strokeColor;
  final double borderRadius;

  _CanvasShapePainter({
    required this.kind,
    required this.fillColor,
    required this.strokeColor,
    this.borderRadius = 0,
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
        final rr = RRect.fromRectAndRadius(
            rect, Radius.circular(borderRadius));
        canvas.drawRRect(rr, fill);
        canvas.drawRRect(rr, stroke);
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
      if (i == 0) { path.moveTo(x, y); } else { path.lineTo(x, y); }
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
      if (i == 0) { path.moveTo(x, y); } else { path.lineTo(x, y); }
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _CanvasShapePainter old) =>
      old.kind != kind ||
      old.fillColor != fillColor ||
      old.strokeColor != strokeColor ||
      old.borderRadius != borderRadius;
}
