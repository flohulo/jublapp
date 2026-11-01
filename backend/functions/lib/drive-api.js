"use strict";

const { httpPost } = require("./http");

/**
 * Läd eine Datei ins Google Drive hoch (Multipart Upload)
 * @param {string} token - Google Access Token
 * @param {string} base64Data - Base64 kodierte Bilddaten (ohne "data:image/jpeg;base64," prefix)
 * @param {string} filename - Name der Datei
 * @param {string} mimeType - MIME Type, z.B. "image/jpeg"
 * @param {string} [folderId] - Optionale Google Drive Folder ID
 * @returns {Promise<Object>} - Response des Google APIs (mit ID und URL)
 */
async function uploadToDrive(token, base64Data, filename, mimeType, folderId) {
  const boundary = "-------314159265358979323846";
  const delimiter = "\r\n--" + boundary + "\r\n";
  const close_delim = "\r\n--" + boundary + "--";

  const metadata = {
    name: filename,
    mimeType: mimeType,
  };

  if (folderId) {
    metadata.parents = [folderId];
  }

  const metadataPart = Buffer.from(
    delimiter +
      "Content-Type: application/json; charset=UTF-8\r\n\r\n" +
      JSON.stringify(metadata) +
      delimiter +
      `Content-Type: ${mimeType}\r\n\r\n`,
  );
  const mediaPart = Buffer.from(base64Data, "base64");
  const closingPart = Buffer.from(close_delim);
  const multipartRequestBody = Buffer.concat([
    metadataPart,
    mediaPart,
    closingPart,
  ]);

  const url =
    "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart&fields=id,webViewLink";

  const result = await httpPost(url, multipartRequestBody, {
    Authorization: "Bearer " + token,
    "Content-Type": `multipart/related; boundary="${boundary}"`,
  });

  const parsed = JSON.parse(result);
  if (parsed.error) throw new Error(parsed.error.message);
  return parsed;
}

module.exports = { uploadToDrive };
