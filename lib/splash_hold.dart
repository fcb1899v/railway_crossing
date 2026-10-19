import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'splash_config.dart';

/// The shortest time the launch splash stays on screen, counted from the start of main().
const splashMinDuration = Duration(seconds: 3);

/// The longest time the launch splash stays on screen, counted from the start of main().
const splashMaxDuration = Duration(seconds: 5);

/// The longest side, in pixels, the splash image is decoded to.
const splashMaxImageSide = 1024;

/// The width, in pixels, to decode an image of [sourceWidth] x [sourceHeight] to.
/// It is the smaller of the source width and [drawWidthPx], and the longest side never passes [splashMaxImageSide].
/// A null [drawWidthPx] means the screen size is not known yet, so only the source and the side limit apply.
int splashTargetWidth({required int sourceWidth, required int sourceHeight, double? drawWidthPx}) {
  var width = drawWidthPx == null ? sourceWidth : math.min(sourceWidth, drawWidthPx.round());
  width = math.max(width, 1);
  final height = width * sourceHeight / sourceWidth;
  final longest = math.max(width.toDouble(), height);
  if (longest > splashMaxImageSide) width = (width * splashMaxImageSide / longest).floor();
  return math.max(width, 1);
}

/// Keeps the launch splash up for at least [minDuration] after launch, and never past [maxDuration].
/// iOS keeps the native splash (FlutterNativeSplash.preserve).
/// Android shows [SplashOverlay] as the first Flutter frame instead, so the window is drawn and takes input at once:
/// a key pressed while no window is drawn waits, and after 5 s Android reports the app as not responding.
class SplashHold {
  /// [elapsed], [delay] and [remove] can be replaced in tests.
  SplashHold({
    this.minDuration = splashMinDuration,
    this.maxDuration = splashMaxDuration,
    this.elapsed,
    Future<void> Function(Duration)? delay,
    void Function()? remove,
  })  : _delay = delay ?? Future<void>.delayed,
        _remove = remove ?? FlutterNativeSplash.remove;

  final Duration minDuration;
  final Duration maxDuration;
  final Duration Function()? elapsed;
  final Future<void> Function(Duration) _delay;
  final void Function() _remove;
  final Stopwatch _stopwatch = Stopwatch();
  final List<Future<void>> _work = [];
  bool _removed = false;

  /// True while the Flutter splash covers the app. [SplashOverlay] listens to it.
  final ValueNotifier<bool> visible = ValueNotifier<bool>(true);

  /// The splash image, decoded before runApp so the very first frame already has it.
  ui.Image? image;

  /// Starts the clock, and a timer that removes the splash at [maxDuration] even when the page never asks.
  /// Call it first in main().
  void start() {
    _stopwatch.start();
    unawaited(_delay(maxDuration).then((_) => removeWhenReady()));
  }

  /// Completes once the splash is gone.
  Future<void> hidden() {
    if (!visible.value) return Future<void>.value();
    final done = Completer<void>();
    void listener() {
      if (visible.value) return;
      visible.removeListener(listener);
      done.complete();
    }
    visible.addListener(listener);
    return done.future;
  }

  Duration get _elapsed => elapsed?.call() ?? _stopwatch.elapsed;

  /// Startup work the splash waits for, up to [maxDuration]. Its failure does not keep the splash up.
  void track(Future<void> work) => _work.add(work.catchError((Object e) => debugPrint('Startup work: $e')));

  /// Decodes [splashImageAsset] for [SplashOverlay], no larger than it is drawn. Failure leaves the plain background.
  Future<void> loadImage() async {
    ui.ImmutableBuffer? buffer;
    ui.ImageDescriptor? descriptor;
    try {
      final data = await rootBundle.load(splashImageAsset);
      buffer = await ui.ImmutableBuffer.fromUint8List(data.buffer.asUint8List());
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      final view = ui.PlatformDispatcher.instance.views.first;
      final size = view.physicalSize;
      final double? drawWidthPx = size == ui.Size.zero
          ? null
          : splashFillWidth ? size.shortestSide : splashImageWidth * view.devicePixelRatio;
      final codec = await descriptor.instantiateCodec(
        targetWidth: splashTargetWidth(sourceWidth: descriptor.width, sourceHeight: descriptor.height, drawWidthPx: drawWidthPx),
      );
      image = (await codec.getNextFrame()).image;
    } catch (e) {
      debugPrint('Splash image: $e');
    } finally {
      descriptor?.dispose();
      buffer?.dispose();
    }
  }

  /// Time still to wait before the splash may go: never negative.
  Duration remaining() {
    final left = minDuration - _elapsed;
    return left > Duration.zero ? left : Duration.zero;
  }

  /// Waits out the remaining time and the tracked work (never past [maxDuration]), then removes the splash once.
  /// It touches no widget, so it is safe to finish after the caller was disposed.
  Future<void> removeWhenReady() async {
    if (_removed) return;
    _removed = true;
    final wait = remaining();
    if (wait > Duration.zero) await _delay(wait);
    final left = maxDuration - _elapsed;
    if (_work.isNotEmpty && left > Duration.zero) {
      await Future.any([Future.wait(_work), _delay(left)]);
    }
    _remove();
    visible.value = false;
    debugPrint('Splash removed at ${_elapsed.inMilliseconds} ms');
  }
}

/// The app-wide instance used by main() and the first page.
final splashHold = SplashHold();

/// Android only: draws the splash over [child] until [SplashHold.visible] turns false.
/// Touches, screen-reader actions and the back button do nothing while it is up: the page under it is not ready, and the splash lasts only seconds.
/// iOS returns [child] as is, because its native splash is still up.
class SplashOverlay extends StatelessWidget {
  const SplashOverlay({super.key, required this.child, this.hold});

  final Widget child;
  /// The hold to follow; the app-wide [splashHold] when null.
  /// Tests pass their own.
  final SplashHold? hold;

  @override
  Widget build(BuildContext context) {
    if (!Platform.isAndroid && hold == null) return child;
    final h = hold ?? splashHold;
    return ValueListenableBuilder<bool>(
      valueListenable: h.visible,
      builder: (context, visible, _) => PopScope(
        canPop: !visible,
        child: Stack(
          fit: StackFit.expand,
          textDirection: TextDirection.ltr,
          children: [
            ExcludeSemantics(excluding: visible, child: child),
            if (visible) AbsorbPointer(
              child: ColoredBox(
                color: splashColor,
                child: splashFillWidth
                    ? SizedBox.expand(child: RawImage(image: h.image, fit: splashFit, filterQuality: FilterQuality.high))
                    : Center(
                        child: RawImage(
                          image: h.image,
                          width: splashImageWidth,
                          height: splashImageHeight,
                          fit: splashFit,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
