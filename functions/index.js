/**
 * Secure AI image generation for LETS CROSSING.
 * Secrets stay on the server; clients call this via Firebase Callable + App Check.
 *
 * Cache policy:
 * - Images are stored in Cloud Storage under a prompt-derived cache key.
 * - Until a key has 9 cached images, every request generates 3 new images.
 * - Once a key has 9+, return 2 from Storage + 1 newly generated image.
 * - Daily free (mode=daily): return 1 random cached image if any exist;
 *   otherwise generate 1 and store it.
 */
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {defineSecret} = require("firebase-functions/params");
const {setGlobalOptions} = require("firebase-functions/v2");
const {GoogleAuth} = require("google-auth-library");
const {initializeApp} = require("firebase-admin/app");
const {getStorage} = require("firebase-admin/storage");
const crypto = require("crypto");

initializeApp();

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
const MAX_IMAGES = 3;
const RETURN_IMAGE_COUNT = 3;
const CACHE_READY_COUNT = 9;
const CACHE_PICK_COUNT = 2;
const MAX_PROMPT_LENGTH = 1000;
const OPENAI_MODEL = "gpt-image-2";
const STORAGE_PREFIX = "train_photos";

// Reuse ADC client across warm instances to avoid token fetch on every call.
const googleAuth = new GoogleAuth({
  scopes: ["https://www.googleapis.com/auth/cloud-platform"],
});
let cachedAuthClient = null;

/**
 * @param {string} prompt
 * @return {string}
 */
function cacheKeyForPrompt(prompt) {
  return crypto.createHash("sha256").update(prompt).digest("hex").slice(0, 32);
}

/**
 * Stable cache key from semantic fields so prompt wording changes do not
 * invalidate existing Storage folders.
 * Key fields: country + train + spot (landmark background).
 * @param {Record<string, unknown>|null|undefined} identity
 * @return {string|null}
 */
function cacheKeyForIdentity(identity) {
  if (!identity || typeof identity !== "object") {
    return null;
  }
  const spot = identity.spot || identity.background;
  const parts = [
    identity.country,
    identity.train,
    spot,
  ].map((value) => String(value || "").trim().toLowerCase());
  if (parts.some((part) => part.length === 0)) {
    return null;
  }
  return crypto
      .createHash("sha256")
      .update(`v2|${parts.join("|")}`)
      .digest("hex")
      .slice(0, 32);
}

/**
 * @return {Promise<string>}
 */
async function getGoogleAccessToken() {
  if (!cachedAuthClient) {
    cachedAuthClient = await googleAuth.getClient();
  }
  const accessToken = await cachedAuthClient.getAccessToken();
  if (!accessToken.token) {
    cachedAuthClient = null;
    throw new Error("Failed to obtain Google access token");
  }
  return accessToken.token;
}

/**
 * Generate images with Vertex AI Imagen 4 Fast.
 * @param {string} prompt
 * @param {number} count
 * @return {Promise<string[]>} base64 image data list
 */
async function generateWithImagen(prompt, count) {
  const startedAt = Date.now();
  const token = await getGoogleAccessToken();

  const response = await fetch(IMAGEN_URL, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      instances: [{prompt}],
      parameters: {
        sampleCount: count,
        aspectRatio: "1:1",
        personGeneration: "allow_adult",
        outputOptions: {
          mimeType: "image/jpeg",
          compressionQuality: 85,
        },
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
  console.log(
      `Imagen ok: count=${images.length} elapsedMs=${Date.now() - startedAt}`,
  );
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

/**
 * @param {string} prompt
 * @param {number} count
 * @param {string} apiKey
 * @return {Promise<string[]>}
 */
async function generateImages(prompt, count, apiKey) {
  try {
    return await generateWithImagen(prompt, count);
  } catch (error) {
    console.error("Imagen generation failed:", error?.message || error);
    try {
      return await generateWithOpenAI(prompt, count, apiKey);
    } catch (fallbackError) {
      console.error(
          "OpenAI fallback failed:",
          fallbackError?.message || fallbackError,
      );
      throw new HttpsError(
          "internal",
          "Image generation failed.",
          {
            imagen: String(error?.message || error),
            openai: String(fallbackError?.message || fallbackError),
          },
      );
    }
  }
}

/**
 * Short stable hash for a Storage path segment.
 * @param {unknown} value
 * @return {string}
 */
function shortHash(value) {
  return crypto
      .createHash("sha256")
      .update(String(value || "").trim().toLowerCase())
      .digest("hex")
      .slice(0, 16);
}

/**
 * Storage path: train_photos/{country}/{train}/{spot}/
 * Segment names are hashes (not human-readable).
 * @param {Record<string, unknown>|null|undefined} identity
 * @param {string} cacheKey
 * @return {{country: string, train: string, spot: string, prefix: string, storagePath: string}}
 */
function storagePathFromIdentity(identity, cacheKey) {
  const spotValue = identity?.spot || identity?.background;
  if (identity?.country && identity?.train && spotValue) {
    const country = shortHash(identity.country);
    const train = shortHash(identity.train);
    const spot = shortHash(spotValue);
    return {
      country,
      train,
      spot,
      prefix: `${STORAGE_PREFIX}/${country}/${train}/${spot}/`,
      storagePath: `${country}/${train}/${spot}`,
    };
  }
  return {
    country: "unknown",
    train: cacheKey.slice(0, 16),
    spot: cacheKey.slice(16) || "spot",
    prefix: `${STORAGE_PREFIX}/unknown/${cacheKey}/`,
    storagePath: `unknown/${cacheKey}`,
  };
}

/**
 * Legacy country folder (jp / uk / cn / us) for older Storage layout.
 * @param {Record<string, unknown>|null|undefined} identity
 * @return {string|null}
 */
function legacyCountryFolder(identity) {
  const country = String(identity?.country || "").trim().toLowerCase();
  const map = {
    japan: "jp",
    "united kingdom": "uk",
    china: "cn",
    usa: "us",
    "united states": "us",
  };
  return map[country] || null;
}

/**
 * @param {{prefix: string}} pathInfo
 * @param {string} cacheKey
 * @param {Record<string, unknown>|null|undefined} identity
 * @return {Promise<import('@google-cloud/storage').File[]>}
 */
async function listCachedFiles(pathInfo, cacheKey, identity) {
  const bucket = getStorage().bucket();
  // Primary: train_photos/{country}/{train}/{spot}/
  // Legacy layouts remain readable so existing objects still count.
  const prefixes = [
    pathInfo.prefix,
    `${STORAGE_PREFIX}/${cacheKey}/`,
  ];
  const countryFolder = legacyCountryFolder(identity);
  if (countryFolder) {
    prefixes.push(`${STORAGE_PREFIX}/${countryFolder}/${cacheKey}/`);
  }
  const listed = await Promise.all(prefixes.map(async (prefix) => {
    const [files] = await bucket.getFiles({prefix});
    return files.filter((file) => !file.name.endsWith("/"));
  }));
  const byName = new Map();
  for (const file of listed.flat()) {
    byName.set(file.name, file);
  }
  return [...byName.values()];
}

/**
 * @param {string} prefix
 * @param {string} cacheKey
 * @param {string} storagePath
 * @param {string[]} base64Images
 * @return {Promise<void>}
 */
async function saveImagesToCache(prefix, cacheKey, storagePath, base64Images) {
  const bucket = getStorage().bucket();
  await Promise.all(base64Images.map(async (image, index) => {
    const objectName =
      `${prefix}${Date.now()}_${index}_${crypto.randomBytes(4).toString("hex")}.jpg`;
    await bucket.file(objectName).save(Buffer.from(image, "base64"), {
      contentType: "image/jpeg",
      resumable: false,
      metadata: {
        cacheControl: "public,max-age=31536000",
        metadata: {
          cacheKey,
          storagePath,
        },
      },
    });
  }));
}

/**
 * @param {import('@google-cloud/storage').File[]} files
 * @param {number} pickCount
 * @return {Promise<string[]>}
 */
async function loadRandomCachedImages(files, pickCount) {
  const shuffled = [...files].sort(() => Math.random() - 0.5);
  const selected = shuffled.slice(0, Math.min(pickCount, shuffled.length));
  const images = await Promise.all(selected.map(async (file) => {
    const [buffer] = await file.download();
    return buffer.toString("base64");
  }));
  return images;
}

/**
 * @param {string[]} images
 * @return {string[]}
 */
function shuffleImages(images) {
  return [...images].sort(() => Math.random() - 0.5);
}

/**
 * Lightweight App Check / Auth probe.
 * Client waits for this to succeed (server logs app:VALID) before enabling photo capture.
 */
exports.pingAppCheck = onCall(
  {
    enforceAppCheck: true,
    timeoutSeconds: 15,
    memory: "256MiB",
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError(
          "unauthenticated",
          "Sign-in required.",
      );
    }
    console.log(
        `pingAppCheck ok uid=${request.auth.uid} ` +
        `app=${request.app ? "VALID" : "MISSING"}`,
    );
    return {
      ok: true,
      uid: request.auth.uid,
      appCheck: request.app ? "VALID" : "MISSING",
    };
  },
);

exports.generateTrainPhoto = onCall(
  {
    enforceAppCheck: true,
    timeoutSeconds: 120,
    memory: "1GiB",
    minInstances: 1,
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
    // Client may still send count; server enforces return size / cache policy.
    const requestedCount = Math.min(
        Math.max(Number(request.data?.count) || RETURN_IMAGE_COUNT, 1),
        MAX_IMAGES,
    );

    if (!prompt || prompt.length > MAX_PROMPT_LENGTH) {
      throw new HttpsError("invalid-argument", "Invalid prompt.");
    }

    const callStartedAt = Date.now();
    const mode = request.data?.mode === "daily" ? "daily" : "standard";
    const cacheIdentity = request.data?.cacheIdentity;
    const identityKey = cacheKeyForIdentity(cacheIdentity);
    const cacheKey = identityKey || cacheKeyForPrompt(prompt);
    const pathInfo = storagePathFromIdentity(cacheIdentity, cacheKey);
    console.log(
        `mode=${mode} cacheKey=${cacheKey} storagePath=${pathInfo.storagePath} ` +
        `source=${identityKey ? "identity" : "prompt"}`,
    );
    if (cacheIdentity) {
      console.log(`cacheIdentity=${JSON.stringify(cacheIdentity)}`);
    }
    const cachedFiles = await listCachedFiles(
        pathInfo,
        cacheKey,
        cacheIdentity,
    );
    const cachedCount = cachedFiles.length;

    let images = [];
    let usedCache = false;

    if (mode === "daily") {
      // Daily free: prefer 1 cached image; generate 1 only when none exist.
      if (cachedCount > 0) {
        images = await loadRandomCachedImages(cachedFiles, 1);
        usedCache = true;
        console.log(
            `Daily cache hit: path=${pathInfo.storagePath} ` +
            `cached=${cachedCount} picked=${images.length}`,
        );
      } else {
        const generated = await generateImages(
            prompt,
            1,
            openAiApiKey.value(),
        );
        await saveImagesToCache(
            pathInfo.prefix,
            cacheKey,
            pathInfo.storagePath,
            generated,
        );
        images = generated.slice(0, 1);
        console.log(
            `Daily cache miss: path=${pathInfo.storagePath} generated=1`,
        );
      }
    } else {
      const useCache = cachedCount >= CACHE_READY_COUNT;
      usedCache = useCache;
      console.log(
          `cacheKey=${cacheKey} storagePath=${pathInfo.storagePath} ` +
          `cachedCount=${cachedCount} useCache=${useCache} ` +
          `threshold=${CACHE_READY_COUNT}`,
      );

      if (useCache) {
        const cachedImages = await loadRandomCachedImages(
            cachedFiles,
            CACHE_PICK_COUNT,
        );
        const generated = await generateImages(
            prompt,
            1,
            openAiApiKey.value(),
        );
        await saveImagesToCache(
            pathInfo.prefix,
            cacheKey,
            pathInfo.storagePath,
            generated,
        );
        images = shuffleImages([...cachedImages, ...generated]).slice(
            0,
            RETURN_IMAGE_COUNT,
        );
        console.log(
            `Cache hit: path=${pathInfo.storagePath} cached=${cachedCount} ` +
            `picked=${cachedImages.length} generated=1`,
        );
      } else {
        const generated = await generateImages(
            prompt,
            requestedCount,
            openAiApiKey.value(),
        );
        await saveImagesToCache(
            pathInfo.prefix,
            cacheKey,
            pathInfo.storagePath,
            generated,
        );
        images = generated.slice(0, RETURN_IMAGE_COUNT);
        console.log(
            `Cache building: path=${pathInfo.storagePath} before=${cachedCount} ` +
            `generated=${generated.length}`,
        );
      }
    }

    console.log(
        `generateTrainPhoto done: mode=${mode} count=${images.length} ` +
        `usedCache=${usedCache} elapsedMs=${Date.now() - callStartedAt}`,
    );
    return {
      images,
      cacheKey,
      storagePath: pathInfo.storagePath,
      cachedCount,
      usedCache,
      mode,
    };
  },
);
