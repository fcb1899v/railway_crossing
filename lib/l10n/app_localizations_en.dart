// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'LETS CROSSING';

  @override
  String get thisApp => 'This app is a realistic railway crossing simulator.';

  @override
  String get confirmed => 'OK';

  @override
  String get back => 'BACK';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'CANCEL';

  @override
  String passes(Object number) {
    return 'Train Photo Shots: $number';
  }

  @override
  String number(Object number) {
    return '$number';
  }

  @override
  String shots(Object number) {
    return '$number Left';
  }

  @override
  String get noPasses => 'No Shots';

  @override
  String get oneFreePerDay => '1 Free Daily';

  @override
  String get album => 'Album';

  @override
  String get worldsFirstApp =>
      'Get your own unique train photo with generative AI!';

  @override
  String get current => 'Current';

  @override
  String get plan => 'Plan';

  @override
  String get premium => 'Monthly Premium';

  @override
  String get standard => 'Monthly Standard';

  @override
  String get trial => 'Trial';

  @override
  String get free => 'Free';

  @override
  String get premiumTitle => 'Monthly\nPremium';

  @override
  String get standardTitle => 'Monthly\nStandard';

  @override
  String get price => 'Price';

  @override
  String get ticket => 'Train Photo Shots';

  @override
  String get tickets => 'Photo Shots';

  @override
  String get ticketNumber => 'Number of passes';

  @override
  String get none => 'None';

  @override
  String get todayPass => 'Today\'s Shot';

  @override
  String get oneFree => '1 Free';

  @override
  String get timing => 'Grant &\nBilling';

  @override
  String get renewal => 'Monthly\nRenewal';

  @override
  String get immediate => 'Immediate';

  @override
  String get rollover => 'Rollover';

  @override
  String get rolloverTickets => 'Rollover';

  @override
  String get available => 'Yes';

  @override
  String get expire => 'No';

  @override
  String get normally => 'Normally ';

  @override
  String get adFree => 'Ad-free';

  @override
  String get adDisplay => 'Ad Display';

  @override
  String adFreeDate(Object date) {
    return 'Ad-free by $date';
  }

  @override
  String freeDate(Object date) {
    return ' by $date';
  }

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get monthly => '/month';

  @override
  String get checkNetwork => 'Please check your network.';

  @override
  String useTickets(Object number) {
    return 'Please use passes until $number times or fewer remain.';
  }

  @override
  String photos(Object number) {
    return '$number times';
  }

  @override
  String get photoSaved => 'Photo saved to album.';

  @override
  String get photoCaptureFailed => 'Photo capture failed.';

  @override
  String get photoSavingFailed => 'Photo saving failed.';

  @override
  String get photoAccessPermission =>
      'To save train images, please allow photo full access from settings.';

  @override
  String get buy => 'Buy';

  @override
  String get toBuy => 'Buy';

  @override
  String get toUpgrade => 'Upgrade';

  @override
  String get cancelSubscription => 'Cancel subscription';

  @override
  String get buyPasses => 'Buy Photo Shots';

  @override
  String get upgrade => 'Upgrade';

  @override
  String get buyOnetimePasses => 'Buy Additional';

  @override
  String get onetime => 'Additional\nPhoto Shots';

  @override
  String nextRenewal(Object date) {
    return 'Next Renewal : $date';
  }

  @override
  String get cancelPlan => 'Cancellation, click here.';

  @override
  String get toRestore => 'Restore Subscription Plan';

  @override
  String get toOnetimeRestore => 'Restore';

  @override
  String get contactUs => 'Contact Us';

  @override
  String get contactUrl => 'https://nakajimamasao-appstudio.web.app/contact/';

  @override
  String get terms => 'Terms and Privacy Policy';

  @override
  String get termsUrl => 'https://nakajimamasao-appstudio.web.app/terms/';

  @override
  String get premiumPlan => 'premium plan';

  @override
  String get standardPlan => 'standard plan';

  @override
  String get addOnPlan => 'additional photo shots';

  @override
  String planPurchase(Object plan) {
    return 'Purchase of\n$plan';
  }

  @override
  String planRestore(Object plan) {
    return 'Restoration of\n$plan.\nThe remaining photo passes cannot be restored.';
  }

  @override
  String planCancel(Object plan) {
    return 'Cancellation of\n$plan';
  }

  @override
  String successPurchase(Object plan) {
    return '\nPurchase of $plan\nhas been completed.';
  }

  @override
  String successRestore(Object plan) {
    return '\nRestoration of $plan\nhas been completed.';
  }

  @override
  String successCancel(Object date, Object plan) {
    return '\n$plan will be canceled\non the next renewal date: $date.';
  }

  @override
  String get successOnetime =>
      '\nPurchase of one-time passes\nhas been completed.';

  @override
  String get successAddOn =>
      '\nPurchase of additional passes\nhas been completed.';

  @override
  String get errorPurchase => 'Purchase error';

  @override
  String get errorRestore => 'Restore error';

  @override
  String get errorCancel => 'Cancel error';

  @override
  String get finishPurchase => '\nThis item has already been purchased.';

  @override
  String get finishRestore => '\nThe restoration has been completed.';

  @override
  String get finishCancel => '\nThe cancellation has been  completed.';

  @override
  String get failPurchase => '\nNot available for purchase.';

  @override
  String get failRestore => '\nThe purchase history could not be found.';

  @override
  String get failCancel => '\nNot available for cancellation.';

  @override
  String get purchaseCancelledMessage => '\nPurchase was cancelled.';

  @override
  String get paymentPendingMessage =>
      '\nThe payment is pending. Please check the store.';

  @override
  String get purchaseInvalidMessage =>
      '\nThis is already a pending purchase. Please check the store.';

  @override
  String get purchaseNotAllowedMessage =>
      '\nThe purchase was not allowed. Please check your payment method.';

  @override
  String get networkErrorMessage => '\nPlease connect to internet.';
}
