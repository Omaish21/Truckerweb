import 'package:flutter/material.dart';
import '../services/speech/native_speech.dart';
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
  bool _isListening = false;

  void _toggleListening() {
    if (_isListening) {
      NativeSpeech.stop();
      setState(() => _isListening = false);
    } else {
      final lang = widget.languageCode == 'ur' ? 'ur-PK' : 'en-US';
      setState(() => _isListening = true);

      NativeSpeech.startListening(
        lang: lang,
        onResult: (text) {
          if (mounted) {
            final currentText = widget.controller.text;
            if (currentText.isEmpty) {
              widget.controller.text = text;
            } else {
              widget.controller.text = '$currentText $text';
            }
          }
        },
        onDone: () {
          if (mounted) {
            setState(() => _isListening = false);
          }
        },
      );
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
      tooltip: widget.tooltip ?? (_isListening ? 'Listening...' : 'Voice Input (اردو / English)'),
      onPressed: _toggleListening,
    );
  }
}
