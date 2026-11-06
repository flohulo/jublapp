# JUBL(A)PP – Flutter-App

Eine Codebasis für Web (Netlify), Android (APK) und Windows (EXE).

```bash
flutter pub get
flutter analyze && flutter test
flutter run -d chrome            # Web (API nur mit --dart-define=API_BASE_URL=..., siehe unten)
flutter build apk --release
flutter build windows --release
```

- Native Apps sprechen mit `https://jubla-wald-reporting.netlify.app`
  (überschreibbar: `--dart-define=API_BASE_URL=https://...`).
- Das Web-Build nutzt relative URLs (gleiche Origin wie Backend, Cookie-Login).
- Übersetzungen: einziger Ort ist `assets/locales/*.json`. Der Test
  `test/i18n_test.dart` prüft Schlüssel und Platzhalter.

## Android-Signatur

Android installiert ein Update nur, wenn die APK mit demselben Schlüssel signiert ist wie die
installierte App. Die Release-Builds in der CI verwenden deshalb einen festen Keystore aus drei
GitHub-Secrets plus dem Keystore selbst. Ohne diese Secrets (lokal, PRs von Forks) wird mit dem
Debug-Schlüssel signiert; solche APKs lassen sich nicht über eine Release-APK drüberinstallieren.

Einmalig einrichten:

```bash
keytool -genkeypair -v -keystore release.keystore -alias jublapp \
  -keyalg RSA -keysize 2048 -validity 10000
base64 -w0 release.keystore   # Ausgabe als Secret ANDROID_KEYSTORE_BASE64 speichern
```

Secrets im GitHub-Repository (Settings, Secrets and variables, Actions):
`ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`.

Den Keystore und die Passwörter sicher aufbewahren (nicht im Repository): Geht der Schlüssel
verloren, kann die App nicht mehr aktualisiert werden. Beim ersten Wechsel auf den festen
Schlüssel muss die installierte App einmalig deinstalliert werden.
