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
  final String status; // 'open', 'assigned', 'in_transit', 'delivered', 'cancelled'
  final DateTime createdAt;

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
  });

  factory LoadModel.fromJson(Map<String, dynamic> json) {
    return LoadModel(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      originCity: json['origin_city'] as String,
      destinationCity: json['destination_city'] as String,
      vehicleTypeRequired: json['vehicle_type_required'] as String,
      weightTons: (json['weight_tons'] as num).toDouble(),
      lengthFt: (json['length_ft'] as num?)?.toDouble(),
      widthFt: (json['width_ft'] as num?)?.toDouble(),
      heightFt: (json['height_ft'] as num?)?.toDouble(),
      goodsType: json['goods_type'] as String?,
      offeredRatePkr: (json['offered_rate_pkr'] as num).toDouble(),
      rateType: json['rate_type'] as String? ?? 'fixed',
      pickupWindowStart: json['pickup_window_start'] != null
          ? DateTime.tryParse(json['pickup_window_start'] as String)
          : null,
      pickupWindowEnd: json['pickup_window_end'] != null
          ? DateTime.tryParse(json['pickup_window_end'] as String)
          : null,
      status: json['status'] as String? ?? 'open',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
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
    };
  }
}
