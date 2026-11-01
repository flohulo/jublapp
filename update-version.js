const fs = require("fs");
const path = require("path");

// 1. Version aus der package.json auslesen
const packageJson = require("./package.json");
const version = packageJson.version;

console.log(`Patsche Version ${version} in die Flutter-App...`);

// Android-versionCode / Windows-Build-Nummer: 0.8.6 -> 806, 1.2.3 -> 10203
const [major, minor, patch] = version
  .split(".")
  .map((n) => parseInt(n, 10) || 0);
const buildNumber = major * 10000 + minor * 100 + patch;

const appDir = path.join(__dirname, "app");

// 2. pubspec.yaml patschen
const pubspecPath = path.join(appDir, "pubspec.yaml");
if (fs.existsSync(pubspecPath)) {
  let pubspec = fs.readFileSync(pubspecPath, "utf8");
  pubspec = pubspec.replace(
    /^version:\s*.+$/m,
    `version: ${version}+${buildNumber}`,
  );
  fs.writeFileSync(pubspecPath, pubspec, "utf8");
}

// 3. lib/version.dart (Anzeige im Login, Fehlerberichte)
const versionDartPath = path.join(appDir, "lib", "version.dart");
fs.writeFileSync(
  versionDartPath,
  `// GENERIERT von update-version.js aus package.json – nicht von Hand ändern.\nconst String appVersion = '${version}';\n`,
  "utf8",
);

// 4. locales (Weblate-Quelle) in die App-Assets spiegeln
const localesSrc = path.join(__dirname, "locales");
const localesDest = path.join(appDir, "assets", "locales");
if (fs.existsSync(localesSrc)) {
  fs.mkdirSync(localesDest, { recursive: true });
  for (const file of fs.readdirSync(localesSrc)) {
    if (file.endsWith(".json")) {
      fs.copyFileSync(
        path.join(localesSrc, file),
        path.join(localesDest, file),
      );
    }
  }
}

console.log("Fertig!");
