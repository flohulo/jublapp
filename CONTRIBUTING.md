# Mitwirken am Jubla Reporting Tool

Danke für dein Interesse! Das Jubla Reporting Tool ist eine Flutter-App (Web, Android, Windows) für Jubla zur Erfassung von Strikes und Ereignissen sowie für Wetter, Feedback und Links. Beiträge sollten Funktionalität, Datenschutz und einfache Bedienbarkeit gemeinsam berücksichtigen.

## Lokal entwickeln

Voraussetzungen: Node.js (aktuell), npm und das [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.47.9). Ausserdem wird die [Netlify CLI](https://docs.netlify.com/cli/get-started/) benötigt.

```bash
npm install
npm run dev
```

`npm run dev` baut die Flutter-Web-App nach `dist/` und startet den lokalen Netlify-Dev-Server inkl. Backend-Functions und Edge Functions. Tests: `npm test` (Backend-Tests mit `node --test`, dann Flutter analyze + test).

Die Version und die Übersetzungen werden in die App übertragen mit:

```bash
npm run build
```

### Umgebungsvariablen

Eine `.env.local`-Datei wird für die lokale Entwicklung benötigt. Orientiere dich an `.env.example`.

Für den Login brauchst du `PIN` und `SESSION_SECRET` (zufällig, mindestens 32 Zeichen, z. B. mit `openssl rand -hex 32`). Fehlt eines von beiden, ist kein Login möglich. Das `SESSION_SECRET` muss auch in den Netlify-Umgebungsvariablen gesetzt sein. Wer es ändert, meldet damit alle Geräte ab.

## Projektstruktur

| Verzeichnis / Datei       | Inhalt                                            |
| ------------------------- | ------------------------------------------------- |
| `backend/functions/`      | Netlify Functions (API-Endpunkte)                 |
| `backend/edge-functions/` | Netlify Edge Functions (z. B. Auth)               |
| `app/`                    | Flutter-App (Web, Android, Windows)               |
| `web-extras/forms.html`   | Netlify-Forms-Deklaration (Ereignis, Feedback)    |
| `scripts/`                | Build-Skripte (Netlify, Web)                      |
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

Alle Übersetzungen liegen an einem einzigen Ort: `app/assets/locales/*.json`. Es gibt keine Kopie und keinen externen Übersetzungsdienst.

- **Quell-Sprache**: Deutsch (`app/assets/locales/de.json`)
- **Unterstützte Sprachen**: Deutsch (`de`), Französisch (`fr`), Italienisch (`it`), Englisch (`en`)
- Neue UI-Texte werden in `de.json` erfasst und in der App über `context.t('schluessel')` eingebunden. Neue Schlüssel in allen vier Sprachen ergänzen.
- Der Flutter-Test `app/test/i18n_test.dart` schlägt fehl, wenn Sprachen unterschiedliche Schlüssel oder Platzhalter haben.

## Pull Requests

- Erkläre den Anwendungsfall und die Auswirkungen auf die Nutzerinnen und Nutzer.
- Halte Änderungen fokussiert.
- Teile keine Zugangsdaten, E-Mail-Adressen, personenbezogenen Daten oder Inhalte aus `.env.local` im Code oder in Issues.
- Vor einem Pull Request müssen `flutter analyze` und `flutter test` (kurz: `npm test`) fehlerfrei laufen.

## Sicherheit

Melde vermutete Sicherheitsprobleme privat gemäss [SECURITY.md](SECURITY.md), nicht als öffentliches Issue.

## Lizenz

Beiträge werden unter der Projektlizenz veröffentlicht (siehe [LICENSE](LICENSE)).
