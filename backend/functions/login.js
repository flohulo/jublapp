const rateLimit = require("./lib/rate-limit");

exports.handler = async (event) => {
  const CORS = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "Content-Type",
    "Content-Type": "application/json",
  };

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

  // Ohne konfigurierten PIN ist kein Login möglich (sonst wäre das Token mit
  // leerem Schlüssel von jedem berechenbar).
  if (!expectedPin) {
    console.error("Login nicht möglich: Umgebungsvariable PIN ist nicht gesetzt.");
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
    const { getExpectedToken } = require("./lib/auth");
    const token = getExpectedToken();
    try {
      await limiter.reset(key);
    } catch (e) {
      console.error("Login-Zähler konnte nicht zurückgesetzt werden:", e && e.message);
    }
    return {
      statusCode: 200,
      headers: {
        ...CORS,
        "Set-Cookie": `auth=${token}; Path=/; HttpOnly; Secure; SameSite=Lax; Max-Age=${60 * 60 * 24 * 30}`, // 30 days
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
