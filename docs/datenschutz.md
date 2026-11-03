# Datenschutzerklärung

Diese Erklärung beschreibt, welche Personendaten die JUBL(A)PP verarbeitet, wozu und wer sie erhält. Sie gilt für die Web-App, die Android-App und die Windows-App.

> **Entwurf:** Dieser Text beschreibt die technische Datenverarbeitung nach dem Stand des Quellcodes. Angaben in `[eckigen Klammern]` muss die Schar ergänzen. Vor der Veröffentlichung sollte der Text von einer fachkundigen Person geprüft werden.

## Verantwortliche Stelle

Verantwortlich für die Datenbearbeitung ist:

- **Name:** `[Name der Schar, z. B. Jubla Wald ZH]`
- **Adresse:** `[Strasse, PLZ Ort]`
- **E-Mail:** `[Kontaktadresse der Schar]`

Anfragen zum Datenschutz richtest du an diese Adresse.

## Wer die App nutzt

Die App ist für Leitende der Schar gedacht. Der Zugang ist mit einem gemeinsamen PIN geschützt. Eine Registrierung oder persönliche Benutzerkonten gibt es nicht.

## Welche Daten verarbeitet werden

### Anmeldung

- Du gibst den PIN ein. Bei Erfolg setzt der Server ein Cookie (`auth`), das 30 Tage gültig ist. Es enthält keinen Namen, sondern nur einen aus dem PIN berechneten Wert.
- Um das Erraten des PIN zu erschweren, zählt der Server falsche Eingaben pro Absender. Dafür wird nur ein **Hash der IP-Adresse** gespeichert, nie die Adresse selbst. Der Zähler gilt 15 Minuten.

### Strikes

Bei einem Strike erfasst die App Datum, deinen Namen als Leiter:in sowie den **Namen der Kinder** und die Anzahl Strikes. Die Angaben werden in einer Google-Tabelle der Schar gespeichert. Der Server wertet frühere Einträge aus, um Ausschlüsse und Auffälligkeiten zu erkennen, und schickt dazu E-Mails an die Scharleitung. Darin stehen Kindernamen und Strikes.

Diese Angaben betreffen Kinder. Sie dürfen nur für die Gruppenstunden der Schar verwendet werden.

### Ereignis melden

Eine Ereignismeldung enthält Datum, deinen Namen und deine Funktion, Kategorie, Schweregrad, Ort, Beschreibung, betroffene Personen, Massnahmen und weitere Schritte. Du kannst bis zu zehn **Fotos** anhängen. Die Meldung wird über Netlify Forms übermittelt. Je nach Ereignis können Gesundheitsdaten oder Fotos von Personen enthalten sein. Das sind besonders schützenswerte Personendaten.

Gib nur Angaben und Fotos ein, die für die Meldung nötig sind.

### Feedback

Beim Feedback gibst du Kategorie und Nachricht ein. Die **E-Mail-Adresse ist freiwillig** und dient nur für Rückfragen. Das Feedback wird über Netlify Forms übermittelt.

### Wetter

Die Wetter-Seite fragt die Prognose für Wald/ZH direkt bei Open-Meteo (`api.open-meteo.com`) ab. Dabei sieht Open-Meteo die IP-Adresse deines Geräts. Dein Standort wird nicht abgefragt, die Koordinaten sind fest hinterlegt.

### Lager

Im Browser ist das Padlet der Schar in die Seite eingebettet. Dabei verbindet sich dein Browser mit Padlet, und es gelten die Datenschutzbestimmungen von Padlet. In der Android- und Windows-App öffnet ein Button das Padlet im Browser.

### Links

Telefonnummern und E-Mail-Adressen öffnen sich erst nach deiner Bestätigung in der Telefon- oder Mail-App deines Geräts.

### Fehlerberichte

Release-Versionen der App melden Fehler an GlitchTip (`app.glitchtip.com`). Ein Bericht enthält die Fehlermeldung, den Fehlertyp, die App-Version, die Plattform und beim Formular-Versand den Namen des Formulars und den HTTP-Status. Es werden keine Formularinhalte gesendet. Der Anbieter sieht technisch bedingt die IP-Adresse.

## Wer die Daten erhält

Die App nutzt folgende Dienstleister. Sie bearbeiten Daten in unserem Auftrag oder stellen den Dienst bereit:

| Anbieter | Zweck | Daten |
| --- | --- | --- |
| Netlify | Hosting, Funktionen, Formulare, Zähler gegen PIN-Raten | alle übermittelten Eingaben, Verbindungsdaten |
| Google (Sheets, Drive, Gmail) | Speicherung der Strikes, Versand von E-Mails an die Scharleitung | Strike-Einträge, E-Mail-Inhalte |
| GlitchTip | Fehlerberichte | technische Fehlerdaten |
| Open-Meteo | Wetterdaten | IP-Adresse des Geräts |
| Padlet | Pinnwand für das Lager | IP-Adresse und Nutzung der eingebetteten Seite |

Einige dieser Anbieter haben ihren Sitz oder ihre Server ausserhalb der Schweiz, auch in den USA. `[Angaben zu Auftragsbearbeitungsverträgen und Garantien für den Datenexport ergänzen]`

## Wie lange Daten gespeichert werden

- Cookie: 30 Tage oder bis zum Abmelden.
- Zähler gegen PIN-Raten: 15 Minuten.
- Strikes, Ereignisse und Feedback: `[Aufbewahrungsdauer festlegen, z. B. bis Ende des Scharjahres plus x Monate]`. Danach sollten die Einträge in der Google-Tabelle, in Netlify Forms und im Drive gelöscht werden.

## Deine Rechte

Du kannst Auskunft über deine Daten verlangen sowie Berichtigung, Löschung und Einschränkung der Bearbeitung. Betroffen sind auch Eltern und Kinder, deren Namen erfasst wurden. Wende dich dafür an die verantwortliche Stelle. Du kannst dich zudem bei der Datenschutzbehörde beschweren, in der Schweiz beim Eidgenössischen Datenschutz- und Öffentlichkeitsbeauftragten (EDÖB).

## Datensicherheit

Die Verbindung zur App und zum Server ist verschlüsselt (HTTPS). Das Login-Cookie ist mit `HttpOnly`, `Secure` und `SameSite=Lax` gesetzt. Daten sind nur nach der Anmeldung mit PIN zugänglich. Teile den PIN nur mit Leitenden deiner Schar.

## Änderungen

Wir passen diese Erklärung an, wenn sich die App ändert. Die aktuelle Fassung steht im Handbuch.

Stand: `[Datum eintragen]`

[Zurück zur Startseite](index.md)
