import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:excelia/utils/constants.dart';

/// 차트 타입 (9종)
enum ChartType { bar, line, pie, scatter, area, stackedBar, doughnut, radar, combo }

/// 범례 위치
enum LegendPosition { none, top, bottom, left, right }

/// 차트 데이터 모델
class ChartData {
  final String id;
  final ChartType type;
  final String title;
  final List<String> labels;
  final List<double> values;
  final List<Color> colors;

  // 확장 속성
  String? axisXTitle;
  String? axisYTitle;
  bool showGridlines;
  LegendPosition legendPosition;
  List<List<double>>? multiSeries; // 누적/복합용
  List<String>? seriesNames;

  ChartData({
    required this.id,
    required this.type,
    required this.title,
    required this.labels,
    required this.values,
    List<Color>? colors,
    this.axisXTitle,
    this.axisYTitle,
    this.showGridlines = true,
    this.legendPosition = LegendPosition.bottom,
    this.multiSeries,
    this.seriesNames,
  }) : colors = colors ?? _defaultColors(max(values.length, (multiSeries?.length ?? 0)));

  static List<Color> _defaultColors(int count) {
    const palette = [
      AppColors.info,
      AppColors.success,
      AppColors.warning,
      AppColors.error,
      AppColors.purple,
      AppColors.orange,
      AppColors.indigo,
      AppColors.green,
    ];
    return List.generate(count, (i) => palette[i % palette.length]);
  }
}

/// 차트 뷰어 다이얼로그
class ChartViewerDialog extends StatelessWidget {
  final ChartData data;

  const ChartViewerDialog({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 헤더
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.spreadsheetGreen,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    data.title,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x, color: AppColors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
          ),
          // 차트 영역
          Container(
            height: 320,
            padding: const EdgeInsets.all(16),
            child: CustomPaint(
              size: const Size(double.infinity, 288),
              painter: _ChartPainter(data: data),
            ),
          ),
          // 범례
          if (data.legendPosition != LegendPosition.none && data.labels.length <= 12)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Wrap(
                spacing: 12,
                runSpacing: 4,
                children: _buildLegendItems(),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildLegendItems() {
    // 다중 시리즈: 시리즈 이름
    if (data.multiSeries != null && data.seriesNames != null) {
      return List.generate(data.seriesNames!.length, (i) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: data.colors[i % data.colors.length],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 4),
            Text(data.seriesNames![i],
                style: const TextStyle(fontSize: 11, color: AppColors.grey800)),
          ],
        );
      });
    }
    // 단일 시리즈: 라벨
    return List.generate(data.labels.length, (i) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: data.colors[i % data.colors.length],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 4),
          Text(data.labels[i],
              style: const TextStyle(fontSize: 11, color: AppColors.grey800)),
        ],
      );
    });
  }
}

// ═══════════════════════════════════════════════════════════════
// CustomPainter: 차트 렌더링 (9종)
// ═══════════════════════════════════════════════════════════════

class _ChartPainter extends CustomPainter {
  final ChartData data;

  _ChartPainter({required this.data});

  static const _leftPad = 40.0;
  static const _bottomPad = 24.0;
  static const _topPad = 8.0;
  static const _rightPad = 8.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.values.isEmpty) return;

    switch (data.type) {
      case ChartType.bar:
        _paintBarChart(canvas, size);
      case ChartType.line:
        _paintLineChart(canvas, size);
      case ChartType.pie:
        _paintPieChart(canvas, size);
      case ChartType.scatter:
        _paintScatterChart(canvas, size);
      case ChartType.area:
        _paintAreaChart(canvas, size);
      case ChartType.stackedBar:
        _paintStackedBarChart(canvas, size);
      case ChartType.doughnut:
        _paintDoughnutChart(canvas, size);
      case ChartType.radar:
        _paintRadarChart(canvas, size);
      case ChartType.combo:
        _paintComboChart(canvas, size);
    }
  }

  // ─── 공용 헬퍼 ────────────────────────────────────────

  void _drawGrid(Canvas canvas, Size size, double maxVal, double minVal) {
    if (!data.showGridlines) return;
    final range = maxVal - minVal;
    if (range == 0) return;

    final chartH = size.height - _bottomPad - _topPad;
    final axisPaint = Paint()..color = AppColors.grey300..strokeWidth = 0.5;
    final textStyle = const TextStyle(fontSize: 10, color: AppColors.grey600);

    for (int i = 0; i <= 4; i++) {
      final y = _topPad + chartH * i / 4;
      canvas.drawLine(Offset(_leftPad, y), Offset(size.width - _rightPad, y), axisPaint);
      final label = (maxVal - (range * i / 4)).toStringAsFixed(range > 10 ? 0 : 1);
      final tp = TextPainter(
        text: TextSpan(text: label, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: _leftPad - 4);
      tp.paint(canvas, Offset(_leftPad - tp.width - 4, y - tp.height / 2));
    }
  }

  void _drawXLabels(Canvas canvas, Size size, List<Offset> points) {
    final textStyle = const TextStyle(fontSize: 10, color: AppColors.grey600);
    final chartH = size.height - _bottomPad - _topPad;
    for (int i = 0; i < points.length && i < data.labels.length; i++) {
      final tp = TextPainter(
        text: TextSpan(text: data.labels[i], style: textStyle),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '\u2026',
      )..layout(maxWidth: 60);
      tp.paint(canvas, Offset(points[i].dx - tp.width / 2, _topPad + chartH + 4));
    }
  }

  // ─── 막대 차트 ────────────────────────────────────────

  void _paintBarChart(Canvas canvas, Size size) {
    final n = data.values.length;
    if (n == 0) return;

    final maxVal = data.values.reduce(max);
    final minVal = min(0.0, data.values.reduce(min));
    final range = maxVal - minVal;
    if (range == 0) return;

    final chartW = size.width - _leftPad;
    final chartH = size.height - _bottomPad - _topPad;
    final barW = (chartW / n) * 0.7;
    final gap = (chartW / n) * 0.3;

    _drawGrid(canvas, size, maxVal, minVal);

    for (int i = 0; i < n; i++) {
      final val = data.values[i];
      final barH = (val - minVal) / range * chartH;
      final x = _leftPad + i * (barW + gap) + gap / 2;
      final y = _topPad + chartH - barH;

      final paint = Paint()..color = data.colors[i % data.colors.length]..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(x, y, barW, barH),
          topLeft: const Radius.circular(3),
          topRight: const Radius.circular(3),
        ),
        paint,
      );
    }
    final pts = List.generate(n, (i) {
      final barW2 = (chartW / n) * 0.7;
      final gap2 = (chartW / n) * 0.3;
      return Offset(_leftPad + i * (barW2 + gap2) + gap2 / 2 + barW2 / 2, 0);
    });
    _drawXLabels(canvas, size, pts);
  }

  // ─── 꺾은선 차트 ──────────────────────────────────────

  void _paintLineChart(Canvas canvas, Size size) {
    final n = data.values.length;
    if (n < 2) return;

    final maxVal = data.values.reduce(max);
    final minVal = data.values.reduce(min);
    final range = maxVal - minVal;
    if (range == 0) return;

    final chartW = size.width - _leftPad - _rightPad;
    final chartH = size.height - _bottomPad - _topPad;

    _drawGrid(canvas, size, maxVal, minVal);

    final linePaint = Paint()
      ..color = data.colors[0]
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final points = <Offset>[];

    for (int i = 0; i < n; i++) {
      final x = _leftPad + (i / (n - 1)) * chartW;
      final y = _topPad + (1 - (data.values[i] - minVal) / range) * chartH;
      points.add(Offset(x, y));
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()..color = data.colors[0]..style = PaintingStyle.fill;
    final dotBorder = Paint()..color = AppColors.white..strokeWidth = 2..style = PaintingStyle.stroke;
    for (final p in points) {
      canvas.drawCircle(p, 4, dotBorder);
      canvas.drawCircle(p, 3, dotPaint);
    }
    _drawXLabels(canvas, size, points);
  }

  // ─── 원형 차트 ────────────────────────────────────────

  void _paintPieChart(Canvas canvas, Size size) {
    _paintCircularChart(canvas, size, 0);
  }

  // ─── 도넛 차트 ────────────────────────────────────────

  void _paintDoughnutChart(Canvas canvas, Size size) {
    _paintCircularChart(canvas, size, 0.55);
  }

  void _paintCircularChart(Canvas canvas, Size size, double holeRatio) {
    final n = data.values.length;
    if (n == 0) return;

    final total = data.values.fold(0.0, (a, b) => a + b.abs());
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 16;
    final rect = Rect.fromCircle(center: center, radius: radius);

    double startAngle = -pi / 2;

    for (int i = 0; i < n; i++) {
      final sweepAngle = (data.values[i].abs() / total) * 2 * pi;
      final paint = Paint()..color = data.colors[i % data.colors.length]..style = PaintingStyle.fill;
      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);
      canvas.drawArc(rect, startAngle, sweepAngle, true,
        Paint()..color = AppColors.white..strokeWidth = 2..style = PaintingStyle.stroke);

      if (sweepAngle > 0.3) {
        final midAngle = startAngle + sweepAngle / 2;
        final labelR = radius * (holeRatio > 0 ? (1 + holeRatio) / 2 : 0.65);
        final lx = center.dx + labelR * cos(midAngle);
        final ly = center.dy + labelR * sin(midAngle);
        final pct = (data.values[i].abs() / total * 100).toStringAsFixed(1);
        final tp = TextPainter(
          text: TextSpan(text: '$pct%',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.white)),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(lx - tp.width / 2, ly - tp.height / 2));
      }
      startAngle += sweepAngle;
    }

    // 도넛 구멍
    if (holeRatio > 0) {
      canvas.drawCircle(center, radius * holeRatio,
        Paint()..color = AppColors.white..style = PaintingStyle.fill);
    }
  }

  // ─── 산점도 ───────────────────────────────────────────

  void _paintScatterChart(Canvas canvas, Size size) {
    final n = data.values.length;
    if (n == 0) return;

    final maxVal = data.values.reduce(max);
    final minVal = data.values.reduce(min);
    final range = maxVal - minVal;
    if (range == 0) return;

    final chartW = size.width - _leftPad - _rightPad;
    final chartH = size.height - _bottomPad - _topPad;

    _drawGrid(canvas, size, maxVal, minVal);

    final points = <Offset>[];
    for (int i = 0; i < n; i++) {
      final x = _leftPad + (i / max(1, n - 1)) * chartW;
      final y = _topPad + (1 - (data.values[i] - minVal) / range) * chartH;
      points.add(Offset(x, y));

      final dotPaint = Paint()..color = data.colors[i % data.colors.length]..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), 5, dotPaint);
      canvas.drawCircle(Offset(x, y), 5,
        Paint()..color = AppColors.white..strokeWidth = 1.5..style = PaintingStyle.stroke);
    }
    _drawXLabels(canvas, size, points);
  }

  // ─── 영역 차트 ────────────────────────────────────────

  void _paintAreaChart(Canvas canvas, Size size) {
    final n = data.values.length;
    if (n < 2) return;

    final maxVal = data.values.reduce(max);
    final minVal = data.values.reduce(min);
    final range = maxVal - minVal;
    if (range == 0) return;

    final chartW = size.width - _leftPad - _rightPad;
    final chartH = size.height - _bottomPad - _topPad;

    _drawGrid(canvas, size, maxVal, minVal);

    final fillPath = Path();
    final linePath = Path();
    final points = <Offset>[];

    for (int i = 0; i < n; i++) {
      final x = _leftPad + (i / (n - 1)) * chartW;
      final y = _topPad + (1 - (data.values[i] - minVal) / range) * chartH;
      points.add(Offset(x, y));
      if (i == 0) {
        fillPath.moveTo(x, _topPad + chartH);
        fillPath.lineTo(x, y);
        linePath.moveTo(x, y);
      } else {
        fillPath.lineTo(x, y);
        linePath.lineTo(x, y);
      }
    }
    fillPath.lineTo(points.last.dx, _topPad + chartH);
    fillPath.close();

    canvas.drawPath(fillPath,
      Paint()..color = data.colors[0].withValues(alpha: 0.25)..style = PaintingStyle.fill);
    canvas.drawPath(linePath,
      Paint()..color = data.colors[0]..strokeWidth = 2..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round);

    _drawXLabels(canvas, size, points);
  }

  // ─── 누적 막대 차트 ───────────────────────────────────

  void _paintStackedBarChart(Canvas canvas, Size size) {
    final series = data.multiSeries;
    if (series == null || series.isEmpty) {
      _paintBarChart(canvas, size);
      return;
    }

    final n = series[0].length;
    if (n == 0) return;

    // 각 카테고리별 합계 → 최대값
    double maxSum = 0;
    for (int i = 0; i < n; i++) {
      double sum = 0;
      for (final s in series) {
        if (i < s.length) sum += s[i].abs();
      }
      if (sum > maxSum) maxSum = sum;
    }
    if (maxSum == 0) return;

    final chartW = size.width - _leftPad - _rightPad;
    final chartH = size.height - _bottomPad - _topPad;
    final barW = (chartW / n) * 0.7;
    final gap = (chartW / n) * 0.3;

    _drawGrid(canvas, size, maxSum, 0);

    final pts = <Offset>[];
    for (int i = 0; i < n; i++) {
      final x = _leftPad + i * (barW + gap) + gap / 2;
      pts.add(Offset(x + barW / 2, 0));
      double stackY = _topPad + chartH;

      for (int s = 0; s < series.length; s++) {
        final val = i < series[s].length ? series[s][i].abs() : 0.0;
        final barH = val / maxSum * chartH;
        stackY -= barH;

        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(x, stackY, barW, barH), const Radius.circular(1)),
          Paint()..color = data.colors[s % data.colors.length]..style = PaintingStyle.fill,
        );
      }
    }
    _drawXLabels(canvas, size, pts);
  }

  // ─── 방사형 차트 ──────────────────────────────────────

  void _paintRadarChart(Canvas canvas, Size size) {
    final n = data.values.length;
    if (n < 3) return;

    final maxVal = data.values.reduce(max);
    if (maxVal == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 32;

    // 배경 축
    final axisPaint = Paint()..color = AppColors.grey300..strokeWidth = 0.5..style = PaintingStyle.stroke;
    final textStyle = const TextStyle(fontSize: 10, color: AppColors.grey600);

    for (int ring = 1; ring <= 4; ring++) {
      final r = radius * ring / 4;
      final ringPath = Path();
      for (int i = 0; i <= n; i++) {
        final angle = -pi / 2 + (2 * pi * (i % n) / n);
        final x = center.dx + r * cos(angle);
        final y = center.dy + r * sin(angle);
        if (i == 0) {
          ringPath.moveTo(x, y);
        } else {
          ringPath.lineTo(x, y);
        }
      }
      canvas.drawPath(ringPath, axisPaint);
    }

    // 축 선
    for (int i = 0; i < n; i++) {
      final angle = -pi / 2 + (2 * pi * i / n);
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      canvas.drawLine(center, Offset(x, y), axisPaint);

      // 라벨
      if (i < data.labels.length) {
        final labelX = center.dx + (radius + 14) * cos(angle);
        final labelY = center.dy + (radius + 14) * sin(angle);
        final tp = TextPainter(
          text: TextSpan(text: data.labels[i], style: textStyle),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        )..layout(maxWidth: 60);
        tp.paint(canvas, Offset(labelX - tp.width / 2, labelY - tp.height / 2));
      }
    }

    // 데이터 다각형
    final dataPath = Path();
    for (int i = 0; i <= n; i++) {
      final idx = i % n;
      final angle = -pi / 2 + (2 * pi * idx / n);
      final r = (data.values[idx] / maxVal) * radius;
      final x = center.dx + r * cos(angle);
      final y = center.dy + r * sin(angle);
      if (i == 0) {
        dataPath.moveTo(x, y);
      } else {
        dataPath.lineTo(x, y);
      }
    }

    canvas.drawPath(dataPath,
      Paint()..color = data.colors[0].withValues(alpha: 0.2)..style = PaintingStyle.fill);
    canvas.drawPath(dataPath,
      Paint()..color = data.colors[0]..strokeWidth = 2..style = PaintingStyle.stroke);

    // 데이터 포인트
    for (int i = 0; i < n; i++) {
      final angle = -pi / 2 + (2 * pi * i / n);
      final r = (data.values[i] / maxVal) * radius;
      final x = center.dx + r * cos(angle);
      final y = center.dy + r * sin(angle);
      canvas.drawCircle(Offset(x, y), 4, Paint()..color = data.colors[0]..style = PaintingStyle.fill);
    }
  }

  // ─── 복합 차트 (막대 + 선) ────────────────────────────

  void _paintComboChart(Canvas canvas, Size size) {
    final series = data.multiSeries;
    if (series == null || series.length < 2) {
      _paintBarChart(canvas, size);
      return;
    }

    final barData = series[0];
    final lineData = series[1];
    final n = barData.length;
    if (n == 0) return;

    final allVals = [...barData, ...lineData];
    final maxVal = allVals.reduce(max);
    final minVal = min(0.0, allVals.reduce(min));
    final range = maxVal - minVal;
    if (range == 0) return;

    final chartW = size.width - _leftPad - _rightPad;
    final chartH = size.height - _bottomPad - _topPad;
    final barW = (chartW / n) * 0.5;
    final gap = (chartW / n) * 0.5;

    _drawGrid(canvas, size, maxVal, minVal);

    // 막대
    final barColor = data.colors[0];
    final pts = <Offset>[];
    for (int i = 0; i < n; i++) {
      final val = barData[i];
      final barH = (val - minVal) / range * chartH;
      final x = _leftPad + i * (barW + gap) + gap / 2;
      final y = _topPad + chartH - barH;
      pts.add(Offset(x + barW / 2, 0));

      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(x, y, barW, barH),
          topLeft: const Radius.circular(3),
          topRight: const Radius.circular(3),
        ),
        Paint()..color = barColor..style = PaintingStyle.fill,
      );
    }

    // 선
    final lineColor = data.colors.length > 1 ? data.colors[1] : AppColors.error;
    final linePaint = Paint()
      ..color = lineColor..strokeWidth = 2.5..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round;
    final linePath = Path();
    final linePoints = <Offset>[];

    for (int i = 0; i < min(n, lineData.length); i++) {
      final x = _leftPad + i * (barW + gap) + gap / 2 + barW / 2;
      final y = _topPad + (1 - (lineData[i] - minVal) / range) * chartH;
      linePoints.add(Offset(x, y));
      if (i == 0) {
        linePath.moveTo(x, y);
      } else {
        linePath.lineTo(x, y);
      }
    }
    canvas.drawPath(linePath, linePaint);

    final dotPaint = Paint()..color = lineColor..style = PaintingStyle.fill;
    for (final p in linePoints) {
      canvas.drawCircle(p, 4, Paint()..color = AppColors.white..strokeWidth = 2..style = PaintingStyle.stroke);
      canvas.drawCircle(p, 3, dotPaint);
    }

    _drawXLabels(canvas, size, pts);
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) =>
      !identical(data, old.data);
}
