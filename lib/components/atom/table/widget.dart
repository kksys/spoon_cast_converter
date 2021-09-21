// Dart imports:
import 'dart:async';
import 'dart:collection';
import 'dart:math';

// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

// Package imports:
import 'package:macos_ui/macos_ui.dart';

// Project imports:
import 'package:spoon_cast_converter/components/atom/table/rendering.dart';

export 'package:flutter/rendering.dart'
    show
        FixedColumnWidth,
        FlexColumnWidth,
        FractionColumnWidth,
        IntrinsicColumnWidth,
        MaxColumnWidth,
        MinColumnWidth,
        TableBorder,
        TableCellVerticalAlignment,
        TableColumnWidth;

enum ScrollBarOrientation {
  vertical,
  horizontal,
}

class ScrollBar extends StatefulWidget {
  final GlobalKey<_ScrollBarState> globalKey;
  final void Function(double, {bool updateGrid}) onUpdate;
  final double handleSize;
  final ScrollBarOrientation orientation;
  final double? top;
  final double? left;
  final double? bottom;
  final double? right;
  final double width;
  final double height;

  static GlobalKey<_ScrollBarState> makeGlobalKey() {
    return GlobalKey<_ScrollBarState>();
  }

  ScrollBar({
    required this.globalKey,
    required this.onUpdate,
    required this.handleSize,
    required this.orientation,
    required this.top,
    required this.left,
    required this.bottom,
    required this.right,
    required this.width,
    required this.height,
  }) : super(key: globalKey);

  @override
  _ScrollBarState createState() => _ScrollBarState();
}

class _ScrollBarState extends State<ScrollBar> {
  double position = -1;
  double downPos = 0;
  Timer? scrollTimer;
  Color handleColor = Colors.white;
  bool entered = false;
  bool tap2 = false;
  double scrollFactor = 1;
  double _lastBuildSize = 0;

  late double handleSize;

  @override
  void initState() {
    super.initState();
    handleSize = widget.handleSize;
  }

  void updateScroll(double delta, {bool updateGrid = true}) {
    position += delta;
    _fixPos();
    update();
    widget.onUpdate(position * scrollFactor, updateGrid: updateGrid);
  }

  void update() {
    if (!mounted) return;
    setState(() {});
  }

  void _fixPos() {
    if (position < 0)
      position = 0;
    else if (position > 1) position = 1;
  }

  @override
  Widget build(BuildContext context) {
    final isVertical = widget.orientation == ScrollBarOrientation.vertical;

    return Positioned(
      top: widget.top,
      bottom: widget.bottom,
      left: widget.left,
      right: widget.right,
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: LayoutBuilder(
          builder: (context, box) {
            double handleHeight = 0;
            double handleWidth = 0;
            double defaultHandleHeight = 0;
            double defaultHandleWidth = 0;
            scrollFactor = 1;
            final offset = 20;
            late double buildSize;

            if (isVertical) {
              buildSize = box.maxHeight;
              defaultHandleHeight = widget.handleSize * buildSize;
              handleWidth = box.maxWidth;

              handleHeight = max(30, defaultHandleHeight);
              scrollFactor = (buildSize == handleHeight)
                  ? 1
                  : (buildSize - defaultHandleHeight) / (buildSize - handleHeight);
              handleSize *= handleHeight / defaultHandleHeight;
            } else {
              buildSize = box.maxWidth;
              defaultHandleWidth = widget.handleSize * buildSize;
              handleHeight = box.maxHeight;

              handleWidth = max(30, defaultHandleWidth);
              scrollFactor = (buildSize == handleWidth)
                  ? 1
                  : (buildSize - defaultHandleWidth) / (buildSize - handleWidth);
              handleSize *= handleWidth / defaultHandleWidth;
            }

            if (_lastBuildSize != 0 && buildSize > _lastBuildSize) {
              position *= buildSize / _lastBuildSize;
            }

            _lastBuildSize = buildSize;

            _fixPos();

            double _getPosition(dynamic details) {
              if (isVertical) return details.localPosition.dy;
              return details.localPosition.dx;
            }

            double _getBoxSize(BoxConstraints box) {
              if (isVertical) return box.maxHeight;
              return box.maxWidth;
            }

            if (tap2 || entered) {
              handleColor = Colors.grey;
            } else {
              handleColor = Colors.white;
            }

            return Listener(
              onPointerDown: (details) {
                if (tap2) return;

                if (scrollTimer == null) {
                  final downPos = (_getPosition(details) - offset) / _getBoxSize(box);
                  final delta = (downPos - position) / 10;

                  scrollTimer = Timer.periodic(Duration(milliseconds: 16), (timer) {
                    position += delta;
                    if ((position - downPos).abs() < delta.abs()) {
                      position = downPos;
                      timer.cancel();
                      scrollTimer = null;
                    }
                    _fixPos();
                    update();
                    widget.onUpdate(position * scrollFactor, updateGrid: true);
                  });
                }
              },
              onPointerUp: (details) {
                if (tap2) return;
                if (scrollTimer != null) {
                  scrollTimer!.cancel();
                  scrollTimer = null;
                }
              },
              child: Container(
                color: Colors.transparent,
                child: Stack(
                  children: [
                    Positioned(
                        top: isVertical ? (position) * (_getBoxSize(box) - handleHeight) : null,
                        left: isVertical
                            ? 0.5 * (box.maxWidth - handleWidth)
                            : (position) * (_getBoxSize(box) - handleWidth),
                        bottom: isVertical ? null : 0.5 * (box.maxHeight - handleHeight),
                        // top: null,
                        // left: null,
                        // bottom: null,
                        child: SizedBox(
                          width: handleWidth,
                          height: handleHeight,
                          child: Listener(
                            onPointerDown: (details) {
                              tap2 = true;
                              downPos = _getPosition(details);
                              update();
                            },
                            onPointerUp: (details) {
                              // position += delta;
                              tap2 = false;
                              entered = false;
                              update();
                            },
                            onPointerMove: (details) {
                              final currentPos = _getPosition(details);
                              double delta = 0;
                              if (_getBoxSize(box) != (isVertical ? handleHeight : handleWidth)) {
                                delta = (currentPos - downPos) /
                                    (_getBoxSize(box) - (isVertical ? handleHeight : handleWidth));
                              }
                              position += delta;
                              _fixPos();
                              downPos = currentPos;
                              widget.onUpdate(position * scrollFactor);
                            },
                            child: MouseRegion(
                              onEnter: (details) {
                                entered = true;
                                update();
                              },
                              onExit: (details) {
                                if (tap2) return;
                                entered = false;
                                update();
                              },
                              child: Container(
                                // color: Colors.grey,
                                decoration: BoxDecoration(
                                  color: handleColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        )),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

@immutable
class MacosStylePainter {
  final Color selectedRowBackgroundColor;

  const MacosStylePainter({
    required this.selectedRowBackgroundColor,
  });
}

/// A horizontal group of cells in a [Table].
///
/// Every row in a table must have the same number of children.
///
/// The alignment of individual cells in a row can be controlled using a
/// [TableCell].
@immutable
class MacosStyleTableRow {
  /// Creates a row in a [Table].
  const MacosStyleTableRow({this.key, this.decoration, this.children});

  /// An identifier for the row.
  final LocalKey? key;

  /// A decoration to paint behind this row.
  ///
  /// Row decorations fill the horizontal and vertical extent of each row in
  /// the table, unlike decorations for individual cells, which might not fill
  /// either.
  final Decoration? decoration;

  /// The widgets that comprise the cells in this row.
  ///
  /// Children may be wrapped in [TableCell] widgets to provide per-cell
  /// configuration to the [Table], but children are not required to be wrapped
  /// in [TableCell] widgets.
  final List<Widget>? children;

  @override
  String toString() {
    final StringBuffer result = StringBuffer();
    result.write('MacosStyleTableRow(');
    if (key != null) result.write('$key, ');
    if (decoration != null) result.write('$decoration, ');
    if (children == null) {
      result.write('child list is null');
    } else if (children!.isEmpty) {
      result.write('no children');
    } else {
      result.write('$children');
    }
    result.write(')');
    return result.toString();
  }
}

class _MacosStyleTableElementRow {
  const _MacosStyleTableElementRow({this.key, required this.children});
  final LocalKey? key;
  final List<Element> children;
}

/// A widget that uses the table layout algorithm for its children.
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=_lbE0wsVZSw}
///
/// {@tool dartpad --template=stateless_widget_scaffold}
///
/// This sample shows a `Table` with borders, multiple types of column widths and different vertical cell alignments.
///
/// ```dart
/// Widget build(BuildContext context) {
///   return Table(
///     border: TableBorder.all(),
///     columnWidths: const <int, TableColumnWidth>{
///       0: IntrinsicColumnWidth(),
///       1: FlexColumnWidth(),
///       2: FixedColumnWidth(64),
///     },
///     defaultVerticalAlignment: TableCellVerticalAlignment.middle,
///     children: <TableRow>[
///       TableRow(
///         children: <Widget>[
///           Container(
///             height: 32,
///             color: Colors.green,
///           ),
///           TableCell(
///             verticalAlignment: TableCellVerticalAlignment.top,
///             child: Container(
///               height: 32,
///               width: 32,
///               color: Colors.red,
///             ),
///           ),
///           Container(
///             height: 64,
///             color: Colors.blue,
///           ),
///         ],
///       ),
///       TableRow(
///         decoration: const BoxDecoration(
///           color: Colors.grey,
///         ),
///         children: <Widget>[
///           Container(
///             height: 64,
///             width: 128,
///             color: Colors.purple,
///           ),
///           Container(
///             height: 32,
///             color: Colors.yellow,
///           ),
///           Center(
///             child: Container(
///               height: 32,
///               width: 32,
///               color: Colors.orange,
///             ),
///           ),
///         ],
///       ),
///     ],
///   );
/// }
/// ```
/// {@end-tool}
///
/// If you only have one row, the [Row] widget is more appropriate. If you only
/// have one column, the [SliverList] or [Column] widgets will be more
/// appropriate.
///
/// Rows size vertically based on their contents. To control the individual
/// column widths, use the [columnWidths] property to specify a
/// [TableColumnWidth] for each column. If [columnWidths] is null, or there is a
/// null entry for a given column in [columnWidths], the table uses the
/// [defaultColumnWidth] instead.
///
/// By default, [defaultColumnWidth] is a [FlexColumnWidth]. This
/// [TableColumnWidth] divides up the remaining space in the horizontal axis to
/// determine the column width. If wrapping a [Table] in a horizontal
/// [ScrollView], choose a different [TableColumnWidth], such as
/// [FixedColumnWidth].
///
/// For more details about the table layout algorithm, see [RenderTable].
/// To control the alignment of children, see [TableCell].
///
/// See also:
///
///  * The [catalog of layout widgets](https://flutter.dev/widgets/layout/).
class MacosStyleTable extends RenderObjectWidget {
  /// Creates a table.
  ///
  /// The [children], [defaultColumnWidth], and [defaultVerticalAlignment]
  /// arguments must not be null.
  MacosStyleTable({
    Key? key,
    this.selectedRows = const <int>[],
    this.headers = const <MacosStyleTableColumn>[],
    this.children = const <MacosStyleTableRow>[],
    this.onChangeColumnWidth,
    this.onChangedViewportSize,
    this.columnWidths,
    this.defaultColumnWidth = const FlexColumnWidth(1.0),
    this.textDirection,
    this.border,
    this.defaultVerticalAlignment = TableCellVerticalAlignment.top,
    this.textBaseline, // NO DEFAULT: we don't know what the text's baseline should be
  })  : assert(
            defaultVerticalAlignment != TableCellVerticalAlignment.baseline || textBaseline != null,
            'textBaseline is required if you specify the defaultVerticalAlignment with TableCellVerticalAlignment.baseline'),
        assert(() {
          if (children.any((MacosStyleTableRow row) => row.children == null)) {
            throw FlutterError(
              'One of the rows of the table had null children.\n'
              'The children property of TableRow must not be null.',
            );
          }
          return true;
        }()),
        assert(() {
          if (children.any((MacosStyleTableRow row1) =>
              row1.key != null &&
              children.any((MacosStyleTableRow row2) => row1 != row2 && row1.key == row2.key))) {
            throw FlutterError(
              'Two or more TableRow children of this Table had the same key.\n'
              'All the keyed TableRow children of a Table must have different Keys.',
            );
          }
          return true;
        }()),
        assert(() {
          if (children.isNotEmpty) {
            final int cellCount = children.first.children!.length;
            if (children.any((MacosStyleTableRow row) => row.children!.length != cellCount)) {
              throw FlutterError(
                'Table contains irregular row lengths.\n'
                'Every TableRow in a Table must have the same number of children, so that every cell is filled. '
                'Otherwise, the table will contain holes.',
              );
            }
          }
          return true;
        }()),
        _rowDecorations = children.any((MacosStyleTableRow row) => row.decoration != null)
            ? children
                .map<Decoration?>((MacosStyleTableRow row) => row.decoration)
                .toList(growable: false)
            : null,
        super(key: key) {
    assert(() {
      final List<Widget> flatChildren = children
          .expand<Widget>((MacosStyleTableRow row) => row.children!)
          .toList(growable: false);
      if (debugChildrenHaveDuplicateKeys(this, flatChildren)) {
        throw FlutterError(
          'Two or more cells in this Table contain widgets with the same key.\n'
          'Every widget child of every TableRow in a Table must have different keys. The cells of a Table are '
          'flattened out for processing, so separate cells cannot have duplicate keys even if they are in '
          'different rows.',
        );
      }
      return true;
    }());
  }

  final List<int> selectedRows;

  /// The headers of the table.
  ///
  /// Every row in a table must have the same number of children, and all the
  /// children must be non-null.
  final List<MacosStyleTableColumn> headers;

  /// The rows of the table.
  ///
  /// Every row in a table must have the same number of children, and all the
  /// children must be non-null.
  final List<MacosStyleTableRow> children;

  /// How the horizontal extents of the columns of this table should be determined.
  ///
  /// If the [Map] has a null entry for a given column, the table uses the
  /// [defaultColumnWidth] instead. By default, that uses flex sizing to
  /// distribute free space equally among the columns.
  ///
  /// The [FixedColumnWidth] class can be used to specify a specific width in
  /// pixels. That is the cheapest way to size a table's columns.
  ///
  /// The layout performance of the table depends critically on which column
  /// sizing algorithms are used here. In particular, [IntrinsicColumnWidth] is
  /// quite expensive because it needs to measure each cell in the column to
  /// determine the intrinsic size of the column.
  ///
  /// The keys of this map (column indexes) are zero-based.
  ///
  /// If this is set to null, then an empty map is assumed.
  final Map<int, TableColumnWidth>? columnWidths;

  final Function(List<double>)? onChangeColumnWidth;
  final Function(Size)? onChangedViewportSize;

  /// How to determine with widths of columns that don't have an explicit sizing
  /// algorithm.
  ///
  /// Specifically, the [defaultColumnWidth] is used for column `i` if
  /// `columnWidths[i]` is null. Defaults to [FlexColumnWidth], which will
  /// divide the remaining horizontal space up evenly between columns of the
  /// same type [TableColumnWidth].
  ///
  /// A [Table] in a horizontal [ScrollView] must use a [FixedColumnWidth], or
  /// an [IntrinsicColumnWidth] as the horizontal space is infinite.
  final TableColumnWidth defaultColumnWidth;

  /// The direction in which the columns are ordered.
  ///
  /// Defaults to the ambient [Directionality].
  final TextDirection? textDirection;

  /// The style to use when painting the boundary and interior divisions of the table.
  final TableBorder? border;

  /// How cells that do not explicitly specify a vertical alignment are aligned vertically.
  ///
  /// Cells may specify a vertical alignment by wrapping their contents in a
  /// [TableCell] widget.
  final TableCellVerticalAlignment defaultVerticalAlignment;

  /// The text baseline to use when aligning rows using [TableCellVerticalAlignment.baseline].
  ///
  /// This must be set if using baseline alignment. There is no default because there is no
  /// way for the framework to know the correct baseline _a priori_.
  final TextBaseline? textBaseline;

  final List<Decoration?>? _rowDecorations;

  @override
  _MacosStyleTableElement createElement() => _MacosStyleTableElement(this);

  @override
  MacosStyleRenderTable createRenderObject(BuildContext context) {
    assert(debugCheckHasDirectionality(context));
    return MacosStyleRenderTable(
      columns: headers.length,
      rows: children.length,
      selectedRows: selectedRows,
      columnWidths: columnWidths,
      defaultColumnWidth: defaultColumnWidth,
      textDirection: textDirection ?? Directionality.of(context),
      border: border,
      rowDecorations: _rowDecorations,
      configuration: createLocalImageConfiguration(context),
      defaultVerticalAlignment: defaultVerticalAlignment,
      textBaseline: textBaseline,
      changedColumnWidthCallback: onChangeColumnWidth,
      changedViewportSizeCallback: onChangedViewportSize,
      painter: _generatePainter(context),
    );
  }

  @override
  void updateRenderObject(BuildContext context, MacosStyleRenderTable renderObject) {
    assert(debugCheckHasDirectionality(context));
    assert(renderObject.columns == headers.length);
    assert(renderObject.rows == children.length);
    renderObject
      ..setChangedColumnWidthCallback(this.onChangeColumnWidth)
      ..setChangedViewportSizeCallback(this.onChangedViewportSize)
      ..selectedRows = selectedRows
      ..columnWidths = columnWidths
      ..defaultColumnWidth = defaultColumnWidth
      ..textDirection = textDirection ?? Directionality.of(context)
      ..border = border
      ..rowDecorations = _rowDecorations
      ..configuration = createLocalImageConfiguration(context)
      ..defaultVerticalAlignment = defaultVerticalAlignment
      ..textBaseline = textBaseline
      ..painter = _generatePainter(context);
  }

  MacosStylePainter _generatePainter(BuildContext context) {
    final brightness = MacosTheme.brightnessOf(context);

    Color selectedRowBackgroundColor = Color.fromRGBO(0x1f, 0x59, 0xc8, 1.0);

    if (brightness != Brightness.dark) {
      selectedRowBackgroundColor = Color.fromRGBO(0x25, 0x64, 0xd9, 1.0);
    }

    return MacosStylePainter(
      selectedRowBackgroundColor: selectedRowBackgroundColor,
    );
  }
}

class _MacosStyleTableElement extends RenderObjectElement {
  _MacosStyleTableElement(MacosStyleTable widget) : super(widget);

  @override
  MacosStyleTable get widget => super.widget as MacosStyleTable;

  @override
  MacosStyleRenderTable get renderObject => super.renderObject as MacosStyleRenderTable;

  List<Element> _headers = const <Element>[];

  List<_MacosStyleTableElementRow> _children = const <_MacosStyleTableElementRow>[];

  bool _doingMountOrUpdate = false;

  @override
  void mount(Element? parent, Object? newSlot) {
    assert(!_doingMountOrUpdate);
    _doingMountOrUpdate = true;
    super.mount(parent, newSlot);
    int rowIndex = -1;
    _headers = widget.headers.map<Element>((e) {
      int columnIndex = 0;
      return inflateWidget(e, _MacosStyleTableSlot(columnIndex++, 0));
    }).toList();
    _children = widget.children.map<_MacosStyleTableElementRow>((MacosStyleTableRow row) {
      int columnIndex = 0;
      rowIndex += 1;
      return _MacosStyleTableElementRow(
        key: row.key,
        children: row.children!.map<Element>((Widget child) {
          return inflateWidget(child, _MacosStyleTableSlot(columnIndex++, rowIndex));
        }).toList(growable: false),
      );
    }).toList(growable: false);
    _updateRenderObjectChildren();
    assert(_doingMountOrUpdate);
    _doingMountOrUpdate = false;
  }

  @override
  void insertRenderObjectChild(RenderBox child, _MacosStyleTableSlot slot) {
    renderObject.setupParentData(child);
    // Once [mount]/[update] are done, the children are getting set all at once
    // in [_updateRenderObjectChildren].
    if (!_doingMountOrUpdate) {
      renderObject.setChild(slot.column, slot.row, child);
    }
  }

  @override
  void moveRenderObjectChild(
      RenderBox child, _MacosStyleTableSlot oldSlot, _MacosStyleTableSlot newSlot) {
    assert(_doingMountOrUpdate);
    // Child gets moved at the end of [update] in [_updateRenderObjectChildren].
  }

  @override
  void removeRenderObjectChild(RenderBox child, _MacosStyleTableSlot slot) {
    final TableCellParentData childParentData = child.parentData! as TableCellParentData;
    renderObject.setChild(childParentData.x!, childParentData.y!, null);
  }

  final Set<Element> _forgottenChildren = HashSet<Element>();

  @override
  void update(MacosStyleTable newWidget) {
    assert(!_doingMountOrUpdate);
    _doingMountOrUpdate = true;

    final List<Element> newHeaders = <Element>[];
    for (int headerIndex = 0; headerIndex < newWidget.headers.length; headerIndex++) {
      final MacosStyleTableColumn column = newWidget.headers[headerIndex];
      final _MacosStyleTableSlot slot = _MacosStyleTableSlot(headerIndex, 0);

      final newHeader = updateChild(
        _headers[headerIndex],
        column,
        slot,
      );
      if (newHeader != null) newHeaders.add(newHeader);
    }
    _headers = newHeaders;

    final Map<LocalKey, List<Element>> oldKeyedRows = <LocalKey, List<Element>>{};
    for (final _MacosStyleTableElementRow row in _children) {
      if (row.key != null) {
        oldKeyedRows[row.key!] = row.children;
      }
    }
    final Iterator<_MacosStyleTableElementRow> oldUnkeyedRows =
        _children.where((_MacosStyleTableElementRow row) => row.key == null).iterator;
    final List<_MacosStyleTableElementRow> newChildren = <_MacosStyleTableElementRow>[];
    final Set<List<Element>> taken = <List<Element>>{};
    for (int rowIndex = 0; rowIndex < newWidget.children.length; rowIndex++) {
      final MacosStyleTableRow row = newWidget.children[rowIndex];
      List<Element> oldChildren;
      if (row.key != null && oldKeyedRows.containsKey(row.key)) {
        oldChildren = oldKeyedRows[row.key]!;
        taken.add(oldChildren);
      } else if (row.key == null && oldUnkeyedRows.moveNext()) {
        oldChildren = oldUnkeyedRows.current.children;
      } else {
        oldChildren = const <Element>[];
      }
      final List<_MacosStyleTableSlot> slots = List<_MacosStyleTableSlot>.generate(
        row.children!.length,
        (int columnIndex) => _MacosStyleTableSlot(columnIndex, rowIndex),
      );
      newChildren.add(_MacosStyleTableElementRow(
        key: row.key,
        children: updateChildren(oldChildren, row.children!,
            forgottenChildren: _forgottenChildren, slots: slots),
      ));
    }
    while (oldUnkeyedRows.moveNext())
      updateChildren(oldUnkeyedRows.current.children, const <Widget>[],
          forgottenChildren: _forgottenChildren);
    for (final List<Element> oldChildren
        in oldKeyedRows.values.where((List<Element> list) => !taken.contains(list)))
      updateChildren(oldChildren, const <Widget>[], forgottenChildren: _forgottenChildren);

    _children = newChildren;
    _updateRenderObjectChildren();
    _forgottenChildren.clear();
    super.update(newWidget);
    assert(widget == newWidget);
    assert(_doingMountOrUpdate);
    _doingMountOrUpdate = false;
  }

  void _updateRenderObjectChildren() {
    renderObject.setHeaders(
      _headers.map<RenderBox>((Element e) {
        return e.renderObject! as RenderBox;
      }).toList(),
    );
    renderObject.setFlatChildren(
      _children.isNotEmpty ? _children[0].children.length : 0,
      _children.expand<RenderBox>((_MacosStyleTableElementRow row) {
        return row.children.map<RenderBox>((Element child) {
          final RenderBox box = child.renderObject! as RenderBox;
          return box;
        });
      }).toList(),
    );
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    _headers.forEach((element) {
      visitor(element);
    });
    for (final Element child
        in _children.expand<Element>((_MacosStyleTableElementRow row) => row.children)) {
      if (!_forgottenChildren.contains(child)) visitor(child);
    }
  }

  @override
  bool forgetChild(Element child) {
    _forgottenChildren.add(child);
    super.forgetChild(child);
    return true;
  }
}

/// A widget that controls how a child of a [Table] is aligned.
///
/// A [TableCell] widget must be a descendant of a [Table], and the path from
/// the [TableCell] widget to its enclosing [Table] must contain only
/// [TableRow]s, [StatelessWidget]s, or [StatefulWidget]s (not
/// other kinds of widgets, like [RenderObjectWidget]s).
class MacosStyleTableCell extends ParentDataWidget<TableCellParentData> {
  /// Creates a widget that controls how a child of a [Table] is aligned.
  const MacosStyleTableCell({
    Key? key,
    this.verticalAlignment,
    required Widget child,
  }) : super(key: key, child: child);

  /// How this cell is aligned vertically.
  final TableCellVerticalAlignment? verticalAlignment;

  @override
  void applyParentData(RenderObject renderObject) {
    final TableCellParentData parentData = renderObject.parentData! as TableCellParentData;
    if (parentData.verticalAlignment != verticalAlignment) {
      parentData.verticalAlignment = verticalAlignment;
      final AbstractNode? targetParent = renderObject.parent;
      if (targetParent is RenderObject) targetParent.markNeedsLayout();
    }
  }

  @override
  Type get debugTypicalAncestorWidgetClass => Table;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
        .add(EnumProperty<TableCellVerticalAlignment>('verticalAlignment', verticalAlignment));
  }
}

class MacosStyleTableColumn extends ParentDataWidget<TableCellParentData> {
  /// Creates a widget that controls how a child of a [Table] is aligned.
  const MacosStyleTableColumn({
    Key? key,
    this.verticalAlignment,
    required Widget child,
  }) : super(key: key, child: child);

  /// How this cell is aligned vertically.
  final TableCellVerticalAlignment? verticalAlignment;

  @override
  void applyParentData(RenderObject renderObject) {
    final TableCellParentData parentData = renderObject.parentData! as TableCellParentData;
    if (parentData.verticalAlignment != verticalAlignment) {
      parentData.verticalAlignment = verticalAlignment;
      final AbstractNode? targetParent = renderObject.parent;
      if (targetParent is RenderObject) targetParent.markNeedsLayout();
    }
  }

  @override
  Type get debugTypicalAncestorWidgetClass => Table;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
        .add(EnumProperty<TableCellVerticalAlignment>('verticalAlignment', verticalAlignment));
  }
}

@immutable
class _MacosStyleTableSlot with Diagnosticable {
  const _MacosStyleTableSlot(this.column, this.row);

  final int column;
  final int row;

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    return other is _MacosStyleTableSlot && column == other.column && row == other.row;
  }

  @override
  int get hashCode => hashValues(column, row);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('x', column));
    properties.add(IntProperty('y', row));
  }
}
