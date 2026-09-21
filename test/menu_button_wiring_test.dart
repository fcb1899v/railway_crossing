// MenuButton itself: its purchase button follows PurchaseManager.onetimePrice while the
// menu is open, and a tap after the price was cleared opens no purchase dialog.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:railroad_crossing/l10n/app_localizations.dart';
import 'package:railroad_crossing/menu.dart';
import 'package:railroad_crossing/purchase_manager.dart';

const purchaseKey = Key("onetimePurchaseButton");

/// Pumps MenuButton and opens its menu
Future<void> openMenu(WidgetTester tester) async {
  tester.view.physicalSize = const Size(956, 440);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  // The test font's square glyphs overflow the fixed-size menu; layout is not tested here
  final onError = FlutterError.onError;
  FlutterError.onError = (details) {
    if (!details.toString().contains("overflowed")) onError?.call(details);
  };
  addTearDown(() => FlutterError.onError = onError);
  await tester.pumpWidget(const ProviderScope(child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: Locale('en'),
    home: Scaffold(body: MenuButton()),
  )));
  await tester.pump();
  await tester.tap(find.byIcon(Icons.menu));
  await tester.pump();
  // Control: the menu is open
  expect(find.text("Credits"), findsOneWidget);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => PurchaseManager.onetimePrice.value = "");

  testWidgets("no price: the open menu has no purchase button", (tester) async {
    await openMenu(tester);
    expect(find.byKey(purchaseKey), findsNothing);
  });

  testWidgets("a price arriving while the menu is open brings the button in", (tester) async {
    await openMenu(tester);
    expect(find.byKey(purchaseKey), findsNothing);
    PurchaseManager.onetimePrice.value = "¥500";
    await tester.pump();
    expect(find.byKey(purchaseKey), findsOneWidget);
  });

  testWidgets("control: with a price, tapping the button opens the purchase dialog", (tester) async {
    PurchaseManager.onetimePrice.value = "¥500";
    await openMenu(tester);
    await tester.tap(find.byKey(purchaseKey));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(AlertDialog), findsOneWidget);
  });

  testWidgets("price cleared before the tap is handled: no purchase dialog", (tester) async {
    PurchaseManager.onetimePrice.value = "¥500";
    await openMenu(tester);
    // Cleared without a rebuild, as a refetch finding nothing between frames would
    PurchaseManager.onetimePrice.value = "";
    await tester.tap(find.byKey(purchaseKey));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(AlertDialog), findsNothing);
  });
}
