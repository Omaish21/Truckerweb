class NativeSpeechPlatform {
  bool isListening = false;

  bool isSupported() => false;

  void startListening({
    required String lang,
    required void Function(String text) onResult,
    required void Function() onDone,
  }) {
    onDone();
  }

  void stop() {
    isListening = false;
  }
}
