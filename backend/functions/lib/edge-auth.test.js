// Prüft, dass die Edge Function (WebCrypto) dieselben Token akzeptiert, die
// die Funktionen (Node) ausstellen.
const test = require("node:test");
const assert = require("node:assert/strict");
const { createSessionToken } = require("./session");

const SECRET = "s".repeat(40);

async function edge(cookie, path = "/api/strikes") {
  globalThis.Netlify = { env: { get: (key) => process.env[key] } };
  const { default: handler } = await import("../../edge-functions/auth.js");
  const request = new Request(`https://example.test${path}`, {
    headers: cookie ? { cookie } : {},
  });
  const response = await handler(request, { next: () => "next" });
  return response === "next" ? "next" : response.status;
}

function withEnv(env, fn) {
  return async () => {
    const before = { ...process.env };
    for (const [key, value] of Object.entries(env)) {
      if (value === undefined) delete process.env[key];
      else process.env[key] = value;
    }
    try {
      await fn();
    } finally {
      for (const key of Object.keys(env)) {
        if (before[key] === undefined) delete process.env[key];
        else process.env[key] = before[key];
      }
    }
  };
}

const ok = { PIN: "123456", SESSION_SECRET: SECRET };

test("gültiges Token wird durchgelassen, Login-Pfade sind öffentlich", withEnv(ok, async () => {
  const token = createSessionToken();
  assert.equal(await edge(`auth=${token}`), "next");
  assert.equal(await edge(undefined, "/api/login"), "next");
}));

test("ohne Cookie, mit verändertem oder abgelaufenem Token: 401", withEnv(ok, async () => {
  assert.equal(await edge(undefined), 401);
  const token = createSessionToken();
  assert.equal(await edge(`auth=${token.slice(0, -1)}${token.endsWith("0") ? "1" : "0"}`), 401);
  const expired = createSessionToken(() => Date.now() - 4 * 24 * 3600 * 1000);
  assert.equal(await edge(`auth=${expired}`), 401);
  assert.equal(await edge("auth=nonsense"), 401);
}));

test("PIN-Änderung oder fehlende Konfiguration: 401", async () => {
  let token;
  await withEnv(ok, () => {
    token = createSessionToken();
  })();
  await withEnv({ ...ok, PIN: "654321" }, async () => {
    assert.equal(await edge(`auth=${token}`), 401);
  })();
  await withEnv({ ...ok, SESSION_SECRET: undefined }, async () => {
    assert.equal(await edge(`auth=${token}`), 401);
  })();
  await withEnv({ ...ok, PIN: undefined }, async () => {
    assert.equal(await edge(`auth=${token}`), 401);
  })();
});
