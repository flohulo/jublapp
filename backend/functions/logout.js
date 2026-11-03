exports.handler = async (event) => {
  if (event.httpMethod !== "POST") {
    return {
      statusCode: 405,
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ error: "Method not allowed" }),
    };
  }

  return {
    statusCode: 204,
    headers: {
      "Set-Cookie": "auth=; Path=/; HttpOnly; Secure; SameSite=Lax; Max-Age=0",
    },
    body: "",
  };
};
