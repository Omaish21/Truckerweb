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
  final double clearanceHeightFt;
  final double truckHeightFt;
  final String roadSegment;
  final double distanceAheadKm;
  final bool isCritical;

  const BridgeClearanceAlert({
    required this.bridgeName,
    required this.clearanceHeightFt,
    required this.truckHeightFt,
    required this.roadSegment,
    required this.distanceAheadKm,
    required this.isCritical,
  });

  double get differenceFt => truckHeightFt - clearanceHeightFt;
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
