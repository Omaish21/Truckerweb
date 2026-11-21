import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../theme/colors.dart';

class VoiceInputButton extends StatefulWidget {
  final TextEditingController controller;
  final String? languageCode; // 'ur' or 'en'
  final String? tooltip;

  const VoiceInputButton({
    super.key,
    required this.controller,
    this.languageCode,
    this.tooltip,
  });

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _isAvailable = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      _isAvailable = await _speech.initialize(
        onError: (val) {
          if (mounted) setState(() => _isListening = false);
        },
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            if (mounted) setState(() => _isListening = false);
          }
        },
      );
      if (mounted) setState(() {});
    } catch (_) {
      _isAvailable = false;
    }
  }

  void _toggleListening() async {
    if (!_isAvailable) {
      await _initSpeech();
    }

    if (_isListening) {
      await _speech.stop();
      if (mounted) setState(() => _isListening = false);
    } else {
      final localeId = widget.languageCode == 'ur' ? 'ur_PK' : 'en_US';
      try {
        final started = await _speech.listen(
          listenOptions: stt.SpeechListenOptions(
            localeId: localeId,
            listenMode: stt.ListenMode.confirmation,
            partialResults: true,
          ),
          onResult: (result) {
            if (result.recognizedWords.isNotEmpty && mounted) {
              final currentText = widget.controller.text;
              if (currentText.isEmpty) {
                widget.controller.text = result.recognizedWords;
              } else if (!currentText.contains(result.recognizedWords)) {
                widget.controller.text = '$currentText ${result.recognizedWords}';
              }
            }
          },
        );
        if (started && mounted) {
          setState(() => _isListening = true);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isListening = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: _isListening ? AppColors.danger.withValues(alpha: 0.2) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          _isListening ? Icons.mic : Icons.mic_none,
          color: _isListening ? AppColors.danger : AppColors.primary,
        ),
      ),
      tooltip: widget.tooltip ?? (_isListening ? 'Stop Listening' : 'Voice Input (اردو / English)'),
      onPressed: _toggleListening,
    );
  }
}
