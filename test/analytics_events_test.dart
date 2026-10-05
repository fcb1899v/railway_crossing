// Event names and parameters of the purchase and photo analytics, and that each outcome is logged once.
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:railroad_crossing/analytics_manager.dart';
import 'package:railroad_crossing/constant.dart';
import 'package:railroad_crossing/menu.dart';
import 'package:railroad_crossing/photo_manager.dart';
import 'package:railroad_crossing/purchase_manager.dart';

typedef Logged = ({String name, Map<String, Object>? params});

void main() {
  late List<Logged> events;

  setUp(() {
    events = [];
    AnalyticsManager.testSink = (name, params) async => events.add((name: name, params: params));
  });
  tearDown(() => AnalyticsManager.testSink = null);

  // purchaseCancelledError is index 1 and storeProblemError index 2 in PurchasesErrorCode
  PlatformException storeError(PurchasesErrorCode code) => PlatformException(code: code.index.toString());

  Future<OnetimePurchaseResult> track(Future<OnetimePurchaseResult> Function() buy) =>
    trackOnetimePurchase(buy, source: "menu");

  group("purchase events", () {
    test("offered and started carry the source", () async {
      await AnalyticsManager.upgradeOffered("menu");
      await AnalyticsManager.upgradeStarted("menu");
      expect(events.map((e) => e.name), ["upgrade_offered", "upgrade_started"]);
      expect(events.every((e) => e.params!.length == 1 && e.params!["source"] == "menu"), isTrue);
    });

    test("purchased logs only upgrade_purchased", () async {
      final result = await track(() async => const OnetimePurchaseResult.purchased());
      expect(result.isPurchased, isTrue);
      expect(events.map((e) => e.name), ["upgrade_purchased"]);
      expect(events.single.params, {"source": "menu"});
    });

    test("cancelled logs only upgrade_cancelled", () async {
      final result = await track(() async => const OnetimePurchaseResult.cancelled());
      expect(result.isPurchased, isFalse);
      expect(events.map((e) => e.name), ["upgrade_cancelled"]);
      expect(events.single.params, {"source": "menu"});
    });

    test("failed logs only upgrade_failed with flow and reason", () async {
      await track(() async => const OnetimePurchaseResult.failed("storeProblemError"));
      expect(events.map((e) => e.name), ["upgrade_failed"]);
      expect(events.single.params, {"source": "menu", "flow": "purchase", "reason": "storeProblemError"});
    });

    test("an empty result is failed with empty_result", () async {
      await track(() async => const OnetimePurchaseResult.failed("empty_result"));
      expect(events.single.params!["reason"], "empty_result");
    });

    test("a StateError from the purchase is store_unavailable", () async {
      final result = await track(() async => throw StateError("No package"));
      expect(result.status, OnetimePurchaseStatus.failed);
      expect(events.map((e) => e.name), ["upgrade_failed"]);
      expect(events.single.params!["reason"], "store_unavailable");
    });

    test("any other exception is other, and a PlatformException is its code name", () async {
      await track(() async => throw Exception("x"));
      await track(() async => throw storeError(PurchasesErrorCode.storeProblemError));
      await track(() async => throw PlatformException(code: "not a number"));
      expect(events.map((e) => e.params!["reason"]), ["other", "storeProblemError", "unknownError"]);
    });

    test("work after the purchase is not tracked, so a grant failure logs no failure", () async {
      final result = await track(() async => const OnetimePurchaseResult.purchased());
      try {
        if (result.isPurchased) throw StateError("grant failed");
      } catch (_) {}
      expect(events.map((e) => e.name), ["upgrade_purchased"]);
    });

    test("a failing analytics call does not break the purchase", () async {
      AnalyticsManager.testSink = (name, params) async => throw Exception("analytics down");
      final result = await track(() async => const OnetimePurchaseResult.purchased());
      expect(result.isPurchased, isTrue);
    });

    test("the error code of a cancelled purchase is told apart", () {
      expect(purchaseErrorCode(storeError(PurchasesErrorCode.purchaseCancelledError)), PurchasesErrorCode.purchaseCancelledError);
      expect(purchaseErrorCode(storeError(PurchasesErrorCode.storeProblemError)), isNot(PurchasesErrorCode.purchaseCancelledError));
    });
  });

  group("photo events", () {
    PhotoResult images(int n) => PhotoResult.images(List.generate(n, (_) => Uint8List(1)));

    test("a free photo logs requested then generated", () async {
      await trackPhotoGeneration(kind: "free", requested: 1, generate: () async => images(1));
      expect(events.map((e) => e.name), ["photo_requested", "photo_generated"]);
      expect(events[0].params, {"kind": "free", "requested": 1});
      expect(events[1].params, {"kind": "free", "requested": 1, "returned": 1});
    });

    test("a ticket photo logs how many came back", () async {
      await trackPhotoGeneration(kind: "ticket", requested: 3, generate: () async => images(2));
      expect(events[1].params, {"kind": "ticket", "requested": 3, "returned": 2});
    });

    test("empty and error are told apart", () async {
      await trackPhotoGeneration(kind: "ticket", requested: 3, generate: () async => const PhotoResult.failed("empty"));
      await trackPhotoGeneration(kind: "free", requested: 1, generate: () async => const PhotoResult.failed("error"));
      expect(events.map((e) => e.name), ["photo_requested", "photo_failed", "photo_requested", "photo_failed"]);
      expect(events[1].params, {"kind": "ticket", "reason": "empty"});
      expect(events[3].params, {"kind": "free", "reason": "error"});
    });

    test("an exception from the call is logged as error and rethrown", () async {
      await expectLater(
        trackPhotoGeneration(kind: "free", requested: 1, generate: () async => throw Exception("x")),
        throwsException,
      );
      expect(events.map((e) => e.name), ["photo_requested", "photo_failed"]);
      expect(events[1].params, {"kind": "free", "reason": "error"});
    });

    test("not_ready is logged with kind unknown", () async {
      await AnalyticsManager.photoNotReady();
      expect(events.single.name, "photo_failed");
      expect(events.single.params, {"kind": "unknown", "reason": "not_ready"});
    });

    test("free asks for 1 and ticket asks for generatePhotoNumber", () async {
      await trackFreePhoto(() async => images(1));
      await trackTicketPhoto(() async => images(generatePhotoNumber));
      expect(events[0].params, {"kind": "free", "requested": 1});
      expect(events[2].params, {"kind": "ticket", "requested": generatePhotoNumber});
      expect(events[3].params, {"kind": "ticket", "requested": generatePhotoNumber, "returned": generatePhotoNumber});
    });

    test("an empty answer is empty, any other exception is error", () {
      expect(photoFailureOf(const EmptyPhotoException()).failureReason, "empty");
      expect(photoFailureOf(FirebaseFunctionsException(message: "x", code: "internal")).failureReason, "error");
      expect(photoFailureOf(Exception("Invalid image payload")).failureReason, "error");
      expect(photoFailureOf(const EmptyPhotoException()).images, isEmpty);
    });

    test("a failing analytics call does not stop the images", () async {
      AnalyticsManager.testSink = (name, params) async => throw Exception("analytics down");
      final result = await trackFreePhoto(() async => images(1));
      expect(result.images, hasLength(1));
      final failed = await trackTicketPhoto(() async => const PhotoResult.failed("empty"));
      expect(failed.failureReason, "empty");
    });
  });

  group("purchase result mapping", () {
    test("a cancelled purchase maps to cancelled", () {
      final r = onetimeResultOfError(storeError(PurchasesErrorCode.purchaseCancelledError));
      expect(r.status, OnetimePurchaseStatus.cancelled);
    });

    test("any other error maps to failed with the code name", () {
      final r = onetimeResultOfError(storeError(PurchasesErrorCode.storeProblemError));
      expect(r.status, OnetimePurchaseStatus.failed);
      expect(r.reason, "storeProblemError");
      expect(onetimeResultOfError(PlatformException(code: "x")).reason, "unknownError");
    });

    test("no purchased product maps to empty_result", () {
      final r = onetimeResultOf(const [], null);
      expect(r.status, OnetimePurchaseStatus.failed);
      expect(r.reason, "empty_result");
    });

    test("a purchased product maps to purchased", () {
      expect(onetimeResultOf(const ["ticket"], null).isPurchased, isTrue);
    });
  });

  group("offering the purchase", () {
    test("under the ticket limit the dialog shows and upgrade_offered is sent once", () {
      var dialog = 0;
      var limit = 0;
      offerOnetime(tickets: onetimeTicketLimitNumber, showTicketLimit: () => limit++, showDialog: () => dialog++);
      expect([dialog, limit], [1, 0]);
      expect(events.map((e) => e.name), ["upgrade_offered"]);
      expect(events.single.params, {"source": "menu"});
    });

    test("over the ticket limit only the snackbar shows and nothing is sent", () {
      var dialog = 0;
      var limit = 0;
      offerOnetime(tickets: onetimeTicketLimitNumber + 1, showTicketLimit: () => limit++, showDialog: () => dialog++);
      expect([dialog, limit], [0, 1]);
      expect(events, isEmpty);
    });
  });
}
