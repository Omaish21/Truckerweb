import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/vehicle_types.dart';
import '../../../../core/providers/app_scope.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/launcher/app_launcher.dart';
import '../../../../core/services/picker/app_document_picker.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/language_toggle_button.dart';
import '../../../../core/widgets/logistics_video_dialog.dart';
import '../../../../core/widgets/notification_bell_button.dart';
import '../../../../core/widgets/radar_pulse.dart';
import '../../../../core/widgets/rating_stars.dart';
import '../../../../core/widgets/verified_badge.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../loads/domain/load_model.dart';
import '../../../route_intelligence/domain/route_models.dart';
import '../../../route_intelligence/presentation/widgets/bridge_alert_banner.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  bool _isOnline = true;
  bool _isUploadingDoc = false;

  final _mockBridgeAlert = const BridgeClearanceAlert(
    bridgeName: 'Railway Overhead Bridge #12',
    clearanceHeightFt: 14.0,
    truckHeightFt: 15.2,
    roadSegment: 'National Highway N-5 near Sahiwal',
    distanceAheadKm: 3.4,
    isCritical: true,
  );

  Future<void> _pickAndUploadDocument(String docType) async {
    final pickedFile = await AppDocumentPicker.pickImage();
    if (pickedFile == null || !mounted) return;

    final user = context.auth.userProfile;
    final authActions = context.authActions;
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _isUploadingDoc = true);
    try {
      final bytes = pickedFile.bytes;
      final uid = user?.id ?? 'usr-current';
      final fileName = pickedFile.name.replaceAll(' ', '_');

      await FirebaseService.instance.uploadDriverDocument(
        uid: uid,
        docType: docType,
        fileBytes: bytes,
        fileName: fileName,
      );

      if (user != null) {
        final updated = user.copyWith(verificationStatus: 'pending');
        authActions.updateUserProfile(updated);
      }

      if (mounted) {
        setState(() => _isUploadingDoc = false);
        messenger.showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.success,
            content: Text('Document uploaded successfully! Verification pending.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingDoc = false);
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: AppColors.danger,
            content: Text('Upload error: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.auth.state;
    final user = authState.userProfile;
    final l10n = AppLocalizations.of(context)!;
    final isUrdu = Localizations.localeOf(context).languageCode == 'ur';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.driverDashboardTitle),
        actions: [
          if (context.auth.isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings, color: Colors.amber),
              tooltip: l10n.adminVerification,
              onPressed: () => context.go('/admin/verification'),
            ),
          const NotificationBellButton(),
          const Center(
            child: LanguageToggleButton(compact: true),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: l10n.switchToTransporter,
            onPressed: () => context.go('/role-selection'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: l10n.logout,
            onPressed: () {
              context.authActions.logout();
              context.go('/login');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Driver Profile Header Card
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.primary,
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.accent,
                        child: Text(
                          user?.fullName.isNotEmpty == true ? user!.fullName[0] : 'D',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.fullName ?? 'Muhammad Asif',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const VerifiedBadge(isVerified: true),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white12,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    l10n.htvPlusLicense,
                                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      RatingStars(rating: user?.rating ?? 4.8, totalRatings: user?.totalRatings ?? 34),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Availability Switch with Animated Radar GPS
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            RadarPulse(
                              size: 20,
                              color: AppColors.success,
                              isLive: _isOnline,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _isOnline ? l10n.onlineStatus : l10n.offlineStatus,
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        Switch(
                          value: _isOnline,
                          activeThumbColor: AppColors.success,
                          onChanged: (val) {
                            setState(() => _isOnline = val);
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Motorway Police 130 & Video Showcase Quick Banner
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          mouseCursor: SystemMouseCursors.click,
                          onTap: () => AppLauncher.makeCall('130'),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppColors.danger,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.emergency, color: Colors.white, size: 14),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isUrdu ? 'ہائی وے ہیلپ لائن: 130' : 'NHMP Helpline: 130',
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.accent,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          ),
                          icon: const Icon(Icons.play_circle_filled, size: 16),
                          label: Text(
                            isUrdu ? 'ویڈیو گائیڈ' : 'Platform Video',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => const LogisticsVideoDialog(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Document Verification Card (Firebase Storage)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.shield_outlined, color: AppColors.accent, size: 20),
                                const SizedBox(width: 6),
                                Text(
                                  isUrdu ? 'نادرا اور لائسنس تصدیق' : 'Driver Document Verification',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                            VerifiedBadge(status: user?.verificationStatus ?? 'verified'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isUrdu
                              ? 'ہائی ویلیو لوڈز حاصل کرنے کے لیے شناختی کارڈ اور ڈرائیونگ لائسنس اپ لوڈ کریں۔'
                              : 'Upload CNIC, HTV/LTV license and vehicle book to get verified.',
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                        const SizedBox(height: 10),
                        if (_isUploadingDoc)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2),
                            ),
                          )
                        else
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(color: Colors.white38),
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                  ),
                                  icon: const Icon(Icons.badge_outlined, size: 14),
                                  label: Text(isUrdu ? 'شناختی کارڈ' : 'CNIC', style: const TextStyle(fontSize: 11)),
                                  onPressed: () => _pickAndUploadDocument('cnic'),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(color: Colors.white38),
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                  ),
                                  icon: const Icon(Icons.drive_eta, size: 14),
                                  label: Text(isUrdu ? 'لائسنس' : 'License', style: const TextStyle(fontSize: 11)),
                                  onPressed: () => _pickAndUploadDocument('license'),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(color: Colors.white38),
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                  ),
                                  icon: const Icon(Icons.description_outlined, size: 14),
                                  label: Text(isUrdu ? 'گاڑی بک' : 'Registration', style: const TextStyle(fontSize: 11)),
                                  onPressed: () => _pickAndUploadDocument('registration'),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // USP 1: Live Road Alert or Bridge Alert Banner from Firestore
            StreamBuilder<List<RoadReport>>(
              stream: FirebaseService.roadReportsStream,
              builder: (context, snapshot) {
                final reports = snapshot.data ?? [];
                if (reports.isNotEmpty) {
                  final activeReport = reports.first;
                  final alert = BridgeClearanceAlert(
                    bridgeName: activeReport.description ?? 'Highway Safety Alert',
                    clearanceHeightFt: 14.0,
                    truckHeightFt: 15.2,
                    roadSegment: 'Active Corridor Alert',
                    distanceAheadKm: 5.2,
                    isCritical: activeReport.reportType == 'broken' || activeReport.reportType == 'accident',
                  );
                  return BridgeAlertBanner(
                    alert: alert,
                    onRerouteTap: () => context.push('/route-planner'),
                  );
                }
                return BridgeAlertBanner(
                  alert: _mockBridgeAlert,
                  onRerouteTap: () => context.push('/route-planner'),
                );
              },
            ),

            // Quick Nav Grid
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.alt_route,
                      title: l10n.routeIntelligence,
                      subtitle: l10n.routeIntelligenceSubtitle,
                      color: AppColors.primaryLight,
                      onTap: () => context.push('/route-planner'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.access_time_filled,
                      title: l10n.cityCurfewTimings,
                      subtitle: l10n.cityCurfewSubtitle,
                      color: AppColors.accentOrange,
                      onTap: () => context.push('/city-timing'),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.report_problem,
                      title: l10n.reportRoadHazard,
                      subtitle: l10n.reportHazardSubtitle,
                      color: AppColors.danger,
                      onTap: () => context.push('/report-condition'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.local_shipping,
                      title: l10n.allAvailableLoads,
                      subtitle: l10n.allLoadsSubtitle,
                      color: AppColors.success,
                      onTap: () => context.push('/loads-feed'),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Top Matched Loads for Driver
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.matchedLoadsNearYou,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/loads-feed'),
                    child: Text(l10n.viewAll),
                  ),
                ],
              ),
            ),

            StreamBuilder<List<LoadModel>>(
              stream: FirebaseService.loadsStream,
              builder: (context, snapshot) {
                final loads = snapshot.data ?? FirebaseService.defaultSampleLoads;
                if (loads.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Center(
                      child: Text(
                        isUrdu ? 'کوئی لوڈ دستیاب نہیں' : 'No matched loads currently available',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }
                return Column(
                  children: loads.take(3).map((load) {
                    final vType = VehicleType.findById(load.vehicleTypeRequired);
                    final vName = isUrdu
                        ? (vType?.nameUr ?? load.vehicleTypeRequired)
                        : (vType?.nameEn ?? load.vehicleTypeRequired);
                    return _MatchedLoadItem(
                      origin: load.originCity,
                      destination: load.destinationCity,
                      vehicleType: vName,
                      weight: l10n.tonsUnit(load.weightTons.toStringAsFixed(0)),
                      rate: AppFormatters.formatPkr(load.offeredRatePkr),
                      inspectLabel: l10n.inspectRoute,
                      onTap: () => context.push('/route-planner'),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      mouseCursor: SystemMouseCursors.click,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchedLoadItem extends StatelessWidget {
  final String origin;
  final String destination;
  final String vehicleType;
  final String weight;
  final String rate;
  final String inspectLabel;
  final VoidCallback onTap;

  const _MatchedLoadItem({
    required this.origin,
    required this.destination,
    required this.vehicleType,
    required this.weight,
    required this.rate,
    required this.inspectLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: const CircleAvatar(
          backgroundColor: AppColors.primary,
          child: Icon(Icons.local_shipping, color: AppColors.accent, size: 20),
        ),
        title: Text(
          '$origin ➔ $destination',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            '$vehicleType • $weight',
            style: const TextStyle(fontSize: 12),
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              rate,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              inspectLabel,
              style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
