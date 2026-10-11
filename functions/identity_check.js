// Pure helpers for checking a cacheIdentity against the prompt catalog.
// No Firebase imports, so they can be tested with plain node.

const MAX_LOGGED_VALUE = 80;

/** Returns the spot name; older builds sent it as `background`. */
function spotOf(identity) {
  return identity?.spot || identity?.background;
}

/**
 * Returns which field the catalog rejects: "cacheIdentity", "country", "train" or "spot".
 * Returns null when the identity is in the catalog.
 */
function unknownIdentityField(catalog, identity) {
  if (!identity || typeof identity !== "object") {
    return "cacheIdentity";
  }
  const entry = Object.hasOwn(catalog, identity.country) ? catalog[identity.country] : null;
  if (!entry) {
    return "country";
  }
  if (identity.train !== entry.train) {
    return "train";
  }
  const spot = spotOf(identity);
  if (!spot || !entry.spots.has(spot)) {
    return "spot";
  }
  return null;
}

/** Returns the rejected value as a bounded string, or null when the field is absent. */
function rejectedValue(identity, field) {
  const raw = field === "spot" ? spotOf(identity) : identity?.[field];
  if (raw === undefined || raw === null) {
    return null;
  }
  return String(raw).slice(0, MAX_LOGGED_VALUE);
}

/**
 * Builds the one-line log for a rejected identity.
 * Only the catalog fields and the Firebase app id are logged, never a user or device identifier.
 */
function rejectionLogLine(field, identity, appId) {
  return "generateTrainPhoto rejected: invalid-argument " + JSON.stringify({
    field,
    value: rejectedValue(identity, field),
    country: rejectedValue(identity, "country"),
    appId: appId || null,
  });
}

module.exports = {unknownIdentityField, rejectionLogLine};
