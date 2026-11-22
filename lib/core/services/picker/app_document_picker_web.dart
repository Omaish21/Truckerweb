// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import 'app_document_picker_stub.dart';

Future<PickedDocument?> appPickDocument({String accept = 'image/*'}) async {
  final completer = Completer<PickedDocument?>();
  final uploadInput = html.FileUploadInputElement()..accept = accept;
  uploadInput.click();

  uploadInput.onChange.listen((e) {
    final files = uploadInput.files;
    if (files != null && files.isNotEmpty) {
      final file = files[0];
      final reader = html.FileReader();
      reader.onLoadEnd.listen((e) {
        final result = reader.result;
        if (result is Uint8List) {
          completer.complete(PickedDocument(name: file.name, bytes: result));
        } else if (result is ByteBuffer) {
          completer.complete(PickedDocument(name: file.name, bytes: result.asUint8List()));
        } else if (result is List<int>) {
          completer.complete(PickedDocument(name: file.name, bytes: Uint8List.fromList(result)));
        } else {
          completer.complete(null);
        }
      });
      reader.onError.listen((e) => completer.complete(null));
      reader.readAsArrayBuffer(file);
    } else {
      completer.complete(null);
    }
  });

  return completer.future;
}
