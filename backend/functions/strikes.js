"use strict";

const { corsHeaders } = require("./lib/cors");
const { getAccessToken } = require("./lib/google-auth");
const { appendRow, getAllRows } = require("./lib/sheets-api");
const { sendMail } = require("./lib/mailer");

const STRIKES_SHEET = "Strikes";
const ALARMS_SHEET = "Alarme";

function formatTimestamp(tsInput) {
  const ts = new Date(tsInput || Date.now());
  return ts.toISOString().replace("T", " ").split(".")[0];
}

function ensureISODate(dateStr) {
  if (!dateStr) return "";
  if (dateStr.includes(".") && dateStr.split(".").length === 3) {
    const [d, m, y] = dateStr.split(".");
    return `${y}-${m.padStart(2, "0")}-${d.padStart(2, "0")}`;
  }
  try {
    return new Date(dateStr).toISOString().split("T")[0];
  } catch (e) {
    return dateStr;
  }
}

// Spalten: [0]Timestamp [1]Datum [2]Leiter [3]Name [4]Strikes [5]Ausschluss [6]Version
async function buildHistoryMap(token) {
  const rows = await getAllRows(token, STRIKES_SHEET);
  const map = new Map();
  for (const r of rows) {
    const name = (r[3] || "").trim();
    if (!name) continue;
    const key = name.toLowerCase();
    if (!map.has(key)) map.set(key, []);
    map
      .get(key)
      .push({ datum: ensureISODate(r[1] || ""), strikes: parseInt(r[4]) || 0 });
  }
  for (const entries of map.values()) {
    entries.sort((a, b) => a.datum.localeCompare(b.datum));
  }
  return map;
}

function getKidHistory(historyMap, kidName) {
  return historyMap.get(kidName.trim().toLowerCase()) || [];
}

function analyzeKid(kidName, todayStrikes, history, referenceDate) {
  const reasons = [];
  const cutoff = new Date(referenceDate || Date.now());
  cutoff.setDate(cutoff.getDate() - 30);
  const cutoffStr = cutoff.toISOString().split("T")[0];

  const recent = history.filter((e) => e.datum >= cutoffStr);

  if (todayStrikes >= 2 && history.length > 0) {
    const last = history[history.length - 1];
    if (last.strikes >= 2)
      reasons.push("2+ Strikes an 2 aufeinanderfolgenden GruStus");
  }

  const recentWithStrikes =
    recent.filter((e) => e.strikes > 0).length + (todayStrikes > 0 ? 1 : 0);
  if (recentWithStrikes >= 3)
    reasons.push(`${recentWithStrikes}× in den letzten 30 Tagen mit Strikes`);

  if (todayStrikes === 2) {
    const twoCount = recent.filter((e) => e.strikes === 2).length;
    if (twoCount >= 1)
      reasons.push(
        `Bereits ${twoCount + 1}× mit genau 2 Strikes (Wiederholungsmuster)`,
      );
  }

  if (history.length >= 3) {
    const totalWith =
      history.filter((e) => e.strikes > 0).length + (todayStrikes > 0 ? 1 : 0);
    const total = history.length + 1;
    const ratio = totalWith / total;
    if (ratio >= 0.5 && total >= 4) {
      reasons.push(
        `Strikes bei ${totalWith}/${total} GruStus (${Math.round(ratio * 100)}%)`,
      );
    }
  }

  return reasons.length > 0
    ? { name: kidName, strikes: todayStrikes, history, reasons }
    : null;
}

function buildBannedMail(banned, datum, leiterName) {
  const names = banned.map((k) => k.name).join(", ");
  const adminLabel = "Scharleitung";
  const orgName = "JUBL(A)PP";
  return {
    subject: `🚫 Ausschluss nächste GruStu – ${names} (${datum})`,
    text: `Hoi ${adminLabel}\n\nAn der GruStu vom ${datum} (erfasst von ${leiterName}) haben folgende Kinder\n3 Strikes erreicht und dürfen bei der nächsten GruStu NICHT teilnehmen:\n\n${banned.map((k) => `  🚫  ${k.name}`).join("\n")}\n\nBitte informiert die Eltern entsprechend.\n\n──────────────────────\n${orgName} · Strike-System`,
  };
}

function buildPatternMail(warnings, datum) {
  const adminLabel = "Scharleitung";
  const orgName = "JUBL(A)PP";
  let text = `Hoi ${adminLabel}\n\nDas Strike-System hat bei der GruStu vom ${datum} bei folgenden Kindern\nein wiederkehrendes Muster erkannt:\n\n`;
  warnings.forEach((w) => {
    text += `👤 ${w.name} (${w.strikes} Strike${w.strikes !== 1 ? "s" : ""} heute)\n`;
    w.reasons.forEach((r) => (text += `   → ${r}\n`));
    if (w.history.length > 0) {
      const last5 = w.history.slice(-5);
      text +=
        `   Verlauf (letzte ${last5.length}): ` +
        last5.map((e) => `${e.datum}=${e.strikes}`).join("  ") +
        "\n";
    }
    text += "\n";
  });
  text += `──────────────────────\n${orgName} · Strike-System`;
  return { subject: `⚠️ Wiederholungsmuster erkannt – GruStu ${datum}`, text };
}

const CORS = corsHeaders({ "Content-Type": "application/json" });
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

const { verifyAuth } = require("./lib/auth");

exports.handler = async (event) => {
  if (event.httpMethod === "OPTIONS")
    return { statusCode: 200, headers: CORS, body: "" };
  if (event.httpMethod !== "POST") return err("Method not allowed", 405);

  if (!verifyAuth(event)) {
    return err("Unauthorized", 401);
  }

  let body;
  let isForm = false;
  try {
    if (
      event.headers["content-type"] &&
      event.headers["content-type"].includes(
        "application/x-www-form-urlencoded",
      )
    ) {
      const params = new URLSearchParams(event.body);
      body = Object.fromEntries(params);
      isForm = true;
    } else {
      body = JSON.parse(event.body);
    }
  } catch {
    return err("Invalid Request Body", 400);
  }

  body.action = body.action || "saveStrikeDay";
  body.datum = body.datum || body.datetime || "";
  body.leiterName =
    body.leiterName || body.melder || body.leiter || "Unbekannt";
  body.kids = Array.isArray(body.kids) ? body.kids : [];

  if (body.kids.length === 0) {
    const seen = new Map();
    for (let i = 1; i <= 4; i++) {
      const name = body[`child_name_${i}`];
      const strikes = parseInt(body[`child_strikes_${i}`], 10);
      if (name && name.trim() !== "" && !isNaN(strikes) && strikes > 0) {
        const key = name.trim().toLowerCase();
        if (seen.has(key)) {
          seen.get(key).strikes = Math.max(seen.get(key).strikes, strikes);
        } else {
          const entry = { name: name.trim(), strikes };
          seen.set(key, entry);
          body.kids.push(entry);
        }
      }
    }
  }

  const { action } = body;

  try {
    const token = await getAccessToken();

    if (action === "saveStrikeDay") {
      const { datum, leiterName, timestamp, kids } = body;
      const tsFormatted = formatTimestamp(timestamp);
      const isoDatum = ensureISODate(datum);

      const kidsWithStrikes = kids.filter((k) => k.strikes > 0);

      const historyMap = await buildHistoryMap(token);

      for (const kid of kidsWithStrikes) {
        await appendRow(token, STRIKES_SHEET, [
          tsFormatted,
          isoDatum,
          leiterName,
          kid.name,
          kid.strikes,
          kid.strikes >= 3 ? "JA" : "NEIN",
          body.version || "1.6",
        ]);
      }

      let mailSent = false;
      let mailErrors = [];

      const banned = kids.filter((k) => k.strikes >= 3);
      if (banned.length > 0) {
        try {
          const { subject, text } = buildBannedMail(banned, datum, leiterName);
          await sendMail(subject, text);
          mailSent = true;
        } catch (e) {
          mailErrors.push(e.message);
        }
      }

      const warnings = [];
      for (const kid of kidsWithStrikes) {
        try {
          const history = getKidHistory(historyMap, kid.name);
          const w = analyzeKid(kid.name, kid.strikes, history, isoDatum);

          if (w) {
            warnings.push(w);
            await appendRow(token, ALARMS_SHEET, [
              tsFormatted,
              isoDatum,
              kid.name,
              kid.strikes,
              w.reasons.join(" | "),
              leiterName,
            ]);
          }
        } catch (e) {
          console.error("Pattern error:", e.message);
        }
      }

      if (warnings.length > 0) {
        try {
          const { subject, text } = buildPatternMail(warnings, datum);
          await sendMail(subject, text);
          mailSent = true;
        } catch (e) {
          mailErrors.push(e.message);
        }
      }

      if (isForm) {
        return {
          statusCode: 303,
          headers: {
            Location: "/erfolg.html",
          },
          body: "",
        };
      }

      return ok({
        saved: kidsWithStrikes.length,
        banned: banned.length,
        patterns: warnings.length,
        alarms: warnings.map((w) => ({
          name: w.name,
          strikes: w.strikes,
          reasons: w.reasons,
        })),
        mailSent,
        mailErrors: mailErrors.length > 0 ? mailErrors : undefined,
      });
    }
  } catch (e) {
    return err(e.message);
  }

  return err("Unbekannte Aktion: " + action, 400);
};
