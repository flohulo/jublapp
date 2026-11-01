exports.handler = async (event, context) => {
  return {
    statusCode: 200,
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      SCHAR_EMAIL: process.env.SCHAR_EMAIL || "",
      SUPPORT_PHONE: process.env.SUPPORT_PHONE || "",
    }),
  };
};
