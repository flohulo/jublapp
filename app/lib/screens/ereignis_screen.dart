import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../i18n/i18n.dart';
import '../router.dart';
import '../services/api_client.dart';
import '../services/error_reporter.dart';
import '../services/forms_service.dart';
import '../services/platform_services.dart';
import '../theme.dart';
import '../widgets/form_widgets.dart';
import '../widgets/page_scaffold.dart';

/// Ereignis melden. Wird – wie in der PWA – als Netlify-Form `ereignis`
/// (multipart, inkl. Fotos) gesendet. Gespeicherte Werte bleiben deutsch,
/// egal in welcher UI-Sprache ausgefüllt wird.
class EreignisScreen extends StatefulWidget {
  const EreignisScreen({super.key});

  /// Von Netlify für das Formular deklarierte Foto-Felder (`foto_1`…).
  static const int maxPhotos = 10;

  @override
  State<EreignisScreen> createState() => _EreignisScreenState();
}

class _EreignisScreenState extends State<EreignisScreen> {
  // (Wert für Netlify, i18n-Schlüssel)
  static const _functions = [
    ('Hauptleitung', 'ereignis.function_hauptleitung'),
    ('Hilfsleitung', 'ereignis.function_hilfsleitung'),
    ('Andere', 'ereignis.function_andere'),
  ];
  static const _categories = [
    ('Unfall / Medizinisch', 'ereignis.category_unfall'),
    ('Sachschaden', 'ereignis.category_sachschaden'),
    ('Konflikt / Verhalten', 'ereignis.category_konflikt'),
    ('Sonstiges', 'ereignis.category_sonstiges'),
  ];
  static const _severities = [
    ('Gering', 'ereignis.schweregrad_gering'),
    ('Mittel', 'ereignis.schweregrad_mittel'),
    ('Hoch', 'ereignis.schweregrad_hoch'),
  ];

  late DateTime _datum = _nowToMinute();
  late final _dateCtrl = TextEditingController(text: formatDateTime(_datum));
  final _melder = TextEditingController();
  final _art = TextEditingController();
  final _ort = TextEditingController();
  final _betroffene = TextEditingController();
  final _beschreibung = TextEditingController();
  final _massnahmen = TextEditingController();
  final _weiteres = TextEditingController();
  String? _funktion;
  String? _kategorie;
  String? _schweregrad;
  final List<PickedPhoto> _photos = [];

  bool _busy = false;
  String _status = '';
  bool _statusIsError = false;
  bool _statusIsSuccess = false;
  Timer? _redirect;

  static DateTime _nowToMinute() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day, n.hour, n.minute);
  }

  @override
  void dispose() {
    _redirect?.cancel();
    for (final c in [
      _dateCtrl,
      _melder,
      _art,
      _ort,
      _betroffene,
      _beschreibung,
      _massnahmen,
      _weiteres,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _setStatus(String message, {bool error = false, bool success = false}) {
    setState(() {
      _status = message;
      _statusIsError = error;
      _statusIsSuccess = success;
    });
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _datum,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 366)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_datum),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (time == null) return;
    setState(() {
      _datum = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      _dateCtrl.text = formatDateTime(_datum);
    });
  }

  void _addPhotos(List<PickedPhoto> picked) {
    if (picked.isEmpty) return;
    final i18n = context.read<I18n>();
    final room = EreignisScreen.maxPhotos - _photos.length;
    setState(() {
      _photos.addAll(picked.take(room < 0 ? 0 : room));
    });
    if (picked.length > room) {
      _setStatus(
        i18n.t('ereignis.error_too_many_photos', {
          'max': EreignisScreen.maxPhotos,
        }),
        error: true,
      );
    } else {
      _setStatus('');
    }
  }

  Future<void> _pickGallery() async {
    final picker = context.read<PhotoPicker>();
    final i18n = context.read<I18n>();
    final reporter = context.read<ErrorReporter>();
    try {
      _addPhotos(await picker.pickFromGallery());
    } catch (e) {
      reporter.reportSubmissionFailure('ereignis', e);
      if (mounted) _setStatus(i18n.t('ereignis.error_image_read'), error: true);
    }
  }

  Future<void> _takePhoto() async {
    final picker = context.read<PhotoPicker>();
    final i18n = context.read<I18n>();
    final reporter = context.read<ErrorReporter>();
    try {
      final photo = await picker.takePhoto();
      if (photo != null) _addPhotos([photo]);
    } catch (e) {
      reporter.reportSubmissionFailure('ereignis', e);
      if (mounted) {
        _setStatus(i18n.t('ereignis.error_image_process'), error: true);
      }
    }
  }

  String? _validate(I18n i18n) {
    if (_melder.text.trim().isEmpty) return i18n.t('ereignis.error_no_name');
    if (_funktion == null) return i18n.t('ereignis.error_no_function');
    if (_art.text.trim().isEmpty) return i18n.t('ereignis.error_no_art');
    if (_kategorie == null) return i18n.t('ereignis.error_no_category');
    if (_schweregrad == null) return i18n.t('ereignis.error_no_schweregrad');
    if (_ort.text.trim().isEmpty) return i18n.t('ereignis.error_no_ort');
    if (_beschreibung.text.trim().isEmpty) {
      return i18n.t('ereignis.error_no_beschreibung');
    }
    return null;
  }

  static String _datetimeLocal(DateTime d) =>
      '${d.year}-${pad2(d.month)}-${pad2(d.day)}T${pad2(d.hour)}:${pad2(d.minute)}';

  static String _extension(PickedPhoto photo) {
    switch (photo.mimeType) {
      case 'image/png':
        return 'png';
      case 'image/webp':
        return 'webp';
      case 'image/gif':
        return 'gif';
      default:
        return 'jpg';
    }
  }

  Future<void> _submit() async {
    if (_busy) return;
    final i18n = context.read<I18n>();
    final forms = context.read<FormsService>();
    final reporter = context.read<ErrorReporter>();
    final router = GoRouter.of(context);

    _setStatus('');
    final problem = _validate(i18n);
    if (problem != null) {
      _setStatus(problem, error: true);
      return;
    }

    setState(() => _busy = true);
    _setStatus(i18n.t('ereignis.saving'));

    final fields = <String, String>{
      'form-name': 'ereignis',
      'bot-field': '',
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'datum': _datetimeLocal(_datum),
      'melder_name': _melder.text.trim(),
      'melder_funktion': _funktion!,
      'kategorie': _kategorie!,
      'art': _art.text.trim(),
      'schweregrad': _schweregrad!,
      'ort': _ort.text.trim(),
      'betroffene': _betroffene.text.trim(),
      'beschreibung': _beschreibung.text.trim(),
      'massnahmen': _massnahmen.text.trim(),
      'weiteres_vorgehen': _weiteres.text.trim(),
    };
    final files = [
      for (var i = 0; i < _photos.length; i++)
        UploadFile(
          field: 'foto_${i + 1}',
          filename: 'ereignis_${i + 1}.${_extension(_photos[i])}',
          bytes: _photos[i].bytes,
          contentType: _photos[i].mimeType,
        ),
    ];

    int? statusCode;
    try {
      await forms.submitMultipart(fields, files);
      _setStatus(i18n.t('ereignis.success'), success: true);
      _redirect = Timer(const Duration(milliseconds: 1200), () {
        router.go(Routes.success);
      });
    } on UnauthorizedException {
      router.go(Routes.login);
    } catch (e) {
      if (e is ApiException) statusCode = e.statusCode;
      reporter.reportSubmissionFailure('ereignis', e, statusCode);
      if (!mounted) return;
      _setStatus(
        i18n.t('ereignis.error_save', {'message': e.toString()}),
        error: true,
      );
      setState(() => _busy = false);
    }
  }

  List<DropdownMenuItem<String>> _items(
    BuildContext context,
    List<(String, String)> options,
  ) => [
    for (final (value, key) in options)
      DropdownMenuItem(value: value, child: Text(context.t(key))),
  ];

  @override
  Widget build(BuildContext context) {
    final picker = context.read<PhotoPicker>();
    final placeholder = context.t('common.please_select');
    return PageScaffold(
      title: context.t('ereignis.title'),
      leadingTooltip: context.t('common.close'),
      onLeading: () => context.go(Routes.groupHour),
      action: HeaderAction(
        icon: FontAwesomeIcons.check,
        tooltip: context.t('common.save'),
        onPressed: _busy ? null : _submit,
      ),
      body: FormColumn(
        children: [
          FormGroup(
            label: context.t('ereignis.label_date'),
            child: JublaTextField(
              fieldKey: const Key('ereignis-date'),
              controller: _dateCtrl,
              readOnly: true,
              onTap: _pickDateTime,
              suffixIcon: const Icon(
                Icons.edit_calendar,
                color: AppColors.primary,
              ),
            ),
          ),
          FormGroup(
            label: context.t('ereignis.label_reporter_name'),
            child: JublaTextField(
              fieldKey: const Key('ereignis-melder'),
              controller: _melder,
              hint: context.t('ereignis.label_reporter_name_placeholder'),
              autofillHints: const [AutofillHints.name],
            ),
          ),
          FormGroup(
            label: context.t('ereignis.label_function'),
            child: JublaDropdown<String>(
              fieldKey: const Key('ereignis-funktion'),
              value: _funktion,
              placeholder: placeholder,
              items: _items(context, _functions),
              onChanged: (v) => setState(() => _funktion = v),
            ),
          ),
          FormGroup(
            label: context.t('ereignis.label_category'),
            child: JublaDropdown<String>(
              fieldKey: const Key('ereignis-kategorie'),
              value: _kategorie,
              placeholder: placeholder,
              items: _items(context, _categories),
              onChanged: (v) => setState(() => _kategorie = v),
            ),
          ),
          FormGroup(
            label: context.t('ereignis.label_art'),
            child: JublaTextField(
              fieldKey: const Key('ereignis-art'),
              controller: _art,
              hint: context.t('ereignis.art_placeholder'),
            ),
          ),
          FormGroup(
            label: context.t('ereignis.label_schweregrad'),
            child: JublaDropdown<String>(
              fieldKey: const Key('ereignis-schweregrad'),
              value: _schweregrad,
              placeholder: placeholder,
              items: _items(context, _severities),
              onChanged: (v) => setState(() => _schweregrad = v),
            ),
          ),
          FormGroup(
            label: context.t('ereignis.label_ort'),
            child: JublaTextField(
              fieldKey: const Key('ereignis-ort'),
              controller: _ort,
              hint: context.t('ereignis.ort_placeholder'),
            ),
          ),
          FormGroup(
            label: context.t('ereignis.label_betroffene'),
            child: JublaTextField(
              fieldKey: const Key('ereignis-betroffene'),
              controller: _betroffene,
              hint: context.t('ereignis.betroffene_placeholder'),
            ),
          ),
          FormGroup(
            label: context.t('ereignis.label_beschreibung'),
            child: JublaTextField(
              fieldKey: const Key('ereignis-beschreibung'),
              controller: _beschreibung,
              hint: context.t('ereignis.beschreibung_placeholder'),
              minLines: 4,
              maxLines: 8,
            ),
          ),
          FormGroup(
            label: context.t('ereignis.label_massnahmen'),
            child: JublaTextField(
              fieldKey: const Key('ereignis-massnahmen'),
              controller: _massnahmen,
              hint: context.t('ereignis.massnahmen_placeholder'),
              minLines: 3,
              maxLines: 8,
            ),
          ),
          FormGroup(
            label: context.t('ereignis.label_weiteres'),
            child: JublaTextField(
              fieldKey: const Key('ereignis-weiteres'),
              controller: _weiteres,
              hint: context.t('ereignis.weiteres_placeholder'),
              minLines: 2,
              maxLines: 6,
            ),
          ),
          FormGroup(
            label: context.t('ereignis.label_fotos'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _PhotoButton(
                      key: const Key('photo-gallery'),
                      icon: FontAwesomeIcons.images,
                      label: context.t('ereignis.fotos_btn'),
                      onPressed: _busy ? null : _pickGallery,
                    ),
                    if (picker.cameraSupported)
                      _PhotoButton(
                        key: const Key('photo-camera'),
                        icon: FontAwesomeIcons.camera,
                        label: context.t('ereignis.fotos_camera'),
                        onPressed: _busy ? null : _takePhoto,
                      ),
                  ],
                ),
                if (_photos.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (var i = 0; i < _photos.length; i++)
                          _PhotoPreview(
                            photo: _photos[i],
                            removeLabel: context.t('common.remove'),
                            onRemove: _busy
                                ? null
                                : () => setState(() => _photos.removeAt(i)),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          StatusMessage(
            _status,
            isError: _statusIsError,
            isSuccess: _statusIsSuccess,
          ),
        ],
      ),
    );
  }
}

class _PhotoButton extends StatelessWidget {
  const _PhotoButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final FaIconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: FaIcon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({
    required this.photo,
    required this.removeLabel,
    required this.onRemove,
  });

  final PickedPhoto photo;
  final String removeLabel;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              photo.bytes,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const ColoredBox(
                color: Colors.black12,
                child: Icon(Icons.broken_image),
              ),
            ),
          ),
          Positioned(
            top: 2,
            right: 2,
            child: Tooltip(
              message: removeLabel,
              child: InkWell(
                onTap: onRemove,
                child: const CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.black54,
                  child: Icon(Icons.close, size: 14, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
