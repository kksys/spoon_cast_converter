// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:macos_ui/macos_ui.dart';

class AppText extends StatelessWidget {
  final String? data;
  final TextOverflow? overflow;
  final TextAlign? textAlign;
  final double textScale;

  const AppText(
    String this.data, {
    Key? key,
    this.overflow,
    this.textAlign,
    this.textScale = 1,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    MacosThemeData themeData = MacosTheme.of(context);
    return Text(
      data ?? '',
      overflow: this.overflow,
      textAlign: textAlign,
      style: TextStyle(
        fontSize: themeData.typography.headline.fontSize != null
            ? themeData.typography.headline.fontSize! * this.textScale
            : null,
      ),
      strutStyle: StrutStyle(
        fontSize: themeData.typography.headline.fontSize != null
            ? themeData.typography.headline.fontSize! * this.textScale
            : null,
        height: 1,
        leading: 0.5,
      ),
    );
  }
}
