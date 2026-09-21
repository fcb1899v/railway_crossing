# Secure AI photo generation (Cloud Functions)

Client apps never receive a service-account key.
They call `generateTrainPhoto` with Firebase Auth (anonymous) + App Check only.

Model: `gemini-3.1-flash-lite-image` (Vertex AI / Agent Platform `:generateContent`), served only on the `global` endpoint, whose host carries no region prefix (`aiplatform.googleapis.com`).
The function runs in `us-central1`, next to the photo cache bucket: Storage has a no-cost quota only in `us-central1`, `us-west1` and `us-east1`, and the function reads that bucket on every call.

There is no second provider and no fallback.
If Gemini fails, the call fails, and the app shows that the photo could not be taken.
Check that a model is still served before switching to it: a discontinued one answers `not found` and every call fails until someone notices.

### The server owns the prompt

The client sends `prompt`, `count`, `mode` and `cacheIdentity` (country, train, spot), but **the server ignores the prompt** and rebuilds it from `PROMPT_CATALOG`, rejecting any identity not in it, so an arbitrary string cannot reach the model.
`PROMPT_CATALOG` mirrors **two** client files — the 89 landmarks in `lib/constant.dart`, and the countries, train names and colors in `lib/common_extension.dart`, which also holds the sentence template.

Only **country, train and spot** are validated.
Change one of those on the client alone and the call fails with `invalid-argument`: a landmark breaks that one spot, a renamed train breaks every request for that country.

**Colors are not validated.**
`aiImageGenerationRequest` in `lib/common_extension.dart` writes them into the prompt string the client sends, but `generateTrainPhoto` throws that string away and calls `buildPromptFromIdentity` instead.
The identity it does read holds country, train and spot only (`cacheIdentity` in `common_extension.dart`), so the server writes its own colors into the prompt.
Change a color on one side alone and nothing fails; the photos simply keep the old color.

### Photo cache (Cloud Storage)

Generated images are stored under `train_photos/{countryHash}/{trainHash}/{spotHash}/`.

- While a key has fewer than **9** images: generate up to **3** new images (the client asks for a count, which the server clamps to 1–3) and store them.
- Once a key has **9+** images: return **2** random cached images + **1** newly generated image (also stored).
- Daily free (`mode: "daily"`): once a key has **9+** images, return **1** random cached image; below that, generate **1** and store it.

Gemini returns one image per request, so the server issues one request per image and a request for 3 can come back with 1, 2 or 3.

Legacy objects under older layouts are still counted and read until moved.
Cache folders are keyed on country, train and spot, so changing the English prompt template or the train colors does not invalidate the existing ones — which is the other reason a color change does not take effect on its own.

## One-time setup

1. Enable billing on the Firebase/GCP project (required for Functions, Vertex AI and Cloud Storage for Firebase).
2. Enable APIs: Agent Platform (`aiplatform.googleapis.com`), Cloud Functions, Cloud Build, Artifact Registry, Cloud Run.
   The Firebase CLI enables the deploy-time ones on first deploy.
3. Grant the Functions runtime service account Vertex AI access, e.g. role **Vertex AI User** (2nd gen default is usually `PROJECT_NUMBER-compute@developer.gserviceaccount.com`).
4. Enable **anonymous** sign-in (Firebase Console → Authentication).
   Every call to the function is authenticated that way.
5. Create the Firestore database and the Cloud Storage bucket.
   Only the function touches the bucket, so put it next to the function rather than next to the users.
   No-cost quotas exist only for buckets in `us-central1`, `us-west1` and `us-east1` (https://firebase.google.com/pricing, checked 2026-09-17).
6. **Recreate `firebase.json`.**
   It is not in git: `flutterfire configure` regenerates its `flutter` section, and anything regenerable stays out of the repository.
   Run `flutterfire configure`, then merge in the three sections it does not write.
   The whole file ends up like this, with the `flutter` block left exactly as the tool wrote it:

   ```json
   {
     "flutter": { "...": "written by flutterfire configure; leave it alone" },
     "firestore": { "rules": "firestore.rules" },
     "storage": { "rules": "storage.rules" },
     "functions": [
       {
         "source": "functions",
         "codebase": "default",
         "ignore": ["node_modules", ".git", "firebase-debug.log", "firebase-debug.*.log", "*.local"]
       }
     ]
   }
   ```

   `flutterfire configure` writes that file minified on one line and merges rather than overwrites, so running it again later keeps these three sections.

7. Install and deploy.
   `.firebaserc` is not committed either, so pass the project.
   **Deploy the rules too**: a new bucket defaults to `allow read, write: if request.auth != null`, and every user of this app is signed in anonymously, so the default leaves the bucket wide open.

   ```bash
   cd functions
   npm install
   cd ..
   firebase deploy --only functions,firestore:rules,storage --project <PROJECT_ID>
   ```

8. Register App Check **debug tokens** for local and emulator builds, **one per platform** (`APPCHECK_DEBUG_TOKEN_ANDROID`, `APPCHECK_DEBUG_TOKEN_IOS`).
   The app reads them from `assets/.env` through dotenv (`lib/constant.dart`), so the value registered in the console must be the value already in that file, not a freshly generated one.
   Treat a registered debug token as a credential, and revoke it if the build leaves your hands.

9. Register the **production** App Check providers.
   Debug tokens only cover emulators and simulators; a release build uses these instead (`lib/constant.dart` switches on `kDebugMode`).

   - **Android, Play Integrity.** Link the Cloud project in Play Console (App integrity → Play Integrity API).
     Up to five projects can be linked, so this is an addition rather than a swap (https://developer.android.com/google/play/integrity/setup).
     Then register the app in Firebase with the SHA-256 of the **app signing key**, not the upload key: Play re-signs what it ships, so the upload key's fingerprint passes locally and fails in production.
     Play's own guidance is to register the key Google holds with API providers (https://support.google.com/googleplay/android-developer/answer/9842756).
   - **iOS, DeviceCheck.** Register the `.p8`, its Key ID and the Team ID.
     The key is created under Account → Keys and is not tied to one app, so an existing key can be reused; Apple only lets you download it once.
     DeviceCheck does not run on simulators.
   - **Token TTL.** 30 minutes to 7 days, one hour by default.
     Replay protection (`consumeAppCheckToken`) is off here, so a leaked token stays usable until it expires: prefer the short end.
     Compare the TTL against how long one sitting with the app actually lasts: if the shortest setting already covers a session, a longer one buys nothing and only widens the window.

10. In Firebase Console → App Check → APIs, enforce App Check for Cloud Functions when ready.
    This only adds enforcement at the API layer: the functions already declare `enforceAppCheck: true` themselves, so a build whose debug token is not registered gets 403 even before you touch that setting.

## After a deploy to a new project

Check all three before shipping an app build.

1. **The model answers.**
   Call `generateTrainPhoto` once and look for the log line with `mimeType=` and `base64Length=`.
   A `not found` there means the model is not served from the endpoint in `GEMINI_LOCATIONS`.
2. **The rules are live.**
   Firebase Console → Firestore → Rules and Storage → Rules must show the files in this repo, not the defaults.
3. **Both platforms pass App Check.**
   Android and iOS use different providers, so one passing says nothing about the other.

## Rotate leaked credentials

If a service-account JSON or an API key was ever shipped in an app build:

1. Delete or disable that key in Google Cloud IAM.
2. Issue a new one and keep it server-side only.
3. Keep the JSON out of the app permanently.
