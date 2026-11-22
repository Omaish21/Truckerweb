import 'package:flutter/foundation.dart';

class NativeTtsPlatform {
  void speak(String text, {String lang = 'ur-PK', double rate = 0.9}) {
    debugPrint('[NativeTts Stub] Speaking ($lang): $text');
  }

  void stop() {
    debugPrint('[NativeTts Stub] Speech stopped');
  }
}
