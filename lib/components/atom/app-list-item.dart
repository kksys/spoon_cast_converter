// Flutter imports:
import 'package:flutter/widgets.dart';

// Package imports:
import 'package:macos_ui/macos_ui.dart';

class AppListItem extends StatefulWidget {
  final Function() onTap;
  final bool selected;
  final Widget Function() build;

  AppListItem({
    Key? key,
    required this.onTap,
    required this.selected,
    required this.build,
  }) : super(key: key);

  @override
  _AppListItemState createState() => _AppListItemState();
}

class _AppListItemState extends State<AppListItem> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      child: GestureDetector(
        onTap: this.widget.onTap,
        child: Container(
          color: this.widget.selected ? MacosColors.systemBlueColor : MacosColors.transparent,
          width: double.infinity,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(2),
            child: this.widget.build(),
          ),
        ),
      ),
    );
  }
}
