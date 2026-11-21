class UserProfile {
  final String id;
  final String role; // 'driver', 'owner', 'admin'
  final String fullName;
  final String phone;
  final String? cnicNumber;
  final bool cnicVerified;
  final String? nadraTransactionId;
  final String? photoUrl;
  final double rating;
  final int totalRatings;

  const UserProfile({
    required this.id,
    required this.role,
    required this.fullName,
    required this.phone,
    this.cnicNumber,
    this.cnicVerified = false,
    this.nadraTransactionId,
    this.photoUrl,
    this.rating = 0.0,
    this.totalRatings = 0,
  });

  bool get isDriver => role == 'driver';
  bool get isOwner => role == 'owner';
  bool get isAdmin => role == 'admin';

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      role: json['role'] as String? ?? 'driver',
      fullName: json['full_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      cnicNumber: json['cnic_number'] as String?,
      cnicVerified: json['cnic_verified'] as bool? ?? false,
      nadraTransactionId: json['nadra_transaction_id'] as String?,
      photoUrl: json['photo_url'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalRatings: json['total_ratings'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'full_name': fullName,
      'phone': phone,
      'cnic_number': cnicNumber,
      'cnic_verified': cnicVerified,
      'nadra_transaction_id': nadraTransactionId,
      'photo_url': photoUrl,
      'rating': rating,
      'total_ratings': totalRatings,
    };
  }
}

class DriverDetails {
  final String profileId;
  final List<String> licenseType;
  final int experienceYears;
  final List<String> vehicleTypes;
  final bool isAvailable;
  final String? currentTripId;
  final double? maxWeightTons;
  final bool hazmatCertified;

  const DriverDetails({
    required this.profileId,
    required this.licenseType,
    required this.experienceYears,
    required this.vehicleTypes,
    this.isAvailable = true,
    this.currentTripId,
    this.maxWeightTons,
    this.hazmatCertified = false,
  });

  factory DriverDetails.fromJson(Map<String, dynamic> json) {
    return DriverDetails(
      profileId: json['profile_id'] as String,
      licenseType: (json['license_type'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      experienceYears: json['experience_years'] as int? ?? 0,
      vehicleTypes: (json['vehicle_types'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      isAvailable: json['is_available'] as bool? ?? true,
      currentTripId: json['current_trip_id'] as String?,
      maxWeightTons: (json['max_weight_tons'] as num?)?.toDouble(),
      hazmatCertified: json['hazmat_certified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'profile_id': profileId,
      'license_type': licenseType,
      'experience_years': experienceYears,
      'vehicle_types': vehicleTypes,
      'is_available': isAvailable,
      'current_trip_id': currentTripId,
      'max_weight_tons': maxWeightTons,
      'hazmat_certified': hazmatCertified,
    };
  }
}
