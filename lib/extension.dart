import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'l10n/app_localizations.dart' show AppLocalizations;
import 'homepage.dart';
import 'constant.dart';

part 'l10n_extension.dart';
part 'size_extension.dart';

/// ===== BUILD CONTEXT EXTENSIONS =====
// Extensions for BuildContext (localization: L10nContextExt, sizing: SizeExt).
extension ContextExt on BuildContext {
  /// ===== NAVIGATION METHODS =====
  // Navigate to home page with fade transition
  void pushHomePage() => Navigator.pushReplacement(this,
    PageRouteBuilder(
      pageBuilder: (context, animation, _) => HomePage(),
      transitionsBuilder: (context, animation, _, child) => FadeTransition(
        opacity: animation,
        child: child,
      ),
      transitionDuration: const Duration(milliseconds: 500),
    )
  );

  // Pop current page from navigation stack
  void popPage() => Navigator.of(this).pop();

  Animation<double> leftAnimation(AnimationController leftController, bool isLeftFast) => Tween(
    begin: trainBeginPosition(isLeftFast),
    end: trainEndPosition(isLeftFast),
  ).animate(leftController);
  Animation<double> rightAnimation(AnimationController rightController, bool isRightFast) => Tween(
    begin: trainEndPosition(isRightFast),
    end: trainBeginPosition(isRightFast),
  ).animate(rightController);
}


/// ===== STRING EXTENSIONS =====
// Extensions for String to provide additional functionality
extension StringExt on String {

  /// ===== DEBUG UTILITIES =====
  // Provides debug printing functionality for development
  void debugPrint() {
    if (kDebugMode) print(this);
  }

  /// ===== SHAREDPREFERENCES HELPERS ===== (all methods log in debug builds)
  void setSharedPrefString(SharedPreferences prefs, String value) {
    "${replaceAll("Key", "")}: $value".debugPrint();
    prefs.setString(this, value);
  }
  void setSharedPrefInt(SharedPreferences prefs, int value) {
    "${replaceAll("Key", "")}: $value".debugPrint();
    prefs.setInt(this, value);
  }
  void setSharedPrefBool(SharedPreferences prefs, bool value) {
    "${replaceAll("Key", "")}: $value".debugPrint();
    prefs.setBool(this, value);
  }
  void setSharedPrefListString(SharedPreferences prefs, List<String> value) {
    "${replaceAll("Key", "")}: $value".debugPrint();
    prefs.setStringList(this, value);
  }
  void setSharedPrefListInt(SharedPreferences prefs, List<int> value) {
    for (int i = 0; i < value.length; i++) {
      prefs.setInt("$this$i", value[i]);
    }
    "${replaceAll("Key", "")}: $value".debugPrint();
  }
  void setSharedPrefListBool(SharedPreferences prefs, List<bool> value) {
    for (int i = 0; i < value.length; i++) {
      prefs.setBool("$this$i", value[i]);
    }
    "${replaceAll("Key", "")}: $value".debugPrint();
  }
  String getSharedPrefString(SharedPreferences prefs, String defaultString) {
    String value = prefs.getString(this) ?? defaultString;
    "${replaceAll("Key", "")}: $value".debugPrint();
    return value;
  }
  int getSharedPrefInt(SharedPreferences prefs, int defaultInt) {
    int value = prefs.getInt(this) ?? defaultInt;
    "${replaceAll("Key", "")}: $value".debugPrint();
    return value;
  }
  bool getSharedPrefBool(SharedPreferences prefs, bool defaultBool) {
    bool value = prefs.getBool(this) ?? defaultBool;
    "${replaceAll("Key", "")}: $value".debugPrint();
    return value;
  }
  List<String> getSharedPrefListString(SharedPreferences prefs, List<String> defaultList) {
    List<String> values = prefs.getStringList(this) ?? defaultList;
    "${replaceAll("Key", "")}: $values".debugPrint();
    return values;
  }
  List<int> getSharedPrefListInt(SharedPreferences prefs, List<int> defaultList) {
    List<int> values = [];
    for (int i = 0; i < defaultList.length; i++) {
      int v = prefs.getInt("$this$i") ?? defaultList[i];
      values.add(v);
    }
    "${replaceAll("Key", "")}: $values".debugPrint();
    return (values == []) ? defaultList: values;
  }
  List<bool> getSharedPrefListBool(SharedPreferences prefs, List<bool> defaultList) {
    List<bool> values = [];
    for (int i = 0; i < defaultList.length; i++) {
      bool v = prefs.getBool("$this$i") ?? defaultList[i];
      values.add(v);
    }
    "${replaceAll("Key", "")}: $values".debugPrint();
    return (values == []) ? defaultList : values;
  }

  /// ===== COUNTRY NUMBER METHODS =====
  // Get country number based on country code
  int getCountryNumber() {
    final countryNumber =
      (this == "JPN" || this == "JP") ? 0:
      (this == "GBR" || this == "GB") ? 1:
      (this == "CHN" || this == "CN") ? 2:
      3;
    "countryCode: $this, countryNumber: $countryNumber".debugPrint();
    return countryNumber;
  }

  /// ===== PLAN CONFIGURATION METHODS ===== (ticket allocation per plan)
  List<int> photosList() => (this == freeID) ?
    [premiumTicketNumber, standardTicketNumber, trialTicketNumber, 0]:
    [premiumTicketNumber, standardTicketNumber, 0];

  // Get rollover settings for different plans
  List<bool?> isPurchaseRolloverList() => (this == freeID) ?
    [false, false, true, null]:
    [false, false, null];

  // Get ad-free settings for different plans
  List<bool?> isPurchaseAdFreeList() => (this == freeID) ?
    [true, false, false, false]:
    [true, false, false];

  // Get ticket number for plan refresh
  int refreshTicketNumber() =>
    (this == premiumID) ? premiumTicketNumber:
    (this == standardID) ? standardTicketNumber:
    0;

  // Get plan number identifier
  int planNumber() =>
    (this == premiumID) ? 0:
    (this == standardID) ? 1:
    2;
  // Get offering ID for subscription
  String offeringID() => (this == premiumID) ? defaultOffering : premiumOffering;
  // Get user access level
  String userAccess() =>
    (this == premiumID) ? premiumUserAccess:
    (this == standardID) ? standardUserAccess:
    freeUserAccess;
  // Get updated tickets for current date
  int updatedTickets(DateTime currentDate) =>
    (this == premiumID) ? premiumTicketNumber:
    (this == standardID) ? standardTicketNumber:
    0;
  // Get Apple updated tickets with purchase date check
  int appleUpdatedTickets(DateTime currentDate, DateTime purchaseDate) =>
      (currentDate.intDiffDateTime(purchaseDate) < 1000)
          ? updatedTickets(currentDate)
          : 0;

  // Get ad-free icon based on plan
  IconData adFreeIcon() => (this == premiumID)
      ? CupertinoIcons.check_mark_circled_solid
      : CupertinoIcons.multiply_circle_fill;
  // Get ad-free icon color based on plan
  Color adFreeIconColor() => (this == premiumID) ? redColor : grayColor;
}

/// ===== CUSTOMER INFO EXTENSIONS =====
// Extensions for CustomerInfo to handle subscription and plan management
extension CustomerInfoExt on CustomerInfo {
  // Get subscription entitlement info for plan
  EntitlementInfo? subscriptionEntitlementInfo(String planID) => entitlements.all[planID.userAccess()];
  // Check if subscription is active for plan
  bool isSubscriptionActive(String planID) =>
      subscriptionEntitlementInfo(planID) == null ? false:
      subscriptionEntitlementInfo(planID)!.isActive;
  // Get current plan ID
  String planID() =>
      (isSubscriptionActive(premiumID)) ? premiumID:
      (isSubscriptionActive(standardID)) ? standardID:
      freeID;
  // Get ticket number to add based on active subscription
  int addTicket() =>
      (isSubscriptionActive(premiumID)) ? premiumTicketNumber:
      (isSubscriptionActive(standardID)) ? standardTicketNumber:
      0;
  // Get subscription expiration date
  int subscriptionExpirationDate() =>
      (subscriptionEntitlementInfo(planID()) == null) ? 20240101000000:
      DateTime.parse(subscriptionEntitlementInfo(planID())!.expirationDate!).intDateTime();

  // Get updated plan based on active subscriptions
  String updatedPlan() =>
      (isSubscriptionActive(premiumID)) ? premiumID:
      (isSubscriptionActive(standardID)) ? standardID:
      freeID;
}

/// ===== INTEGER EXTENSIONS =====
// Extensions for int to provide date/time conversion and UI utilities
extension IntExt on int {
  // Convert integer date/time to DateTime object
  DateTime toDate() {
    final year = this ~/ 10000000000;
    final month = (this % 10000000000) ~/ 100000000;
    final day = (this % 100000000) ~/ 1000000;
    final hour = (this % 1000000) ~/ 10000;
    final minute = (this % 10000) ~/ 100;
    final second = (this % 100);
    return DateTime(year, month, day, hour, minute, second);
  }

  // Check if date is today
  bool isToday(int currentDate) => (this ~/ 1000000 == currentDate ~/ 1000000);
  // Get next month DateTime
  DateTime nextMonthDateTime() => DateTime(toDate().year, toDate().month + 1,
      toDate().day, toDate().hour, toDate().minute, toDate().second);
  // Get next month as integer
  int nextMonth() => nextMonthDateTime().intDateTime();

  /// ===== TICKET ICON METHODS =====
  // Get icon for one-time tickets based on availability
  IconData onetimeHaveTicketsIcon(bool isUseTodayTicket) =>
      (this == 0 && isUseTodayTicket) ? CupertinoIcons.multiply_circle_fill:
      CupertinoIcons.star_circle_fill;
  // Get color for one-time tickets based on availability
  Color onetimeHaveTicketsColor(bool isUseTodayTicket) =>
      (this == 0 && isUseTodayTicket) ? redColor : greenColor;

  /// ===== AD-FREE ICON METHODS =====
  // Get icon for ad-free status based on expiration date
  IconData onetimeAdFreeIcon(int expirationDate) =>
      (this > expirationDate) ? CupertinoIcons.multiply_circle_fill:
      CupertinoIcons.star_circle_fill;
  // Get color for ad-free status based on expiration date
  Color onetimeAdFreeIconColor(int expirationDate) =>
      (this > expirationDate) ? redColor : greenColor;

  /// ===== ASSET PATH METHODS =====
  // Get country string for asset paths
  String countryString() =>
    (this == 0) ? "jp":
    (this == 1) ? "uk":
    (this == 2) ? "cn":
    "us";
  // Get crossing assets path
  String crossingAssets() => "assets/images/crossing/${countryString()}/";
  // Get train name for country
  String countryTrain() =>
    (this == 0) ? "n700s":
    (this == 1) ? "374":
    (this == 2) ? "cr400af":
    "avelia_liberty";
  // Generate train image list
  List<String> trainImage() => List.generate(6, (i) =>
    "assets/images/train/${countryString()}/${countryTrain()}_${i + 1}.png"
  );

  /// ===== AI PROMPT METHODS =====
  // Get train name for AI prompts
  String inputTrain() =>
    (this == 0) ? "Shinkansen N700S":
    (this == 1) ? "Eurostar e320":
    (this == 2) ? "Fu Xing Hao CR400AF":
    "Amtrak Acela Express Avelia Liberty";
  // Get train primary color for AI prompts
  String trainPrimaryColor() =>
    (this == 0) ? "white":
    (this == 1) ? "blue":
    (this == 2) ? "silver":
    "white";
  // Get train accent color for AI prompts
  String trainAccentColor() =>
    (this == 0) ? "blue":
    (this == 1) ? "yellow and white":
    (this == 2) ? "red and black":
    "blue and red";
  // Get background spots for AI prompts
  List<String> inputBackGround() =>
    (this == 0) ? jpSpot:
    (this == 1) ? ukSpot:
    (this == 2) ? cnSpot:
    usSpot;
  // Get country name for AI prompts
  String inputCountry() =>
    (this == 0) ? "Japan":
    (this == 1) ? "United Kingdom":
    (this == 2) ? "China":
    "USA";
  // Generate random number for background selection
  int randomNumber() => math.Random().nextInt(inputBackGround().length);

  /// ===== AI IMAGE GENERATION PROMPTS =====
  // Prompt text may change over time; cacheIdentity stays stable for Storage reuse.
  Map<String, dynamic> aiImageGenerationRequest() {
    final train = inputTrain();
    final primaryColor = trainPrimaryColor();
    final accentColor = trainAccentColor();
    final background = inputBackGround()[randomNumber()];
    final country = inputCountry();
    final prompt = [
      "A square realistic scenic photo showing the entire $train train. ",
      "The train's primary color is $primaryColor and its accent color is $accentColor. ",
      "$background in $country is clearly visible and is the main subject of this photo.",
    ].join();
    return {
      'prompt': prompt,
      // Cache by country + train + spot only (prompt wording/colors may change).
      'cacheIdentity': <String, String>{
        'country': country,
        'train': train,
        'spot': background,
      },
    };
  }

  // Prompt text only (legacy helper).
  String aiImagePrompt() =>
      aiImageGenerationRequest()['prompt'] as String;

  /// ===== IMAGE ASSET METHODS =====
  // Get flag image path
  String flagImage() => "assets/images/flag/${countryString()}.png";
  // Get flag map with image and country number
  Map<String, Object> flagMap() => {'image': flagImage(), 'countryNumber': this};
  // Get background image path
  String backgroundImage() => "${crossingAssets()}background.png";
  // Get pole image paths
  String poleFrontImage() => "${crossingAssets()}pole_front.png";
  String poleBackImage() => "${crossingAssets()}pole_back.png";
  // Get bar image paths
  String barFrontOff() => "${crossingAssets()}bar_front_off.png";
  String barFrontOn() => "${crossingAssets()}bar_front_on.png";
  String barBackOff() => "${crossingAssets()}bar_back_off.png";
  String barBackOn() => "${crossingAssets()}bar_back_on.png";
  // Get bar image based on wait state and index
  String barFrontImage(bool isWait, int index) =>
      isWait ? [barFrontOff(), barFrontOn()][index]: barFrontOff();
  String barBackImage(bool isWait, int index) =>
      isWait ? [barBackOff(), barBackOn()][index]: barBackOff();
  // Get bar angle based on country and wait state
  double barAngle(bool isWait) => (this == 2 || isWait) ? 0.0 : barUpAngle;
  // Get bar shift based on country and wait state
  double barShift(bool isWait) => (this == 2 && !isWait) ? 1.0 : 0.0;
  // Get warning image paths
  String warningFrontImageOff() => "${crossingAssets()}warning_off.png";
  String warningFrontImageLeft() => "${crossingAssets()}warning_left.png";
  String warningFrontImageRight() => "${crossingAssets()}warning_right.png";
  String warningFrontImageYellow() => "${crossingAssets()}warning_yellow.png";
  // Get warning image based on state
  String warningFrontImage(bool isYellow, bool isWait, int index) =>
      isYellow ? warningFrontImageYellow():
      isWait ? [warningFrontImageLeft(), warningFrontImageRight()][index]:
      warningFrontImageOff();
  String warningBackImageOff() => "${crossingAssets()}warning_back_off.png";
  String warningBackImageLeft() => "${crossingAssets()}warning_back_left.png";
  String warningBackImageRight() => "${crossingAssets()}warning_back_right.png";
  String warningBackImageYellow() => "${crossingAssets()}warning_back_yellow.png";
  String warningBackImage(bool isYellow, bool isWait, int index) =>
      isYellow ? warningBackImageYellow():
      isWait ? [warningBackImageLeft(), warningBackImageRight()][index]:
      warningBackImageOff();
  // Get direction image paths
  String directionImageOff() => "${crossingAssets()}direction_off.png";
  String directionImageLeft() => "${crossingAssets()}direction_left.png";
  String directionImageRight() => "${crossingAssets()}direction_right.png";
  String directionImageBoth() => "${crossingAssets()}direction_both.png";
  // Get direction image based on wait states
  String directionImage(bool isLeftWait, bool isRightWait) =>
    (isLeftWait && isRightWait) ? directionImageBoth():
    (isLeftWait) ? directionImageLeft():
    (isRightWait) ? directionImageRight():
    directionImageOff();
  // Get emergency image path
  String emergencyImage() => "${crossingAssets()}emergency.png";
  // Get traffic sign image path
  String signImage() => "${crossingAssets()}sign.png";
  // Get gate image paths
  String gateFrontImage() => "${crossingAssets()}gate_front.png";
  String gateBackImage() => "${crossingAssets()}gate_back.png";
  // Get fence image paths
  String fenceFrontLeftImage() => "${crossingAssets()}fence_front_left.png";
  String fenceFrontRightImage() => "${crossingAssets()}fence_front_right.png";
  String fenceBackLeftImage() => "${crossingAssets()}fence_back_left.png";
  String fenceBackRightImage() => "${crossingAssets()}fence_back_right.png";

  /// ===== AUDIO ASSET METHODS =====
  // Get sound assets path
  String soundAssets() => "assets/audios/${countryString()}/";
  // Get warning sound path
  String warningSound() => "${soundAssets()}warning_${countryString()}.mp3";

  /// ===== TIMING METHODS =====
  // Get flash time based on country
  int flashTime() => (this == 1) ? 500 : 1000;

  /// ===== BAR POSITION METHODS =====
  // Get front bar alignment X position
  double frontBarAlignmentX() =>
    (this == 0) ? 0.6947:
    (this == 1) ? 0.7637:
    (this == 2) ? 0.7637:
    (this == 3) ? 0.63:
    0.6947;
  // Get front bar alignment Y position
  double frontBarAlignmentY() =>
    (this == 0) ? -0.4122:
    (this == 1) ? -0.4122:
    (this == 2) ? -0.4122:
    (this == 3) ? -0.3:
    -0.4122;
  // Get back bar alignment X position
  double backBarAlignmentX() =>
    (this == 0) ? -0.6947:
    (this == 1) ? -0.7637:
    (this == 2) ? -0.7637:
    (this == 3) ? -0.63:
    -0.6947;
  // Get back bar alignment Y position
  double backBarAlignmentY() =>
    (this == 0) ? -0.4122:
    (this == 1) ? -0.4122:
    (this == 2) ? -0.4122:
    (this == 3) ? -0.3:
    -0.4122;
}

/// ===== BOOLEAN EXTENSIONS =====
// Extensions for bool to provide utility methods
extension BoolExt on bool {
  // Returns 1 if the value is false, 0 if true
  int isFalseNumber() => this ? 0 : 1;
}

/// ===== DATETIME EXTENSIONS =====
// Extensions for DateTime to provide formatting and difference calculation
extension DateTimeExt on DateTime {
  // Converts DateTime to int in 'yyyyMMddHHmmss' format
  int intDateTime() {
    final DateFormat formatter = DateFormat('yyyyMMddHHmmss');
    return int.parse(formatter.format(this));
  }

  // Converts DateTime to int in 'yyyyMMdd' format
  int intDate() {
    final DateFormat formatter = DateFormat('yyyyMMdd');
    return int.parse(formatter.format(this));
  }

  // Calculates the difference between two DateTime objects as an int
  // Format: MddHHmmss (M: months, dd: days, HH: hours, mm: minutes, ss: seconds)
  int intDiffDateTime(DateTime dateTime) {
    final diffDateTime = difference(dateTime);
    // Get total days difference
    final totalDays = diffDateTime.inDays;
    // Calculate months and remaining days (1 month = 30 days)
    final months = totalDays ~/ 30;
    final days = totalDays % 30;
    final hours = diffDateTime.inHours % 24;
    final minutes = diffDateTime.inMinutes % 60;
    final seconds = diffDateTime.inSeconds % 60;
    // Format each part with zero padding where needed
    final monthPart = '$months';
    final dayPart = days.toString().padLeft(2, '0');
    final hourPart = hours.toString().padLeft(2, '0');
    final minutePart = minutes.toString().padLeft(2, '0');
    final secondPart = seconds.toString().padLeft(2, '0');
    // Concatenate all parts and convert to int
    final diff = '$monthPart$dayPart$hourPart$minutePart$secondPart';
    "diffDateTime: $diff".debugPrint();
    return int.parse(diff).abs();
  }
}
