import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/language_toggle_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/route_models.dart';
import '../widgets/bridge_alert_banner.dart';

class RoutePlannerScreen extends StatefulWidget {
  const RoutePlannerScreen({super.key});

  @override
  State<RoutePlannerScreen> createState() => _RoutePlannerScreenState();
}

class _RoutePlannerScreenState extends State<RoutePlannerScreen> {
  final String _origin = 'Lahore';
  final String _destination = 'Karachi';
  final double _truckHeightFt = 15.2;
  final double _grossWeightTons = 35.0;
  bool _useMotorwayBypass = false;

  final List<BridgeClearanceAlert> _detectedBridges = const [
    BridgeClearanceAlert(
      bridgeName: 'Railway Overhead Bridge #12',
      clearanceHeightFt: 14.0,
      truckHeightFt: 15.2,
      roadSegment: 'National Highway N-5 near Sahiwal',
      distanceAheadKm: 185.0,
      isCritical: true,
    ),
    BridgeClearanceAlert(
      bridgeName: 'Rohri Canal Aqueduct Clearance',
      clearanceHeightFt: 16.5,
      truckHeightFt: 15.2,
      roadSegment: 'Sindh Highway',
      distanceAheadKm: 780.0,
      isCritical: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final criticalBridge = _detectedBridges.firstWhere(
      (b) => b.isCritical && b.truckHeightFt > b.clearanceHeightFt,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.routePlannerTitle),
        actions: const [
          Center(child: LanguageToggleButton(compact: true)),
          SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Truck Profile Parameters Header
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.hereTruckProfile,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            l10n.activeConfiguration,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _ParameterChip(
                            icon: Icons.height,
                            label: l10n.truckHeight(_truckHeightFt.toString()),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ParameterChip(
                            icon: Icons.scale,
                            label: l10n.tonsUnit(_grossWeightTons.toInt().toString()),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Critical Clearance Warning
            BridgeAlertBanner(
              alert: criticalBridge,
              onRerouteTap: () {
                setState(() => _useMotorwayBypass = true);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.primary,
                    content: Text(l10n.recalculatingOptimalRoute),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // Routing Controls & Settings
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text(l10n.avoidLowBridges, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: Text(l10n.avoidLowBridgesDesc, style: const TextStyle(fontSize: 12)),
                    value: true,
                    activeThumbColor: AppColors.primary,
                    onChanged: (val) {},
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: Text(l10n.useMotorwayBypass, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: Text(l10n.useMotorwayBypassDesc, style: const TextStyle(fontSize: 12)),
                    value: _useMotorwayBypass,
                    activeThumbColor: AppColors.primary,
                    onChanged: (val) {
                      setState(() => _useMotorwayBypass = val);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Route Summary & Milestones
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$_origin ➔ $_destination',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _useMotorwayBypass ? AppColors.success.withValues(alpha: 0.12) : AppColors.danger.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _useMotorwayBypass ? 'M-5 / M-3 Clearance Verified' : 'N-5 Hazard Detected',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _useMotorwayBypass ? AppColors.success : AppColors.danger,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _useMotorwayBypass
                          ? '1,210 km via M-3 / M-5 Motorway. All bridge clearances exceed 16.5 ft. Safe for 15.2 ft container truck.'
                          : '1,180 km via N-5 National Highway. Obstruction at Sahiwal Railway Bridge (14.0 ft).',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                    ),
                    const Divider(height: 24),
                    Text(
                      l10n.detectedClearanceAlerts,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    ..._detectedBridges.map((b) {
                      final hasCollision = b.truckHeightFt > b.clearanceHeightFt;
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          hasCollision ? Icons.error_outline : Icons.check_circle_outline,
                          color: hasCollision ? AppColors.danger : AppColors.success,
                        ),
                        title: Text(b.bridgeName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        subtitle: Text('${b.roadSegment} • ${l10n.distanceAhead(b.distanceAheadKm.toInt().toString())}'),
                        trailing: Text(
                          l10n.bridgeClearance(b.clearanceHeightFt.toString()),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: hasCollision ? AppColors.danger : Colors.black87,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Starting GPS Turn-by-Turn Navigation with Bridge Proximity Monitor...'),
                  ),
                );
              },
              icon: const Icon(Icons.navigation),
              label: Text(l10n.startGpsNavigation, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParameterChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ParameterChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
