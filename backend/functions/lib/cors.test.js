const test = require("node:test");
const assert = require("node:assert/strict");
const { corsHeaders } = require("./cors");

function withOrigin(value, fn) {
  const before = process.env.ALLOWED_ORIGIN;
  if (value === undefined) delete process.env.ALLOWED_ORIGIN;
  else process.env.ALLOWED_ORIGIN = value;
  try {
    fn();
  } finally {
    if (before === undefined) delete process.env.ALLOWED_ORIGIN;
    else process.env.ALLOWED_ORIGIN = before;
  }
}

test("ohne ALLOWED_ORIGIN oder mit * wird keine Origin freigegeben", () => {
  for (const value of [undefined, "", "*"]) {
    withOrigin(value, () => {
      const headers = corsHeaders({ "Content-Type": "application/json" });
      assert.equal(headers["Access-Control-Allow-Origin"], undefined);
      assert.equal(headers["Content-Type"], "application/json");
    });
  }
});

test("mit ALLOWED_ORIGIN wird genau diese Origin freigegeben", () => {
  withOrigin("http://localhost:8080", () => {
    const headers = corsHeaders();
    assert.equal(headers["Access-Control-Allow-Origin"], "http://localhost:8080");
    assert.equal(headers.Vary, "Origin");
  });
});
