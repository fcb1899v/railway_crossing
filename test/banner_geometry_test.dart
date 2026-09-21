// The banner slot must clear the control row, stop short of the centre crossing and stay >= 320.
// Landscape only; sizes are logical pixels.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:railroad_crossing/common_extension.dart';
import 'package:railroad_crossing/constant.dart';

/// The narrowest standard creative is 320x50. A slot under it cannot be filled
/// by one.
const double narrowestStandardCreative = 320;

/// One device, as MediaQuery reports it in landscape.
class Device {
  const Device(this.name, this.width, this.height);
  final String name;
  final double width;
  final double height;
  @override
  String toString() => '$name (${width.toInt()}x${height.toInt()})';
}

const devices = <Device>[
  Device('iPhone SE 3rd', 667, 375),
  Device('iPhone 16 Pro', 874, 402),
  Device('iPhone 16 Pro Max', 956, 440),
  Device('iPad 10.9', 1180, 820),
];

/// Runs [body] with a BuildContext that reports [device] as the window size.
Future<void> withDevice(
  WidgetTester tester,
  Device device,
  void Function(BuildContext context) body,
) async {
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(size: Size(device.width, device.height)),
      child: Builder(
        builder: (context) {
          body(context);
          return const SizedBox.shrink();
        },
      ),
    ),
  );
}

// bannerSlotWidth() is the expression admob_banner.dart uses.
// Restating it here would let this file pass while the widget is broken.

/// Where the control row ends: the left margin plus five 0.12h buttons with 0.03h
/// margins. Five is the count with the emergency button showing, the widest the row gets.
double controlsRightEdge(BuildContext context) =>
    context.sideMargin() + 5 * (context.operationButtonSize() + context.buttonSpace());

void main() {
  group('banner slot', () {
    for (final device in devices) {
      testWidgets('$device clears the control row', (tester) async {
        await withDevice(tester, device, (context) {
          final left = device.width - context.bannerSlotWidth();
          expect(
            left,
            greaterThan(controlsRightEdge(context)),
            reason: 'the banner would cover the buttons on $device',
          );
        });
      });

      testWidgets('$device stops short of the centre', (tester) async {
        await withDevice(tester, device, (context) {
          final left = device.width - context.bannerSlotWidth();
          expect(
            left,
            greaterThanOrEqualTo(device.width / 2),
            reason: 'the banner would cross the crossing on $device',
          );
        });
      });

      testWidgets('$device leaves room for a standard creative', (tester) async {
        await withDevice(tester, device, (context) {
          expect(
            context.bannerSlotWidth(),
            greaterThanOrEqualTo(narrowestStandardCreative),
            reason: 'under 320 no standard creative fits the slot, so the '
                'fill drops with nothing failing to show it',
          );
        });
      });
    }

    test('the height ceiling stays inside what a banner can be', () {
      // 50 is the shortest standard creative, and 150 is the tallest AdMob serves an adaptive banner at.
      // The ceiling has to sit between them.
      expect(maxBannerHeight, greaterThanOrEqualTo(50));
      expect(maxBannerHeight, lessThanOrEqualTo(150));
    });

    test('the ratio keeps the banner on its own half', () {
      expect(bannerWidthRatio, lessThanOrEqualTo(0.5));
    });
  });
}
