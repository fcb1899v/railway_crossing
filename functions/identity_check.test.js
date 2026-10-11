// Run with: node --test
const test = require("node:test");
const assert = require("node:assert");
const {unknownIdentityField, rejectionLogLine} = require("./identity_check");

const catalog = {
  "Japan": {train: "Shinkansen N700S", spots: new Set(["Tokyo Tower"])},
};
const ok = {country: "Japan", train: "Shinkansen N700S", spot: "Tokyo Tower"};

test("a catalog identity is accepted", () => {
  assert.strictEqual(unknownIdentityField(catalog, ok), null);
  assert.strictEqual(unknownIdentityField(catalog, {...ok, spot: undefined, background: "Tokyo Tower"}), null);
});

test("each unknown field is named", () => {
  assert.strictEqual(unknownIdentityField(catalog, undefined), "cacheIdentity");
  assert.strictEqual(unknownIdentityField(catalog, "x"), "cacheIdentity");
  assert.strictEqual(unknownIdentityField(catalog, {...ok, country: "Peru"}), "country");
  assert.strictEqual(unknownIdentityField(catalog, {...ok, country: "toString"}), "country");
  assert.strictEqual(unknownIdentityField(catalog, {...ok, train: "Old Train"}), "train");
  assert.strictEqual(unknownIdentityField(catalog, {...ok, spot: "Livepool Cathedral"}), "spot");
  assert.strictEqual(unknownIdentityField(catalog, {...ok, spot: undefined}), "spot");
});

test("the log line is one line of JSON with the field, value and app id", () => {
  const line = rejectionLogLine("spot", {...ok, spot: "Bad\nSpot"}, "1:123:ios:abc");
  assert.ok(!line.includes("\n"));
  const json = JSON.parse(line.slice(line.indexOf("{")));
  assert.deepStrictEqual(json, {field: "spot", value: "Bad\nSpot", country: "Japan", appId: "1:123:ios:abc"});
  assert.ok(line.startsWith("generateTrainPhoto rejected: invalid-argument "));
});

test("long values are cut and a missing identity logs nulls", () => {
  const long = rejectionLogLine("spot", {...ok, spot: "x".repeat(500)}, undefined);
  assert.strictEqual(JSON.parse(long.slice(long.indexOf("{"))).value.length, 80);
  const none = JSON.parse(rejectionLogLine("cacheIdentity", undefined, undefined).replace(/^[^{]*/, ""));
  assert.deepStrictEqual(none, {field: "cacheIdentity", value: null, country: null, appId: null});
});
