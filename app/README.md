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
- Übersetzungen: Quelle ist `../locales/*.json` (Weblate). `node ../update-version.js`
  spiegelt sie nach `assets/locales/`. Der Test `test/i18n_test.dart` prüft
  Schlüssel, Platzhalter und Spiegelung.
