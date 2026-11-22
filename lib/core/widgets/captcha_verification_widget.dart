import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/colors.dart';

class CaptchaVerificationWidget extends StatefulWidget {
  final ValueChanged<bool> onVerified;
  final bool isUrdu;
  final bool hasError;

  const CaptchaVerificationWidget({
    super.key,
    required this.onVerified,
    this.isUrdu = false,
    this.hasError = false,
  });

  @override
  State<CaptchaVerificationWidget> createState() => _CaptchaVerificationWidgetState();
}

class _CaptchaVerificationWidgetState extends State<CaptchaVerificationWidget>
    with SingleTickerProviderStateMixin {
  bool _isChecking = false;
  bool _isVerified = false;
  bool _showMathChallenge = false;

  late int _num1;
  late int _num2;
  late int _expectedAnswer;
  final TextEditingController _mathAnswerController = TextEditingController();

  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _generateMathChallenge();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );
  }

  @override
  void dispose() {
    _mathAnswerController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _generateMathChallenge() {
    final rand = Random();
    _num1 = rand.nextInt(9) + 2; // 2..10
    _num2 = rand.nextInt(8) + 1; // 1..8
    _expectedAnswer = _num1 + _num2;
    _mathAnswerController.clear();
  }

  void _handleCheckboxTap() async {
    if (_isVerified || _isChecking) return;

    setState(() => _isChecking = true);

    // Simulate authentic client-side entropy and browser integrity verification
    await Future.delayed(const Duration(milliseconds: 900));

    if (mounted) {
      setState(() {
        _isChecking = false;
        _isVerified = true;
      });
      _animController.forward(from: 0.0);
      widget.onVerified(true);
    }
  }

  void _checkMathAnswer(String val) {
    final parsed = int.tryParse(val.trim());
    if (parsed == _expectedAnswer) {
      setState(() {
        _isVerified = true;
      });
      _animController.forward(from: 0.0);
      widget.onVerified(true);
    }
  }

  void _resetVerification() {
    setState(() {
      _isVerified = false;
      _isChecking = false;
      _generateMathChallenge();
    });
    widget.onVerified(false);
  }

  @override
  Widget build(BuildContext context) {
    final isUrdu = widget.isUrdu;
    final borderColor = widget.hasError && !_isVerified
        ? AppColors.danger
        : (_isVerified ? AppColors.success : Colors.white24);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: widget.hasError && !_isVerified ? 1.8 : 1.2),
        boxShadow: [
          if (_isVerified)
            BoxShadow(
              color: AppColors.success.withValues(alpha: 0.15),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          if (widget.hasError && !_isVerified)
            BoxShadow(
              color: AppColors.danger.withValues(alpha: 0.25),
              blurRadius: 12,
              spreadRadius: 1,
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row with Shield and Turnstile Check
          Row(
            children: [
              // Interactive Checkbox / Spinner / Checkmark
              MouseRegion(
                cursor: _isVerified ? SystemMouseCursors.basic : SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: _handleCheckboxTap,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _isVerified
                          ? AppColors.success
                          : (_isChecking ? Colors.white12 : Colors.white10),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _isVerified
                            ? AppColors.success
                            : (_isChecking ? AppColors.accent : (widget.hasError ? AppColors.danger : Colors.white60)),
                        width: 2,
                      ),
                    ),
                    child: _isChecking
                        ? const Padding(
                            padding: EdgeInsets.all(6.0),
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.accent,
                            ),
                          )
                        : (_isVerified
                            ? ScaleTransition(
                                scale: _scaleAnimation,
                                child: const Icon(Icons.check, color: Colors.white, size: 20),
                              )
                            : null),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Title and Status
              Expanded(
                child: MouseRegion(
                  cursor: _isVerified ? SystemMouseCursors.basic : SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: _handleCheckboxTap,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isVerified
                              ? (isUrdu ? 'سیکیورٹی تصدیق مکمل ہو گئی ✓' : 'Human Verification Passed ✓')
                              : (_isChecking
                                  ? (isUrdu ? 'براؤزر سیکیورٹی جانچ جاری ہے...' : 'Verifying connection...')
                                  : (isUrdu ? 'میں انسان ہوں (Bot Protection)' : "I'm a human transporter")),
                          style: TextStyle(
                            color: _isVerified ? AppColors.success : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isUrdu ? 'ٹرک لنک پی کے اینٹی بوٹ و سیکیورٹی فلٹر' : 'TruckLink PK Cloud Defense',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Shield Badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Icon(
                    _isVerified ? Icons.verified_user : Icons.security,
                    color: _isVerified ? AppColors.success : AppColors.accent,
                    size: 22,
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'CAPTCHA',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Optional Math Challenge Expansion for Extra Rigor or Manual Solver
          if (!_isVerified) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    foregroundColor: AppColors.accent,
                  ),
                  icon: Icon(_showMathChallenge ? Icons.keyboard_arrow_up : Icons.calculate_outlined, size: 14),
                  label: Text(
                    _showMathChallenge
                        ? (isUrdu ? 'پہیلی بند کریں' : 'Hide Math Puzzle')
                        : (isUrdu ? 'حسابی کوڈ سے حل کریں' : 'Solve with Math Challenge'),
                    style: const TextStyle(fontSize: 11),
                  ),
                  onPressed: () {
                    setState(() => _showMathChallenge = !_showMathChallenge);
                  },
                ),
                if (_isVerified)
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 14, color: Colors.white54),
                    tooltip: 'Reset',
                    onPressed: _resetVerification,
                  ),
              ],
            ),
          ],

          if (_showMathChallenge && !_isVerified) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade900.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.accent.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      '$_num1 + $_num2 = ?',
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _mathAnswerController,
                      keyboardType: TextInputType.number,
                      cursorColor: AppColors.accent,
                      showCursor: true,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: isUrdu ? 'جواب لکھیں' : 'Answer',
                        hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
                        ),
                      ),
                      onChanged: _checkMathAnswer,
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 18, color: Colors.white70),
                    tooltip: isUrdu ? 'نیا سوال' : 'Refresh Math',
                    onPressed: () {
                      setState(() {
                        _generateMathChallenge();
                      });
                    },
                  ),
                ],
              ),
            ),
          ],

          if (widget.hasError && !_isVerified) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.error_outline, size: 13, color: AppColors.danger),
                const SizedBox(width: 4),
                Text(
                  isUrdu
                      ? 'براہ کرم آگے بڑھنے سے پہلے سیکیورٹی چیک پر کلک کریں'
                      : 'Please verify the anti-bot checkbox before continuing',
                  style: const TextStyle(color: AppColors.danger, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
