import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:excelia/utils/constants.dart';
import 'package:excelia/utils/pptx_parser.dart';
import 'package:excelia/utils/pptx_writer.dart';

// =============================================================================
// SlideElement – a single element on a slide (text, shape, image)
// =============================================================================

enum SlideElementType { text, shape, image }

enum ShapeKind { rectangle, circle, triangle, arrow, star, hexagon, diamond, pentagon }

// ─── 슬라이드 전환 ─────────────────────────────────────
enum SlideTransitionType { none, fade, push, wipe, zoom }

// ─── 요소 애니메이션 ───────────────────────────────────
enum AnimationType { fadeIn, fadeOut, flyInLeft, flyInRight, flyInBottom, zoomIn }
enum AnimationTrigger { onClick, withPrevious, afterPrevious }

class ElementAnimation {
  final String elementId;
  final AnimationType type;
  final AnimationTrigger trigger;
  final int durationMs;
  final int delayMs;

  const ElementAnimation({
    required this.elementId,
    this.type = AnimationType.fadeIn,
    this.trigger = AnimationTrigger.onClick,
    this.durationMs = 500,
    this.delayMs = 0,
  });

  Map<String, dynamic> toJson() => {
        'elementId': elementId,
        'type': type.index,
        'trigger': trigger.index,
        'durationMs': durationMs,
        'delayMs': delayMs,
      };

  factory ElementAnimation.fromJson(Map<String, dynamic> json) =>
      ElementAnimation(
        elementId: json['elementId'] as String,
        type: AnimationType.values[json['type'] as int? ?? 0],
        trigger: AnimationTrigger.values[json['trigger'] as int? ?? 0],
        durationMs: json['durationMs'] as int? ?? 500,
        delayMs: json['delayMs'] as int? ?? 0,
      );
}

class SlideElement {
  final String id;
  SlideElementType type;
  double x;
  double y;
  double width;
  double height;
  String content; // text content, image path, or shape kind name
  ShapeKind? shapeKind;

  // Style
  Color color;
  Color? backgroundColor;
  double fontSize;
  FontWeight fontWeight;
  bool italic;
  bool underline;
  bool strikethrough;
  String? fontFamily;
  TextAlign textAlign;
  double borderRadius;
  double rotation; // degrees

  SlideElement({
    String? id,
    required this.type,
    this.x = 0,
    this.y = 0,
    this.width = 200,
    this.height = 100,
    this.content = '',
    this.shapeKind,
    this.color = AppColors.black,
    this.backgroundColor,
    this.fontSize = 18,
    this.fontWeight = FontWeight.normal,
    this.italic = false,
    this.underline = false,
    this.strikethrough = false,
    this.fontFamily,
    this.textAlign = TextAlign.left,
    this.borderRadius = 0,
    this.rotation = 0,
  }) : id = id ?? const Uuid().v4();

  SlideElement copyWith({
    String? id,
    SlideElementType? type,
    double? x,
    double? y,
    double? width,
    double? height,
    String? content,
    ShapeKind? shapeKind,
    Color? color,
    Color? backgroundColor,
    double? fontSize,
    FontWeight? fontWeight,
    bool? italic,
    bool? underline,
    bool? strikethrough,
    String? fontFamily,
    TextAlign? textAlign,
    double? borderRadius,
    double? rotation,
  }) {
    return SlideElement(
      id: id ?? this.id,
      type: type ?? this.type,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      content: content ?? this.content,
      shapeKind: shapeKind ?? this.shapeKind,
      color: color ?? this.color,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      fontSize: fontSize ?? this.fontSize,
      fontWeight: fontWeight ?? this.fontWeight,
      italic: italic ?? this.italic,
      underline: underline ?? this.underline,
      strikethrough: strikethrough ?? this.strikethrough,
      fontFamily: fontFamily ?? this.fontFamily,
      textAlign: textAlign ?? this.textAlign,
      borderRadius: borderRadius ?? this.borderRadius,
      rotation: rotation ?? this.rotation,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.index,
        'x': x,
        'y': y,
        'width': width,
        'height': height,
        'content': content,
        'shapeKind': shapeKind?.index,
        'color': color.toARGB32(),
        'backgroundColor': backgroundColor?.toARGB32(),
        'fontSize': fontSize,
        'fontWeight': fontWeight.index,
        'italic': italic,
        'underline': underline,
        'strikethrough': strikethrough,
        'fontFamily': fontFamily,
        'textAlign': textAlign.index,
        'borderRadius': borderRadius,
        'rotation': rotation,
      };

  factory SlideElement.fromJson(Map<String, dynamic> json) {
    return SlideElement(
      id: json['id'] as String,
      type: SlideElementType.values[json['type'] as int],
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      content: json['content'] as String? ?? '',
      shapeKind: json['shapeKind'] != null
          ? ShapeKind.values[json['shapeKind'] as int]
          : null,
      color: Color(json['color'] as int),
      backgroundColor: json['backgroundColor'] != null
          ? Color(json['backgroundColor'] as int)
          : null,
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 18,
      fontWeight:
          FontWeight.values[(json['fontWeight'] as int?) ?? 3],
      italic: json['italic'] as bool? ?? false,
      underline: json['underline'] as bool? ?? false,
      strikethrough: json['strikethrough'] as bool? ?? false,
      fontFamily: json['fontFamily'] as String?,
      textAlign:
          TextAlign.values[(json['textAlign'] as int?) ?? 0],
      borderRadius: (json['borderRadius'] as num?)?.toDouble() ?? 0,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0,
    );
  }
}

// =============================================================================
// Slide
// =============================================================================

class Slide {
  final String id;
  String title;
  Color backgroundColor;
  List<SlideElement> elements;

  // 전환 효과
  SlideTransitionType transition;
  int transitionDurationMs;

  // 발표자 노트
  String notes;

  // 요소 애니메이션
  List<ElementAnimation> animations;

  Slide({
    String? id,
    this.title = '',
    this.backgroundColor = AppColors.white,
    List<SlideElement>? elements,
    this.transition = SlideTransitionType.none,
    this.transitionDurationMs = 500,
    this.notes = '',
    List<ElementAnimation>? animations,
  })  : id = id ?? const Uuid().v4(),
        elements = elements ?? [],
        animations = animations ?? [];

  Slide copyWith({
    String? id,
    String? title,
    Color? backgroundColor,
    List<SlideElement>? elements,
    SlideTransitionType? transition,
    int? transitionDurationMs,
    String? notes,
    List<ElementAnimation>? animations,
  }) {
    return Slide(
      id: id ?? this.id,
      title: title ?? this.title,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      elements:
          elements ?? this.elements.map((e) => e.copyWith()).toList(),
      transition: transition ?? this.transition,
      transitionDurationMs: transitionDurationMs ?? this.transitionDurationMs,
      notes: notes ?? this.notes,
      animations: animations ?? List.from(this.animations),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'backgroundColor': backgroundColor.toARGB32(),
        'elements': elements.map((e) => e.toJson()).toList(),
        'transition': transition.index,
        'transitionDurationMs': transitionDurationMs,
        'notes': notes,
        'animations': animations.map((a) => a.toJson()).toList(),
      };

  factory Slide.fromJson(Map<String, dynamic> json) {
    return Slide(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      backgroundColor: Color(json['backgroundColor'] as int),
      elements: (json['elements'] as List<dynamic>?)
              ?.map(
                  (e) => SlideElement.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      transition: json['transition'] != null
          ? SlideTransitionType.values[json['transition'] as int]
          : SlideTransitionType.none,
      transitionDurationMs: json['transitionDurationMs'] as int? ?? 500,
      notes: json['notes'] as String? ?? '',
      animations: (json['animations'] as List<dynamic>?)
              ?.map((a) => ElementAnimation.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

// =============================================================================
// PresentationProvider
// =============================================================================

/// Undo/Redo 스냅샷
class _PresentationSnapshot {
  final List<Slide> slides;
  final int currentIndex;
  final String? selectedElementId;

  _PresentationSnapshot({
    required this.slides,
    required this.currentIndex,
    required this.selectedElementId,
  });
}

class PresentationProvider extends ChangeNotifier {
  List<Slide> _slides = [];
  int _currentIndex = 0;
  String _title = 'Untitled Presentation';
  String? _filePath;
  bool _isDirty = false;
  DateTime? _lastSavedAt;
  String? _selectedElementId;
  bool _showPropertiesPanel = false;
  bool _gridSnap = false;
  static const double gridSize = 16;

  // Undo / Redo
  final List<_PresentationSnapshot> _undoStack = [];
  final List<_PresentationSnapshot> _redoStack = [];
  static const int _maxUndo = SpreadsheetDefaults.maxUndoStack;

  // Getters
  List<Slide> get slides => _slides;
  int get currentIndex => _currentIndex;
  Slide? get currentSlide {
    if (_slides.isEmpty) return null;
    if (_currentIndex < 0 || _currentIndex >= _slides.length) return null;
    return _slides[_currentIndex];
  }
  String get title => _title;
  String? get filePath => _filePath;
  bool get isDirty => _isDirty;
  DateTime? get lastSavedAt => _lastSavedAt;
  String? get selectedElementId => _selectedElementId;
  bool get showPropertiesPanel => _showPropertiesPanel;
  bool get gridSnap => _gridSnap;
  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  SlideElement? get selectedElement {
    if (_selectedElementId == null || currentSlide == null) return null;
    try {
      return currentSlide!.elements
          .firstWhere((e) => e.id == _selectedElementId);
    } catch (e) {
      debugPrint('Presentation selectedElement lookup failed: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Undo / Redo
  // ---------------------------------------------------------------------------

  void _pushUndo() {
    final snap = _PresentationSnapshot(
      slides: _slides.map((s) => s.copyWith()).toList(),
      currentIndex: _currentIndex,
      selectedElementId: _selectedElementId,
    );
    _undoStack.add(snap);
    if (_undoStack.length > _maxUndo) _undoStack.removeAt(0);
    _redoStack.clear();
  }

  void undo() {
    if (_undoStack.isEmpty) return;
    // Save current state to redo stack
    _redoStack.add(_PresentationSnapshot(
      slides: _slides.map((s) => s.copyWith()).toList(),
      currentIndex: _currentIndex,
      selectedElementId: _selectedElementId,
    ));
    final snap = _undoStack.removeLast();
    _slides = snap.slides;
    _currentIndex = _slides.isEmpty
        ? 0
        : snap.currentIndex.clamp(0, _slides.length - 1);
    _selectedElementId = snap.selectedElementId;
    _isDirty = true;
    notifyListeners();
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    // Save current state to undo stack
    _undoStack.add(_PresentationSnapshot(
      slides: _slides.map((s) => s.copyWith()).toList(),
      currentIndex: _currentIndex,
      selectedElementId: _selectedElementId,
    ));
    final snap = _redoStack.removeLast();
    _slides = snap.slides;
    _currentIndex = _slides.isEmpty
        ? 0
        : snap.currentIndex.clamp(0, _slides.length - 1);
    _selectedElementId = snap.selectedElementId;
    _isDirty = true;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  void createNew({
    String? defaultTitle,
    String? titleSlideLabel,
    String? presentationTitleText,
    String? subtitleHint,
  }) {
    _slides = [
      Slide(
        title: titleSlideLabel ?? 'Title Slide',
        elements: [
          SlideElement(
            type: SlideElementType.text,
            x: 80,
            y: 120,
            width: 800,
            height: 80,
            content: presentationTitleText ?? 'Presentation Title',
            fontSize: 44,
            fontWeight: FontWeight.bold,
            textAlign: TextAlign.center,
            color: const Color(0xFF333333),
          ),
          SlideElement(
            type: SlideElementType.text,
            x: 200,
            y: 240,
            width: 560,
            height: 48,
            content: subtitleHint ?? 'Enter subtitle',
            fontSize: 22,
            color: AppColors.grey500,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ];
    _currentIndex = 0;
    _title = defaultTitle ?? 'Untitled Presentation';
    _filePath = null;
    _isDirty = false;
    _selectedElementId = null;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Slide CRUD
  // ---------------------------------------------------------------------------

  void addSlide({String? slideLabel, String? titleHint}) {
    _pushUndo();
    final slide = Slide(
      title: slideLabel ?? 'Slide ${_slides.length + 1}',
      elements: [
        SlideElement(
          type: SlideElementType.text,
          x: 60,
          y: 40,
          width: 840,
          height: 60,
          content: titleHint ?? 'Enter title',
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF333333),
        ),
      ],
    );
    _slides.add(slide);
    _currentIndex = _slides.length - 1;
    _isDirty = true;
    notifyListeners();
  }

  void deleteSlide(int index) {
    if (_slides.length <= 1) return; // keep at least one
    _pushUndo();
    _slides.removeAt(index);
    if (_currentIndex >= _slides.length) {
      _currentIndex = _slides.length - 1;
    }
    _selectedElementId = null;
    _isDirty = true;
    notifyListeners();
  }

  void duplicateSlide(int index) {
    if (index < 0 || index >= _slides.length) return;
    _pushUndo();
    final copy = _slides[index].copyWith(id: const Uuid().v4());
    _slides.insert(index + 1, copy);
    _currentIndex = index + 1;
    _isDirty = true;
    notifyListeners();
  }

  void reorderSlide(int from, int to) {
    if (from == to) return;
    _pushUndo();
    final slide = _slides.removeAt(from);
    _slides.insert(to, slide);
    _currentIndex = to;
    _isDirty = true;
    notifyListeners();
  }

  void setCurrentSlide(int index) {
    if (index < 0 || index >= _slides.length) return;
    _currentIndex = index;
    _selectedElementId = null;
    notifyListeners();
  }

  void setSlideBackground(int index, Color color) {
    if (index < 0 || index >= _slides.length) return;
    _pushUndo();
    _slides[index].backgroundColor = color;
    _isDirty = true;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Element CRUD
  // ---------------------------------------------------------------------------

  void addElement(int slideIndex, SlideElement element) {
    if (slideIndex < 0 || slideIndex >= _slides.length) return;
    _pushUndo();
    _slides[slideIndex].elements.add(element);
    _selectedElementId = element.id;
    _isDirty = true;
    notifyListeners();
  }

  void updateElement(int slideIndex, String elementId,
      SlideElement Function(SlideElement) updater) {
    if (slideIndex < 0 || slideIndex >= _slides.length) return;
    _pushUndo();
    final elements = _slides[slideIndex].elements;
    final idx = elements.indexWhere((e) => e.id == elementId);
    if (idx == -1) return;
    elements[idx] = updater(elements[idx]);
    _isDirty = true;
    notifyListeners();
  }

  void deleteElement(int slideIndex, String elementId) {
    if (slideIndex < 0 || slideIndex >= _slides.length) return;
    _pushUndo();
    _slides[slideIndex].elements.removeWhere((e) => e.id == elementId);
    if (_selectedElementId == elementId) _selectedElementId = null;
    _isDirty = true;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Z-order controls
  // ---------------------------------------------------------------------------

  void bringToFront(int slideIndex, String elementId) {
    if (slideIndex < 0 || slideIndex >= _slides.length) return;
    final elements = _slides[slideIndex].elements;
    final idx = elements.indexWhere((e) => e.id == elementId);
    if (idx == -1 || idx == elements.length - 1) return;
    _pushUndo();
    final el = elements.removeAt(idx);
    elements.add(el);
    _isDirty = true;
    notifyListeners();
  }

  void sendToBack(int slideIndex, String elementId) {
    if (slideIndex < 0 || slideIndex >= _slides.length) return;
    final elements = _slides[slideIndex].elements;
    final idx = elements.indexWhere((e) => e.id == elementId);
    if (idx <= 0) return;
    _pushUndo();
    final el = elements.removeAt(idx);
    elements.insert(0, el);
    _isDirty = true;
    notifyListeners();
  }

  void bringForward(int slideIndex, String elementId) {
    if (slideIndex < 0 || slideIndex >= _slides.length) return;
    final elements = _slides[slideIndex].elements;
    final idx = elements.indexWhere((e) => e.id == elementId);
    if (idx == -1 || idx == elements.length - 1) return;
    _pushUndo();
    final tmp = elements[idx];
    elements[idx] = elements[idx + 1];
    elements[idx + 1] = tmp;
    _isDirty = true;
    notifyListeners();
  }

  void sendBackward(int slideIndex, String elementId) {
    if (slideIndex < 0 || slideIndex >= _slides.length) return;
    final elements = _slides[slideIndex].elements;
    final idx = elements.indexWhere((e) => e.id == elementId);
    if (idx <= 0) return;
    _pushUndo();
    final tmp = elements[idx];
    elements[idx] = elements[idx - 1];
    elements[idx - 1] = tmp;
    _isDirty = true;
    notifyListeners();
  }

  void duplicateElement(int slideIndex, String elementId) {
    if (slideIndex < 0 || slideIndex >= _slides.length) return;
    _pushUndo();
    final elements = _slides[slideIndex].elements;
    final idx = elements.indexWhere((e) => e.id == elementId);
    if (idx == -1) return;
    final original = elements[idx];
    final copy = original.copyWith(
      id: const Uuid().v4(),
      x: original.x + 20,
      y: original.y + 20,
    );
    elements.insert(idx + 1, copy);
    _selectedElementId = copy.id;
    _isDirty = true;
    notifyListeners();
  }

  void insertSlide(int index, Slide slide) {
    _slides.insert(index.clamp(0, _slides.length), slide);
    _isDirty = true;
    notifyListeners();
  }

  void insertElement(int slideIndex, int elementIndex, SlideElement element) {
    if (slideIndex < 0 || slideIndex >= _slides.length) return;
    _slides[slideIndex].elements.insert(
      elementIndex.clamp(0, _slides[slideIndex].elements.length),
      element,
    );
    _isDirty = true;
    notifyListeners();
  }

  void selectElement(String? id) {
    _selectedElementId = id;
    notifyListeners();
  }

  void moveElement(String elementId, double dx, double dy) {
    if (currentSlide == null) return;
    final idx =
        currentSlide!.elements.indexWhere((e) => e.id == elementId);
    if (idx == -1) return;
    final el = currentSlide!.elements[idx];
    double newX = el.x + dx;
    double newY = el.y + dy;
    if (_gridSnap) {
      newX = (newX / gridSize).round() * gridSize;
      newY = (newY / gridSize).round() * gridSize;
    }
    el.x = newX.clamp(0, 960 - el.width);
    el.y = newY.clamp(0, 540 - el.height);
    _isDirty = true;
    notifyListeners();
  }

  void resizeElement(
      String elementId, double newWidth, double newHeight) {
    if (currentSlide == null) return;
    final idx =
        currentSlide!.elements.indexWhere((e) => e.id == elementId);
    if (idx == -1) return;
    final el = currentSlide!.elements[idx];
    el.width = newWidth.clamp(24, 960 - el.x);
    el.height = newHeight.clamp(24, 540 - el.y);
    _isDirty = true;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // UI toggles
  // ---------------------------------------------------------------------------

  void togglePropertiesPanel() {
    _showPropertiesPanel = !_showPropertiesPanel;
    notifyListeners();
  }

  void toggleGridSnap() {
    _gridSnap = !_gridSnap;
    notifyListeners();
  }

  void setTitle(String newTitle) {
    if (newTitle.trim().isEmpty) return;
    _title = newTitle.trim();
    _isDirty = true;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Slide Transitions
  // ---------------------------------------------------------------------------

  void setSlideTransition(int index, SlideTransitionType type) {
    if (index < 0 || index >= _slides.length) return;
    _pushUndo();
    _slides[index].transition = type;
    _isDirty = true;
    notifyListeners();
  }

  void setSlideTransitionDuration(int index, int ms) {
    if (index < 0 || index >= _slides.length) return;
    _pushUndo();
    _slides[index].transitionDurationMs = ms.clamp(100, 3000);
    _isDirty = true;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Speaker Notes
  // ---------------------------------------------------------------------------

  void setSlideNotes(int index, String notes) {
    if (index < 0 || index >= _slides.length) return;
    _pushUndo();
    _slides[index].notes = notes;
    _isDirty = true;
    notifyListeners();
  }

  String getSlideNotes(int index) {
    if (index < 0 || index >= _slides.length) return '';
    return _slides[index].notes;
  }

  // ---------------------------------------------------------------------------
  // Element Animations
  // ---------------------------------------------------------------------------

  void addAnimation(int slideIndex, ElementAnimation anim) {
    if (slideIndex < 0 || slideIndex >= _slides.length) return;
    _pushUndo();
    _slides[slideIndex].animations.add(anim);
    _isDirty = true;
    notifyListeners();
  }

  void removeAnimation(int slideIndex, String elementId) {
    if (slideIndex < 0 || slideIndex >= _slides.length) return;
    _pushUndo();
    _slides[slideIndex].animations.removeWhere((a) => a.elementId == elementId);
    _isDirty = true;
    notifyListeners();
  }

  List<ElementAnimation> getAnimations(int slideIndex) {
    if (slideIndex < 0 || slideIndex >= _slides.length) return [];
    return _slides[slideIndex].animations;
  }

  // ---------------------------------------------------------------------------
  // Template Slides
  // ---------------------------------------------------------------------------

  /// Apply a template to the first slide (for template gallery launch).
  void applyTemplate(String templateType) {
    if (templateType == 'blank') return;
    // Remove default blank slide and add template slide
    if (_slides.isNotEmpty) {
      _slides.removeAt(0);
    }
    addSlideFromTemplate(templateType);
    _currentIndex = 0;
    notifyListeners();
  }

  void addSlideFromTemplate(String templateType, {
    String? titleSlideLabel,
    String? presentationTitleText,
    String? subtitleText,
    String? titleHint,
    String? titleBodyLabel,
    String? bodyHint,
    String? twoColumnLabel,
    String? comparisonTitle,
    String? leftContent,
    String? rightContent,
    String? sectionBreakLabel,
    String? sectionTitleText,
    String? defaultSlideLabel,
  }) {
    Slide slide;
    switch (templateType) {
      case 'title':
        slide = Slide(
          title: titleSlideLabel ?? 'Title Slide',
          elements: [
            SlideElement(
              type: SlideElementType.text,
              x: 80, y: 150, width: 800, height: 80,
              content: presentationTitleText ?? 'Presentation Title',
              fontSize: 44, fontWeight: FontWeight.bold,
              textAlign: TextAlign.center,
              color: const Color(0xFF333333),
            ),
            SlideElement(
              type: SlideElementType.text,
              x: 200, y: 260, width: 560, height: 48,
              content: subtitleText ?? 'Subtitle',
              fontSize: 22, color: AppColors.grey500,
              textAlign: TextAlign.center,
            ),
          ],
        );
      case 'titleBody':
        slide = Slide(
          title: titleBodyLabel ?? 'Title + Body',
          elements: [
            SlideElement(
              type: SlideElementType.text,
              x: 60, y: 30, width: 840, height: 60,
              content: titleHint ?? 'Enter title',
              fontSize: 32, fontWeight: FontWeight.bold,
              color: const Color(0xFF333333),
            ),
            SlideElement(
              type: SlideElementType.text,
              x: 60, y: 110, width: 840, height: 380,
              content: bodyHint ?? 'Enter body text',
              fontSize: 18, color: const Color(0xFF666666),
            ),
          ],
        );
      case 'twoColumn':
        slide = Slide(
          title: twoColumnLabel ?? 'Two Column',
          elements: [
            SlideElement(
              type: SlideElementType.text,
              x: 60, y: 30, width: 840, height: 60,
              content: comparisonTitle ?? 'Comparison Title',
              fontSize: 32, fontWeight: FontWeight.bold,
              textAlign: TextAlign.center,
              color: const Color(0xFF333333),
            ),
            SlideElement(
              type: SlideElementType.text,
              x: 40, y: 110, width: 420, height: 380,
              content: leftContent ?? 'Left Content',
              fontSize: 18, color: const Color(0xFF666666),
            ),
            SlideElement(
              type: SlideElementType.text,
              x: 500, y: 110, width: 420, height: 380,
              content: rightContent ?? 'Right Content',
              fontSize: 18, color: const Color(0xFF666666),
            ),
          ],
        );
      case 'section':
        slide = Slide(
          title: sectionBreakLabel ?? 'Section Break',
          backgroundColor: const Color(0xFF2C3E50),
          elements: [
            SlideElement(
              type: SlideElementType.text,
              x: 80, y: 200, width: 800, height: 80,
              content: sectionTitleText ?? 'Section Title',
              fontSize: 40, fontWeight: FontWeight.bold,
              textAlign: TextAlign.center,
              color: AppColors.white,
            ),
          ],
        );
      default:
        slide = Slide(title: defaultSlideLabel ?? 'Slide ${_slides.length + 1}');
    }
    _slides.add(slide);
    _currentIndex = _slides.length - 1;
    _isDirty = true;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Persistence
  // ---------------------------------------------------------------------------

  Future<String> saveToFile([String? path]) async {
    final savePath = path ?? _filePath ?? await _defaultPath();
    final json = {
      'title': _title,
      'slides': _slides.map((s) => s.toJson()).toList(),
      'modified': DateTime.now().toIso8601String(),
    };
    final file = File(savePath);
    await file.writeAsString(jsonEncode(json));
    _filePath = savePath;
    _isDirty = false;
    _lastSavedAt = DateTime.now();
    notifyListeners();
    return savePath;
  }

  Future<void> loadFromFile(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw Exception('File not found: $path');
    }
    final content = await file.readAsString();
    final json = jsonDecode(content) as Map<String, dynamic>;
    _title = json['title'] as String? ?? 'Untitled Presentation';
    _slides = (json['slides'] as List<dynamic>)
        .map((s) => Slide.fromJson(s as Map<String, dynamic>))
        .toList();
    _filePath = path;
    _currentIndex = 0;
    _isDirty = false;
    _selectedElementId = null;
    notifyListeners();
  }

  Future<String> _defaultPath() async {
    final dir = await getApplicationDocumentsDirectory();
    final sanitized = _title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    return '${dir.path}/$sanitized.expres';
  }

  // ---------------------------------------------------------------------------
  // PPTX 읽기/쓰기
  // ---------------------------------------------------------------------------

  Future<void> loadPptx(String path) async {
    final file = File(path);
    if (!await file.exists()) throw Exception('PPTX file not found: $path');
    final bytes = await file.readAsBytes();
    final parser = PptxParser();
    final slideMaps = parser.parse(Uint8List.fromList(bytes));
    if (slideMaps == null || slideMaps.isEmpty) {
      throw Exception('Failed to parse PPTX');
    }

    _slides = slideMaps.map((m) => Slide.fromJson(m)).toList();
    _title = path.split(RegExp(r'[/\\]')).last.replaceAll('.pptx', '');
    _filePath = path;
    _currentIndex = 0;
    _isDirty = false;
    _selectedElementId = null;
    notifyListeners();
  }

  Future<String> savePptx([String? path]) async {
    final savePath = path ?? await _pptxPath();
    final slideMaps = _slides.map((s) => s.toJson()).toList();
    final writer = PptxWriter();
    final Uint8List bytes = writer.write(slideMaps);

    final file = File(savePath);
    await file.writeAsBytes(bytes);
    return savePath;
  }

  Future<String> _pptxPath() async {
    final dir = await getApplicationDocumentsDirectory();
    final sanitized = _title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    return '${dir.path}/$sanitized.pptx';
  }

  // ---------------------------------------------------------------------------
  // Find & Replace
  // ---------------------------------------------------------------------------

  String _searchQuery = '';
  List<(int slideIndex, String elementId)> _searchResults = [];
  int _searchIndex = -1;

  String get searchQuery => _searchQuery;
  int get searchResultCount => _searchResults.length;
  int get searchIndex => _searchIndex;
  bool get hasSearchResults => _searchResults.isNotEmpty;

  void findAll(String query) {
    _searchQuery = query;
    _searchResults = [];
    _searchIndex = -1;
    if (query.isEmpty) {
      notifyListeners();
      return;
    }
    final q = query.toLowerCase();
    for (int s = 0; s < _slides.length; s++) {
      for (final el in _slides[s].elements) {
        if (el.type == SlideElementType.text &&
            el.content.toLowerCase().contains(q)) {
          _searchResults.add((s, el.id));
        }
      }
    }
    if (_searchResults.isNotEmpty) {
      _searchIndex = 0;
      final (si, eid) = _searchResults[0];
      _currentIndex = si;
      _selectedElementId = eid;
    }
    notifyListeners();
  }

  void findNext() {
    if (_searchResults.isEmpty) return;
    _searchIndex = (_searchIndex + 1) % _searchResults.length;
    final (si, eid) = _searchResults[_searchIndex];
    _currentIndex = si;
    _selectedElementId = eid;
    notifyListeners();
  }

  void findPrev() {
    if (_searchResults.isEmpty) return;
    _searchIndex =
        (_searchIndex - 1 + _searchResults.length) % _searchResults.length;
    final (si, eid) = _searchResults[_searchIndex];
    _currentIndex = si;
    _selectedElementId = eid;
    notifyListeners();
  }

  void replaceOne(String replacement) {
    if (_searchResults.isEmpty || _searchIndex < 0) return;
    final (si, eid) = _searchResults[_searchIndex];
    final slide = _slides[si];
    final elIdx = slide.elements.indexWhere((e) => e.id == eid);
    if (elIdx < 0) return;
    final el = slide.elements[elIdx];
    final newContent = el.content.replaceFirst(
      RegExp(RegExp.escape(_searchQuery), caseSensitive: false),
      replacement,
    );
    updateElement(si, eid, (e) => e.copyWith(content: newContent));
    findAll(_searchQuery);
  }

  void replaceAllMatches(String replacement) {
    if (_searchResults.isEmpty) return;
    final processed = <String>{};
    for (final (si, eid) in _searchResults) {
      final key = '$si:$eid';
      if (processed.contains(key)) continue;
      processed.add(key);
      final slide = _slides[si];
      final elIdx = slide.elements.indexWhere((e) => e.id == eid);
      if (elIdx < 0) continue;
      final el = slide.elements[elIdx];
      final newContent = el.content.replaceAll(
        RegExp(RegExp.escape(_searchQuery), caseSensitive: false),
        replacement,
      );
      updateElement(si, eid, (e) => e.copyWith(content: newContent));
    }
    findAll(_searchQuery);
  }

  void clearSearch() {
    _searchQuery = '';
    _searchResults = [];
    _searchIndex = -1;
    notifyListeners();
  }
}
