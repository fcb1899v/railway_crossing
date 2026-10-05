// A purchase started from the App Store product page grants the pass exactly once, and only when the store charged.

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:railroad_crossing/common_function.dart';
import 'package:railroad_crossing/constant.dart';
import 'package:railroad_crossing/extension.dart';
import 'package:railroad_crossing/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

PromotedPurchaseResult purchased(List<String> products) => PromotedPurchaseResult(
  productIdentifier: "passes",
  customerInfo: CustomerInfo(
    const EntitlementInfos({}, {}), const {}, const [], products, const [], "", "", const {}, "",
  ),
);

void main() {
  late ProviderContainer container;
  late int grants;
  Future<void> grant(ProviderContainer _) async => grants++;

  setUp(() {
    container = ProviderContainer();
    grants = 0;
  });
  tearDown(() => container.dispose());

  test("a charged purchase grants once", () async {
    await handlePromotedPurchase(container, "passes", () async => purchased(["passes"]), grant: grant);
    expect(grants, 1);
  });

  test("a cancelled or failed purchase grants nothing", () async {
    await handlePromotedPurchase(container, "passes", () async => throw Exception("cancelled"), grant: grant);
    expect(grants, 0);
  });

  test("a result with nothing purchased grants nothing", () async {
    await handlePromotedPurchase(container, "passes", () async => purchased([]), grant: grant);
    expect(grants, 0);
  });

  test("a failing grant is contained", () async {
    await expectLater(handlePromotedPurchase(container, "passes", () async => purchased(["passes"]),
      grant: (_) async => throw StateError("write failed")), completes);
    expect(grants, 0);
  });

  test("the real grant adds the pass tickets and sets the ad-free expiry", () async {
    SharedPreferences.setMockInitialValues({});
    final real = ProviderContainer();
    addTearDown(real.dispose);
    real.read(ticketsProvider.notifier).update(3);
    final pushed = <int>[];
    Future<void> push({required int tickets, required int expiration, required int lastClaimed}) async => pushed.add(tickets);
    await grantOnetimePlan(real, serverTime: () async => 20261005, pushProgress: push);
    expect(real.read(ticketsProvider), 3 + addOnTicketNumber);
    expect(pushed, [3 + addOnTicketNumber]);
    expect(real.read(currentProvider), 20261005);
    expect(real.read(expirationProvider), 20261005.nextMonth());
    await grantOnetimePlan(real, serverTime: () async => 20261005, pushProgress: push);
    expect(real.read(ticketsProvider), 3 + 2 * addOnTicketNumber);
  });
}
