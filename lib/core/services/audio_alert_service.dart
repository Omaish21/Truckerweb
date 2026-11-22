import 'tts/native_tts.dart';

class AudioAlertService {
  static final AudioAlertService _instance = AudioAlertService._internal();
  factory AudioAlertService() => _instance;
  AudioAlertService._internal();

  Future<void> speakWarning({required String text, String languageCode = 'ur'}) async {
    final lang = languageCode == 'ur' ? 'ur-PK' : 'en-US';
    NativeTts.speak(text, lang: lang, rate: 0.9);
  }

  Future<void> stop() async {
    NativeTts.stop();
  }
}
