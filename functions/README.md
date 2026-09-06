# Secure AI photo generation (Cloud Functions)

Client apps never receive the Vertex service-account JSON or the OpenAI API key.
They call `generateTrainPhoto` with Firebase Auth + App Check only.

Primary model: `gemini-2.5-flash-image` (Vertex AI `:generateContent`), tried in
`asia-northeast1` first and then `us-central1`. On 2026-09-03 both observed
requests were refused in Tokyo and served from us-central1.
Fallback: OpenAI `gpt-image-2` via Secret Manager.

`imagen-4.0-fast-generate-001` was the primary model until 2026-09-03. It was
discontinued on 2026-06-30, and every call between then and the migration
failed. `generateWithImagen()` is still in the file but is no longer called.
See `03_Developer/technical/2026-09-03_generate_train_photo_outage.md` in the
company repo.

### Photo cache (Cloud Storage)

Generated JPEGs are stored under:
`train_photos/{countryHash}/{trainHash}/{spotHash}/`

- While a key has fewer than **9** images: generate **3** new images and store them.
- Once a key has **9+** images: return **2** random cached images + **1** newly generated image (also stored).
- Daily free (`mode: "daily"`): once a key has **9+** images, return **1** random cached image; below that, generate **1** and store it.

Gemini answers one request per image, so a request for 3 can come back with 1,
2 or 3. Imagen's `sampleCount` used to make the count all-or-nothing.

Legacy objects under older layouts are still counted/read until moved.
Changing the English prompt template or train colors does not invalidate existing cache folders.

## One-time setup

1. Enable billing on the `letscrossing-app` Firebase/GCP project (required for Functions + Vertex AI; free tier still applies for small usage).
2. Enable APIs: Cloud Functions, Cloud Build, Secret Manager, Vertex AI.
3. Grant the Functions runtime service account Vertex AI access, e.g. role **Vertex AI User** on:
   - `x-service-account@letscrossing-app.iam.gserviceaccount.com`
   - (2nd gen default is often `PROJECT_NUMBER-compute@developer.gserviceaccount.com`)
4. Store the OpenAI key (fallback only):

```bash
firebase functions:secrets:set OPEN_AI_API_KEY
```

5. Install and deploy:

```bash
cd functions
npm install
cd ..
firebase deploy --only functions
```

6. Register App Check **debug tokens** for local/emulator builds (Android/iOS Debug providers).
7. In Firebase Console → App Check → APIs, enforce App Check for Cloud Functions when ready.

## Rotate leaked credentials

If `assets/letscrossing-app-*.json` or an old OpenAI key was ever shipped in an app build:

1. Delete/disable that service-account key in Google Cloud IAM.
2. Rotate `OPEN_AI_API_KEY` in Secret Manager.
3. Keep the JSON out of the app permanently.
