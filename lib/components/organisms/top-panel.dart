// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:file_selector/file_selector.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:redux/redux.dart';

// Project imports:
import 'package:spoon_cast_converter/components/atom/app-list-item.dart';
import 'package:spoon_cast_converter/components/atom/app-text.dart';
import 'package:spoon_cast_converter/components/templates/app-modal-dialog.dart';
import 'package:spoon_cast_converter/conf.dart';
import 'package:spoon_cast_converter/models/redux/action/app-actions.dart';
import 'package:spoon_cast_converter/models/redux/app-state.dart';

class TopPanel extends StatefulWidget {
  TopPanel({Key? key}) : super(key: key);

  @override
  _TopPanelState createState() => _TopPanelState();
}

class _TopPanelState extends State<TopPanel> {
  final padding = 6.0;

  void _addFile(_ViewModel viewModel) async {
    var result = await openFile();

    if (result == null) {
      return;
    } else if (viewModel.inputFileNameList.contains(result.path)) {
      viewModel.updateModalInfo(const ModalInfo(modalType: ModalType.MODAL_FILE_CONFLICT));
    } else {
      viewModel.addInputFilePathList(result.path);
    }
  }

  void _deleteFile(_ViewModel viewModel) {
    viewModel.removeInputFilePathList(viewModel.selectedIndex);
  }

  void _startConvert(_ViewModel viewModel) {
    viewModel.startConvertFileSequence();
  }

  void _selectItem(_ViewModel viewModel, int index) {
    viewModel.selectInputFilePathList(index);
  }

  void _showModalDialog(BuildContext context) {
    showMacosAlertDialog(
      context: context,
      builder: (context) => AppModalDialog(),
    );
  }

  void _updateModalDialog(BuildContext context, _ViewModel viewModel) {
    switch (viewModel.modalInfo.modalType) {
      case ModalType.MODAL_HIDDEN:
        Navigator.of(context).pop();
        break;
      default:
        _showModalDialog(context);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context)!;

    return new StoreConnector<AppState, _ViewModel>(
      converter: _ViewModel.fromStore,
      distinct: true,
      onWillChange: (_ViewModel? before, _ViewModel after) {
        if (before?.modalInfo.modalType != after.modalInfo.modalType) {
          _updateModalDialog(context, after);
        }
      },
      builder: (context, viewModel) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                height: double.infinity,
                decoration: LAYOUT_DEBUGGING
                    ? BoxDecoration(
                        border: Border.all(
                          color: Colors.blue,
                          width: 1.0,
                        ),
                      )
                    : null,
                child: GestureDetector(
                  onTap: () {
                    _selectItem(viewModel, -1);
                  },
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: viewModel.inputFileNameList.length,
                    itemBuilder: (_, index) {
                      return AppListItem(
                        onTap: () => _selectItem(viewModel, index),
                        selected: viewModel.selectedIndex == index,
                        build: () {
                          return AppText(
                            viewModel.inputFileNameList[index],
                            overflow: TextOverflow.ellipsis,
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.only(left: padding),
              width: 120,
              decoration: LAYOUT_DEBUGGING
                  ? BoxDecoration(
                      border: Border.all(
                        color: Colors.red,
                        width: 1.0,
                      ),
                    )
                  : null,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    child: PushButton(
                      onPressed: viewModel.convertingIndex > -1 ? null : () => _addFile(viewModel),
                      buttonSize: ButtonSize.small,
                      child: AppText(localizations.appSelectButton),
                    ),
                  ),
                  Container(
                    height: 5,
                  ),
                  Container(
                    width: double.infinity,
                    child: PushButton(
                      onPressed: viewModel.convertingIndex > -1
                          ? null
                          : viewModel.selectedIndex > -1
                              ? () => _deleteFile(viewModel)
                              : null,
                      buttonSize: ButtonSize.small,
                      child: AppText(localizations.appDeleteButton),
                    ),
                  ),
                  Spacer(),
                  Container(
                    width: double.infinity,
                    child: PushButton(
                      onPressed:
                          viewModel.convertingIndex > -1 || viewModel.inputFileNameList.length == 0
                              ? null
                              : () => _startConvert(viewModel),
                      buttonSize: ButtonSize.small,
                      child: AppText(localizations.appStartToConvertButton),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ViewModel {
  final List<String> inputFileNameList;
  final int selectedIndex;
  final AudioFileInfo? fileInfo;
  final int convertingIndex;
  final Rational convertingStatus;
  final ModalInfo modalInfo;
  final Function(String) addInputFilePathList;
  final Function(int) removeInputFilePathList;
  final Function(int) selectInputFilePathList;
  final Function() startConvertFileSequence;
  final Function(ModalInfo) updateModalInfo;

  _ViewModel({
    required this.inputFileNameList,
    required this.selectedIndex,
    required this.fileInfo,
    required this.convertingIndex,
    required this.convertingStatus,
    required this.modalInfo,
    required this.addInputFilePathList,
    required this.removeInputFilePathList,
    required this.selectInputFilePathList,
    required this.startConvertFileSequence,
    required this.updateModalInfo,
  });

  static _ViewModel fromStore(Store<AppState> store) {
    return new _ViewModel(
      inputFileNameList: store.state.inputFilePathList,
      selectedIndex: store.state.selectedIndex,
      fileInfo: store.state.fileInfo,
      convertingIndex: store.state.convertingIndex,
      convertingStatus: store.state.convertingStatus,
      modalInfo: store.state.modalInfo,
      addInputFilePathList: (String filepath) {
        store.dispatch(CheckAndAddInputFilePathListAction(filepath: filepath));
      },
      removeInputFilePathList: (int index) {
        store.dispatch(RemoveInputFilePathListAction(index: index));
      },
      selectInputFilePathList: (int index) {
        store.dispatch(SelectInputFilePathListAction(index: index));
        if (store.state.inputFilePathList.asMap().containsKey(index)) {
          store.dispatch(OpenInputFileAction(filePath: store.state.inputFilePathList[index]));
        } else {
          store.dispatch(UpdateFileInfoAction());
        }
      },
      startConvertFileSequence: () {
        store.dispatch(StartConvertSequenceAction());
      },
      updateModalInfo: (ModalInfo modalInfo) {
        store.dispatch(UpdateModalInfoAction(modalInfo: modalInfo));
      },
    );
  }
}
