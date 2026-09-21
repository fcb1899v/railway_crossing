// The one-time menu panel: the purchase button is drawn only from a live store price, and
// without it the panel shrinks by exactly that space. Wiring: menu_button_wiring_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:railroad_crossing/common_extension.dart';
import 'package:railroad_crossing/constant.dart';
import 'package:railroad_crossing/l10n/app_localizations.dart';
import 'package:railroad_crossing/menu.dart';

const purchaseKey = Key("onetimePurchaseButton");

Future<void> pumpPanel(WidgetTester tester, String price) async {
  tester.view.physicalSize = const Size(956, 440);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  // The test font's square glyphs overflow the fixed-size menu. Both layouts overflow
  // alike, so the geometry below is compared between them, not against the panel alone
  final onError = FlutterError.onError;
  FlutterError.onError = (details) {
    if (!details.toString().contains("overflowed")) onError?.call(details);
  };
  addTearDown(() => FlutterError.onError = onError);
  await tester.pumpWidget(MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Scaffold(body: Builder(builder: (context) => MenuWidget(
      context: context,
      isMenuOpen: true,
      countryNumber: 0,
      tickets: 0,
      currentDate: 20260913000000,
      lastClaimedDate: 20260912000000,
      expirationDate: 20260101000000,
    ).onetimeMenuWidget(price: price, onTap: () {}))),
  ));
  await tester.pump();
}

/// The panel's own box: the first DecoratedBox under the white panel Container
Rect panelRect(WidgetTester tester) => tester.getRect(find.descendant(
  of: find.byWidgetPredicate((w) => w is Container
    && w.decoration is BoxDecoration
    && (w.decoration as BoxDecoration).color == transpWhiteColor),
  matching: find.byType(DecoratedBox),
).first);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets("no price: no purchase button", (tester) async {
    await pumpPanel(tester, "");
    // Control: the menu itself and its links were drawn
    expect(find.text("Credits"), findsOneWidget);
    expect(find.byType(Divider), findsNWidgets(2));
    expect(find.byKey(purchaseKey), findsNothing);
  });

  testWidgets("price: the purchase button is drawn", (tester) async {
    await pumpPanel(tester, "¥500");
    expect(find.byKey(purchaseKey), findsOneWidget);
  });

  testWidgets("without the button the panel loses exactly its space, top unchanged", (tester) async {
    await pumpPanel(tester, "¥500");
    final withPanel = panelRect(tester);
    final withButton = tester.getRect(find.byKey(purchaseKey));
    final withGap = withPanel.bottom - tester.getRect(find.text("Credits")).bottom;
    final context = tester.element(find.byType(Scaffold));
    final extent = context.onetimeMenuPurchaseButtonExtent();

    await pumpPanel(tester, "");
    final withoutPanel = panelRect(tester);
    final withoutGap = withoutPanel.bottom - tester.getRect(find.text("Credits")).bottom;

    // The button's box plus its margins is the extent being removed
    expect(withButton.height, moreOrLessEquals(extent));
    expect(withoutPanel.top, withPanel.top);
    expect(withPanel.height - withoutPanel.height, moreOrLessEquals(extent));
    // The strip under the last row is the same as with the button: no blank left behind
    expect(withoutGap, moreOrLessEquals(withGap));
  });
}
