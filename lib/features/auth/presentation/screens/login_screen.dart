import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/app_scope.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/captcha_verification_widget.dart';
import '../../../../core/widgets/cinematic_hero_background.dart';
import '../../../../core/widgets/language_toggle_button.dart';
import '../../../../core/widgets/logistics_video_dialog.dart';
import '../../../../core/widgets/trust_banner.dart';
import '../../../../l10n/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  int _selectedTab = 0; // 0: Phone OTP, 1: Email/Password
  bool _isCaptchaVerified = false;
  bool _captchaError = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSendOtp() async {
    if (_isSubmitting || context.auth.isLoading) return;

    if (!_isCaptchaVerified) {
      setState(() => _captchaError = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.danger,
          content: Text(
            Localizations.localeOf(context).languageCode == 'ur'
                ? 'براہ کرم سیکیورٹی چیک (CAPTCHA) مکمل کریں'
                : 'Please complete the anti-bot verification check (CAPTCHA)',
          ),
        ),
      );
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isSubmitting = true);
      try {
        final phone = AppValidators.normalizePhone(_phoneController.text);
        await context.authActions.sendOtp(phone);
        if (mounted) {
          final error = context.auth.errorMessage;
          if (error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: AppColors.danger,
                duration: const Duration(seconds: 8),
                content: SelectableText(
                  error,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                action: SnackBarAction(
                  label: 'DISMISS',
                  textColor: Colors.white,
                  onPressed: () {},
                ),
              ),
            );
          }
        }
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    }
  }

  void _handleVerifyOtp() async {
    if (_isSubmitting || context.auth.isLoading) return;

    final rawOtp = _otpController.text;
    final cleanOtp = rawOtp.replaceAll(RegExp(r'\D'), '');

    if (cleanOtp.length != 6) {
      final isUrdu = Localizations.localeOf(context).languageCode == 'ur';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.danger,
          content: Text(
            isUrdu
                ? 'براہ کرم مکمل ۶ ہندسوں کا تصدیقی کوڈ درج کریں'
                : 'Please enter the complete 6-digit OTP code',
          ),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final success = await context.authActions.verifyOtp(cleanOtp);
      if (success && mounted) {
        context.go('/role-selection');
      } else if (mounted) {
        final error = context.auth.errorMessage;
        if (error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.danger,
              duration: const Duration(seconds: 8),
              content: SelectableText(
                error,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              action: SnackBarAction(
                label: 'DISMISS',
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _handleEmailLogin() async {
    if (!_isCaptchaVerified) {
      setState(() => _captchaError = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.danger,
          content: Text(
            Localizations.localeOf(context).languageCode == 'ur'
                ? 'براہ کرم سیکیورٹی چیک (CAPTCHA) مکمل کریں'
                : 'Please complete the anti-bot verification check (CAPTCHA)',
          ),
        ),
      );
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      final success = await context.authActions.signInWithEmailPassword(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );
      if (success && mounted) {
        context.go('/role-selection');
      }
    }
  }

  void _openVideoShowcase() {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => const LogisticsVideoDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.auth.state;
    final l10n = AppLocalizations.of(context)!;
    final isUrdu = Localizations.localeOf(context).languageCode == 'ur';
    final screenSize = MediaQuery.of(context).size;
    final isWideScreen = screenSize.width > 900;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const AppLogoWithTitle(iconSize: 28, isLight: true),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: const BorderSide(color: AppColors.accent, width: 1.2),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  icon: const Icon(Icons.play_circle_fill, size: 18),
                  label: Text(
                    isUrdu ? 'ویڈیو دیکھیں' : 'Video Showcase',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  onPressed: _openVideoShowcase,
                ),
                const SizedBox(width: 12),
                const LanguageToggleButton(),
              ],
            ),
          ),
        ],
      ),
      body: CinematicHeroBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: isWideScreen
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Left Column: Hero branding, statistics, video showcase trigger & trust
                          Expanded(
                            flex: 6,
                            child: _buildHeroColumn(isUrdu, l10n),
                          ),
                          const SizedBox(width: 48),
                          // Right Column: Frosted Glass Login Box
                          Expanded(
                            flex: 5,
                            child: _buildGlassLoginCard(authState, l10n, isUrdu),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildMobileHeroHeader(isUrdu, l10n),
                          const SizedBox(height: 24),
                          _buildGlassLoginCard(authState, l10n, isUrdu),
                          const SizedBox(height: 28),
                          TrustBanner(onWatchVideo: _openVideoShowcase),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroColumn(bool isUrdu, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppLogoWithTitle(
          iconSize: 48,
          isLight: true,
          titleStyle: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),

        // Verified Government & Security Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.6)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.verified, color: AppColors.accent, size: 16),
              const SizedBox(width: 8),
              Text(
                isUrdu ? 'پاکستان کا آفیشل ڈیجیٹل فریٹ نیٹ ورک' : 'Pakistan Official Digital Freight Platform',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Grand Title with gradient accent
        Text(
          isUrdu ? 'لاکھوں ٹن مال برداری، محفوظ اور بااعتماد' : 'Pakistan’s Leading\nDigital Freight Network',
          style: TextStyle(
            fontSize: isUrdu ? 38 : 42,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            height: 1.15,
            letterSpacing: isUrdu ? 0 : -0.5,
          ),
        ),
        const SizedBox(height: 16),

        Text(
          isUrdu
              ? 'نادرا سے تصدیق شدہ ڈرائیورز، کم اونچائی والے پلوں کی وارننگ اور بغیر کمیشن براہ راست بولی۔'
              : 'NADRA verified drivers, automated low-bridge collision prevention, M-5/N-5 corridor routing, and zero-commission instant bidding.',
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white70,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 28),

        // Interactive Video Showcase Card
        InkWell(
          onTap: _openVideoShowcase,
          mouseCursor: SystemMouseCursors.click,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.accent.withValues(alpha: 0.25),
                  AppColors.primaryLight.withValues(alpha: 0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent,
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 34),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            isUrdu ? 'پلیٹ فارم کا ویڈیو تعارف دیکھیں' : 'Watch Interactive Platform Showcase',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.danger,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '4K VIDEO',
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isUrdu ? 'CPEC کوریڈور، نادرا تصدیق اور لائیو الرٹس کا عملی مظاہرہ' : 'See live CPEC transit, smart bridge clearance & bidding flow in action',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white70),
              ],
            ),
          ),
        ),

        const SizedBox(height: 32),

        // Live Corridor & Trust Stats Strip
        TrustBanner(onWatchVideo: _openVideoShowcase),
      ],
    );
  }

  Widget _buildMobileHeroHeader(bool isUrdu, AppLocalizations l10n) {
    return Column(
      children: [
        const AppLogo(
          size: 76,
          borderRadius: 20,
          showGlow: true,
        ),
        const SizedBox(height: 14),
        Text(
          l10n.appTitle,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.appSubtitle,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.accent,
            side: const BorderSide(color: AppColors.accent, width: 1.2),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          icon: const Icon(Icons.play_circle_filled, size: 20),
          label: Text(
            isUrdu ? 'ویڈیو ڈیمو دیکھیں (4K)' : 'Watch Video Showcase (4K)',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          onPressed: _openVideoShowcase,
        ),
      ],
    );
  }

  Widget _buildGlassLoginCard(dynamic authState, AppLocalizations l10n, bool isUrdu) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F2B48).withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 30,
            spreadRadius: 4,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Tab selector: Phone OTP vs Email
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedTab = 0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _selectedTab == 0 ? AppColors.accent : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.phone_iphone,
                                    size: 16,
                                    color: _selectedTab == 0 ? Colors.black87 : Colors.white70,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isUrdu ? 'فون نمبر (OTP)' : 'Phone OTP',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: _selectedTab == 0 ? Colors.black87 : Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedTab = 1),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _selectedTab == 1 ? AppColors.accent : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.lock_outline,
                                    size: 16,
                                    color: _selectedTab == 1 ? Colors.black87 : Colors.white70,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isUrdu ? 'ای میل / پاس ورڈ' : 'Email / Pass',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: _selectedTab == 1 ? Colors.black87 : Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                if (_selectedTab == 1) ...[
                  Text(
                    isUrdu ? 'ای میل اور پاس ورڈ سے لاگ ان کریں' : 'Email Sign In',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isUrdu ? 'ڈیمو ٹرانسپورٹر / ڈرائیور اکاؤنٹ کے لیے نیچے کلک کریں' : 'Use your registered corporate or personal email',
                    style: const TextStyle(fontSize: 13, color: Colors.white60),
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _emailController,
                    style: const TextStyle(color: Colors.white),
                    cursorColor: AppColors.accent,
                    cursorWidth: 2.2,
                    showCursor: true,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.08),
                      prefixIcon: const Icon(Icons.email_outlined, color: AppColors.accent),
                      labelText: isUrdu ? 'ای میل ایڈریس' : 'Email Address',
                      labelStyle: const TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white24)),
                    ),
                    validator: (val) => val == null || !val.contains('@') ? 'Valid email required' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _passwordController,
                    style: const TextStyle(color: Colors.white),
                    cursorColor: AppColors.accent,
                    cursorWidth: 2.2,
                    showCursor: true,
                    obscureText: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.08),
                      prefixIcon: const Icon(Icons.lock_outline, color: AppColors.accent),
                      labelText: isUrdu ? 'پاس ورڈ' : 'Password',
                      labelStyle: const TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white24)),
                    ),
                    validator: (val) => val == null || val.length < 6 ? 'Min 6 characters' : null,
                  ),
                  if (authState.errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      authState.errorMessage!,
                      style: const TextStyle(color: AppColors.danger, fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 12),
                  CaptchaVerificationWidget(
                    isUrdu: isUrdu,
                    hasError: _captchaError,
                    onVerified: (verified) {
                      setState(() {
                        _isCaptchaVerified = verified;
                        if (verified) _captchaError = false;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                      ),
                      onPressed: authState.isLoading ? null : _handleEmailLogin,
                      child: authState.isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                            )
                          : Text(
                              isUrdu ? 'لاگ ان کریں' : 'Sign In to Dashboard',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                    ),
                  ),
                ] else if (!authState.isOtpSent) ...[
                  Text(
                    l10n.loginTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.loginSubtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _phoneController,
                    inputFormatters: [PakistaniPhoneInputFormatter()],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                    cursorColor: AppColors.accent,
                    cursorWidth: 2.5,
                    cursorHeight: 24,
                    cursorRadius: const Radius.circular(2),
                    showCursor: true,
                    mouseCursor: SystemMouseCursors.text,
                    keyboardType: TextInputType.phone,
                    onChanged: (val) => setState(() {}),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.10),
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      labelText: isUrdu ? 'پاکستانی موبائل نمبر' : 'Pakistani Mobile Number',
                      hintText: '+92 308 750 2250',
                      labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.38),
                        fontSize: 15,
                        letterSpacing: 1.2,
                      ),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🇵🇰', style: TextStyle(fontSize: 20)),
                            const SizedBox(width: 8),
                            Container(height: 22, width: 1.2, color: Colors.white30),
                          ],
                        ),
                      ),
                      suffixIcon: _phoneController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.white60, size: 18),
                              onPressed: () {
                                _phoneController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white30, width: 1.2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.accent, width: 2.0),
                      ),
                    ),
                    validator: AppValidators.validatePhone,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isUrdu ? 'فارمیٹ: +92 308 750 2250 (خودکار فارمیٹنگ)' : 'Format: +92 308 750 2250 (Auto-formatted)',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 11),
                  ),
                  if (authState.errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.danger.withValues(alpha: 0.8)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: SelectableText(
                              authState.errorMessage!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  CaptchaVerificationWidget(
                    isUrdu: isUrdu,
                    hasError: _captchaError,
                    onVerified: (verified) {
                      setState(() {
                        _isCaptchaVerified = verified;
                        if (verified) _captchaError = false;
                      });
                    },
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                      ),
                      onPressed: (authState.isLoading || _isSubmitting) ? null : _handleSendOtp,
                      child: (authState.isLoading || _isSubmitting)
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                            )
                          : Text(
                              l10n.sendVerificationCode,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                    ),
                  ),
                ] else ...[
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => context.authActions.logout(),
                      ),
                      Text(
                        l10n.verifyOtpTitle,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.codeSentTo(authState.phoneNumber ?? ''),
                    style: const TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _otpController,
                    style: const TextStyle(color: Colors.white, letterSpacing: 4, fontSize: 18),
                    cursorColor: AppColors.accent,
                    cursorWidth: 2.5,
                    showCursor: true,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    onFieldSubmitted: (_) => _handleVerifyOtp(),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.08),
                      prefixIcon: const Icon(Icons.lock_clock_outlined, color: AppColors.accent),
                      labelText: l10n.otpLabel,
                      hintText: l10n.otpHint,
                      labelStyle: const TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white24)),
                    ),
                  ),
                  if (authState.errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.danger.withValues(alpha: 0.8)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: SelectableText(
                              authState.errorMessage!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                      ),
                      onPressed: (authState.isLoading || _isSubmitting) ? null : _handleVerifyOtp,
                      child: (authState.isLoading || _isSubmitting)
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                            )
                          : Text(
                              l10n.verifyAndContinue,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
