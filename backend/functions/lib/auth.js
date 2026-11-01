const crypto = require("crypto");

function getExpectedToken() {
  const pin = process.env.PIN || "";
  return crypto
    .createHmac("sha256", pin)
    .update("jubla-auth-token")
    .digest("hex");
}

function verifyAuth(event) {
  const cookieHeader = event.headers?.cookie || "";
  const match = cookieHeader.match(/(?:^|;\s*)auth=([^;]+)/);
  const cookieValue = match ? match[1] : null;

  return cookieValue === getExpectedToken();
}

module.exports = {
  getExpectedToken,
  verifyAuth,
};
