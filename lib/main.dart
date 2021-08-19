// Dart imports:
import 'dart:io';

// Flutter imports:
import 'package:flutter/cupertino.dart';

// Package imports:
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:redux/redux.dart';
import 'package:window_size/window_size.dart';

// Project imports:
import 'package:spoon_cast_converter/components/pages/home-page.dart';
import 'package:spoon_cast_converter/models/redux/app-state.dart';
import 'package:spoon_cast_converter/models/redux/middleware/app-middleware.dart';
import 'package:spoon_cast_converter/models/redux/reducer/app-reducer.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    setWindowMinSize(const Size(700, 500));
    setWindowMaxSize(Size.infinite);
  }
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final store = new Store<AppState>(
    appReducer,
    middleware: rootMiddleware(),
    initialState: const AppState(),
  );

  @override
  void initState() {
    super.initState();
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new StoreProvider(
      store: store,
      child: MacosApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        title: 'Spoon CAST Converter',
        theme: MacosThemeData.light(),
        darkTheme: MacosThemeData.dark(),
        debugShowCheckedModeBanner: false,
        builder: (context, child) {
          return StoreConnector<AppState, bool>(
            distinct: true,
            converter: (store) => true,
            builder: (context, _) => Navigator(
              onGenerateRoute: (settings) => CupertinoPageRoute(
                builder: (context) => HomePage(),
              ),
            ),
          );
        },
      ),
    );
  }
}
