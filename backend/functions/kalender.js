"use strict";

const { google } = require("googleapis");
const { getAccessToken } = require("./lib/google-auth");
const { verifyAuth } = require("./lib/auth");

const CALENDAR_ID = process.env.CALENDAR_ID;

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "Content-Type",
  "Content-Type": "application/json",
};

const ok = (d = {}) => ({
  statusCode: 200,
  headers: CORS,
  body: JSON.stringify({ ok: true, ...d }),
});
const err = (m, c = 500) => ({
  statusCode: c,
  headers: CORS,
  body: JSON.stringify({ ok: false, error: m }),
});

exports.handler = async (event) => {
  if (event.httpMethod === "OPTIONS")
    return { statusCode: 200, headers: CORS, body: "" };
  if (event.httpMethod !== "POST") return err("Method not allowed", 405);

  if (!verifyAuth(event)) {
    return err("Unauthorized", 401);
  }

  let body;
  try {
    body = JSON.parse(event.body);
  } catch {
    return err("Invalid Request Body", 400);
  }

  const { summary, description, startISO, endISO } = body;

  if (!summary || !startISO || !endISO) {
    return err("Fehlende Pflichtfelder (summary, startISO, endISO)", 400);
  }

  try {
    const token = await getAccessToken();

    const auth = new google.auth.OAuth2();
    auth.setCredentials({ access_token: token });

    const calendar = google.calendar({ version: "v3", auth });

    const event = {
      summary: summary,
      description: description || "",
      start: { dateTime: startISO },
      end: { dateTime: endISO },
    };

    const response = await calendar.events.insert({
      calendarId: CALENDAR_ID,
      resource: event,
    });

    return ok({ eventId: response.data.id });
  } catch (error) {
    console.error("Fehler beim Erstellen des Termins:", error);
    return err("Termin konnte nicht erstellt werden", 500);
  }
};
