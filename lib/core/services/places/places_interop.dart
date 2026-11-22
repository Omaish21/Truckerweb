import 'places_interop_stub.dart'
    if (dart.library.html) 'places_interop_web.dart';

Future<List<String>> getWebPlacePredictions(String input) =>
    fetchWebPlacePredictions(input);
