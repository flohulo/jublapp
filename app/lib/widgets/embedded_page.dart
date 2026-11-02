// Eingebettete Webseite (iframe). Nur im Web verfügbar; auf Android und
// Windows liefert die Stub-Variante `embedSupported == false`.
export 'embedded_page_stub.dart'
    if (dart.library.js_interop) 'embedded_page_web.dart';
