import 'dart:math' as math;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class TruckProfile {
  final double heightCm; // e.g. 457 (15ft)
  final double widthCm; // e.g. 244 (8ft)
  final double lengthCm; // e.g. 1219 (40ft)
  final double grossWeightKg; // e.g. 30000
  final int axleCount;
  final List<String> hazmatClasses;

  const TruckProfile({
    required this.heightCm,
    required this.widthCm,
    required this.lengthCm,
    required this.grossWeightKg,
    this.axleCount = 4,
    this.hazmatClasses = const [],
  });

  double get heightFt => heightCm / 30.48;
  double get widthFt => widthCm / 30.48;
  double get lengthFt => lengthCm / 30.48;
  double get grossWeightTons => grossWeightKg / 1000.0;
}

class BridgeClearanceAlert {
  final String bridgeName;
  final String? nameUr;
  final double clearanceHeightFt;
  final double clearanceHeightM;
  final double truckHeightFt;
  final String roadSegment;
  final double distanceAheadKm;
  final bool isCritical;
  final LatLng? location;
  final double? maxWeightTons;
  final String? warningEn;
  final String? warningUr;

  const BridgeClearanceAlert({
    required this.bridgeName,
    this.nameUr,
    required this.clearanceHeightFt,
    this.clearanceHeightM = 0.0,
    required this.truckHeightFt,
    required this.roadSegment,
    required this.distanceAheadKm,
    required this.isCritical,
    this.location,
    this.maxWeightTons,
    this.warningEn,
    this.warningUr,
  });

  double get differenceFt => truckHeightFt - clearanceHeightFt;
}

class PakistanBridgeHazard {
  final String id;
  final String nameEn;
  final String nameUr;
  final String roadSegment;
  final LatLng location;
  final double clearanceHeightFt;
  final double clearanceHeightM;
  final double maxWeightTons;
  final String warningEn;
  final String warningUr;
  final bool isMotorway;

  const PakistanBridgeHazard({
    required this.id,
    required this.nameEn,
    required this.nameUr,
    required this.roadSegment,
    required this.location,
    required this.clearanceHeightFt,
    required this.clearanceHeightM,
    required this.maxWeightTons,
    required this.warningEn,
    required this.warningUr,
    this.isMotorway = false,
  });

  BridgeClearanceAlert toAlert({
    required double truckHeightFt,
    double distanceAheadKm = 0,
  }) {
    return BridgeClearanceAlert(
      bridgeName: nameEn,
      nameUr: nameUr,
      clearanceHeightFt: clearanceHeightFt,
      clearanceHeightM: clearanceHeightM,
      truckHeightFt: truckHeightFt,
      roadSegment: roadSegment,
      distanceAheadKm: distanceAheadKm,
      isCritical: truckHeightFt > clearanceHeightFt,
      location: location,
      maxWeightTons: maxWeightTons,
      warningEn: warningEn,
      warningUr: warningUr,
    );
  }
}

class PakistanBridgesDataset {
  static const List<PakistanBridgeHazard> all = [
    PakistanBridgeHazard(
      id: 'sahiwal_rail',
      nameEn: 'Sahiwal Railway Overhead Bridge #12',
      nameUr: 'ساہیوال ریلوے اوور ہیڈ پل نمبر ۱۲',
      roadSegment: 'National Highway N-5 near Sahiwal',
      location: LatLng(30.6682, 73.1114),
      clearanceHeightFt: 14.0,
      clearanceHeightM: 4.27,
      maxWeightTons: 40.0,
      warningEn: 'Strict 14.0 ft clearance. High-cube containers will hit overhead girder.',
      warningUr: 'صرف ۱۴ فٹ اونچائی! ہائی کیوب کنٹینرز اور بڑے ٹرالے پل سے ٹکرا سکتے ہیں۔',
      isMotorway: false,
    ),
    PakistanBridgeHazard(
      id: 'gujranwala_chan',
      nameEn: 'Chan Da Qila Railway Overhead Bridge',
      nameUr: 'چن دا قلعہ ریلوے اوور ہیڈ پل',
      roadSegment: 'N-5 GT Road, Gujranwala Bypass',
      location: LatLng(32.1384, 74.1982),
      clearanceHeightFt: 14.2,
      clearanceHeightM: 4.33,
      maxWeightTons: 45.0,
      warningEn: '14.2 ft overhead beam clearance. Container traffic must use bypass lane.',
      warningUr: '۱۴.۲ فٹ اونچائی۔ کنٹینر اور ٹرالے لازمی بائی پاس سڑک استعمال کریں۔',
      isMotorway: false,
    ),
    PakistanBridgeHazard(
      id: 'wazirabad_truss',
      nameEn: 'Palkhu Nullah Historic Steel Truss Bridge',
      nameUr: 'پلکھو نالہ پرانا لوہے کا ٹرس پل',
      roadSegment: 'N-5 Grand Trunk Road, Wazirabad',
      location: LatLng(32.4412, 74.1205),
      clearanceHeightFt: 14.4,
      clearanceHeightM: 4.39,
      maxWeightTons: 38.0,
      warningEn: 'Low steel truss arch. Max clearance 14.4 ft. Overloaded trucks restricted.',
      warningUr: 'لوہے کا پرانا محرابی پل۔ ۱۴.۴ فٹ سے زائد اونچی گاڑیاں منع ہیں۔',
      isMotorway: false,
    ),
    PakistanBridgeHazard(
      id: 'jhelum_arch',
      nameEn: 'Jhelum River Historic Overhead Arch Bridge',
      nameUr: 'دریائے جہلم تاریخی محرابی پل',
      roadSegment: 'N-5 GT Road Jhelum Entrance',
      location: LatLng(32.9328, 73.7262),
      clearanceHeightFt: 14.6,
      clearanceHeightM: 4.45,
      maxWeightTons: 42.0,
      warningEn: 'Arch clearance 14.6 ft at center, lower at shoulders. Heavy trailers use new bypass.',
      warningUr: 'مرکز میں ۱۴.۶ فٹ اونچائی۔ ۲۲ ویلر ٹرالے نیا جہلم بائی پاس استعمال کریں۔',
      isMotorway: false,
    ),
    PakistanBridgeHazard(
      id: 'attock_indus',
      nameEn: 'Attock Khurd Historic Indus Rail/Road Bridge',
      nameUr: 'اٹک خورد دریائے سندھ تاریخی ریلوے پل',
      roadSegment: 'N-5 Punjab-KP Border, Attock',
      location: LatLng(33.8892, 72.2415),
      clearanceHeightFt: 14.0,
      clearanceHeightM: 4.27,
      maxWeightTons: 35.0,
      warningEn: 'Double-deck historic structure. Strict 14.0 ft height limit. Heavy trucks use M-1.',
      warningUr: 'ڈبل ڈیکر پل۔ سخت ۱۴ فٹ حد۔ تمام بڑے ٹرک موٹروے M-1 اختیار کریں۔',
      isMotorway: false,
    ),
    PakistanBridgeHazard(
      id: 'sukkur_rohri',
      nameEn: 'Rohri Canal Aqueduct & Railway Clearance',
      nameUr: 'روہڑی کینال ایکویڈکٹ اوور ہیڈ پل',
      roadSegment: 'N-5 Sindh Freight Corridor, Sukkur',
      location: LatLng(27.6744, 68.8931),
      clearanceHeightFt: 15.5,
      clearanceHeightM: 4.72,
      maxWeightTons: 50.0,
      warningEn: '15.5 ft clearance under canal siphon. Caution for double-stacked loads.',
      warningUr: 'کینال سائیفن کے نیچے ۱۵.۵ فٹ گنجائش۔ زائد اونچے بوجھ کے لیے احتیاط کریں۔',
      isMotorway: false,
    ),
    PakistanBridgeHazard(
      id: 'hyderabad_kotri',
      nameEn: 'Kotri Barrage Approach Overhead Siphon',
      nameUr: 'کوٹری بیراج اپروچ اوور ہیڈ پل',
      roadSegment: 'N-5 National Highway, Hyderabad',
      location: LatLng(25.3670, 68.3090),
      clearanceHeightFt: 14.5,
      clearanceHeightM: 4.42,
      maxWeightTons: 40.0,
      warningEn: 'Narrow arch with 14.5 ft vertical clearance. Oversize trailers divert to M-9.',
      warningUr: 'محرابی تنگی کے ساتھ ۱۴.۵ فٹ گنجائش۔ بڑے ٹریلر موٹروے M-9 پر جائیں۔',
      isMotorway: false,
    ),
    PakistanBridgeHazard(
      id: 'm2_kallar_kahar',
      nameEn: 'Salt Range Kallar Kahar Descent Viaduct',
      nameUr: 'سالٹ رینج کلر کہار موٹروے وایاڈکٹ',
      roadSegment: 'M-2 Motorway, Km 220-235',
      location: LatLng(32.7812, 72.7092),
      clearanceHeightFt: 17.5,
      clearanceHeightM: 5.33,
      maxWeightTons: 60.0,
      warningEn: 'Full 17.5 ft container clearance. 7% steep gradient ahead — test truck air brakes.',
      warningUr: '۱۷.۵ فٹ کلیئرنس۔ ۷ فیصد شدید ڈھلوان — ٹرک کے پریشر بریک لازمی چیک کریں۔',
      isMotorway: true,
    ),
    PakistanBridgeHazard(
      id: 'm5_multan_interchange',
      nameEn: 'M-5 Multan South Flyover & Interchange',
      nameUr: 'موٹروے M-5 ملتان ساؤتھ فلائی اوور',
      roadSegment: 'M-5 Sukkur-Multan Motorway',
      location: LatLng(29.8912, 71.3210),
      clearanceHeightFt: 17.2,
      clearanceHeightM: 5.24,
      maxWeightTons: 65.0,
      warningEn: 'Safe 17.2 ft clearance for standard and high-cube trailers.',
      warningUr: '۱۷.۲ فٹ محفوظ اونچائی۔ تمام اقسام کے ٹرالوں اور کنٹینرز کے لیے مکمل محفوظ۔',
      isMotorway: true,
    ),
    PakistanBridgeHazard(
      id: 'm3_abdul_hakeem',
      nameEn: 'M-3 Abdul Hakeem Rail Crossing Underpass',
      nameUr: 'موٹروے M-3 عبدالحکیم ریلوے انڈرپاس',
      roadSegment: 'M-3 Lahore-Abdul Hakeem Motorway',
      location: LatLng(30.5512, 72.1245),
      clearanceHeightFt: 17.0,
      clearanceHeightM: 5.18,
      maxWeightTons: 60.0,
      warningEn: 'Full 17.0 ft vertical clearance on Motorway standard.',
      warningUr: '۱۷ فٹ محفوظ موٹروے کلیئرنس۔',
      isMotorway: true,
    ),
  ];

  /// Finds all bridges along the route corridor that lie within [bufferKm] of the polyline
  static List<BridgeClearanceAlert> findCorridorBridges({
    required List<LatLng> routePoints,
    required double truckHeightFt,
    double bufferKm = 25.0,
    bool isMotorway = true,
  }) {
    if (routePoints.isEmpty) return [];

    final alerts = <BridgeClearanceAlert>[];

    for (final bridge in all) {
      // Filter motorway vs non-motorway
      if (isMotorway && !bridge.isMotorway && bridge.roadSegment.contains('N-5') && bridge.id != 'sahiwal_rail') {
        // When motorway is selected, N-5 local bridges are avoided
        continue;
      }
      if (!isMotorway && bridge.isMotorway) {
        continue;
      }

      double minDistanceKm = double.infinity;
      for (final pt in routePoints) {
        final d = _haversineDistanceKm(pt, bridge.location);
        if (d < minDistanceKm) {
          minDistanceKm = d;
        }
      }

      if (minDistanceKm <= bufferKm) {
        alerts.add(
          bridge.toAlert(
            truckHeightFt: truckHeightFt,
            distanceAheadKm: minDistanceKm,
          ),
        );
      }
    }

    return alerts;
  }

  static double _haversineDistanceKm(LatLng p1, LatLng p2) {
    const r = 6371.0;
    final dLat = (p2.latitude - p1.latitude) * (math.pi / 180.0);
    final dLng = (p2.longitude - p1.longitude) * (math.pi / 180.0);
    final lat1 = p1.latitude * (math.pi / 180.0);
    final lat2 = p2.latitude * (math.pi / 180.0);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.sin(dLng / 2) * math.sin(dLng / 2) * math.cos(lat1) * math.cos(lat2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }
}

class CityTimingRule {
  final String id;
  final String cityName;
  final String vehicleCategory; // 'heavy', 'container', 'all'
  final String entryFrom; // '23:00'
  final String entryUntil; // '05:00'
  final String notes;
  final double confidence;

  const CityTimingRule({
    required this.id,
    required this.cityName,
    required this.vehicleCategory,
    required this.entryFrom,
    required this.entryUntil,
    required this.notes,
    required this.confidence,
  });

  /// Check whether entry is currently allowed based on current time (HH:mm)
  bool isEntryAllowedNow([DateTime? nowTime]) {
    final now = nowTime ?? DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;

    final fromParts = entryFrom.split(':').map(int.parse).toList();
    final untilParts = entryUntil.split(':').map(int.parse).toList();

    final fromMinutes = fromParts[0] * 60 + fromParts[1];
    final untilMinutes = untilParts[0] * 60 + untilParts[1];

    if (fromMinutes <= untilMinutes) {
      return currentMinutes >= fromMinutes && currentMinutes <= untilMinutes;
    } else {
      // Overnight window e.g. 23:00 to 05:00
      return currentMinutes >= fromMinutes || currentMinutes <= untilMinutes;
    }
  }

  /// Calculates hours/minutes until next entry window
  String getNextWindowCountdown([DateTime? nowTime]) {
    if (isEntryAllowedNow(nowTime)) {
      return 'Entry OPEN until $entryUntil';
    }
    return 'Window opens at $entryFrom';
  }
}

class RoadReport {
  final String id;
  final String reporterId;
  final String reportType; // 'kacha', 'broken', 'flooded', 'landslide', 'protest', 'accident'
  final String? description;
  final String? photoUrl;
  final double confidence;
  final int upvotes;
  final int downvotes;
  final DateTime createdAt;
  final DateTime? expiresAt;

  const RoadReport({
    required this.id,
    required this.reporterId,
    required this.reportType,
    this.description,
    this.photoUrl,
    this.confidence = 0.5,
    this.upvotes = 0,
    this.downvotes = 0,
    required this.createdAt,
    this.expiresAt,
  });

  factory RoadReport.fromJson(Map<String, dynamic> json) {
    return RoadReport(
      id: json['id'] as String,
      reporterId: json['reporter_id'] as String,
      reportType: json['report_type'] as String,
      description: json['description'] as String?,
      photoUrl: json['photo_url'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.5,
      upvotes: json['upvotes'] as int? ?? 0,
      downvotes: json['downvotes'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
    );
  }
}
