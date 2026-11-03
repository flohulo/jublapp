// Begrenzt falsche PIN-Eingaben pro Absender. Die Zähler liegen in Netlify Blobs,
// damit sie für alle Funktionsinstanzen gelten. In den Blobs steht nur ein Hash
// der IP-Adresse, nie die Adresse selbst.
const crypto = require("crypto");

const MAX_FAILURES = 5; // Fehlversuche, danach Sperre
const WINDOW_MS = 15 * 60 * 1000; // Zählfenster ab dem ersten Fehlversuch = Sperrdauer
const STORE_NAME = "login-attempts";

function clientKey(event) {
  const headers = event.headers || {};
  const ip =
    headers["x-nf-client-connection-ip"] ||
    headers["client-ip"] ||
    (headers["x-forwarded-for"] || "").split(",")[0].trim() ||
    "unknown";
  return crypto.createHash("sha256").update(ip).digest("hex");
}

/**
 * @param store  Blobs-Store (get(key, {type:"json"}), setJSON, delete)
 * @param now    Zeitquelle in ms (für Tests ersetzbar)
 */
function createLimiter(store, now = Date.now) {
  async function read(key) {
    const state = await store.get(key, { type: "json" });
    if (!state || now() - state.first >= WINDOW_MS) return null;
    return state;
  }

  function blockedResult(state) {
    return {
      blocked: true,
      retryAfter: Math.max(
        1,
        Math.ceil((state.first + WINDOW_MS - now()) / 1000),
      ),
    };
  }

  return {
    /** Ist der Absender gesperrt? */
    async check(key) {
      const state = await read(key);
      if (state && state.count >= MAX_FAILURES) return blockedResult(state);
      return { blocked: false, retryAfter: 0 };
    },
    /** Fehlversuch zählen; liefert den Stand nach dem Versuch. */
    async fail(key) {
      const state = (await read(key)) || { count: 0, first: now() };
      state.count += 1;
      await store.setJSON(key, state);
      if (state.count >= MAX_FAILURES) return blockedResult(state);
      return { blocked: false, retryAfter: 0 };
    },
    /** Nach erfolgreichem Login zurücksetzen. */
    async reset(key) {
      await store.delete(key);
    },
  };
}

/** Limiter auf dem Netlify-Blobs-Store (Lambda-kompatible Funktionen). */
function getLoginLimiter(event) {
  const { connectLambda, getStore } = require("@netlify/blobs");
  connectLambda(event);
  return createLimiter(getStore({ name: STORE_NAME, consistency: "strong" }));
}

module.exports = {
  MAX_FAILURES,
  WINDOW_MS,
  clientKey,
  createLimiter,
  getLoginLimiter,
};
