// Flutter imports:
import 'package:flutter/widgets.dart';

// Package imports:
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

// Project imports:
import 'package:spoon_cast_converter/components/organisms/dialogs/already-exist-destination-dialog.dart';
import 'package:spoon_cast_converter/components/organisms/dialogs/already-latest-version-dialog.dart';
import 'package:spoon_cast_converter/components/organisms/dialogs/available-update-dialog.dart';
import 'package:spoon_cast_converter/components/organisms/dialogs/downloading-update-dialog.dart';
import 'package:spoon_cast_converter/components/organisms/dialogs/failed-to-update-dialog.dart';
import 'package:spoon_cast_converter/components/organisms/dialogs/file-conflict-dialog.dart';
import 'package:spoon_cast_converter/components/organisms/dialogs/finish-convert-sequence-dialog.dart';
import 'package:spoon_cast_converter/components/organisms/dialogs/license-dialog.dart';
import 'package:spoon_cast_converter/components/organisms/dialogs/unsupported-filetype-dialog.dart';
import 'package:spoon_cast_converter/models/redux/app-state.dart';

class AppModalDialog extends StatefulWidget {
  AppModalDialog({Key? key}) : super(key: key);

  @override
  _AppModalDialogState createState() => _AppModalDialogState();
}

class _AppModalDialogState extends State<StatefulWidget> {
  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, _ViewModel>(
      converter: _ViewModel.fromStore,
      builder: (context, viewModel) {
        final Widget widget;

        switch (viewModel.modalType) {
          case ModalType.MODAL_FILE_CONFLICT:
            widget = AppFileConflictDialog();
            break;
          case ModalType.MODAL_FINISH_CONVERT_SEQUENCE:
            widget = AppFinishConvertSequenceDialog();
            break;
          case ModalType.MODAL_UNSUPPORTED_FILETYPE:
            widget = AppUnsupportedFileTypeDialog();
            break;
          case ModalType.MODAL_AVAILABLE_UPDATE:
            widget = AppAvailableUpdateDialog();
            break;
          case ModalType.MODAL_ALREADY_LATEST_VERSION:
            widget = AppAlreadyLatestVersionDialog();
            break;
          case ModalType.MODAL_DOWNLOADING_UPDATE:
            widget = AppDownloadingUpdateDialog();
            break;
          case ModalType.MODAL_FAILED_TO_UPDATE:
            widget = AppFailedToUpdateDialog();
            break;
          case ModalType.MODAL_LICENSE:
            widget = AppLicenseDialog();
            break;
          case ModalType.MODAL_ALREADY_EXIST_DESTINATION:
            widget = AppAlreadyExistDestinationDialog();
            break;
          default:
            widget = SizedBox.shrink();
            break;
        }

        return widget;
      },
    );
  }
}

class _ViewModel {
  final ModalType modalType;

  _ViewModel({
    required this.modalType,
  });

  static _ViewModel fromStore(Store<AppState> store) {
    return _ViewModel(
      modalType: store.state.modalInfo.modalType,
    );
  }
}
