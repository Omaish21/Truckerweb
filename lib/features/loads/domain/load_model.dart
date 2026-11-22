class LoadModel {
  final String id;
  final String ownerId;
  final String originCity;
  final String destinationCity;
  final String vehicleTypeRequired;
  final double weightTons;
  final double? lengthFt;
  final double? widthFt;
  final double? heightFt;
  final String? goodsType;
  final double offeredRatePkr;
  final String rateType; // 'fixed', 'per_ton', 'negotiable'
  final DateTime? pickupWindowStart;
  final DateTime? pickupWindowEnd;
  final String status; // 'open', 'bidding', 'assigned', 'in_transit', 'delivered', 'cancelled'
  final DateTime createdAt;
  final String? assignedDriverId;
  final String? contactPhone;
  final int bidsCount;

  const LoadModel({
    required this.id,
    required this.ownerId,
    required this.originCity,
    required this.destinationCity,
    required this.vehicleTypeRequired,
    required this.weightTons,
    this.lengthFt,
    this.widthFt,
    this.heightFt,
    this.goodsType,
    required this.offeredRatePkr,
    this.rateType = 'fixed',
    this.pickupWindowStart,
    this.pickupWindowEnd,
    this.status = 'open',
    required this.createdAt,
    this.assignedDriverId,
    this.contactPhone,
    this.bidsCount = 0,
  });

  factory LoadModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is DateTime) return val;
      if (val.runtimeType.toString() == 'Timestamp' || val.toString().contains('Timestamp')) {
        try {
          // Dynamic invocation for cloud_firestore Timestamp
          final dynamic ts = val;
          return ts.toDate() as DateTime;
        } catch (_) {}
      }
      return DateTime.tryParse(val.toString()) ?? DateTime.now();
    }

    DateTime? parseNullableDate(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val;
      if (val.runtimeType.toString() == 'Timestamp' || val.toString().contains('Timestamp')) {
        try {
          final dynamic ts = val;
          return ts.toDate() as DateTime;
        } catch (_) {}
      }
      return DateTime.tryParse(val.toString());
    }

    return LoadModel(
      id: json['id'] as String? ?? '',
      ownerId: json['owner_id'] as String? ?? '',
      originCity: json['origin_city'] as String? ?? '',
      destinationCity: json['destination_city'] as String? ?? '',
      vehicleTypeRequired: json['vehicle_type_required'] as String? ?? '22_wheeler',
      weightTons: (json['weight_tons'] as num?)?.toDouble() ?? 10.0,
      lengthFt: (json['length_ft'] as num?)?.toDouble(),
      widthFt: (json['width_ft'] as num?)?.toDouble(),
      heightFt: (json['height_ft'] as num?)?.toDouble(),
      goodsType: json['goods_type'] as String?,
      offeredRatePkr: (json['offered_rate_pkr'] as num?)?.toDouble() ?? 50000.0,
      rateType: json['rate_type'] as String? ?? 'fixed',
      pickupWindowStart: parseNullableDate(json['pickup_window_start']),
      pickupWindowEnd: parseNullableDate(json['pickup_window_end']),
      status: json['status'] as String? ?? 'open',
      createdAt: parseDate(json['created_at']),
      assignedDriverId: json['assigned_driver_id'] as String?,
      contactPhone: json['contact_phone'] as String? ?? '+923001234567',
      bidsCount: (json['bids_count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'origin_city': originCity,
      'destination_city': destinationCity,
      'vehicle_type_required': vehicleTypeRequired,
      'weight_tons': weightTons,
      'length_ft': lengthFt,
      'width_ft': widthFt,
      'height_ft': heightFt,
      'goods_type': goodsType,
      'offered_rate_pkr': offeredRatePkr,
      'rate_type': rateType,
      'pickup_window_start': pickupWindowStart?.toIso8601String(),
      'pickup_window_end': pickupWindowEnd?.toIso8601String(),
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'assigned_driver_id': assignedDriverId,
      'contact_phone': contactPhone,
      'bids_count': bidsCount,
    };
  }

  LoadModel copyWith({
    String? id,
    String? ownerId,
    String? originCity,
    String? destinationCity,
    String? vehicleTypeRequired,
    double? weightTons,
    double? lengthFt,
    double? widthFt,
    double? heightFt,
    String? goodsType,
    double? offeredRatePkr,
    String? rateType,
    DateTime? pickupWindowStart,
    DateTime? pickupWindowEnd,
    String? status,
    DateTime? createdAt,
    String? assignedDriverId,
    String? contactPhone,
    int? bidsCount,
  }) {
    return LoadModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      originCity: originCity ?? this.originCity,
      destinationCity: destinationCity ?? this.destinationCity,
      vehicleTypeRequired: vehicleTypeRequired ?? this.vehicleTypeRequired,
      weightTons: weightTons ?? this.weightTons,
      lengthFt: lengthFt ?? this.lengthFt,
      widthFt: widthFt ?? this.widthFt,
      heightFt: heightFt ?? this.heightFt,
      goodsType: goodsType ?? this.goodsType,
      offeredRatePkr: offeredRatePkr ?? this.offeredRatePkr,
      rateType: rateType ?? this.rateType,
      pickupWindowStart: pickupWindowStart ?? this.pickupWindowStart,
      pickupWindowEnd: pickupWindowEnd ?? this.pickupWindowEnd,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      assignedDriverId: assignedDriverId ?? this.assignedDriverId,
      contactPhone: contactPhone ?? this.contactPhone,
      bidsCount: bidsCount ?? this.bidsCount,
    );
  }
}
