// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

class NativeTtsPlatform {
  void speak(String text, {String lang = 'ur-PK', double rate = 0.9}) {
    try {
      final synth = html.window.speechSynthesis;
      if (synth == null) return;
      synth.cancel();
      final utterance = html.SpeechSynthesisUtterance(text);
      utterance.lang = lang;
      utterance.rate = rate;
      synth.speak(utterance);
    } catch (_) {}
  }

  void stop() {
    try {
      html.window.speechSynthesis?.cancel();
    } catch (_) {}
  }
}
