// Flutter imports:
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';

// Package imports:
import 'package:macos_ui/macos_ui.dart';

/// A [AppProgressBar] that shows progress in a horizontal bar.
class AppProgressBar extends StatelessWidget {
  /// Creates a new progress bar
  ///
  /// [height] more be non-negative
  ///
  /// [value] must be in the range of 0 and 100
  const AppProgressBar({
    Key? key,
    this.height = 4.5,
    required this.value,
    this.trackColor,
    this.backgroundColor,
    this.semanticLabel,
  })  : assert(value >= 0 && value <= 100),
        assert(height >= 0),
        super(key: key);

  /// The value of the progress bar. If non-null, this has to
  /// be non-negative and less the 100. If null, the progress bar
  /// will be considered indeterminate.
  final double value;

  /// The height of the line. Default to 4.5px
  final double height;

  /// The color of the track. If null, [MacosThemeData.accentColor] is used
  final Color? trackColor;

  /// The color of the background. If null, [CupertinoColors.secondarySystemFill]
  /// is used
  final Color? backgroundColor;

  /// The semantic label used by screen readers.
  final String? semanticLabel;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('value', value));
    properties.add(DoubleProperty('height', height));
    properties.add(ColorProperty('trackColor', trackColor));
    properties.add(ColorProperty('backgroundColor', backgroundColor));
    properties.add(StringProperty('semanticLabel', semanticLabel));
  }

  @override
  Widget build(BuildContext context) {
    // assert(debugCheckHasMacosTheme(context));
    final MacosThemeData theme = MacosTheme.of(context);
    return Semantics(
      label: semanticLabel,
      value: value.toStringAsFixed(2),
      child: Container(
        constraints: BoxConstraints(
          minHeight: height,
          maxHeight: height,
          minWidth: 85,
        ),
        child: CustomPaint(
          painter: _DeterminateBarPainter(
            value,
            activeColor: MacosDynamicColor.resolve(
              trackColor ?? theme.primaryColor,
              context,
            ),
            backgroundColor: MacosDynamicColor.resolve(
              backgroundColor ?? CupertinoColors.secondarySystemFill,
              context,
            ),
          ),
        ),
      ),
    );
  }
}

class _DeterminateBarPainter extends CustomPainter {
  const _DeterminateBarPainter(
    this.value, {
    this.backgroundColor,
    this.activeColor,
  });

  final double value;
  final Color? backgroundColor;
  final Color? activeColor;

  @override
  void paint(Canvas canvas, Size size) {
    // Draw the background line
    canvas.drawRRect(
      BorderRadius.circular(100).toRRect(
        Offset.zero & size,
      ),
      Paint()
        ..color = backgroundColor ?? CupertinoColors.secondarySystemFill
        ..style = PaintingStyle.fill,
    );

    // Draw the active tick line
    canvas.save();

    canvas.clipRRect(
      BorderRadius.circular(100).toRRect(
        Offset.zero & size,
      ),
    );
    canvas.drawRRect(
      BorderRadius.circular(100).toRRect(Offset.zero &
          Size(
            (value / 100).clamp(0.0, 1.0) * size.width,
            size.height,
          )),
      Paint()
        ..color = activeColor ?? CupertinoColors.activeBlue
        ..style = PaintingStyle.fill,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(_DeterminateBarPainter old) => old.value != value;

  @override
  bool shouldRebuildSemantics(_DeterminateBarPainter oldDelegate) => false;
}
