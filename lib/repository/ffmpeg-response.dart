// Package imports:
import 'package:json_annotation/json_annotation.dart';

part 'ffmpeg-response.g.dart';

@JsonSerializable(explicitToJson: true)
class FFmpegGetFileInfoDurationRepository {
  const FFmpegGetFileInfoDurationRepository({
    required this.seconds,
    required this.milliseconds,
  });

  final int seconds;
  final int milliseconds;

  factory FFmpegGetFileInfoDurationRepository.fromJson(Map<String, dynamic> json) =>
      _$FFmpegGetFileInfoDurationRepositoryFromJson(json);
  Map<String, dynamic> toJson() => _$FFmpegGetFileInfoDurationRepositoryToJson(this);
}

@JsonSerializable(explicitToJson: true)
class FFmpegGetFileInfoResponseRepository {
  const FFmpegGetFileInfoResponseRepository({
    required this.codec,
    this.profile,
    required this.sampleRates,
    required this.bitRates,
    required this.channels,
    required this.duration,
  });

  final String codec;
  final String? profile;
  final int sampleRates;
  final int bitRates;
  final int channels;
  final FFmpegGetFileInfoDurationRepository duration;

  factory FFmpegGetFileInfoResponseRepository.fromJson(Map<String, dynamic> json) =>
      _$FFmpegGetFileInfoResponseRepositoryFromJson(json);
  Map<String, dynamic> toJson() => _$FFmpegGetFileInfoResponseRepositoryToJson(this);
}

@JsonSerializable(explicitToJson: true)
class FFmpegGetFileInfoRepository {
  const FFmpegGetFileInfoRepository({
    required this.status,
    this.response,
    this.error,
  });

  final String status;
  final FFmpegGetFileInfoResponseRepository? response;
  final String? error;

  factory FFmpegGetFileInfoRepository.fromJson(Map<String, dynamic> json) =>
      _$FFmpegGetFileInfoRepositoryFromJson(json);
  Map<String, dynamic> toJson() => _$FFmpegGetFileInfoRepositoryToJson(this);
}

@JsonSerializable(explicitToJson: true)
class FFmpegConvertResponseRepository {
  const FFmpegConvertResponseRepository();

  factory FFmpegConvertResponseRepository.fromJson(Map<String, dynamic> json) =>
      _$FFmpegConvertResponseRepositoryFromJson(json);
  Map<String, dynamic> toJson() => _$FFmpegConvertResponseRepositoryToJson(this);
}

@JsonSerializable(explicitToJson: true)
class FFmpegConvertRepository {
  const FFmpegConvertRepository({
    required this.status,
    this.response,
    this.error,
  });

  final String status;
  final FFmpegConvertResponseRepository? response;
  final String? error;

  factory FFmpegConvertRepository.fromJson(Map<String, dynamic> json) =>
      _$FFmpegConvertRepositoryFromJson(json);
  Map<String, dynamic> toJson() => _$FFmpegConvertRepositoryToJson(this);
}
