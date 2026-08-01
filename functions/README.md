# Secure AI photo generation (Cloud Functions)

Client apps never receive the Vertex service-account JSON or the OpenAI API key.
They call `generateTrainPhoto` with Firebase Auth + App Check only.

Primary model: `imagen-4.0-fast-generate-001` (Vertex AI `:predict` in `asia-northeast1`).
Fallback: OpenAI `gpt-image-2` via Secret Manager.

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
