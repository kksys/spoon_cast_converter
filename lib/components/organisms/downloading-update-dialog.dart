// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:intl/intl.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:redux/redux.dart';

// Project imports:
import 'package:spoon_cast_converter/components/atom/app-progressbar.dart';
import 'package:spoon_cast_converter/components/atom/app-text.dart';
import 'package:spoon_cast_converter/models/redux/action/app-actions.dart';
import 'package:spoon_cast_converter/models/redux/app-state.dart';

class AppDownloadingUpdateDialog extends StatefulWidget {
  AppDownloadingUpdateDialog({Key? key}) : super(key: key);

  @override
  _AppDownloadingUpdateDialogState createState() => _AppDownloadingUpdateDialogState();
}

class _AppDownloadingUpdateDialogState extends State<AppDownloadingUpdateDialog> {
  final parcentFormatter = NumberFormat("0.0");

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context)!;

    return StoreConnector<AppState, _ViewModel>(
      converter: _ViewModel.fromStore,
      builder: (context, viewModel) {
        final double progress =
            viewModel.totalBytes > 0 ? viewModel.currentBytes / viewModel.totalBytes * 100 : 0;

        return MacosAlertDialog(
          appIcon: FlutterLogo(
            size: 56,
          ),
          title: AppText(
            progress.floor() == 100
                ? localizations.alertDownloadingUpdaterTitleWithDownloaded
                : localizations.alertDownloadingUpdaterTitleWithDownloading,
          ),
          message: Column(
            children: [
              AppText(
                progress.floor() == 100
                    ? localizations.alertDownloadingUpdaterMessageWithDownloaded
                    : localizations.alertDownloadingUpdaterMessageWithDownloading,
              ),
              Container(
                margin: EdgeInsets.only(top: 20.0),
                width: double.infinity,
                height: 20,
                child: Stack(
                  fit: StackFit.expand,
                  alignment: Alignment.center,
                  children: [
                    AppProgressBar(
                      height: 20,
                      value: progress,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        AppText(
                          '${parcentFormatter.format(progress)} %',
                        ),
                      ],
                    ),
                  ],
                ),
              )
            ],
          ),
          primaryButton: PushButton(
            buttonSize: ButtonSize.small,
            child: AppText(localizations.alertDownloadingUpdaterExitButton),
            onPressed: progress.floor() == 100
                ? () {
                    viewModel.exitAndOpenPackage();
                  }
                : null,
          ),
        );
      },
    );
  }
}

class _ViewModel {
  final int currentBytes;
  final int totalBytes;
  final Function() exitAndOpenPackage;

  _ViewModel({
    required this.currentBytes,
    required this.totalBytes,
    required this.exitAndOpenPackage,
  });

  static _ViewModel fromStore(Store<AppState> store) {
    return new _ViewModel(
      currentBytes: store.state.modalInfo.payload.containsKey('currentBytes')
          ? store.state.modalInfo.payload['currentBytes']
          : 0,
      totalBytes: store.state.modalInfo.payload.containsKey('totalBytes')
          ? store.state.modalInfo.payload['totalBytes']
          : 0,
      exitAndOpenPackage: () {
        store.dispatch(ExitAndOpenPackageAction());
      },
    );
  }
}
