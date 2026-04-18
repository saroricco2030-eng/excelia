import 'package:flutter/material.dart';

/// Thin horizontal accent line with a continuously-panning gradient.
///
/// Used under editor AppBars to replace the previous solid 2px accent color.
/// The gradient slides left-to-right with [TileMode.mirror] so the motion
/// is seamless and direction-agnostic.
///
/// **Performance note**: when [opacity] is set to 0 the widget renders a
/// static solid bar (no AnimationController, no per-frame rebuild). Editor
/// AppBars in heavy modes can pass `opacity: 0` to fully disable the
/// animation cost.
class AuroraAccentBar extends StatefulWidget {
  final List<Color> colors;

  /// Global opacity for the whole bar. 1.0 = full strength (home / identity
  /// moments). 0.35 = subdued (editor views where content must lead — Gestalt
  /// Figure/Ground). 0 = completely static (no animation cost).
  final double opacity;

  const AuroraAccentBar({
    super.key,
    required this.colors,
    this.opacity = 1.0,
  });

  @override
  State<AuroraAccentBar> createState() => _AuroraAccentBarState();
}

class _AuroraAccentBarState extends State<AuroraAccentBar>
    with SingleTickerProviderStateMixin {
  AnimationController? _ctrl;

  @override
  void initState() {
    super.initState();
    if (widget.opacity > 0) {
      _ctrl = AnimationController(
        vsync: this,
        // Slowed from 4s → 8s. The motion is still readable but each minute
        // costs half the rebuilds. Combined with TileMode.mirror this is
        // effectively imperceptible to the eye while halving GPU draws.
        duration: const Duration(seconds: 8),
      )..repeat();
    }
  }

  @override
  void didUpdateWidget(covariant AuroraAccentBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If opacity flipped on/off mid-life, allocate or release the controller.
    if (widget.opacity > 0 && _ctrl == null) {
      _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 8),
      )..repeat();
    } else if (widget.opacity <= 0 && _ctrl != null) {
      _ctrl!.dispose();
      _ctrl = null;
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = _ctrl;
    // Static path — zero AnimationController cost.
    if (ctrl == null) {
      return RepaintBoundary(
        child: Container(
          height: 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: widget.colors),
          ),
        ),
      );
    }
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: ctrl,
        builder: (context, _) {
          // Shift gradient stops horizontally for a panning effect.
          final shift = 2 * ctrl.value;
          final bar = Container(
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
          if (widget.opacity >= 0.999) return bar;
          return Opacity(opacity: widget.opacity.clamp(0.0, 1.0), child: bar);
        },
      ),
    );
  }
}
