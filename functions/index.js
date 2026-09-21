// AI image generation (Callable + App Check). <9 cached -> generate 3; 9+ -> 2 cached + 1 new.
// Gemini may return fewer than asked; any non-empty result consumes the ticket (photo.dart).
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {setGlobalOptions} = require("firebase-functions/v2");
const {GoogleAuth} = require("google-auth-library");
const {initializeApp} = require("firebase-admin/app");
const {getStorage} = require("firebase-admin/storage");
const crypto = require("crypto");

initializeApp();

setGlobalOptions({
  region: "us-central1",
  maxInstances: 20,
});

const PROJECT_ID = process.env.GCLOUD_PROJECT || "railway-crossing-9fca7";
// Imagen 4 Fast was discontinued 2026-06-30; we moved off it on 2026-09-03.
const GEMINI_MODEL = "gemini-3.1-flash-lite-image";
// Verified 2026-09-17: this model answers only on the global endpoint.
// us-central1 returns "not found" for both 3.1 image models.
const GEMINI_LOCATIONS = ["global"];

// The server owns the prompt wording, so anything not listed here is rejected.
// Spots mirror lib/constant.dart; countries, trains and colors mirror lib/common_extension.dart.
const PROMPT_CATALOG = {
  "Japan": {
    train: "Shinkansen N700S",
    primary: "white",
    accent: "blue",
    spots: new Set([
      "Mount Fuji and Cherry Blossoms",
      "Mount Fuji and Five-storied pagoda",
      "Tokyo Tower",
      "Himeji Castle",
      "Kinkaku-ji Temple",
      "Gassho style house of Shirakawa-go",
      "Fushimi Inari Shrine",
      "Atomic Bomb Dome",
      "Todai-ji Temple",
      "Asakusa Senso-ji Temple",
      "Kamakura Great Buddha",
      "Tsutenkaku",
      "Horyu-ji Temple",
      "Itsukushima Shrine",
      "Tenryu-ji Temple Japanese Garden",
      "Furano Lavender Fields",
      "Sapporo Snow Festival",
    ]),
  },
  "United Kingdom": {
    train: "Eurostar e320",
    primary: "blue",
    accent: "yellow and white",
    spots: new Set([
      "Big Ben",
      "Tower Bridge",
      "Stonehenge",
      "White Cliffs",
      "Forth Railway Bridge",
      "British Museum",
      "Buckingham Palace",
      "Trafalgar Square",
      "London Eye",
      "Tower of London",
      "Westminster Abbey",
      "Kew Garden with flowers",
      "St Paul's Cathedral",
      "Piccadilly Circus",
      "Kings Cross Station",
      "Greenwich Observatory",
      "Oxford University",
      "Windsor Castle",
      "Bourton on the Water",
      "Jurassic Coast",
      "Edinburgh Castle",
      "Hadrian's Wall",
      "Livepool Cathedral",
      "Old Trafford Stadium",
      "Giant's Causeway",
    ]),
  },
  "China": {
    train: "Fu Xing Hao CR400AF",
    primary: "silver",
    accent: "red and black",
    spots: new Set([
      "Great wall",
      "Tiananmen Square",
      "Shanghai",
      "Guilin",
      "Stone Forest",
      "Zhangjiajie",
      "Potala Palace",
      "Jiuzhaigou Valley",
      "Yu Garden",
      "Forbidden City",
      "Broken Bridge of West Lake",
      "Terracotta Army",
      "Lijiang old town",
      "Mogao Caves",
      "Jiulong Waterfalls",
      "Sanya Beaches",
      "Kashga old Town",
      "Shaolin Temple",
      "Dazu Rock Carvings",
      "Longmen Grottoes",
      "Temple of Heaven",
      "Summer Palace",
      "Xi'an City Wall",
      "Canton Tower",
      "Ping An Finance Centre",
    ]),
  },
  "USA": {
    train: "Amtrak Acela Express Avelia Liberty",
    primary: "white",
    accent: "blue and red",
    spots: new Set([
      "Grand Canyon",
      "Statue of Liberty",
      "Niagara Falls",
      "Times Square",
      "Golden Gate Bridge",
      "Las Vegas Strip",
      "Mount Rushmore",
      "Hollywood",
      "Yellowstone",
      "White House",
      "Brooklyn Bridge",
      "Central Park",
      "Death Valley",
      "Big Sur",
      "Capitol Building",
      "Washington Monument",
      "Kennedy Space Center",
      "Zion",
      "Kenai Fjords",
      "Hoover Dam",
      "Waikiki Beach",
      "Hawai'i Volcanoes",
    ]),
  },
};

/** Rebuilds the prompt from the identity; null when it is not in the catalog. */
function buildPromptFromIdentity(identity) {
  const entry = PROMPT_CATALOG[identity?.country];
  if (!entry || identity?.train !== entry.train) {
    return null;
  }
  const spot = identity?.spot || identity?.background;
  if (!spot || !entry.spots.has(spot)) {
    return null;
  }
  return `A square realistic scenic photo showing the entire ${entry.train} ` +
    `train. The train's primary color is ${entry.primary} and its accent ` +
    `color is ${entry.accent}. ${spot} in ${identity.country} is clearly ` +
    "visible and is the main subject of this photo.";
}

/** Vertex AI generateContent URL. The global endpoint carries no region prefix. */
function geminiUrlFor(location) {
  const host = location === "global" ?
    "aiplatform.googleapis.com" :
    `${location}-aiplatform.googleapis.com`;
  return `https://${host}/v1/projects/` +
    `${PROJECT_ID}/locations/${location}/publishers/google/models/` +
    `${GEMINI_MODEL}:generateContent`;
}

const MAX_IMAGES = 3;
const RETURN_IMAGE_COUNT = 3;
const CACHE_READY_COUNT = 9;
const CACHE_PICK_COUNT = 2;
const STORAGE_PREFIX = "train_photos";

// Reuse ADC client across warm instances to avoid token fetch on every call.
const googleAuth = new GoogleAuth({
  scopes: ["https://www.googleapis.com/auth/cloud-platform"],
});
let cachedAuthClient = null;

/** Stable cache key from country + train + spot so prompt wording changes do not
 * invalidate existing Storage folders. */
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

/** Access token for Vertex AI from application default credentials. */
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

/** Generate one image with Gemini image model (one call = one inline image part).
 * A call that finds no image logs the parts it received, since the shape is unconfirmed. */
async function generateOneWithGemini(prompt, location) {
  const token = await getGoogleAccessToken();

  const response = await fetch(geminiUrlFor(location), {
    method: "POST",
    headers: {
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      contents: [{role: "user", parts: [{text: prompt}]}],
      generationConfig: {responseModalities: ["TEXT", "IMAGE"]},
    }),
  });

  const body = await response.json();
  if (!response.ok) {
    const message = body?.error?.message || `Gemini HTTP ${response.status}`;
    const error = new Error(message);
    error.httpStatus = response.status;
    throw error;
  }

  const parts = body?.candidates?.[0]?.content?.parts || [];
  for (const part of parts) {
    const inline = part?.inlineData || part?.inline_data;
    const data = inline?.data;
    if (typeof data === "string" && data.length > 0) {
      // saveImagesToCache() stores everything as image/jpeg.
      // If this reports image/png, the cached objects are silently mislabelled for a year.
      console.log(
          `Gemini image: mimeType=${inline?.mimeType || inline?.mime_type} ` +
          `base64Length=${data.length}`,
      );
      return data;
    }
  }

  console.error(
      "Gemini returned no image. parts=",
      JSON.stringify(parts).slice(0, 1000),
  );
  throw new Error("No image in Gemini response");
}

/** Generate images with Gemini, trying each region in turn; returns base64 data. */
async function generateWithGemini(prompt, count) {
  let lastError = null;

  for (const location of GEMINI_LOCATIONS) {
    const startedAt = Date.now();
    const results = await Promise.allSettled(
        Array.from({length: count},
            () => generateOneWithGemini(prompt, location)),
    );

    const images = results
        .filter((result) => result.status === "fulfilled")
        .map((result) => result.value);

    if (images.length > 0) {
      console.log(
          `Gemini ok: location=${location} count=${images.length}/${count} ` +
          `elapsedMs=${Date.now() - startedAt}`,
      );
      return images;
    }

    const failed = results.find((result) => result.status === "rejected");
    lastError = failed?.reason || new Error("Gemini generation failed");
    console.error(
        `Gemini failed at ${location}:`, lastError.message || lastError,
    );

    // Stop only on a definite non-404 HTTP answer: quota, safety and bad request repeat in the next region.
    // Transport and parse errors fall through to it.
    const decided = typeof lastError.httpStatus === "number";
    if (decided && lastError.httpStatus !== 404) {
      break;
    }
  }

  throw lastError || new Error("Gemini generation failed");
}

/** Generate images with Gemini; returns base64 images. */
async function generateImages(prompt, count) {
  // Gemini is the only provider: Imagen was discontinued and there is no fallback
  try {
    return await generateWithGemini(prompt, count);
  } catch (error) {
    console.error("Gemini generation failed:", error?.message || error);
    throw new HttpsError("internal", "Image generation failed.", {
      gemini: String(error?.message || error),
    });
  }
}

/** Short stable hash for a Storage path segment. */
function shortHash(value) {
  return crypto
      .createHash("sha256")
      .update(String(value || "").trim().toLowerCase())
      .digest("hex")
      .slice(0, 16);
}

/** Storage path train_photos/{country}/{train}/{spot}/ with hashed segments. */
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

/** Legacy country folder (jp / uk / cn / us) for the older Storage layout. */
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

/** Lists cached files under the current and legacy Storage prefixes. */
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

/** Saves base64 images to Storage under the prefix as JPEG objects. */
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

/** Downloads pickCount random cached files as base64. */
async function loadRandomCachedImages(files, pickCount) {
  const shuffled = [...files].sort(() => Math.random() - 0.5);
  const selected = shuffled.slice(0, Math.min(pickCount, shuffled.length));
  const images = await Promise.all(selected.map(async (file) => {
    const [buffer] = await file.download();
    return buffer.toString("base64");
  }));
  return images;
}

/** Returns a shuffled copy of the image list. */
function shuffleImages(images) {
  return [...images].sort(() => Math.random() - 0.5);
}

/** Lightweight App Check / Auth probe; the client waits for it before enabling capture. */
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
    // No minInstances: an idle warm instance is billed and costs more than the images it serves at this traffic.
    memory: "1GiB",
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError(
          "unauthenticated",
          "Sign-in required to generate photos.",
      );
    }

    // The client's own prompt is ignored.
    // The server rebuilds it from the identity so no arbitrary string reaches Gemini under our project.
    const cacheIdentity = request.data?.cacheIdentity;
    const prompt = buildPromptFromIdentity(cacheIdentity);
    if (!prompt) {
      throw new HttpsError(
          "invalid-argument",
          "Unknown country, train or spot.",
      );
    }
    // Client may still send count; server enforces return size / cache policy.
    const requestedCount = Math.min(
        Math.max(Number(request.data?.count) || RETURN_IMAGE_COUNT, 1),
        MAX_IMAGES,
    );

    const callStartedAt = Date.now();
    const mode = request.data?.mode === "daily" ? "daily" : "standard";
    const identityKey = cacheKeyForIdentity(cacheIdentity);
    const cacheKey = identityKey;
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
      // Daily free: build cache until 9; then return 1 cached image only.
      const useDailyCache = cachedCount >= CACHE_READY_COUNT;
      usedCache = useDailyCache;
      console.log(
          `Daily: path=${pathInfo.storagePath} cached=${cachedCount} ` +
          `useCache=${useDailyCache} threshold=${CACHE_READY_COUNT}`,
      );
      if (useDailyCache) {
        images = await loadRandomCachedImages(cachedFiles, 1);
        console.log(
            `Daily cache hit: path=${pathInfo.storagePath} ` +
            `picked=${images.length}`,
        );
      } else {
        const generated = await generateImages(
            prompt,
            1,
        );
        await saveImagesToCache(
            pathInfo.prefix,
            cacheKey,
            pathInfo.storagePath,
            generated,
        );
        images = generated.slice(0, 1);
        console.log(
            `Daily cache building: path=${pathInfo.storagePath} ` +
            `before=${cachedCount} generated=1`,
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
