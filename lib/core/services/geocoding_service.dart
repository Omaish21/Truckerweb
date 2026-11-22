import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'google_maps_service.dart';

/// Geocoding result data model with Pakistani logistics metadata
class GeocodingLocation {
  final String query;
  final String formattedAddress;
  final LatLng coordinates;
  final String? cityName;
  final String? province;
  final String? postalCode;
  final String? placeId;
  final bool isVerifiedHub;
  final bool isFallback;

  const GeocodingLocation({
    required this.query,
    required this.formattedAddress,
    required this.coordinates,
    this.cityName,
    this.province,
    this.postalCode,
    this.placeId,
    this.isVerifiedHub = false,
    this.isFallback = false,
  });

  double get latitude => coordinates.latitude;
  double get longitude => coordinates.longitude;
}

/// Pakistani Logistics Hub / Landmark Entry
class LogisticsLandmark {
  final String id;
  final String nameEn;
  final String nameUr;
  final String category; // 'port', 'dryport', 'toll_plaza', 'border', 'industrial_estate'
  final String city;
  final String highway;
  final LatLng location;

  const LogisticsLandmark({
    required this.id,
    required this.nameEn,
    required this.nameUr,
    required this.category,
    required this.city,
    required this.highway,
    required this.location,
  });
}

/// Robust Pakistani Geocoding and Reverse Geocoding Service.
/// Interacts directly with Google Geocoding API with smart offline fallback for Pakistani logistics nodes.
class GeocodingService {
  static final GeocodingService instance = GeocodingService._internal();
  factory GeocodingService() => instance;
  GeocodingService._internal();

  final Map<String, GeocodingLocation> _forwardCache = {};
  final Map<String, String> _reverseCache = {};

  /// Comprehensive catalog of Pakistan's major freight hubs, dry ports, customs borders, and toll plazas
  static const List<LogisticsLandmark> majorLogisticsLandmarks = [
    // Seaports
    LogisticsLandmark(
      id: 'khi_port',
      nameEn: 'Karachi Port (KPT East & West Wharf)',
      nameUr: 'کراچی پورٹ (کے پی ٹی)',
      category: 'port',
      city: 'Karachi',
      highway: 'M-9 / Northern Bypass',
      location: LatLng(24.8436, 66.9744),
    ),
    LogisticsLandmark(
      id: 'port_qasim',
      nameEn: 'Port Muhammad Bin Qasim (FOTCO & QICT)',
      nameUr: 'پورٹ قاسم',
      category: 'port',
      city: 'Karachi',
      highway: 'National Highway N-5',
      location: LatLng(24.7836, 67.3486),
    ),
    LogisticsLandmark(
      id: 'gwadar_port',
      nameEn: 'Gwadar Deep Sea Port',
      nameUr: 'گوادر ڈیپ سی پورٹ',
      category: 'port',
      city: 'Gwadar',
      highway: 'Makran Coastal Highway N-10',
      location: LatLng(25.1092, 62.3333),
    ),

    // Dry Ports & Inland Freight Terminals
    LogisticsLandmark(
      id: 'lhr_mughalpura',
      nameEn: 'Mughalpura Dry Port, Lahore',
      nameUr: 'مغلپورہ ڈرائی پورٹ لاہور',
      category: 'dryport',
      city: 'Lahore',
      highway: 'Canal Bank Road / Ring Road',
      location: LatLng(31.5714, 74.3792),
    ),
    LogisticsLandmark(
      id: 'lhr_prem_nagar',
      nameEn: 'Prem Nagar Dry Port (PNDP)',
      nameUr: 'پریم نگر ڈرائی پورٹ',
      category: 'dryport',
      city: 'Lahore',
      highway: 'Multan Road N-5',
      location: LatLng(31.2589, 74.1231),
    ),
    LogisticsLandmark(
      id: 'fsd_dryport',
      nameEn: 'Faisalabad Dry Port Trust (Gatti)',
      nameUr: 'فیصل آباد ڈرائی پورٹ ٹرسٹ',
      category: 'dryport',
      city: 'Faisalabad',
      highway: 'M-3 / Millat Road',
      location: LatLng(31.4883, 73.1558),
    ),
    LogisticsLandmark(
      id: 'skt_sambrial',
      nameEn: 'Sialkot Dry Port Sambrial (SDPT)',
      nameUr: 'سیالکوٹ ڈرائی پورٹ سمبڑیال',
      category: 'dryport',
      city: 'Sialkot',
      highway: 'M-11 Sialkot-Lahore Motorway',
      location: LatLng(32.4939, 74.3547),
    ),
    LogisticsLandmark(
      id: 'mul_dryport',
      nameEn: 'Multan Dry Port (Sher Shah)',
      nameUr: 'ملتان ڈرائی پورٹ شیر شاہ',
      category: 'dryport',
      city: 'Multan',
      highway: 'Multan Bypass / M-5',
      location: LatLng(30.1345, 71.3654),
    ),
    LogisticsLandmark(
      id: 'psh_dryport',
      nameEn: 'Peshawar Dry Port (Cantonment)',
      nameUr: 'پشاور ڈرائی پورٹ',
      category: 'dryport',
      city: 'Peshawar',
      highway: 'Grand Trunk Road N-5',
      location: LatLng(33.9983, 71.5542),
    ),
    LogisticsLandmark(
      id: 'qta_dryport',
      nameEn: 'Quetta Dry Port (Chaman Road)',
      nameUr: 'کوئٹہ ڈرائی پورٹ',
      category: 'dryport',
      city: 'Quetta',
      highway: 'N-25 / N-40',
      location: LatLng(30.1654, 66.9854),
    ),

    // Toll Plazas & Motorway Interchanges
    LogisticsLandmark(
      id: 'toll_ravi',
      nameEn: 'Ravi Toll Plaza (Lahore Entry)',
      nameUr: 'راوی ٹول پلازہ لاہور',
      category: 'toll_plaza',
      city: 'Lahore',
      highway: 'M-2 / N-5',
      location: LatLng(31.6231, 74.2754),
    ),
    LogisticsLandmark(
      id: 'toll_babu_sabu',
      nameEn: 'Babu Sabu Interchange & Truck Adda',
      nameUr: 'بابو صابو انٹرچینج اور ٹرک اڈا',
      category: 'toll_plaza',
      city: 'Lahore',
      highway: 'M-2 Motorway',
      location: LatLng(31.5422, 74.2642),
    ),
    LogisticsLandmark(
      id: 'toll_sukkur',
      nameEn: 'Rohri / Sukkur M-5 Interchange Toll Plaza',
      nameUr: 'روہڑی / سکھر موٹروے ایم-5 ٹول پلازہ',
      category: 'toll_plaza',
      city: 'Sukkur',
      highway: 'M-5 Multan-Sukkur Motorway',
      location: LatLng(27.6987, 68.9124),
    ),
    LogisticsLandmark(
      id: 'toll_karachi_m9',
      nameEn: 'Karachi M-9 Toll Plaza (Kathore)',
      nameUr: 'کراچی ایم-9 ٹول پلازہ',
      category: 'toll_plaza',
      city: 'Karachi',
      highway: 'M-9 Motorway',
      location: LatLng(25.0432, 67.3125),
    ),
    LogisticsLandmark(
      id: 'toll_islamabad',
      nameEn: 'Islamabad M-2 Toll Plaza (Zero Point)',
      nameUr: 'اسلام آباد ایم-2 ٹول پلازہ',
      category: 'toll_plaza',
      city: 'Islamabad',
      highway: 'M-2 Motorway',
      location: LatLng(33.6421, 72.9842),
    ),

    // Customs Borders
    LogisticsLandmark(
      id: 'border_torkham',
      nameEn: 'Torkham Pak-Afghan Border Crossing',
      nameUr: 'طورخم پاک افغان بارڈر کراسنگ',
      category: 'border',
      city: 'Khyber',
      highway: 'N-5 Peshawar-Torkham',
      location: LatLng(34.1256, 71.0924),
    ),
    LogisticsLandmark(
      id: 'border_chaman',
      nameEn: 'Chaman Friendship Gate Border',
      nameUr: 'چمن فرینڈشپ گیٹ',
      category: 'border',
      city: 'Chaman',
      highway: 'N-25 Quetta-Chaman Highway',
      location: LatLng(30.9234, 66.4521),
    ),
    LogisticsLandmark(
      id: 'border_taftan',
      nameEn: 'Taftan Pak-Iran Border Checkpost',
      nameUr: 'تفتان پاک ایران بارڈر',
      category: 'border',
      city: 'Taftan',
      highway: 'N-40 Highway',
      location: LatLng(28.9642, 61.5789),
    ),
    LogisticsLandmark(
      id: 'border_sost',
      nameEn: 'Sost Dry Port & Khunjerab Border',
      nameUr: 'سوست ڈرائی پورٹ (شاہراہ ریشم)',
      category: 'border',
      city: 'Sost',
      highway: 'Karakoram Highway N-35',
      location: LatLng(36.6854, 74.8214),
    ),
  ];

  /// Forward Geocode: Converts address / landmark text to GPS coordinates
  Future<GeocodingLocation?> forwardGeocode(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return null;

    final cacheKey = cleanQuery.toLowerCase();
    if (_forwardCache.containsKey(cacheKey)) {
      return _forwardCache[cacheKey];
    }

    // 1. Check local landmark catalog first for instant offline match
    for (final hub in majorLogisticsLandmarks) {
      if (cleanQuery.toLowerCase().contains(hub.city.toLowerCase()) ||
          cleanQuery.toLowerCase().contains(hub.id) ||
          hub.nameEn.toLowerCase().contains(cleanQuery.toLowerCase()) ||
          hub.nameUr.contains(cleanQuery)) {
        final loc = GeocodingLocation(
          query: cleanQuery,
          formattedAddress: '${hub.nameEn}, ${hub.highway}, Pakistan',
          coordinates: hub.location,
          cityName: hub.city,
          isVerifiedHub: true,
          isFallback: false,
        );
        _forwardCache[cacheKey] = loc;
        return loc;
      }
    }

    // 2. Call Google Geocoding API
    try {
      final formattedAddressParam = cleanQuery.contains('Pakistan')
          ? cleanQuery
          : '$cleanQuery, Pakistan';

      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(formattedAddressParam)}&region=pk&key=${GoogleMapsService.apiKey}',
      );

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final results = data['results'] as List<dynamic>?;

        if (results != null && results.isNotEmpty) {
          final first = results[0] as Map<String, dynamic>;
          final geom = first['geometry']?['location'];
          final lat = (geom?['lat'] as num?)?.toDouble() ?? 0.0;
          final lng = (geom?['lng'] as num?)?.toDouble() ?? 0.0;
          final formatted = first['formatted_address'] as String? ?? cleanQuery;
          final placeId = first['place_id'] as String?;

          // Parse address components for city and province
          String? city;
          String? province;
          String? postal;
          final components = first['address_components'] as List<dynamic>?;
          if (components != null) {
            for (final c in components) {
              final types = (c['types'] as List<dynamic>?)?.cast<String>() ?? [];
              if (types.contains('locality')) {
                city = c['long_name'] as String?;
              } else if (types.contains('administrative_area_level_1')) {
                province = c['long_name'] as String?;
              } else if (types.contains('postal_code')) {
                postal = c['long_name'] as String?;
              }
            }
          }

          final loc = GeocodingLocation(
            query: cleanQuery,
            formattedAddress: formatted,
            coordinates: LatLng(lat, lng),
            cityName: city,
            province: province,
            postalCode: postal,
            placeId: placeId,
            isVerifiedHub: false,
            isFallback: false,
          );

          _forwardCache[cacheKey] = loc;
          return loc;
        }
      }
    } catch (e) {
      debugPrint('Error during Google Forward Geocoding: $e');
    }

    // 3. Fallback: match major Pakistani cities
    final fallbackCoords = _getCityFallbackCoordinate(cleanQuery);
    if (fallbackCoords != null) {
      final loc = GeocodingLocation(
        query: cleanQuery,
        formattedAddress: '$cleanQuery, Pakistan',
        coordinates: fallbackCoords,
        cityName: cleanQuery,
        isVerifiedHub: false,
        isFallback: true,
      );
      _forwardCache[cacheKey] = loc;
      return loc;
    }

    return null;
  }

  /// Reverse Geocode: Resolves GPS coordinates into a human-readable street/city address
  Future<String?> reverseGeocode(LatLng coordinates) async {
    final key = '${coordinates.latitude.toStringAsFixed(4)},${coordinates.longitude.toStringAsFixed(4)}';
    if (_reverseCache.containsKey(key)) {
      return _reverseCache[key];
    }

    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=${coordinates.latitude},${coordinates.longitude}&key=${GoogleMapsService.apiKey}',
      );

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final results = data['results'] as List<dynamic>?;
        if (results != null && results.isNotEmpty) {
          final first = results[0] as Map<String, dynamic>;
          final formatted = first['formatted_address'] as String? ?? '';
          if (formatted.isNotEmpty) {
            _reverseCache[key] = formatted;
            return formatted;
          }
        }
      }
    } catch (e) {
      debugPrint('Error during Google Reverse Geocoding: $e');
    }

    // Fallback: Find nearest major hub
    final nearest = findNearestLandmark(coordinates);
    if (nearest != null) {
      final dist = calculateDistanceKm(coordinates, nearest.location);
      return '${nearest.nameEn} (~${dist.toStringAsFixed(1)} km away)';
    }

    return '${coordinates.latitude.toStringAsFixed(4)}° N, ${coordinates.longitude.toStringAsFixed(4)}° E';
  }

  /// Finds the nearest logistics landmark in Pakistan to a given coordinate
  LogisticsLandmark? findNearestLandmark(LatLng target) {
    LogisticsLandmark? closest;
    double minDistance = double.infinity;

    for (final hub in majorLogisticsLandmarks) {
      final dist = calculateDistanceKm(target, hub.location);
      if (dist < minDistance) {
        minDistance = dist;
        closest = hub;
      }
    }
    return closest;
  }

  /// Computes the great-circle distance between two coordinates in kilometers using Haversine formula
  static double calculateDistanceKm(LatLng a, LatLng b) {
    const earthRadiusKm = 6371.0;
    final dLat = _degreesToRadians(b.latitude - a.latitude);
    final dLon = _degreesToRadians(b.longitude - a.longitude);

    final lat1 = _degreesToRadians(a.latitude);
    final lat2 = _degreesToRadians(b.latitude);

    final sinDlat = math.sin(dLat / 2);
    final sinDlon = math.sin(dLon / 2);

    final h = sinDlat * sinDlat +
        math.cos(lat1) * math.cos(lat2) * sinDlon * sinDlon;

    final c = 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
    return earthRadiusKm * c;
  }

  /// Computes compass bearing in degrees (0° = North, 90° = East, 180° = South, 270° = West)
  static double calculateBearing(LatLng a, LatLng b) {
    final lat1 = _degreesToRadians(a.latitude);
    final lon1 = _degreesToRadians(a.longitude);
    final lat2 = _degreesToRadians(b.latitude);
    final lon2 = _degreesToRadians(b.longitude);

    final dLon = lon2 - lon1;

    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    final radians = math.atan2(y, x);
    final degrees = (radians * 180.0 / math.pi + 360.0) % 360.0;
    return degrees;
  }

  static double _degreesToRadians(double degrees) => degrees * math.pi / 180.0;

  /// Synchronous fast lookup for known Pakistani cities and hubs
  LatLng? getKnownCoordinates(String cityName) => _getCityFallbackCoordinate(cityName);

  static LatLng? _getCityFallbackCoordinate(String cityName) {
    final lower = cityName.toLowerCase();
    const map = {
      'lahore': LatLng(31.5204, 74.3587),
      'karachi': LatLng(24.8607, 67.0011),
      'islamabad': LatLng(33.6844, 73.0479),
      'rawalpindi': LatLng(33.5651, 73.0169),
      'faisalabad': LatLng(31.4504, 73.1350),
      'multan': LatLng(30.1575, 71.5249),
      'peshawar': LatLng(34.0151, 71.5249),
      'quetta': LatLng(30.1798, 66.9750),
      'sukkur': LatLng(27.7052, 68.8574),
      'gwadar': LatLng(25.1216, 62.3254),
      'hyderabad': LatLng(25.3960, 68.3578),
      'gujranwala': LatLng(32.1877, 74.1945),
      'sialkot': LatLng(32.4945, 74.5229),
      'okara': LatLng(30.8138, 73.4534),
      'sahiwal': LatLng(30.6682, 73.1114),
      'bahawalpur': LatLng(29.3544, 71.6911),
      'rahim yar khan': LatLng(28.4212, 70.2989),
      'chaman': LatLng(30.9234, 66.4521),
      'torkham': LatLng(34.1256, 71.0924),
    };

    for (final entry in map.entries) {
      if (lower.contains(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }
}
