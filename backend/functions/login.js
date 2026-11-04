const { corsHeaders } = require("./lib/cors");
const rateLimit = require("./lib/rate-limit");
const session = require("./lib/session");

exports.handler = async (event) => {
  const CORS = corsHeaders({ "Content-Type": "application/json" });

  if (event.httpMethod === "OPTIONS") {
    return { statusCode: 200, headers: CORS, body: "" };
  }

  if (event.httpMethod !== "POST") {
    return {
      statusCode: 405,
      headers: CORS,
      body: JSON.stringify({ error: "Method not allowed" }),
    };
  }

  let pin = "";
  if (
    event.headers["content-type"] &&
    event.headers["content-type"].includes("application/x-www-form-urlencoded")
  ) {
    const params = new URLSearchParams(event.body);
    pin = params.get("pin") || "";
  } else {
    try {
      const body = JSON.parse(event.body);
      pin = body.pin || "";
    } catch (e) {}
  }

  const expectedPin = process.env.PIN;

  // Ohne konfigurierten PIN oder SESSION_SECRET ist kein Login möglich (sonst
  // ließen sich Sitzungs-Token von jedem berechnen).
  if (!expectedPin || !session.isConfigured()) {
    console.error(
      "Login nicht möglich: PIN oder SESSION_SECRET (mind. 32 Zeichen) ist nicht gesetzt.",
    );
    return {
      statusCode: 503,
      headers: CORS,
      body: JSON.stringify({ error: "Login not configured" }),
    };
  }

  const tooMany = (retryAfter) => ({
    statusCode: 429,
    headers: { ...CORS, "Retry-After": String(retryAfter) },
    body: JSON.stringify({ error: "Too many attempts", retryAfter }),
  });

  // Fehlversuche werden pro Absender gezählt. Ist der Zähler nicht erreichbar,
  // wird der Login verweigert, statt das Raten unbegrenzt zuzulassen.
  let limiter;
  let key;
  try {
    limiter = rateLimit.getLoginLimiter(event);
    key = rateLimit.clientKey(event);
    const state = await limiter.check(key);
    if (state.blocked) return tooMany(state.retryAfter);
  } catch (e) {
    console.error("Login-Zähler nicht verfügbar:", e && e.message);
    return {
      statusCode: 503,
      headers: CORS,
      body: JSON.stringify({ error: "Login temporarily unavailable" }),
    };
  }

  if (pin === expectedPin) {
    const token = session.createSessionToken();
    try {
      await limiter.reset(key);
    } catch (e) {
      console.error("Login-Zähler konnte nicht zurückgesetzt werden:", e && e.message);
    }
    return {
      statusCode: 200,
      headers: {
        ...CORS,
        "Set-Cookie": `auth=${token}; Path=/; HttpOnly; Secure; SameSite=Lax; Max-Age=${session.SESSION_SECONDS}`,
      },
      body: JSON.stringify({ ok: true }),
    };
  }

  try {
    const state = await limiter.fail(key);
    if (state.blocked) return tooMany(state.retryAfter);
  } catch (e) {
    console.error("Fehlversuch konnte nicht gezählt werden:", e && e.message);
    return {
      statusCode: 503,
      headers: CORS,
      body: JSON.stringify({ error: "Login temporarily unavailable" }),
    };
  }

  return {
    statusCode: 401,
    headers: CORS,
    body: JSON.stringify({ error: "Invalid PIN" }),
  };
};
