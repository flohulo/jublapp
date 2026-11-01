const { jsPDF } = require("jspdf");
const autoTable = require("jspdf-autotable");

/**
 * Generates an improved PDF report.
 * @param {Array} reports - Array of report objects: { datum, hl, kinder, dynamik, bemerkungen }
 * @param {Array} strikes - Array of strike objects: { datum, name, strikes, ausschluss }
 * @param {Array} alarms - Array of alarm objects: { datum, name, strikes, grund }
 * @param {Object} metadata - { title, subtitle, orgName, appName }
 * @returns {Buffer} PDF Buffer
 */
function generatePdf(reports, strikes, alarms, metadata) {
  const { title, subtitle, orgName, appName, requestedBy, requestedAt } =
    metadata;
  const doc = new jsPDF();
  const now = new Date();

  const headerHeight = 35;

  // --- Header ---
  doc.setFillColor(41, 128, 185); // Header blue
  doc.rect(0, 0, doc.internal.pageSize.getWidth(), headerHeight, "F");

  doc.setTextColor(255, 255, 255);
  doc.setFontSize(22);
  doc.setFont("helvetica", "bold");
  doc.text(title || `${orgName} Export`, 14, 20);

  doc.setFontSize(12);
  doc.setFont("helvetica", "normal");
  doc.text(subtitle || `Erstellt am: ${now.toLocaleString("de-DE")}`, 14, 28);

  // Reset Text Color
  doc.setTextColor(50, 50, 50);

  let currentY = 45;

  // --- Tabelle 1: Berichte ---
  doc.setFontSize(14);
  doc.setFont("helvetica", "bold");
  doc.text(`Berichte`, 14, currentY);

  if (reports && reports.length > 0) {
    const reportData = reports.map((r) => [
      r.datum || "",
      r.hl || "",
      r.kinder !== undefined
        ? r.kinder
        : r.anzahl !== undefined
          ? r.anzahl
          : "0",
      r.dynamik || "1",
      r.bemerkungen || "",
    ]);

    autoTable.default(doc, {
      startY: currentY + 5,
      head: [["Datum", "Hauptleitung", "Kinder", "Dyn.", "Bemerkungen"]],
      body: reportData,
      theme: "grid",
      headStyles: { fillColor: [41, 128, 185], textColor: [255, 255, 255] },
      alternateRowStyles: { fillColor: [245, 247, 250] },
      columnStyles: {
        0: { cellWidth: 25 },
        1: { cellWidth: 35 },
        2: { cellWidth: 15 },
        3: { cellWidth: 15 },
        4: { cellWidth: "auto" },
      },
      styles: { overflow: "linebreak", fontSize: 9 },
    });
    currentY = doc.lastAutoTable.finalY + 15;
  } else {
    doc.setFontSize(10);
    doc.setFont("helvetica", "normal");
    doc.text("Keine Berichte in diesem Zeitraum.", 14, currentY + 10);
    currentY += 25;
  }

  // --- Tabelle 2: Strikes ---
  if (currentY > 240) {
    doc.addPage();
    currentY = 20;
  }

  doc.setFontSize(14);
  doc.setFont("helvetica", "bold");
  doc.setTextColor(192, 57, 43); // Red
  doc.text(`Strikes`, 14, currentY);
  doc.setTextColor(50, 50, 50);

  if (strikes && strikes.length > 0) {
    const strikeData = strikes.map((s) => [
      s.datum || "",
      s.name || "",
      s.strikes || "0",
      s.ausschluss || "NEIN",
    ]);

    autoTable.default(doc, {
      startY: currentY + 5,
      head: [["Datum", "Name (Kind)", "Strikes", "Ausschluss"]],
      body: strikeData,
      theme: "grid",
      headStyles: { fillColor: [192, 57, 43] },
      alternateRowStyles: { fillColor: [253, 242, 240] },
      columnStyles: { 0: { cellWidth: 30 } },
      styles: { fontSize: 9 },
    });
    currentY = doc.lastAutoTable.finalY + 15;
  } else {
    doc.setFontSize(10);
    doc.setFont("helvetica", "normal");
    doc.text("Keine Strikes in diesem Zeitraum.", 14, currentY + 10);
    currentY += 25;
  }

  // --- Tabelle 3: Alarme ---
  if (currentY > 240) {
    doc.addPage();
    currentY = 20;
  }

  doc.setFontSize(14);
  doc.setFont("helvetica", "bold");
  doc.setTextColor(230, 126, 34); // Orange
  doc.text(`Erkannte Verhaltensmuster (Alarme)`, 14, currentY);
  doc.setTextColor(50, 50, 50);

  if (alarms && alarms.length > 0) {
    const alarmData = alarms.map((a) => [
      a.datum || "",
      a.name || "",
      a.strikes || "0",
      a.grund || "",
    ]);

    autoTable.default(doc, {
      startY: currentY + 5,
      head: [["Datum", "Name", "S.", "Erkanntes Muster / Grund"]],
      body: alarmData,
      theme: "grid",
      headStyles: { fillColor: [230, 126, 34] },
      alternateRowStyles: { fillColor: [253, 246, 238] },
      columnStyles: {
        0: { cellWidth: 25 },
        1: { cellWidth: 35 },
        2: { cellWidth: 10 },
        3: { cellWidth: "auto" },
      },
      styles: { fontSize: 9 },
    });
    currentY = doc.lastAutoTable.finalY + 15;
  } else {
    doc.setFontSize(10);
    doc.setFont("helvetica", "normal");
    doc.text("Keine Alarme in diesem Zeitraum.", 14, currentY + 10);
  }

  // --- Footer ---
  const pageCount = doc.internal.getNumberOfPages();
  for (let i = 1; i <= pageCount; i++) {
    doc.setPage(i);
    doc.setFontSize(8);
    doc.setTextColor(150, 150, 150);

    if (requestedBy) {
      doc.text(
        `Angefordert am: ${requestedAt || now.toLocaleString("de-DE")} von: ${requestedBy}`,
        14,
        doc.internal.pageSize.getHeight() - 15,
      );
    }
    doc.text(
      `Automatisch erstellt durch das ${appName || "Reporting Tool"} | Seite ${i} von ${pageCount}`,
      14,
      doc.internal.pageSize.getHeight() - 10,
    );
  }

  return Buffer.from(doc.output("arraybuffer"));
}

module.exports = { generatePdf };
