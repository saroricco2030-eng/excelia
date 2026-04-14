import 'package:flutter/material.dart';

/// Thin horizontal accent line with a continuously-panning gradient.
///
/// Used under editor AppBars to replace the previous solid 2px accent color.
/// The gradient slides left-to-right in a 4-second loop with [TileMode.mirror]
/// so the motion is seamless and direction-agnostic.
///
/// Callers supply their own editor-specific color palette (usually 5 colors
/// starting and ending with the editor's identity color to keep the loop
/// closed).
class AuroraAccentBar extends StatefulWidget {
  final List<Color> colors;

  const AuroraAccentBar({super.key, required this.colors});

  @override
  State<AuroraAccentBar> createState() => _AuroraAccentBarState();
}

class _AuroraAccentBarState extends State<AuroraAccentBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          // Shift gradient stops horizontally for a panning effect.
          // 0..2 range so the gradient travels fully off-screen and
          // mirror tile mode keeps it seamless.
          final shift = 2 * _ctrl.value;
          return Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(-1.0 + shift, 0),
                end: Alignment(1.0 + shift, 0),
                colors: widget.colors,
                tileMode: TileMode.mirror,
              ),
            ),
          );
        },
      ),
    );
  }
}
