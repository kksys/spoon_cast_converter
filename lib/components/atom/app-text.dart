// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:macos_ui/macos_ui.dart';

class AppText extends StatelessWidget {
  final String? data;
  final TextOverflow? overflow;

  const AppText(
    String this.data, {
    Key? key,
    this.overflow,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    MacosThemeData themeData = MacosTheme.of(context);
    return Text(
      data ?? '',
      overflow: this.overflow,
      style: TextStyle(
        fontSize: themeData.typography.headline.fontSize,
      ),
      strutStyle: StrutStyle(
        fontSize: themeData.typography.headline.fontSize,
        height: 1,
        leading: 0.5,
      ),
    );
  }
}
