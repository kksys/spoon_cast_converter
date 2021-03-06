// Dart imports:
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

// Package imports:
import 'package:path/path.dart';
import 'package:redux/redux.dart';

// Project imports:
import 'package:spoon_cast_converter/lib/ffmpeg-lib.dart';
import 'package:spoon_cast_converter/models/redux/action/app-actions.dart';
import 'package:spoon_cast_converter/models/redux/app-state.dart';

final FFmpegLib ffmpegLib = FFmpegLibImpl();

final List<Middleware<AppState>> ffmpegMiddleware = [
  TypedMiddleware<AppState, GetFileInfoAction>(_getFileInfo(ffmpegLib)),
  TypedMiddleware<AppState, CheckAndAddInputFilePathListAction>(
      _checkAndAddInputFileListPath(ffmpegLib)),
  TypedMiddleware<AppState, ConvertFileAction>(_convertFile(ffmpegLib)),
  TypedMiddleware<AppState, StartConvertSequenceAction>(_startConvertSequence()),
  TypedMiddleware<AppState, ContinueNextConvertSequenceAction>(_continueNextConvertSequence()),
  TypedMiddleware<AppState, RequestConvertAction>(_requestConvert()),
];

void Function(
  Store<AppState> store,
  GetFileInfoAction action,
  NextDispatcher next,
) _getFileInfo(FFmpegLib ffmpegLib) {
  return (store, action, next) async {
    try {
      final description = await ffmpegLib.getFileInfo(filePath: action.filePath);
      store.dispatch(UpdateFileInfoAction(
        fileInfo: AudioFileInfo(
          codec: description.codec,
          profile: description.profile,
          sampleRates: description.sampleRates,
          bitRates: description.bitRates,
          channels: description.channels,
          duration: AudioFileDuration(
            seconds: description.duration.seconds,
            milliseconds: description.duration.milliseconds,
          ),
        ),
      ));
    } catch (e) {
      print(e);
      store.dispatch(UpdateFileInfoAction(
        fileInfo: null,
      ));
    }
  };
}

void Function(
  Store<AppState> store,
  CheckAndAddInputFilePathListAction action,
  NextDispatcher next,
) _checkAndAddInputFileListPath(FFmpegLib ffmpegLib) {
  return (store, action, next) async {
    try {
      await ffmpegLib.getFileInfo(filePath: action.convertItem.inputFilePath);
      store.dispatch(AddConvertItemAction(
        convertItem: action.convertItem,
      ));
    } catch (e) {
      store.dispatch(UpdateModalInfoAction(
        modalInfo: const ModalInfo(modalType: ModalType.MODAL_UNSUPPORTED_FILETYPE),
      ));
    }
  };
}

class ConvertFileSpawnParams {
  SendPort sendPort;
  SendPort sendPortForCallback;
  String inputFilePath;
  String outputFilePath;

  ConvertFileSpawnParams({
    required this.sendPort,
    required this.sendPortForCallback,
    required this.inputFilePath,
    required this.outputFilePath,
  });
}

class ConvertFileCallbackParam {
  int current;
  int duration;

  ConvertFileCallbackParam({
    required this.current,
    required this.duration,
  });
}

void _internalConvertFile(ConvertFileSpawnParams params) async {
  FFmpegLib ffmpegLib = FFmpegLibImpl();
  Map result;
  try {
    final response = await ffmpegLib.convertFile(
      inputFilePath: params.inputFilePath,
      outputFilePath: params.outputFilePath,
      callback: (int current, int duration) {
        params.sendPortForCallback.send(ConvertFileCallbackParam(
          current: current,
          duration: duration,
        ));
      },
    );
    result = {
      'status': 'SUCCESS',
      'result': jsonEncode(response.toJson()),
    };
  } catch (e) {
    result = {
      'status': 'FAILED',
      'error': e,
    };
  }
  params.sendPort.send(result);
}

void Function(
  Store<AppState> store,
  ConvertFileAction action,
  NextDispatcher next,
) _convertFile(FFmpegLib ffmpegLib) {
  return (store, action, next) async {
    try {
      print('_convertFile');

      _updateConvertingState(store);

      ReceivePort receivePort = ReceivePort();
      ReceivePort receivePortForCallback = ReceivePort();
      ConvertFileSpawnParams params = ConvertFileSpawnParams(
        sendPort: receivePort.sendPort,
        sendPortForCallback: receivePortForCallback.sendPort,
        inputFilePath: action.inputFilePath,
        outputFilePath: action.outputFilePath,
      );
      receivePortForCallback.listen((value) {
        final param = value as ConvertFileCallbackParam;

        store.dispatch(
          UpdateConvertingStatusAction(
            convertingStatus: Rational(
              current: param.current,
              duration: param.duration,
            ),
          ),
        );
      });
      await Isolate.spawn(
        _internalConvertFile,
        params,
      );
      final result = await receivePort.first;
      if (result['status'] != 'SUCCESS') {
        throw result['error'];
      }

      _updateSuccessState(store);
    } catch (e) {
      print(e);

      _updateErrorState(store);
    }

    store.dispatch(ContinueNextConvertSequenceAction());
  };
}

void Function(
  Store<AppState> store,
  StartConvertSequenceAction action,
  NextDispatcher next,
) _startConvertSequence() {
  return (store, action, next) async {
    print('_startConvertSequence');
    _updateAllWaitingState(store);
    store.dispatch(ContinueNextConvertSequenceAction());
  };
}

void Function(
  Store<AppState> store,
  ContinueNextConvertSequenceAction action,
  NextDispatcher next,
) _continueNextConvertSequence() {
  return (store, action, next) async {
    print('_continueNextConvertSequence');
    int nextConvertIndex = store.state.convertingIndex + 1;
    nextConvertIndex =
        nextConvertIndex < store.state.convertFileList.length ? nextConvertIndex : -1;

    store.dispatch(
      UpdateConvertingStatusAction(convertingStatus: Rational()),
    );
    store.dispatch(UpdateConvertingIndexAction(convertingIndex: nextConvertIndex));

    print('nextConvertIndex: $nextConvertIndex');

    if (nextConvertIndex < 0) {
      store.dispatch(UpdateModalInfoAction(
        modalInfo: const ModalInfo(modalType: ModalType.MODAL_FINISH_CONVERT_SEQUENCE),
      ));
      return;
    }

    store.dispatch(RequestConvertAction());
  };
}

void Function(
  Store<AppState> store,
  RequestConvertAction action,
  NextDispatcher next,
) _requestConvert() {
  return (store, action, next) async {
    print('_requestConvert');

    final int nextConvertIndex = store.state.convertingIndex;
    final String inputFilePath = store.state.convertFileList[nextConvertIndex].inputFilePath;
    final inputExt = extension(inputFilePath);
    final String outputFilePath = store.state.convertFileList[nextConvertIndex].outputFilePath ??
        inputFilePath.replaceFirst(RegExp('$inputExt\$'), '.m4a');

    print('inputFilePath: $inputFilePath');
    print('outputFilePath: $outputFilePath');

    if (!action.forceConvert && File(outputFilePath).existsSync()) {
      store.dispatch(UpdateModalInfoAction(
        modalInfo: const ModalInfo(modalType: ModalType.MODAL_ALREADY_EXIST_DESTINATION),
      ));
    } else {
      store.dispatch(ConvertFileAction(
        inputFilePath: inputFilePath,
        outputFilePath: outputFilePath,
      ));
    }
  };
}

void _updateAllWaitingState(Store<AppState> store) {
  final convertItemList = store.state.convertFileList
      .map(
        (element) => ConvertItem.fromMap({
          ...element.toMap(),
          'state': ConvertState.WAITING,
        }),
      )
      .toList();
  convertItemList.forEach((element) {
    store.dispatch(UpdateConvertItemAction(
      convertItem: element,
    ));
  });
}

void _updateConvertingState(Store<AppState> store) {
  final previousItem = store.state.convertFileList[store.state.convertingIndex];
  final newItem = ConvertItem.fromMap({
    ...previousItem.toMap(),
    'state': ConvertState.CONVERTING,
  });
  store.dispatch(UpdateConvertItemAction(
    convertItem: newItem,
  ));
}

void _updateSuccessState(Store<AppState> store) {
  final previousItem = store.state.convertFileList[store.state.convertingIndex];
  final newItem = ConvertItem.fromMap({
    ...previousItem.toMap(),
    'state': ConvertState.SUCCESS,
  });
  store.dispatch(UpdateConvertItemAction(
    convertItem: newItem,
  ));
}

void _updateErrorState(Store<AppState> store) {
  final previousItem = store.state.convertFileList[store.state.convertingIndex];
  final newItem = ConvertItem.fromMap({
    ...previousItem.toMap(),
    'state': ConvertState.ERROR,
  });
  store.dispatch(UpdateConvertItemAction(
    convertItem: newItem,
  ));
}
