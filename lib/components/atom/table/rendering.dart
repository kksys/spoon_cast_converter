// Dart imports:
import 'dart:collection';
import 'dart:math' as math;

// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

// Package imports:
import 'package:macos_ui/macos_ui.dart';

// Project imports:
import 'package:spoon_cast_converter/components/atom/table/widget.dart';

/// A table where the columns and rows are sized to fit the contents of the cells.
class MacosStyleRenderTable extends RenderBox {
  /// Creates a table render object.
  ///
  ///  * `columns` must either be null or non-negative. If `columns` is null,
  ///    the number of columns will be inferred from length of the first sublist
  ///    of `children`.
  ///  * `rows` must either be null or non-negative. If `rows` is null, the
  ///    number of rows will be inferred from the `children`. If `rows` is not
  ///    null, then `children` must be null.
  ///  * `children` must either be null or contain lists of all the same length.
  ///    if `children` is not null, then `rows` must be null.
  ///  * [columnWidths] may be null, in which case it defaults to an empty map.
  ///  * [defaultColumnWidth] must not be null.
  ///  * [configuration] must not be null (but has a default value).
  MacosStyleRenderTable({
    int? columns,
    int? rows,
    Map<int, TableColumnWidth>? columnWidths,
    TableColumnWidth defaultColumnWidth = const FlexColumnWidth(1.0),
    required TextDirection textDirection,
    TableBorder? border,
    List<Decoration?>? rowDecorations,
    ImageConfiguration configuration = ImageConfiguration.empty,
    TableCellVerticalAlignment defaultVerticalAlignment = TableCellVerticalAlignment.top,
    TextBaseline? textBaseline,
    List<List<RenderBox>>? children,
    List<RenderBox> headers = const [],
    Function(List<double>)? changedColumnWidthCallback,
    Function(Size)? changedViewportSizeCallback,
  })  : assert(columns == null || columns >= 0),
        assert(rows == null || rows >= 0),
        assert(rows == null || children == null),
        assert(headers.length != columns),
        _textDirection = textDirection,
        _columns = columns ?? (children != null && children.isNotEmpty ? children.first.length : 0),
        _rows = rows ?? 0,
        _columnWidths = columnWidths ?? HashMap<int, TableColumnWidth>(),
        _defaultColumnWidth = defaultColumnWidth,
        _border = border,
        _textBaseline = textBaseline,
        _defaultVerticalAlignment = defaultVerticalAlignment,
        _configuration = configuration {
    _headers = <RenderBox?>[]..length = _columns;
    _children = <RenderBox?>[]..length = _columns * _rows;
    this.rowDecorations = rowDecorations; // must use setter to initialize box painters array
    headers.forEach(addHeader);
    children?.forEach(addRow);
    _changedColumnWidthCallback = changedColumnWidthCallback;
    _changedViewportSizeCallback = changedViewportSizeCallback;
  }

  Function(List<double>)? _changedColumnWidthCallback;
  Function(Size)? _changedViewportSizeCallback;

  List<RenderBox?> _headers = const <RenderBox?>[];

  // Children are stored in row-major order.
  // _children.length must be rows * columns
  List<RenderBox?> _children = const <RenderBox?>[];

  /// The number of vertical alignment lines in this table.
  ///
  /// Changing the number of columns will remove any children that no longer fit
  /// in the table.
  ///
  /// Changing the number of columns is an expensive operation because the table
  /// needs to rearrange its internal representation.
  int get columns => _columns;
  int _columns;
  set columns(int value) {
    assert(value >= 0);
    if (value == columns) return;
    final int oldColumns = columns;
    final List<RenderBox?> oldChildren = _children;
    _columns = value;
    _children = List<RenderBox?>.filled(columns * rows, null, growable: false);
    final int columnsToCopy = math.min(columns, oldColumns);
    for (int y = 0; y < rows; y += 1) {
      for (int x = 0; x < columnsToCopy; x += 1)
        _children[x + y * columns] = oldChildren[x + y * oldColumns];
    }
    if (oldColumns > columns) {
      for (int y = 0; y < rows; y += 1) {
        for (int x = columns; x < oldColumns; x += 1) {
          final int xy = x + y * oldColumns;
          if (oldChildren[xy] != null) dropChild(oldChildren[xy]!);
        }
      }
    }
    markNeedsLayout();
  }

  /// The number of horizontal alignment lines in this table.
  ///
  /// Changing the number of rows will remove any children that no longer fit
  /// in the table.
  int get rows => _rows;
  int _rows;
  set rows(int value) {
    assert(value >= 0);
    if (value == rows) return;
    if (_rows > value) {
      for (int xy = columns * value; xy < _children.length; xy += 1) {
        if (_children[xy] != null) dropChild(_children[xy]!);
      }
    }
    _rows = value;
    _children.length = columns * rows;
    markNeedsLayout();
  }

  /// How the horizontal extents of the columns of this table should be determined.
  ///
  /// If the [Map] has a null entry for a given column, the table uses the
  /// [defaultColumnWidth] instead.
  ///
  /// The layout performance of the table depends critically on which column
  /// sizing algorithms are used here. In particular, [IntrinsicColumnWidth] is
  /// quite expensive because it needs to measure each cell in the column to
  /// determine the intrinsic size of the column.
  ///
  /// This property can never return null. If it is set to null, and the existing
  /// map is not empty, then the value is replaced by an empty map. (If it is set
  /// to null while the current value is an empty map, the value is not changed.)
  Map<int, TableColumnWidth>? get columnWidths =>
      Map<int, TableColumnWidth>.unmodifiable(_columnWidths);
  Map<int, TableColumnWidth> _columnWidths;
  set columnWidths(Map<int, TableColumnWidth>? value) {
    if (_columnWidths == value) return;
    if (_columnWidths.isEmpty && value == null) return;
    _columnWidths = value ?? HashMap<int, TableColumnWidth>();
    markNeedsLayout();
  }

  /// Determines how the width of column with the given index is determined.
  void setColumnWidth(int column, TableColumnWidth value) {
    if (_columnWidths[column] == value) return;
    _columnWidths[column] = value;
    markNeedsLayout();
  }

  /// How to determine with widths of columns that don't have an explicit sizing algorithm.
  ///
  /// Specifically, the [defaultColumnWidth] is used for column `i` if
  /// `columnWidths[i]` is null.
  TableColumnWidth get defaultColumnWidth => _defaultColumnWidth;
  TableColumnWidth _defaultColumnWidth;
  set defaultColumnWidth(TableColumnWidth value) {
    if (defaultColumnWidth == value) return;
    _defaultColumnWidth = value;
    markNeedsLayout();
  }

  /// The direction in which the columns are ordered.
  TextDirection get textDirection => _textDirection;
  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (_textDirection == value) return;
    _textDirection = value;
    markNeedsLayout();
  }

  /// The style to use when painting the boundary and interior divisions of the table.
  TableBorder? get border => _border;
  TableBorder? _border;
  set border(TableBorder? value) {
    if (border == value) return;
    _border = value;
    markNeedsPaint();
  }

  /// The decorations to use for each row of the table.
  ///
  /// Row decorations fill the horizontal and vertical extent of each row in
  /// the table, unlike decorations for individual cells, which might not fill
  /// either.
  List<Decoration> get rowDecorations =>
      List<Decoration>.unmodifiable(_rowDecorations ?? const <Decoration>[]);
  // _rowDecorations and _rowDecorationPainters need to be in sync. They have to
  // either both be null or have same length.
  List<Decoration?>? _rowDecorations;
  List<BoxPainter?>? _rowDecorationPainters;
  set rowDecorations(List<Decoration?>? value) {
    if (_rowDecorations == value) return;
    _rowDecorations = value;
    if (_rowDecorationPainters != null) {
      for (final BoxPainter? painter in _rowDecorationPainters!) painter?.dispose();
    }
    _rowDecorationPainters = _rowDecorations != null
        ? List<BoxPainter?>.filled(_rowDecorations!.length, null, growable: false)
        : null;
  }

  /// The settings to pass to the [rowDecorations] when painting, so that they
  /// can resolve images appropriately. See [ImageProvider.resolve] and
  /// [BoxPainter.paint].
  ImageConfiguration get configuration => _configuration;
  ImageConfiguration _configuration;
  set configuration(ImageConfiguration value) {
    if (value == _configuration) return;
    _configuration = value;
    markNeedsPaint();
  }

  /// How cells that do not explicitly specify a vertical alignment are aligned vertically.
  TableCellVerticalAlignment get defaultVerticalAlignment => _defaultVerticalAlignment;
  TableCellVerticalAlignment _defaultVerticalAlignment;
  set defaultVerticalAlignment(TableCellVerticalAlignment value) {
    if (_defaultVerticalAlignment == value) return;
    _defaultVerticalAlignment = value;
    markNeedsLayout();
  }

  /// The text baseline to use when aligning rows using [TableCellVerticalAlignment.baseline].
  TextBaseline? get textBaseline => _textBaseline;
  TextBaseline? _textBaseline;
  set textBaseline(TextBaseline? value) {
    if (_textBaseline == value) return;
    _textBaseline = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! TableCellParentData) child.parentData = TableCellParentData();
  }

  /// Replaces the children of this table with the given cells.
  ///
  /// The cells are divided into the specified number of columns before
  /// replacing the existing children.
  ///
  /// If the new cells contain any existing children of the table, those
  /// children are simply moved to their new location in the table rather than
  /// removed from the table and re-added.
  void setFlatChildren(int columns, List<RenderBox?> cells) {
    if (cells == _children && columns == _columns) return;
    assert(columns >= 0);
    // consider the case of a newly empty table
    if (columns == 0 || cells.isEmpty) {
      assert(cells.isEmpty);
      _columns = columns;
      if (_children.isEmpty) {
        assert(_rows == 0);
        return;
      }
      for (final RenderBox? oldChild in _children) {
        if (oldChild != null) dropChild(oldChild);
      }
      _rows = 0;
      _children.clear();
      markNeedsLayout();
      return;
    }
    assert(cells.length % columns == 0);
    // fill a set with the cells that are moving (it's important not
    // to dropChild a child that's remaining with us, because that
    // would clear their parentData field)
    final Set<RenderBox> lostChildren = HashSet<RenderBox>();
    for (int y = 0; y < _rows; y += 1) {
      for (int x = 0; x < _columns; x += 1) {
        final int xyOld = x + y * _columns;
        final int xyNew = x + y * columns;
        if (_children[xyOld] != null &&
            (x >= columns || xyNew >= cells.length || _children[xyOld] != cells[xyNew]))
          lostChildren.add(_children[xyOld]!);
      }
    }
    // adopt cells that are arriving, and cross cells that are just moving off our list of lostChildren
    int y = 0;
    while (y * columns < cells.length) {
      for (int x = 0; x < columns; x += 1) {
        final int xyNew = x + y * columns;
        final int xyOld = x + y * _columns;
        if (cells[xyNew] != null &&
            (x >= _columns || y >= _rows || _children[xyOld] != cells[xyNew])) {
          if (!lostChildren.remove(cells[xyNew])) adoptChild(cells[xyNew]!);
        }
      }
      y += 1;
    }
    // drop all the lost children
    lostChildren.forEach(dropChild);
    // update our internal values
    _columns = columns;
    _rows = cells.length ~/ columns;
    _children = List<RenderBox?>.from(cells);
    assert(_children.length == rows * columns);
    markNeedsLayout();
  }

  void setChangedColumnWidthCallback(Function(List<double>)? callback) {
    _changedColumnWidthCallback = callback;
  }

  void setChangedViewportSizeCallback(Function(Size)? callback) {
    _changedViewportSizeCallback = callback;
  }

  void setHeaders(List<RenderBox> headers) {
    for (final RenderBox? oldHeader in _headers) {
      if (oldHeader != null) dropHeader(oldHeader);
    }
    _headers.clear();
    headers.forEach(addHeader);
  }

  /// Replaces the children of this table with the given cells.
  void setChildren(List<List<RenderBox>>? cells) {
    if (cells == null) {
      setFlatChildren(0, const <RenderBox?>[]);
      return;
    }
    for (final RenderBox? oldChild in _children) {
      if (oldChild != null) dropChild(oldChild);
    }
    _children.clear();
    _columns = cells.isNotEmpty ? cells.first.length : 0;
    _rows = 0;
    cells.forEach(addRow);
    assert(_children.length == rows * columns);
  }

  void addHeader(RenderBox? header) {
    _headers.add(header);
    if (header != null) adoptChild(header);
    markNeedsLayout();
  }

  void dropHeader(RenderObject child) {
    // ignore: invalid_use_of_protected_member
    dropChild(child);
  }

  /// Adds a row to the end of the table.
  ///
  /// The newly added children must not already have parents.
  void addRow(List<RenderBox?> cells) {
    assert(cells.length == columns);
    assert(_children.length == rows * columns);
    _rows += 1;
    _children.addAll(cells);
    for (final RenderBox? cell in cells) {
      if (cell != null) adoptChild(cell);
    }
    markNeedsLayout();
  }

  /// Replaces the child at the given position with the given child.
  ///
  /// If the given child is already located at the given position, this function
  /// does not modify the table. Otherwise, the given child must not already
  /// have a parent.
  void setChild(int x, int y, RenderBox? value) {
    assert(x >= 0 && x < columns && y >= 0 && y < rows);
    assert(_children.length == rows * columns);
    final int xy = x + y * columns;
    final RenderBox? oldChild = _children[xy];
    if (oldChild == value) return;
    if (oldChild != null) dropChild(oldChild);
    _children[xy] = value;
    if (value != null) adoptChild(value);
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    for (final RenderBox? child in _children) child?.attach(owner);
  }

  @override
  void detach() {
    super.detach();
    if (_rowDecorationPainters != null) {
      for (final BoxPainter? painter in _rowDecorationPainters!) painter?.dispose();
      _rowDecorationPainters =
          List<BoxPainter?>.filled(_rowDecorations!.length, null, growable: false);
    }
    for (final RenderBox? child in _children) child?.detach();
  }

  @override
  void visitChildren(RenderObjectVisitor visitor) {
    assert(_children.length == rows * columns);
    for (final RenderBox? header in _headers) {
      if (header != null) visitor(header);
    }
    for (final RenderBox? child in _children) {
      if (child != null) visitor(child);
    }
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    assert(_children.length == rows * columns);
    double totalMinWidth = 0.0;
    for (int x = 0; x < columns; x += 1) {
      final TableColumnWidth columnWidth = _columnWidths[x] ?? defaultColumnWidth;
      final Iterable<RenderBox> columnCells = column(x);
      totalMinWidth += columnWidth.minIntrinsicWidth(columnCells, double.infinity);
    }
    return totalMinWidth;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    assert(_children.length == rows * columns);
    double totalMaxWidth = 0.0;
    for (int x = 0; x < columns; x += 1) {
      final TableColumnWidth columnWidth = _columnWidths[x] ?? defaultColumnWidth;
      final Iterable<RenderBox> columnCells = column(x);
      totalMaxWidth += columnWidth.maxIntrinsicWidth(columnCells, double.infinity);
    }
    return totalMaxWidth;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    // winner of the 2016 world's most expensive intrinsic dimension function award
    // honorable mention, most likely to improve if taught about memoization award
    assert(_children.length == rows * columns);
    final List<double> widths = _computeColumnWidths(BoxConstraints.tightForFinite(width: width));
    double rowTop = 0.0;
    for (int y = 0; y < rows; y += 1) {
      double rowHeight = 0.0;
      for (int x = 0; x < columns; x += 1) {
        final int xy = x + y * columns;
        final RenderBox? child = _children[xy];
        if (child != null) rowHeight = math.max(rowHeight, child.getMaxIntrinsicHeight(widths[x]));
      }
      rowTop += rowHeight;
    }
    return rowTop;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    return computeMinIntrinsicHeight(width);
  }

  double? _baselineDistance;
  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    // returns the baseline of the first cell that has a baseline in the first row
    assert(!debugNeedsLayout);
    return _baselineDistance;
  }

  /// Returns the list of [RenderBox] objects that are in the given
  /// column, in row order, starting from the first row.
  ///
  /// This is a lazily-evaluated iterable.
  Iterable<RenderBox> column(int x) sync* {
    for (int y = 0; y < rows; y += 1) {
      final int xy = x + y * columns;
      final RenderBox? child = _children[xy];
      if (child != null) yield child;
    }
  }

  /// Returns the list of [RenderBox] objects that are on the given
  /// row, in column order, starting with the first column.
  ///
  /// This is a lazily-evaluated iterable.
  Iterable<RenderBox> row(int y) sync* {
    final int start = y * columns;
    final int end = (y + 1) * columns;
    for (int xy = start; xy < end; xy += 1) {
      final RenderBox? child = _children[xy];
      if (child != null) yield child;
    }
  }

  List<double> _computeColumnWidths(BoxConstraints constraints) {
    assert(_children.length == rows * columns);
    // We apply the constraints to the column widths in the order of
    // least important to most important:
    // 1. apply the ideal widths (maxIntrinsicWidth)
    // 2. grow the flex columns so that the table has the maxWidth (if
    //    finite) or the minWidth (if not)
    // 3. if there were no flex columns, then grow the table to the
    //    minWidth.
    // 4. apply the maximum width of the table, shrinking columns as
    //    necessary, applying minimum column widths as we go

    // 1. apply ideal widths, and collect information we'll need later
    final List<double> widths = List<double>.filled(columns, 0.0, growable: false);
    final List<double> minWidths = List<double>.filled(columns, 0.0, growable: false);
    final List<double?> flexes = List<double?>.filled(columns, null, growable: false);
    double tableWidth = 0.0; // running tally of the sum of widths[x] for all x
    double unflexedTableWidth =
        0.0; // sum of the maxIntrinsicWidths of any column that has null flex
    double totalFlex = 0.0;
    for (int x = 0; x < columns; x += 1) {
      final TableColumnWidth columnWidth = _columnWidths[x] ?? defaultColumnWidth;
      final Iterable<RenderBox> columnCells = column(x);
      // apply ideal width (maxIntrinsicWidth)
      final double maxIntrinsicWidth =
          columnWidth.maxIntrinsicWidth(columnCells, constraints.maxWidth);
      assert(maxIntrinsicWidth.isFinite);
      assert(maxIntrinsicWidth >= 0.0);
      widths[x] = maxIntrinsicWidth;
      tableWidth += maxIntrinsicWidth;
      // collect min width information while we're at it
      final double minIntrinsicWidth =
          columnWidth.minIntrinsicWidth(columnCells, constraints.maxWidth);
      assert(minIntrinsicWidth.isFinite);
      assert(minIntrinsicWidth >= 0.0);
      minWidths[x] = minIntrinsicWidth;
      assert(maxIntrinsicWidth >= minIntrinsicWidth);
      // collect flex information while we're at it
      final double? flex = columnWidth.flex(columnCells);
      if (flex != null) {
        assert(flex.isFinite);
        assert(flex > 0.0);
        flexes[x] = flex;
        totalFlex += flex;
      } else {
        unflexedTableWidth = unflexedTableWidth + maxIntrinsicWidth;
      }
    }
    final double maxWidthConstraint = constraints.maxWidth;
    final double minWidthConstraint = constraints.minWidth;

    // 2. grow the flex columns so that the table has the maxWidth (if
    //    finite) or the minWidth (if not)
    if (totalFlex > 0.0) {
      // this can only grow the table, but it _will_ grow the table at
      // least as big as the target width.
      final double targetWidth;
      if (maxWidthConstraint.isFinite) {
        targetWidth = maxWidthConstraint;
      } else {
        targetWidth = minWidthConstraint;
      }
      if (tableWidth < targetWidth) {
        final double remainingWidth = targetWidth - unflexedTableWidth;
        assert(remainingWidth.isFinite);
        assert(remainingWidth >= 0.0);
        for (int x = 0; x < columns; x += 1) {
          if (flexes[x] != null) {
            final double flexedWidth = remainingWidth * flexes[x]! / totalFlex;
            assert(flexedWidth.isFinite);
            assert(flexedWidth >= 0.0);
            if (widths[x] < flexedWidth) {
              final double delta = flexedWidth - widths[x];
              tableWidth += delta;
              widths[x] = flexedWidth;
            }
          }
        }
        assert(tableWidth + precisionErrorTolerance >= targetWidth);
      }
    } // step 2 and 3 are mutually exclusive

    // 3. if there were no flex columns, then grow the table to the
    //    minWidth.
    else if (tableWidth < minWidthConstraint) {
      final double delta = (minWidthConstraint - tableWidth) / columns;
      for (int x = 0; x < columns; x += 1) widths[x] = widths[x] + delta;
      tableWidth = minWidthConstraint;
    }

    // beyond this point, unflexedTableWidth is no longer valid

    // 4. apply the maximum width of the table, shrinking columns as
    //    necessary, applying minimum column widths as we go
    if (tableWidth > maxWidthConstraint) {
      double deficit = tableWidth - maxWidthConstraint;
      // Some columns may have low flex but have all the free space.
      // (Consider a case with a 1px wide column of flex 1000.0 and
      // a 1000px wide column of flex 1.0; the sizes coming from the
      // maxIntrinsicWidths. If the maximum table width is 2px, then
      // just applying the flexes to the deficit would result in a
      // table with one column at -998px and one column at 990px,
      // which is wildly unhelpful.)
      // Similarly, some columns may be flexible, but not actually
      // be shrinkable due to a large minimum width. (Consider a
      // case with two columns, one is flex and one isn't, both have
      // 1000px maxIntrinsicWidths, but the flex one has 1000px
      // minIntrinsicWidth also. The whole deficit will have to come
      // from the non-flex column.)
      // So what we do is we repeatedly iterate through the flexible
      // columns shrinking them proportionally until we have no
      // available columns, then do the same to the non-flexible ones.
      int availableColumns = columns;
      while (deficit > precisionErrorTolerance && totalFlex > precisionErrorTolerance) {
        double newTotalFlex = 0.0;
        for (int x = 0; x < columns; x += 1) {
          if (flexes[x] != null) {
            final double newWidth = widths[x] - deficit * flexes[x]! / totalFlex;
            assert(newWidth.isFinite);
            if (newWidth <= minWidths[x]) {
              // shrank to minimum
              deficit -= widths[x] - minWidths[x];
              widths[x] = minWidths[x];
              flexes[x] = null;
              availableColumns -= 1;
            } else {
              deficit -= widths[x] - newWidth;
              widths[x] = newWidth;
              newTotalFlex += flexes[x]!;
            }
            assert(widths[x] >= 0.0);
          }
        }
        totalFlex = newTotalFlex;
      }
      while (deficit > precisionErrorTolerance && availableColumns > 0) {
        // Now we have to take out the remaining space from the
        // columns that aren't minimum sized.
        // To make this fair, we repeatedly remove equal amounts from
        // each column, clamped to the minimum width, until we run out
        // of columns that aren't at their minWidth.
        final double delta = deficit / availableColumns;
        assert(delta != 0);
        int newAvailableColumns = 0;
        for (int x = 0; x < columns; x += 1) {
          final double availableDelta = widths[x] - minWidths[x];
          if (availableDelta > 0.0) {
            if (availableDelta <= delta) {
              // shrank to minimum
              deficit -= widths[x] - minWidths[x];
              widths[x] = minWidths[x];
            } else {
              deficit -= delta;
              widths[x] = widths[x] - delta;
              newAvailableColumns += 1;
            }
          }
        }
        availableColumns = newAvailableColumns;
      }
    }
    return widths;
  }

  // cache the table geometry for painting purposes
  final List<double> _rowTops = <double>[];
  Iterable<double>? _columnLefts;

  /// Returns the position and dimensions of the box that the given
  /// row covers, in this render object's coordinate space (so the
  /// left coordinate is always 0.0).
  ///
  /// The row being queried must exist.
  ///
  /// This is only valid after layout.
  Rect getRowBox(int row) {
    assert(row >= 0);
    assert(row < rows);
    assert(!debugNeedsLayout);
    return Rect.fromLTRB(0.0, _rowTops[row], size.width, _rowTops[row + 1]);
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    if (rows * columns == 0) {
      return constraints.constrain(Size.zero);
    }
    final List<double> widths = _computeColumnWidths(constraints);
    final double tableWidth = widths.fold(0.0, (double a, double b) => a + b);
    double rowTop = 0.0;
    for (int y = 0; y < rows; y += 1) {
      double rowHeight = 0.0;
      for (int x = 0; x < columns; x += 1) {
        final int xy = x + y * columns;
        final RenderBox? child = _children[xy];
        if (child != null) {
          final TableCellParentData childParentData = child.parentData! as TableCellParentData;
          switch (childParentData.verticalAlignment ?? defaultVerticalAlignment) {
            case TableCellVerticalAlignment.baseline:
              assert(debugCannotComputeDryLayout(
                reason:
                    'TableCellVerticalAlignment.baseline requires a full layout for baseline metrics to be available.',
              ));
              return Size.zero;
            case TableCellVerticalAlignment.top:
            case TableCellVerticalAlignment.middle:
            case TableCellVerticalAlignment.bottom:
              final Size childSize = child.getDryLayout(BoxConstraints.tightFor(width: widths[x]));
              rowHeight = math.max(rowHeight, childSize.height);
              break;
            case TableCellVerticalAlignment.fill:
              break;
          }
        }
      }
      rowTop += rowHeight;
    }
    return constraints.constrain(Size(tableWidth, rowTop));
  }

  @override
  void performLayout() {
    final BoxConstraints constraints = this.constraints;
    final int rows = this.rows;
    final int columns = this.columns;
    assert(_children.length == rows * columns);
    if (rows * columns == 0) {
      size = constraints.constrain(Size.zero);
      return;
    }
    final List<double> widths = _computeColumnWidths(constraints);
    final List<double> positions = List<double>.filled(columns, 0.0, growable: false);
    final double tableWidth;
    switch (textDirection) {
      case TextDirection.rtl:
        positions[columns - 1] = 0.0;
        for (int x = columns - 2; x >= 0; x -= 1) positions[x] = positions[x + 1] + widths[x + 1];
        _columnLefts = positions.reversed;
        tableWidth = positions.first + widths.first;
        break;
      case TextDirection.ltr:
        positions[0] = 0.0;
        for (int x = 1; x < columns; x += 1) positions[x] = positions[x - 1] + widths[x - 1];
        _columnLefts = positions;
        tableWidth = positions.last + widths.last;
        break;
    }
    _rowTops.clear();
    _baselineDistance = null;
    // then, lay out each row
    const double headerHeight = 27;
    double rowTop = headerHeight;

    for (int x = 0; x < columns; x += 1) {
      final RenderBox? header = _headers[x];
      if (header != null) {
        final TableCellParentData headerParentData = header.parentData! as TableCellParentData;
        final offset = this.localToGlobal(
          Offset.zero,
          ancestor: ((this.parent! as RenderBox).parent! as RenderBox).parent! as RenderBox,
        );
        header.layout(BoxConstraints.tightFor(width: widths[x], height: headerHeight));
        headerParentData.offset = Offset(positions[x], -offset.dy);
      }
    }

    for (int y = 0; y < rows; y += 1) {
      _rowTops.add(rowTop);
      double rowHeight = 0.0;
      bool haveBaseline = false;
      double beforeBaselineDistance = 0.0;
      double afterBaselineDistance = 0.0;
      final List<double> baselines = List<double>.filled(columns, 0.0, growable: false);
      for (int x = 0; x < columns; x += 1) {
        final int xy = x + y * columns;
        final RenderBox? child = _children[xy];
        if (child != null) {
          final TableCellParentData childParentData = child.parentData! as TableCellParentData;
          childParentData.x = x;
          childParentData.y = y;
          switch (childParentData.verticalAlignment ?? defaultVerticalAlignment) {
            case TableCellVerticalAlignment.baseline:
              assert(textBaseline != null,
                  'An explicit textBaseline is required when using baseline alignment.');
              child.layout(BoxConstraints.tightFor(width: widths[x]), parentUsesSize: true);
              final double? childBaseline =
                  child.getDistanceToBaseline(textBaseline!, onlyReal: true);
              if (childBaseline != null) {
                beforeBaselineDistance = math.max(beforeBaselineDistance, childBaseline);
                afterBaselineDistance =
                    math.max(afterBaselineDistance, child.size.height - childBaseline);
                baselines[x] = childBaseline;
                haveBaseline = true;
              } else {
                rowHeight = math.max(rowHeight, child.size.height);
                childParentData.offset = Offset(positions[x], rowTop);
              }
              break;
            case TableCellVerticalAlignment.top:
            case TableCellVerticalAlignment.middle:
            case TableCellVerticalAlignment.bottom:
              child.layout(BoxConstraints.tightFor(width: widths[x]), parentUsesSize: true);
              rowHeight = math.max(rowHeight, child.size.height);
              break;
            case TableCellVerticalAlignment.fill:
              break;
          }
        }
      }
      if (haveBaseline) {
        if (y == 0) _baselineDistance = beforeBaselineDistance;
        rowHeight = math.max(rowHeight, beforeBaselineDistance + afterBaselineDistance);
      }
      for (int x = 0; x < columns; x += 1) {
        final int xy = x + y * columns;
        final RenderBox? child = _children[xy];
        if (child != null) {
          final TableCellParentData childParentData = child.parentData! as TableCellParentData;
          switch (childParentData.verticalAlignment ?? defaultVerticalAlignment) {
            case TableCellVerticalAlignment.baseline:
              childParentData.offset =
                  Offset(positions[x], rowTop + beforeBaselineDistance - baselines[x]);
              break;
            case TableCellVerticalAlignment.top:
              childParentData.offset = Offset(positions[x], rowTop);
              break;
            case TableCellVerticalAlignment.middle:
              childParentData.offset =
                  Offset(positions[x], rowTop + (rowHeight - child.size.height) / 2.0);
              break;
            case TableCellVerticalAlignment.bottom:
              childParentData.offset = Offset(positions[x], rowTop + rowHeight - child.size.height);
              break;
            case TableCellVerticalAlignment.fill:
              child.layout(BoxConstraints.tightFor(width: widths[x], height: rowHeight));
              childParentData.offset = Offset(positions[x], rowTop);
              break;
          }
        }
      }
      rowTop += rowHeight;
    }
    _rowTops.add(rowTop);

    size = constraints.constrain(Size(tableWidth, rowTop));
    assert(_rowTops.length == rows + 1);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    assert(_children.length == rows * columns);
    for (int index = _headers.length - 1; index >= 0; index -= 1) {
      final RenderBox? header = _headers[index];
      if (header != null) {
        final TableCellParentData headerParentData = header.parentData! as TableCellParentData;
        final offset = this.localToGlobal(
          Offset.zero + Offset(headerParentData.offset.dx, 0),
          ancestor: (this.parent! as RenderBox).parent! as RenderBox,
        );
        final bool isHit = result.addWithPaintOffset(
          offset: Offset(offset.dx, -offset.dy),
          position: position,
          hitTest: (BoxHitTestResult result, Offset? transformed) {
            assert(transformed == position - Offset(offset.dx, -offset.dy));
            return header.hitTest(result, position: transformed!);
          },
        );
        if (isHit) return true;
      }
    }
    for (int index = _children.length - 1; index >= 0; index -= 1) {
      final RenderBox? child = _children[index];
      if (child != null) {
        final BoxParentData childParentData = child.parentData! as BoxParentData;
        final bool isHit = result.addWithPaintOffset(
          offset: childParentData.offset,
          position: position,
          hitTest: (BoxHitTestResult result, Offset? transformed) {
            assert(transformed == position - childParentData.offset);
            return child.hitTest(result, position: transformed!);
          },
        );
        if (isHit) return true;
      }
    }
    return false;
  }

  Offset calculateHeaderOffset() {
    final globalTableContainerOffset =
        ((((this.parent! as RenderBox).parent! as RenderBox).parent! as RenderBox).parent!
                as RenderBox)
            .localToGlobal(Offset.zero);
    final globalTableOffset = this.localToGlobal(Offset.zero);

    return globalTableContainerOffset - globalTableOffset;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    assert(_children.length == rows * columns);
    if (rows * columns == 0) {
      if (border != null) {
        final Rect borderRect = Rect.fromLTWH(offset.dx, offset.dy, size.width, 0.0);
        border!
            .paint(context.canvas, borderRect, rows: const <double>[], columns: const <double>[]);
      }
      return;
    }
    assert(_rowTops.length == rows + 1);
    if (_rowDecorations != null) {
      assert(_rowDecorations!.length == _rowDecorationPainters!.length);
      final Canvas canvas = context.canvas;
      for (int y = 0; y < rows; y += 1) {
        if (_rowDecorations!.length <= y) break;
        if (_rowDecorations![y] != null) {
          _rowDecorationPainters![y] ??= _rowDecorations![y]!.createBoxPainter(markNeedsPaint);
          _rowDecorationPainters![y]!.paint(
            canvas,
            Offset(offset.dx, offset.dy + _rowTops[y]),
            configuration.copyWith(size: Size(size.width, _rowTops[y + 1] - _rowTops[y])),
          );
        }
      }
    }
    for (int index = 0; index < _children.length; index += 1) {
      final RenderBox? child = _children[index];
      if (child != null) {
        final BoxParentData childParentData = child.parentData! as BoxParentData;
        context.paintChild(
          child,
          childParentData.offset + offset,
        );
      }
    }
    assert(_rows == _rowTops.length - 1);
    assert(_columns == _columnLefts!.length);
    if (border != null) {
      // The border rect might not fill the entire height of this render object
      // if the rows underflow. We always force the columns to fill the width of
      // the render object, which means the columns cannot underflow.
      final Rect borderRect = Rect.fromLTWH(offset.dx, offset.dy, size.width, _rowTops.last);
      final Iterable<double> rows = _rowTops.getRange(1, _rowTops.length - 1);
      final Iterable<double> columns = _columnLefts!.skip(1);
      border!.paint(context.canvas, borderRect, rows: rows, columns: columns);
    }
    for (int index = 0; index < _headers.length; index += 1) {
      final RenderBox? header = _headers[index];
      final RenderBox? nextHeader = (index != _headers.length - 1) ? _headers[index + 1] : null;

      if (header != null) {
        final relativeOffset = this.calculateHeaderOffset();
        final BoxParentData headerParentData = header.parentData! as BoxParentData;
        context.paintChild(
            header, Offset(headerParentData.offset.dx + offset.dx, relativeOffset.dy + offset.dy));
      }

      if (nextHeader != null) {
        final relativeOffset = this.calculateHeaderOffset();
        final BoxParentData headerParentData = nextHeader.parentData! as BoxParentData;

        context.canvas.save();
        context.canvas.drawLine(
          Offset(headerParentData.offset.dx + offset.dx, relativeOffset.dy + offset.dy + 3),
          Offset(headerParentData.offset.dx + offset.dx, relativeOffset.dy + offset.dy + 23),
          Paint()
            ..color = MacosColors.windowBackgroundColor
            ..strokeWidth = 2
            ..style = PaintingStyle.fill,
        );
        context.canvas.restore();
      }
    }

    this._changedViewportSizeCallback?.call(this.size);
    this._changedColumnWidthCallback?.call(_headers.map((e) => e?.size.width ?? 0).toList());
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<TableBorder>('border', border, defaultValue: null));
    properties.add(DiagnosticsProperty<Map<int, TableColumnWidth>>(
        'specified column widths', _columnWidths,
        level: _columnWidths.isEmpty ? DiagnosticLevel.hidden : DiagnosticLevel.info));
    properties
        .add(DiagnosticsProperty<TableColumnWidth>('default column width', defaultColumnWidth));
    properties.add(MessageProperty('table size', '$columns\u00D7$rows'));
    properties.add(IterableProperty<String>('column offsets', _columnLefts?.map(debugFormatDouble),
        ifNull: 'unknown'));
    properties.add(IterableProperty<String>('row offsets', _rowTops.map(debugFormatDouble),
        ifNull: 'unknown'));
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    if (_children.isEmpty) {
      return <DiagnosticsNode>[DiagnosticsNode.message('table is empty')];
    }

    final List<DiagnosticsNode> children = <DiagnosticsNode>[];
    for (int y = 0; y < rows; y += 1) {
      for (int x = 0; x < columns; x += 1) {
        final int xy = x + y * columns;
        final RenderBox? child = _children[xy];
        final String name = 'child ($x, $y)';
        if (child != null)
          children.add(child.toDiagnosticsNode(name: name));
        else
          children.add(
              DiagnosticsProperty<Object>(name, null, ifNull: 'is null', showSeparator: false));
      }
    }
    return children;
  }
}
