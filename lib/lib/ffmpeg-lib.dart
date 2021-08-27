// Dart imports:
import 'dart:convert';
import 'dart:ffi';

// Package imports:
import 'package:ffi/ffi.dart';

// Project imports:
import 'package:spoon_cast_converter/repository/ffmpeg-response.dart';

final DynamicLibrary _ffmpegLib = DynamicLibrary.process();

abstract class FFmpegLib {
  Future<FFmpegGetFileInfoResponseRepository> getFileInfo({
    required String filePath,
  });
  Future<FFmpegConvertResponseRepository> convertFile({
    required String inputFilePath,
    required String outputFilePath,
    required ConvertingCallback callback,
  });
}

typedef ConvertingCallback = void Function(int, int);
typedef NativeConvertingCallback = Void Function(Int64, Int64);

class FFmpegLibImpl implements FFmpegLib {
  late Pointer<Utf8> Function(Pointer<Utf8> filePath) _getFileInfo;
  late Pointer<Utf8> Function(
    Pointer<Utf8> inputFilePath,
    Pointer<Utf8> outputFilePath,
    Pointer<NativeFunction<NativeConvertingCallback>> callback,
  ) _convertFile;

  static ConvertingCallback? _callback;

  static void convertingCallback(int current, int duration) {
    _callback?.call(current, duration);
  }

  FFmpegLibImpl() {
    _getFileInfo = _ffmpegLib
        .lookup<NativeFunction<Pointer<Utf8> Function(Pointer<Utf8>)>>("getFileInfo")
        .asFunction();
    _convertFile = _ffmpegLib
        .lookup<
            NativeFunction<
                Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>,
                    Pointer<NativeFunction<NativeConvertingCallback>>)>>("convertFile")
        .asFunction();
  }

  Future<FFmpegGetFileInfoResponseRepository> getFileInfo({required String filePath}) async {
    final description = _getFileInfo(filePath.toNativeUtf8()).toDartString();
    Map<String, dynamic> json = jsonDecode(description);
    final repository = FFmpegGetFileInfoRepository.fromJson(json);
    FFmpegGetFileInfoResponseRepository result;

    if (repository.status == 'SUCCESS') {
      result = repository.response!;
    } else {
      throw repository.error!;
    }

    return result;
  }

  Future<FFmpegConvertResponseRepository> convertFile({
    required String inputFilePath,
    required String outputFilePath,
    required ConvertingCallback callback,
  }) async {
    _callback = callback;
    Pointer<NativeFunction<NativeConvertingCallback>> nativeCallback =
        Pointer.fromFunction(convertingCallback);
    final description = _convertFile(
      inputFilePath.toNativeUtf8(),
      outputFilePath.toNativeUtf8(),
      nativeCallback,
    ).toDartString();
    _callback = null;
    Map<String, dynamic> json = jsonDecode(description);
    final repository = FFmpegConvertRepository.fromJson(json);
    FFmpegConvertResponseRepository result;

    if (repository.status == 'SUCCESS') {
      result = repository.response!;
    } else {
      throw repository.error!;
    }

    return result;
  }
}
