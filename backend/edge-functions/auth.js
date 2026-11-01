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

  const correctPin = Netlify.env.get("PIN") || "";
  const encoder = new TextEncoder();
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(correctPin),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    "HMAC",
    key,
    encoder.encode("jubla-auth-token"),
  );
  const expectedToken = Array.from(new Uint8Array(signature))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");

  if (token !== expectedToken) {
    return unauthorizedResponse();
  }

  return context.next();
};
