const test = require("node:test");
const assert = require("node:assert/strict");
const { sanitizeCell } = require("./sheets-api");

test("Texte mit Formelzeichen am Anfang werden als Text markiert", () => {
  for (const value of [
    '=HYPERLINK("http://example.com","x")',
    "+1+1",
    "-2+3",
    "@SUM(A1)",
    "\t=1",
    "\r=1",
  ]) {
    assert.equal(sanitizeCell(value), "'" + value);
  }
});

test("normale Werte bleiben unverändert", () => {
  for (const value of ["Max Muster", "2026-11-04", "a=b", "", 3, null, undefined]) {
    assert.equal(sanitizeCell(value), value);
  }
});
