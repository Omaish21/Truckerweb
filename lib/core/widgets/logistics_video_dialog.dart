import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/colors.dart';

class LogisticsVideoDialog extends StatefulWidget {
  const LogisticsVideoDialog({super.key});

  @override
  State<LogisticsVideoDialog> createState() => _LogisticsVideoDialogState();
}

class _LogisticsVideoDialogState extends State<LogisticsVideoDialog> {
  int _currentSlide = 0;
  bool _isPlaying = true;
  Timer? _timer;

  final List<Map<String, String>> _videoScenes = const [
    {
      'titleUr': 'لاہور تا کراچی محفوظ کوریڈور',
      'titleEn': 'Lahore to Karachi CPEC & M-5 Freight Corridor',
      'subUr': 'ہائی وے پولیس سے تصدیق شدہ تیز ترین اور محفوظ ترین راستہ',
      'subEn': 'NHMP Verified, 22-Wheeler Clearance Guaranteed across M-5 / N-5',
      'stat': '1,210 KM',
      'statLabel': 'Live Corridor',
      'icon': 'local_shipping',
    },
    {
      'titleUr': 'نادرا اور ویری سس سے ڈرائیور کی تصدیق',
      'titleEn': 'NADRA Verisys 100% Identity Authentication',
      'subUr': 'ہر ڈرائیور اور ٹرانسپورٹر کے کوائف نادرا ڈیٹابیس سے تصدیق شدہ ہیں',
      'subEn': 'Zero fraud risk with bio-metric CNIC and HTV license validation',
      'stat': '100% Safe',
      'statLabel': 'NADRA Verified',
      'icon': 'verified_user',
    },
    {
      'titleUr': 'کم اونچائی والے پلوں کی خودکار نشاندہی',
      'titleEn': 'Automatic Low-Clearance Bridge Collision Alerts',
      'subUr': 'ٹرک کی اونچائی کے مطابق خودکار ری روٹنگ تاکہ حادثات سے بچا جا سکے',
      'subEn': 'HERE Truck routing protects 15ft+ container trucks from damage',
      'stat': '0 Accidents',
      'statLabel': 'Bridge Clearance',
      'icon': 'alt_route',
    },
    {
      'titleUr': 'براہ راست بولی اور فوری ادائیگیاں',
      'titleEn': 'Real-Time Load Bidding & Instant Escrow Payments',
      'subUr': 'کوئی کمیشن نہیں، ڈائریکٹ واٹس ایپ اور کال رابطہ',
      'subEn': 'Direct shipper-to-driver booking with verified rates in PKR',
      'stat': 'Rs. 50 Cr+',
      'statLabel': 'Safe Transactions',
      'icon': 'payments',
    },
  ];

  @override
  void initState() {
    super.initState();
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _timer = Timer.periodic(const Duration(seconds: 4), (t) {
      if (_isPlaying && mounted) {
        setState(() {
          _currentSlide = (_currentSlide + 1) % _videoScenes.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUrdu = Localizations.localeOf(context).languageCode == 'ur';
    final scene = _videoScenes[_currentSlide];

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 480),
        decoration: BoxDecoration(
          color: const Color(0xFF071426),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.7),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // Video Player Top Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.black45,
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isUrdu ? 'ٹرک لنک پی کے لائیو ویڈیو ڈیمو (۴ کے)' : 'TruckLink PK Cinematic Showcase (4K)',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Video Simulation Screen
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Animated Gradient / Highway Visual
                  AnimatedContainer(
                    duration: const Duration(seconds: 1),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _currentSlide % 2 == 0 ? const Color(0xFF0B2545) : const Color(0xFF133E68),
                          _currentSlide % 2 == 0 ? const Color(0xFF134074) : const Color(0xFF091F36),
                        ],
                      ),
                    ),
                  ),

                  // Center Cinematic Motion Graphics
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.4),
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.accent.withValues(alpha: 0.6), width: 2),
                            ),
                            child: Icon(
                              _getIcon(scene['icon']!),
                              size: 54,
                              color: AppColors.accent,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            isUrdu ? scene['titleUr']! : scene['titleEn']!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isUrdu ? scene['subUr']! : scene['subEn']!,
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.success),
                            ),
                            child: Text(
                              '${scene['statLabel']}: ${scene['stat']}',
                              style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Player Timeline & Controls
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      color: Colors.black54,
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: AppColors.accent),
                            onPressed: () {
                              setState(() => _isPlaying = !_isPlaying);
                            },
                          ),
                          Expanded(
                            child: Row(
                              children: List.generate(_videoScenes.length, (idx) {
                                final isActive = idx == _currentSlide;
                                return Expanded(
                                  child: Container(
                                    height: 4,
                                    margin: const EdgeInsets.symmetric(horizontal: 3),
                                    decoration: BoxDecoration(
                                      color: isActive ? AppColors.accent : Colors.white24,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '0${_currentSlide + 1} / 0${_videoScenes.length}',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon(String name) {
    switch (name) {
      case 'verified_user':
        return Icons.verified_user;
      case 'alt_route':
        return Icons.alt_route;
      case 'payments':
        return Icons.payments;
      default:
        return Icons.local_shipping;
    }
  }
}
