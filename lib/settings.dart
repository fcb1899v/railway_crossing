import 'dart:io';
import 'package:fab_circular_menu_plus/fab_circular_menu_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'common_extension.dart';
import 'constant.dart';
import 'plan_provider.dart';
import 'main.dart';
import 'admob_banner.dart';

class MySettingsPage extends HookConsumerWidget {
  const MySettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final width = context.width();
    final height = context.height();
    final apiKey = dotenv.get((Platform.isIOS || Platform.isMacOS) ? "REVENUE_CAT_IOS_API_KEY": "REVENUE_CAT_ANDROID_API_KEY");

    final isPremiumProvider = ref.watch(planProvider).isPremium;
    final isPremium = useState("premium".getSettingsValueBool(false));
    final isPremiumRestore = useState("premiumRestore".getSettingsValueBool(false));
    final premiumPrice = useState("premiumPrice".getSettingsValueString(""));
    final isReadError = useState(false);

    final isSelectLeft  = useState(false);
    final isSelectRight = useState(false);
    final isSelectBack  = useState(false);

    onSelectLeft() {
      isSelectLeft.value = !isSelectLeft.value;
      "isSelectLeft: ${isSelectLeft.value}".debugPrint();
    }

    onRightLeft() {
      isSelectLeft.value = !isSelectLeft.value;
      "isSelectRight: ${isSelectRight.value}".debugPrint();
    }

    getPremiumPrice() async {
      final Offerings offerings = await Purchases.getOfferings();
      if (offerings.current != null && offerings.current!.availablePackages.isNotEmpty) {
        premiumPrice.value = offerings.current!.availablePackages[0].storeProduct.priceString;
        await Settings.setValue("key_premiumPrice", premiumPrice.value);
      }
    }

    final controller = useAnimationController(
      duration: const Duration(milliseconds: 300),
    );

    final animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(controller);

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        initSettings();
        // if (!isPremiumProvider) {
        //   await Purchases.setLogLevel(LogLevel.debug);
        //   await Purchases.configure(PurchasesConfiguration(apiKey));
        //   await Purchases.enableAdServicesAttributionTokenCollection();
        //   Purchases.addReadyForPromotedProductPurchaseListener((productID, startPurchase) async {
        //     'productID: $productID'.debugPrint();
        //     try {
        //       final purchaseResult = await startPurchase.call();
        //       'productID: ${purchaseResult.productIdentifier}'.debugPrint();
        //       'customerInfo: ${purchaseResult.customerInfo}'.debugPrint();
        //     } on PlatformException catch (e) {
        //       'Error: ${e.message}'.debugPrint();
        //     }
        //   });
        //   if (premiumPrice.value == "") {
        //     try {
        //       getPremiumPrice();
        //     } on PlatformException catch (e) {
        //       isReadError.value = true;
        //       'ReadError: ${isReadError.value}, Error: ${e.message}'.debugPrint();
        //     }
        //   }
        // }
      });
      "width: $width, height: $height".debugPrint();
      "isPremiumProvider: $isPremiumProvider, isPremium: ${isPremium.value}, isPremiumRestore: ${isPremiumRestore.value}".debugPrint();
      return;
    }, const []);

    return Scaffold(
      body: Column(children: [
        Row(children: [
          SizedBox(width: context.height() * 0.05),
          IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () async => context.pushHomePage(),
          ),
          const Spacer(),
        ]),
        const Spacer(),
        // Stack(
        //   alignment: Alignment.center,
        //   children: [
        //     if (!isSelectLeft.value) FloatingActionButton(
        //       shape: const CircleBorder(),
        //       backgroundColor: blackColor,
        //       heroTag: "select_left",
        //       onPressed: () => onSelectLeft(),
        //       child: const Icon(Icons.arrow_back),  // ユニークなタグを割り当てます
        //     ),
        //   ],
        // ),
        // const Spacer(),
        // Flexible(child:
        //   SettingsList(sections: [
        //     ///Premium Plan
        //     if (!isPremiumProvider) SettingsSection(
        //       title: Text(context.upgrade()),
        //       tiles: [
        //         SettingsTile(
        //           title: Text(context.settingsPremiumTitle(premiumPrice.value, isReadError.value)),
        //           leading: premiumPrice.value.settingsPremiumLeadingIcon(isReadError.value),
        //           trailing: premiumPrice.value.settingsPremiumTrailingIcon(),
        //           onPressed: (context) => (premiumPrice.value != "") ? context.pushUpgradePage(): null,
        //         ),
        //       ]
        //     ),
        //   ]),
        // ),
        ///AdMob Banner
        if (!isPremiumProvider) const AdBannerWidget()
      ]),
      floatingActionButton: FabCircularMenuPlus(
          alignment: Alignment.center,
          ringWidth: context.height() * 0.15,
          ringDiameter: context.height() * 0.6,
          ringColor: yellowColor,
          fabCloseColor: yellowColor,
          fabOpenColor: whiteColor,
          fabOpenIcon: const Icon(Icons.menu, color: blackColor),
          fabCloseIcon: const Icon(Icons.close, color: blackColor),
          children: [
            FabCircularMenuPlus(
                alignment: Alignment.center,
                ringWidth: context.height() * 0.15,
                ringDiameter: context.height() * 0.6,
                ringColor: yellowColor,
                fabCloseColor: yellowColor,
                fabOpenColor: whiteColor,
                fabOpenIcon: const Icon(Icons.menu, color: blackColor),
                fabCloseIcon: const Icon(Icons.close, color: blackColor),
                children: [
                  GestureDetector(
                      child: SizedBox(
                        width: context.height() * 0.15,
                        child: Image.asset(flagImageJP),
                      ),
                      onTap: () {
                        'flag_jp'.debugPrint();
                      }
                  ),
                  GestureDetector(
                      child: SizedBox(
                        width: context.height() * 0.15,
                        child: Image.asset(flagImageUS),
                      ),
                      onTap: () {
                        'flag_us'.debugPrint();
                      }
                  ),
                  GestureDetector(
                      child: SizedBox(
                        width: context.height() * 0.15,
                        child: Image.asset(flagImageUK),
                      ),
                      onTap: () {
                        'flag_uk'.debugPrint();
                      }
                  ),
                ]
            ),
            GestureDetector(
              child: SizedBox(
                width: context.height() * 0.15,
                child: Image.asset(flagImageUS),
              ),
              onTap: () {
                'flag_us'.debugPrint();
              }
            ),
            GestureDetector(
              child: SizedBox(
                width: context.height() * 0.15,
                child: Image.asset(flagImageUK),
              ),
              onTap: () {
                'flag_uk'.debugPrint();
              }
            ),
          ]
      ),
    );
  }
}