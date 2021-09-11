// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:macos_ui/macos_ui.dart';
import 'package:uuid/uuid.dart';

// Project imports:
import 'package:spoon_cast_converter/components/atom/app-table.dart';
import 'package:spoon_cast_converter/components/atom/app-text.dart';

class TestPage extends StatefulWidget {
  const TestPage({Key? key}) : super(key: key);

  _TestPageState createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  @override
  Widget build(BuildContext context) {
    final padding = EdgeInsets.all(16);

    return MacosScaffold(
      titleBar: TitleBar(
        height: kTitleBarHeight,
        centerTitle: true,
        title: const Text('Test'),
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
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final Size size = mediaQuery.size;
    final double panelHeight = size.height - padding;

    return Container(
      width: size.width - padding,
      height: panelHeight,
      child: AppTable(
        columns: [
          const AppTableColumn(
            width: 80.0,
            child: AppText(
              'aaa',
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const AppTableColumn(
            width: 100.0,
            child: AppText(
              'bbb',
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const AppTableColumn(
            width: 100.0,
            child: AppText(
              'ccc',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
        rows: [
          ...List.generate(56, (index) {
            final Uuid uuid = Uuid();
            return AppTableRow(
              children: [
                AppTableCell(
                  child: AppText(
                    'testA$index - ${uuid.v4()}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                AppTableCell(
                  child: AppText(
                    'testB$index - ${uuid.v4()}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                AppTableCell(
                  child: AppText(
                    'testC$index - ${uuid.v4()}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}
