import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/report_categories.dart';
import '../../../../core/constants/vehicle_types.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/language_toggle_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/route_models.dart';
import '../widgets/bridge_alert_banner.dart';

class RoutePlannerScreen extends ConsumerStatefulWidget {
  const RoutePlannerScreen({super.key});

  @override
  ConsumerState<RoutePlannerScreen> createState() => _RoutePlannerScreenState();
}

class _RoutePlannerScreenState extends ConsumerState<RoutePlannerScreen> {
  final String _origin = 'Lahore';
  final String _destination = 'Karachi';
  bool _useMotorwayBypass = false;
  String _selectedVehicleId = '22_wheeler';

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

  // Route Corridor Coordinates (Lahore to Karachi)
  final List<LatLng> _nationalCorridorRoute = const [
    LatLng(31.5204, 74.3587), // Lahore
    LatLng(30.6682, 73.1114), // Sahiwal
    LatLng(30.1575, 71.5249), // Multan
    LatLng(29.3956, 71.6833), // Bahawalpur
    LatLng(28.4212, 70.2989), // Rahim Yar Khan
    LatLng(27.7052, 68.8574), // Sukkur
    LatLng(25.3960, 68.3578), // Hyderabad
    LatLng(24.8607, 67.0011), // Karachi Port Qasim
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isUrdu = Localizations.localeOf(context).languageCode == 'ur';
    final roadReportsAsync = ref.watch(firebaseRoadReportsStreamProvider);
    final reportsList = roadReportsAsync.value ?? [];

    final criticalBridge = _detectedBridges.firstWhere(
      (b) => b.isCritical && b.truckHeightFt > b.clearanceHeightFt,
    );

    // Dynamic cost & fuel calculations
    final distanceKm = _useMotorwayBypass ? 1210.0 : 1180.0;
    final vehicle = VehicleType.findById(_selectedVehicleId) ?? VehicleType.all[2];
    // Fuel efficiency (km/liter) based on vehicle capacity
    final kmPerLiter = (vehicle.typicalCapacityTons > 25) ? 2.6 : (vehicle.typicalCapacityTons > 12 ? 3.5 : 5.0);
    final litersNeeded = distanceKm / kmPerLiter;
    final dieselCostPkr = litersNeeded * 280.0; // ~280 PKR/liter
    final tollCostPkr = _useMotorwayBypass ? 14500.0 : 6200.0;
    final totalTripCostPkr = dieselCostPkr + tollCostPkr;

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
            // Interactive OpenStreetMap (FlutterMap) Card
            Card(
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    color: AppColors.primary,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.map, color: AppColors.accent, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              isUrdu ? 'قومی مال بردار کوریڈور (M-5 / N-5)' : 'National Freight Corridor Map',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isUrdu ? 'اوپن اسٹریٹ میپ' : 'OpenStreetMap Live',
                            style: const TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Map Canvas
                  SizedBox(
                    height: 320,
                    child: FlutterMap(
                      options: const MapOptions(
                        initialCenter: LatLng(28.2, 71.0),
                        initialZoom: 5.8,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'pk.trucklink.app',
                        ),
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: _nationalCorridorRoute,
                              strokeWidth: 4.5,
                              color: _useMotorwayBypass ? AppColors.success : AppColors.primary,
                            ),
                          ],
                        ),
                        MarkerLayer(
                          markers: [
                            // Origin (Lahore)
                            const Marker(
                              point: LatLng(31.5204, 74.3587),
                              width: 36,
                              height: 36,
                              child: Icon(Icons.location_on, color: AppColors.primary, size: 36),
                            ),
                            // Destination (Karachi)
                            const Marker(
                              point: LatLng(24.8607, 67.0011),
                              width: 36,
                              height: 36,
                              child: Icon(Icons.flag, color: AppColors.accent, size: 36),
                            ),
                            // Sahiwal Low Bridge Warning
                            const Marker(
                              point: LatLng(30.6682, 73.1114),
                              width: 32,
                              height: 32,
                              child: Icon(Icons.warning, color: AppColors.danger, size: 30),
                            ),
                            // Live Firestore Road Hazard Reports
                            ...reportsList.map((r) {
                              final cat = RoadReportCategory.findById(r.reportType);
                              return Marker(
                                point: const LatLng(30.8138, 73.4534), // Okara / N-5 report
                                width: 32,
                                height: 32,
                                child: Tooltip(
                                  message: '${cat?.nameEn ?? r.reportType}: ${r.description ?? ''}',
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.report_problem,
                                      color: cat?.color ?? AppColors.danger,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Map Legend
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    color: Colors.grey.shade100,
                    child: Wrap(
                      spacing: 14,
                      children: [
                        _LegendItem(color: AppColors.primary, label: isUrdu ? 'آغاز: لاہور' : 'Start: Lahore'),
                        _LegendItem(color: AppColors.accent, label: isUrdu ? 'منزل: کراچی' : 'End: Karachi'),
                        _LegendItem(color: AppColors.danger, label: isUrdu ? 'کم اونچائی پل' : 'Bridge Clearance'),
                        _LegendItem(color: AppColors.hazardBroken, label: isUrdu ? 'لائیو رپورٹ پن' : 'Live Report'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Cost & Fuel Calculator Card
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
                          isUrdu ? 'ڈیزل اور ٹول ٹیکس کا تخمینہ' : 'Estimated Diesel & Toll Costs',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        DropdownButton<String>(
                          value: _selectedVehicleId,
                          underline: const SizedBox(),
                          items: VehicleType.all.map((v) {
                            return DropdownMenuItem(
                              value: v.id,
                              child: Text(isUrdu ? v.nameUr : v.nameEn, style: const TextStyle(fontSize: 13)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedVehicleId = val);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _CostSummaryBox(
                            title: isUrdu ? 'کل فاصلہ' : 'Total Distance',
                            value: '${distanceKm.toInt()} km',
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _CostSummaryBox(
                            title: isUrdu ? 'ڈیزل خرچ' : 'Diesel Cost',
                            value: AppFormatters.formatPkr(dieselCostPkr),
                            color: AppColors.accentOrange,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _CostSummaryBox(
                            title: isUrdu ? 'کل ٹول و خرچ' : 'Total Est. Cost',
                            value: AppFormatters.formatPkr(totalTripCostPkr),
                            color: AppColors.success,
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

class _CostSummaryBox extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _CostSummaryBox({required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.black87)),
      ],
    );
  }
}
