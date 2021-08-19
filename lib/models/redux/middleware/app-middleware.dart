// Package imports:
import 'package:redux/redux.dart';

// Project imports:
import 'package:spoon_cast_converter/models/redux/app-state.dart';
import 'package:spoon_cast_converter/models/redux/middleware/ffmpeg-middleware.dart';
import 'package:spoon_cast_converter/models/redux/middleware/version-middleware.dart';

List<Middleware<AppState>> rootMiddleware() {
  return [
    ...ffmpegMiddleware,
    ...versionMiddleware,
  ];
}
