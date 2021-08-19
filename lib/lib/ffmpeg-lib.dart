// Dart imports:
import 'dart:convert';
import 'dart:ffi';

// Package imports:
import 'package:ffi/ffi.dart';

final DynamicLibrary _ffmpegLib = DynamicLibrary.process();

abstract class FFmpegLib {
  Future<Map<String, dynamic>> getFileInfo({
    required String filePath,
  });
  Future<Map<String, dynamic>> convertFile({
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

  Future<Map<String, dynamic>> getFileInfo({required String filePath}) async {
    final description = _getFileInfo(filePath.toNativeUtf8()).toDartString();
    Map<String, dynamic> json = jsonDecode(description);
    var result = Map<String, dynamic>();

    if (json['status'] == 'SUCCESS') {
      result = json['response'];
    } else {
      throw json['error'];
    }

    return result;
  }

  Future<Map<String, dynamic>> convertFile({
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
    var result = Map<String, dynamic>();

    if (json['status'] == 'SUCCESS') {
      result = json['response'];
    } else {
      throw json['error'];
    }

    return result;
  }
}
