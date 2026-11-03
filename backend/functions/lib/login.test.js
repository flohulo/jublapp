const test = require("node:test");
const assert = require("node:assert/strict");
const rateLimit = require("./rate-limit");
const { handler } = require("../login");
const { verifyAuth } = require("./auth");

function fakeStore() {
  const data = new Map();
  return {
    get: async (key) => (data.has(key) ? structuredClone(data.get(key)) : null),
    setJSON: async (key, value) => void data.set(key, structuredClone(value)),
    delete: async (key) => void data.delete(key),
  };
}

function login(pin) {
  return handler({
    httpMethod: "POST",
    headers: {
      "content-type": "application/json",
      "x-nf-client-connection-ip": "203.0.113.7",
    },
    body: JSON.stringify({ pin }),
  });
}

const SECRET = "s".repeat(40);

function withEnv(pin, fn, secret = SECRET) {
  return async () => {
    const before = process.env.PIN;
    const beforeSecret = process.env.SESSION_SECRET;
    if (secret === null) delete process.env.SESSION_SECRET;
    else process.env.SESSION_SECRET = secret;
    const original = rateLimit.getLoginLimiter;
    const store = fakeStore();
    rateLimit.getLoginLimiter = () => rateLimit.createLimiter(store);
    if (pin === undefined) delete process.env.PIN;
    else process.env.PIN = pin;
    try {
      await fn();
    } finally {
      rateLimit.getLoginLimiter = original;
      if (before === undefined) delete process.env.PIN;
      else process.env.PIN = before;
      if (beforeSecret === undefined) delete process.env.SESSION_SECRET;
      else process.env.SESSION_SECRET = beforeSecret;
    }
  };
}

test("richtiger PIN: Cookie mit Secure und HttpOnly", withEnv("123456", async () => {
  const res = await login("123456");
  assert.equal(res.statusCode, 200);
  const cookie = res.headers["Set-Cookie"];
  assert.match(cookie, /; HttpOnly; Secure; SameSite=Lax;/);
  assert.equal(verifyAuth({ headers: { cookie: cookie.split(";")[0] } }), true);
}));

test("falscher PIN: 401, nach 5 Fehlversuchen 429 mit Retry-After, auch mit richtigem PIN", withEnv("123456", async () => {
  for (let i = 1; i < rateLimit.MAX_FAILURES; i++) {
    assert.equal((await login("000000")).statusCode, 401);
  }
  const blocked = await login("000000");
  assert.equal(blocked.statusCode, 429);
  assert.ok(Number(blocked.headers["Retry-After"]) > 0);
  const correct = await login("123456");
  assert.equal(correct.statusCode, 429);
  assert.equal(correct.headers["Set-Cookie"], undefined);
}));

test("erfolgreicher Login setzt den Zähler zurück", withEnv("123456", async () => {
  for (let i = 1; i < rateLimit.MAX_FAILURES; i++) await login("000000");
  assert.equal((await login("123456")).statusCode, 200);
  for (let i = 1; i < rateLimit.MAX_FAILURES; i++) {
    assert.equal((await login("000000")).statusCode, 401);
  }
}));

test("ohne gesetzten PIN ist kein Login möglich", withEnv(undefined, async () => {
  const res = await login("");
  assert.equal(res.statusCode, 503);
  assert.equal(res.headers["Set-Cookie"], undefined);
}));

test("Zähler nicht erreichbar: Login wird verweigert", withEnv("123456", async () => {
  rateLimit.getLoginLimiter = () => {
    throw new Error("Blobs nicht verfügbar");
  };
  assert.equal((await login("123456")).statusCode, 503);
}));

test("ohne SESSION_SECRET ist kein Login möglich", withEnv("123456", async () => {
  const res = await login("123456");
  assert.equal(res.statusCode, 503);
  assert.equal(res.headers["Set-Cookie"], undefined);
}, null));

test("zu kurzes SESSION_SECRET wird abgelehnt", withEnv("123456", async () => {
  assert.equal((await login("123456")).statusCode, 503);
}, "kurz"));

test("jede Anmeldung bekommt ein anderes Token, ohne PIN darin", withEnv("123456", async () => {
  const a = (await login("123456")).headers["Set-Cookie"].split(";")[0];
  const b = (await login("123456")).headers["Set-Cookie"].split(";")[0];
  assert.notEqual(a, b);
  assert.equal(a.includes("123456"), false);
}));
