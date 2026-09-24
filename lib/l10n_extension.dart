// ===== L10nContextExt: localization helpers (part of extension.dart) =====
part of 'extension.dart';

extension L10nContextExt on BuildContext {
  /// ===== LOCALE AND LANGUAGE METHODS =====
  // Get current locale for internationalization
  Locale locale() => Localizations.localeOf(this);
  String lang() => locale().languageCode;

  /// ===== DATE FORMATTING METHODS =====
  // Format date according to country and language preferences
  String toCountryDate(int countryNumber, int date) =>
    (lang() == "ja") ? "${date.toDate().year}/${date.toDate().month}/${date.toDate().day}":
    (lang() == "zh") ? "${date.toDate().year}年${date.toDate().month}月${date.toDate().day}日":
    (countryNumber == 1) ? "${date.toDate().day} ${monthList[date.toDate().month - 1]} ${date.toDate().year}":
    "${monthList[date.toDate().month - 1]} ${date.toDate().day}, ${date.toDate().year}";

  // Format date without year according to country and language preferences
  String toCountryDateNoYear(int countryNumber, int date) =>
    (lang() == "ja") ? "${date.toDate().month}/${date.toDate().day}":
    (lang() == "zh") ? "${date.toDate().month}月${date.toDate().day}日":
    (countryNumber == 1) ? "${date.toDate().day} ${monthList[date.toDate().month - 1]}":
    "${monthList[date.toDate().month - 1]} ${date.toDate().day}";

  /// ===== LOCALIZATION METHODS =====
  // Get localized strings for app interface
  String appTitle() => AppLocalizations.of(this)!.appTitle;
  String thisApp() => AppLocalizations.of(this)!.thisApp;
  String ok() => AppLocalizations.of(this)!.ok;
  String cancel() => AppLocalizations.of(this)!.cancel;
  String shots(String number) => AppLocalizations.of(this)!.shots(number);
  String noPasses() => AppLocalizations.of(this)!.noPasses;
  String oneFree() => AppLocalizations.of(this)!.oneFree;
  String checkNetwork() => AppLocalizations.of(this)!.checkNetwork;
  String useTickets(int number) => AppLocalizations.of(this)!.useTickets(number);

  // Get photo shots text based on current date and ticket availability
  String photoShots(int currentDate, int lastClaimedDate, int tickets) =>
      !lastClaimedDate.isToday(currentDate) ? oneFree():
      (tickets < 1) ? noPasses():
      shots("$tickets");

  // Photo-related localized strings
  String photoSaved() => AppLocalizations.of(this)!.photoSaved;
  String photoCaptureFailed() => AppLocalizations.of(this)!.photoCaptureFailed;
  String photoNeedsConnection() => AppLocalizations.of(this)!.photoNeedsConnection;
  String photoSavingFailed() => AppLocalizations.of(this)!.photoSavingFailed;
  String photoAccessPermission() => AppLocalizations.of(this)!.photoAccessPermission;
  String progressSyncTitle() => AppLocalizations.of(this)!.progressSyncTitle;
  String progressSyncMessageIOS() => AppLocalizations.of(this)!.progressSyncMessageIOS;
  String progressSyncMessageAndroid() => AppLocalizations.of(this)!.progressSyncMessageAndroid;
  String progressSyncMessage() => (Platform.isIOS || Platform.isMacOS) ? progressSyncMessageIOS(): progressSyncMessageAndroid();
  String progressSyncDoNotShowAgain() => AppLocalizations.of(this)!.progressSyncDoNotShowAgain;
  String progressSyncOpenSettings() => AppLocalizations.of(this)!.progressSyncOpenSettings;
  String progressSyncSucceededIOS() => AppLocalizations.of(this)!.progressSyncSucceededIOS;
  String progressSyncSucceededAndroid() => AppLocalizations.of(this)!.progressSyncSucceededAndroid;
  String progressSyncSucceeded() => (Platform.isIOS || Platform.isMacOS) ? progressSyncSucceededIOS(): progressSyncSucceededAndroid();
  String progressSyncFailed() => AppLocalizations.of(this)!.progressSyncFailed;

  /// ===== MENU LOCALIZATION METHODS =====
  // Menu-related localized strings
  String upgrade() => AppLocalizations.of(this)!.upgrade;
  String buyPasses() => AppLocalizations.of(this)!.buyPasses;
  String purchasePlan(String plan) =>
    (plan == premiumID) ? buyOnetimePasses():
    (plan == standardID) ? upgrade():
    buyPasses();
  String ticket() => AppLocalizations.of(this)!.ticket;
  String todayPass() => AppLocalizations.of(this)!.todayPass;
  String ticketsLeft(int currentDate, int lastClaimedDate) =>
      !lastClaimedDate.isToday(currentDate) ? todayPass() : ticketNumber();
  String none() => AppLocalizations.of(this)!.none;
  String oneFreePerDay() => AppLocalizations.of(this)!.oneFreePerDay;
  String number(int tickets) => AppLocalizations.of(this)!.number(tickets);
  String menuTicketsNumber(int tickets, int currentDate, int lastClaimedDate) =>
    !lastClaimedDate.isToday(currentDate) ? oneFreePerDay():
    (tickets > 0) ? number(tickets):
    none();
  String buyOnetimePasses() => AppLocalizations.of(this)!.buyOnetimePasses;
  String purchaseButtonText(String plan, bool isOnetime, bool isCancel) =>
    isCancel ? cancelSubscription():
    isOnetime ? buyOnetimePasses():
    (plan == standardID) ? toUpgrade():
    toBuy();
  String contactUs() => AppLocalizations.of(this)!.contactUs;
  String contactUrl() => AppLocalizations.of(this)!.contactUrl;
  String terms() => AppLocalizations.of(this)!.terms;
  String termsUrl() => AppLocalizations.of(this)!.termsUrl;

  /// ===== PLAN TABLE LOCALIZATION METHODS =====
  // Plan table-related localized strings
  String worldsFirstApp() => AppLocalizations.of(this)!.worldsFirstApp;
  String current() => AppLocalizations.of(this)!.current;
  String plan() => AppLocalizations.of(this)!.plan;
  String tickets() => AppLocalizations.of(this)!.tickets;
  String ticketNumber() => AppLocalizations.of(this)!.ticketNumber;
  String trial() => AppLocalizations.of(this)!.trial;
  String onetime() => AppLocalizations.of(this)!.onetime;
  String timing() => AppLocalizations.of(this)!.timing;
  String rollover() => AppLocalizations.of(this)!.rollover;
  String rolloverTickets() => AppLocalizations.of(this)!.rolloverTickets;
  String adFree() => AppLocalizations.of(this)!.adFree;
  String adDisplay() => AppLocalizations.of(this)!.adDisplay;
  String adFreeDate(String date) => AppLocalizations.of(this)!.adFreeDate(date);
  String freeDate(String date) => AppLocalizations.of(this)!.freeDate(date);
  String price() => AppLocalizations.of(this)!.price;
  String buy() => AppLocalizations.of(this)!.buy;
  List<String> purchaseDataTitleList(String planID) =>
      (planID == freeID) ? [plan(), tickets(), timing(), rollover(), adFree(), price(), buy()]:
      [current(), plan(), tickets(), adFree()];
  List<String> upgradeDataTitleList() => [current(), plan(), tickets(), adFree(), price()];
  List<String> onetimeDataTitleList() => [onetime(), rolloverTickets(), price()];

  /// ===== TICKET AND PLAN DATA METHODS =====
  // Ticket-related localized strings
  String photos(int number) => (number == 0) ? "-" : AppLocalizations.of(this)!.photos(number);

  // Plan-related localized strings
  String premium() => AppLocalizations.of(this)!.premium;
  String standard() => AppLocalizations.of(this)!.standard;
  String free() => AppLocalizations.of(this)!.free;
  String premiumTitle() => AppLocalizations.of(this)!.premiumTitle;
  String standardTitle() => AppLocalizations.of(this)!.standardTitle;
  String currentPlanTitle(String currentPlan) =>
      "${(currentPlan == premiumID) ? premium() : (currentPlan == standardID) ? standard() : free()} ${plan()}";
  List<String> purchasePlanList(String plan) =>
      (plan == freeID) ? [premiumTitle(), standardTitle(), trial(), free()]:
      [premiumTitle(), standardTitle(), free()];
  List<String> upgradePlanList() => [premiumTitle(), standardTitle()];

  // Timing-related localized strings
  String renewal() => AppLocalizations.of(this)!.renewal;
  String immediate() => AppLocalizations.of(this)!.immediate;
  List<String> timingList() => [renewal(), renewal(), immediate(), "-"];

  // Rollover-related localized strings
  String available() => AppLocalizations.of(this)!.available;
  String expire() => AppLocalizations.of(this)!.expire;
  List<String> purchaseRolloverList(String plan) =>
      (plan == freeID) ? [expire(), expire(), available(), "-"]: [expire(), expire(), "-"];

  // Ad-free-related localized strings
  String yes() => AppLocalizations.of(this)!.yes;
  String no() => AppLocalizations.of(this)!.no;
  String adFreeText(String plan) => (plan == premiumID) ? yes() : no();
  String onetimeAdFreeText(int currentDate, int expirationDate) =>
      (currentDate > expirationDate) ? yes() : no();
  List<String> purchaseAdFreeList(String plan) =>
      (plan == freeID) ? [yes(), no(), no(), no()] : [yes(), no(), no()];
  List<String> upgradeAdFreeList() => [yes(), no()];

  // Price-related localized strings
  String monthly() => AppLocalizations.of(this)!.monthly;
  String toBuy() => AppLocalizations.of(this)!.toBuy;
  String toUpgrade() => AppLocalizations.of(this)!.toUpgrade;
  String cancelSubscription() => AppLocalizations.of(this)!.cancelSubscription;
  String nextRenewal(String date) => AppLocalizations.of(this)!.nextRenewal(date);
  String cancelPlan() => AppLocalizations.of(this)!.cancelPlan;
  String otherSelectPlan(String plan) => (plan == freeID) ? toRestore() : cancelPlan();

  /// ===== REVENUECAT LOCALIZATION METHODS =====
  // RevenueCat purchase-related localized strings
  String toRestore() => AppLocalizations.of(this)!.toRestore;
  String toOnetimeRestore() => AppLocalizations.of(this)!.toOnetimeRestore;
  String premiumPlan() => AppLocalizations.of(this)!.premiumPlan;
  String standardPlan() => AppLocalizations.of(this)!.standardPlan;
  String onetimePlan() => AppLocalizations.of(this)!.addOnPlan;
  String planName(String planID) =>
    (planID == premiumID) ? premiumPlan():
    (planID == standardID) ? standardPlan():
    onetimePlan();
  String planPurchase(String planID) =>
      AppLocalizations.of(this)!.planPurchase(planName(planID));
  String planRestore(String planID) =>
      AppLocalizations.of(this)!.planRestore(planName(planID));
  String planCancel(String planID) =>
      AppLocalizations.of(this)!.planCancel(planName(planID));
  String planPurchaseTitle(String planID, bool isRestore, bool isCancel) =>
      isRestore ? planRestore(planID):
      isCancel ? planCancel(planID):
      planPurchase(planID);
  String successPurchase(String planID) =>
      AppLocalizations.of(this)!.successPurchase(planName(planID));
  String successRestore(String planID) =>
      AppLocalizations.of(this)!.successRestore(planName(planID));
  String successCancel(String planID, int expirationDate) =>
      AppLocalizations.of(this)!
          .successCancel(planName(planID), expirationDate);
  String successPurchaseMessage(String planID, int? expirationDate, bool isRestore, bool isCancel) =>
      isRestore ? successRestore(planID):
      isCancel ? successCancel(planID, expirationDate!):
      successPurchase(planID);
  String successOnetime() => AppLocalizations.of(this)!.successOnetime;
  String successAddOn() => AppLocalizations.of(this)!.successAddOn;
  String errorPurchase() => AppLocalizations.of(this)!.errorPurchase;
  String errorRestore() => AppLocalizations.of(this)!.errorRestore;
  String errorCancel() => AppLocalizations.of(this)!.errorCancel;
  String errorPurchaseTitle(bool isRestore, bool isCancel) =>
      isRestore ? errorRestore():
      isCancel ? errorCancel():
      errorPurchase();
  String finishPurchase() => AppLocalizations.of(this)!.finishPurchase;
  String finishRestore() => AppLocalizations.of(this)!.finishRestore;
  String finishCancel() => AppLocalizations.of(this)!.finishCancel;
  String finishPurchaseMessage(bool isRestore, bool isCancel) =>
      isRestore ? finishRestore():
      isCancel ? finishCancel():
      finishPurchase();
  String failPurchase() => AppLocalizations.of(this)!.failPurchase;
  String failRestore() => AppLocalizations.of(this)!.failRestore;
  String failCancel() => AppLocalizations.of(this)!.failCancel;
  String failPurchaseMessage(bool isRestore, bool isCancel) =>
      isRestore ? failRestore():
      isCancel ? failCancel():
      failPurchase();
  String purchaseCancelledMessage() => AppLocalizations.of(this)!.purchaseCancelledMessage;
  String paymentPendingMessage() => AppLocalizations.of(this)!.paymentPendingMessage;
  String purchaseInvalidMessage() => AppLocalizations.of(this)!.purchaseInvalidMessage;
  String purchaseNotAllowedMessage() => AppLocalizations.of(this)!.purchaseNotAllowedMessage;
  String networkErrorMessage() => AppLocalizations.of(this)!.networkErrorMessage;
  String purchaseErrorMessage(PurchasesErrorCode errorCode, bool isRestore, bool isCancel) =>
      (errorCode == PurchasesErrorCode.purchaseCancelledError) ? purchaseCancelledMessage():
      (errorCode == PurchasesErrorCode.paymentPendingError) ? paymentPendingMessage():
      (errorCode == PurchasesErrorCode.purchaseInvalidError) ? purchaseInvalidMessage():
      (errorCode == PurchasesErrorCode.purchaseNotAllowedError) ? purchaseNotAllowedMessage():
      (errorCode == PurchasesErrorCode.networkError) ? networkErrorMessage():
      failPurchaseMessage(isRestore, isCancel);
  String onetimePurchaseErrorMessage(PurchasesErrorCode errorCode) =>
      (errorCode == PurchasesErrorCode.purchaseCancelledError) ? purchaseCancelledMessage():
      (errorCode == PurchasesErrorCode.paymentPendingError) ? paymentPendingMessage():
      (errorCode == PurchasesErrorCode.purchaseInvalidError) ? purchaseInvalidMessage():
      (errorCode == PurchasesErrorCode.purchaseNotAllowedError) ? purchaseNotAllowedMessage():
      (errorCode == PurchasesErrorCode.networkError) ? networkErrorMessage():
      failPurchase();
}
