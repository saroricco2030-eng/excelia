import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:excelia/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:excelia/providers/spreadsheet_provider.dart';
import 'package:excelia/utils/constants.dart';
import 'cell_editor.dart';

/// 행/열 헤더가 고정된 전문 스프레드시트 그리드
class SpreadsheetGrid extends StatefulWidget {
  const SpreadsheetGrid({super.key});

  @override
  State<SpreadsheetGrid> createState() => _SpreadsheetGridState();
}

class _SpreadsheetGridState extends State<SpreadsheetGrid> {
  final ScrollController _hScroll = ScrollController();
  final ScrollController _vScroll = ScrollController();
  final ScrollController _colHeaderScroll = ScrollController();
  final ScrollController _rowHeaderScroll = ScrollController();

  static const double _rowHeaderWidth = 46.0;
  static const double _colHeaderHeight = 28.0;

  // 열 크기 조정
  int? _resizingCol;
  double _resizeStartX = 0;
  double _resizeStartWidth = 0;

  // 행 크기 조정
  int? _resizingRow;
  double _resizeStartY = 0;
  double _resizeStartHeight = 0;

  // 자동 채우기 드래그
  bool _isAutoFilling = false;
  int _autoFillTargetRow = 0;
  int _autoFillTargetCol = 0;
  Offset _fillDragDelta = Offset.zero;

  // 줌
  double _zoomLevel = 1.0;
  static const double _minZoom = 0.4;
  static const double _maxZoom = 3.0;

  // 틀 고정용 트랜스폼 컨트롤러
  final TransformationController _transformCtrl = TransformationController();
  double _scrollX = 0;
  double _scrollY = 0;

  // 키보드 포커스 — build() 안에서 FocusNode() 생성 금지 (매 프레임 누수)
  late final FocusNode _keyboardFocusNode;

  @override
  void initState() {
    super.initState();
    _keyboardFocusNode = FocusNode();
    _hScroll.addListener(_syncHorizontalScroll);
    _vScroll.addListener(_syncVerticalScroll);
    _transformCtrl.addListener(_onTransformChanged);
  }

  void _syncHorizontalScroll() {
    if (_colHeaderScroll.hasClients) {
      _colHeaderScroll.jumpTo(_hScroll.offset);
    }
  }

  void _syncVerticalScroll() {
    if (_rowHeaderScroll.hasClients) {
      _rowHeaderScroll.jumpTo(_vScroll.offset);
    }
  }

  void _onTransformChanged() {
    final m = _transformCtrl.value;
    setState(() {
      _scrollX = -m.getTranslation().x;
      _scrollY = -m.getTranslation().y;
      _zoomLevel = m.getMaxScaleOnAxis();
    });
  }

  @override
  void dispose() {
    _hScroll.removeListener(_syncHorizontalScroll);
    _vScroll.removeListener(_syncVerticalScroll);
    _transformCtrl.removeListener(_onTransformChanged);
    _keyboardFocusNode.dispose();
    _hScroll.dispose();
    _vScroll.dispose();
    _colHeaderScroll.dispose();
    _rowHeaderScroll.dispose();
    _transformCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Consumer<SpreadsheetProvider>(
      builder: (context, prov, _) {
        final totalWidth = prov.totalWidth;
        final totalHeight = prov.totalHeight;

        return KeyboardListener(
          focusNode: _keyboardFocusNode..requestFocus(),
          onKeyEvent: (e) => _handleKey(e, prov),
          child: Column(
            children: [
              // ── 줌 표시 + 리셋 ──
              if ((_zoomLevel - 1.0).abs() > 0.05)
                Container(
                  height: 28,
                  color: AppColors.grey100,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Text(l.spreadsheetZoomPercent((_zoomLevel * 100).round()),
                          style: const TextStyle(fontSize: 11, color: AppColors.grey600)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => setState(() => _zoomLevel = 1.0),
                        child: Text(l.commonReset, style: const TextStyle(fontSize: 11, color: AppColors.primary)),
                      ),
                    ],
                  ),
                ),
              // ── 열 헤더 행 ──
              SizedBox(
                height: _colHeaderHeight,
                child: Row(
                  children: [
                    // 좌상단 코너 (전체 선택)
                    GestureDetector(
                      onTap: () => prov.selectRange(
                          0, 0, prov.totalRows - 1, prov.totalCols - 1),
                      child: Container(
                        width: _rowHeaderWidth,
                        height: _colHeaderHeight,
                        decoration: BoxDecoration(
                          color: AppColors.grey200,
                          border: Border(
                            right: BorderSide(color: AppColors.grey300),
                            bottom: BorderSide(color: AppColors.grey300),
                          ),
                        ),
                      ),
                    ),
                    // 열 헤더 (A, B, C ...)
                    Expanded(
                      child: ListView.builder(
                        controller: _colHeaderScroll,
                        scrollDirection: Axis.horizontal,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: prov.totalCols,
                        itemBuilder: (_, col) =>
                            _buildColumnHeader(col, prov),
                      ),
                    ),
                  ],
                ),
              ),
              // ── 본문 영역 ──
              Expanded(
                child: Row(
                  children: [
                    // 행 헤더 (1, 2, 3 ...)
                    SizedBox(
                      width: _rowHeaderWidth,
                      child: ListView.builder(
                        controller: _rowHeaderScroll,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: prov.totalRows,
                        itemBuilder: (_, row) =>
                            _buildRowHeader(row, prov),
                      ),
                    ),
                    // 셀 영역 — InteractiveViewer + 틀 고정 오버레이
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final vpWidth = constraints.maxWidth;
                          final vpHeight = constraints.maxHeight;
                          return Stack(
                        children: [
                          InteractiveViewer(
                            transformationController: _transformCtrl,
                            constrained: false,
                            minScale: _minZoom,
                            maxScale: _maxZoom,
                            onInteractionUpdate: (details) {
                              if (_colHeaderScroll.hasClients) {
                                _colHeaderScroll.jumpTo(
                                  _scrollX.clamp(0, totalWidth).toDouble(),
                                );
                              }
                              if (_rowHeaderScroll.hasClients) {
                                _rowHeaderScroll.jumpTo(
                                  _scrollY.clamp(0, totalHeight).toDouble(),
                                );
                              }
                            },
                            child: SizedBox(
                              width: totalWidth,
                              height: totalHeight,
                              child: CustomPaint(
                                painter: GridPainter(
                                  provider: prov,
                                  totalWidth: totalWidth,
                                  totalHeight: totalHeight,
                                  viewportWidth: vpWidth,
                                  viewportHeight: vpHeight,
                                  scrollX: _scrollX,
                                  scrollY: _scrollY,
                                  zoom: _zoomLevel,
                                ),
                                child: Stack(
                                  children: [
                                    _buildCellTapLayer(prov, totalWidth, totalHeight),
                                    if (prov.isEditing)
                                      _buildInlineEditor(prov),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // 틀 고정 오버레이
                          if (prov.hasFrozenPanes)
                            ..._buildFrozenOverlays(prov),
                          // 자동 채우기 핸들 + 미리보기
                          if (!prov.isEditing)
                            ..._buildAutoFillHandle(prov),
                        ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ────────────────── 열 헤더 ──────────────────

  Widget _buildColumnHeader(int col, SpreadsheetProvider prov) {
    final w = prov.getColumnWidth(col);
    final isSelected = prov.isCellInSelection(prov.selectedRow, col);
    return GestureDetector(
      onTap: () => prov.selectRange(0, col, prov.totalRows - 1, col),
      child: Stack(
        children: [
          Container(
            width: w,
            height: _colHeaderHeight,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.spreadsheetGreen.withValues(alpha: 0.15)
                  : AppColors.grey200,
              border: Border(
                right: BorderSide(color: AppColors.grey300),
                bottom: BorderSide(color: AppColors.grey300),
              ),
            ),
            child: Text(
              prov.getColumnName(col),
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.spreadsheetGreen : AppColors.grey800,
              ),
            ),
          ),
          // 크기 조정 핸들
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: GestureDetector(
              onHorizontalDragStart: (d) {
                _resizingCol = col;
                _resizeStartX = d.globalPosition.dx;
                _resizeStartWidth = w;
              },
              onHorizontalDragUpdate: (d) {
                if (_resizingCol == col) {
                  final delta = d.globalPosition.dx - _resizeStartX;
                  prov.setColumnWidth(col, _resizeStartWidth + delta);
                }
              },
              onHorizontalDragEnd: (_) => _resizingCol = null,
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeColumn,
                child: const SizedBox(width: 6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────── 행 헤더 ──────────────────

  Widget _buildRowHeader(int row, SpreadsheetProvider prov) {
    final h = prov.getRowHeight(row);
    final isSelected = prov.isCellInSelection(row, prov.selectedCol);
    return GestureDetector(
      onTap: () => prov.selectRange(row, 0, row, prov.totalCols - 1),
      child: Stack(
        children: [
          Container(
            width: _rowHeaderWidth,
            height: h,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.spreadsheetGreen.withValues(alpha: 0.15)
                  : AppColors.grey200,
              border: Border(
                right: BorderSide(color: AppColors.grey300),
                bottom: BorderSide(color: AppColors.grey300),
              ),
            ),
            child: Text(
              '${row + 1}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.spreadsheetGreen : AppColors.grey800,
              ),
            ),
          ),
          // 크기 조정 핸들
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onVerticalDragStart: (d) {
                _resizingRow = row;
                _resizeStartY = d.globalPosition.dy;
                _resizeStartHeight = h;
              },
              onVerticalDragUpdate: (d) {
                if (_resizingRow == row) {
                  final delta = d.globalPosition.dy - _resizeStartY;
                  prov.setRowHeight(row, _resizeStartHeight + delta);
                }
              },
              onVerticalDragEnd: (_) => _resizingRow = null,
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeRow,
                child: const SizedBox(height: 5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────── 셀 터치 레이어 ──────────────────

  Widget _buildCellTapLayer(
      SpreadsheetProvider prov, double totalW, double totalH) {
    return SizedBox(
      width: totalW,
      height: totalH,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapUp: (d) {
          final pos = d.localPosition;
          final col = prov.getColumnAtX(pos.dx);
          final row = prov.getRowAtY(pos.dy);
          if (prov.isFormatPainterActive) {
            prov.applyFormatPainter(row, col);
            return;
          }
          prov.selectCell(row, col);
        },
        onDoubleTapDown: (d) {
          final pos = d.localPosition;
          final col = prov.getColumnAtX(pos.dx);
          final row = prov.getRowAtY(pos.dy);
          prov.selectCell(row, col);
          prov.startEditing();
        },
        onLongPressStart: (d) {
          final pos = d.localPosition;
          final col = prov.getColumnAtX(pos.dx);
          final row = prov.getRowAtY(pos.dy);
          if (prov.isFormatPainterActive) {
            prov.applyFormatPainter(row, col);
            return;
          }
          prov.selectCell(row, col);
          _showContextMenu(d.globalPosition, prov);
        },
      ),
    );
  }

  void _showContextMenu(Offset globalPos, SpreadsheetProvider prov) {
    final l = AppLocalizations.of(context)!;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        globalPos.dx, globalPos.dy,
        overlay.size.width - globalPos.dx,
        overlay.size.height - globalPos.dy,
      ),
      items: [
        PopupMenuItem(value: 'cut', child: Row(children: [
          const Icon(LucideIcons.scissors, size: 18),
          const SizedBox(width: 8),
          Text(l.contextCut),
        ])),
        PopupMenuItem(value: 'copy', child: Row(children: [
          const Icon(LucideIcons.copy, size: 18),
          const SizedBox(width: 8),
          Text(l.contextCopy),
        ])),
        PopupMenuItem(value: 'paste', child: Row(children: [
          const Icon(LucideIcons.clipboardPaste, size: 18),
          const SizedBox(width: 8),
          Text(l.contextPaste),
        ])),
        const PopupMenuDivider(),
        PopupMenuItem(value: 'insRow', child: Row(children: [
          const Icon(LucideIcons.arrowDownFromLine, size: 18),
          const SizedBox(width: 8),
          Text(l.spreadsheetInsertRow),
        ])),
        PopupMenuItem(value: 'insCol', child: Row(children: [
          const Icon(LucideIcons.arrowRightFromLine, size: 18),
          const SizedBox(width: 8),
          Text(l.spreadsheetInsertCol),
        ])),
        PopupMenuItem(value: 'delRow', child: Row(children: [
          const Icon(LucideIcons.trash2, size: 18),
          const SizedBox(width: 8),
          Text(l.spreadsheetDeleteRow),
        ])),
        PopupMenuItem(value: 'delCol', child: Row(children: [
          const Icon(LucideIcons.trash2, size: 18),
          const SizedBox(width: 8),
          Text(l.spreadsheetDeleteCol),
        ])),
        const PopupMenuDivider(),
        PopupMenuItem(value: 'clear', child: Row(children: [
          const Icon(LucideIcons.eraser, size: 18),
          const SizedBox(width: 8),
          Text(l.contextClearContent),
        ])),
        const PopupMenuDivider(),
        PopupMenuItem(value: 'hideRow', child: Row(children: [
          const Icon(LucideIcons.eyeOff, size: 18),
          const SizedBox(width: 8),
          Text(l.hideRow),
        ])),
        PopupMenuItem(value: 'hideCol', child: Row(children: [
          const Icon(LucideIcons.eyeOff, size: 18),
          const SizedBox(width: 8),
          Text(l.hideCol),
        ])),
        if (prov.hiddenRows.isNotEmpty || prov.hiddenCols.isNotEmpty)
          PopupMenuItem(value: 'unhideAll', child: Row(children: [
            const Icon(LucideIcons.eye, size: 18),
            const SizedBox(width: 8),
            Text(l.unhideAll),
          ])),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: prov.hasComment(prov.selectedRow, prov.selectedCol)
              ? 'editComment'
              : 'addComment',
          child: Row(children: [
            const Icon(LucideIcons.messageSquare, size: 18),
            const SizedBox(width: 8),
            Text(prov.hasComment(prov.selectedRow, prov.selectedCol)
                ? l.editComment
                : l.addComment),
          ]),
        ),
        if (prov.hasComment(prov.selectedRow, prov.selectedCol))
          PopupMenuItem(value: 'deleteComment', child: Row(children: [
            Icon(LucideIcons.trash2, size: 18, color: AppColors.error),
            const SizedBox(width: 8),
            Text(l.deleteComment),
          ])),
      ],
    ).then((value) {
      if (value == null) return;
      switch (value) {
        case 'cut':
          prov.cut();
        case 'copy':
          prov.copy();
        case 'paste':
          prov.paste();
        case 'insRow':
          prov.insertRow(prov.selectedRow);
        case 'insCol':
          prov.insertColumn(prov.selectedCol);
        case 'delRow':
          prov.deleteRow(prov.selectedRow);
        case 'delCol':
          prov.deleteColumn(prov.selectedCol);
        case 'clear':
          prov.clearSelectionContent();
        case 'hideRow':
          prov.hideSelectedRows();
        case 'hideCol':
          prov.hideSelectedCols();
        case 'unhideAll':
          prov.unhideAllRows();
          prov.unhideAllCols();
        case 'addComment':
        case 'editComment':
          _showCommentDialog(prov);
        case 'deleteComment':
          prov.removeComment(prov.selectedRow, prov.selectedCol);
      }
    });
  }

  // ────────────────── 셀 메모 다이얼로그 ──────────────────

  void _showCommentDialog(SpreadsheetProvider prov) {
    final existing = prov.getComment(prov.selectedRow, prov.selectedCol);
    final controller = TextEditingController(text: existing?.text ?? '');
    showDialog(
      context: context,
      builder: (ctx) {
        final l = AppLocalizations.of(ctx)!;
        return AlertDialog(
          title: Text(existing != null ? l.editComment : l.addComment),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: l.commentHint,
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l.commonCancel),
            ),
            FilledButton(
              onPressed: () {
                prov.setComment(
                  prov.selectedRow,
                  prov.selectedCol,
                  controller.text.trim(),
                );
                Navigator.pop(ctx);
              },
              child: Text(l.commonSave),
            ),
          ],
        );
      },
    );
  }

  // ────────────────── 인라인 편집기 ──────────────────

  Widget _buildInlineEditor(SpreadsheetProvider prov) {
    final x = prov.getColumnX(prov.selectedCol);
    final y = prov.getRowY(prov.selectedRow);
    final w = prov.getColumnWidth(prov.selectedCol);
    final h = prov.getRowHeight(prov.selectedRow);

    return Positioned(
      left: x,
      top: y,
      child: CellEditor(
        width: w,
        height: h,
        initialValue: prov.editValue,
        // Enter commits and moves down one row (Excel/Sheets parity).
        onSubmit: (v) {
          prov.updateEditValue(v);
          prov.confirmEdit();
          prov.moveSelection(1, 0);
        },
        onCancel: prov.cancelEdit,
        onChanged: prov.updateEditValue,
        // Tab commits and moves horizontally (forward=next col, shift=prev).
        onTab: (forward) {
          prov.confirmEdit();
          prov.moveSelection(0, forward ? 1 : -1);
        },
      ),
    );
  }

  // ────────────────── 틀 고정 오버레이 ──────────────────

  List<Widget> _buildFrozenOverlays(SpreadsheetProvider prov) {
    final fRows = prov.frozenRows;
    final fCols = prov.frozenCols;
    final fW = prov.frozenWidth * _zoomLevel;
    final fH = prov.frozenHeight * _zoomLevel;
    final gridScrollX = _scrollX / _zoomLevel;
    final gridScrollY = _scrollY / _zoomLevel;

    return [
      // ── 고정 행 (상단 스트립, 가로 스크롤만 동기화) ──
      if (fRows > 0)
        Positioned(
          left: 0, top: 0, right: 0,
          height: fH,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) {
              final gx = d.localPosition.dx / _zoomLevel + gridScrollX;
              final gy = d.localPosition.dy / _zoomLevel;
              if (prov.isFormatPainterActive) {
                prov.applyFormatPainter(
                    prov.getRowAtY(gy), prov.getColumnAtX(gx));
                return;
              }
              prov.selectCell(prov.getRowAtY(gy), prov.getColumnAtX(gx));
            },
            onDoubleTapDown: (d) {
              final gx = d.localPosition.dx / _zoomLevel + gridScrollX;
              final gy = d.localPosition.dy / _zoomLevel;
              prov.selectCell(prov.getRowAtY(gy), prov.getColumnAtX(gx));
              prov.startEditing();
            },
            child: ClipRect(
              child: CustomPaint(
                painter: _FrozenCellsPainter(
                  provider: prov,
                  rowRange: (0, fRows - 1),
                  colRange: (0, prov.totalCols - 1),
                  scrollOffsetX: gridScrollX,
                  scrollOffsetY: 0,
                  zoom: _zoomLevel,
                ),
              ),
            ),
          ),
        ),

      // ── 고정 열 (좌측 스트립, 세로 스크롤만 동기화) ──
      if (fCols > 0)
        Positioned(
          left: 0, top: 0, bottom: 0,
          width: fW,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) {
              final gx = d.localPosition.dx / _zoomLevel;
              final gy = d.localPosition.dy / _zoomLevel + gridScrollY;
              if (prov.isFormatPainterActive) {
                prov.applyFormatPainter(
                    prov.getRowAtY(gy), prov.getColumnAtX(gx));
                return;
              }
              prov.selectCell(prov.getRowAtY(gy), prov.getColumnAtX(gx));
            },
            onDoubleTapDown: (d) {
              final gx = d.localPosition.dx / _zoomLevel;
              final gy = d.localPosition.dy / _zoomLevel + gridScrollY;
              prov.selectCell(prov.getRowAtY(gy), prov.getColumnAtX(gx));
              prov.startEditing();
            },
            child: ClipRect(
              child: CustomPaint(
                painter: _FrozenCellsPainter(
                  provider: prov,
                  rowRange: (0, prov.totalRows - 1),
                  colRange: (0, fCols - 1),
                  scrollOffsetX: 0,
                  scrollOffsetY: gridScrollY,
                  zoom: _zoomLevel,
                ),
              ),
            ),
          ),
        ),

      // ── 고정 코너 (좌상단, 완전 고정) ──
      if (fRows > 0 && fCols > 0)
        Positioned(
          left: 0, top: 0,
          width: fW, height: fH,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) {
              final gx = d.localPosition.dx / _zoomLevel;
              final gy = d.localPosition.dy / _zoomLevel;
              if (prov.isFormatPainterActive) {
                prov.applyFormatPainter(
                    prov.getRowAtY(gy), prov.getColumnAtX(gx));
                return;
              }
              prov.selectCell(prov.getRowAtY(gy), prov.getColumnAtX(gx));
            },
            onDoubleTapDown: (d) {
              final gx = d.localPosition.dx / _zoomLevel;
              final gy = d.localPosition.dy / _zoomLevel;
              prov.selectCell(prov.getRowAtY(gy), prov.getColumnAtX(gx));
              prov.startEditing();
            },
            child: CustomPaint(
              painter: _FrozenCellsPainter(
                provider: prov,
                rowRange: (0, fRows - 1),
                colRange: (0, fCols - 1),
                scrollOffsetX: 0,
                scrollOffsetY: 0,
                zoom: _zoomLevel,
              ),
            ),
          ),
        ),

      // ── 고정 경계선 (그림자 효과) ──
      if (fRows > 0)
        Positioned(
          left: 0, right: 0, top: fH,
          child: IgnorePointer(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.grey800.withValues(alpha: 0.15),
                    AppColors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
      if (fCols > 0)
        Positioned(
          top: 0, bottom: 0, left: fW,
          child: IgnorePointer(
            child: Container(
              width: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    AppColors.grey800.withValues(alpha: 0.15),
                    AppColors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
    ];
  }

  // ────────────────── 자동 채우기 핸들 ──────────────────

  List<Widget> _buildAutoFillHandle(SpreadsheetProvider prov) {
    final selR0 = prov.hasRange
        ? min(prov.selStartRow, prov.selEndRow)
        : prov.selectedRow;
    final selR1 = prov.hasRange
        ? max(prov.selStartRow, prov.selEndRow)
        : prov.selectedRow;
    final selC0 = prov.hasRange
        ? min(prov.selStartCol, prov.selEndCol)
        : prov.selectedCol;
    final selC1 = prov.hasRange
        ? max(prov.selStartCol, prov.selEndCol)
        : prov.selectedCol;

    // 그리드 좌표 기준 핸들 위치 (선택 영역 우하단)
    final gridHandleX =
        prov.getColumnX(selC1) + prov.getColumnWidth(selC1);
    final gridHandleY =
        prov.getRowY(selR1) + prov.getRowHeight(selR1);

    // 화면 좌표 변환
    final screenX = gridHandleX * _zoomLevel - _scrollX - 4;
    final screenY = gridHandleY * _zoomLevel - _scrollY - 4;

    final widgets = <Widget>[];

    // ── 채우기 미리보기 (드래그 중) ──
    if (_isAutoFilling &&
        (_autoFillTargetRow > selR1 || _autoFillTargetCol > selC1)) {
      double pLeft, pTop, pWidth, pHeight;

      if (_autoFillTargetRow > selR1) {
        // 아래로 채우기
        pLeft = prov.getColumnX(selC0) * _zoomLevel - _scrollX;
        pTop = gridHandleY * _zoomLevel - _scrollY;
        double w = 0;
        for (int c = selC0; c <= selC1; c++) {
          w += prov.getColumnWidth(c);
        }
        pWidth = w * _zoomLevel;
        double h = 0;
        for (int r = selR1 + 1;
            r <= _autoFillTargetRow && r < prov.totalRows;
            r++) {
          h += prov.getRowHeight(r);
        }
        pHeight = h * _zoomLevel;
      } else {
        // 오른쪽으로 채우기
        pLeft = gridHandleX * _zoomLevel - _scrollX;
        pTop = prov.getRowY(selR0) * _zoomLevel - _scrollY;
        double w = 0;
        for (int c = selC1 + 1;
            c <= _autoFillTargetCol && c < prov.totalCols;
            c++) {
          w += prov.getColumnWidth(c);
        }
        pWidth = w * _zoomLevel;
        double h = 0;
        for (int r = selR0; r <= selR1; r++) {
          h += prov.getRowHeight(r);
        }
        pHeight = h * _zoomLevel;
      }

      if (pWidth > 0 && pHeight > 0) {
        widgets.add(
          Positioned(
            left: pLeft,
            top: pTop,
            child: IgnorePointer(
              child: Container(
                width: pWidth,
                height: pHeight,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.spreadsheetGreen,
                    width: 1.5,
                  ),
                  color: AppColors.spreadsheetGreen
                      .withValues(alpha: 0.06),
                ),
              ),
            ),
          ),
        );
      }
    }

    // ── 핸들 위젯 (8×8 파란 사각형) ──
    widgets.add(
      Positioned(
        left: screenX,
        top: screenY,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (_) {
            setState(() {
              _isAutoFilling = true;
              _fillDragDelta = Offset.zero;
              _autoFillTargetRow = selR1;
              _autoFillTargetCol = selC1;
            });
          },
          onPanUpdate: (d) {
            setState(() {
              _fillDragDelta += d.delta;
              final gdx = _fillDragDelta.dx / _zoomLevel;
              final gdy = _fillDragDelta.dy / _zoomLevel;

              // 지배적 방향으로 제한
              if (gdy.abs() >= gdx.abs()) {
                _autoFillTargetRow =
                    prov.getRowAtY(gridHandleY + gdy);
                _autoFillTargetCol = selC1;
              } else {
                _autoFillTargetRow = selR1;
                _autoFillTargetCol =
                    prov.getColumnAtX(gridHandleX + gdx);
              }
              // 최소 선택 범위 유지
              if (_autoFillTargetRow < selR1) {
                _autoFillTargetRow = selR1;
              }
              if (_autoFillTargetCol < selC1) {
                _autoFillTargetCol = selC1;
              }
            });
          },
          onPanEnd: (_) {
            if (_isAutoFilling &&
                (_autoFillTargetRow > selR1 ||
                    _autoFillTargetCol > selC1)) {
              prov.autoFill(_autoFillTargetRow, _autoFillTargetCol);
            }
            setState(() {
              _isAutoFilling = false;
              _fillDragDelta = Offset.zero;
            });
          },
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.spreadsheetGreen,
              border: Border.all(color: AppColors.white, width: 1),
            ),
          ),
        ),
      ),
    );

    return widgets;
  }

  // ────────────────── 키보드 처리 ──────────────────

  void _handleKey(KeyEvent event, SpreadsheetProvider prov) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return;
    final key = event.logicalKey;

    if (prov.isEditing) {
      if (key == LogicalKeyboardKey.escape) {
        prov.cancelEdit();
      }
      // Enter, Tab은 CellEditor에서 처리
      return;
    }

    // 방향키 이동
    if (key == LogicalKeyboardKey.arrowUp) {
      prov.moveSelection(-1, 0);
    } else if (key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.enter) {
      prov.moveSelection(1, 0);
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      prov.moveSelection(0, -1);
    } else if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.tab) {
      prov.moveSelection(0, 1);
    } else if (key == LogicalKeyboardKey.f2) {
      prov.startEditing();
    } else if (key == LogicalKeyboardKey.delete ||
        key == LogicalKeyboardKey.backspace) {
      prov.setCellValue(prov.selectedRow, prov.selectedCol, null);
    } else if (HardwareKeyboard.instance.isControlPressed) {
      if (key == LogicalKeyboardKey.keyC) prov.copy();
      if (key == LogicalKeyboardKey.keyX) prov.cut();
      if (key == LogicalKeyboardKey.keyV) prov.paste();
      if (key == LogicalKeyboardKey.keyZ) prov.undo();
      if (key == LogicalKeyboardKey.keyY) prov.redo();
    } else {
      // 일반 문자 입력시 편집 모드 진입
      final char = event.character;
      if (char != null && char.isNotEmpty && char.codeUnitAt(0) >= 32) {
        prov.startEditing(char);
      }
    }
  }

}

// ═══════════════════════════════════════════════════════════════
// CustomPainter: 그리드 라인 + 셀 내용 + 선택 영역 렌더링
// ═══════════════════════════════════════════════════════════════

class GridPainter extends CustomPainter {
  final SpreadsheetProvider provider;
  final double totalWidth;
  final double totalHeight;
  final int _stateVersion;

  // Viewport clipping parameters
  final double viewportWidth;
  final double viewportHeight;
  final double scrollX;
  final double scrollY;
  final double zoom;

  GridPainter({
    required this.provider,
    required this.totalWidth,
    required this.totalHeight,
    this.viewportWidth = 0,
    this.viewportHeight = 0,
    this.scrollX = 0,
    this.scrollY = 0,
    this.zoom = 1.0,
  }) : _stateVersion = provider.stateVersion;

  // ── Reuse Paint objects — avoid GC pressure (60fps x Paint() = 3600 allocs/min) ──
  static final _gridPaint = Paint()
    ..strokeWidth = 0.5
    ..style = PaintingStyle.stroke;

  static final _selectionFillPaint = Paint()
    ..style = PaintingStyle.fill;

  static final _activeBorderPaint = Paint()
    ..strokeWidth = 2.0
    ..style = PaintingStyle.stroke;

  static final _selectionBorderPaint = Paint()
    ..strokeWidth = 1.0
    ..style = PaintingStyle.stroke;

  static final _whitePaint = Paint()
    ..style = PaintingStyle.fill;

  static final _borderPaint = Paint()
    ..strokeWidth = 1.5
    ..style = PaintingStyle.stroke;

  static final _searchHighlightPaint = Paint()
    ..style = PaintingStyle.fill;

  static final _searchFocusPaint = Paint()
    ..strokeWidth = 2.0
    ..style = PaintingStyle.stroke;

  static final _arrowPaint = Paint()
    ..style = PaintingStyle.fill;

  static final _filterHighlightPaint = Paint()
    ..style = PaintingStyle.fill;

  static final _bgFillPaint = Paint()
    ..style = PaintingStyle.fill;

  static final _hyperlinkPaint = Paint()
    ..style = PaintingStyle.fill;

  static final _commentPaint = Paint()
    ..style = PaintingStyle.fill;

  static final _dataBarBorderPaint = Paint()
    ..strokeWidth = 1.5
    ..style = PaintingStyle.stroke;

  // ── TextPainter cache — avoids layout() on every frame ──
  static final Map<int, TextPainter> _tpCache = {};
  static const int _maxCacheSize = 2000;

  static TextPainter _getCachedPainter(String text, TextStyle style, double maxWidth, {int? maxLines, String? ellipsis}) {
    final key = Object.hash(text, style, maxWidth, maxLines);
    var tp = _tpCache[key];
    if (tp != null) return tp;

    // Evict oldest if cache full
    if (_tpCache.length >= _maxCacheSize) {
      _tpCache.remove(_tpCache.keys.first);
    }

    tp = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: maxLines ?? 1,
      ellipsis: ellipsis ?? '\u2026',
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    _tpCache[key] = tp;
    return tp;
  }

  /// Binary search on prefix sum offsets: returns the index of the first
  /// offset >= [value]. Used to find visible row/column range.
  static int _binarySearchOffset(List<double> offsets, double value) {
    int lo = 0, hi = offsets.length - 1;
    while (lo < hi) {
      final mid = (lo + hi) ~/ 2;
      if (offsets[mid] < value) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return lo;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Set colors on static paints (only color changes per theme, not object allocation)
    _gridPaint.color = AppColors.gridLine;
    _selectionFillPaint.color = AppColors.spreadsheetGreen.withValues(alpha: 0.08);
    _activeBorderPaint.color = AppColors.spreadsheetGreen;
    _selectionBorderPaint.color = AppColors.spreadsheetGreen.withValues(alpha: 0.5);
    _whitePaint.color = AppColors.white;
    _searchHighlightPaint.color = AppColors.searchHighlight;
    _searchFocusPaint.color = AppColors.warning;
    _arrowPaint.color = AppColors.spreadsheetGreen;
    _commentPaint.color = AppColors.error;
    _hyperlinkPaint.color = AppColors.hyperlinkBlue;

    // ── Calculate visible row/column range via prefix sums ──
    final colOffsets = provider.colOffsets;
    final rowOffsets = provider.rowOffsets;
    final bool hasViewport = viewportWidth > 0 && viewportHeight > 0
        && colOffsets.length > 1 && rowOffsets.length > 1;

    int firstCol, lastCol, firstRow, lastRow;
    if (hasViewport) {
      final effectiveZoom = zoom > 0 ? zoom : 1.0;
      final visibleLeft = scrollX / effectiveZoom;
      final visibleRight = visibleLeft + viewportWidth / effectiveZoom;
      final visibleTop = scrollY / effectiveZoom;
      final visibleBottom = visibleTop + viewportHeight / effectiveZoom;

      firstCol = (_binarySearchOffset(colOffsets, visibleLeft) - 1)
          .clamp(0, provider.totalCols - 1);
      lastCol = (_binarySearchOffset(colOffsets, visibleRight) + 1)
          .clamp(0, provider.totalCols - 1);
      firstRow = (_binarySearchOffset(rowOffsets, visibleTop) - 1)
          .clamp(0, provider.totalRows - 1);
      lastRow = (_binarySearchOffset(rowOffsets, visibleBottom) + 1)
          .clamp(0, provider.totalRows - 1);
    } else {
      // Fallback: draw everything (e.g. during initial layout)
      firstCol = 0;
      lastCol = provider.totalCols - 1;
      firstRow = 0;
      lastRow = provider.totalRows - 1;
    }

    // Precompute visible edge positions for grid lines
    final visLeftX = provider.getColumnX(firstCol);
    final visRightX = provider.getColumnX(lastCol + 1);
    final visTopY = provider.getRowY(firstRow);
    final visBotY = provider.getRowY(lastRow + 1);

    // ── 그리드 라인 (visible range only) ──
    for (int r = firstRow; r <= lastRow + 1 && r <= provider.totalRows; r++) {
      final y = provider.getRowY(r);
      canvas.drawLine(Offset(visLeftX, y), Offset(visRightX, y), _gridPaint);
    }
    for (int c = firstCol; c <= lastCol + 1 && c <= provider.totalCols; c++) {
      final x = provider.getColumnX(c);
      canvas.drawLine(Offset(x, visTopY), Offset(x, visBotY), _gridPaint);
    }

    // ── 선택 영역 배경 ──
    if (provider.hasRange) {
      final minR = min(provider.selStartRow, provider.selEndRow);
      final maxR = max(provider.selStartRow, provider.selEndRow);
      final minC = min(provider.selStartCol, provider.selEndCol);
      final maxC = max(provider.selStartCol, provider.selEndCol);

      // Only draw if selection overlaps visible range
      if (maxR >= firstRow && minR <= lastRow && maxC >= firstCol && minC <= lastCol) {
        final rx = provider.getColumnX(minC);
        final ry = provider.getRowY(minR);
        final rw = provider.getColumnX(maxC + 1) - rx;
        final rh = provider.getRowY(maxR + 1) - ry;

        canvas.drawRect(Rect.fromLTWH(rx, ry, rw, rh), _selectionFillPaint);
        canvas.drawRect(Rect.fromLTWH(rx, ry, rw, rh), _selectionBorderPaint);
      }
    }

    // ── 병합 셀 배경 (흰색으로 그리드 라인 덮기) ──
    final mergedCells = provider.mergedCells;

    for (final m in mergedCells) {
      // Skip merged cells entirely outside visible range
      if (m.$3 < firstRow || m.$1 > lastRow || m.$4 < firstCol || m.$2 > lastCol) continue;

      final mx = provider.getColumnX(m.$2);
      final my = provider.getRowY(m.$1);
      final mEndCol = min(m.$4, provider.totalCols - 1);
      final mEndRow = min(m.$3, provider.totalRows - 1);
      final mw = provider.getColumnX(mEndCol + 1) - mx;
      final mh = provider.getRowY(mEndRow + 1) - my;
      // 병합 영역 내부 그리드 라인 지우기
      canvas.drawRect(Rect.fromLTWH(mx + 0.5, my + 0.5, mw - 1, mh - 1), _whitePaint);
      // 병합 영역 외곽선
      canvas.drawRect(Rect.fromLTWH(mx, my, mw, mh), _gridPaint);
    }

    // ── 셀 내용 렌더링 (only visible cells) ──
    final cellData = provider.currentCellData;
    final cellFormats = provider.currentCellFormats;

    for (final entry in cellData.entries) {
      final parsed = provider.parseCellReference(entry.key);
      if (parsed == null) continue;
      final row = parsed.$1;
      final col = parsed.$2;
      if (row >= provider.totalRows || col >= provider.totalCols) continue;

      // Viewport culling: skip cells outside visible range
      // (For merged cells, check if their merge area overlaps the visible range)
      final merge = provider.getMergeForCell(row, col);
      if (merge != null) {
        if (merge.$3 < firstRow || merge.$1 > lastRow ||
            merge.$4 < firstCol || merge.$2 > lastCol) {
          continue;
        }
      } else {
        if (row < firstRow || row > lastRow ||
            col < firstCol || col > lastCol) {
          continue;
        }
      }

      // 병합된 셀의 숨겨진 부분은 건너뜀
      if (provider.isMergeHidden(row, col)) continue;

      // 병합 셀이면 전체 병합 영역 크기 사용
      double cx, cy, cw, ch;
      if (merge != null && merge.$1 == row && merge.$2 == col) {
        cx = provider.getColumnX(col);
        cy = provider.getRowY(row);
        final mEndCol = min(merge.$4, provider.totalCols - 1);
        final mEndRow = min(merge.$3, provider.totalRows - 1);
        cw = provider.getColumnX(mEndCol + 1) - cx;
        ch = provider.getRowY(mEndRow + 1) - cy;
      } else {
        cx = provider.getColumnX(col);
        cy = provider.getRowY(row);
        cw = provider.getColumnWidth(col);
        ch = provider.getRowHeight(row);
      }

      // 배경색
      final fmt = cellFormats[entry.key];
      // 조건부 서식 (조건 매치 시 배경/텍스트 오버라이드)
      final condFmt = provider.getConditionalFormat(row, col);

      if (condFmt?.backgroundColor != null) {
        _bgFillPaint.color = condFmt!.backgroundColor!;
        canvas.drawRect(Rect.fromLTWH(cx, cy, cw, ch), _bgFillPaint);
      } else if (fmt?.backgroundColor != null) {
        _bgFillPaint.color = fmt!.backgroundColor!;
        canvas.drawRect(Rect.fromLTWH(cx, cy, cw, ch), _bgFillPaint);
      }

      // 데이터 바 렌더링 (조건부 서식 확장)
      final dataBarInfo = provider.getDataBarInfo(row, col);
      if (dataBarInfo != null) {
        final ratio = dataBarInfo.clamp(0.0, 1.0);
        final barWidth = (cw - 4) * ratio;
        final barRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(cx + 2, cy + 2, barWidth, ch - 4),
          const Radius.circular(2),
        );
        _bgFillPaint.shader = LinearGradient(
          colors: [
            AppColors.selectionBlue.withAlpha(90),
            AppColors.selectionBlue.withAlpha(38),
          ],
        ).createShader(Rect.fromLTWH(cx + 2, cy + 2, barWidth, ch - 4));
        canvas.drawRRect(barRect, _bgFillPaint);
        _bgFillPaint.shader = null; // reset shader for next use
        // 우측 경계 액센트
        if (barWidth > 3) {
          _dataBarBorderPaint.color = AppColors.selectionBlue.withAlpha(128);
          canvas.drawLine(
            Offset(cx + 2 + barWidth, cy + 2),
            Offset(cx + 2 + barWidth, cy + ch - 2),
            _dataBarBorderPaint,
          );
        }
      }

      // 하이퍼링크 표시기 (좌하단 파란 점)
      if (provider.getHyperlink(row, col) != null) {
        canvas.drawCircle(
          Offset(cx + 4, cy + ch - 4),
          2.5,
          _hyperlinkPaint,
        );
      }

      // 셀 메모 표시기 (우상단 빨간 삼각형)
      if (provider.hasComment(row, col)) {
        final triPath = Path()
          ..moveTo(cx + cw - 8, cy)
          ..lineTo(cx + cw, cy)
          ..lineTo(cx + cw, cy + 8)
          ..close();
        canvas.drawPath(triPath, _commentPaint);
      }

      // 텍스트
      final display = provider.getCellDisplay(row, col);
      if (display.isNotEmpty) {
        TextAlign align = TextAlign.left;
        Color textColor = condFmt?.textColor ?? AppColors.grey900;
        FontWeight fontWeight =
            (condFmt?.bold == true) ? FontWeight.w700 : FontWeight.w400;
        FontStyle fontStyle = FontStyle.normal;
        double fontSize = 13;

        // 하이퍼링크 스타일 오버라이드
        final hasHyperlink = provider.getHyperlink(row, col) != null;
        if (hasHyperlink) {
          textColor = AppColors.hyperlinkBlue;
        }

        if (fmt != null) {
          align = fmt.alignment;
          if (!hasHyperlink && condFmt?.textColor == null && fmt.textColor != null) {
            textColor = fmt.textColor!;
          }
          if (condFmt?.bold != true && fmt.bold) {
            fontWeight = FontWeight.w700;
          }
          if (fmt.italic) fontStyle = FontStyle.italic;
          if (fmt.fontSize != null && fmt.fontSize! > 0) {
            fontSize = fmt.fontSize!.toDouble();
          }
        }

        final style = TextStyle(
          fontSize: fontSize,
          color: textColor,
          fontWeight: fontWeight,
          fontStyle: fontStyle,
          fontFamily: fmt?.fontFamily,
          decoration:
              fmt?.underline == true ? TextDecoration.underline : null,
        );
        final isWrap = fmt?.wrapText == true;
        final tp = _getCachedPainter(
          display,
          style,
          cw - 8,
          maxLines: isWrap ? null : 1,
          ellipsis: isWrap ? null : '\u2026',
        );

        double dx;
        switch (align) {
          case TextAlign.center:
            dx = cx + (cw - tp.width) / 2;
          case TextAlign.right:
          case TextAlign.end:
            dx = cx + cw - tp.width - 4;
          default:
            dx = cx + 4;
        }
        final dy = cy + (ch - tp.height) / 2;

        // 클리핑 영역 설정 후 텍스트 렌더링
        canvas.save();
        canvas.clipRect(Rect.fromLTWH(cx, cy, cw, ch));
        tp.paint(canvas, Offset(dx, dy));
        canvas.restore();
      }
    }

    // ── 셀 테두리 렌더링 (only visible cells) ──
    _borderPaint.color = AppColors.black;

    for (final entry in cellFormats.entries) {
      final fmt = entry.value;
      if (fmt.borders == null || !fmt.borders!.hasAny) continue;
      final parsed = provider.parseCellReference(entry.key);
      if (parsed == null) continue;
      final bRow = parsed.$1;
      final bCol = parsed.$2;
      // Viewport culling
      if (bRow < firstRow || bRow > lastRow || bCol < firstCol || bCol > lastCol) continue;

      final bx = provider.getColumnX(bCol);
      final by = provider.getRowY(bRow);
      final bw = provider.getColumnWidth(bCol);
      final bh = provider.getRowHeight(bRow);
      final borders = fmt.borders!;
      _borderPaint.color = borders.color;
      if (borders.top) canvas.drawLine(Offset(bx, by), Offset(bx + bw, by), _borderPaint);
      if (borders.bottom) canvas.drawLine(Offset(bx, by + bh), Offset(bx + bw, by + bh), _borderPaint);
      if (borders.left) canvas.drawLine(Offset(bx, by), Offset(bx, by + bh), _borderPaint);
      if (borders.right) canvas.drawLine(Offset(bx + bw, by), Offset(bx + bw, by + bh), _borderPaint);
    }

    // ── 검색 매치 하이라이트 (only visible) ──
    if (provider.searchResults.isNotEmpty) {
      for (int i = 0; i < provider.searchResults.length; i++) {
        final pos = provider.searchResults[i];
        // Viewport culling
        if (pos.$1 < firstRow || pos.$1 > lastRow || pos.$2 < firstCol || pos.$2 > lastCol) continue;
        final sx = provider.getColumnX(pos.$2);
        final sy = provider.getRowY(pos.$1);
        final sw = provider.getColumnWidth(pos.$2);
        final sh = provider.getRowHeight(pos.$1);
        canvas.drawRect(Rect.fromLTWH(sx, sy, sw, sh), _searchHighlightPaint);
        if (i == provider.searchIndex) {
          canvas.drawRect(Rect.fromLTWH(sx, sy, sw, sh), _searchFocusPaint);
        }
      }
    }

    // ── 자동 필터 헤더 표시기 (드롭다운 화살표) ──
    final af = provider.autoFilter;
    if (af != null) {
      final hRow = af.headerRow;
      // Only draw if filter header row is visible
      if (hRow >= firstRow && hRow <= lastRow) {
        final hy = provider.getRowY(hRow);
        final hh = provider.getRowHeight(hRow);
        // Clamp filter column range to visible range
        final fColStart = max(af.startCol, firstCol);
        final fColEnd = min(af.endCol, lastCol);
        for (int c = fColStart; c <= fColEnd && c < provider.totalCols; c++) {
          final hx = provider.getColumnX(c);
          final hw = provider.getColumnWidth(c);
          // 우하단에 작은 삼각형 화살표
          final arrowPath = Path()
            ..moveTo(hx + hw - 14, hy + hh / 2 - 3)
            ..lineTo(hx + hw - 6, hy + hh / 2 - 3)
            ..lineTo(hx + hw - 10, hy + hh / 2 + 3)
            ..close();
          canvas.drawPath(arrowPath, _arrowPaint);
          // 필터가 활성화된 열은 색상 강조
          if (af.activeFilters.containsKey(c)) {
            _filterHighlightPaint.color = AppColors.spreadsheetGreen.withValues(alpha: 0.1);
            canvas.drawRect(
              Rect.fromLTWH(hx, hy, hw, hh),
              _filterHighlightPaint,
            );
          }
        }
      }
    }

    // ── 활성 셀 테두리 ──
    final ax = provider.getColumnX(provider.selectedCol);
    final ay = provider.getRowY(provider.selectedRow);
    final aw = provider.getColumnWidth(provider.selectedCol);
    final ah = provider.getRowHeight(provider.selectedRow);
    canvas.drawRect(Rect.fromLTWH(ax, ay, aw, ah), _activeBorderPaint);
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) =>
      _stateVersion != oldDelegate._stateVersion ||
      scrollX != oldDelegate.scrollX ||
      scrollY != oldDelegate.scrollY ||
      zoom != oldDelegate.zoom ||
      viewportWidth != oldDelegate.viewportWidth ||
      viewportHeight != oldDelegate.viewportHeight;
}

// ═══════════════════════════════════════════════════════════════
// CustomPainter: 틀 고정 영역 렌더링 (고정 행/열/코너)
// ═══════════════════════════════════════════════════════════════

class _FrozenCellsPainter extends CustomPainter {
  final SpreadsheetProvider provider;
  final (int, int) rowRange; // (시작행, 끝행) inclusive
  final (int, int) colRange; // (시작열, 끝열) inclusive
  final double scrollOffsetX; // 그리드 좌표 기준 가로 스크롤
  final double scrollOffsetY; // 그리드 좌표 기준 세로 스크롤
  final double zoom;
  final int _stateVersion;

  _FrozenCellsPainter({
    required this.provider,
    required this.rowRange,
    required this.colRange,
    required this.scrollOffsetX,
    required this.scrollOffsetY,
    required this.zoom,
  }) : _stateVersion = provider.stateVersion;

  // Reuse static Paint objects from GridPainter to avoid duplication
  static final _bgPaint = Paint()..style = PaintingStyle.fill;
  static final _gridPaint = Paint()
    ..strokeWidth = 0.5
    ..style = PaintingStyle.stroke;
  static final _borderPaint = Paint()
    ..strokeWidth = 1.5
    ..style = PaintingStyle.stroke;
  static final _activeBorderPaint = Paint()
    ..strokeWidth = 2.0
    ..style = PaintingStyle.stroke;
  static final _selFillPaint = Paint()..style = PaintingStyle.fill;
  static final _selBorderPaint = Paint()
    ..strokeWidth = 1.0
    ..style = PaintingStyle.stroke;

  @override
  void paint(Canvas canvas, Size size) {
    // 불투명 배경으로 아래 스크롤 콘텐츠 가리기
    _bgPaint.color = AppColors.white;
    canvas.drawRect(Offset.zero & size, _bgPaint);

    canvas.save();
    canvas.scale(zoom);
    canvas.translate(-scrollOffsetX, -scrollOffsetY);

    _gridPaint.color = AppColors.gridLine;

    final (r0, r1) = rowRange;
    final (c0, c1) = colRange;

    // ── 셀 배경·내용·그리드 라인 ──
    for (int r = r0; r <= r1 && r < provider.totalRows; r++) {
      for (int c = c0; c <= c1 && c < provider.totalCols; c++) {
        // 병합 셀의 숨겨진 부분 건너뜀
        if (provider.isMergeHidden(r, c)) continue;

        final cx = provider.getColumnX(c);
        final cy = provider.getRowY(r);
        final cw = provider.getColumnWidth(c);
        final ch = provider.getRowHeight(r);
        final cellRect = Rect.fromLTWH(cx, cy, cw, ch);

        // 그리드 라인
        canvas.drawRect(cellRect, _gridPaint);

        // 배경색
        final fmt = provider.getCellFormat(r, c);
        if (fmt.backgroundColor != null) {
          _bgPaint.color = fmt.backgroundColor!;
          canvas.drawRect(cellRect, _bgPaint);
        }

        // 텍스트
        final display = provider.getCellDisplay(r, c);
        if (display.isNotEmpty) {
          final align = fmt.alignment;
          final textColor = fmt.textColor ?? AppColors.grey900;
          final fontWeight = fmt.bold ? FontWeight.w700 : FontWeight.w400;
          final fontStyle =
              fmt.italic ? FontStyle.italic : FontStyle.normal;
          final fontSize = (fmt.fontSize != null && fmt.fontSize! > 0)
              ? fmt.fontSize!.toDouble()
              : 13.0;

          final style = TextStyle(
            fontSize: fontSize,
            color: textColor,
            fontWeight: fontWeight,
            fontStyle: fontStyle,
            fontFamily: fmt.fontFamily,
            decoration: fmt.underline ? TextDecoration.underline : null,
          );
          final isWrap = fmt.wrapText;
          final tp = GridPainter._getCachedPainter(
            display,
            style,
            cw - 8,
            maxLines: isWrap ? null : 1,
            ellipsis: isWrap ? null : '\u2026',
          );

          double dx;
          switch (align) {
            case TextAlign.center:
              dx = cx + (cw - tp.width) / 2;
            case TextAlign.right:
            case TextAlign.end:
              dx = cx + cw - tp.width - 4;
            default:
              dx = cx + 4;
          }
          final dy = cy + (ch - tp.height) / 2;

          canvas.save();
          canvas.clipRect(cellRect);
          tp.paint(canvas, Offset(dx, dy));
          canvas.restore();
        }

        // 셀 테두리
        if (fmt.borders != null && fmt.borders!.hasAny) {
          _borderPaint.color = fmt.borders!.color;
          if (fmt.borders!.top) {
            canvas.drawLine(
                Offset(cx, cy), Offset(cx + cw, cy), _borderPaint);
          }
          if (fmt.borders!.bottom) {
            canvas.drawLine(
                Offset(cx, cy + ch), Offset(cx + cw, cy + ch), _borderPaint);
          }
          if (fmt.borders!.left) {
            canvas.drawLine(
                Offset(cx, cy), Offset(cx, cy + ch), _borderPaint);
          }
          if (fmt.borders!.right) {
            canvas.drawLine(
                Offset(cx + cw, cy), Offset(cx + cw, cy + ch), _borderPaint);
          }
        }
      }
    }

    // ── 활성 셀 하이라이트 (고정 영역 내일 때) ──
    final selR = provider.selectedRow;
    final selC = provider.selectedCol;
    if (selR >= r0 && selR <= r1 && selC >= c0 && selC <= c1) {
      final ax = provider.getColumnX(selC);
      final ay = provider.getRowY(selR);
      final aw = provider.getColumnWidth(selC);
      final ah = provider.getRowHeight(selR);
      _activeBorderPaint.color = AppColors.spreadsheetGreen;
      canvas.drawRect(Rect.fromLTWH(ax, ay, aw, ah), _activeBorderPaint);
    }

    // ── 선택 영역 하이라이트 ──
    if (provider.hasRange) {
      final minR = min(provider.selStartRow, provider.selEndRow);
      final maxR = max(provider.selStartRow, provider.selEndRow);
      final minC = min(provider.selStartCol, provider.selEndCol);
      final maxC = max(provider.selStartCol, provider.selEndCol);

      // 선택 영역이 고정 범위와 겹치는지 확인
      final oR0 = max(minR, r0);
      final oR1 = min(maxR, r1);
      final oC0 = max(minC, c0);
      final oC1 = min(maxC, c1);

      if (oR0 <= oR1 && oC0 <= oC1) {
        final rx = provider.getColumnX(oC0);
        final ry = provider.getRowY(oR0);
        double rw = 0;
        for (int c = oC0; c <= oC1; c++) {
          rw += provider.getColumnWidth(c);
        }
        double rh = 0;
        for (int r = oR0; r <= oR1; r++) {
          rh += provider.getRowHeight(r);
        }
        _selFillPaint.color = AppColors.spreadsheetGreen.withValues(alpha: 0.08);
        canvas.drawRect(Rect.fromLTWH(rx, ry, rw, rh), _selFillPaint);
        _selBorderPaint.color = AppColors.spreadsheetGreen.withValues(alpha: 0.5);
        canvas.drawRect(Rect.fromLTWH(rx, ry, rw, rh), _selBorderPaint);
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FrozenCellsPainter old) =>
      _stateVersion != old._stateVersion ||
      scrollOffsetX != old.scrollOffsetX ||
      scrollOffsetY != old.scrollOffsetY ||
      zoom != old.zoom;
}
