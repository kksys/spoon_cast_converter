// Dart imports:
import 'dart:convert';

// Flutter imports:
import 'package:flutter/services.dart';

enum ButtonType {
  closable,
  resizable,
  miniaturizable,
}

final buttonTypeString =
    ButtonType.values.map((e) => e.toString().replaceFirst('ButtonType.', '')).toList();

abstract class TitlebarButtonLib {
  enableWindowButton({
    required ButtonType buttonType,
    required bool enabled,
  });
}

class TitlebarButtonLibImpl implements TitlebarButtonLib {
  late final MethodChannel channel;

  TitlebarButtonLibImpl() {
    channel = const MethodChannel('net.kk_systems.spoonCastConverter.titlebar_button_lib');
  }

  @override
  enableWindowButton({
    required ButtonType buttonType,
    required bool enabled,
  }) {
    channel.invokeMethod(
      'enableWindowButton',
      jsonEncode(
        {
          'buttonType': buttonTypeString[buttonType.index],
          'enabled': enabled,
        },
      ),
    );
  }
}
