// import 'dart:io';
// import 'package:flutter/services.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:railroad_crossing/audio_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'common_extension.dart';
import 'common_function.dart';
import 'common_widget.dart';
import 'constant.dart';
import 'main.dart';
import 'purchase_manager.dart';

// Menu Button Widget - Handles menu functionality and purchase options
class MenuButton extends HookConsumerWidget {
  const MenuButton({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {

    /// ===== PROVIDER STATE MANAGEMENT =====
    // Watch provider states for reactive updates
    final countryNumber = ref.watch(countryProvider);
    final tickets = ref.watch(ticketsProvider);
    final currentDate = ref.watch(currentProvider);
    final expirationDate = ref.watch(expirationProvider);
    final lastClaimedDate = ref.watch(lastClaimedProvider);
    final isLoading = ref.watch(loadingProvider);

    /// ===== MENU STATE VARIABLES =====
    // Menu-related state variables for UI control
    final isMenuOpen = useState(false);
    final lifecycle = useAppLifecycleState();

    /// ===== PURCHASE STATE VARIABLES =====
    // Purchase-related state variables for in-app purchases
    final passesPrice = useState(defaultPrice);
    // final priceList = useState(defaultPriceList);
    // final currentPlan = useState(freeID);
    // final activePlan = useState<List<String>>([]);
    // final isLoadedSubscriptionInfo = useState(false);
    // final counter = useState(0);

    /// ===== MANAGER AND WIDGET INITIALIZATION =====
    // Initialize managers and widgets for audio and menu functionality
    final audioManager = useMemoized(() => AudioManager());
    final purchaseManager = useMemoized(() => PurchaseManager(context: context));
    final common = CommonWidget(context: context);
    final menu = MenuWidget(
      context: context,
      isMenuOpen: isMenuOpen.value,
      countryNumber: countryNumber,
      tickets: tickets,
      currentDate: currentDate,
      lastClaimedDate: lastClaimedDate,
      expirationDate: expirationDate,
    );

    /// ===== APP LIFECYCLE MANAGEMENT =====
    // Handle app lifecycle changes (pause, resume) to stop audio
    useEffect(() {
      Future<void> handleLifecycleChange() async {
        if (!context.mounted) return;
        if (lifecycle == AppLifecycleState.inactive || lifecycle == AppLifecycleState.paused) {
          try {
            await audioManager.stopAll();
          } catch (e) {
            'Error handling stop for player: $e'.debugPrint();
          }
        }
      }
      handleLifecycleChange();
      return null;
    }, [lifecycle, context.mounted]);

    /// ===== INITIALIZATION METHODS =====
    // Initialize app state and load saved preferences
    initState() async {
      "initState".debugPrint();
      final prefs = await SharedPreferences.getInstance();
      passesPrice.value = await purchaseManager.loadOnetimePrice(prefs);
      // currentPlan.value = "plan".getSharedPrefString(prefs, freeID);
      // activePlan.value = "activePlan".getSharedPrefListString(prefs, []);
      // priceList.value = await loadPriceList(prefs);
    }

    // Initialize app
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await initState();
        // await loadSubscriptionInfo();
      });
      return null;
    }, const []);

    /// ===== MENU CONTROL METHODS =====
    // Toggle menu open/close state
    openMenu() async {
      // if (isLoadedSubscriptionInfo.value) {
        audioManager.playEffectSound(openSound);
        isMenuOpen.value = !isMenuOpen.value;
      // }
    }

    /// ===== PURCHASE MANAGEMENT METHODS =====
    // Set one-time purchase plan and update user state
    onetimeSetPlan() async {
      "onetimeSetPlan".debugPrint();
      final prefs = await SharedPreferences.getInstance();
      final newCurrentDate = await getServerDateTime();
      final addedTickets = tickets + addOnTicketNumber;
      "tickets".setSharedPrefInt(prefs, addedTickets);
      "expiration".setSharedPrefInt(prefs, newCurrentDate.nextMonth());
      ref.read(ticketsProvider.notifier).update(addedTickets);
      ref.read(currentProvider.notifier).update(newCurrentDate);
      ref.read(expirationProvider.notifier).update(newCurrentDate.nextMonth());
      if (context.mounted) context.pushHomePage();
    }

    // Buy one-time passes through RevenueCat
    Future<void> buyOnetimeAction() async {
      if (!isLoading) {
        ref.read(loadingProvider.notifier).update(true);
        try {
          final CustomerInfo? purchaseInfo = await purchaseManager.buyOnetime();
          (purchaseInfo == null) ? menu.onetimePurchaseErrorDialog(): await onetimeSetPlan();
          ref.read(loadingProvider.notifier).update(false);
        } catch (e) {
          menu.onetimePurchaseErrorDialog();
          ref.read(loadingProvider.notifier).update(false);
        }
      }
    }

    // Show one-time purchase dialog or snackbar
     void toBuyOnetime() {
      isMenuOpen.value = false;
      "isMenuOpen: ${isMenuOpen.value}".debugPrint();
      (tickets > onetimeTicketLimitNumber) ?
      common.showSnackBar(context.useTickets(onetimeTicketLimitNumber), true):
      menu.buyOnetimeDialog(price: passesPrice.value, onTap: () => buyOnetimeAction());
    }

    /// ===== CURRENTLY NOT USE FUNCTIONS =====
    // // isShowAd: (currentPlan.value != premiumID)
    // setPlan({
    //   required String newPlan,
    //   required List<String> newActivePlanList,
    //   required int newTickets,
    //   required int newExpirationDate
    // }) async {
    //   "setPlan: $newPlan".debugPrint();
    //   currentPlan.value = newPlan;
    //   activePlan.value = newActivePlanList;
    //   ref.read(ticketsProvider.notifier).state = newTickets;
    //   ref.read(expirationProvider.notifier).state = newExpirationDate;
    //   final prefs = await SharedPreferences.getInstance();
    //   "plan".setSharedPrefString(prefs, newPlan);
    //   "activePlan".setSharedPrefListString(prefs, newActivePlanList);
    //   "tickets".setSharedPrefInt(prefs, newTickets);
    //   'expiration'.setSharedPrefInt(prefs, newExpirationDate);
    // }
    //
    // loadPurchaseInfo() async {
    //   if (currentDate > expirationDate) {
    //     try {
    //       "loadPurchaseInfo".debugPrint();
    //       final customerInfo = await Purchases.getCustomerInfo();
    //       await setPlan(
    //         newPlan: currentPlan.value,
    //         newActivePlanList: activePlan.value,
    //         newTickets: tickets + customerInfo.addTicket(),
    //         newExpirationDate: expirationDate.nextMonth(),
    //       );
    //       "Grant tickets: ${customerInfo.planID()}".debugPrint();
    //       isLoadedSubscriptionInfo.value = true;
    //       "isLoadedSubscriptionInfo: ${isLoadedSubscriptionInfo.value}".debugPrint();
    //     } on PlatformException catch (e) {
    //       "Failed to load subscription information: $e".debugPrint();
    //       isLoadedSubscriptionInfo.value = false;
    //       "isLoadedSubscriptionInfo: ${isLoadedSubscriptionInfo.value}".debugPrint();
    //       counter.value += 1;
    //       if (!isLoadedSubscriptionInfo.value && counter.value < 10) {
    //         Future.delayed(const Duration(seconds: 10), () {
    //           //loadSubscriptionInfo();
    //           if (context.mounted && counter.value == 9) common.showSnackBar(context.checkNetwork(), true);
    //         });
    //       }
    //     }
    //   } else if (currentPlan.value != freeID && activePlan.value.isEmpty && currentDate > expirationDate) {
    //     "loadSubscriptionInfo: Cancel".debugPrint();
    //     await setPlan(
    //       newPlan: freeID,
    //       newActivePlanList: [],
    //       newTickets: 0,
    //       newExpirationDate: defaultIntDateTime,
    //     );
    //     isLoadedSubscriptionInfo.value = true;
    //     "isLoadedSubscriptionInfo: ${isLoadedSubscriptionInfo.value}".debugPrint();
    //   } else {
    //     isLoadedSubscriptionInfo.value = true;
    //     "isLoadedSubscriptionInfo: ${isLoadedSubscriptionInfo.value}".debugPrint();
    //   }
    // }
    //
    // loadSubscriptionInfo() async {
    //   if (currentPlan.value != freeID && activePlan.value.isNotEmpty && currentDate > expirationDate) {
    //     try {
    //       "loadSubscriptionInfo: Update".debugPrint();
    //       final customerInfo = await Purchases.getCustomerInfo();
    //       await setPlan(
    //         newPlan: customerInfo.updatedPlan(),
    //         newActivePlanList: customerInfo.activeSubscriptions,
    //         newTickets: (expirationDate == defaultDateTime.intDateTime()) ? tickets: customerInfo.addTicket(),
    //         newExpirationDate: customerInfo.subscriptionExpirationDate(),
    //       );
    //       "Grant tickets: ${customerInfo.planID()}".debugPrint();
    //       isLoadedSubscriptionInfo.value = true;
    //       "isLoadedSubscriptionInfo: ${isLoadedSubscriptionInfo.value}".debugPrint();
    //     } on PlatformException catch (e) {
    //       "Failed to load subscription information: $e".debugPrint();
    //       isLoadedSubscriptionInfo.value = false;
    //       "isLoadedSubscriptionInfo: ${isLoadedSubscriptionInfo.value}".debugPrint();
    //       counter.value += 1;
    //       if (!isLoadedSubscriptionInfo.value && counter.value < 10) {
    //         Future.delayed(const Duration(seconds: 10), () {
    //           loadSubscriptionInfo();
    //           if (context.mounted && counter.value == 9) common.showSnackBar(context.checkNetwork(), true);
    //         });
    //       }
    //     }
    //   } else if (currentPlan.value != freeID && activePlan.value.isEmpty && currentDate > expirationDate) {
    //     "loadSubscriptionInfo: Cancel".debugPrint();
    //     await setPlan(
    //       newPlan: freeID,
    //       newActivePlanList: [],
    //       newTickets: 0,
    //       newExpirationDate: defaultIntDateTime,
    //     );
    //     isLoadedSubscriptionInfo.value = true;
    //     "isLoadedSubscriptionInfo: ${isLoadedSubscriptionInfo.value}".debugPrint();
    //   } else {
    //     isLoadedSubscriptionInfo.value = true;
    //     "isLoadedSubscriptionInfo: ${isLoadedSubscriptionInfo.value}".debugPrint();
    //   }
    // }
    //
    // //Revenue cat Subscription
    // //Buy subscription plan
    // buySubscriptionPlan(String planID) async {
    //   if (!isLoading) {
    //     ref.read(loadingProvider.notifier).update(true);
    //     "isLoading: $isLoading".debugPrint();
    //     if (currentPlan.value != planID && tickets <= premiumTicketNumber) {
    //       try {
    //         "Buy: $planID: ${activePlan.value.contains(planID)}".debugPrint();
    //         if (!activePlan.value.contains(planID)) {
    //           final purchaseResult = await purchaseManager.getPurchaseResult(offering: planID.offeringID(), isSubscription: true);
    //           final newCurrentTime = await getServerDateTime();
    //           ref.read(currentProvider.notifier).state = newCurrentTime;
    //           if (purchaseResult.isSubscriptionActive(planID)) {
    //             if (Platform.isIOS || Platform.isMacOS) {
    //               final originalPurchaseDate = DateTime.parse(purchaseResult.originalPurchaseDate!);
    //               "originalPurchaseDate: $originalPurchaseDate".debugPrint();
    //               await setPlan(
    //                 newPlan: planID,
    //                 newActivePlanList: purchaseResult.activeSubscriptions,
    //                 newTickets: tickets + planID.appleUpdatedTickets(currentDate.toDate(), originalPurchaseDate),
    //                 newExpirationDate: purchaseResult.subscriptionExpirationDate()
    //               );
    //             } else {
    //               await setPlan(
    //                 newPlan: planID,
    //                 newActivePlanList: purchaseResult.activeSubscriptions,
    //                 newTickets: tickets + planID.updatedTickets(currentDate.toDate()),
    //                 newExpirationDate: purchaseResult.subscriptionExpirationDate()
    //               );
    //             }
    //             if (context.mounted) context.pushHomePage();
    //           } else {
    //             if (context.mounted) purchaseManager.purchaseErrorDialog(isRestore: false, isCancel: false);
    //           }
    //         } else{
    //           if (context.mounted) purchaseManager.purchaseFinishedDialog(isRestore: false, isCancel: false);
    //         }
    //       } on PlatformException catch (e) {
    //         if (context.mounted) purchaseManager.purchaseExceptionDialog(e: e, isRestore: false, isCancel: false);
    //       }
    //     } else {
    //       if (context.mounted) context.pushHomePage();
    //       common.showSnackBar(context.useTickets(premiumTicketNumber), true);
    //     }
    //   }
    // }
    //
    // upgradePlan() async {
    //   if (context.mounted) context.popPage();
    //   if (!isLoading) {
    //     ref.read(loadingProvider.notifier).update(true);
    //     "isLoading: $isLoading".debugPrint();
    //     if (currentPlan.value != premiumID && tickets <= premiumTicketNumber) {
    //       try {
    //         "Upgrade: $premiumID: ${activePlan.value.contains(premiumID)}".debugPrint();
    //         if (!activePlan.value.contains(premiumID)) {
    //           final offerings = await Purchases.getOfferings();
    //           final offering = offerings.getOffering(premiumID.offeringID());
    //           final purchaseResult = await Purchases.purchasePackage(
    //             offering!.monthly!,
    //             googleProductChangeInfo: GoogleProductChangeInfo(standardID)
    //           );
    //           "activePlan: ${purchaseResult.activeSubscriptions}".debugPrint();
    //           if (purchaseResult.isSubscriptionActive(premiumID)) {
    //             await setPlan(
    //               newPlan: premiumID,
    //               newActivePlanList: purchaseResult.activeSubscriptions,
    //               newTickets: tickets + premiumTicketNumber,
    //               newExpirationDate: purchaseResult.subscriptionExpirationDate()
    //             );
    //             if (context.mounted) context.pushHomePage();
    //           } else {
    //             if (context.mounted) purchaseManager.purchaseErrorDialog(isRestore: false, isCancel: false);
    //           }
    //         } else{
    //           if (context.mounted) purchaseManager.purchaseFinishedDialog(isRestore: false, isCancel: false);
    //         }
    //       } on PlatformException catch (e) {
    //         if (context.mounted) purchaseManager.purchaseExceptionDialog(e: e, isRestore: false, isCancel: false);
    //       }
    //     } else {
    //       if (context.mounted) context.pushHomePage();
    //       common.showSnackBar(context.useTickets(premiumTicketNumber), true);
    //     }
    //   }
    // }
    //
    // //Buy trial passes
    // buyTrial() async {
    //   if (!isLoading) {
    //     ref.read(loadingProvider.notifier).update(true);
    //     "isLoading: $isLoading".debugPrint();
    //     if (tickets <= 1) {
    //       try {
    //         "buyOnetime".debugPrint();
    //         final offerings = await Purchases.getOfferings();
    //         final offering = offerings.getOffering(defaultOffering);
    //         final purchaseResult = await Purchases.purchasePackage(offering!.lifetime!);
    //         "${purchaseResult.allPurchasedProductIdentifiers}".debugPrint();
    //         if (purchaseResult.allPurchasedProductIdentifiers.isNotEmpty) {
    //           await setPlan(
    //             newPlan: currentPlan.value,
    //             newActivePlanList: [],
    //             newTickets: trialTicketNumber,
    //             newExpirationDate: expirationDate,
    //           );
    //           if (context.mounted) context.pushHomePage();
    //         } else {
    //           if (context.mounted) purchaseManager.purchaseErrorDialog(isRestore: false, isCancel: false);
    //         }
    //       } on PlatformException catch (e) {
    //         if (context.mounted) purchaseManager.purchaseExceptionDialog(e: e, isRestore: false, isCancel: false);
    //       }
    //     } else {
    //       if (context.mounted) context.pushHomePage();
    //       common.showSnackBar(context.useTickets(1), true);
    //     }
    //   }
    // }
    //
    // //Cancellation page for subscription
    // cancelPlan() async {
    //   if (!isLoading) {
    //     ref.read(loadingProvider.notifier).update(true);
    //     "isLoading: $isLoading".debugPrint();
    //     "activePlan: ${activePlan.value}".debugPrint();
    //     if (activePlan.value.isNotEmpty) {
    //       try {
    //         final canLaunch = await canLaunchUrl(subscriptionUri);
    //         "canLaunchUrl: $canLaunch".debugPrint();
    //         if (context.mounted) context.pushHomePage();
    //         await launchUrl(subscriptionUri, mode: LaunchMode.externalApplication);
    //       } on PlatformException catch (e) {
    //         if (context.mounted) purchaseManager.purchaseExceptionDialog(e: e, isRestore: false, isCancel: true);
    //       }
    //     } else {
    //       if (context.mounted) purchaseManager.purchaseFinishedDialog(isRestore: false, isCancel: true);
    //     }
    //   }
    // }
    //
    // Future<void> buyPremium() async {
    //   await buySubscriptionPlan(premiumID);
    // }
    //
    // Future<void> buyStandard() async {
    //   await buySubscriptionPlan(standardID);
    // }
    //
    // //Buy subscription
    // toPurchase() async {
    //   isMenuOpen.value = false;
    //   "isMenuOpen: ${isMenuOpen.value}".debugPrint();
    //   // isMyPurchase.value = true;
    // }
    //
    // //Cancel Subscription,
    // toCancel() {
    //   isMenuOpen.value = false;
    //   "isMenuOpen: ${isMenuOpen.value}".debugPrint();
    //   cancelDialog(context, currentPlan.value, cancelPlan);
    // }
    //
    // //Upgrade & Downgrade Subscription,
    // toUpgradePlan() {
    //   isMenuOpen.value = false;
    //   "isMenuOpen: ${isMenuOpen.value}".debugPrint();
    //   menu.upgradePlanDialog(currentPlan.value, priceList.value, upgradePlan);
    // }
    //
    // //Restore Button
    // toRestore() async {
    //   if (!isLoading) {
    //     ref.read(loadingProvider.notifier).update(true);
    //     try {
    //       final restoredInfo = await Purchases.restorePurchases();
    //       "activePlan: ${restoredInfo.activeSubscriptions}".debugPrint();
    //       if (restoredInfo.activeSubscriptions.isNotEmpty) { //&& currentPlan.value == freeID) {
    //         await setPlan(
    //           newPlan: restoredInfo.updatedPlan(),
    //           newActivePlanList: restoredInfo.activeSubscriptions,
    //           newTickets: tickets,
    //           newExpirationDate: restoredInfo.subscriptionExpirationDate()
    //         );
    //         if (context.mounted) purchaseManager.purchaseSubscriptionSuccessDialog(restoredInfo.planID(), expirationDate: expirationDate, isRestore: true, isCancel: false);
    //       } else {
    //         if (context.mounted) purchaseManager.purchaseErrorDialog(isRestore: true, isCancel: false);
    //       }
    //     } on PlatformException catch (e) {
    //       if (context.mounted) purchaseManager.purchaseExceptionDialog(e: e, isRestore: true, isCancel: false);
    //     }
    //   }
    // }

    /// ===== MAIN UI LAYOUT =====
    // Main UI layout with menu components
    return Stack(alignment: Alignment.centerLeft,
      children: [
        if (isMenuOpen.value && !isLoading) menu.onetimeMenuWidget(onTap: () => toBuyOnetime()),
        menu.menuButton(onTap: () => openMenu()),
        // if (isMenuOpen.value) menuWidget(context, currentPlan.value, tickets.value, countryNumber.value, currentDate.value.intDateTime(), lastClaimedDate.value, expirationDate.value, toBuyOnetime, toUpgradePlan, toPurchase, toCancel, toRestore),
        // if (isMyPurchase.value) purchaseTable(context, currentPlan.value, tickets.value, priceList.value, buyPremium, buyStandard, buyTrial),
      ],
    );
  }
}

/// Menu Widget - UI components for menu functionality
class MenuWidget {

  /// ===== WIDGET PROPERTIES =====
  final BuildContext context;
  final bool isMenuOpen;
  final int countryNumber;
  final int tickets;
  final int currentDate;
  final int lastClaimedDate;
  final int expirationDate;

  MenuWidget({
    required this.context,
    required this.isMenuOpen,
    required this.countryNumber,
    required this.tickets,
    required this.currentDate,
    required this.lastClaimedDate,
    required this.expirationDate,
  });

  CommonWidget common() => CommonWidget(context: context);

  /// ===== MENU BUTTON COMPONENTS =====
  /// Menu button widget - Floating action button for menu toggle
  Widget menuButton({
    required void Function() onTap
  }) => Container(
      alignment: Alignment.topLeft,
      margin: EdgeInsets.symmetric(
      horizontal: context.fabSideMargin(),
      vertical: context.fabTopMargin(),
    ),
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        width: context.fabSize(),
        height: context.fabSize(),
        decoration: BoxDecoration(
          color: isMenuOpen ? transpColor: transpBlackColor,
          shape: BoxShape.circle,
          border: Border.all(color: isMenuOpen ? transpColor: whiteColor,
            width: context.fabBorderWidth(),
          ),
        ),
        child: Icon(isMenuOpen ? Icons.close: Icons.menu,
          color: isMenuOpen ? transpBlackColor: whiteColor,
          size: context.menuButtonIconSize(),
        ),
      ),
    ),
  );

  /// ===== ONETIME MENU COMPONENTS =====
  /// One-time purchase menu widget with purchase options
  Widget onetimeMenuWidget({
    required void Function() onTap,
  }) => Container(
    alignment: Alignment.centerLeft,
    margin: EdgeInsets.only(
      left: context.menuSideMargin(),
      bottom: context.onetimeMenuMarginBottom(),
    ),
    padding: EdgeInsets.symmetric(vertical: context.menuPaddingTop()),
    width: context.menuWidth(),
    height: context.onetimeMenuHeight(),
    decoration: BoxDecoration(
      color: transpWhiteColor,
      borderRadius: BorderRadius.circular(context.menuCornerRadius())
    ),
    child: Column(children: [
      onetimeMenuTitleText(),
      onetimeMenuTicketsLeftStatus(),
      menuDivider(),
      onetimeMenuAdFreeStatus(),
      menuDivider(),
      onetimeMenuPurchaseButton(onTap),
      Row(children: [
        creditsButton(),
        Spacer(),
        contactLink(),
      ])
    ]),
  );

  /// ===== MENU TEXT COMPONENTS =====
  /// Menu title text widget for plan display
  Widget menuTitleText(String plan) => Container(
    margin: EdgeInsets.symmetric(
        vertical: context.menuTitleMargin()
    ),
    child: Text(context.currentPlanTitle(plan),
      style: TextStyle(
        fontSize: context.menuTitleTextFontSize(),
        fontWeight: FontWeight.bold,
        fontFamily: "beon",
        color: transpBlackColor
      ),
    ),
  );

  /// Menu divider widget for visual separation
  Widget menuDivider() => Divider(
    color: transpBlackColor,
    thickness: context.menuPurchaseButtonBorderWidth(),
    height: context.menuPurchaseButtonBorderWidth(),
    indent: context.menuDividerSideMargin(),
    endIndent: context.menuDividerSideMargin(),
  );

  /// ===== EXTERNAL LINK COMPONENTS =====
  /// External link widget for opening URLs
  Widget contactLink() => GestureDetector(
    onTap: () => launchUrl(Uri.parse(context.contactUrl()), mode: LaunchMode.externalApplication),
    child: Container(
      margin: EdgeInsets.only(
        top: context.menuOtherSelectMarginTop(),
        left: context.menuOtherSelectMarginSide(),
        right: context.menuOtherSelectMarginSide(),
      ),
      alignment: Alignment.centerRight,
      child: Text(context.contactUs(),
        style: TextStyle(
          fontSize: context.menuOtherSelectFontSize(),
          color: transpBlackColor,
          decoration: TextDecoration.underline,
        ),
      ),
    ),
  );

  /// ===== CREDITS BUTTON COMPONENTS =====
  /// Credits button widget - Bottom left button for showing credits
  Widget creditsButton() => GestureDetector(
    onTap: () => showCreditsDialog(),
    child: Container(
      margin: EdgeInsets.only(
        top: context.menuOtherSelectMarginTop(),
        left: context.menuOtherSelectMarginSide(),
        right: context.menuOtherSelectMarginSide(),
      ),
      alignment: Alignment.centerRight,
      child: Text("Credits",
        style: TextStyle(
          fontSize: context.menuOtherSelectFontSize(),
          color: transpBlackColor,
          decoration: TextDecoration.underline,
        ),
      ),
    ),
  );

  // Show credits dialog
  void showCreditsDialog() => showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: '',
    barrierColor: transpBlackColor,
    transitionDuration: const Duration(milliseconds: 500),
    pageBuilder: (context, animation, _) => IntrinsicHeight(
      child: AlertDialog(
        backgroundColor: transpWhiteColor,
        title: Text("Credits",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: context.menuTitleTextFontSize(),
            color: transpBlackColor,
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(mainAxisSize: MainAxisSize.min,
          children: credits.map((credit) => 
            Container(
              margin: EdgeInsets.symmetric(vertical: context.menuTextUpDownMargin()),
              child: Text(credit,
                style: TextStyle(
                  fontSize: context.menuOtherSelectFontSize(),
                  color: transpBlackColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ).toList(),
        ),
      ),
    ),
    transitionBuilder: (context, animation, _, child) =>
      common().customFadeTransition(animation: animation, child: child),
  );

  /// ===== ONETIME MENU TEXT COMPONENTS =====
  /// One-time menu title text widget
  Widget onetimeMenuTitleText() => Container(
    margin: EdgeInsets.symmetric(
      vertical: context.menuTitleMargin()
    ),
    child: Text(context.ticket(),
      style: TextStyle(
        fontSize: context.menuTitleTextFontSize(),
        fontWeight: FontWeight.bold,
        fontFamily: "beon",
        color: transpBlackColor
      ),
    ),
  );

  // One-time menu tickets left status widget
  Widget onetimeMenuTicketsLeftStatus() => Container(
    margin: EdgeInsets.symmetric(
      horizontal: context.menuTextSideMargin(),
    ),
    alignment: Alignment.topLeft,
    child: Row(children: [
      Text(context.ticketsLeft(currentDate, lastClaimedDate),
        style: TextStyle(
          fontSize: context.menuTextFontSize(),
          color: transpBlackColor,
        ),
      ),
      const Spacer(),
      Icon(tickets.onetimeHaveTicketsIcon(lastClaimedDate.isToday(currentDate)),
        color: tickets.onetimeHaveTicketsColor(lastClaimedDate.isToday(currentDate)),
        size: context.menuIconSize(),
      ),
      SizedBox(width: context.menuIconMargin()),
      Text(context.menuTicketsNumber(tickets, currentDate, lastClaimedDate),
        style: TextStyle(
          fontSize: context.menuTextSubFontSize(),
          fontWeight: FontWeight.bold,
          fontFamily: (context.lang() == "en") ? "beon": null,
          color: transpBlackColor,
        ),
      )
    ])
  );

  // One-time menu ad-free status widget
  Widget onetimeMenuAdFreeStatus() => Container(
    margin: EdgeInsets.only(
      top: context.menuTextUpDownMargin(),
      left: context.menuTextSideMargin(),
      right: context.menuTextSideMargin(),
    ),
    alignment: Alignment.topLeft,
    child: Row(children: [
      Text(context.adDisplay(),
        style: TextStyle(
          fontSize: context.menuTextFontSize(),
          color: transpBlackColor,
        ),
      ),
      const Spacer(),
      Icon(currentDate.onetimeAdFreeIcon(expirationDate),
        color: currentDate.onetimeAdFreeIconColor(expirationDate),
        size: context.menuIconSize(),
      ),
      SizedBox(width: context.menuIconMargin()),
      Text(context.onetimeAdFreeText(currentDate, expirationDate),
        style: TextStyle(
          fontSize: context.menuTextSubFontSize(),
          fontWeight: FontWeight.bold,
          fontFamily: "beon",
          color: transpBlackColor,
        ),
      ),
      if (currentDate <= expirationDate) SizedBox(width: context.menuIconMargin()),
      if (currentDate <= expirationDate) Text(context.freeDate(context.toCountryDateNoYear(countryNumber, expirationDate)),
        style: TextStyle(
          fontSize: context.menuAdFreeDateFontSize(),
          fontWeight: FontWeight.bold,
          color: transpBlackColor,
        ),
      )
    ])
  );

  /// ===== DIALOG COMPONENTS =====
  // Show one-time purchase dialog
  void buyOnetimeDialog({
    required String price,
    required void Function() onTap
  }) => showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: '',
    barrierColor: transpBlackColor,
    transitionDuration: const Duration(milliseconds: 500),
    pageBuilder: (context, animation, _) =>
      buyOnetimeDialogWidget(price, onTap),
    transitionBuilder: (context, animation, _, child) =>
      common().customFadeTransition(animation: animation, child: child),
  );

  // One-time purchase dialog widget content
  Widget buyOnetimeDialogWidget(String price, void Function() onTap) => Center(
    child: IntrinsicHeight(
      child: AlertDialog(
        backgroundColor: transpWhiteColor,
        content: Column(children: [
          Container(
            alignment: Alignment.center,
            margin: EdgeInsets.only(top: context.purchaseTableMarginTop()),
            child: Text("${context.ticket()} : ${context.photos(addOnTicketNumber)}",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: context.onetimePurchaseTableFontSize(),
                color: transpBlackColor,
              ),
            ),
          ),
          Container(
            alignment: Alignment.center,
            margin: EdgeInsets.only(top: context.purchaseTableMarginTop()),
            child: Text(price,
              style: TextStyle(
                fontFamily: "beon",
                fontWeight: FontWeight.bold,
                fontSize: context.onetimePurchaseTableNumberFontSize(),
                color: transpBlackColor,
              ),
            ),
          ),
          Container(
            alignment: Alignment.center,
            margin: EdgeInsets.only(top: context.purchaseTableMarginTop()),
            child: Text(context.adFreeDate(context.toCountryDate(countryNumber, currentDate.nextMonth())),
              style: TextStyle(
                fontSize: context.onetimePurchaseTableSubFontSize(),
                color: transpBlackColor,
              ),
            ),
          ),
          onetimeMenuPurchaseButton(onTap)
        ]),
      ),
    ),
  );

  // One-time menu purchase button widget
  Widget onetimeMenuPurchaseButton(void Function() onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: context.menuPurchaseButtonWidth(),
      height: context.menuPurchaseButtonHeight(),
      margin: EdgeInsets.only(
        top: context.menuPurchaseButtonMargin(),
        bottom: context.menuPurchaseButtonMarginBottom(),
        ),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: transpYellowColor,
        border: Border.all(
          color: redColor,
          width: context.menuPurchaseButtonBorderWidth(),
        ),
        borderRadius: BorderRadius.circular(context.menuPurchaseButtonCornerRadius())
      ),
      child: Text(context.buyPasses(),
        style: TextStyle(
          fontSize: context.menuPurchaseButtonFontSize(),
          fontWeight: FontWeight.bold,
          fontFamily: "beon",
          color: redColor,
        ),
        textAlign: TextAlign.center,
      ),
    ),
  );

  void onetimePurchaseErrorDialog() {
    "Purchase Error".debugPrint();
    return common().customDialog(
      title: context.errorPurchase(),
      content: "",
      isPositive: false,
    );
  }
}
