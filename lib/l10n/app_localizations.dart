import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('zh')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'LETS CROSSING'**
  String get appTitle;

  /// No description provided for @thisApp.
  ///
  /// In en, this message translates to:
  /// **'This app is a realistic railway crossing simulator.'**
  String get thisApp;

  /// No description provided for @confirmed.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get confirmed;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'BACK'**
  String get back;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'CANCEL'**
  String get cancel;

  /// No description provided for @passes.
  ///
  /// In en, this message translates to:
  /// **'Train Photo Shots: {number}'**
  String passes(Object number);

  /// No description provided for @number.
  ///
  /// In en, this message translates to:
  /// **'{number}'**
  String number(Object number);

  /// No description provided for @shots.
  ///
  /// In en, this message translates to:
  /// **'{number} Left'**
  String shots(Object number);

  /// No description provided for @noPasses.
  ///
  /// In en, this message translates to:
  /// **'No Shots'**
  String get noPasses;

  /// No description provided for @oneFreePerDay.
  ///
  /// In en, this message translates to:
  /// **'1 Free Daily'**
  String get oneFreePerDay;

  /// No description provided for @album.
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get album;

  /// No description provided for @worldsFirstApp.
  ///
  /// In en, this message translates to:
  /// **'Get your own unique train photo with generative AI!'**
  String get worldsFirstApp;

  /// No description provided for @current.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get current;

  /// No description provided for @plan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get plan;

  /// No description provided for @premium.
  ///
  /// In en, this message translates to:
  /// **'Monthly Premium'**
  String get premium;

  /// No description provided for @standard.
  ///
  /// In en, this message translates to:
  /// **'Monthly Standard'**
  String get standard;

  /// No description provided for @trial.
  ///
  /// In en, this message translates to:
  /// **'Trial'**
  String get trial;

  /// No description provided for @free.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get free;

  /// No description provided for @premiumTitle.
  ///
  /// In en, this message translates to:
  /// **'Monthly\nPremium'**
  String get premiumTitle;

  /// No description provided for @standardTitle.
  ///
  /// In en, this message translates to:
  /// **'Monthly\nStandard'**
  String get standardTitle;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @ticket.
  ///
  /// In en, this message translates to:
  /// **'Train Photo Shots'**
  String get ticket;

  /// No description provided for @tickets.
  ///
  /// In en, this message translates to:
  /// **'Photo Shots'**
  String get tickets;

  /// No description provided for @ticketNumber.
  ///
  /// In en, this message translates to:
  /// **'Number of passes'**
  String get ticketNumber;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @todayPass.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Shot'**
  String get todayPass;

  /// No description provided for @oneFree.
  ///
  /// In en, this message translates to:
  /// **'1 Free'**
  String get oneFree;

  /// No description provided for @timing.
  ///
  /// In en, this message translates to:
  /// **'Grant &\nBilling'**
  String get timing;

  /// No description provided for @renewal.
  ///
  /// In en, this message translates to:
  /// **'Monthly\nRenewal'**
  String get renewal;

  /// No description provided for @immediate.
  ///
  /// In en, this message translates to:
  /// **'Immediate'**
  String get immediate;

  /// No description provided for @rollover.
  ///
  /// In en, this message translates to:
  /// **'Rollover'**
  String get rollover;

  /// No description provided for @rolloverTickets.
  ///
  /// In en, this message translates to:
  /// **'Rollover'**
  String get rolloverTickets;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get available;

  /// No description provided for @expire.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get expire;

  /// No description provided for @normally.
  ///
  /// In en, this message translates to:
  /// **'Normally '**
  String get normally;

  /// No description provided for @adFree.
  ///
  /// In en, this message translates to:
  /// **'Ad-free'**
  String get adFree;

  /// No description provided for @adDisplay.
  ///
  /// In en, this message translates to:
  /// **'Ad Display'**
  String get adDisplay;

  /// No description provided for @adFreeDate.
  ///
  /// In en, this message translates to:
  /// **'Ad-free by {date}'**
  String adFreeDate(Object date);

  /// No description provided for @freeDate.
  ///
  /// In en, this message translates to:
  /// **' by {date}'**
  String freeDate(Object date);

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'/month'**
  String get monthly;

  /// No description provided for @checkNetwork.
  ///
  /// In en, this message translates to:
  /// **'Please check your network.'**
  String get checkNetwork;

  /// No description provided for @useTickets.
  ///
  /// In en, this message translates to:
  /// **'Please use passes until {number} times or fewer remain.'**
  String useTickets(Object number);

  /// No description provided for @photos.
  ///
  /// In en, this message translates to:
  /// **'{number} times'**
  String photos(Object number);

  /// No description provided for @photoSaved.
  ///
  /// In en, this message translates to:
  /// **'Photo saved to album.'**
  String get photoSaved;

  /// No description provided for @photoCaptureFailed.
  ///
  /// In en, this message translates to:
  /// **'Photo capture failed.'**
  String get photoCaptureFailed;

  /// No description provided for @photoSavingFailed.
  ///
  /// In en, this message translates to:
  /// **'Photo saving failed.'**
  String get photoSavingFailed;

  /// No description provided for @photoAccessPermission.
  ///
  /// In en, this message translates to:
  /// **'To save train images, please allow photo full access from settings.'**
  String get photoAccessPermission;

  /// No description provided for @buy.
  ///
  /// In en, this message translates to:
  /// **'Buy'**
  String get buy;

  /// No description provided for @toBuy.
  ///
  /// In en, this message translates to:
  /// **'Buy'**
  String get toBuy;

  /// No description provided for @toUpgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get toUpgrade;

  /// No description provided for @cancelSubscription.
  ///
  /// In en, this message translates to:
  /// **'Cancel subscription'**
  String get cancelSubscription;

  /// No description provided for @buyPasses.
  ///
  /// In en, this message translates to:
  /// **'Buy Photo Shots'**
  String get buyPasses;

  /// No description provided for @upgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get upgrade;

  /// No description provided for @buyOnetimePasses.
  ///
  /// In en, this message translates to:
  /// **'Buy Additional'**
  String get buyOnetimePasses;

  /// No description provided for @onetime.
  ///
  /// In en, this message translates to:
  /// **'Additional\nPhoto Shots'**
  String get onetime;

  /// No description provided for @nextRenewal.
  ///
  /// In en, this message translates to:
  /// **'Next Renewal : {date}'**
  String nextRenewal(Object date);

  /// No description provided for @cancelPlan.
  ///
  /// In en, this message translates to:
  /// **'Cancellation, click here.'**
  String get cancelPlan;

  /// No description provided for @toRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore Subscription Plan'**
  String get toRestore;

  /// No description provided for @toOnetimeRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get toOnetimeRestore;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contactUs;

  /// No description provided for @contactUrl.
  ///
  /// In en, this message translates to:
  /// **'https://nakajimamasao-appstudio.web.app/contact/'**
  String get contactUrl;

  /// No description provided for @terms.
  ///
  /// In en, this message translates to:
  /// **'Terms and Privacy Policy'**
  String get terms;

  /// No description provided for @termsUrl.
  ///
  /// In en, this message translates to:
  /// **'https://nakajimamasao-appstudio.web.app/terms/'**
  String get termsUrl;

  /// No description provided for @premiumPlan.
  ///
  /// In en, this message translates to:
  /// **'premium plan'**
  String get premiumPlan;

  /// No description provided for @standardPlan.
  ///
  /// In en, this message translates to:
  /// **'standard plan'**
  String get standardPlan;

  /// No description provided for @addOnPlan.
  ///
  /// In en, this message translates to:
  /// **'additional photo shots'**
  String get addOnPlan;

  /// No description provided for @planPurchase.
  ///
  /// In en, this message translates to:
  /// **'Purchase of\n{plan}'**
  String planPurchase(Object plan);

  /// No description provided for @planRestore.
  ///
  /// In en, this message translates to:
  /// **'Restoration of\n{plan}.\nThe remaining photo passes cannot be restored.'**
  String planRestore(Object plan);

  /// No description provided for @planCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancellation of\n{plan}'**
  String planCancel(Object plan);

  /// No description provided for @successPurchase.
  ///
  /// In en, this message translates to:
  /// **'\nPurchase of {plan}\nhas been completed.'**
  String successPurchase(Object plan);

  /// No description provided for @successRestore.
  ///
  /// In en, this message translates to:
  /// **'\nRestoration of {plan}\nhas been completed.'**
  String successRestore(Object plan);

  /// No description provided for @successCancel.
  ///
  /// In en, this message translates to:
  /// **'\n{plan} will be canceled\non the next renewal date: {date}.'**
  String successCancel(Object date, Object plan);

  /// No description provided for @successOnetime.
  ///
  /// In en, this message translates to:
  /// **'\nPurchase of one-time passes\nhas been completed.'**
  String get successOnetime;

  /// No description provided for @successAddOn.
  ///
  /// In en, this message translates to:
  /// **'\nPurchase of additional passes\nhas been completed.'**
  String get successAddOn;

  /// No description provided for @errorPurchase.
  ///
  /// In en, this message translates to:
  /// **'Purchase error'**
  String get errorPurchase;

  /// No description provided for @errorRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore error'**
  String get errorRestore;

  /// No description provided for @errorCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel error'**
  String get errorCancel;

  /// No description provided for @finishPurchase.
  ///
  /// In en, this message translates to:
  /// **'\nThis item has already been purchased.'**
  String get finishPurchase;

  /// No description provided for @finishRestore.
  ///
  /// In en, this message translates to:
  /// **'\nThe restoration has been completed.'**
  String get finishRestore;

  /// No description provided for @finishCancel.
  ///
  /// In en, this message translates to:
  /// **'\nThe cancellation has been  completed.'**
  String get finishCancel;

  /// No description provided for @failPurchase.
  ///
  /// In en, this message translates to:
  /// **'\nNot available for purchase.'**
  String get failPurchase;

  /// No description provided for @failRestore.
  ///
  /// In en, this message translates to:
  /// **'\nThe purchase history could not be found.'**
  String get failRestore;

  /// No description provided for @failCancel.
  ///
  /// In en, this message translates to:
  /// **'\nNot available for cancellation.'**
  String get failCancel;

  /// No description provided for @purchaseCancelledMessage.
  ///
  /// In en, this message translates to:
  /// **'\nPurchase was cancelled.'**
  String get purchaseCancelledMessage;

  /// No description provided for @paymentPendingMessage.
  ///
  /// In en, this message translates to:
  /// **'\nThe payment is pending. Please check the store.'**
  String get paymentPendingMessage;

  /// No description provided for @purchaseInvalidMessage.
  ///
  /// In en, this message translates to:
  /// **'\nThis is already a pending purchase. Please check the store.'**
  String get purchaseInvalidMessage;

  /// No description provided for @purchaseNotAllowedMessage.
  ///
  /// In en, this message translates to:
  /// **'\nThe purchase was not allowed. Please check your payment method.'**
  String get purchaseNotAllowedMessage;

  /// No description provided for @networkErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'\nPlease connect to internet.'**
  String get networkErrorMessage;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
