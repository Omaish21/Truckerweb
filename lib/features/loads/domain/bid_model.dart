class BidModel {
  final String id;
  final String loadId;
  final String driverId;
  final String driverName;
  final String driverPhone;
  final double driverRating;
  final bool isVerifiedDriver;
  final double proposedRatePkr;
  final int estimatedHours;
  final String? notes;
  final String status; // 'pending', 'accepted', 'rejected'
  final DateTime createdAt;

  const BidModel({
    required this.id,
    required this.loadId,
    required this.driverId,
    required this.driverName,
    required this.driverPhone,
    this.driverRating = 5.0,
    this.isVerifiedDriver = false,
    required this.proposedRatePkr,
    required this.estimatedHours,
    this.notes,
    this.status = 'pending',
    required this.createdAt,
  });

  factory BidModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is DateTime) return val;
      if (val.runtimeType.toString() == 'Timestamp' || val.toString().contains('Timestamp')) {
        try {
          final dynamic ts = val;
          return ts.toDate() as DateTime;
        } catch (_) {}
      }
      return DateTime.tryParse(val.toString()) ?? DateTime.now();
    }

    return BidModel(
      id: json['id'] as String? ?? '',
      loadId: json['load_id'] as String? ?? '',
      driverId: json['driver_id'] as String? ?? '',
      driverName: json['driver_name'] as String? ?? 'Pakistani Driver',
      driverPhone: json['driver_phone'] as String? ?? '+923001234567',
      driverRating: (json['driver_rating'] as num?)?.toDouble() ?? 5.0,
      isVerifiedDriver: json['is_verified_driver'] as bool? ?? false,
      proposedRatePkr: (json['proposed_rate_pkr'] as num?)?.toDouble() ?? 0.0,
      estimatedHours: (json['estimated_hours'] as num?)?.toInt() ?? 24,
      notes: json['notes'] as String?,
      status: json['status'] as String? ?? 'pending',
      createdAt: parseDate(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'load_id': loadId,
      'driver_id': driverId,
      'driver_name': driverName,
      'driver_phone': driverPhone,
      'driver_rating': driverRating,
      'is_verified_driver': isVerifiedDriver,
      'proposed_rate_pkr': proposedRatePkr,
      'estimated_hours': estimatedHours,
      'notes': notes,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
