"use strict";

const { getAccessToken } = require("./lib/google-auth");
const { appendRow, getAllRows } = require("./lib/sheets-api");

const SHOPPING_SHEET = process.env.SHOPPING_SHEET_NAME || "Einkaufsliste";

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "Content-Type",
  "Content-Type": "application/json",
};

const ok = (data = {}) => ({
  statusCode: 200,
  headers: CORS_HEADERS,
  body: JSON.stringify({ ok: true, ...data }),
});
const err = (msg, code = 500) => ({
  statusCode: code,
  headers: CORS_HEADERS,
  body: JSON.stringify({ ok: false, error: msg }),
});

function formatTimestamp(isoString) {
  const date = new Date(isoString || Date.now());
  return date.toISOString().replace("T", " ").split(".")[0];
}

function createItemId() {
  return `item-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
}

function isDone(value) {
  return String(value).toUpperCase() === "TRUE" || value === true;
}

function buildCurrentItems(rows) {
  const items = new Map();

  rows.forEach((row) => {
    const event = {
      timestamp: row[0] || "",
      user: row[1] || "",
      action: (row[2] || "add").toLowerCase(),
      itemId: row[3] || "",
      title: row[4] || "",
      amount: row[5] || "",
      category: row[6] || "",
      note: row[7] || "",
      done: isDone(row[8]),
      status: (row[9] || "open").toLowerCase(),
    };

    if (!event.itemId) return;

    if (event.action === "add" || !items.has(event.itemId)) {
      items.set(event.itemId, {
        ...event,
        createdAt: event.timestamp,
        updatedAt: event.timestamp,
        removed: event.status === "removed",
      });
      return;
    }

    const current = items.get(event.itemId);
    if (event.action === "toggle") {
      current.user = event.user || current.user;
      current.amount = event.amount ?? current.amount;
      current.category = event.category ?? current.category;
      current.note = event.note ?? current.note;
      current.done = event.done;
      current.updatedAt = event.timestamp;
      current.removed = false;
      return;
    }

    if (event.action === "remove") {
      current.user = event.user || current.user;
      current.updatedAt = event.timestamp;
      current.removed = true;
    }
  });

  return [...items.values()]
    .filter((item) => !item.removed)
    .sort((a, b) => {
      if (a.done !== b.done) return a.done ? 1 : -1;
      return (b.createdAt || "").localeCompare(a.createdAt || "");
    });
}

function buildStats(items) {
  return {
    total: items.length,
    open: items.filter((item) => !item.done).length,
    done: items.filter((item) => item.done).length,
  };
}

async function loadShoppingState(token) {
  const rows = await getAllRows(token, SHOPPING_SHEET).catch(() => []);
  const items = buildCurrentItems(rows);
  return { items, stats: buildStats(items) };
}

exports.handler = async (event) => {
  if (event.httpMethod === "OPTIONS")
    return { statusCode: 200, headers: CORS_HEADERS, body: "" };
  if (event.httpMethod !== "POST") return err("Method not allowed", 405);

  let body;
  try {
    body = JSON.parse(event.body);
  } catch {
    return err("Invalid JSON", 400);
  }

  const { action, pin } = body;
  const correctPin = process.env.SCHAR_PIN || "1234";

  if (pin !== correctPin) {
    return err("Ungültiger PIN. Zugriff verweigert.", 403);
  }

  if (action === "verifyPin") {
    return ok({ verified: true });
  }

  try {
    const token = await getAccessToken();

    if (action === "getList") {
      return ok(await loadShoppingState(token));
    }

    if (action === "addItem") {
      const title = (body.title || "").trim();
      if (!title) return err("Bitte einen Artikel eingeben.", 400);

      const itemId = createItemId();
      const row = [
        formatTimestamp(body.timestamp),
        body.leiterName || "",
        "add",
        itemId,
        title,
        body.amount || "",
        body.category || "",
        body.note || "",
        "FALSE",
        "open",
      ];

      await appendRow(token, SHOPPING_SHEET, row);
      return ok({ ...(await loadShoppingState(token)), addedId: itemId });
    }

    if (action === "toggleItem") {
      const itemId = (body.itemId || "").trim();
      if (!itemId) return err("Artikel-ID fehlt.", 400);

      const state = await loadShoppingState(token);
      const current = state.items.find((item) => item.itemId === itemId);
      if (!current) return err("Artikel nicht gefunden.", 404);

      const nextDone = !current.done;
      await appendRow(token, SHOPPING_SHEET, [
        formatTimestamp(body.timestamp),
        body.leiterName || "",
        "toggle",
        itemId,
        current.title,
        current.amount || "",
        current.category || "",
        current.note || "",
        nextDone ? "TRUE" : "FALSE",
        "open",
      ]);

      return ok(await loadShoppingState(token));
    }

    if (action === "removeItem") {
      const itemId = (body.itemId || "").trim();
      if (!itemId) return err("Artikel-ID fehlt.", 400);

      const state = await loadShoppingState(token);
      const current = state.items.find((item) => item.itemId === itemId);
      if (!current) return err("Artikel nicht gefunden.", 404);

      await appendRow(token, SHOPPING_SHEET, [
        formatTimestamp(body.timestamp),
        body.leiterName || "",
        "remove",
        itemId,
        current.title,
        current.amount || "",
        current.category || "",
        current.note || "",
        current.done ? "TRUE" : "FALSE",
        "removed",
      ]);

      return ok(await loadShoppingState(token));
    }

    if (action === "clearDone") {
      const state = await loadShoppingState(token);
      const doneItems = state.items.filter((item) => item.done);
      if (doneItems.length === 0) {
        return ok({ ...state, cleared: 0 });
      }

      for (const item of doneItems) {
        await appendRow(token, SHOPPING_SHEET, [
          formatTimestamp(body.timestamp),
          body.leiterName || "",
          "remove",
          item.itemId,
          item.title,
          item.amount || "",
          item.category || "",
          item.note || "",
          "TRUE",
          "removed",
        ]);
      }

      return ok({
        ...(await loadShoppingState(token)),
        cleared: doneItems.length,
      });
    }
  } catch (e) {
    return err(e.message);
  }

  return err("Unbekannte Aktion: " + action, 400);
};
