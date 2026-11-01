"use strict";

const { getAccessToken } = require("./lib/google-auth");
const { appendRow } = require("./lib/sheets-api");
const { verifyAuth } = require("./lib/auth");

const CORS = {
  "Access-Control-Allow-Origin": process.env.ALLOWED_ORIGIN || "*",
  "Access-Control-Allow-Headers": "Content-Type",
  "Content-Type": "application/json",
};

const ok = (data = {}) => ({
  statusCode: 200,
  headers: CORS,
  body: JSON.stringify({ ok: true, ...data }),
});
const err = (message, statusCode = 500) => ({
  statusCode,
  headers: CORS,
  body: JSON.stringify({ ok: false, error: message }),
});

function formatTimestamp(timestamp) {
  return new Date(timestamp || Date.now())
    .toISOString()
    .replace("T", " ")
    .split(".")[0];
}

exports.handler = async (event) => {
  if (event.httpMethod === "OPTIONS")
    return { statusCode: 200, headers: CORS, body: "" };
  if (event.httpMethod !== "POST") return err("Method not allowed", 405);
  if (!verifyAuth(event)) return err("Unauthorized", 401);

  let body;
  try {
    body = JSON.parse(event.body || "{}");
  } catch {
    return err("Invalid Request Body", 400);
  }

  const vorname = (body.vorname || "").trim();
  const nachname = (body.nachname || "").trim();
  const email = (body.email || "").trim();
  const telefon = (body.telefon || "").trim();
  const funktion = (body.funktion || "").trim();
  const stufe = (body.stufe || "").trim();
  const bemerkungen = (body.bemerkungen || "").trim();

  if (!vorname || !nachname || !funktion) {
    return err("Vorname, Nachname und Funktion sind Pflichtfelder", 400);
  }

  try {
    const token = await getAccessToken();
    const sheetName = process.env.LEADERS_SHEET_NAME || "Leiter";

    // Spalten: Erfasst am, Vorname, Nachname, E-Mail, Telefon, Funktion, Stufe, Bemerkungen
    await appendRow(token, sheetName, [
      formatTimestamp(body.timestamp),
      vorname,
      nachname,
      email,
      telefon,
      funktion,
      stufe,
      bemerkungen,
    ]);

    return ok({ saved: true });
  } catch (error) {
    console.error("Leiter konnte nicht gespeichert werden:", error);
    return err(error.message);
  }
};
