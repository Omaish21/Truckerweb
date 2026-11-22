import 'native_speech_stub.dart'
    if (dart.library.html) 'native_speech_web.dart';

class NativeSpeech {
  static final NativeSpeechPlatform _platform = NativeSpeechPlatform();

  static bool isSupported() => _platform.isSupported();

  static bool get isListening => _platform.isListening;

  static void startListening({
    required String lang,
    required void Function(String text) onResult,
    required void Function() onDone,
  }) {
    _platform.startListening(
      lang: lang,
      onResult: onResult,
      onDone: onDone,
    );
  }

  static void stop() {
    _platform.stop();
  }
}
