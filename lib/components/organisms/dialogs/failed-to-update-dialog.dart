// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:redux/redux.dart';

// Project imports:
import 'package:spoon_cast_converter/components/atom/app-text.dart';
import 'package:spoon_cast_converter/models/redux/action/app-actions.dart';
import 'package:spoon_cast_converter/models/redux/app-state.dart';

class AppFailedToUpdateDialog extends StatefulWidget {
  AppFailedToUpdateDialog({Key? key}) : super(key: key);

  @override
  _AppFailedToUpdateDialogState createState() => _AppFailedToUpdateDialogState();
}

class _AppFailedToUpdateDialogState extends State<AppFailedToUpdateDialog> {
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
          title: AppText(localizations.alertFailedToUpdateTitle),
          message: AppText(localizations.alertFailedToUpdateMessage),
          primaryButton: PushButton(
            buttonSize: ButtonSize.small,
            child: AppText(localizations.alertCommonOk),
            onPressed: () {
              Navigator.of(context).pop();
              viewModel.updateModalInfo(const ModalInfo(modalType: ModalType.MODAL_HIDDEN));
            },
          ),
        );
      },
    );
  }
}

class _ViewModel {
  final Function(ModalInfo) updateModalInfo;

  _ViewModel({
    required this.updateModalInfo,
  });

  static _ViewModel fromStore(Store<AppState> store) {
    return new _ViewModel(
      updateModalInfo: (ModalInfo modalInfo) {
        store.dispatch(UpdateModalInfoAction(modalInfo: modalInfo));
      },
    );
  }
}
