// The banner slot has to satisfy three things at once, and all three were got
// wrong at least once on 2026-09-04:
//
//   1. it must not sit on the control row in the bottom left
//   2. it must stop short of the centre, where the road crosses the tracks
//   3. it must stay at or above 320, the narrowest standard creative
//
// Three is the one with no visible symptom: a slot under 320 has no standard
// creative that fits it, so the fill drops without anything failing. The first
// draft used width() instead of mediaWidth() and gave 285 on an iPhone 16 Pro;
// the ratio alone still gives 266 on an iPhone SE, which is why there is a
// floor. Google states no minimum width, so this is about fill, not about the
// SDK refusing.
//
// The app is locked to landscape (main.dart), so only landscape sizes are
// listed. Sizes are logical pixels, the unit both Flutter and AdSize use.

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

// bannerSlotWidth() is the expression admob_banner.dart uses. Restating it here
// would let this file pass while the widget is broken, which is the failure the
// 2026-09-02 review caught in another test.

/// Where the control row ends: the left margin plus five buttons, each a
/// 0.12h square with a 0.03h margin. Five is the count with the emergency
/// button showing (homepage.dart), which is the widest the row ever gets.
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
      // 50 is the shortest standard creative; 150 is the tallest AdMob will
      // serve an adaptive banner at, so the ceiling has to sit between them
      expect(maxBannerHeight, greaterThanOrEqualTo(50));
      expect(maxBannerHeight, lessThanOrEqualTo(150));
    });

    test('the ratio keeps the banner on its own half', () {
      expect(bannerWidthRatio, lessThanOrEqualTo(0.5));
    });
  });
}
