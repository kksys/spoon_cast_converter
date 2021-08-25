// Flutter imports:
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:macos_ui/macos_ui.dart';

const _kDialogBorderRadius = BorderRadius.all(Radius.circular(12.0));

class AppAlertDialog extends MacosAlertDialog {
  const AppAlertDialog({
    Key? key,
    required Widget appIcon,
    required Widget title,
    required Widget message,
    required Widget primaryButton,
    Widget? secondaryButton,
    bool? horizontalActions = true,
    Widget? suppress,
  }) : super(
          key: key,
          appIcon: appIcon,
          title: title,
          message: message,
          primaryButton: primaryButton,
          secondaryButton: secondaryButton,
          horizontalActions: horizontalActions,
          suppress: suppress,
        );
  @override
  Widget build(BuildContext context) {
    final brightness = MacosTheme.brightnessOf(context);

    final outerBorderColor = brightness.resolve(
      Colors.black.withOpacity(0.23),
      Colors.black.withOpacity(0.76),
    );

    final innerBorderColor = brightness.resolve(
      Colors.white.withOpacity(0.45),
      Colors.white.withOpacity(0.15),
    );

    final Size size = MediaQuery.of(context).size;

    return Dialog(
      backgroundColor: brightness.resolve(
        CupertinoColors.systemGrey6.color,
        MacosColors.controlBackgroundColor.darkColor,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: _kDialogBorderRadius,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        decoration: BoxDecoration(
          border: Border.all(
            width: 2,
            color: innerBorderColor,
          ),
          borderRadius: _kDialogBorderRadius,
        ),
        foregroundDecoration: BoxDecoration(
          border: Border.all(
            width: 1,
            color: outerBorderColor,
          ),
          borderRadius: _kDialogBorderRadius,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: size.width * 0.9,
            maxHeight: size.height * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 28),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: 56,
                  maxWidth: 56,
                ),
                child: appIcon,
              ),
              const SizedBox(height: 28),
              DefaultTextStyle(
                style: MacosTheme.of(context).typography.headline,
                textAlign: TextAlign.center,
                child: title,
              ),
              const SizedBox(height: 16),
              DefaultTextStyle(
                textAlign: TextAlign.center,
                style: MacosTheme.of(context).typography.headline,
                child: message,
              ),
              const SizedBox(height: 18),
              if (secondaryButton == null) ...[
                Row(
                  children: [
                    Expanded(
                      child: primaryButton,
                    ),
                  ],
                ),
              ] else ...[
                if (horizontalActions!) ...[
                  Row(
                    children: [
                      if (secondaryButton != null) ...[
                        Expanded(
                          child: secondaryButton!,
                        ),
                        const SizedBox(width: 8.0),
                      ],
                      Expanded(
                        child: primaryButton,
                      ),
                    ],
                  ),
                ] else ...[
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(child: primaryButton),
                        ],
                      ),
                      const SizedBox(height: 8.0),
                      if (secondaryButton != null) ...[
                        Row(
                          children: [
                            Expanded(
                              child: secondaryButton!,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
              ],
              const SizedBox(height: 16),
              if (suppress != null)
                DefaultTextStyle(
                  style: MacosTheme.of(context).typography.headline,
                  child: suppress!,
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
