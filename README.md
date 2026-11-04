<div align="center">

# JUBL(A)PP

**Die App für die Gruppenstunde: Strikes, Ereignisse, Wetter und Links an einem Ort.**

[![CI](https://github.com/flohulo/jublapp/actions/workflows/ci.yml/badge.svg)](https://github.com/flohulo/jublapp/actions/workflows/ci.yml)
[![Netlify Status](https://api.netlify.com/api/v1/badges/5f437261-5c16-4d69-87a1-6d7bb4cb87f6/deploy-status)](https://app.netlify.com/projects/jubla-wald-reporting/deploys)
![Flutter](https://img.shields.io/badge/Flutter-3.47-02569B?logo=flutter&logoColor=white)
![Plattformen](https://img.shields.io/badge/Web%20%C2%B7%20Android%20%C2%B7%20Windows-eine%20Codebasis-4c9a2a)
![Sprachen](https://img.shields.io/badge/Sprachen-DE%20%C2%B7%20GSW%20%C2%B7%20FR%20%C2%B7%20IT%20%C2%B7%20EN-blue)
[![Lizenz: AGPL-3.0](https://img.shields.io/badge/Lizenz-AGPL--3.0-lightgrey)](LICENSE)

</div>

Die JUBL(A)PP unterstützt Leitende der Jubla Wald ZH im Scharalltag. Sie läuft auf dem Smartphone, im Browser und unter Windows, aus einer einzigen Flutter-Codebasis, und ist mit dem Netlify-Backend der Schar verbunden.

## Funktionen

| Funktion              | Wofür                                                |
| --------------------- | ---------------------------------------------------- |
| **Strike**            | Strikes für bis zu vier Kinder erfassen              |
| **Ereignis melden**   | Unfälle, Konflikte und Sachschäden dokumentieren     |
| **Wetter**            | Wetter für die Gruppenstunde im Blick                |
| **Links**             | Notfallnummern, Jubla-Webseiten und Kontakte         |
| **Lager**             | Padlet der Schar fürs Lager, im Web eingebettet      |
| **Feedback**          | Fehler melden und Ideen einreichen, direkt in der App |

Die Anleitungen für Leitende stehen im Handbuch (Quelltext in [`docs/`](docs/index.md)). Es wird beim Deploy unter `dist/handbuch` veröffentlicht.

## Aufbau

```mermaid
flowchart LR
    App["Flutter-App<br/>Web, Android, Windows"] -->|"/api/*"| Edge["Edge Function<br/>auth"]
    Edge --> Fn["Netlify Functions<br/>strikes, ereignis, kalender, ..."]
    Fn --> Google["Google<br/>Sheets und Drive"]
    App -->|"Formulare"| Forms["Netlify Forms<br/>Ereignis, Feedback"]
    App -.->|"Fehlerberichte"| GT["GlitchTip"]
```

| Ordner                    | Inhalt                                              |
| ------------------------- | --------------------------------------------------- |
| `app/`                    | Flutter-App                                         |
| `backend/functions/`      | Netlify Functions (API-Endpunkte)                   |
| `backend/edge-functions/` | Auth-Prüfung vor allen Daten-Endpunkten             |
| `web-extras/forms.html`   | Formular-Deklaration für Netlify Forms              |
| `app/assets/locales/`     | Übersetzungen (Deutsch, Schweizerdeutsch, Französisch, Italienisch, Englisch) |
| `docs/`                   | Handbuch (MkDocs)                                   |

## Loslegen

Voraussetzungen: Node.js, npm, [Flutter](https://docs.flutter.dev/get-started/install) 3.47.9 und die Netlify CLI.

```bash
npm install
cp .env.example .env.local   # Werte eintragen, nie committen
npm run dev                  # Web-App bauen und lokal mit Backend starten
npm test                     # flutter analyze und flutter test
```

Mehr dazu, zur Projektstruktur und zu Übersetzungen steht in [CONTRIBUTING.md](CONTRIBUTING.md). Befehle zur Flutter-App findest du in [`app/README.md`](app/README.md).

## Mitmachen

Beiträge sind willkommen. Bitte lies zuerst [CONTRIBUTING.md](CONTRIBUTING.md). Sicherheitsprobleme meldest du privat gemäss [SECURITY.md](SECURITY.md).

## Lizenz

[GNU Affero General Public License v3.0](LICENSE)
