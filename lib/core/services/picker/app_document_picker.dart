import 'app_document_picker_stub.dart' show PickedDocument;
import 'app_document_picker_stub.dart'
    if (dart.library.html) 'app_document_picker_web.dart';

export 'app_document_picker_stub.dart' show PickedDocument;

class AppDocumentPicker {
  static Future<PickedDocument?> pickImage() =>
      appPickDocument(accept: 'image/png,image/jpeg,image/webp');

  static Future<PickedDocument?> pickPdfOrImage() =>
      appPickDocument(accept: 'image/*,application/pdf');
}
