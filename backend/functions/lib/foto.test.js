const test = require("node:test");
const assert = require("node:assert/strict");
const { MAX_BYTES, validateFoto } = require("./foto");

const jpeg = Buffer.concat([Buffer.from([0xff, 0xd8, 0xff, 0xe0]), Buffer.alloc(32)]);
const png = Buffer.concat([Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]), Buffer.alloc(32)]);
const webp = Buffer.concat([Buffer.from("RIFF"), Buffer.alloc(4), Buffer.from("WEBP"), Buffer.alloc(16)]);

test("JPEG, PNG und WebP werden anhand der Bytes erkannt", () => {
  assert.deepEqual(
    [jpeg, png, webp].map((b) => validateFoto(b.toString("base64")).mimeType),
    ["image/jpeg", "image/png", "image/webp"],
  );
});

test("andere Dateitypen werden abgelehnt, auch bei falsch deklariertem Typ", () => {
  const html = Buffer.from("<script>alert(1)</script>, genug Text fuer 12 Bytes");
  assert.equal(validateFoto(html.toString("base64")).ok, false);
  assert.equal(validateFoto(Buffer.from("%PDF-1.7 und mehr Text").toString("base64")).ok, false);
});

test("ungültige Eingaben werden abgelehnt", () => {
  for (const value of [undefined, null, 5, "", "kein base64!", "abc"]) {
    assert.equal(validateFoto(value).ok, false);
  }
});

test("zu grosse Fotos werden abgelehnt", () => {
  const big = Buffer.concat([jpeg, Buffer.alloc(MAX_BYTES)]);
  assert.deepEqual(validateFoto(big.toString("base64")), { ok: false, error: "Foto zu gross" });
});
