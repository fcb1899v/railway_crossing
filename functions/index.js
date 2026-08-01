/**
 * Secure AI image generation for LETS CROSSING.
 * Secrets stay on the server; clients call this via Firebase Callable + App Check.
 */
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {defineSecret} = require("firebase-functions/params");
const {setGlobalOptions} = require("firebase-functions/v2");
const {GoogleAuth} = require("google-auth-library");

setGlobalOptions({
  region: "asia-northeast1",
  maxInstances: 20,
});

const openAiApiKey = defineSecret("OPEN_AI_API_KEY");

const PROJECT_ID = process.env.GCLOUD_PROJECT || "letscrossing-app";
const IMAGEN_LOCATION = "asia-northeast1";
const IMAGEN_MODEL = "imagen-4.0-fast-generate-001";
const IMAGEN_URL =
  `https://${IMAGEN_LOCATION}-aiplatform.googleapis.com/v1/projects/${PROJECT_ID}` +
  `/locations/${IMAGEN_LOCATION}/publishers/google/models/${IMAGEN_MODEL}:predict`;
const MAX_IMAGES = 2;
const MAX_PROMPT_LENGTH = 1000;
const OPENAI_MODEL = "gpt-image-2";

/**
 * Generate images with Vertex AI Imagen 4 Fast.
 * @param {string} prompt
 * @param {number} count
 * @return {Promise<string[]>} base64 image data list
 */
async function generateWithImagen(prompt, count) {
  const auth = new GoogleAuth({
    scopes: ["https://www.googleapis.com/auth/cloud-platform"],
  });
  const client = await auth.getClient();
  const accessToken = await client.getAccessToken();
  if (!accessToken.token) {
    throw new Error("Failed to obtain Google access token");
  }

  const response = await fetch(IMAGEN_URL, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${accessToken.token}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      instances: [{prompt}],
      parameters: {
        sampleCount: count,
        aspectRatio: "1:1",
        personGeneration: "allow_adult",
      },
    }),
  });

  const body = await response.json();
  if (!response.ok) {
    const message = body?.error?.message || `Imagen HTTP ${response.status}`;
    throw new Error(message);
  }

  const predictions = body?.predictions || [];
  const images = predictions
    .map((prediction) => prediction?.bytesBase64Encoded)
    .filter((data) => typeof data === "string" && data.length > 0);

  if (images.length === 0) {
    throw new Error("No images in Imagen response");
  }
  return images;
}

/**
 * @param {string} prompt
 * @param {number} count
 * @param {string} apiKey
 * @return {Promise<string[]>} base64 images
 */
async function generateWithOpenAI(prompt, count, apiKey) {
  const response = await fetch("https://api.openai.com/v1/images/generations", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: OPENAI_MODEL,
      prompt,
      n: count,
      size: "1024x1024",
    }),
  });

  const body = await response.json();
  if (!response.ok) {
    const message = body?.error?.message || `OpenAI HTTP ${response.status}`;
    throw new Error(message);
  }

  const items = body?.data || [];
  const images = [];
  for (const item of items) {
    if (item.b64_json) {
      images.push(item.b64_json);
      continue;
    }
    if (item.url) {
      const imageResponse = await fetch(item.url);
      if (!imageResponse.ok) {
        throw new Error(`Failed to download OpenAI image: ${imageResponse.status}`);
      }
      const buffer = Buffer.from(await imageResponse.arrayBuffer());
      images.push(buffer.toString("base64"));
    }
  }
  if (images.length === 0) {
    throw new Error("No images in OpenAI response");
  }
  return images;
}

exports.generateTrainPhoto = onCall(
  {
    enforceAppCheck: true,
    timeoutSeconds: 120,
    memory: "1GiB",
    secrets: [openAiApiKey],
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "Sign-in required to generate photos.",
      );
    }

    const prompt = typeof request.data?.prompt === "string" ?
      request.data.prompt.trim() :
      "";
    const count = Math.min(
      Math.max(Number(request.data?.count) || 1, 1),
      MAX_IMAGES,
    );

    if (!prompt || prompt.length > MAX_PROMPT_LENGTH) {
      throw new HttpsError("invalid-argument", "Invalid prompt.");
    }

    const images = [];
    let lastError = null;

    try {
      const imagenResults = await generateWithImagen(prompt, count);
      images.push(...imagenResults);
    } catch (error) {
      lastError = error;
      console.error("Imagen generation failed:", error?.message || error);
      try {
        const openAiImages = await generateWithOpenAI(
          prompt,
          count,
          openAiApiKey.value(),
        );
        images.push(...openAiImages);
      } catch (fallbackError) {
        console.error(
          "OpenAI fallback failed:",
          fallbackError?.message || fallbackError,
        );
        throw new HttpsError(
          "internal",
          "Image generation failed.",
          {
            imagen: String(lastError?.message || lastError),
            openai: String(fallbackError?.message || fallbackError),
          },
        );
      }
    }

    return {images};
  },
);
