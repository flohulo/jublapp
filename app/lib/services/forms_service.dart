import 'api_client.dart';

/// Versand der Netlify-Forms (Ereignis, Feedback).
///
/// Netlify erkennt die Formulare anhand von `forms.html` (siehe
/// `web-extras/forms.html`); die Feldnamen müssen dort 1:1 deklariert sein.
class FormsService {
  FormsService(this._api);

  final ApiClient _api;

  /// Existierender, nicht öffentlicher Pfad der Site – dort läuft die
  /// Auth-Prüfung der Edge Function wie für alle Formular-Posts.
  static const String path = '/forms.html';

  Future<void> submitUrlEncoded(Map<String, String> fields) async {
    final response = await _api.postForm(path, fields);
    _ensureOk(response.statusCode);
  }

  Future<void> submitMultipart(
    Map<String, String> fields,
    List<UploadFile> files,
  ) async {
    final response = await _api.postMultipart(path, fields, files);
    _ensureOk(response.statusCode);
  }

  void _ensureOk(int status) {
    if (status >= 400) {
      throw ApiException('Form submission rejected', statusCode: status);
    }
  }
}
