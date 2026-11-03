const test = require("node:test");
const assert = require("node:assert/strict");
const { verifyAuth } = require("./auth");
const { createSessionToken } = require("./session");

const SECRET = "s".repeat(40);

function withEnv({ pin, secret = SECRET }, fn) {
  return async () => {
    const before = { PIN: process.env.PIN, SESSION_SECRET: process.env.SESSION_SECRET };
    if (pin === undefined) delete process.env.PIN;
    else process.env.PIN = pin;
    if (secret === undefined) delete process.env.SESSION_SECRET;
    else process.env.SESSION_SECRET = secret;
    try {
      await fn();
    } finally {
      for (const [key, value] of Object.entries(before)) {
        if (value === undefined) delete process.env[key];
        else process.env[key] = value;
      }
    }
  };
}

const withCookie = (cookie) => ({ headers: { cookie } });

test(
  "akzeptiert das passende Cookie, auch zwischen anderen Cookies",
  withEnv({ pin: "1234" }, () => {
    const token = createSessionToken();
    assert.equal(verifyAuth(withCookie(`auth=${token}`)), true);
    assert.equal(verifyAuth(withCookie(`a=1; auth=${token}; b=2`)), true);
  }),
);

test(
  "lehnt falsches, fehlendes oder ähnlich benanntes Cookie ab",
  withEnv({ pin: "1234" }, () => {
    const token = createSessionToken();
    assert.equal(verifyAuth(withCookie("auth=falsch")), false);
    assert.equal(verifyAuth(withCookie("")), false);
    assert.equal(verifyAuth({}), false);
    assert.equal(verifyAuth(withCookie(`xauth=${token}`)), false);
  }),
);

test(
  "ohne gesetzten PIN ist nie jemand angemeldet",
  withEnv({ pin: undefined }, () => {
    assert.equal(verifyAuth(withCookie("auth=")), false);
    assert.equal(verifyAuth(withCookie("auth=null")), false);
  }),
);

test(
  "ohne SESSION_SECRET ist nie jemand angemeldet",
  withEnv({ pin: "1234", secret: undefined }, () => {
    assert.equal(verifyAuth(withCookie("auth=")), false);
    assert.equal(verifyAuth(withCookie("auth=null")), false);
  }),
);
