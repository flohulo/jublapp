"use strict";

// Prüft ein vom Client geschicktes Foto. Mime-Type und Endung werden aus den
// ersten Bytes der Datei bestimmt, nicht aus den Angaben des Clients.
const MAX_BYTES = 4 * 1024 * 1024; // Netlify Functions erlauben max. ~6 MB pro Anfrage

const TYPES = [
  { mime: "image/jpeg", ext: "jpg", test: (b) => b[0] === 0xff && b[1] === 0xd8 && b[2] === 0xff },
  {
    mime: "image/png",
    ext: "png",
    test: (b) => b.subarray(0, 8).equals(Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a])),
  },
  {
    mime: "image/webp",
    ext: "webp",
    test: (b) => b.subarray(0, 4).toString("latin1") === "RIFF" && b.subarray(8, 12).toString("latin1") === "WEBP",
  },
];

/**
 * @param {unknown} base64 Base64-Daten ohne "data:"-Präfix
 * @returns {{ok: true, buffer: Buffer, mimeType: string, ext: string} | {ok: false, error: string}}
 */
function validateFoto(base64) {
  if (typeof base64 !== "string" || base64.length === 0) {
    return { ok: false, error: "Ungültiges Foto" };
  }
  // Grobe Obergrenze vor dem Dekodieren, damit grosse Eingaben nicht erst Speicher belegen.
  if (base64.length > Math.ceil((MAX_BYTES * 4) / 3) + 4) {
    return { ok: false, error: "Foto zu gross" };
  }
  if (!/^[A-Za-z0-9+/]+={0,2}$/.test(base64) || base64.length % 4 !== 0) {
    return { ok: false, error: "Ungültiges Foto" };
  }
  const buffer = Buffer.from(base64, "base64");
  if (buffer.length > MAX_BYTES) return { ok: false, error: "Foto zu gross" };
  const type = TYPES.find((t) => buffer.length >= 12 && t.test(buffer));
  if (!type) return { ok: false, error: "Nur JPEG, PNG oder WebP erlaubt" };
  return { ok: true, buffer, mimeType: type.mime, ext: type.ext };
}

module.exports = { MAX_BYTES, validateFoto };
