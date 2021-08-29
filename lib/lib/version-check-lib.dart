// Dart imports:
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

// Package imports:
import 'package:http/http.dart' as http;
import 'package:package_info/package_info.dart';
import 'package:path_provider/path_provider.dart';

// Project imports:
import 'package:spoon_cast_converter/conf.dart';

abstract class VersionCheckLib {
  Future<String> getCurrentVersion();
  Future<void> fetchLatestVersionInfo();
  Future<String?> getAvailableUpdate();
  Future<String?> generateLocalPackagePath();
  Future<void> downloadUpdate({
    required String downloadPath,
    required Function(int, int) onUpdate,
    required Function() onDone,
    required Function(dynamic) onFailure,
  });
}

class Version {
  final String _rawVersion;
  late final int _major;
  late final int _minor;
  late final int _patch;
  late final String _prerelease;
  late final String _buildmetadata;

  Version(this._rawVersion) {
    final matcher = RegExp(
      r"^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$",
      multiLine: true,
    ).allMatches(this._rawVersion).single;

    this._major = matcher.group(1) != null ? int.parse(matcher.group(1)!) : -1;
    this._minor = matcher.group(2) != null ? int.parse(matcher.group(2)!) : -1;
    this._patch = matcher.group(3) != null ? int.parse(matcher.group(3)!) : -1;
    this._prerelease = matcher.group(4) ?? '';
    this._buildmetadata = matcher.group(5) ?? '';
  }

  bool operator <(Version rhs) {
    bool result = false;

    if (this._major != rhs._major) {
      result = this._major < rhs._major;
    } else if (this._minor != rhs._minor) {
      result = this._minor < rhs._minor;
    } else if (this._patch != rhs._patch) {
      result = this._patch < rhs._patch;
    } else if (this._prerelease != rhs._prerelease) {
      result = this._prerelease.compareTo(rhs._prerelease) < 0;
    } else {
      result = this._buildmetadata.compareTo(rhs._buildmetadata) < 0;
    }

    return result;
  }

  bool operator >(Version rhs) {
    bool result = false;

    if (this._major != rhs._major) {
      result = this._major > rhs._major;
    } else if (this._minor != rhs._minor) {
      result = this._minor > rhs._minor;
    } else if (this._patch != rhs._patch) {
      result = this._patch > rhs._patch;
    } else if (this._prerelease != rhs._prerelease) {
      result = this._prerelease.compareTo(rhs._prerelease) > 0;
    } else {
      result = this._buildmetadata.compareTo(rhs._buildmetadata) > 0;
    }

    return result;
  }

  @override
  String toString() {
    return this._rawVersion;
  }
}

class VersionCheckLibImpl implements VersionCheckLib {
  Map<String, dynamic> fetchedLatestInfo = {};

  VersionCheckLibImpl();

  Future<String> getCurrentVersion() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();

    return packageInfo.version;
  }

  Future<void> fetchLatestVersionInfo() async {
    try {
      final Map<String, dynamic> result;
      if (USE_DUMMY_AVAILABLE_VERSION_RESPONSE) {
        result = {
          'name': '1.0.1',
          'assets': [
            {
              'name': 'SpoonCASTConverter_1.0.1_darwin.dmg',
              'browser_download_url': 'http://ipv4.download.thinkbroadband.com/100MB.zip',
            },
          ],
        };
      } else {
        final response = await http.get(
          Uri.parse(LATEST_VERSION_API_URI),
        );
        result = JsonDecoder().convert(response.body);
      }
      this.fetchedLatestInfo = result;
    } catch (error) {
      this.fetchedLatestInfo = {};
      throw error;
    }
  }

  Future<String?> getAvailableUpdate() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();

    if (this.fetchedLatestInfo.isEmpty) {
      return null;
    }

    return Version(this.fetchedLatestInfo['name']) > Version(packageInfo.version)
        ? this.fetchedLatestInfo['name']
        : null;
  }

  Future<String?> generateLocalPackagePath() async {
    if (this.fetchedLatestInfo.isEmpty) {
      return null;
    }

    final assets = (this.fetchedLatestInfo['assets'] as List<dynamic>).cast<Map<String, dynamic>>();
    final asset = assets.firstWhere((element) => RegExp(r'darwin.dmg$').hasMatch(element['name']));
    final packageName = asset['name'];

    final downloadDir = await getDownloadsDirectory();

    return '${downloadDir?.path}/$packageName';
  }

  Future<void> downloadUpdate({
    required String downloadPath,
    required Function(int, int) onUpdate,
    required Function() onDone,
    required Function(dynamic) onFailure,
  }) async {
    if (this.fetchedLatestInfo.isEmpty) {
      return;
    }

    final assets = (this.fetchedLatestInfo['assets'] as List<dynamic>).cast<Map<String, dynamic>>();
    final asset = assets.firstWhere((element) => RegExp(r'darwin.dmg$').hasMatch(element['name']));
    final packageUri = asset['browser_download_url'];

    final client = http.Client();
    final request = new http.Request('GET', Uri.parse(packageUri));
    final response = client.send(request);

    List<List<int>> chunks = [];
    int downloaded = 0;

    response.asStream().listen((http.StreamedResponse r) {
      r.stream.listen(
        (List<int> chunk) {
          // Display percentage of completion
          print('downloadPercentage: ${downloaded / r.contentLength! * 100}');

          chunks.add(chunk);
          downloaded += chunk.length;

          onUpdate(downloaded, r.contentLength!);
        },
        onDone: () async {
          // Display percentage of completion
          print('downloadPercentage: ${downloaded / r.contentLength! * 100}');

          // Save the file
          File file = new File(downloadPath);
          final Uint8List bytes = Uint8List(r.contentLength!);
          int offset = 0;
          for (List<int> chunk in chunks) {
            bytes.setRange(offset, offset + chunk.length, chunk);
            offset += chunk.length;
          }
          await file.writeAsBytes(bytes);

          onDone();
        },
        onError: (e) async {
          onFailure(e);
        },
      );
    });
  }
}
