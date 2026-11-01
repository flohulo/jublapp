import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../theme.dart';

const _border = OutlineInputBorder(
  borderRadius: BorderRadius.zero,
  borderSide: BorderSide(color: AppColors.primary, width: 2),
);

InputDecoration jublaInputDecoration({String? hint, Widget? suffixIcon}) =>
    InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF9E9E9E)),
      filled: true,
      fillColor: Colors.white,
      isDense: false,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: _border,
      enabledBorder: _border,
      focusedBorder: _border,
      errorBorder: _border,
      focusedErrorBorder: _border,
      suffixIcon: suffixIcon,
    );

/// Beschriftung über einem Eingabefeld (`.form-group` + `.form-label`).
class FormGroup extends StatelessWidget {
  const FormGroup({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.label,
            fontWeight: FontWeight.w500,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

/// Vertikale Liste von Formularfeldern mit 24 px Abstand.
class FormColumn extends StatelessWidget {
  const FormColumn({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 24),
            children[i],
          ],
        ],
      ),
    );
  }
}

class JublaTextField extends StatelessWidget {
  const JublaTextField({
    super.key,
    required this.controller,
    this.hint,
    this.keyboardType,
    this.minLines,
    this.maxLines,
    this.readOnly = false,
    this.onTap,
    this.suffixIcon,
    this.inputFormatters,
    this.autofillHints,
    this.fieldKey,
  });

  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;
  final int? minLines;
  final int? maxLines;
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? suffixIcon;
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;
  final Key? fieldKey;

  @override
  Widget build(BuildContext context) {
    final multiline = (maxLines ?? 1) > 1;
    return TextField(
      key: fieldKey,
      controller: controller,
      keyboardType:
          keyboardType ??
          (multiline ? TextInputType.multiline : TextInputType.text),
      minLines: minLines,
      maxLines: maxLines ?? 1,
      readOnly: readOnly,
      onTap: onTap,
      inputFormatters: inputFormatters,
      autofillHints: autofillHints,
      style: const TextStyle(fontSize: 16, color: AppColors.textDark),
      decoration: jublaInputDecoration(hint: hint, suffixIcon: suffixIcon),
    );
  }
}

class JublaDropdown<T> extends StatelessWidget {
  const JublaDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.placeholder,
    this.fieldKey,
  });

  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String placeholder;
  final Key? fieldKey;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      key: fieldKey,
      initialValue: value,
      isExpanded: true,
      items: items,
      onChanged: onChanged,
      hint: Text(
        placeholder,
        style: const TextStyle(color: Color(0xFF757575), fontSize: 16),
      ),
      icon: const FaIcon(FontAwesomeIcons.chevronDown, size: 14),
      style: const TextStyle(fontSize: 16, color: AppColors.textDark),
      decoration: jublaInputDecoration(),
    );
  }
}

/// Statuszeile unter dem Formular (Speichern…, Fehler, Erfolg).
class StatusMessage extends StatelessWidget {
  const StatusMessage(
    this.message, {
    super.key,
    this.isError = false,
    this.isSuccess = false,
  });

  final String message;
  final bool isError;
  final bool isSuccess;

  @override
  Widget build(BuildContext context) {
    if (message.isEmpty) return const SizedBox.shrink();
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isError
                ? AppColors.error
                : isSuccess
                ? AppColors.success
                : AppColors.textDark,
          ),
        ),
      ),
    );
  }
}

/// Zwei-stelliges Auffüllen.
String pad2(int value) => value.toString().padLeft(2, '0');

String formatDate(DateTime d) => '${pad2(d.day)}.${pad2(d.month)}.${d.year}';

String formatDateTime(DateTime d) =>
    '${formatDate(d)} ${pad2(d.hour)}:${pad2(d.minute)}';
