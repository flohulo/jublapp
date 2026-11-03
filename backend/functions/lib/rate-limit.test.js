const test = require("node:test");
const assert = require("node:assert/strict");
const {
  MAX_FAILURES,
  WINDOW_MS,
  clientKey,
  createLimiter,
} = require("./rate-limit");

function fakeStore() {
  const data = new Map();
  return {
    data,
    get: async (key) => (data.has(key) ? structuredClone(data.get(key)) : null),
    setJSON: async (key, value) => void data.set(key, structuredClone(value)),
    delete: async (key) => void data.delete(key),
  };
}

test("sperrt nach MAX_FAILURES Fehlversuchen und nennt die Wartezeit", async () => {
  let t = 1_000_000;
  const limiter = createLimiter(fakeStore(), () => t);
  for (let i = 1; i < MAX_FAILURES; i++) {
    assert.equal((await limiter.fail("a")).blocked, false);
    assert.equal((await limiter.check("a")).blocked, false);
  }
  const last = await limiter.fail("a");
  assert.equal(last.blocked, true);
  assert.equal(last.retryAfter, WINDOW_MS / 1000);
  t += 60_000;
  const state = await limiter.check("a");
  assert.equal(state.blocked, true);
  assert.equal(state.retryAfter, WINDOW_MS / 1000 - 60);
});

test("Sperre läuft nach dem Zeitfenster ab", async () => {
  let t = 0;
  const limiter = createLimiter(fakeStore(), () => t);
  for (let i = 0; i < MAX_FAILURES; i++) await limiter.fail("a");
  assert.equal((await limiter.check("a")).blocked, true);
  t += WINDOW_MS;
  assert.equal((await limiter.check("a")).blocked, false);
  assert.equal((await limiter.fail("a")).blocked, false);
});

test("Absender sind unabhängig, reset löscht den Zähler", async () => {
  const limiter = createLimiter(fakeStore(), () => 0);
  for (let i = 0; i < MAX_FAILURES; i++) await limiter.fail("a");
  assert.equal((await limiter.check("a")).blocked, true);
  assert.equal((await limiter.check("b")).blocked, false);
  await limiter.reset("a");
  assert.equal((await limiter.check("a")).blocked, false);
});

test("clientKey nutzt die Netlify-IP und speichert nur einen Hash", () => {
  const key = clientKey({
    headers: {
      "x-nf-client-connection-ip": "203.0.113.7",
      "x-forwarded-for": "198.51.100.1",
    },
  });
  assert.match(key, /^[0-9a-f]{64}$/);
  assert.notEqual(
    key,
    clientKey({ headers: { "x-forwarded-for": "198.51.100.1" } }),
  );
  assert.equal(
    clientKey({ headers: { "x-forwarded-for": "198.51.100.1, 10.0.0.1" } }),
    clientKey({ headers: { "client-ip": "198.51.100.1" } }),
  );
});
