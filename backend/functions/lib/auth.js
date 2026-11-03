const { verifySessionToken } = require("./session");

function verifyAuth(event) {
  const cookieHeader = event.headers?.cookie || "";
  const match = cookieHeader.match(/(?:^|;\s*)auth=([^;]+)/);
  return verifySessionToken(match ? match[1] : null);
}

module.exports = {
  verifyAuth,
};
