const test = require("node:test");
const assert = require("node:assert/strict");
const { getExpectedToken, verifyAuth } = require("./auth");

function withPin(pin, fn) {
  return async () => {
    const before = process.env.PIN;
    if (pin === undefined) delete process.env.PIN;
    else process.env.PIN = pin;
    try {
      await fn();
    } finally {
      if (before === undefined) delete process.env.PIN;
      else process.env.PIN = before;
    }
  };
}

const withCookie = (cookie) => ({ headers: { cookie } });

test(
  "kein Token ohne gesetzten PIN",
  withPin(undefined, () => {
    assert.equal(getExpectedToken(), null);
  }),
);

test(
  "Token ist stabil und hängt vom PIN ab",
  withPin("1234", () => {
    const token = getExpectedToken();
    assert.match(token, /^[0-9a-f]{64}$/);
    assert.equal(getExpectedToken(), token);
    process.env.PIN = "4321";
    assert.notEqual(getExpectedToken(), token);
  }),
);

test(
  "akzeptiert das passende Cookie, auch zwischen anderen Cookies",
  withPin("1234", () => {
    const token = getExpectedToken();
    assert.equal(verifyAuth(withCookie(`auth=${token}`)), true);
    assert.equal(verifyAuth(withCookie(`a=1; auth=${token}; b=2`)), true);
  }),
);

test(
  "lehnt falsches, fehlendes oder ähnlich benanntes Cookie ab",
  withPin("1234", () => {
    const token = getExpectedToken();
    assert.equal(verifyAuth(withCookie("auth=falsch")), false);
    assert.equal(verifyAuth(withCookie("")), false);
    assert.equal(verifyAuth({}), false);
    assert.equal(verifyAuth(withCookie(`xauth=${token}`)), false);
  }),
);

test(
  "ohne gesetzten PIN ist nie jemand angemeldet",
  withPin(undefined, () => {
    assert.equal(verifyAuth(withCookie("auth=")), false);
    assert.equal(verifyAuth(withCookie("auth=null")), false);
  }),
);
