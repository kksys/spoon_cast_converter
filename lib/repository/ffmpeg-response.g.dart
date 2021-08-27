// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ffmpeg-response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FFmpegGetFileInfoDurationRepository
    _$FFmpegGetFileInfoDurationRepositoryFromJson(Map<String, dynamic> json) {
  return $checkedNew('FFmpegGetFileInfoDurationRepository', json, () {
    final val = FFmpegGetFileInfoDurationRepository(
      seconds: $checkedConvert(json, 'seconds', (v) => v as int),
      milliseconds: $checkedConvert(json, 'milliseconds', (v) => v as int),
    );
    return val;
  });
}

Map<String, dynamic> _$FFmpegGetFileInfoDurationRepositoryToJson(
        FFmpegGetFileInfoDurationRepository instance) =>
    <String, dynamic>{
      'seconds': instance.seconds,
      'milliseconds': instance.milliseconds,
    };

FFmpegGetFileInfoResponseRepository
    _$FFmpegGetFileInfoResponseRepositoryFromJson(Map<String, dynamic> json) {
  return $checkedNew('FFmpegGetFileInfoResponseRepository', json, () {
    final val = FFmpegGetFileInfoResponseRepository(
      codec: $checkedConvert(json, 'codec', (v) => v as String),
      profile: $checkedConvert(json, 'profile', (v) => v as String?),
      sampleRates: $checkedConvert(json, 'sample_rates', (v) => v as int),
      bitRates: $checkedConvert(json, 'bit_rates', (v) => v as int),
      channels: $checkedConvert(json, 'channels', (v) => v as int),
      duration: $checkedConvert(
          json,
          'duration',
          (v) => FFmpegGetFileInfoDurationRepository.fromJson(
              v as Map<String, dynamic>)),
    );
    return val;
  }, fieldKeyMap: const {
    'sampleRates': 'sample_rates',
    'bitRates': 'bit_rates'
  });
}

Map<String, dynamic> _$FFmpegGetFileInfoResponseRepositoryToJson(
        FFmpegGetFileInfoResponseRepository instance) =>
    <String, dynamic>{
      'codec': instance.codec,
      'profile': instance.profile,
      'sample_rates': instance.sampleRates,
      'bit_rates': instance.bitRates,
      'channels': instance.channels,
      'duration': instance.duration.toJson(),
    };

FFmpegGetFileInfoRepository _$FFmpegGetFileInfoRepositoryFromJson(
    Map<String, dynamic> json) {
  return $checkedNew('FFmpegGetFileInfoRepository', json, () {
    final val = FFmpegGetFileInfoRepository(
      status: $checkedConvert(json, 'status', (v) => v as String),
      response: $checkedConvert(
          json,
          'response',
          (v) => v == null
              ? null
              : FFmpegGetFileInfoResponseRepository.fromJson(
                  v as Map<String, dynamic>)),
      error: $checkedConvert(json, 'error', (v) => v as String?),
    );
    return val;
  });
}

Map<String, dynamic> _$FFmpegGetFileInfoRepositoryToJson(
        FFmpegGetFileInfoRepository instance) =>
    <String, dynamic>{
      'status': instance.status,
      'response': instance.response?.toJson(),
      'error': instance.error,
    };

FFmpegConvertResponseRepository _$FFmpegConvertResponseRepositoryFromJson(
    Map<String, dynamic> json) {
  return $checkedNew('FFmpegConvertResponseRepository', json, () {
    final val = FFmpegConvertResponseRepository();
    return val;
  });
}

Map<String, dynamic> _$FFmpegConvertResponseRepositoryToJson(
        FFmpegConvertResponseRepository instance) =>
    <String, dynamic>{};

FFmpegConvertRepository _$FFmpegConvertRepositoryFromJson(
    Map<String, dynamic> json) {
  return $checkedNew('FFmpegConvertRepository', json, () {
    final val = FFmpegConvertRepository(
      status: $checkedConvert(json, 'status', (v) => v as String),
      response: $checkedConvert(
          json,
          'response',
          (v) => v == null
              ? null
              : FFmpegConvertResponseRepository.fromJson(
                  v as Map<String, dynamic>)),
      error: $checkedConvert(json, 'error', (v) => v as String?),
    );
    return val;
  });
}

Map<String, dynamic> _$FFmpegConvertRepositoryToJson(
        FFmpegConvertRepository instance) =>
    <String, dynamic>{
      'status': instance.status,
      'response': instance.response?.toJson(),
      'error': instance.error,
    };
