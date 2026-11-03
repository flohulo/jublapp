// Sitzungs-Token für das `auth`-Cookie.
//
// Format: v1.<zufällige Sitzungs-ID>.<Ablauf (Unix-Sekunden)>.<Signatur>
// Signatur = HMAC-SHA256(SESSION_SECRET, "<ID>.<Ablauf>.<PIN>")
//
// * Das Token enthält weder den PIN noch einen Hash davon; ohne SESSION_SECRET
//   lässt sich daraus kein PIN ableiten und kein Token fälschen.
// * Die Signatur deckt den PIN mit ab: wird der PIN geändert, sind alle
//   bestehenden Sitzungen ungültig.
// * Die Edge Function (backend/edge-functions/auth.js) prüft dasselbe Format.
const crypto = require("crypto");

const VERSION = "v1";
const SESSION_SECONDS = 60 * 60 * 24 * 30; // 30 Tage, wie das Cookie
const MIN_SECRET_LENGTH = 32;

function config() {
  const secret = process.env.SESSION_SECRET || "";
  const pin = process.env.PIN || "";
  if (secret.length < MIN_SECRET_LENGTH || !pin) return null;
  return { secret, pin };
}

function sign(cfg, id, expires) {
  return crypto
    .createHmac("sha256", cfg.secret)
    .update(`${id}.${expires}.${cfg.pin}`)
    .digest("hex");
}

/** Sind PIN und SESSION_SECRET (mind. 32 Zeichen) gesetzt? */
function isConfigured() {
  return config() !== null;
}

/** Neues Token für eine Sitzung, oder null wenn nicht konfiguriert. */
function createSessionToken(now = Date.now) {
  const cfg = config();
  if (!cfg) return null;
  const id = crypto.randomBytes(16).toString("hex");
  const expires = Math.floor(now() / 1000) + SESSION_SECONDS;
  return `${VERSION}.${id}.${expires}.${sign(cfg, id, expires)}`;
}

/** Ist das Token echt und nicht abgelaufen? */
function verifySessionToken(token, now = Date.now) {
  const cfg = config();
  if (!cfg || typeof token !== "string") return false;
  const parts = token.split(".");
  if (parts.length !== 4 || parts[0] !== VERSION) return false;
  const [, id, expiresText, signature] = parts;
  if (!/^[0-9a-f]{32}$/.test(id) || !/^\d{1,12}$/.test(expiresText)) {
    return false;
  }
  const expires = Number(expiresText);
  if (expires <= Math.floor(now() / 1000)) return false;
  const expected = Buffer.from(sign(cfg, id, expires), "hex");
  const given = Buffer.from(signature, "hex");
  return (
    given.length === expected.length && crypto.timingSafeEqual(given, expected)
  );
}

module.exports = {
  MIN_SECRET_LENGTH,
  SESSION_SECONDS,
  createSessionToken,
  isConfigured,
  verifySessionToken,
};
