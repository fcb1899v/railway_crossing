# LETS CROSSING -- Railway Crossing Simulator

<div align="center">
  <img src="assets/icon/appIcon.png" alt="LETS CROSSING Icon" width="120" height="120">
  <br>
  <strong>Enjoy railway crossings from around the world, anytime, anywhere</strong>
  <br>
  <strong>Hyper-real railway crossing sim with authentic visuals and sounds</strong>
</div>

## 📱 Application Overview

**LETS CROSSING** is a cross-platform Flutter app for Android & iOS that lets you experience and operate railway crossings from Japan, China, the UK, and the US.
It features realistic visuals, authentic sounds, photo galleries, train illustrations, and multi-language support.

### 🎯 Key Features

- **Realistic Railway Crossing Simulation**: Authentic visuals and sounds for JP, CN, UK, US
- **Photo Gallery & Train Illustrations**: Explore real crossing photos and train images
- **Cross-platform Support**: Android & iOS compatibility
- **Multi-language Support**: Japanese, English, Chinese
- **Google Mobile Ads**: Banner ads
- **Firebase Integration**: Analytics, App Check, Auth, Firestore, Cloud Functions
- **Audio**: just_audio, with playback stopped when the app is not visible
- **Interactive UI Elements**: Blinking camera button animation and credits dialog
- **In-app Purchase**: a one-time purchase through RevenueCat adds 24 tickets and hides the ads for a month
- **Photo Tickets**: one free photo a day, more with tickets; the balance and the ad-free expiry sync through Firestore, keyed by the Game Center / Play Games player id so they survive a reinstall
- **AI Photo Generation**: a Cloud Function calls the model server-side; the app never holds a model key

## 🚀 Technology Stack

### Frameworks & Libraries
- **Flutter**: 3.47.0+
- **Dart**: 3.13.0+
- **Firebase**: Analytics, App Check, Auth, Firestore, Cloud Functions
- **Google Mobile Ads**: Banner ads
- **RevenueCat**: In-app purchase management
- **Generative AI**: `gemini-3.1-flash-lite-image`, called server-side through `cloud_functions` (see `functions/README.md`)

The model is served on the `global` endpoint only.
The function runs in `us-central1`, and the app calls that same region through `generateTrainPhotoRegion` in `lib/constant.dart`: the two have to match.

### Core Features
- **Audio**: just_audio
- **Vibration**: vibration
- **Localization**: flutter_localizations, intl
- **Environment Variables**: flutter_dotenv
- **State Management**: hooks_riverpod, flutter_hooks
- **Permissions**: permission_handler
- **Image Save**: image_gallery_saver_plus
- **WebView**: webview_flutter
- **UI Components**: fab_circular_menu_plus
- **Ticket Sync**: games_services (Game Center / Play Games), cloud_firestore

## 📋 Prerequisites

- Flutter 3.47.0+ (required by Android Gradle Plugin 9: earlier versions force the Kotlin Gradle Plugin onto modules that AGP 9 compiles itself)
- Dart 3.13.0+
- Android Studio / Xcode
- Firebase project on the Blaze plan (App Check, Analytics, Auth, Firestore, Cloud Functions)
- RevenueCat account for in-app purchases
- `firebase-tools` (`npm i -g firebase-tools`) and `flutterfire_cli` (`dart pub global activate flutterfire_cli`), then `firebase login`

## 🛠️ Setup

### 1. Clone the Repository
```bash
git clone https://github.com/fcb1899v/railway_crossing.git
cd railway_crossing
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Configuration Files Setup

**Environment variables.** Copy `assets/.env_example` to `assets/.env` and fill in the values.
The template lists every key with what it is for, and is the one place that list is maintained.
`pubspec.yaml` declares `assets/.env`, so the file has to exist or the build fails.
Debug builds use Google's demo ad units and need no real ids, and the demo unit for an inline adaptive request is not the same id as the fixed-size one.

**Android signing, release only.** Copy `android/key.properties.example` to `android/key.properties` and fill it in.
Nothing in it ships inside the app, and the two passwords are real secrets: together with the keystore they let anyone publish an update Play accepts as coming from you.
Keep the keystore outside the repository and back both up.
A release built without this file falls back to the debug signing config, which produces an artifact Play rejects.

### 4. Firebase Configuration

1. Create a Firebase project.
   The Blaze plan is required for Cloud Functions and for the image model.
2. Run `flutterfire configure`.
   It writes `google-services.json`, `GoogleService-Info.plist`, `lib/firebase_options.dart` and the `flutter` section of `firebase.json`.
   **None of those are in git**: anything regenerable stays out, and these are the files GitHub's secret scanner flags, which reports what it finds to the provider.
3. Add the sections `flutterfire configure` does not write back to `firebase.json` — `firestore`, `storage` and `functions`.
   `functions/README.md` shows the whole file, and is where the rest of the backend setup lives.
4. Enable Anonymous Authentication.
5. Deploy the functions **and the rules**.
   A new Storage bucket defaults to `allow read, write: if request.auth != null`, and every user here is signed in anonymously, so the default leaves it open.
   ```bash
   cd functions && npm install && cd ..
   firebase deploy --only functions,firestore:rules,storage --project <PROJECT_ID>
   ```
6. Register the App Check providers: debug tokens for emulators, Play Integrity and DeviceCheck for release.
   See `functions/README.md`.

### 5. Play Games and Game Center

Ticket balances are keyed on the signed-in player id, so a build without this signs nobody in and every device keeps its own balance.

1. Enable Play Games Services for the app in Play Console, and Game Center for the bundle id in App Store Connect.
2. Replace `android/app/src/main/res/values/games-ids.xml` with the file Play Console generates for your own project.
   The one in the repository carries the original project's ids.

### 6. RevenueCat

Filling in the API keys is not enough: the code asks for one offering by name.

1. Create an offering called `normal_offering` (`normalOffering` in `lib/constant.dart`).
2. Give it a **lifetime** package; `lib/purchase_manager.dart` reads `getOffering(...)?.lifetime` and throws `No package to purchase in normal_offering` when it is missing.
3. The purchase adds 24 tickets and hides the ads for a month, so the product is a consumable top-up rather than a permanent unlock.

### 7. Run the Application
```bash
# Android
flutter run

# iOS (Swift Package Manager: there is no Podfile to install)
flutter run
```

## 🎮 Application Structure

```
lib/
├── main.dart                # Application entry point
├── homepage.dart            # Main railway crossing interface
├── menu.dart                # Purchase and settings menu
├── photo.dart               # Photo capture and gallery functionality
├── common_widget.dart       # Common widgets
├── common_function.dart     # Common functions
├── common_extension.dart    # Extensions: prompts, localisation helpers, layout maths
├── constant.dart            # Constant definitions
├── audio_manager.dart       # Audio playback
├── purchase_manager.dart    # RevenueCat purchases and the price notifier
├── photo_manager.dart       # Photo gallery and AI generation management
├── ticket_manager.dart      # Photo tickets and ad-free expiry, synced to Firestore
├── admob_banner.dart        # Banner ad management
└── l10n/                    # Localization
    ├── app_en.arb
    ├── app_ja.arb
    ├── app_zh.arb
    ├── app_localizations.dart
    ├── app_localizations_en.dart
    ├── app_localizations_ja.dart
    └── app_localizations_zh.dart

assets/
├── images/                  # Image resources (crossings, trains, flags, etc.)
├── audios/                  # Audio files (crossing sounds, warnings, etc.)
├── fonts/                   # Font files
└── icon/                    # App icons
```

## 🎨 Customization

### Crossing Styles
- Multiple countries: Japan, China, UK, US
- Each with unique visuals, sounds, and warning patterns
- Realistic train animations and sound effects

### Visual Themes
- Realistic backgrounds and crossing equipment
- Photo galleries and train illustrations
- AI-generated railway crossing photos
- Interactive UI elements with blinking animations
- Credits dialog for sound attribution

### Audio Features
- Authentic warning sounds for each country
- Train passing sounds with proper looping
- Emergency sound effects

## 📱 Supported Platforms

- **Android**: API 24+ (`flutter.minSdkVersion`)
- **iOS**: iOS 15.0+ (`IPHONEOS_DEPLOYMENT_TARGET`)

## 🔧 Development

### Code Analysis
```bash
flutter analyze   # expected: No issues found!
```

### Run Tests
```bash
flutter test      # expected: All tests passed! (21 tests)
```

Three files cover the parts most likely to break: banner geometry, the menu's purchase button wiring, and what the button does while the price is still loading.

### Firebase plugin versions are pinned on purpose

Every Firebase plugin requires its own `firebase-ios-sdk` with `exact:`.
One plugin drifting to a newer version stops Swift Package Manager from resolving, and the iOS build fails outright.
All six are pinned without a caret in `pubspec.yaml`: bump them together, then check they still agree.

```bash
flutter pub get   # the check reads .dart_tool/package_config.json
python3 - <<'PY'
import json, pathlib, re
cfg = json.load(open(".dart_tool/package_config.json"))
found = 0
for p in cfg["packages"]:
    if not re.match(r"(firebase_|cloud_)", p["name"]):
        continue
    root = pathlib.Path(p["rootUri"].replace("file://", ""))
    for sw in root.glob("ios/*/Package.swift"):
        for line in sw.read_text().splitlines():
            if "let firebaseSdkVersion" in line:
                found += 1
                print(f'{p["name"]:22} {line.split(chr(34))[1]}')
print(f"{found} plugins reported a version")
PY
```

Expect six lines carrying one distinct version.
Two or more versions means the iOS build will fail; fewer than six lines means the check itself broke and says nothing about the project.

Reading the versions out of `~/.pub-cache` instead does not work: every version ever fetched is still there, so a healthy project looks broken.

### Build
```bash
# Android APK
flutter build apk

# Android App Bundle
flutter build appbundle

# iOS
flutter build ios
```

## 📄 License

This project is not open source.
The source is published so that it can be read, and all rights are reserved.
See [LICENSE](LICENSE) for what that permits.
Third-party components keep their own licenses, listed below.

## 🤝 Contributing

Issue reports are welcome.
Pull requests are not accepted, because the code is not licensed for redistribution.

## 📞 Support

If you have any problems or questions, please create an issue on GitHub.

---

<div align="center">
  <strong>LETS CROSSING</strong> - Experience the world of railway crossings!
</div>

## Licenses & Credits

This app uses the following third-party components:

- Flutter (BSD 3-Clause License)
- firebase_core, firebase_analytics, firebase_app_check, firebase_auth, cloud_firestore, cloud_functions (BSD 3-Clause License)
- google_mobile_ads (Apache License 2.0)
- Google Mobile Ads Android SDK (Android Software Development Kit License): `play-services-ads`, pulled in by google_mobile_ads
- Google Mobile Ads iOS SDK (proprietary Google binary; its CocoaPods spec declares only a Google copyright notice, with no open-source license): `Google-Mobile-Ads-SDK`, pulled in by google_mobile_ads
- User Messaging Platform, the consent SDK (Android Software Development Kit License): `com.google.android.ump:user-messaging-platform`, pulled in by google_mobile_ads
- User Messaging Platform on iOS (proprietary Google binary, declared the same way as the iOS ads SDK): `GoogleUserMessagingPlatform`, pulled in by `Google-Mobile-Ads-SDK`
- shared_preferences (BSD 3-Clause License)
- flutter_dotenv (MIT License)
- just_audio (MIT License), which bundles ExoPlayer on Android: `androidx.media3:media3-exoplayer` (Apache License 2.0)
- vibration (BSD 2-Clause License)
- hooks_riverpod, flutter_hooks (MIT License)
- url_launcher (BSD 3-Clause License)
- webview_flutter (BSD 3-Clause License)
- cupertino_icons (MIT License)
- flutter_launcher_icons (MIT License)
- flutter_native_splash (MIT License)
- intl (BSD 3-Clause License)
- flutter_localizations (BSD 3-Clause License)
- image_gallery_saver_plus (MIT License)
- permission_handler (MIT License)
- purchases_flutter (MIT License)
- games_services (MIT License)
- devicelocale (Apache License 2.0)
- device_info_plus, ntp, share_plus, http, path, path_provider, url_launcher_platform_interface, webview_flutter_android (BSD 3-Clause License)
- fab_circular_menu_plus (MIT License)

For details of each license, please refer to [pub.dev](https://pub.dev/) or the LICENSE file in each repository.
