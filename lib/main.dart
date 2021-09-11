// Dart imports:
import 'dart:io';

// Flutter imports:
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:redux/redux.dart';
import 'package:window_size/window_size.dart';

// Project imports:
import 'package:spoon_cast_converter/components/pages/home-page.dart';
import 'package:spoon_cast_converter/components/pages/test-page.dart';
import 'package:spoon_cast_converter/conf.dart';
import 'package:spoon_cast_converter/models/redux/action/app-actions.dart';
import 'package:spoon_cast_converter/models/redux/app-state.dart';
import 'package:spoon_cast_converter/models/redux/middleware/app-middleware.dart';
import 'package:spoon_cast_converter/models/redux/reducer/app-reducer.dart';

void showCheckForUpdatesDialog({
  required Store<AppState> store,
}) {
  store.dispatch(CheckExistAvailableUpdateAction(launchTime: false));
}

void showLicenseDialog({
  required Store<AppState> store,
}) {
  store.dispatch(UpdateModalInfoAction(
    modalInfo: ModalInfo(modalType: ModalType.MODAL_LICENSE),
  ));
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    setWindowMinSize(const Size(700, 500));
    setWindowMaxSize(Size.infinite);
  }
  final store = new Store<AppState>(
    appReducer,
    middleware: rootMiddleware(),
    initialState: const AppState(),
  );

  runApp(MyApp(store: store));
}

class MyApp extends StatefulWidget {
  final Store<AppState> store;

  MyApp({
    Key? key,
    required this.store,
  }) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const menuChannel = const MethodChannel('net.kk_systems.spoonCastConverter.menu');

  @override
  void initState() {
    super.initState();
    menuChannel.setMethodCallHandler(myUtilsHandler);
  }

  Future<dynamic> myUtilsHandler(MethodCall methodCall) async {
    switch (methodCall.method) {
      case 'showCheckForUpdatesDialog':
        showCheckForUpdatesDialog(store: this.widget.store);
        break;
      case 'showLicenseDialog':
        showLicenseDialog(store: this.widget.store);
        break;
      default:
        break;
    }
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new StoreProvider(
      store: this.widget.store,
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
                builder: (context) => UI_TEST_MODE ? TestPage() : HomePage(),
              ),
            ),
          );
        },
      ),
    );
  }
}
