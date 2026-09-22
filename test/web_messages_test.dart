@TestOn('browser')
library;

import 'dart:convert';
import 'dart:js_interop';

import 'package:flutter_test/flutter_test.dart';
import 'package:html_editor_enhanced/src/web_messages.dart';
import 'package:web/web.dart' as web;

/// The Dart ↔ iframe bridge, exercised against the real `window` in a browser.
/// Run with `flutter test --platform chrome` and again with `--wasm`: the two
/// compilers take different `dart:js_interop` paths and this file is the only
/// place that proves both deliver a message.
void main() {
  test('a JSON string posted to the window arrives decoded', () async {
    final received =
        editorMessages.firstWhere((m) => m['type'] == 'toDart: probe');
    postEditorMessage(
        json.encode({'type': 'toDart: probe', 'view': 'v1', 'text': 'hello'}));
    final message = await received.timeout(const Duration(seconds: 5));
    expect(message, {'type': 'toDart: probe', 'view': 'v1', 'text': 'hello'});
  });

  test(
      'non-JSON strings and non-string payloads are dropped, later messages still arrive',
      () async {
    final received =
        editorMessages.firstWhere((m) => m['type'] == 'toDart: after-noise');
    web.window.postMessage('definitely not json'.toJS, '*'.toJS);
    web.window.postMessage(
        <String, Object>{'type': 'object, not a string'}.jsify(), '*'.toJS);
    web.window.postMessage(42.toJS, '*'.toJS);
    web.window.postMessage(null, '*'.toJS);
    postEditorMessage(json.encode(['a', 'json', 'array']));
    postEditorMessage(json.encode({'type': 'toDart: after-noise'}));
    final message = await received.timeout(const Duration(seconds: 5));
    expect(message['type'], 'toDart: after-noise');
  });
}
