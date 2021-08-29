// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:file_selector/file_selector.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:path/path.dart' as FilePath;
import 'package:redux/redux.dart';

// Project imports:
import 'package:spoon_cast_converter/components/atom/app-text.dart';
import 'package:spoon_cast_converter/models/redux/action/app-actions.dart';
import 'package:spoon_cast_converter/models/redux/app-state.dart';

class AppAlreadyExistDestinationDialog extends StatefulWidget {
  AppAlreadyExistDestinationDialog({Key? key}) : super(key: key);

  @override
  _AppAlreadyExistDestinationDialogState createState() => _AppAlreadyExistDestinationDialogState();
}

class _AppAlreadyExistDestinationDialogState extends State<AppAlreadyExistDestinationDialog> {
  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context)!;

    return StoreConnector<AppState, _ViewModel>(
      converter: _ViewModel.fromStore,
      builder: (context, viewModel) {
        return MacosAlertDialog(
          appIcon: FlutterLogo(
            size: 56,
          ),
          title: AppText(localizations.alertAlreadyExistDestinationTitle),
          message: AppText(localizations.alertAlreadyExistDestinationMessage),
          primaryButton: PushButton(
            buttonSize: ButtonSize.small,
            child: AppText(localizations.appAlreadyExistDestinationOverwriteButton),
            onPressed: () {
              Navigator.of(context).pop();
              viewModel.updateModalInfo(const ModalInfo(modalType: ModalType.MODAL_HIDDEN));
              viewModel.continueConvertFile();
            },
          ),
          secondaryButton: PushButton(
            buttonSize: ButtonSize.small,
            child: AppText(localizations.appAlreadyExistDestinationSelectOtherDestinationButton),
            onPressed: () async {
              final manualSelectedOutputPath = await getSavePath(
                acceptedTypeGroups: [
                  XTypeGroup(
                    label: 'm4a Files',
                    extensions: ['m4a'],
                    mimeTypes: ['audio/*'],
                  ),
                ],
                initialDirectory: viewModel.initDirectory,
                suggestedName: 'untitled',
              );
              Navigator.of(context).pop();
              viewModel.updateModalInfo(const ModalInfo(modalType: ModalType.MODAL_HIDDEN));
              if (manualSelectedOutputPath != null) {
                viewModel.updateOutputFilePath(manualSelectedOutputPath);
                viewModel.continueConvertFile();
              } else {
                await Future.delayed(Duration(microseconds: 500));
                viewModel.continueNextConvertSequence();
              }
            },
          ),
        );
      },
    );
  }
}

class _ViewModel {
  final String? initDirectory;
  final Function(ModalInfo) updateModalInfo;
  final Function(String) updateOutputFilePath;
  final Function() continueConvertFile;
  final Function() continueNextConvertSequence;

  _ViewModel({
    this.initDirectory,
    required this.updateModalInfo,
    required this.updateOutputFilePath,
    required this.continueConvertFile,
    required this.continueNextConvertSequence,
  });

  static _ViewModel fromStore(Store<AppState> store) {
    return new _ViewModel(
      initDirectory: store.state.convertingIndex < store.state.convertFileList.length
          ? FilePath.dirname(store.state.convertFileList[store.state.convertingIndex].inputFilePath)
          : null,
      updateModalInfo: (ModalInfo modalInfo) {
        store.dispatch(UpdateModalInfoAction(modalInfo: modalInfo));
      },
      updateOutputFilePath: (String outputFilePath) {
        final currentItem = store.state.convertFileList[store.state.convertingIndex];
        store.dispatch(UpdateConvertItemAction(
          convertItem: ConvertItem(
            id: currentItem.id,
            inputFilePath: currentItem.inputFilePath,
            outputFilePath: outputFilePath,
          ),
        ));
      },
      continueConvertFile: () {
        store.dispatch(RequestConvertAction(forceConvert: true));
      },
      continueNextConvertSequence: () {
        store.dispatch(ContinueNextConvertSequenceAction());
      },
    );
  }
}
