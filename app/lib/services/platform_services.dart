import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import 'api_client.dart';

/// Öffnet Links (Web, Telefon, E-Mail). Abstrahiert für Tests.
abstract class UrlOpener {
  /// [sameTab] gilt nur im Web (z. B. Handbuch im selben Tab).
  Future<bool> open(Uri uri, {bool sameTab = false});
}

class DefaultUrlOpener implements UrlOpener {
  const DefaultUrlOpener();

  @override
  Future<bool> open(Uri uri, {bool sameTab = false}) async {
    try {
      return await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: sameTab ? '_self' : '_blank',
      );
    } catch (_) {
      return false;
    }
  }
}

class PickedPhoto {
  const PickedPhoto({
    required this.name,
    required this.bytes,
    this.mimeType = 'image/jpeg',
  });
  final String name;
  final Uint8List bytes;
  final String mimeType;
}

/// Fotoauswahl für das Ereignis-Formular. Abstrahiert für Tests.
abstract class PhotoPicker {
  /// Kamera-Aufnahme verfügbar (Android/iOS; im Web wählt der Browser selbst).
  bool get cameraSupported;
  Future<List<PickedPhoto>> pickFromGallery();
  Future<PickedPhoto?> takePhoto();
}

/// Bilder werden wie in der PWA auf max. 1024 px skaliert und als JPEG mit
/// Qualität 70 übernommen.
class ImagePickerPhotoPicker implements PhotoPicker {
  ImagePickerPhotoPicker({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;
  static const double _maxSize = 1024;
  static const int _quality = 70;

  @override
  bool get cameraSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Future<List<PickedPhoto>> pickFromGallery() async {
    final files = await _picker.pickMultiImage(
      maxWidth: _maxSize,
      maxHeight: _maxSize,
      imageQuality: _quality,
    );
    return Future.wait(files.map(_convert));
  }

  @override
  Future<PickedPhoto?> takePhoto() async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: _maxSize,
      maxHeight: _maxSize,
      imageQuality: _quality,
    );
    return file == null ? null : _convert(file);
  }

  Future<PickedPhoto> _convert(XFile file) async => PickedPhoto(
    name: file.name,
    bytes: await file.readAsBytes(),
    mimeType: _mime(file),
  );

  static String _mime(XFile file) {
    final fromFile = file.mimeType;
    if (fromFile != null && fromFile.startsWith('image/')) return fromFile;
    final name = file.name.toLowerCase();
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.webp')) return 'image/webp';
    if (name.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }
}

/// Server-Konfiguration (`/api/config`).
class RemoteConfig {
  const RemoteConfig({this.scharEmail = '', this.supportPhone = ''});
  final String scharEmail;
  final String supportPhone;
}

class ConfigService {
  ConfigService(this._api);
  final ApiClient _api;

  Future<RemoteConfig> load() async {
    final response = await _api.get('/api/config');
    if (response.statusCode != 200) {
      throw ApiException('Config failed', statusCode: response.statusCode);
    }
    final data =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return RemoteConfig(
      scharEmail: (data['SCHAR_EMAIL'] ?? '') as String,
      supportPhone: (data['SUPPORT_PHONE'] ?? '') as String,
    );
  }
}
