// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

class NativeSpeechPlatform {
  html.SpeechRecognition? _recognition;
  bool isListening = false;

  bool isSupported() {
    return html.SpeechRecognition.supported;
  }

  void startListening({
    required String lang,
    required void Function(String text) onResult,
    required void Function() onDone,
  }) {
    if (!html.SpeechRecognition.supported) {
      onDone();
      return;
    }
    try {
      _recognition = html.SpeechRecognition()
        ..continuous = false
        ..interimResults = true
        ..lang = lang;

      _recognition!.onResult.listen((event) {
        final results = event.results;
        if (results != null && results.isNotEmpty) {
          final first = results.first;
          final transcript = first.item(0).transcript;
          if (transcript != null) {
            onResult(transcript);
          }
        }
      });

      _recognition!.onEnd.listen((_) {
        isListening = false;
        onDone();
      });

      _recognition!.onError.listen((_) {
        isListening = false;
        onDone();
      });

      _recognition!.start();
      isListening = true;
    } catch (_) {
      isListening = false;
      onDone();
    }
  }

  void stop() {
    try {
      _recognition?.stop();
    } catch (_) {}
    isListening = false;
  }
}
