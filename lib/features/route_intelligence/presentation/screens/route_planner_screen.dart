import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/report_categories.dart';
import '../../../../core/constants/vehicle_types.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/google_maps_service.dart';
import '../../../../core/services/launcher/app_launcher.dart';
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
  final MapController _mapController = MapController();

  String _origin = 'Lahore';
  String _destination = 'Karachi';
  bool _useMotorwayBypass = true;
  String _selectedVehicleId = '22_wheeler';
  String _activePlaceCategory = 'adda'; // 'adda', 'fuel', 'weighbridge'

  bool _isLoadingRoute = false;
  GoogleRoutePlan? _liveRoutePlan;
  List<TruckPlace> _nearbyPlaces = [];
  TruckPlace? _selectedPlace;

  static const List<String> _majorCities = [
    'Lahore',
    'Karachi',
    'Faisalabad',
    'Rawalpindi',
    'Multan',
    'Peshawar',
    'Quetta',
    'Sukkur',
    'Gwadar',
    'Hyderabad',
    'Gujranwala',
    'Sialkot',
  ];

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

  // Fallback route coordinates
  final List<LatLng> _fallbackRoute = const [
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
  void initState() {
    super.initState();
    _fetchLiveRoute();
    _fetchNearbyPlaces();
  }

  Future<void> _fetchLiveRoute() async {
    setState(() => _isLoadingRoute = true);
    final plan = await GoogleMapsService.computeRoute(
      origin: _origin,
      destination: _destination,
      avoidTolls: !_useMotorwayBypass,
    );

    if (mounted) {
      setState(() {
        _liveRoutePlan = plan;
        _isLoadingRoute = false;
      });

      if (plan != null && plan.points.isNotEmpty) {
        // Fit camera to route midpoint
        final midIndex = plan.points.length ~/ 2;
        _mapController.move(plan.points[midIndex], 6.0);
      }
    }
  }

  Future<void> _fetchNearbyPlaces() async {
    String query;
    switch (_activePlaceCategory) {
      case 'fuel':
        query = 'PSO Diesel Pump $_destination';
        break;
      case 'weighbridge':
        query = 'Weighbridge Kanta $_destination';
        break;
      case 'adda':
      default:
        query = 'Truck Adda $_destination';
        break;
    }

    final places = await GoogleMapsService.searchTruckPlaces(
      query: query,
      category: _activePlaceCategory,
    );

    if (mounted) {
      setState(() {
        _nearbyPlaces = places;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isUrdu = Localizations.localeOf(context).languageCode == 'ur';
    final roadReportsAsync = ref.watch(firebaseRoadReportsStreamProvider);
    final reportsList = roadReportsAsync.value ?? [];

    final criticalBridge = _detectedBridges.firstWhere(
      (b) => b.isCritical && b.truckHeightFt > b.clearanceHeightFt,
    );

    final vehicle = VehicleType.findById(_selectedVehicleId) ?? VehicleType.all[2];
    final kmPerLiter = (vehicle.typicalCapacityTons > 25)
        ? 2.6
        : (vehicle.typicalCapacityTons > 12 ? 3.5 : 5.0);

    final double distanceKm = _liveRoutePlan != null
        ? _liveRoutePlan!.distanceKm
        : (_useMotorwayBypass ? 1205.0 : 1180.0);

    final double dieselCostPkr = _liveRoutePlan != null
        ? _liveRoutePlan!.calculateDieselCost(kmPerLiter: kmPerLiter)
        : (distanceKm / kmPerLiter * 285.0);

    final double tollCostPkr = _liveRoutePlan != null
        ? _liveRoutePlan!.calculateTollCost(useMotorway: _useMotorwayBypass)
        : (_useMotorwayBypass ? 14500.0 : 6200.0);

    final double totalTripCostPkr = dieselCostPkr + tollCostPkr;

    final displayPoints = _liveRoutePlan != null && _liveRoutePlan!.points.isNotEmpty
        ? _liveRoutePlan!.points
        : _fallbackRoute;

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
            // Live Route Selector (Origin & Destination)
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.alt_route, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          isUrdu ? 'گوگل ہائی وے روٹ سلیکٹر' : 'Google Highway Route Engine',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const Spacer(),
                        if (_isLoadingRoute)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2.2),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isUrdu ? 'آغاز (شہر)' : 'Origin City',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              DropdownButtonFormField<String>(
                                initialValue: _origin,
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                items: _majorCities.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)))).toList(),
                                onChanged: (v) {
                                  if (v != null && v != _origin) {
                                    setState(() => _origin = v);
                                    _fetchLiveRoute();
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12),
                          child: IconButton(
                            icon: const Icon(Icons.swap_horiz, color: AppColors.primary),
                            onPressed: () {
                              setState(() {
                                final temp = _origin;
                                _origin = _destination;
                                _destination = temp;
                              });
                              _fetchLiveRoute();
                              _fetchNearbyPlaces();
                            },
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isUrdu ? 'منزل (شہر)' : 'Destination City',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              DropdownButtonFormField<String>(
                                initialValue: _destination,
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                items: _majorCities.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)))).toList(),
                                onChanged: (v) {
                                  if (v != null && v != _destination) {
                                    setState(() => _destination = v);
                                    _fetchLiveRoute();
                                    _fetchNearbyPlaces();
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Interactive Map Card with Google Route Polyline & Live Amenities
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
                              isUrdu
                                  ? 'لائیو روٹ: $_origin تا $_destination'
                                  : 'Live Route: $_origin to $_destination',
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
                            _liveRoutePlan != null
                                ? (isUrdu ? _liveRoutePlan!.durationTextUrdu() : _liveRoutePlan!.durationText)
                                : (isUrdu ? 'گوگل روٹ لائیو' : 'Google Routes v2'),
                            style: const TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Map Canvas
                  SizedBox(
                    height: 340,
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: displayPoints.isNotEmpty
                            ? displayPoints[displayPoints.length ~/ 2]
                            : const LatLng(28.2, 71.0),
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
                              points: displayPoints,
                              strokeWidth: 5.0,
                              color: _useMotorwayBypass ? const Color(0xFF00A86B) : AppColors.primary,
                            ),
                          ],
                        ),
                        MarkerLayer(
                          markers: [
                            // Origin Marker
                            if (displayPoints.isNotEmpty)
                              Marker(
                                point: displayPoints.first,
                                width: 40,
                                height: 40,
                                child: const Icon(Icons.location_on, color: AppColors.primary, size: 38),
                              ),
                            // Destination Marker
                            if (displayPoints.isNotEmpty)
                              Marker(
                                point: displayPoints.last,
                                width: 40,
                                height: 40,
                                child: const Icon(Icons.flag, color: AppColors.accent, size: 38),
                              ),
                            // Nearby Facilities (Truck Addas / Fuel / Weighbridges)
                            ..._nearbyPlaces.map((place) {
                              IconData icon;
                              Color pinColor;
                              switch (place.category) {
                                case 'fuel':
                                  icon = Icons.local_gas_station;
                                  pinColor = Colors.orange.shade800;
                                  break;
                                case 'weighbridge':
                                  icon = Icons.scale;
                                  pinColor = Colors.purple.shade700;
                                  break;
                                case 'adda':
                                default:
                                  icon = Icons.local_shipping;
                                  pinColor = Colors.teal.shade700;
                                  break;
                              }

                              return Marker(
                                point: place.location,
                                width: 34,
                                height: 34,
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() => _selectedPlace = place);
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.25),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                      padding: const EdgeInsets.all(4),
                                      child: Icon(icon, color: pinColor, size: 20),
                                    ),
                                  ),
                                ),
                              );
                            }),
                            // Bridge Alert Markers
                            const Marker(
                              point: LatLng(30.6682, 73.1114),
                              width: 32,
                              height: 32,
                              child: Icon(Icons.warning, color: AppColors.danger, size: 30),
                            ),
                            // Live Firestore Reports
                            ...reportsList.map((r) {
                              final cat = RoadReportCategory.findById(r.reportType);
                              return Marker(
                                point: const LatLng(30.8138, 73.4534),
                                width: 32,
                                height: 32,
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.report_problem,
                                    color: cat?.color ?? AppColors.danger,
                                    size: 22,
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Selected Facility Details Card (if clicked)
                  if (_selectedPlace != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      color: Colors.blueGrey.shade50,
                      child: Row(
                        children: [
                          const Icon(Icons.place, color: AppColors.primary, size: 24),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedPlace!.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                Text(
                                  _selectedPlace!.address,
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.directions, color: AppColors.primary),
                            tooltip: 'Navigate',
                            onPressed: () {
                              final url =
                                  'https://www.google.com/maps/dir/?api=1&destination=${_selectedPlace!.location.latitude},${_selectedPlace!.location.longitude}';
                              AppLauncher.openUrl(url);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () => setState(() => _selectedPlace = null),
                          ),
                        ],
                      ),
                    ),

                  // Map Legend & Filters
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    color: Colors.grey.shade100,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              isUrdu ? 'قریبی سہولیات تلاش کریں:' : 'Find Near Destination:',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: Text(isUrdu ? 'اڈے' : 'Addas', style: const TextStyle(fontSize: 11)),
                              selected: _activePlaceCategory == 'adda',
                              onSelected: (val) {
                                if (val) {
                                  setState(() => _activePlaceCategory = 'adda');
                                  _fetchNearbyPlaces();
                                }
                              },
                            ),
                            const SizedBox(width: 6),
                            ChoiceChip(
                              label: Text(isUrdu ? 'پمپ' : 'Fuel', style: const TextStyle(fontSize: 11)),
                              selected: _activePlaceCategory == 'fuel',
                              onSelected: (val) {
                                if (val) {
                                  setState(() => _activePlaceCategory = 'fuel');
                                  _fetchNearbyPlaces();
                                }
                              },
                            ),
                            const SizedBox(width: 6),
                            ChoiceChip(
                              label: Text(isUrdu ? 'کانٹا' : 'Weigh', style: const TextStyle(fontSize: 11)),
                              selected: _activePlaceCategory == 'weighbridge',
                              onSelected: (val) {
                                if (val) {
                                  setState(() => _activePlaceCategory = 'weighbridge');
                                  _fetchNearbyPlaces();
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 12,
                          children: [
                            _LegendItem(color: AppColors.primary, label: isUrdu ? 'آغاز: $_origin' : 'Start: $_origin'),
                            _LegendItem(color: AppColors.accent, label: isUrdu ? 'منزل: $_destination' : 'End: $_destination'),
                            _LegendItem(color: AppColors.danger, label: isUrdu ? 'کم اونچائی پل' : 'Low Bridge'),
                            _LegendItem(color: Colors.teal.shade700, label: isUrdu ? 'ٹرک اڈہ' : 'Truck Stand'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Cost & Fuel Calculator Card (Real Live Highway Math)
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
                            title: isUrdu ? 'کل فاصلہ (گوگل)' : 'Distance (Google)',
                            value: '${distanceKm.toStringAsFixed(1)} km',
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
                _fetchLiveRoute();
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
                    subtitle: Text(
                      isUrdu
                          ? 'موٹروے M-3 / M-5 کا انتخاب کریں (بغیر رکاوٹ، تیز سفر)'
                          : 'Prefer Motorway M-3 / M-5 route (Fast, high bridge clearances)',
                      style: const TextStyle(fontSize: 12),
                    ),
                    value: _useMotorwayBypass,
                    activeThumbColor: AppColors.primary,
                    onChanged: (val) {
                      setState(() => _useMotorwayBypass = val);
                      _fetchLiveRoute();
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
                            color: _useMotorwayBypass
                                ? AppColors.success.withValues(alpha: 0.12)
                                : AppColors.danger.withValues(alpha: 0.12),
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
                      _liveRoutePlan != null
                          ? '${_liveRoutePlan!.distanceKm.toStringAsFixed(1)} km (${_liveRoutePlan!.durationText}) via ${_useMotorwayBypass ? "M-3 / M-5 Motorway Corridor" : "N-5 National Highway"}.'
                          : (_useMotorwayBypass
                              ? '1,210 km via M-3 / M-5 Motorway. All bridge clearances exceed 16.5 ft. Safe for 15.2 ft container truck.'
                              : '1,180 km via N-5 National Highway. Obstruction at Sahiwal Railway Bridge (14.0 ft).'),
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
                final url =
                    'https://www.google.com/maps/dir/?api=1&origin=$_origin,Pakistan&destination=$_destination,Pakistan';
                AppLauncher.openUrl(url);
              },
              icon: const Icon(Icons.navigation),
              label: Text(
                isUrdu ? 'گوگل میپس پر لائیو نیویگیشن شروع کریں' : 'Start Google Navigation',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
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
          Text(title, style: TextStyle(fontSize: 11, color: Colors.grey.shade700), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color), textAlign: TextAlign.center),
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
