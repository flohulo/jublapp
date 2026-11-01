const { getAccessToken } = require("./lib/google-auth");
const { getAllRows } = require("./lib/sheets-api");
const nodemailer = require("nodemailer");
const { schedule } = require("@netlify/functions");

const COL = {
  DATUM: 1,
  MELDER: 2,
  HL: 3,
  KINDER: 5,
  DYNAMIK: 7,
  BEMERKUNGEN: 8,
};

const STRIKE_COL = {
  DATUM: 1,
  NAME: 3,
  STRIKES: 4,
  AUSSCHLUSS: 5,
};

const ALARM_COL = {
  DATUM: 1,
  NAME: 2,
  STRIKES: 3,
  GRUND: 4,
  LEITER: 5,
};

/**
 * Netlify Function: mailexport
 */
const mailexport = async () => {
  console.log("Starting monthly Export task (mailexport)...");

  try {
    const token = await getAccessToken();
    const reportingSheet = process.env.SHEET_NAME || "Reporting";
    const orgName = "Jubla";
    const appName = "Jubla-Reporting Tool";
    const adminLabel = "Scharleitung";

    const allReports = await getAllRows(token, reportingSheet);
    const allStrikes = await getAllRows(token, "Strikes").catch(() => []);
    const allAlarms = await getAllRows(token, "Alarme").catch(() => []);

    const now = new Date();
    const firstDayLastMonth = new Date(
      now.getFullYear(),
      now.getMonth() - 1,
      1,
      0,
      0,
      0,
    );
    const lastDayLastMonth = new Date(
      now.getFullYear(),
      now.getMonth(),
      0,
      23,
      59,
      59,
    );
    const monthName = firstDayLastMonth.toLocaleString("de-DE", {
      month: "long",
      year: "numeric",
    });

    const monthlyReports = allReports.filter((row) => {
      const date = new Date(row[COL.DATUM]);
      return (
        !isNaN(date) && date >= firstDayLastMonth && date <= lastDayLastMonth
      );
    });

    const monthlyStrikes = allStrikes.filter((row) => {
      const date = new Date(row[STRIKE_COL.DATUM]);
      return (
        !isNaN(date) && date >= firstDayLastMonth && date <= lastDayLastMonth
      );
    });

    const monthlyAlarms = allAlarms.filter((row) => {
      const date = new Date(row[ALARM_COL.DATUM]);
      return (
        !isNaN(date) && date >= firstDayLastMonth && date <= lastDayLastMonth
      );
    });

    const { generatePdf } = require("./lib/pdf-gen");
    const metadata = {
      title: `${orgName} Export – ${monthName}`,
      subtitle: `Erstellt am: ${now.toLocaleString("de-DE")}`,
      orgName,
      appName,
    };

    const reports = monthlyReports.map((r) => ({
      datum: r[COL.DATUM],
      hl: r[COL.HL],
      kinder: r[COL.KINDER],
      dynamik: r[COL.DYNAMIK],
      bemerkungen: r[COL.BEMERKUNGEN],
    }));

    const strikes = monthlyStrikes.map((s) => ({
      datum: s[STRIKE_COL.DATUM],
      name: s[STRIKE_COL.NAME],
      strikes: s[STRIKE_COL.STRIKES],
      ausschluss: s[STRIKE_COL.AUSSCHLUSS],
    }));

    const alarms = monthlyAlarms.map((a) => ({
      datum: a[ALARM_COL.DATUM],
      name: a[ALARM_COL.NAME],
      strikes: a[ALARM_COL.STRIKES],
      grund: a[ALARM_COL.GRUND],
    }));

    const pdfBuffer = generatePdf(reports, strikes, alarms, metadata);

    const transporter = nodemailer.createTransport({
      host: "smtp.gmail.com",
      port: 465,
      secure: true,
      auth: {
        user: process.env.SMTP_USER,
        pass: process.env.SMTP_PASS,
      },
    });

    await transporter.sendMail({
      from: `"${appName}" <${process.env.SMTP_USER}>`,
      to: process.env.SCHARLEITUNG_EMAIL || process.env.SMTP_USER,
      subject: `${orgName} Export – ${monthName}`,
      text: `Hoi ${adminLabel},\n\nanbei findest du den Export für ${monthName} inkl. der erkannten Verhaltensmuster.\n\nLiebe Grüsse,\nDein ${appName}`,
      attachments: [
        {
          filename: `Export_${monthName.replace(/\s/g, "_")}.pdf`,
          content: pdfBuffer,
        },
      ],
    });

    return { statusCode: 200, body: "Export gesendet" };
  } catch (error) {
    console.error("Export failed:", error);
    return { statusCode: 500, body: JSON.stringify({ error: error.message }) };
  }
};

exports.handler = schedule("0 0 1 * *", mailexport);
