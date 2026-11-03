const test = require("node:test");
const assert = require("node:assert/strict");
const crypto = require("crypto");
const {
  SESSION_SECONDS,
  createSessionToken,
  isConfigured,
  verifySessionToken,
} = require("./session");

const SECRET = "s".repeat(40);

function withEnv({ pin = "123456", secret = SECRET }, fn) {
  return async () => {
    const before = { ...process.env };
    if (pin === null) delete process.env.PIN;
    else process.env.PIN = pin;
    if (secret === null) delete process.env.SESSION_SECRET;
    else process.env.SESSION_SECRET = secret;
    try {
      await fn();
    } finally {
      for (const key of ["PIN", "SESSION_SECRET"]) {
        if (before[key] === undefined) delete process.env[key];
        else process.env[key] = before[key];
      }
    }
  };
}

test("Token ist gültig, zufällig und enthält weder PIN noch Hash davon", withEnv({}, () => {
  const a = createSessionToken();
  const b = createSessionToken();
  assert.match(a, /^v1\.[0-9a-f]{32}\.\d+\.[0-9a-f]{64}$/);
  assert.notEqual(a, b);
  assert.equal(verifySessionToken(a), true);
  assert.equal(a.includes("123456"), false);
  const sha = crypto.createHash("sha256").update("123456").digest("hex");
  assert.equal(a.includes(sha), false);
}));

test("Token läuft nach 30 Tagen ab", withEnv({}, () => {
  const t0 = 1_700_000_000_000;
  const token = createSessionToken(() => t0);
  assert.equal(verifySessionToken(token, () => t0 + (SESSION_SECONDS - 1) * 1000), true);
  assert.equal(verifySessionToken(token, () => t0 + SESSION_SECONDS * 1000), false);
}));

test("veränderte Token werden abgelehnt", withEnv({}, () => {
  const [v, id, expires, sig] = createSessionToken().split(".");
  const flipped = (sig[0] === "0" ? "1" : "0") + sig.slice(1);
  assert.equal(verifySessionToken([v, id, expires, flipped].join(".")), false);
  assert.equal(verifySessionToken([v, id, String(Number(expires) + 1e6), sig].join(".")), false);
  assert.equal(verifySessionToken([v, "0".repeat(32), expires, sig].join(".")), false);
  assert.equal(verifySessionToken([v, id, expires].join(".")), false);
  assert.equal(verifySessionToken("v2." + [id, expires, sig].join(".")), false);
  assert.equal(verifySessionToken(""), false);
  assert.equal(verifySessionToken(null), false);
}));

test("PIN-Änderung macht bestehende Token ungültig", async () => {
  let token;
  await withEnv({}, () => {
    token = createSessionToken();
  })();
  await withEnv({ pin: "654321" }, () => {
    assert.equal(verifySessionToken(token), false);
  })();
});

test("anderes SESSION_SECRET macht Token ungültig", async () => {
  let token;
  await withEnv({}, () => {
    token = createSessionToken();
  })();
  await withEnv({ secret: "t".repeat(40) }, () => {
    assert.equal(verifySessionToken(token), false);
  })();
});

test("alte PIN-Hash-Token (Format vor Punkt 3) sind ungültig", withEnv({}, () => {
  const old = crypto.createHmac("sha256", "123456").update("jubla-auth-token").digest("hex");
  assert.equal(verifySessionToken(old), false);
}));

test("ohne PIN oder mit zu kurzem SESSION_SECRET gibt es kein Token", async () => {
  await withEnv({ pin: null }, () => {
    assert.equal(isConfigured(), false);
    assert.equal(createSessionToken(), null);
  })();
  await withEnv({ secret: null }, () => {
    assert.equal(createSessionToken(), null);
  })();
  await withEnv({ secret: "x".repeat(31) }, () => {
    assert.equal(createSessionToken(), null);
  })();
});
