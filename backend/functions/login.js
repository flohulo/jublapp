exports.handler = async (event) => {
  const CORS = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "Content-Type",
    "Content-Type": "application/json",
  };

  if (event.httpMethod === "OPTIONS") {
    return { statusCode: 200, headers: CORS, body: "" };
  }

  if (event.httpMethod !== "POST") {
    return {
      statusCode: 405,
      headers: CORS,
      body: JSON.stringify({ error: "Method not allowed" }),
    };
  }

  let pin = "";
  if (
    event.headers["content-type"] &&
    event.headers["content-type"].includes("application/x-www-form-urlencoded")
  ) {
    const params = new URLSearchParams(event.body);
    pin = params.get("pin") || "";
  } else {
    try {
      const body = JSON.parse(event.body);
      pin = body.pin || "";
    } catch (e) {}
  }

  const expectedPin = process.env.PIN;

  if (pin === expectedPin) {
    const { getExpectedToken } = require("./lib/auth");
    const token = getExpectedToken();
    return {
      statusCode: 200,
      headers: {
        ...CORS,
        "Set-Cookie": `auth=${token}; Path=/; HttpOnly; SameSite=Lax; Max-Age=${60 * 60 * 24 * 30}`, // 30 days
      },
      body: JSON.stringify({ ok: true }),
    };
  } else {
    return {
      statusCode: 401,
      headers: CORS,
      body: JSON.stringify({ error: "Invalid PIN" }),
    };
  }
};
