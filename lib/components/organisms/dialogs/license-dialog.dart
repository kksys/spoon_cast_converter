// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:redux/redux.dart';
import 'package:sticky_headers/sticky_headers.dart';

// Project imports:
import 'package:spoon_cast_converter/components/atom/app-alert-dialog.dart';
import 'package:spoon_cast_converter/components/atom/app-text.dart';
import 'package:spoon_cast_converter/ffmpeg_licenses.dart';
import 'package:spoon_cast_converter/models/redux/action/app-actions.dart';
import 'package:spoon_cast_converter/models/redux/app-state.dart';
import 'package:spoon_cast_converter/oss_licenses.dart';

class FlutterLibrariesLicense {
  final String name;
  final String version;
  final String license;

  const FlutterLibrariesLicense({
    required this.name,
    required this.version,
    required this.license,
  });
}

class AppLicenseDialog extends StatefulWidget {
  AppLicenseDialog({Key? key}) : super(key: key);

  @override
  _AppLicenseDialogState createState() => _AppLicenseDialogState();
}

class _AppLicenseDialogState extends State<AppLicenseDialog> {
  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    final licenses = [
      ...ossLicenses.values
          .map((e) => FlutterLibrariesLicense(
                name: e['name'],
                version: e['version'],
                license: e['license'],
              ))
          .toList(),
      ...ffmpegLicenses.values
          .map((e) => FlutterLibrariesLicense(
                name: e['name'],
                version: e['version'],
                license: e['license'],
              ))
          .toList(),
    ];

    final size = MediaQuery.of(context).size;
    const paddingLicense = 18.0;
    const paddingLicenseBottom = 54.0;
    const padding = 28 + 56 + 28 + 16 + 18 + 16 + 16 + 46;

    return StoreConnector<AppState, _ViewModel>(
      converter: _ViewModel.fromStore,
      builder: (context, viewModel) {
        return AppAlertDialog(
          appIcon: FlutterLogo(
            size: 56,
          ),
          title: AppText(localizations.alertLicenseTitle),
          message: Container(
            width: double.infinity,
            height: size.height * 0.85 - padding,
            child: SingleChildScrollView(
              child: Column(
                children: licenses
                    .asMap()
                    .map((index, license) {
                      return MapEntry(
                        index,
                        StickyHeader(
                          header: Container(
                            width: double.infinity,
                            height: 50.0,
                            color: MacosColors.windowBackgroundColor,
                            padding: EdgeInsets.symmetric(horizontal: 16.0),
                            alignment: Alignment.centerLeft,
                            child: AppText(
                              '${license.name} v.${license.version}',
                              textScale: 1.5,
                            ),
                          ),
                          content: Container(
                            padding: EdgeInsets.only(
                              top: paddingLicense,
                              left: paddingLicense,
                              right: paddingLicense,
                              bottom: index < licenses.length - 1 ? paddingLicenseBottom : 0.0,
                            ),
                            width: double.infinity,
                            child: AppText(
                              license.license,
                              textAlign: TextAlign.left,
                            ),
                          ),
                        ),
                      );
                    })
                    .values
                    .toList(),
              ),
            ),
          ),
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
