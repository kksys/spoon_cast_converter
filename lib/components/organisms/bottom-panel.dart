// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

// Package imports:
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:intl/intl.dart';
import 'package:redux/redux.dart';

// Project imports:
import 'package:spoon_cast_converter/components/atom/app-progressbar.dart';
import 'package:spoon_cast_converter/components/atom/app-text.dart';
import 'package:spoon_cast_converter/conf.dart';
import 'package:spoon_cast_converter/models/redux/app-state.dart';

class TableDescriptor {
  final bool Function() visible;
  final String column;
  final String value;

  const TableDescriptor({
    required this.visible,
    required this.column,
    required this.value,
  });
}

class BottomPanel extends StatefulWidget {
  BottomPanel({Key? key}) : super(key: key);

  @override
  _BottomPanelState createState() => _BottomPanelState();
}

class _BottomPanelState extends State<BottomPanel> {
  final hzFormatter = NumberFormat("#,###");
  final parcentFormatter = NumberFormat("0.0");

  List<TableRow> generateTableItems(_ViewModel viewModel) {
    final localizations = AppLocalizations.of(context)!;
    final description = [
      TableDescriptor(
        visible: () => true,
        column: localizations.appDurationLabel,
        value: '${viewModel.fileInfo?.duration.toTimeString() ?? '--:--:-- ---'}',
      ),
      TableDescriptor(
        visible: () => true,
        column: localizations.appSampleRatesLabel,
        value:
            '${viewModel.fileInfo?.sampleRates != null ? hzFormatter.format(viewModel.fileInfo?.sampleRates) : '-'} Hz',
      ),
      TableDescriptor(
        visible: () => viewModel.fileInfo?.bitRates != null && viewModel.fileInfo!.bitRates > 0,
        column: localizations.appBitRatesLabel,
        value:
            '${viewModel.fileInfo?.bitRates != null && viewModel.fileInfo!.bitRates > 0 ? viewModel.fileInfo!.bitRates : '-'} bps',
      ),
      TableDescriptor(
        visible: () => true,
        column: localizations.appChannelsLabel,
        value: '${viewModel.fileInfo?.channels ?? '-'}',
      ),
      TableDescriptor(
        visible: () => true,
        column: localizations.appCodecLabel,
        value: (() {
          var result = '';

          if (viewModel.fileInfo?.codec == null) {
            result = '-';
          } else if (viewModel.fileInfo?.profile == null) {
            result = '${viewModel.fileInfo!.codec}';
          } else {
            result = '${viewModel.fileInfo!.codec} (${viewModel.fileInfo!.profile})';
          }

          return result;
        })(),
      ),
    ];

    return description.where((e) => e.visible()).map((e) {
      return TableRow(
        children: [
          TableCell(
            child: AppText(e.column),
          ),
          TableCell(
            child: AppText(e.value),
          ),
        ],
      );
    }).toList();
  }

  double calculateCurrentFileProgress(_ViewModel viewModel) {
    double result = 0;
    final current = viewModel.convertingStatus.current;
    final duration = viewModel.convertingStatus.duration;

    if (duration > 0) {
      result = current / duration * 100;
    }

    return result;
  }

  double calculateTotalProgress(_ViewModel viewModel) {
    double result = 0;
    final numberOfTask = viewModel.convertFileList.length;
    final currentTaskIndex = viewModel.convertingIndex > 0 ? viewModel.convertingIndex : 0;
    final current = viewModel.convertingStatus.current;
    final duration = viewModel.convertingStatus.duration;

    if (numberOfTask > 0) {
      result = currentTaskIndex / numberOfTask * 100;
    }

    if (duration > 0 && numberOfTask > 0) {
      result += current / duration * 100 / numberOfTask;
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return new StoreConnector<AppState, _ViewModel>(
      converter: _ViewModel.fromStore,
      builder: (context, viewModel) {
        return Container(
          decoration: LAYOUT_DEBUGGING
              ? BoxDecoration(
                  border: Border.all(
                    color: Colors.purple,
                    width: 1.0,
                  ),
                )
              : null,
          child: Column(
            children: [
              Expanded(
                child: Container(
                  child: Table(
                    columnWidths: {
                      0: FixedColumnWidth(150),
                      1: FlexColumnWidth(),
                    },
                    children: generateTableItems(viewModel),
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                height: 20,
                child: Stack(
                  fit: StackFit.expand,
                  alignment: Alignment.center,
                  children: [
                    AppProgressBar(
                      value: calculateCurrentFileProgress(viewModel),
                      height: 20,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        AppText(
                          '${parcentFormatter.format(calculateCurrentFileProgress(viewModel))} %',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                height: 5,
              ),
              Container(
                width: double.infinity,
                height: 20,
                child: Stack(
                  fit: StackFit.expand,
                  alignment: Alignment.center,
                  children: [
                    AppProgressBar(
                      value: calculateTotalProgress(viewModel),
                      height: 20,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        AppText(
                          '${viewModel.convertingIndex + 1} / ${viewModel.convertFileList.length}',
                        ),
                      ],
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
}

class _ViewModel {
  final List<ConvertItem> convertFileList;
  final AudioFileInfo? fileInfo;
  final int convertingIndex;
  final Rational convertingStatus;

  _ViewModel({
    required this.convertFileList,
    required this.fileInfo,
    required this.convertingIndex,
    required this.convertingStatus,
  });

  static _ViewModel fromStore(Store<AppState> store) {
    return new _ViewModel(
      convertFileList: store.state.convertFileList,
      fileInfo: store.state.fileInfo,
      convertingIndex: store.state.convertingIndex,
      convertingStatus: store.state.convertingStatus,
    );
  }
}
