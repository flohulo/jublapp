import 'package:flutter/widgets.dart';

/// Native Plattformen betten keine Webseiten ein.
const bool embedSupported = false;

Widget buildEmbed(String url) => const SizedBox.shrink();
