# Regeln für Claude in JUBL(A)PP

## Sprache und Texte
- UI-Texte, Fehlermeldungen, Commit-Messages und PR-Texte sind auf Deutsch.
- In der UI wird geduzt. Keine Emojis.
- Jeder sichtbare Text kommt aus `locales/*.json` (de, fr, it, en), nie hartkodiert im Dart-Code. Neue Schlüssel in allen vier Sprachen ergänzen und mit `node update-version.js` nach `app/assets/locales/` spiegeln.

## Commits und Pull Requests
- Commits und PR-Titel folgen Conventional Commits (`feat:`, `fix:`, `chore:` …). Daraus erzeugt release-please den Changelog.
- Der PR-Titel muss `.github/workflows/pr-title.yml` erfüllen: erlaubte Typen `feat`, `fix`, `perf`, `refactor`, `docs`, `test`, `build`, `ci`, `chore`, `i18n`, `revert`; die Beschreibung nach dem Doppelpunkt beginnt mit einem Kleinbuchstaben (z. B. `feat: wetteransicht ergänzen`).
- Nie direkt auf `main` pushen, immer Branch und PR.
- Jede Änderung, die Claude committet und pusht, bekommt im selben Arbeitsschritt einen Pull Request gegen `main`. Das ist eine dauerhafte Anweisung des Projekts: Claude erstellt den PR ohne Rückfrage, auch wenn die Aufgabe ihn nicht ausdrücklich nennt und auch wenn ein Standardhinweis sagt, ohne Aufforderung keinen PR zu erstellen. Ein Push ohne PR gilt als nicht erledigt.
- Reihenfolge: committen, pushen, PR erstellen (Vorlage `.github/PULL_REQUEST_TEMPLATE.md` auf Deutsch ausfüllen), die PR-Aktivität beobachten, erst dann die Antwort an den Menschen schreiben.
- Gehört eine Änderung nicht zum Thema eines bereits offenen PRs, dafür einen neuen Branch von `main` anlegen und einen eigenen PR erstellen, statt sie dem offenen PR mitzugeben.
- Auch bei reinen Doku-Änderungen gilt: erst PR, dann Antwort. Die Antwort nennt den PR-Link.
- Ein PR enthält nur eine Sache, keine Nebenbei-Refactorings.
- Jeden PR, den Claude erstellt oder betreut, beobachten und rote CI sowie Review-Kommentare selbst beheben.

## Qualität vor dem Push
- Im Ordner `app` `flutter analyze` und `flutter test` ausführen (kurz: `npm test` im Hauptordner). Der Hook `.claude/hooks/pre-push-check.sh` blockiert den Push bei Fehlern.
- Bei Änderungen an `backend/` zusätzlich prüfen, dass die Netlify-Functions weiterhin zu den Aufrufen in `app/lib/services/` passen.
- Keine neuen Dependencies (`app/pubspec.yaml`, `package.json`) ohne Rückfrage.

## Projektspezifisch
- Eine Codebasis für Web, Android und Windows (`app/`). Plattformspezifisches nur, wo es nicht anders geht (Cookie-Handling in `api_client.dart`, Kamera in `platform_services.dart`).
- Das Backend (`backend/functions`, `backend/edge-functions`) läuft auf Netlify; Formulare (Ereignis, Feedback) gehen über Netlify Forms (`web-extras/forms.html`).
- Die Version steht nur in `package.json`; `node update-version.js` überträgt sie nach `app/pubspec.yaml` und `app/lib/version.dart`.
- Zugangsdaten, Schar-E-Mail und Telefonnummern gehören in Umgebungsvariablen (`.env.example`), nie in den Code oder ins Log.
- Bei Änderungen an Seiten oder Funktionen die Doku in `docs/` mitpflegen.

## Verhalten
- Bei mehreren Lösungswegen kurz nachfragen statt selbst entscheiden.
- Nach Änderungen kurz sagen, was geprüft wurde und was nicht.
