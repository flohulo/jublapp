# Mitwirken am Jubla Reporting Tool

Danke für dein Interesse! Das Jubla Reporting Tool ist eine Web-App für Jubla zur Verwaltung von Strikes, Rapporten, Einkaufslisten, Spesen, Barkasse und Leiterplanung. Beiträge sollten Funktionalität, Datenschutz und einfache Bedienbarkeit gemeinsam berücksichtigen.

## Lokal entwickeln

Voraussetzungen: Node.js (aktuell), npm und das [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.41.1). Ausserdem wird die [Netlify CLI](https://docs.netlify.com/cli/get-started/) benötigt.

```bash
npm install
npm run dev
```

`npm run dev` baut die Flutter-Web-App nach `dist/` und startet den lokalen Netlify-Dev-Server inkl. Backend-Functions und Edge Functions. Tests: `npm test` (Flutter analyze + test).

Der Build (erzeugt Versionsdatei und baut das MkDocs-Handbuch) läuft mit:

```bash
npm run build
```

### Umgebungsvariablen

Eine `.env.local`-Datei wird für die lokale Entwicklung benötigt. Orientiere dich an `.env.example`.

## Projektstruktur

| Verzeichnis / Datei       | Inhalt                                            |
| ------------------------- | ------------------------------------------------- |
| `backend/functions/`      | Netlify Functions (API-Endpunkte)                 |
| `backend/edge-functions/` | Netlify Edge Functions (z. B. Auth)               |
| `app/`                    | Flutter-App (Web, Android, Windows)               |
| `web-extras/forms.html`   | Netlify-Forms-Deklaration (Ereignis, Feedback)    |
| `scripts/`                | Build-Skripte (Netlify, Web)                      |
| `legacy-pwa/`             | Alte PWA (nur Archiv, kann gelöscht werden)       |
| `docs/`                   | Handbuch-Quelltext (MkDocs)                       |
| `netlify.toml`            | Netlify-Konfiguration (Build, Redirects, Headers) |
| `mkdocs.yml`              | Handbuch-Navigation und -Konfiguration            |

## Dokumentation (Handbuch)

Das Handbuch liegt unter `docs/` und wird mit [MkDocs Material](https://squidfunk.github.io/mkdocs-material/) gebaut. Es wird beim Netlify-Deploy automatisch unter `dist/handbuch` veröffentlicht.

Änderungen an Seiten oder an `mkdocs.yml` vor dem Pull Request lokal prüfen:

```bash
pip install -r requirements.txt
mkdocs build
mkdocs serve
```

Die Navigation steht in `mkdocs.yml`. Neue Seiten dort eintragen und aus bestehenden Seiten verlinken, damit sie nicht verwaist sind.

## Versionierung

Die Version wird in `package.json` gepflegt. Vor einem Push auf `main` die Version in `package.json` anpassen – `npm run build` schreibt sie automatisch in die App.

## Übersetzungen

Übersetzungen werden über [Weblate auf Codeberg](https://translate.codeberg.org) verwaltet und synchronisiert.

- **Quell-Sprache**: Deutsch (`locales/de.json`)
- **Unterstützte Sprachen**: Deutsch (`de`), Französisch (`fr`), Italienisch (`it`), Englisch (`en`)
- Die Übersetzungsdateien liegen unter `locales/*.json` und werden mit `npm run build` (`update-version.js`) nach `app/assets/locales/` gespiegelt. Der Flutter-Test `app/test/i18n_test.dart` schlägt fehl, wenn Sprachen unterschiedliche Schlüssel/Platzhalter haben oder die Spiegelung veraltet ist.
- Neue UI-Texte werden in `locales/de.json` erfasst und in der App über `context.t('schluessel')` eingebunden (neue Schlüssel in allen vier Sprachen ergänzen).
- Weblate übernimmt Änderungen automatisch über Pull Requests bzw. Commits auf das Codeberg-Repository.

## Pull Requests

- Erkläre den Anwendungsfall und die Auswirkungen auf die Nutzerinnen und Nutzer.
- Halte Änderungen fokussiert.
- Teile keine Zugangsdaten, E-Mail-Adressen, personenbezogenen Daten oder Inhalte aus `.env.local` im Code oder in Issues.
- Vor einem Pull Request muss der Build (`npm run build`) erfolgreich sein.

## Sicherheit

Melde vermutete Sicherheitsprobleme privat gemäss [SECURITY.md](SECURITY.md), nicht als öffentliches Issue.

## Lizenz

Beiträge werden unter der Projektlizenz veröffentlicht (siehe [LICENSE](LICENSE)).
