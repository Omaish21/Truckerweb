// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:js_interop';

@JS('truckLinkGetPlacePredictions')
external void _truckLinkGetPlacePredictions(
    JSString input, JSFunction callback);

Future<List<String>> fetchWebPlacePredictions(String input) {
  final completer = Completer<List<String>>();
  try {
    final callback = ((JSArray results) {
      final list = <String>[];
      for (var i = 0; i < results.length; i++) {
        final item = results[i];
        if (item != null) list.add(item.toString());
      }
      completer.complete(list);
    }).toJS;

    _truckLinkGetPlacePredictions(input.toJS, callback);
  } catch (e) {
    completer.complete(<String>[]);
  }
  return completer.future.timeout(
    const Duration(seconds: 2),
    onTimeout: () => <String>[],
  );
}
