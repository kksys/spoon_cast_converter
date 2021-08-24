// Dart imports:
import 'dart:io';
import 'dart:isolate';

// Package imports:
import 'package:redux/redux.dart';

// Project imports:
import 'package:spoon_cast_converter/lib/version-check-lib.dart';
import 'package:spoon_cast_converter/models/redux/action/app-actions.dart';
import 'package:spoon_cast_converter/models/redux/app-state.dart';

final VersionCheckLib versionLib = VersionCheckLibImpl();

final List<Middleware<AppState>> versionMiddleware = [
  TypedMiddleware<AppState, CheckExistAvailableUpdateAction>(
      _checkAvailableUpdateAtLaunch(versionLib)),
  TypedMiddleware<AppState, DownloadLatestUpdatePackageAction>(_downloadLatestVersion(versionLib)),
  TypedMiddleware<AppState, ExitAndOpenPackageAction>(_exitAndOpenPackage(versionLib)),
];

void Function(
  Store<AppState> store,
  CheckExistAvailableUpdateAction action,
  NextDispatcher next,
) _checkAvailableUpdateAtLaunch(VersionCheckLib versionLib) {
  return (store, action, next) async {
    try {
      await versionLib.fetchLatestVersionInfo();
      final currentVersion = await versionLib.getCurrentVersion();
      final availableVersion = await versionLib.getAvailableUpdate();

      if (!action.launchTime || availableVersion != null) {
        store.dispatch(UpdateModalInfoAction(
          modalInfo: ModalInfo(
            modalType: ModalType.MODAL_AVAILABLE_UPDATE,
            payload: {
              'currentVersion': currentVersion,
              'availableVersion': availableVersion,
            },
          ),
        ));
      }
    } catch (e) {
      print(e);
      if (!action.launchTime) {
        store.dispatch(UpdateModalInfoAction(
          modalInfo: ModalInfo(
            modalType: ModalType.MODAL_FAILED_TO_UPDATE,
          ),
        ));
      }
    }
  };
}

class DownloadLatestVersionSpawnParams {
  SendPort sendPort;
  SendPort sendPortForCallback;
  String downloadPath;

  DownloadLatestVersionSpawnParams({
    required this.sendPort,
    required this.sendPortForCallback,
    required this.downloadPath,
  });
}

class DownloadLatestVersionCallbackParam {
  int currentBytes;
  int totalBytes;

  DownloadLatestVersionCallbackParam({
    required this.currentBytes,
    required this.totalBytes,
  });
}

void _internalDownloadLatestVersion(DownloadLatestVersionSpawnParams params) async {
  VersionCheckLib versionLib = VersionCheckLibImpl();

  await versionLib.fetchLatestVersionInfo();
  await versionLib.downloadUpdate(
    downloadPath: params.downloadPath,
    onUpdate: (int currentBytes, int totalBytes) {
      params.sendPortForCallback.send(DownloadLatestVersionCallbackParam(
        currentBytes: currentBytes,
        totalBytes: totalBytes,
      ));
    },
    onDone: () {
      params.sendPort.send({
        'status': 'SUCCESS',
        'result': '',
      });
    },
    onFailure: (dynamic e) {
      params.sendPort.send({
        'status': 'FAILED',
        'result': e.toString(),
      });
    },
  );
}

void Function(
  Store<AppState> store,
  DownloadLatestUpdatePackageAction action,
  NextDispatcher next,
) _downloadLatestVersion(VersionCheckLib versionLib) {
  return (store, action, next) async {
    try {
      store.dispatch(
        UpdateModalInfoAction(
          modalInfo: ModalInfo(
            modalType: ModalType.MODAL_DOWNLOADING_UPDATE,
            payload: {
              'currentBytes': 0,
              'totalBytes': 0,
            },
          ),
        ),
      );
      ReceivePort receivePort = ReceivePort();
      ReceivePort receivePortForCallback = ReceivePort();
      DownloadLatestVersionSpawnParams params = DownloadLatestVersionSpawnParams(
        sendPort: receivePort.sendPort,
        sendPortForCallback: receivePortForCallback.sendPort,
        downloadPath: (await versionLib.generateLocalPackagePath())!,
      );
      receivePortForCallback.listen((value) {
        final param = value as DownloadLatestVersionCallbackParam;

        store.dispatch(
          UpdateModalInfoAction(
            modalInfo: ModalInfo(
              modalType: ModalType.MODAL_DOWNLOADING_UPDATE,
              payload: {
                'currentBytes': param.currentBytes,
                'totalBytes': param.totalBytes,
              },
            ),
          ),
        );
      });
      await Isolate.spawn(
        _internalDownloadLatestVersion,
        params,
      );
      final result = await receivePort.first;
      if (result['status'] != 'SUCCESS') {
        throw result['error'];
      }
    } catch (e) {
      print(e);
      store.dispatch(UpdateModalInfoAction(
        modalInfo: ModalInfo(
          modalType: ModalType.MODAL_FAILED_TO_UPDATE,
        ),
      ));
    }
  };
}

void Function(
  Store<AppState> store,
  ExitAndOpenPackageAction action,
  NextDispatcher next,
) _exitAndOpenPackage(VersionCheckLib versionLib) {
  return (store, action, next) async {
    try {
      final localPath = await versionLib.generateLocalPackagePath();
      if (localPath != null) {
        Process.runSync('open', [localPath]);
      }
      exit(0);
    } catch (e) {
      print(e);
    }
  };
}
