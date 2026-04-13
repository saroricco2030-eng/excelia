import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:excelia/l10n/app_localizations.dart';
import 'package:excelia/providers/presentation_provider.dart';
import 'package:excelia/screens/presentation/widgets/slideshow_element_builder.dart';
import 'package:excelia/utils/constants.dart';

class PresenterView extends StatefulWidget {
  final List<Slide> slides;
  final int startIndex;

  const PresenterView({
    super.key,
    required this.slides,
    this.startIndex = 0,
  });

  @override
  State<PresenterView> createState() => _PresenterViewState();
}

class _PresenterViewState extends State<PresenterView> {
  late int _index;
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  String _elapsed = '00:00';

  @override
  void initState() {
    super.initState();
    _index = widget.startIndex.clamp(0, widget.slides.length - 1);
    _stopwatch.start();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final secs = _stopwatch.elapsed.inSeconds;
      final m = (secs ~/ 60).toString().padLeft(2, '0');
      final s = (secs % 60).toString().padLeft(2, '0');
      setState(() => _elapsed = '$m:$s');
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  void _next() {
    if (_index < widget.slides.length - 1) {
      setState(() => _index++);
    }
  }

  void _prev() {
    if (_index > 0) {
      setState(() => _index--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final slide = widget.slides[_index];
    final hasNext = _index < widget.slides.length - 1;
    final notes = slide.notes.trim();

    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: GestureDetector(
          onTap: _next,
          onHorizontalDragEnd: (d) {
            if (d.primaryVelocity != null) {
              if (d.primaryVelocity! < -100) _next();
              if (d.primaryVelocity! > 100) _prev();
            }
          },
          child: Column(
            children: [
              // Top bar: timer + slide number + close
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: AppColors.black,
                child: Row(
                  children: [
                    const Icon(LucideIcons.timer, color: AppColors.white, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      '${l.presenterElapsed}: $_elapsed',
                      style: const TextStyle(
                          color: AppColors.white, fontSize: 14),
                    ),
                    const Spacer(),
                    Text(
                      '${_index + 1} / ${widget.slides.length}',
                      style: const TextStyle(
                          color: AppColors.white, fontSize: 14),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(LucideIcons.x,
                          color: AppColors.white, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // Main area
              Expanded(
                child: Row(
                  children: [
                    // Current slide (large)
                    Expanded(
                      flex: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: _buildSlidePreview(slide),
                      ),
                    ),

                    // Next slide preview (small)
                    Expanded(
                      flex: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                l.presenterNextSlide,
                                style: const TextStyle(
                                  color: AppColors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Expanded(
                              child: hasNext
                                  ? _buildSlidePreview(
                                      widget.slides[_index + 1])
                                  : Center(
                                      child: Text(
                                        l.presenterEndOfSlides,
                                        style: const TextStyle(
                                          color: AppColors.white,
                                          fontSize: 12,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Notes panel
              Container(
                height: 120,
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.08),
                  border: Border(
                    top: BorderSide(
                      color: AppColors.white.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                child: notes.isEmpty
                    ? Center(
                        child: Text(
                          l.speakerNotes,
                          style: TextStyle(
                            color: AppColors.white.withValues(alpha: 0.4),
                            fontSize: 14,
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        child: Text(
                          notes,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlidePreview(Slide slide) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: BoxDecoration(
          color: slide.backgroundColor,
          borderRadius: BorderRadius.circular(4),
        ),
        clipBehavior: Clip.antiAlias,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scaleX = constraints.maxWidth / 960;
            final scaleY = constraints.maxHeight / 540;
            return Stack(
              children: slide.elements.map((el) {
                return Positioned(
                  left: el.x * scaleX,
                  top: el.y * scaleY,
                  width: el.width * scaleX,
                  height: el.height * scaleY,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.topLeft,
                    child: buildSlideshowElement(el),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }
}
