import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'common_extension.dart';
import 'constant.dart';

/// ===== COMMON WIDGET CLASS =====
// Common Widget Class - Provides reusable UI components and utilities
class CommonWidget {

  /// ===== CLASS PROPERTIES =====
  // Build context for UI interactions
  final BuildContext context;

  CommonWidget({
    required this.context,
  });

  /// ===== BUTTON COMPONENTS =====
  // Circular icon button for photo display controls
  Widget circleIconButton({
    required IconData icon,
    required void Function() onTap,
  }) =>  GestureDetector(
    onTap: onTap,
    child: Container(
      width: context.fabSize(),
      height: context.fabSize(),
      margin: EdgeInsets.all(context.buttonSpace()),
      decoration: const BoxDecoration(shape: BoxShape.circle),
      child: Icon(icon,
        color: whiteColor,
        size: context.fabIconSize(),
      ),
    ),
  );

  /// ===== NOTIFICATION COMPONENTS =====
  // Show snackbar notification with customizable alert styling
  void showSnackBar(String text, bool isAlert) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: blackColor,
          fontSize: context.snackBarFontSize(),
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    final snackBar = SnackBar(
      content: Text(text,
        style: TextStyle(
          color: isAlert ? whiteColor: blackColor,
          fontWeight: FontWeight.bold,
          fontSize: context.snackBarFontSize(),
        ),
        textAlign: TextAlign.center,
      ),
      backgroundColor: isAlert ? redColor: whiteColor,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.snackBarBorderRadius()),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: 0,
        vertical: context.snackBarPadding(),
      ), // Content padding
      margin: EdgeInsets.symmetric(
        horizontal: context.snackBarSideMargin(textPainter),
        vertical: context.snackBarBottomMargin(),
      ), // Center positioning
    );
    "showSnackBar: $text".debugPrint();
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  /// ===== DIALOG COMPONENTS =====
  // Show custom Cupertino dialog with title, content, and action
  void customDialog({
    required String title,
    required String content,
    required bool isPositive
  }) => showCupertinoDialog(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        CupertinoDialogAction(
          child: Text(context.ok(),
            style: TextStyle(
              color: isPositive ? greenColor: redColor,
            )
          ),
          onPressed: () => context.pushHomePage()
        ),
      ],
    ),
  );

  /// ===== ANIMATION COMPONENTS =====
  // Custom fade transition with ease-in-out curve
  FadeTransition customFadeTransition({
    required Animation<double> animation,
    required Widget child
  }) => FadeTransition(
    opacity: CurvedAnimation(
      parent: animation,
      curve: Curves.easeInOut,
    ),
    child: child,
  );

  /// ===== LOADING COMPONENTS =====
  // Circular progress indicator with overlay background
  Widget circularProgressIndicator() => Stack(children: [
    Container(
      width: context.mediaWidth(),
      height: context.mediaHeight(),
      color: transpBlackColor,
    ),
    Center(
      child: SizedBox(
        width: context.circleSize(),
        height: context.circleSize(),
        child: CircularProgressIndicator(
          color: whiteColor,
          strokeWidth: context.circleStrokeWidth(),
        )
      )
    ),
  ]);
}
