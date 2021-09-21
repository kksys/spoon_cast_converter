// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

// Package imports:
import 'package:file_selector/file_selector.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:path/path.dart' as path;
import 'package:redux/redux.dart';

// Project imports:
import 'package:spoon_cast_converter/components/atom/app-table.dart';
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
  final _tableViewKey = GlobalKey();
  Size? _tableViewSize;

  @override
  void initState() {
    super.initState();
  }

  void _addFile(_ViewModel viewModel) async {
    var result = await openFile();

    if (result == null) {
      return;
    } else if (viewModel.convertFileList.any((element) => element.inputFilePath == result.path)) {
      viewModel.updateModalInfo(
        const ModalInfo(
          modalType: ModalType.MODAL_FILE_CONFLICT,
        ),
      );
    } else {
      viewModel.addInputFilePathList(
        ConvertItem(
          state: ConvertState.ADDED,
          inputFilePath: result.path,
        ),
      );
    }
  }

  void _deleteFile(_ViewModel viewModel) {
    final id = viewModel.convertFileList[viewModel.selectedIndex].id;

    if (id != null) {
      viewModel.removeInputFilePathList(id);
    }
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
    if (viewModel.modalInfo.modalType != ModalType.MODAL_HIDDEN) {
      _showModalDialog(context);
    }
  }

  String getConvertStatusString(ConvertState state) {
    switch (state) {
      case ConvertState.ADDED:
        return 'ADDED';
      case ConvertState.WAITING:
        return 'WAITING';
      case ConvertState.CONVERTING:
        return 'CONVERTING';
      case ConvertState.SUCCESS:
        return 'SUCCESS';
      case ConvertState.ERROR:
        return 'ERROR';
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context)!;

    WidgetsBinding.instance?.addPostFrameCallback((timeStamp) {
      if (_tableViewSize != _tableViewKey.currentContext?.size) {
        _tableViewSize = _tableViewKey.currentContext?.size;
        print(_tableViewSize);
        setState(() {});
      }
    });

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
                child: LayoutBuilder(
                  builder: (context2, constraints) {
                    return Stack(
                      children: [
                        Container(
                          key: _tableViewKey,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                        if (_tableViewSize != null)
                          (Container(
                            width: _tableViewSize!.width,
                            height: _tableViewSize!.height,
                            child: AppTable(
                              selectedRows: [viewModel.selectedIndex],
                              onSelected: (list) =>
                                  _selectItem(viewModel, list.length > 0 ? list.first : -1),
                              columns: [
                                AppTableColumn(
                                  width: 100.0,
                                  child: AppText(
                                    'Status',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                AppTableColumn(
                                  width: 200.0,
                                  child: AppText(
                                    'File Name',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                AppTableColumn(
                                  width: 300.0,
                                  child: AppText(
                                    'File Directory',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                              rows: viewModel.convertFileList
                                  .map(
                                    (e) => AppTableRow(
                                      children: [
                                        AppTableCell(
                                          child: AppText(
                                            getConvertStatusString(e.state),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        AppTableCell(
                                          child: AppText(
                                            path.basename(e.inputFilePath),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        AppTableCell(
                                          child: AppText(
                                            path.dirname(e.inputFilePath),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                  .toList(),
                            ),
                          )),
                      ],
                    );
                  },
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
                          viewModel.convertingIndex > -1 || viewModel.convertFileList.length == 0
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
  final List<ConvertItem> convertFileList;
  final int selectedIndex;
  final AudioFileInfo? fileInfo;
  final int convertingIndex;
  final Rational convertingStatus;
  final ModalInfo modalInfo;
  final Function(ConvertItem) addInputFilePathList;
  final Function(String) removeInputFilePathList;
  final Function(int) selectInputFilePathList;
  final Function() startConvertFileSequence;
  final Function(ModalInfo) updateModalInfo;

  _ViewModel({
    required this.convertFileList,
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
      convertFileList: store.state.convertFileList,
      selectedIndex: store.state.selectedIndex,
      fileInfo: store.state.fileInfo,
      convertingIndex: store.state.convertingIndex,
      convertingStatus: store.state.convertingStatus,
      modalInfo: store.state.modalInfo,
      addInputFilePathList: (ConvertItem convertItem) {
        store.dispatch(CheckAndAddInputFilePathListAction(convertItem: convertItem));
      },
      removeInputFilePathList: (String id) {
        store.dispatch(RemoveConvertItemAction(id: id));
      },
      selectInputFilePathList: (int index) {
        store.dispatch(SelectConvertFileListAction(index: index));
        if (store.state.convertFileList.asMap().containsKey(index)) {
          store.dispatch(GetFileInfoAction(
            filePath: store.state.convertFileList[index].inputFilePath,
          ));
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
