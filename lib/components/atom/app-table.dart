// Dart imports:
import 'dart:io';
import 'dart:math';

// Flutter imports:
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:macos_ui/macos_ui.dart';

// Project imports:
import 'package:spoon_cast_converter/components/atom/app-text.dart';
import 'package:spoon_cast_converter/components/atom/table/widget.dart';

class AppTableColumn extends StatefulWidget {
  final double width;
  final Widget child;

  const AppTableColumn({
    Key? key,
    required this.width,
    required this.child,
  }) : super(key: key);

  @override
  _AppTableColumnState createState() => _AppTableColumnState();
}

class _AppTableColumnState extends State<AppTableColumn> {
  @override
  Widget build(BuildContext context) {
    return this.widget.child;
  }
}

class AppTableCell extends StatefulWidget {
  final Widget child;

  const AppTableCell({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  _AppTableCellState createState() => _AppTableCellState();
}

class _AppTableCellState extends State<AppTableColumn> {
  @override
  Widget build(BuildContext context) {
    return this.widget.child;
  }
}

class AppTableRow extends StatefulWidget {
  final List<AppTableCell> children;

  const AppTableRow({
    Key? key,
    required this.children,
  }) : super(key: key);

  @override
  _AppTableRowState createState() => _AppTableRowState();
}

class _AppTableRowState extends State<AppTableColumn> {
  @override
  Widget build(BuildContext context) {
    return this.widget.child;
  }
}

enum AppTableSelectionType {
  SINGLE_ROW_SELECTION,
  MULTI_ROW_SELECTION,
}

class AppTable extends StatefulWidget {
  final List<AppTableColumn> columns;
  final List<AppTableRow> rows;
  final AppTableSelectionType selectionType;
  final Function(List<int>)? onSelected;
  final List<int> selectedRow;

  const AppTable({
    Key? key,
    required this.columns,
    required this.rows,
    this.selectionType = AppTableSelectionType.SINGLE_ROW_SELECTION,
    this.onSelected,
    this.selectedRow = const [],
  }) : super(key: key);

  _AppTable createState() => _AppTable();
}

class _AppTable extends State<AppTable> {
  int? _targetIndex;
  int? _targetIndex2;
  double? _currentPos;
  double? _mouseDiffPos;
  late List<double> _widthForViewIncludeLast;
  late List<double> _widthForView;
  late List<double> _widthForCalculate;
  FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _widthForView = _widthForCalculate = widget.columns.map((e) => e.width).toList();
    _widthForViewIncludeLast = [..._widthForView, 0];
  }

  void _onDoubleClickDown(int index, TapDownDetails detail) {
    print('_onDoubleClickDown: $index, ${detail.localPosition}');

    if (index < _widthForCalculate.length &&
        detail.localPosition.dx > _widthForCalculate[index] - 2 &&
        detail.localPosition.dx <= _widthForCalculate[index]) {
      setState(() {
        _targetIndex2 = index;
      });
    } else if (index > 0 && detail.localPosition.dx >= 0 && detail.localPosition.dx < 2) {
      setState(() {
        _targetIndex2 = index - 1;
      });
    }
  }

  void _onDoubleClick(int index) {
    print('_onDoubleClick: $index');

    setState(() {
      if (_targetIndex2 != null) {
        _widthForViewIncludeLast[_targetIndex2!] = _widthForView[_targetIndex2!] = -1;
      }
      _targetIndex2 = null;
    });
  }

  void _onDragStart(int index, DragDownDetails detail) {
    print('_onDragStart: ${detail.localPosition}');

    if (index < _widthForCalculate.length &&
        detail.localPosition.dx > _widthForCalculate[index] - 2 &&
        detail.localPosition.dx <= _widthForCalculate[index]) {
      setState(() {
        _targetIndex = index;
        _currentPos = detail.localPosition.dx;
        _mouseDiffPos = detail.localPosition.dx - (_widthForCalculate[index] - 2);
      });
    } else if (index > 0 && detail.localPosition.dx >= 0 && detail.localPosition.dx < 2) {
      setState(() {
        _targetIndex = index - 1;
        _currentPos = _widthForCalculate[_targetIndex!] + detail.localPosition.dx;
        _mouseDiffPos = _widthForCalculate[_targetIndex!] +
            detail.localPosition.dx -
            (_widthForCalculate[_targetIndex!] - 2);
      });
    }
  }

  void _onDragMove(int index, DragUpdateDetails detail) {
    print('_onDragMove: ${detail.localPosition}');

    setState(() {
      if (_targetIndex != null && _currentPos != null && _mouseDiffPos != null) {
        _currentPos = _currentPos! + detail.delta.dx;
        final double width = max(_currentPos! - _mouseDiffPos! + 2, 0);

        if (_targetIndex == this._widthForViewIncludeLast.length - 2) {
          final lastWidth = _size!.width -
              2 -
              this
                  ._widthForViewIncludeLast
                  .sublist(0, _targetIndex)
                  .reduce((value, element) => value + element);
          _widthForViewIncludeLast[_targetIndex! + 1] = lastWidth;

          _widthForViewIncludeLast.setRange(_targetIndex!, _targetIndex! + 2, [width, lastWidth]);
          _widthForView[_targetIndex!] = width;
        } else {
          _widthForViewIncludeLast[_targetIndex!] = width;
          _widthForView[_targetIndex!] = width;
        }
      }
    });
  }

  void _onDragStop(int index) {
    print('_onDragStop:');

    setState(() {
      _targetIndex = null;
      _currentPos = null;
      _mouseDiffPos = null;
    });
  }

  bool _multiSelectionKeyPressed = false;

  void _onCellClick(int row) {
    List<int> _selectedRow = [...this.widget.selectedRow];

    setState(() {
      if (this.widget.selectionType == AppTableSelectionType.SINGLE_ROW_SELECTION ||
          (this.widget.selectionType == AppTableSelectionType.MULTI_ROW_SELECTION &&
              !_multiSelectionKeyPressed)) {
        _selectedRow = [row];
      } else if (_selectedRow.contains(row)) {
        _selectedRow = _selectedRow.where((element) => element != row).toList();
      } else {
        _selectedRow = [..._selectedRow, row]..sort((a, b) => a.compareTo(b));
      }
    });

    this.widget.onSelected?.call(_selectedRow);
  }

  void _onKey(RawKeyEvent event) {
    final multipleSelectionKeyList = (Platform.isMacOS)
        ? [LogicalKeyboardKey.meta, LogicalKeyboardKey.metaLeft, LogicalKeyboardKey.metaRight]
        : [
            LogicalKeyboardKey.control,
            LogicalKeyboardKey.controlLeft,
            LogicalKeyboardKey.controlRight
          ];

    if (!multipleSelectionKeyList.any((element) => element == event.logicalKey)) {
      return;
    }

    _multiSelectionKeyPressed =
        multipleSelectionKeyList.any((element) => event.isKeyPressed(element));
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return MediaQuery(
      data: mediaQuery.copyWith(
        padding: EdgeInsets.all(-3),
        viewPadding: EdgeInsets.all(-3),
      ),
      child: RawKeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKey: _onKey,
        child: buildContainer(context),
      ),
    );
  }

  final _key = GlobalKey();
  Size? _size;

  Widget buildContainer(BuildContext context) {
    WidgetsBinding.instance?.addPostFrameCallback((timeStamp) {
      if (_size != _key.currentContext?.size) {
        setState(() {
          _size = _key.currentContext?.size ?? _size;
        });
      }
    });

    return Stack(
      children: [
        Container(
          key: _key,
          width: double.infinity,
          height: double.infinity,
        ),
        if (_size != null)
          (Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: MacosColors.windowBackgroundColor,
                width: 1.0,
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              physics: ClampingScrollPhysics(),
              child: SingleChildScrollView(
                padding: EdgeInsets.zero,
                physics: ClampingScrollPhysics(),
                child: Container(
                  constraints: BoxConstraints(
                    minWidth: _size!.width > 0 ? _size!.width - 2 : 0,
                    minHeight: _size!.height > 0 ? _size!.height - 2 : 0,
                  ),
                  child: buildTable(context),
                ),
              ),
            ),
          ))
      ],
    );
  }

  MacosStyleTableColumn generateColumn({
    required int index,
    required Widget child,
  }) {
    double leftCursorRegionWidth = 2;
    double rightCursorRegionWidth = 2;

    if (index == 0 && this._widthForViewIncludeLast[index] < 2) {
      leftCursorRegionWidth = 0;
      rightCursorRegionWidth = this._widthForViewIncludeLast[index];
    } else if (index == this._widthForViewIncludeLast.length - 1 &&
        this._widthForViewIncludeLast[index] < 2) {
      leftCursorRegionWidth = this._widthForViewIncludeLast[index];
      rightCursorRegionWidth = 0;
    } else if (this._widthForViewIncludeLast[index] < 4) {
      final width = this._widthForViewIncludeLast[index] / 2;
      leftCursorRegionWidth = width;
      rightCursorRegionWidth = width;
    }

    return MacosStyleTableColumn(
      child: GestureDetector(
        onDoubleTapDown: (detail) => this._onDoubleClickDown(index, detail),
        onDoubleTap: () => this._onDoubleClick(index),
        onHorizontalDragDown: (detail) => this._onDragStart(index, detail),
        onHorizontalDragEnd: (detail) => this._onDragStop(index),
        onHorizontalDragUpdate: (detail) => this._onDragMove(index, detail),
        onHorizontalDragCancel: () => this._onDragStop(index),
        child: Container(
          width: double.infinity,
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(3.0),
                decoration: BoxDecoration(
                  color: MacosColors.textBackgroundColor,
                  border: Border(
                    bottom: BorderSide(
                      color: MacosColors.windowBackgroundColor,
                      width: 1.0,
                    ),
                  ),
                ),
                child: child,
              ),
              if (index > 0)
                Positioned(
                  left: 0,
                  width: leftCursorRegionWidth,
                  height: 27,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.resizeLeftRight,
                    child: Container(
                      width: leftCursorRegionWidth,
                    ),
                  ),
                ),
              if (index < this.widget.columns.length)
                Positioned(
                  right: 0,
                  width: rightCursorRegionWidth,
                  height: 27,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.resizeLeftRight,
                    child: Container(
                      width: rightCursorRegionWidth,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  MacosStyleTableCell generateCell({
    required int index,
    required Widget child,
  }) {
    Color backgroundColor = (index % 2 > 0)
        ? MacosColors.alternatingContentBackgroundColor
        : MacosColors.textBackgroundColor;

    if (this.widget.selectedRow.contains(index)) {
      backgroundColor = MacosColors.selectedControlBackgroundColor;
    }

    return MacosStyleTableCell(
      child: GestureDetector(
        onTap: () => this._onCellClick(index),
        child: Container(
          margin: (index > 0) ? EdgeInsets.zero : EdgeInsets.only(top: 5.0),
          padding: EdgeInsets.only(left: 3.0, right: 3.0),
          decoration: BoxDecoration(
            color: backgroundColor,
          ),
          child: child,
        ),
      ),
    );
  }

  Widget buildTable(BuildContext context) {
    return MacosStyleTable(
      columnWidths: [
        ..._widthForView.map((e) => e < 0 ? IntrinsicColumnWidth() : FixedColumnWidth(e)).toList(),
        FlexColumnWidth(),
      ].asMap(),
      onChangeColumnWidth: (widthList) {
        final newWidthList = widthList.sublist(0, this.widget.columns.length);
        print(widthList);
        _widthForCalculate = newWidthList;
        _widthForViewIncludeLast = widthList;
      },
      headers: [
        ...this.widget.columns.asMap().map((index, e) {
          return MapEntry(
            index,
            generateColumn(
              index: index,
              child: e.child,
            ),
          );
        }).values,
        generateColumn(
          index: this.widget.columns.length,
          child: const AppText(''),
        ),
      ],
      children: [
        ...this.widget.rows.asMap().map((index, e) {
          return MapEntry(
            index,
            MacosStyleTableRow(
              children: [
                ...e.children.map((cell) {
                  return generateCell(
                    index: index,
                    child: cell.child,
                  );
                }),
                generateCell(
                  index: index,
                  child: const AppText(''),
                ),
              ],
            ),
          );
        }).values,
      ],
    );
  }
}
