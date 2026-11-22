import 'native_tts_stub.dart'
    if (dart.library.html) 'native_tts_web.dart';

class NativeTts {
  static final NativeTtsPlatform _platform = NativeTtsPlatform();

  static void speak(String text, {String lang = 'ur-PK', double rate = 0.9}) {
    _platform.speak(text, lang: lang, rate: rate);
  }

  static void stop() {
    _platform.stop();
  }
}
