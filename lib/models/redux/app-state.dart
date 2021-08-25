// Flutter imports:
import 'package:flutter/foundation.dart';

class AudioFileDuration {
  final int seconds;
  final int milliseconds;

  const AudioFileDuration({
    required this.seconds,
    required this.milliseconds,
  });

  String toTimeString() {
    final int hours = (this.seconds / 3600).floor();
    final int minutes = (this.seconds / 60).floor() % 60;
    final int seconds = this.seconds % 60;

    final String strHours = '$hours'.padLeft(2, '0');
    final String strMinutes = '$minutes'.padLeft(2, '0');
    final String strSeconds = '$seconds'.padLeft(2, '0');
    final String strMilliseconds = '${this.milliseconds}'.padLeft(3, '0');

    return '$strHours:$strMinutes:$strSeconds $strMilliseconds';
  }

  Map toMap() {
    return {
      'seconds': this.seconds,
      'milliseconds': this.milliseconds,
    };
  }

  static AudioFileDuration fromMap(Map obj) {
    return AudioFileDuration(
      seconds: obj['seconds'],
      milliseconds: obj['milliseconds'],
    );
  }
}

class Rational {
  final int current;
  final int duration;

  const Rational({
    this.current = 0,
    this.duration = 0,
  });

  Map toMap() {
    return {
      'current': this.current,
      'duration': this.duration,
    };
  }

  static Rational fromMap(Map obj) {
    return Rational(
      current: obj['current'],
      duration: obj['duration'],
    );
  }
}

class AudioFileInfo {
  final String codec;
  final String? profile;
  final int sampleRates;
  final int bitRates;
  final int channels;
  final AudioFileDuration duration;

  const AudioFileInfo({
    required this.codec,
    required this.profile,
    required this.sampleRates,
    required this.bitRates,
    required this.channels,
    required this.duration,
  });

  Map toMap() {
    return {
      'codec': this.codec,
      'profile': this.profile,
      'sampleRates': this.sampleRates,
      'bitRates': this.bitRates,
      'channels': this.channels,
      'duration': this.duration.toMap(),
    };
  }

  static AudioFileInfo fromMap(Map obj) {
    return AudioFileInfo(
      codec: obj['codec'],
      profile: obj['profile'],
      sampleRates: obj['sampleRates'],
      bitRates: obj['bitRates'],
      channels: obj['channels'],
      duration: AudioFileDuration.fromMap(obj['duration']),
    );
  }
}

enum ModalType {
  MODAL_HIDDEN,
  MODAL_FILE_CONFLICT,
  MODAL_FINISH_CONVERT_SEQUENCE,
  MODAL_UNSUPPORTED_FILETYPE,
  MODAL_AVAILABLE_UPDATE,
  MODAL_DOWNLOADING_UPDATE,
  MODAL_FAILED_TO_UPDATE,
  MODAL_LICENSE,
}

class ModalInfo {
  final ModalType modalType;
  final Map<String, dynamic> payload;

  const ModalInfo({
    required this.modalType,
    this.payload = const {},
  });

  Map toMap() {
    return {
      'modalType': this.modalType,
      'payload': this.payload,
    };
  }

  static ModalInfo fromMap(Map obj) {
    return ModalInfo(
      modalType: obj['modalType'],
      payload: obj['payload'],
    );
  }
}

@immutable
class AppState {
  final List<String> inputFilePathList;
  final int selectedIndex;
  final AudioFileInfo? fileInfo;
  final int convertingIndex;
  final Rational convertingStatus;
  final ModalInfo modalInfo;

  const AppState({
    this.inputFilePathList = const [],
    this.selectedIndex = -1,
    this.fileInfo,
    this.convertingIndex = -1,
    this.convertingStatus = const Rational(),
    this.modalInfo = const ModalInfo(modalType: ModalType.MODAL_HIDDEN),
  });

  Map toMap() {
    return {
      'inputFilePathList': this.inputFilePathList,
      'selectedIndex': this.selectedIndex,
      'fileInfo': this.fileInfo?.toMap(),
      'convertingIndex': this.convertingIndex,
      'convertingStatus': this.convertingStatus.toMap(),
      'modalInfo': this.modalInfo.toMap(),
    };
  }

  static AppState fromMap(Map obj) {
    return AppState(
      inputFilePathList: obj['inputFilePathList'],
      selectedIndex: obj['selectedIndex'],
      fileInfo: obj['fileInfo'] != null ? AudioFileInfo.fromMap(obj['fileInfo']) : null,
      convertingIndex: obj['convertingIndex'],
      convertingStatus: Rational.fromMap(obj['convertingStatus']),
      modalInfo: ModalInfo.fromMap(obj['modalInfo']),
    );
  }
}
