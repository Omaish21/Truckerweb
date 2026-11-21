import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/verified_badge.dart';
import '../../../../core/widgets/rating_stars.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../route_intelligence/domain/route_models.dart';
import '../../../route_intelligence/presentation/widgets/bridge_alert_banner.dart';

class DriverHomeScreen extends ConsumerStatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  ConsumerState<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends ConsumerState<DriverHomeScreen> {
  bool _isOnline = true;
  final bool _showSimulatedBridgeAlert = true;

  final _mockBridgeAlert = const BridgeClearanceAlert(
    bridgeName: 'Railway Overhead Bridge #12',
    clearanceHeightFt: 14.0,
    truckHeightFt: 15.2,
    roadSegment: 'National Highway N-5 near Sahiwal',
    distanceAheadKm: 3.4,
    isCritical: true,
  );

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.userProfile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Dashboard / ڈرائیور پینل'),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: 'Switch to Transporter Mode',
            onPressed: () => context.go('/role-selection'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              ref.read(authProvider.notifier).logout();
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
                                  child: const Text(
                                    'HTV+ License',
                                    style: TextStyle(color: Colors.white70, fontSize: 11),
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

                  // Availability Switch
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
                            Icon(
                              _isOnline ? Icons.circle : Icons.circle_outlined,
                              size: 14,
                              color: _isOnline ? AppColors.success : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isOnline ? 'Online: Receiving Load Requests' : 'Offline: Hidden from search',
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
                ],
              ),
            ),

            // USP 1: Live Bridge Alert Banner
            if (_showSimulatedBridgeAlert) ...[
              BridgeAlertBanner(
                alert: _mockBridgeAlert,
                onRerouteTap: () {
                  context.push('/route-planner');
                },
              ),
            ],

            // Quick Nav Grid
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.alt_route,
                      title: 'Route Intelligence',
                      subtitle: 'راستے کی تفصیل و الرٹس',
                      color: AppColors.primaryLight,
                      onTap: () => context.push('/route-planner'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.access_time_filled,
                      title: 'City Curfew Timings',
                      subtitle: 'شہر میں داخلے کا وقت',
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
                      title: 'Report Road Hazard',
                      subtitle: 'سڑک کی خرابی درج کریں',
                      color: AppColors.danger,
                      onTap: () => context.push('/report-condition'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.local_shipping,
                      title: 'All Available Loads',
                      subtitle: 'دستیاب لوڈز دیکھیں',
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
                  const Text(
                    'Matched Loads Near You',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/loads-feed'),
                    child: const Text('View All / سب دیکھیں'),
                  ),
                ],
              ),
            ),

            _MatchedLoadItem(
              origin: 'Lahore (Badami Bagh)',
              destination: 'Karachi (Port Qasim)',
              vehicleType: '22-Wheeler (Trolley)',
              weight: '35 Tons',
              rate: AppFormatters.formatPkr(245000),
              status: 'Open',
              onTap: () => context.push('/route-planner'),
            ),

            _MatchedLoadItem(
              origin: 'Faisalabad (Textile City)',
              destination: 'Rawalpindi (I-9)',
              vehicleType: '10-Wheeler',
              weight: '16 Tons',
              rate: AppFormatters.formatPkr(85000),
              status: 'Open',
              onTap: () => context.push('/route-planner'),
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
              textDirection: TextDirection.rtl,
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
  final String status;
  final VoidCallback onTap;

  const _MatchedLoadItem({
    required this.origin,
    required this.destination,
    required this.vehicleType,
    required this.weight,
    required this.rate,
    required this.status,
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
            const Text(
              'Inspect Route',
              style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
