const crypto = require("crypto");

// Ohne gesetzten PIN gibt es kein gültiges Token (null), damit niemand mit
// leerem Schlüssel ein Token berechnen kann.
function getExpectedToken() {
  const pin = process.env.PIN || "";
  if (!pin) return null;
  return crypto
    .createHmac("sha256", pin)
    .update("jubla-auth-token")
    .digest("hex");
}

function verifyAuth(event) {
  const cookieHeader = event.headers?.cookie || "";
  const match = cookieHeader.match(/(?:^|;\s*)auth=([^;]+)/);
  const cookieValue = match ? match[1] : null;

  const expected = getExpectedToken();
  return Boolean(expected) && cookieValue === expected;
}

module.exports = {
  getExpectedToken,
  verifyAuth,
};
