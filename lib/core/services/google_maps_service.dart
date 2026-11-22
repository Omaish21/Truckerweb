import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'places/places_interop.dart';

class RouteStep {
  final String instruction;
  final String maneuver;
  final int distanceMeters;
  final int durationSeconds;
  final LatLng startLocation;
  final LatLng endLocation;

  const RouteStep({
    required this.instruction,
    required this.maneuver,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.startLocation,
    required this.endLocation,
  });

  double get distanceKm => distanceMeters / 1000.0;

  String get distanceText =>
      distanceKm < 1.0 ? '${distanceMeters}m' : '${distanceKm.toStringAsFixed(1)}km';

  String get durationText {
    final mins = durationSeconds ~/ 60;
    if (mins >= 60) {
      final hrs = mins ~/ 60;
      final remMins = mins % 60;
      return '$hrs hr $remMins min';
    }
    return '$mins min';
  }
}

class GoogleRoutePlan {
  final String origin;
  final String destination;
  final int distanceMeters;
  final int durationSeconds;
  final String encodedPolyline;
  final List<LatLng> points;
  final List<RouteStep> steps;

  const GoogleRoutePlan({
    required this.origin,
    required this.destination,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.encodedPolyline,
    required this.points,
    this.steps = const [],
  });

  double get distanceKm => distanceMeters / 1000.0;

  String get durationText {
    final hours = durationSeconds ~/ 3600;
    final mins = (durationSeconds % 3600) ~/ 60;
    if (hours > 0) {
      return '$hours hrs $mins mins';
    }
    return '$mins mins';
  }

  String durationTextUrdu() {
    final hours = durationSeconds ~/ 3600;
    final mins = (durationSeconds % 3600) ~/ 60;
    if (hours > 0) {
      return '$hours گھنٹے $mins منٹ';
    }
    return '$mins منٹ';
  }

  double calculateDieselLiters({required double kmPerLiter}) {
    if (kmPerLiter <= 0) return 0;
    return distanceKm / kmPerLiter;
  }

  double calculateDieselCost({required double kmPerLiter, double pricePerLiter = 285.0}) {
    return calculateDieselLiters(kmPerLiter: kmPerLiter) * pricePerLiter;
  }

  double calculateTollCost({required bool useMotorway}) {
    if (!useMotorway) return (distanceKm * 5.5).clamp(2000.0, 8500.0);
    return (distanceKm * 12.0).clamp(4000.0, 18500.0);
  }

  double calculateTotalTripCost({
    required double kmPerLiter,
    required bool useMotorway,
    double pricePerLiter = 285.0,
  }) {
    return calculateDieselCost(kmPerLiter: kmPerLiter, pricePerLiter: pricePerLiter) +
        calculateTollCost(useMotorway: useMotorway);
  }
}

class TruckPlace {
  final String name;
  final String address;
  final LatLng location;
  final String category; // 'adda', 'fuel', 'weighbridge', 'dryport'

  const TruckPlace({
    required this.name,
    required this.address,
    required this.location,
    required this.category,
  });
}

class GoogleMapsService {
  static const String apiKey = 'AIzaSyC3-mnY90RAu4nEV3iOG6j9aH2XQAbW0tg';

  static final Map<String, GoogleRoutePlan> _routeCache = {};
  static final Map<String, List<TruckPlace>> _placesCache = {};

  /// Decodes Google Encoded Polyline into LatLng points
  static List<LatLng> decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      poly.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return poly;
  }

  /// Computes live real-world Google Highway Route between any two Pakistani cities/locations
  static Future<GoogleRoutePlan?> computeRoute({
    required String origin,
    required String destination,
    bool avoidTolls = false,
  }) async {
    final cacheKey = '${origin.trim()}_${destination.trim()}_avoidTolls:$avoidTolls';
    if (_routeCache.containsKey(cacheKey)) {
      return _routeCache[cacheKey];
    }

    try {
      final originAddress = origin.contains('Pakistan') ? origin : '$origin, Pakistan';
      final destAddress = destination.contains('Pakistan') ? destination : '$destination, Pakistan';

      final body = {
        'origin': {'address': originAddress},
        'destination': {'address': destAddress},
        'travelMode': 'DRIVE',
        if (avoidTolls)
          'routeModifiers': {
            'avoidTolls': true,
          },
      };

      final response = await http.post(
        Uri.parse('https://routes.googleapis.com/directions/v2:computeRoutes'),
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': apiKey,
          'X-Goog-FieldMask':
              'routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline,routes.legs.steps.navigationInstruction,routes.legs.steps.distanceMeters,routes.legs.steps.staticDuration,routes.legs.steps.startLocation,routes.legs.steps.endLocation',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final routes = data['routes'] as List<dynamic>?;
        if (routes != null && routes.isNotEmpty) {
          final firstRoute = routes[0] as Map<String, dynamic>;
          final distMeters = (firstRoute['distanceMeters'] as num?)?.toInt() ?? 0;
          final durationStr = (firstRoute['duration'] as String?)?.replaceAll('s', '') ?? '0';
          final durationSecs = int.tryParse(durationStr) ?? 0;
          final polyline = firstRoute['polyline']?['encodedPolyline'] as String? ?? '';

          final points = polyline.isNotEmpty ? decodePolyline(polyline) : <LatLng>[];

          // Parse turn-by-turn navigation steps
          final parsedSteps = <RouteStep>[];
          final legs = firstRoute['legs'] as List<dynamic>?;
          if (legs != null && legs.isNotEmpty) {
            final stepsRaw = legs[0]['steps'] as List<dynamic>?;
            if (stepsRaw != null) {
              for (final s in stepsRaw) {
                final instruction =
                    s['navigationInstruction']?['instructions'] as String? ?? '';
                final maneuver =
                    s['navigationInstruction']?['maneuver'] as String? ?? 'MANEUVER_UNSPECIFIED';
                final stepDist = (s['distanceMeters'] as num?)?.toInt() ?? 0;
                final stepDurationStr =
                    (s['staticDuration'] as String?)?.replaceAll('s', '') ?? '0';
                final stepDurSecs = int.tryParse(stepDurationStr) ?? 0;

                final startLat =
                    (s['startLocation']?['latLng']?['latitude'] as num?)?.toDouble() ?? 0.0;
                final startLng =
                    (s['startLocation']?['latLng']?['longitude'] as num?)?.toDouble() ?? 0.0;
                final endLat =
                    (s['endLocation']?['latLng']?['latitude'] as num?)?.toDouble() ?? 0.0;
                final endLng =
                    (s['endLocation']?['latLng']?['longitude'] as num?)?.toDouble() ?? 0.0;

                if (instruction.isNotEmpty) {
                  parsedSteps.add(
                    RouteStep(
                      instruction: instruction,
                      maneuver: maneuver,
                      distanceMeters: stepDist,
                      durationSeconds: stepDurSecs,
                      startLocation: LatLng(startLat, startLng),
                      endLocation: LatLng(endLat, endLng),
                    ),
                  );
                }
              }
            }
          }

          final plan = GoogleRoutePlan(
            origin: origin,
            destination: destination,
            distanceMeters: distMeters,
            durationSeconds: durationSecs,
            encodedPolyline: polyline,
            points: points,
            steps: parsedSteps,
          );

          _routeCache[cacheKey] = plan;
          return plan;
        }
      } else {
        debugPrint('Google Routes API error: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      debugPrint('Error calling Google Routes API: $e');
    }
    return null;
  }

  /// Searches Google Places (New) for nearby Truck Addas, Diesel Pumps, or Weighbridges
  static Future<List<TruckPlace>> searchTruckPlaces({
    required String query,
    required String category,
  }) async {
    final cacheKey = '${category}_$query';
    if (_placesCache.containsKey(cacheKey)) {
      return _placesCache[cacheKey]!;
    }

    try {
      final response = await http.post(
        Uri.parse('https://places.googleapis.com/v1/places:searchText'),
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': apiKey,
          'X-Goog-FieldMask': 'places.displayName,places.formattedAddress,places.location',
        },
        body: jsonEncode({
          'textQuery': '$query Pakistan',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final places = data['places'] as List<dynamic>?;
        if (places != null) {
          final list = places.map((p) {
            final loc = p['location'] as Map<String, dynamic>?;
            final lat = (loc?['latitude'] as num?)?.toDouble() ?? 0.0;
            final lng = (loc?['longitude'] as num?)?.toDouble() ?? 0.0;
            final name = p['displayName']?['text'] as String? ?? 'Truck Facility';
            final address = p['formattedAddress'] as String? ?? 'Pakistan';
            return TruckPlace(
              name: name,
              address: address,
              location: LatLng(lat, lng),
              category: category,
            );
          }).where((p) => p.location.latitude != 0.0).toList();

          _placesCache[cacheKey] = list;
          return list;
        }
      }
    } catch (e) {
      debugPrint('Error searching truck places: $e');
    }
    return [];
  }

  /// Fetches place autocomplete predictions in Pakistan using Google Places API (JS client + REST fallback)
  static Future<List<String>> getPlaceSuggestions(String input) async {
    final cleanInput = input.trim();
    if (cleanInput.length < 2) return [];

    // 1. Try web JavaScript Google Places Autocomplete first (runs in browser domain with paid API key)
    try {
      final webPredictions = await getWebPlacePredictions(cleanInput);
      if (webPredictions.isNotEmpty) {
        return webPredictions;
      }
    } catch (e) {
      debugPrint('getWebPlacePredictions error: $e');
    }

    // 2. Fallback to Google Places (New) REST API
    try {
      final response = await http.post(
        Uri.parse('https://places.googleapis.com/v1/places:autocomplete'),
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': apiKey,
        },
        body: jsonEncode({
          'input': cleanInput,
          'includedRegionCodes': ['pk'],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final suggestions = data['suggestions'] as List<dynamic>?;
        if (suggestions != null) {
          return suggestions
              .map((s) => s['placePrediction']?['text']?['text'] as String?)
              .whereType<String>()
              .toList();
        }
      }
    } catch (_) {}
    return [];
  }
}
