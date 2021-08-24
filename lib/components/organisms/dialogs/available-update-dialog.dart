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

class AppAvailableUpdateDialog extends StatefulWidget {
  AppAvailableUpdateDialog({Key? key}) : super(key: key);

  @override
  _AppAvailableUpdateDialogState createState() => _AppAvailableUpdateDialogState();
}

class _AppAvailableUpdateDialogState extends State<AppAvailableUpdateDialog> {
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
          title: AppText(localizations.alertAvailableVersionTitle),
          message: AppText(localizations.alertAvailableVersionMessage(
            viewModel.currentVersion,
            viewModel.availableVersion,
          )),
          primaryButton: PushButton(
            buttonSize: ButtonSize.small,
            child: AppText(localizations.alertAvailableVersionDownloadButton),
            onPressed: () {
              Navigator.of(context).pop();
              viewModel.updateModalInfo(const ModalInfo(modalType: ModalType.MODAL_HIDDEN));
              viewModel.startUpdateSequence();
            },
          ),
          secondaryButton: PushButton(
            buttonSize: ButtonSize.small,
            child: AppText(localizations.alertAvailableVersionAfterwardsButton),
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
  final String currentVersion;
  final String availableVersion;
  final Function(ModalInfo) updateModalInfo;
  final Function() startUpdateSequence;

  _ViewModel({
    required this.currentVersion,
    required this.availableVersion,
    required this.updateModalInfo,
    required this.startUpdateSequence,
  });

  static _ViewModel fromStore(Store<AppState> store) {
    return new _ViewModel(
      currentVersion: store.state.modalInfo.payload.containsKey('currentVersion')
          ? store.state.modalInfo.payload['currentVersion']
          : '',
      availableVersion: store.state.modalInfo.payload.containsKey('availableVersion')
          ? store.state.modalInfo.payload['availableVersion']
          : '',
      updateModalInfo: (ModalInfo modalInfo) {
        store.dispatch(UpdateModalInfoAction(modalInfo: modalInfo));
      },
      startUpdateSequence: () {
        store.dispatch(DownloadLatestUpdatePackageAction());
      },
    );
  }
}
