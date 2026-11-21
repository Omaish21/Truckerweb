import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
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
    final criticalBridge = _detectedBridges.firstWhere(
      (b) => b.isCritical && b.truckHeightFt > b.clearanceHeightFt,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Intelligence / روٹ انٹیلیجنس'),
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
                        const Text(
                          'HERE Truck Profile',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Active Configuration',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _SpecItem(label: 'Origin', value: _origin),
                        const Icon(Icons.arrow_forward, color: AppColors.accent, size: 20),
                        _SpecItem(label: 'Destination', value: _destination),
                        _SpecItem(label: 'Height', value: '${_truckHeightFt.toStringAsFixed(1)} ft'),
                        _SpecItem(label: 'Gross Weight', value: '${_grossWeightTons.toInt()} Tons'),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // USP Bridge Alert Banner if critical restriction found
            if (!_useMotorwayBypass)
              BridgeAlertBanner(
                alert: criticalBridge,
                onRerouteTap: () {
                  setState(() {
                    _useMotorwayBypass = true;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: AppColors.success,
                      content: Text('Alternative Route Activated: Diverting via M-5 Motorway (Clearance > 18ft)'),
                    ),
                  );
                },
              )
            else
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.success, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Bypass Route Active (M-5 Sukkur-Multan)',
                            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.success),
                          ),
                          Text(
                            'All low bridges bypassed. Minimum clearance: 18.5 ft.',
                            style: TextStyle(fontSize: 12, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _useMotorwayBypass = false),
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 12),

            // Route Summary & Timing Windows Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Corridor Analysis & ETA',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _RouteStat(
                          icon: Icons.straighten,
                          title: 'Distance',
                          value: _useMotorwayBypass ? '1,210 km' : '1,180 km',
                        ),
                        _RouteStat(
                          icon: Icons.timer_outlined,
                          title: 'Est. Drive Time',
                          value: _useMotorwayBypass ? '21 Hours' : '23 Hours',
                        ),
                        _RouteStat(
                          icon: Icons.nightlight_round,
                          title: 'Karachi Curfew',
                          value: '11 PM - 5 AM',
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    const Text(
                      'Destination Timing Advice:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Heavy vehicles cannot enter Karachi Toll Plaza before 11:00 PM. Recommended layover parking at Hyderabad Bypass or Nooriabad.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Bridge Clearance Points
            const Text(
              'Bridge Height Clearance Points on Route',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            ..._detectedBridges.map((bridge) {
              final isUnder = bridge.truckHeightFt > bridge.clearanceHeightFt;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isUnder ? AppColors.danger.withValues(alpha: 0.15) : AppColors.success.withValues(alpha: 0.15),
                    child: Icon(
                      isUnder ? Icons.close : Icons.check,
                      color: isUnder ? AppColors.danger : AppColors.success,
                    ),
                  ),
                  title: Text(
                    bridge.bridgeName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  subtitle: Text(
                    '${bridge.roadSegment} • Clearance: ${bridge.clearanceHeightFt} ft',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Text(
                    isUnder ? 'LOW (-${bridge.differenceFt.toStringAsFixed(1)} ft)' : 'OK (+${(bridge.clearanceHeightFt - bridge.truckHeightFt).toStringAsFixed(1)} ft)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isUnder ? AppColors.danger : AppColors.success,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _SpecItem extends StatelessWidget {
  final String label;
  final String value;

  const _SpecItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}

class _RouteStat extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _RouteStat({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}
