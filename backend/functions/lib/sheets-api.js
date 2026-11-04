"use strict";

const { httpGet, httpPost } = require("./http");

function getSheetUrl(sheetName, path = "") {
  const id = process.env.GOOGLE_SHEET_ID;
  if (!id) throw new Error("GOOGLE_SHEET_ID missing in environment!");
  return `https://sheets.googleapis.com/v4/spreadsheets/${id}/values/${encodeURIComponent(sheetName)}${path}`;
}

// Mit USER_ENTERED wertet Sheets Eingaben wie "=HYPERLINK(...)" als Formel aus.
// Texte, die mit einem Formelzeichen beginnen, bekommen ein ' vorangestellt;
// Sheets zeigt sie dann als reinen Text an. Zahlen und Datumsangaben bleiben
// unverändert.
function sanitizeCell(value) {
  if (typeof value !== "string") return value;
  return /^[=+\-@\t\r]/.test(value) ? "'" + value : value;
}

async function appendRow(token, sheetName, row) {
  const url = getSheetUrl(
    sheetName,
    ":append?valueInputOption=USER_ENTERED&insertDataOption=INSERT_ROWS",
  );
  const result = await httpPost(url, JSON.stringify({ values: [row.map(sanitizeCell)] }), {
    Authorization: "Bearer " + token,
    "Content-Type": "application/json",
  });
  const parsed = JSON.parse(result);
  if (parsed.error) throw new Error(parsed.error.message);
  return parsed;
}

/**
 * Returns all data rows, skipping the header row (row 1).
 */
async function getAllRows(token, sheetName) {
  const url = getSheetUrl(sheetName);
  const raw = await httpGet(url, { Authorization: "Bearer " + token });
  const parsed = JSON.parse(raw);
  if (parsed.error) throw new Error(parsed.error.message);
  return (parsed.values || []).slice(1); // Skip header row once here
}

module.exports = { appendRow, getAllRows, sanitizeCell };
