// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_redux/flutter_redux.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:redux/redux.dart';

// Project imports:
import 'package:spoon_cast_converter/components/organisms/bottom-panel.dart';
import 'package:spoon_cast_converter/components/organisms/top-panel.dart';
import 'package:spoon_cast_converter/conf.dart';
import 'package:spoon_cast_converter/models/redux/action/app-actions.dart';
import 'package:spoon_cast_converter/models/redux/app-state.dart';

class HomePage extends StatefulWidget {
  HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    final padding = EdgeInsets.all(16);

    return MacosScaffold(
      titleBar: TitleBar(
        height: kTitleBarHeight,
        centerTitle: true,
        title: const Text('Spoon CAST Converter'),
      ),
      children: [
        ContentArea(
          builder: (BuildContext context, ScrollController scrollController) {
            final MediaQueryData mediaQuery = MediaQuery.of(context);
            final systemBarHeight = mediaQuery.padding.top + mediaQuery.padding.bottom;
            final Size size = mediaQuery.size;
            final double height = size.height - systemBarHeight - (padding.top + padding.bottom);

            return MediaQuery(
              data: mediaQuery.copyWith(
                size: Size(size.width, height),
                padding: padding,
                viewPadding: padding,
              ),
              child: Container(
                padding: padding,
                child: contentView(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget contentView() {
    final padding = 6.0;

    return new StoreConnector<AppState, _ViewModel>(
      converter: _ViewModel.fromStore,
      onInitialBuild: (_ViewModel viewModel) {
        if (SHOULD_CHECK_UPDATE_AT_LAUNCH) {
          viewModel.checkAvailableUpdateAtLaunch();
        }
      },
      builder: (context, viewModel) {
        final MediaQueryData mediaQuery = MediaQuery.of(context);
        final Size size = mediaQuery.size;
        final double panelHeight = (size.height - padding) / 2;

        return Stack(
          children: [
            Container(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    height: panelHeight,
                    child: TopPanel(),
                  ),
                  Container(height: padding),
                  Container(
                    height: panelHeight,
                    child: BottomPanel(),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ViewModel {
  final List<String> inputFileNameList;
  final int selectedIndex;
  final AudioFileInfo? fileInfo;
  final int convertingIndex;
  final Rational convertingStatus;
  final Function() checkAvailableUpdateAtLaunch;

  _ViewModel({
    required this.inputFileNameList,
    required this.selectedIndex,
    required this.fileInfo,
    required this.convertingIndex,
    required this.convertingStatus,
    required this.checkAvailableUpdateAtLaunch,
  });

  static _ViewModel fromStore(Store<AppState> store) {
    return new _ViewModel(
      inputFileNameList: store.state.inputFilePathList,
      selectedIndex: store.state.selectedIndex,
      fileInfo: store.state.fileInfo,
      convertingIndex: store.state.convertingIndex,
      convertingStatus: store.state.convertingStatus,
      checkAvailableUpdateAtLaunch: () {
        store.dispatch(CheckExistAvailableUpdateAction(launchTime: true));
      },
    );
  }
}
