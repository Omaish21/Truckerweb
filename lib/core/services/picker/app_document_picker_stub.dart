import 'dart:typed_data';

class PickedDocument {
  final String name;
  final Uint8List bytes;

  const PickedDocument({required this.name, required this.bytes});
}

Future<PickedDocument?> appPickDocument({String accept = 'image/*'}) async {
  return null;
}
