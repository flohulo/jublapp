"use strict";

const { getAccessToken } = require("./lib/google-auth");
const { appendRow } = require("./lib/sheets-api");
const { uploadToDrive } = require("./lib/drive-api");
const { sendMail } = require("./lib/mailer");

const SHEET_NAME = "Ereignisse";
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

function formatTimestamp(tsInput) {
  const ts = new Date(tsInput || Date.now());
  return ts.toISOString().replace("T", " ").split(".")[0];
}

const { verifyAuth } = require("./lib/auth");

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

  const {
    datum,
    melder,
    art,
    betroffene,
    beschreibung,
    massnahmen,
    timestamp,
    fotoBase64,
    fotoMimeType,
  } = body;

  if (!datum || !melder || !art) {
    return err("Fehlende Pflichtfelder", 400);
  }

  try {
    const token = await getAccessToken();
    const tsFormatted = formatTimestamp(timestamp);

    let driveLink = "";
    let attachments = [];

    // Foto hochladen
    if (fotoBase64) {
      try {
        const folderId = process.env.GOOGLE_DRIVE_FOLDER_ID || "";
        const filename = `ereignis_${datum.replace(/\./g, "-")}_${Date.now()}.jpg`;

        const driveRes = await uploadToDrive(
          token,
          fotoBase64,
          filename,
          fotoMimeType || "image/jpeg",
          folderId,
        );
        driveLink = driveRes.webViewLink || driveRes.id || "Hochgeladen";

        // Foto als Mail-Anhang vorbereiten
        attachments.push({
          filename: filename,
          content: Buffer.from(fotoBase64, "base64"),
          contentType: fotoMimeType || "image/jpeg",
        });
      } catch (e) {
        console.error("Fehler beim Foto-Upload:", e);
        driveLink = "Fehler beim Upload";
      }
    }

    // 1. Speichern im Hauptblatt (Ereignisse)
    // Spalten: [0]Timestamp [1]Datum [2]Melder [3]Art [4]Betroffene [5]Beschreibung [6]Massnahmen [7]Foto
    await appendRow(token, SHEET_NAME, [
      tsFormatted,
      datum,
      melder,
      art,
      betroffene || "-",
      beschreibung || "-",
      massnahmen || "-",
      driveLink || "-",
    ]);

    // 2. E-Mail senden
    const orgName = "JUBL(A)PP";
    const adminLabel = "Scharleitung";

    let mailText = `Hoi ${adminLabel}\n\nEs wurde soeben ein neues Ereignis gemeldet!\n\n`;
    mailText += `Datum: ${datum}\n`;
    mailText += `Melder: ${melder}\n`;
    mailText += `Art des Ereignisses: ${art}\n`;
    mailText += `Betroffene Personen/Objekte: ${betroffene || "-"}\n\n`;
    mailText += `Beschreibung:\n${beschreibung || "-"}\n\n`;
    mailText += `Massnahmen:\n${massnahmen || "-"}\n\n`;

    if (driveLink && driveLink !== "-" && driveLink !== "Fehler beim Upload") {
      mailText += `Foto (Drive-Link): ${driveLink}\n`;
      mailText += `Das Foto ist zusätzlich im Anhang dieser E-Mail zu finden.\n\n`;
    }

    mailText += `──────────────────────\n${orgName} · Ereignis-System`;

    const subject = `🚨 Neues Ereignis: ${art} (${datum})`;

    await sendMail(
      subject,
      mailText,
      process.env.SCHARLEITUNG_EMAIL || process.env.SMTP_USER,
      attachments,
    );

    return ok({ saved: true });
  } catch (e) {
    console.error(e);
    return err(e.message);
  }
};
