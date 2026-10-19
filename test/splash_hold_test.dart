import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:railroad_crossing/splash_hold.dart';

void main() {
  late List<Duration> waits;
  late int removes;

  SplashHold hold(Duration elapsed) => SplashHold(
        elapsed: () => elapsed,
        delay: (d) async => waits.add(d),
        remove: () => removes++,
      );

  setUp(() {
    waits = [];
    removes = 0;
  });

  test('the minimum is 3 seconds and the cap is 5 seconds', () {
    expect(splashMinDuration, const Duration(seconds: 3));
    expect(splashMaxDuration, const Duration(seconds: 5));
  });

  test('1 s elapsed waits 2 s, then removes', () async {
    await hold(const Duration(seconds: 1)).removeWhenReady();
    expect(waits, [const Duration(seconds: 2)]);
    expect(removes, 1);
  });

  test('3 s elapsed removes without waiting', () async {
    await hold(const Duration(seconds: 3)).removeWhenReady();
    expect(waits, isEmpty);
    expect(removes, 1);
  });

  test('more than 3 s elapsed removes without waiting', () async {
    await hold(const Duration(seconds: 7)).removeWhenReady();
    expect(waits, isEmpty);
    expect(removes, 1);
  });

  test('0 s elapsed waits 3 s', () async {
    await hold(Duration.zero).removeWhenReady();
    expect(waits, [const Duration(seconds: 3)]);
    expect(removes, 1);
  });

  test('a second call does not remove or wait again', () async {
    final h = hold(Duration.zero);
    await h.removeWhenReady();
    await h.removeWhenReady();
    expect(waits.length, 1);
    expect(removes, 1);
  });

  test('concurrent calls remove once', () async {
    final h = hold(Duration.zero);
    await Future.wait([h.removeWhenReady(), h.removeWhenReady()]);
    expect(removes, 1);
  });

  test('the real clock waits about 3 s when just started', () {
    // The timer start() sets never completes, so no real timer is left behind
    final h = SplashHold(delay: (_) => Completer<void>().future)..start();
    expect(h.remaining(), greaterThan(const Duration(milliseconds: 2500)));
    expect(h.remaining(), lessThanOrEqualTo(splashMinDuration));
  });

  group('the cap', () {
    test('start() sets a timer for the cap, and the splash goes when no page asks', () async {
      final h = SplashHold(
        elapsed: () => splashMaxDuration,
        delay: (d) async => waits.add(d),
        remove: () => removes++,
      )..start();
      await Future<void>.delayed(Duration.zero);
      expect(waits.first, splashMaxDuration);
      expect(h.visible.value, isFalse);
      expect(removes, 1);
    });

    test('the page asking first and the timer later remove once', () async {
      final h = SplashHold(
        elapsed: () => splashMaxDuration,
        delay: (d) async => waits.add(d),
        remove: () => removes++,
      )..start();
      await h.removeWhenReady();
      await Future<void>.delayed(Duration.zero);
      expect(removes, 1);
    });

    test('the splash stays up until the timer completes, then goes', () async {
      var now = const Duration(seconds: 1);
      final timer = Completer<void>();
      final h = SplashHold(
        elapsed: () => now,
        delay: (_) => timer.future,
        remove: () => removes++,
      )..start();
      await Future<void>.delayed(Duration.zero);
      expect(h.visible.value, isTrue);
      expect(removes, 0);
      now = splashMaxDuration;
      timer.complete();
      await Future<void>.delayed(Duration.zero);
      expect(h.visible.value, isFalse);
      expect(removes, 1);
    });
  });

  group('startup work', () {
    late Duration now;
    late List<Duration> delays;
    late int removed;

    SplashHold workHold() => SplashHold(
          elapsed: () => now,
          // The fake delay moves the clock, so the 5 s cap is measured from the same start
          delay: (d) async {
            delays.add(d);
            now += d;
          },
          remove: () => removed++,
        );

    setUp(() {
      now = Duration.zero;
      delays = [];
      removed = 0;
    });

    test('work done before 3 s: removed at 3 s', () async {
      final h = workHold()..track(Future<void>.value());
      await h.removeWhenReady();
      expect(delays.first, const Duration(seconds: 3));
      expect(removed, 1);
      expect(h.visible.value, isFalse);
    });

    test('work never ends: removed at the 5 s cap', () async {
      final h = workHold()..track(Completer<void>().future);
      await h.removeWhenReady();
      expect(delays, [const Duration(seconds: 3), const Duration(seconds: 2)]);
      expect(removed, 1);
    });

    test('failed work does not keep the splash up', () async {
      final h = workHold()..track(Future<void>.error(StateError('offline')));
      await h.removeWhenReady();
      expect(removed, 1);
    });

    test('past the cap already: no wait for the work', () async {
      now = const Duration(seconds: 6);
      final h = workHold()..track(Completer<void>().future);
      await h.removeWhenReady();
      expect(delays, isEmpty);
      expect(removed, 1);
    });
  });

  group('image size', () {
    test('a source larger than the drawn size is decoded to the drawn size', () {
      expect(splashTargetWidth(sourceWidth: 512, sourceHeight: 512, drawWidthPx: 384), 384);
    });

    test('a source smaller than the drawn size keeps its own size', () {
      expect(splashTargetWidth(sourceWidth: 200, sourceHeight: 200, drawWidthPx: 768), 200);
    });

    test('the longest side never passes 1024 px', () {
      expect(splashTargetWidth(sourceWidth: 3000, sourceHeight: 3000, drawWidthPx: 1080), 1024);
      expect(splashTargetWidth(sourceWidth: 3000, sourceHeight: 3000, drawWidthPx: 700), 700);
      expect(splashTargetWidth(sourceWidth: 500, sourceHeight: 2000), 256);
    });

    test('an unknown screen size decodes at the source width, within the limit', () {
      expect(splashTargetWidth(sourceWidth: 3000, sourceHeight: 3000), 1024);
      expect(splashTargetWidth(sourceWidth: 600, sourceHeight: 300), 600);
    });
  });

  testWidgets('the overlay covers the page, takes no touch, and goes when the hold ends', (tester) async {
    var taps = 0;
    final h = SplashHold(elapsed: () => const Duration(seconds: 3), delay: (_) async {}, remove: () {});
    await tester.pumpWidget(MaterialApp(home: SplashOverlay(hold: h, child: Scaffold(
      body: Center(child: ElevatedButton(onPressed: () => taps++, child: const Text('home'))),
    ))));
    expect(find.byType(ColoredBox), findsWidgets);
    await tester.tap(find.text('home'), warnIfMissed: false);
    expect(taps, 0, reason: 'touches do nothing while the splash is up');
    await h.removeWhenReady();
    await tester.pump();
    await tester.tap(find.text('home'));
    expect(taps, 1);
  });

  testWidgets('the back button does nothing while the splash is up, and pops after it goes', (tester) async {
    final h = SplashHold(elapsed: () => const Duration(seconds: 3), delay: (_) async {}, remove: () {});
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(
      navigatorKey: navigator,
      home: const Scaffold(body: Text('root')),
    ));
    navigator.currentState!.push(MaterialPageRoute<void>(builder: (_) => SplashOverlay(hold: h, child: const Scaffold(body: Text('home')))));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('home'), findsOneWidget, reason: 'still on the page under the splash');
    await h.removeWhenReady();
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('home'), findsNothing);
  });

  testWidgets('screen readers do not reach the page under the splash', (tester) async {
    final handle = tester.ensureSemantics();
    final h = SplashHold(elapsed: () => const Duration(seconds: 3), delay: (_) async {}, remove: () {});
    await tester.pumpWidget(MaterialApp(home: SplashOverlay(hold: h, child: const Scaffold(body: Text('home')))));
    expect(find.bySemanticsLabel('home'), findsNothing);
    await h.removeWhenReady();
    await tester.pump();
    expect(find.bySemanticsLabel('home'), findsOneWidget);
    handle.dispose();
  });

  test('hidden() completes when the splash goes', () async {
    final h = SplashHold(elapsed: () => const Duration(seconds: 3), delay: (_) async {}, remove: () {});
    var done = false;
    unawaited(h.hidden().then((_) => done = true));
    await Future<void>.delayed(Duration.zero);
    expect(done, isFalse);
    await h.removeWhenReady();
    await Future<void>.delayed(Duration.zero);
    expect(done, isTrue);
  });
}
