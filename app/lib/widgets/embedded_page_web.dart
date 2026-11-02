import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';

/// Im Web wird die Seite als iframe eingebettet.
const bool embedSupported = true;

const _viewType = 'jublapp-embedded-page';
bool _registered = false;

@JS('document.createElement')
external _Element _createElement(String tag);

extension type _Element._(JSObject _) implements JSObject {
  external void setAttribute(String name, String value);
}

Widget buildEmbed(String url) {
  if (!_registered) {
    _registered = true;
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final iframe = _createElement('iframe');
      iframe.setAttribute('src', url);
      iframe.setAttribute(
        'allow',
        'camera;microphone;geolocation;display-capture;clipboard-write',
      );
      iframe.setAttribute('allowfullscreen', '');
      iframe.setAttribute('style', 'border:0;width:100%;height:100%;');
      return iframe;
    });
  }
  return const HtmlElementView(viewType: _viewType);
}
