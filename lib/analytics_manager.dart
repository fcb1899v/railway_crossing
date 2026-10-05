// ===== AnalyticsManager: Firebase Analytics event logging =====
// Purchase funnel and photo generation events. Ad, reward and review events are not logged.

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'extension.dart';

class AnalyticsManager {

  /// Replaces the Firebase call in tests, so events can be read without a Firebase app
  @visibleForTesting
  static Future<void> Function(String name, Map<String, Object>? params)? testSink;

  // --- Internal Helper ---

  /// Log an event and swallow any failure so analytics never breaks the app
  static Future<void> _log(String name, [Map<String, Object>? params]) async {
    try {
      final sink = testSink;
      if (sink != null) {
        await sink(name, params);
      } else {
        await FirebaseAnalytics.instance.logEvent(name: name, parameters: params);
      }
      "Analytics: $name ${params ?? ""}".debugPrint();
    } catch (e) {
      "Analytics error: $name: $e".debugPrint();
    }
  }

  // --- Purchase Events ---

  /// Log that the upgrade dialog was shown, with the trigger that opened it
  static Future<void> upgradeOffered(String source) =>
      _log("upgrade_offered", {"source": source});

  /// Log that the user started the purchase flow
  static Future<void> upgradeStarted(String source) =>
      _log("upgrade_started", {"source": source});

  /// Log a completed purchase
  static Future<void> upgradePurchased(String source) =>
      _log("upgrade_purchased", {"source": source});

  /// Log that the user closed the store sheet without buying
  static Future<void> upgradeCancelled(String source) =>
      _log("upgrade_cancelled", {"source": source});

  /// Log a purchase that failed, with a short fixed reason
  static Future<void> upgradeFailed({
    required String source,
    required String flow,
    required String reason,
  }) => _log("upgrade_failed", {"source": source, "flow": flow, "reason": reason});

  // --- Photo Events ---

  /// Log that a photo generation started: `kind` is free or ticket, `requested` the images asked for
  static Future<void> photoRequested({
    required String kind,
    required int requested,
  }) => _log("photo_requested", {"kind": kind, "requested": requested});

  /// Log that at least one photo came back, so `returned` is always 1 or more
  static Future<void> photoGenerated({
    required String kind,
    required int requested,
    required int returned,
  }) => _log("photo_generated", {"kind": kind, "requested": requested, "returned": returned});

  /// Log a generation that returned no photo: `reason` is empty, error or not_ready
  /// `kind` is unknown for not_ready, because free or ticket is decided after the checks that failed
  static Future<void> photoFailed({
    required String kind,
    required String reason,
  }) => _log("photo_failed", {"kind": kind, "reason": reason});

  /// Log a generation that stopped before the call: App Check or the server time was not available
  static Future<void> photoNotReady() => photoFailed(kind: "unknown", reason: "not_ready");
}
