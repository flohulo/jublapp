"use strict";

// Die Web-App wird von derselben Origin ausgeliefert wie die API, die native App
// ist nicht an CORS gebunden. Deshalb wird standardmässig keine fremde Origin
// freigegeben. Nur wenn ALLOWED_ORIGIN gesetzt ist (z. B. für die lokale
// Entwicklung), wird genau diese eine Origin erlaubt.
function corsHeaders(extra = {}) {
  const headers = { "Access-Control-Allow-Headers": "Content-Type", ...extra };
  const origin = (process.env.ALLOWED_ORIGIN || "").trim();
  if (origin && origin !== "*") {
    headers["Access-Control-Allow-Origin"] = origin;
    headers.Vary = "Origin";
  }
  return headers;
}

module.exports = { corsHeaders };
