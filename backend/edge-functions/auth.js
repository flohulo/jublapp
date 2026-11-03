// Prüft das Sitzungs-Token. Format und Signatur wie in
// backend/functions/lib/session.js: v1.<ID>.<Ablauf>.<HMAC-SHA256(SESSION_SECRET,
// "<ID>.<Ablauf>.<PIN>")>. Ohne PIN oder SESSION_SECRET (mind. 32 Zeichen) ist
// keine Sitzung gültig.
const MIN_SECRET_LENGTH = 32;

const hexToBytes = (hex) =>
  new Uint8Array(hex.match(/../g).map((byte) => parseInt(byte, 16)));

async function isValidSession(token) {
  const secret = Netlify.env.get("SESSION_SECRET") || "";
  const pin = Netlify.env.get("PIN") || "";
  if (secret.length < MIN_SECRET_LENGTH || !pin) return false;

  const parts = token.split(".");
  if (parts.length !== 4 || parts[0] !== "v1") return false;
  const [, id, expires, signature] = parts;
  if (
    !/^[0-9a-f]{32}$/.test(id) ||
    !/^\d{1,12}$/.test(expires) ||
    !/^[0-9a-f]{64}$/.test(signature)
  ) {
    return false;
  }
  if (Number(expires) <= Math.floor(Date.now() / 1000)) return false;

  const encoder = new TextEncoder();
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["verify"],
  );
  // verify() vergleicht in konstanter Zeit.
  return crypto.subtle.verify(
    "HMAC",
    key,
    hexToBytes(signature),
    encoder.encode(`${id}.${expires}.${pin}`),
  );
}

// Schützt die API und den Formular-Endpunkt der Flutter-App.
// Statische Dateien (App, Handbuch) sind öffentlich – sie enthalten keine Daten;
// die App selbst leitet ohne Login auf die PIN-Eingabe.
// Geltungsbereich: siehe [[edge_functions]] in netlify.toml.
export default async (request, context) => {
  const url = new URL(request.url);

  const unauthorizedResponse = () =>
    new Response(JSON.stringify({ ok: false, error: "Unauthorized" }), {
      status: 401,
      headers: { "Content-Type": "application/json" },
    });

  const publicPaths = [
    "/api/login",
    "/api/logout",
    "/.netlify/functions/login",
    "/.netlify/functions/logout",
  ];

  if (publicPaths.some((path) => url.pathname.startsWith(path))) {
    return context.next();
  }

  const cookieHeader = request.headers.get("cookie") || "";
  const authMatch = cookieHeader.match(/(?:^|;\s*)auth=([^;]+)/);
  const token = authMatch ? authMatch[1] : null;

  if (!token) {
    return unauthorizedResponse();
  }

  if (!(await isValidSession(token))) {
    return unauthorizedResponse();
  }

  return context.next();
};
