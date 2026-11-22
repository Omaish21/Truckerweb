import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import '../../../../core/constants/report_categories.dart';
import '../../../../core/constants/vehicle_types.dart';
import '../../../../core/services/audio_alert_service.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/geocoding_service.dart';
import '../../../../core/services/google_maps_service.dart';
import '../../../../core/services/launcher/app_launcher.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/language_toggle_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/route_models.dart';
import '../widgets/bridge_alert_banner.dart';

class RoutePlannerScreen extends StatefulWidget {
  final String? initialOrigin;
  final String? initialDestination;
  final String? initialVehicle;
  final bool? initialMotorway;

  const RoutePlannerScreen({
    super.key,
    this.initialOrigin,
    this.initialDestination,
    this.initialVehicle,
    this.initialMotorway,
  });

  @override
  State<RoutePlannerScreen> createState() => _RoutePlannerScreenState();
}

class _RoutePlannerScreenState extends State<RoutePlannerScreen>
    with SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;
  late TabController _tabController;
  StreamSubscription<List<RoadReport>>? _reportsSub;
  List<RoadReport> _roadReports = [];

  String _origin = 'Lahore';
  String _destination = 'Karachi';
  bool _useMotorwayBypass = true;
  String _selectedVehicleId = '22_wheeler';
  String _activePlaceCategory = 'adda';

  bool _isSatelliteView = false;
  bool _isTrafficEnabled = true;
  bool _isLoadingRoute = false;

  GoogleRoutePlan? _liveRoutePlan;
  List<TruckPlace> _nearbyPlaces = [];
  TruckPlace? _selectedPlace;
  List<BridgeClearanceAlert> _corridorBridgeAlerts = [];

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

  static const Map<String, LatLng> _cityCoordinates = {
    'Lahore': LatLng(31.5204, 74.3587),
    'Karachi': LatLng(24.8607, 67.0011),
    'Faisalabad': LatLng(31.4504, 73.1350),
    'Rawalpindi': LatLng(33.5651, 73.0169),
    'Multan': LatLng(30.1575, 71.5249),
    'Peshawar': LatLng(34.0151, 71.5249),
    'Quetta': LatLng(30.1798, 66.9750),
    'Sukkur': LatLng(27.7052, 68.8574),
    'Gwadar': LatLng(25.1216, 62.3254),
    'Hyderabad': LatLng(25.3960, 68.3578),
    'Gujranwala': LatLng(32.1877, 74.1945),
    'Sialkot': LatLng(32.4945, 74.5229),
  };

  @override
  void initState() {
    super.initState();
    if (widget.initialOrigin != null && widget.initialOrigin!.isNotEmpty) {
      _origin = widget.initialOrigin!;
    }
    if (widget.initialDestination != null && widget.initialDestination!.isNotEmpty) {
      _destination = widget.initialDestination!;
    }
    if (widget.initialVehicle != null && widget.initialVehicle!.isNotEmpty) {
      _selectedVehicleId = widget.initialVehicle!;
    }
    if (widget.initialMotorway != null) {
      _useMotorwayBypass = widget.initialMotorway!;
    }
    _tabController = TabController(length: 3, vsync: this);
    _reportsSub = FirebaseService.roadReportsStream.listen((reports) {
      if (mounted) setState(() => _roadReports = reports);
    });
    _fetchLiveRoute();
    _fetchNearbyPlaces();
  }

  void _syncUrl() {
    if (!mounted) return;
    final uri = Uri(
      path: '/route-planner',
      queryParameters: {
        'origin': _origin,
        'destination': _destination,
        'vehicle': _selectedVehicleId,
        'motorway': _useMotorwayBypass.toString(),
      },
    );
    GoRouter.of(context).replace(uri.toString());
  }

  @override
  void dispose() {
    _reportsSub?.cancel();
    _tabController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  VehicleType get _selectedVehicle =>
      VehicleType.findById(_selectedVehicleId) ?? VehicleType.all[2];

  Future<void> _fetchLiveRoute() async {
    setState(() => _isLoadingRoute = true);

    // Resolve robust geocoded coordinates for corridor validation
    final originGeo = await GeocodingService.instance.forwardGeocode(_origin);
    final destGeo = await GeocodingService.instance.forwardGeocode(_destination);
    if (kDebugMode) {
      debugPrint('[Geocoding] Origin: ${originGeo?.formattedAddress} -> Dest: ${destGeo?.formattedAddress}');
    }

    final plan = await GoogleMapsService.computeRoute(
      origin: originGeo?.formattedAddress ?? _origin,
      destination: destGeo?.formattedAddress ?? _destination,
      avoidTolls: !_useMotorwayBypass,
    );

    if (mounted) {
      final points = plan?.points ?? [];
      final bridgeAlerts = PakistanBridgesDataset.findCorridorBridges(
        routePoints: points,
        truckHeightFt: _selectedVehicle.standardHeightFt,
        isMotorway: _useMotorwayBypass,
      );

      setState(() {
        _liveRoutePlan = plan;
        _corridorBridgeAlerts = bridgeAlerts;
        _isLoadingRoute = false;
      });

      _fitRouteInView();
    }
  }

  void _fitRouteInView() {
    final points = _liveRoutePlan?.points;
    if (points == null || points.isEmpty || _mapController == null) return;

    try {
      double minLat = points.first.latitude;
      double maxLat = points.first.latitude;
      double minLng = points.first.longitude;
      double maxLng = points.first.longitude;

      for (final p in points) {
        if (p.latitude < minLat) minLat = p.latitude;
        if (p.latitude > maxLat) maxLat = p.latitude;
        if (p.longitude < minLng) minLng = p.longitude;
        if (p.longitude > maxLng) maxLng = p.longitude;
      }

      final bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );

      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 48),
      );
    } catch (_) {
      final midIndex = points.length ~/ 2;
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(points[midIndex], 6.0),
      );
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

  void _speakSafetySummary(bool isUrdu) {
    final hasCritical = _corridorBridgeAlerts.any((b) => b.isCritical);
    String message;
    if (hasCritical) {
      final critical = _corridorBridgeAlerts.firstWhere((b) => b.isCritical);
      message = isUrdu
          ? 'توجہ فرمائیں! آپ کا ٹرک ${_selectedVehicle.nameUr} اونچائی ${_selectedVehicle.standardHeightFt} فٹ ہے۔ راستے میں ${critical.bridgeName} کی اونچائی صرف ${critical.clearanceHeightFt} فٹ ہے۔ حادثے سے بچنے کے لیے موٹروے بائی پاس استعمال کریں۔'
          : 'Warning! Critical bridge hazard detected on route: ${critical.bridgeName}. Clearance is ${critical.clearanceHeightFt} feet, while your truck is ${_selectedVehicle.standardHeightFt} feet. Please use Motorway bypass.';
    } else {
      message = isUrdu
          ? 'روٹ محفوظ ہے۔ تمام پلوں اور انڈر پاسز کی اونچائی آپ کی گاڑی کے لیے موزوں ہے۔ محفوظ سفر کریں۔'
          : 'Route verified safe. All overhead clearances exceed your vehicle height of ${_selectedVehicle.standardHeightFt} feet.';
    }

    AudioAlertService().speakWarning(
      text: message,
      languageCode: isUrdu ? 'ur' : 'en',
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isUrdu = Localizations.localeOf(context).languageCode == 'ur';
    final reportsList = _roadReports;

    final kmPerLiter = (_selectedVehicle.typicalCapacityTons > 25)
        ? 2.6
        : (_selectedVehicle.typicalCapacityTons > 12 ? 3.5 : 5.0);

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

    final hasCriticalClearance = _corridorBridgeAlerts.any((b) => b.isCritical);
    final criticalBridge = _corridorBridgeAlerts.cast<BridgeClearanceAlert?>().firstWhere(
          (b) => b != null && b.isCritical,
          orElse: () => null,
        );

    // Build Google Map Polylines
    final polylines = <Polyline>{};
    if (_liveRoutePlan != null && _liveRoutePlan!.points.isNotEmpty) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('active_google_route'),
          points: _liveRoutePlan!.points,
          width: 5,
          color: hasCriticalClearance
              ? const Color(0xFFE53935)
              : (_useMotorwayBypass ? const Color(0xFF00A86B) : const Color(0xFF0A2540)),
        ),
      );
    }

    // Build Google Map Markers
    final markers = <Marker>{};

    // Origin Marker
    final originPos = _cityCoordinates[_origin] ??
        (_liveRoutePlan?.points.isNotEmpty == true
            ? _liveRoutePlan!.points.first
            : const LatLng(31.5204, 74.3587));
    markers.add(
      Marker(
        markerId: const MarkerId('origin_marker'),
        position: originPos,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: InfoWindow(
          title: isUrdu ? 'آغاز: $_origin' : 'Origin: $_origin',
          snippet: isUrdu ? 'لوڈنگ مقام' : 'Trip Start Location',
        ),
      ),
    );

    // Destination Marker
    final destPos = _cityCoordinates[_destination] ??
        (_liveRoutePlan?.points.isNotEmpty == true
            ? _liveRoutePlan!.points.last
            : const LatLng(24.8607, 67.0011));
    markers.add(
      Marker(
        markerId: const MarkerId('destination_marker'),
        position: destPos,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: isUrdu ? 'منزل: $_destination' : 'Destination: $_destination',
          snippet: isUrdu ? 'ڈلیوری مقام' : 'Delivery Dropoff Hub',
        ),
      ),
    );

    // Bridge Hazard Markers
    for (final b in _corridorBridgeAlerts) {
      if (b.location == null) continue;
      markers.add(
        Marker(
          markerId: MarkerId('bridge_${b.bridgeName}'),
          position: b.location!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            b.isCritical ? BitmapDescriptor.hueRose : BitmapDescriptor.hueOrange,
          ),
          infoWindow: InfoWindow(
            title: isUrdu ? (b.nameUr ?? b.bridgeName) : b.bridgeName,
            snippet:
                'Clearance: ${b.clearanceHeightFt}ft (${b.clearanceHeightM.toStringAsFixed(1)}m) • Truck: ${b.truckHeightFt}ft',
          ),
        ),
      );
    }

    // Nearby Facilities (Truck Addas, Fuel, Weighbridge)
    for (final p in _nearbyPlaces) {
      double hue = BitmapDescriptor.hueGreen;
      if (p.category == 'fuel') hue = BitmapDescriptor.hueOrange;
      if (p.category == 'weighbridge') hue = BitmapDescriptor.hueViolet;

      markers.add(
        Marker(
          markerId: MarkerId('place_${p.name}_${p.location.latitude}'),
          position: p.location,
          icon: BitmapDescriptor.defaultMarkerWithHue(hue),
          infoWindow: InfoWindow(
            title: p.name,
            snippet: p.address,
            onTap: () {
              setState(() => _selectedPlace = p);
            },
          ),
        ),
      );
    }

    // Live Crowdsourced Road Hazards from Firestore
    for (final r in reportsList) {
      final cat = RoadReportCategory.findById(r.reportType);
      markers.add(
        Marker(
          markerId: MarkerId('hazard_${r.id}'),
          position: const LatLng(30.8138, 73.4534), // Okara N-5 hazard coordinate
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
          infoWindow: InfoWindow(
            title: isUrdu ? (cat?.nameUr ?? r.reportType) : (cat?.nameEn ?? r.reportType),
            snippet: r.description ?? '',
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLogo(size: 28, borderRadius: 6),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                l10n.routePlannerTitle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: isUrdu ? 'روٹ کا لنک شیئر کریں' : 'Share Route Link',
            onPressed: () {
              final baseUri = Uri.base;
              final shareUrl = '${baseUri.scheme}://${baseUri.host}${baseUri.hasPort ? ':${baseUri.port}' : ''}/route-planner?origin=${Uri.encodeComponent(_origin)}&destination=${Uri.encodeComponent(_destination)}&vehicle=${Uri.encodeComponent(_selectedVehicleId)}&motorway=$_useMotorwayBypass';
              Clipboard.setData(ClipboardData(text: shareUrl));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.primary,
                  content: Text(
                    isUrdu
                        ? 'روٹ کا لنک کاپی کر لیا گیا ہے: $_origin تا $_destination'
                        : 'Route link copied to clipboard: $_origin to $_destination',
                  ),
                  action: SnackBarAction(
                    label: isUrdu ? 'واٹس ایپ' : 'WhatsApp',
                    textColor: AppColors.accent,
                    onPressed: () {
                      final msg = isUrdu
                          ? 'Truck Link PK پر روٹ دیکھیں ($_origin تا $_destination):\n$shareUrl'
                          : 'Check this route on Truck Link PK ($_origin to $_destination):\n$shareUrl';
                      AppLauncher.openWhatsApp(phone: '', message: msg);
                    },
                  ),
                ),
              );
            },
          ),
          const Center(child: LanguageToggleButton(compact: true)),
          SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Origin / Destination & Truck Selector
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
                          isUrdu ? 'گوگل روٹس انجن اور نیویگیشن' : 'Google Routes & Corridor Safety',
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
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              DropdownButtonFormField<String>(
                                initialValue: _origin,
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                items: _majorCities
                                    .map(
                                      (c) => DropdownMenuItem(
                                        value: c,
                                        child: Text(c, style: const TextStyle(fontSize: 13)),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null && v != _origin) {
                                    setState(() => _origin = v);
                                    _syncUrl();
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
                              _syncUrl();
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
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              DropdownButtonFormField<String>(
                                initialValue: _destination,
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                items: _majorCities
                                    .map(
                                      (c) => DropdownMenuItem(
                                        value: c,
                                        child: Text(c, style: const TextStyle(fontSize: 13)),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null && v != _destination) {
                                    setState(() => _destination = v);
                                    _syncUrl();
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
                    const SizedBox(height: 12),
                    // Truck Height Specification Row
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.local_shipping, size: 20, color: AppColors.primary),
                              const SizedBox(width: 8),
                              DropdownButton<String>(
                                value: _selectedVehicleId,
                                underline: const SizedBox(),
                                items: VehicleType.all.map((v) {
                                  return DropdownMenuItem(
                                    value: v.id,
                                    child: Text(
                                      isUrdu ? v.nameUr : v.nameEn,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _selectedVehicleId = val);
                                    _syncUrl();
                                    _fetchLiveRoute();
                                  }
                                },
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${_selectedVehicle.standardHeightFt} ft (${_selectedVehicle.standardHeightM} m)',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Critical Low Bridge Danger Banner (if triggered)
            if (hasCriticalClearance && criticalBridge != null)
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

            // Native Google Maps Canvas Card with PointerInterceptor
            Card(
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Map Header Toolbar with Normal/Satellite & Traffic toggles
                  PointerInterceptor(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      color: AppColors.primary,
                      child: Row(
                        children: [
                          const Icon(Icons.map, color: AppColors.accent, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '$_origin ➔ $_destination',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Satellite View Toggle
                          IconButton(
                            icon: Icon(
                              _isSatelliteView ? Icons.satellite_alt : Icons.map_outlined,
                              color: _isSatelliteView ? AppColors.accent : Colors.white70,
                              size: 20,
                            ),
                            tooltip: _isSatelliteView ? l10n.normalView : l10n.satelliteView,
                            onPressed: () {
                              setState(() => _isSatelliteView = !_isSatelliteView);
                            },
                          ),
                          // Live Traffic Toggle
                          IconButton(
                            icon: Icon(
                              Icons.traffic,
                              color: _isTrafficEnabled ? Colors.greenAccent : Colors.white70,
                              size: 20,
                            ),
                            tooltip: l10n.liveTraffic,
                            onPressed: () {
                              setState(() => _isTrafficEnabled = !_isTrafficEnabled);
                            },
                          ),
                          // Fit Camera to Route
                          IconButton(
                            icon: const Icon(Icons.crop_free, color: Colors.white70, size: 20),
                            tooltip: 'Fit Route',
                            onPressed: _fitRouteInView,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Native GoogleMap View
                  SizedBox(
                    height: 380,
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _cityCoordinates[_origin] ?? const LatLng(30.3753, 69.3451),
                        zoom: 6.0,
                      ),
                      mapType: _isSatelliteView ? MapType.hybrid : MapType.normal,
                      trafficEnabled: _isTrafficEnabled,
                      polylines: polylines,
                      markers: markers,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: true,
                      onMapCreated: (ctrl) {
                        _mapController = ctrl;
                        _fitRouteInView();
                      },
                    ),
                  ),

                  // Selected Facility Details Card (if clicked)
                  if (_selectedPlace != null)
                    PointerInterceptor(
                      child: Container(
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
                                    style:
                                        const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
                    ),

                  // Map Legend & Facility Filter Bar (Wrapped with PointerInterceptor)
                  PointerInterceptor(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      color: Colors.grey.shade100,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                isUrdu ? 'قریبی سہولیات:' : 'Find Near Destination:',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              ChoiceChip(
                                label: Text(isUrdu ? 'اڈے' : 'Addas',
                                    style: const TextStyle(fontSize: 11)),
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
                                label: Text(isUrdu ? 'ڈیزل پمپ' : 'Fuel',
                                    style: const TextStyle(fontSize: 11)),
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
                                label: Text(isUrdu ? 'وزن کانٹا' : 'Weigh',
                                    style: const TextStyle(fontSize: 11)),
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
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Highway Route Mode Switcher (Motorway M-3/M-5 vs N-5)
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text(
                      l10n.useMotorwayBypass,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: Text(
                      isUrdu
                          ? 'موٹروے M-3 / M-5 کا انتخاب کریں (بغیر رکاوٹ، تیز سفر اور اونچے پل)'
                          : 'Prefer Motorway M-3 / M-5 (Fast, avoids low railway bridges)',
                      style: const TextStyle(fontSize: 12),
                    ),
                    value: _useMotorwayBypass,
                    activeThumbColor: AppColors.primary,
                    onChanged: (val) {
                      setState(() => _useMotorwayBypass = val);
                      _syncUrl();
                      _fetchLiveRoute();
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Tabbed Interactive Route Guidance & Safety Drawer
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  TabBar(
                    controller: _tabController,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: Colors.grey.shade600,
                    indicatorColor: AppColors.accent,
                    indicatorWeight: 3,
                    tabs: [
                      Tab(
                        icon: const Icon(Icons.shield_outlined, size: 20),
                        text: l10n.safetyAndAlerts,
                      ),
                      Tab(
                        icon: const Icon(Icons.turn_right_rounded, size: 20),
                        text: l10n.turnByTurnSteps,
                      ),
                      Tab(
                        icon: const Icon(Icons.payments_outlined, size: 20),
                        text: l10n.costAndStops,
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 380,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Tab 1: Safety & Bridge Alerts
                        _buildSafetyTab(isUrdu, l10n, reportsList),

                        // Tab 2: Turn-by-Turn Guidance Steps
                        _buildTurnByTurnTab(isUrdu, l10n),

                        // Tab 3: Cost, Fuel, Tolls & GPS Deep Link
                        _buildCostAndStopsTab(
                          isUrdu,
                          l10n,
                          distanceKm,
                          dieselCostPkr,
                          tollCostPkr,
                          totalTripCostPkr,
                        ),
                      ],
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

  /// Tab 1: Safety & Bridge Clearance Alerts
  Widget _buildSafetyTab(
    bool isUrdu,
    AppLocalizations l10n,
    List<RoadReport> reportsList,
  ) {
    final hasCritical = _corridorBridgeAlerts.any((b) => b.isCritical);

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Truck Clearance Status Header
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: hasCritical
                ? AppColors.danger.withValues(alpha: 0.1)
                : AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: hasCritical ? AppColors.danger : AppColors.success,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Icon(
                hasCritical ? Icons.dangerous : Icons.check_circle,
                color: hasCritical ? AppColors.danger : AppColors.success,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasCritical ? l10n.criticalClearanceDanger : l10n.clearanceSafe,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: hasCritical ? AppColors.danger : AppColors.success,
                      ),
                    ),
                    Text(
                      '${_selectedVehicle.nameEn} (Height: ${_selectedVehicle.standardHeightFt} ft / ${_selectedVehicle.standardHeightM} m)',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                onPressed: () => _speakSafetySummary(isUrdu),
                icon: const Icon(Icons.volume_up, size: 16),
                label: Text(l10n.speakAlert),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Detected Bridges along the route
        Text(
          l10n.detectedClearanceAlerts,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),

        if (_corridorBridgeAlerts.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Text(
              isUrdu
                  ? 'اس راستے پر کوئی خطرناک پل ریکارڈ میں نہیں ہے۔'
                  : 'No restricted bridges detected along this corridor.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          )
        else
          ..._corridorBridgeAlerts.map((b) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              color: b.isCritical ? Colors.red.shade50 : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: b.isCritical ? Colors.red.shade300 : Colors.grey.shade200,
                ),
              ),
              child: ListTile(
                dense: true,
                leading: Icon(
                  b.isCritical ? Icons.error : Icons.verified,
                  color: b.isCritical ? AppColors.danger : AppColors.success,
                ),
                title: Text(
                  isUrdu ? (b.nameUr ?? b.bridgeName) : b.bridgeName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: b.isCritical ? AppColors.danger : Colors.black87,
                  ),
                ),
                subtitle: Text(
                  '${b.roadSegment}\n${isUrdu ? (b.warningUr ?? b.warningEn ?? "") : (b.warningEn ?? "")}',
                  style: const TextStyle(fontSize: 11),
                ),
                trailing: Text(
                  '${b.clearanceHeightFt} ft\n(${b.clearanceHeightM.toStringAsFixed(1)}m)',
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: b.isCritical ? AppColors.danger : Colors.black87,
                  ),
                ),
                onTap: () {
                  if (b.location != null) {
                    _mapController?.animateCamera(
                      CameraUpdate.newLatLngZoom(b.location!, 14.0),
                    );
                  }
                },
              ),
            );
          }),

        const Divider(height: 24),

        // Live Road Hazards from Community
        Text(
          l10n.roadHazardAlert,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        if (reportsList.isEmpty)
          Text(
            l10n.noHazardReports,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          )
        else
          ...reportsList.take(3).map((r) {
            final cat = RoadReportCategory.findById(r.reportType);
            return ListTile(
              dense: true,
              leading: Icon(Icons.report_problem, color: cat?.color ?? AppColors.danger),
              title: Text(
                isUrdu ? (cat?.nameUr ?? r.reportType) : (cat?.nameEn ?? r.reportType),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              subtitle: Text(r.description ?? ''),
            );
          }),
      ],
    );
  }

  /// Tab 2: Turn-by-Turn Navigation Steps
  Widget _buildTurnByTurnTab(bool isUrdu, AppLocalizations l10n) {
    final steps = _liveRoutePlan?.steps ?? [];

    if (steps.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.navigation_outlined, size: 40, color: Colors.grey),
              const SizedBox(height: 8),
              Text(
                l10n.noTurnStepsAvailable,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12.0),
      itemCount: steps.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, idx) {
        final step = steps[idx];
        IconData maneuverIcon = Icons.straight;
        if (step.maneuver.contains('LEFT')) {
          maneuverIcon = Icons.turn_left;
        } else if (step.maneuver.contains('RIGHT')) {
          maneuverIcon = Icons.turn_right;
        } else if (step.maneuver.contains('UTURN')) {
          maneuverIcon = Icons.u_turn_left;
        } else if (step.maneuver.contains('RAMP') || step.maneuver.contains('FORK')) {
          maneuverIcon = Icons.merge;
        }

        return ListTile(
          dense: true,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(maneuverIcon, color: AppColors.primary, size: 20),
          ),
          title: Text(
            step.instruction,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          subtitle: Text('${step.distanceText} • ${step.durationText}'),
          trailing: const Icon(Icons.search, size: 18, color: Colors.grey),
          onTap: () {
            _mapController?.animateCamera(
              CameraUpdate.newLatLngZoom(step.startLocation, 14.5),
            );
          },
        );
      },
    );
  }

  /// Tab 3: Cost, Stops & Google GPS Navigation Deep Link
  Widget _buildCostAndStopsTab(
    bool isUrdu,
    AppLocalizations l10n,
    double distanceKm,
    double dieselCostPkr,
    double tollCostPkr,
    double totalTripCostPkr,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Cost Summary Box
        Row(
          children: [
            Expanded(
              child: _CostSummaryBox(
                title: isUrdu ? 'فاصلہ (گوگل)' : 'Distance',
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
                title: isUrdu ? 'ٹول ٹیکس' : 'Est. Toll',
                value: AppFormatters.formatPkr(tollCostPkr),
                color: AppColors.success,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Total Trip Cost Box
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isUrdu ? 'کل متوقع سفری لاگت:' : 'Total Est. Trip Expense:',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text(
                AppFormatters.formatPkr(totalTripCostPkr),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 1-Tap External Google Maps Turn-by-Turn GPS Navigation Button
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () {
            final url =
                'https://www.google.com/maps/dir/?api=1&origin=$_origin,Pakistan&destination=$_destination,Pakistan';
            AppLauncher.openUrl(url);
          },
          icon: const Icon(Icons.navigation, color: AppColors.accent),
          label: Text(
            l10n.openGpsNavigation,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
      ],
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
          Text(
            title,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
