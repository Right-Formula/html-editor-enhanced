import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// The `window.postMessage` bridge between Dart and the Summernote iframe, on
/// `package:web` so it compiles under dart2wasm as well as dart2js.
///
/// Both directions use `window` (not the iframe's `contentWindow`) with a
/// `'*'` origin, as before: the iframe is a `srcdoc` document, so it shares
/// the page's origin, and every message carries a `view` id that listeners
/// filter on.
///
/// Messages that are not JSON object strings (other libraries, browser
/// extensions, the Flutter engine's own traffic) are dropped rather than
/// thrown on. `json.decode(event.data)` was previously called blind, which
/// only worked because such messages were rare.
Stream<Map<String, dynamic>> get editorMessages =>
    web.EventStreamProviders.messageEvent
        .forTarget(web.window)
        .map(_decode)
        .where((m) => m != null)
        .cast<Map<String, dynamic>>();

Map<String, dynamic>? _decode(web.MessageEvent event) {
  final data = event.data;
  if (data == null || !data.isA<JSString>()) return null;
  try {
    final decoded = json.decode((data as JSString).toDart);
    return decoded is Map<String, dynamic> ? decoded : null;
  } on FormatException {
    return null;
  }
}

/// Posts an already JSON-encoded message to the window for the iframe.
void postEditorMessage(String json) {
  web.window.postMessage(json.toJS, '*'.toJS);
}
