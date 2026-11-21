class UserProfile {
  final String id;
  final String role; // 'driver', 'owner', 'admin'
  final String fullName;
  final String phone;
  final String? cnicNumber;
  final bool cnicVerified;
  final String verificationStatus; // 'unverified', 'pending', 'verified'
  final String? nadraTransactionId;
  final String? photoUrl;
  final String? cnicFrontUrl;
  final String? licenseUrl;
  final String? registrationUrl;
  final double rating;
  final int totalRatings;

  const UserProfile({
    required this.id,
    required this.role,
    required this.fullName,
    required this.phone,
    this.cnicNumber,
    this.cnicVerified = false,
    this.verificationStatus = 'unverified',
    this.nadraTransactionId,
    this.photoUrl,
    this.cnicFrontUrl,
    this.licenseUrl,
    this.registrationUrl,
    this.rating = 0.0,
    this.totalRatings = 0,
  });

  bool get isDriver => role == 'driver';
  bool get isOwner => role == 'owner';
  bool get isAdmin => role == 'admin';

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final verified = json['cnic_verified'] as bool? ?? false;
    final status = json['verification_status'] as String? ?? (verified ? 'verified' : 'unverified');
    return UserProfile(
      id: json['id'] as String? ?? '',
      role: json['role'] as String? ?? 'driver',
      fullName: json['full_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      cnicNumber: json['cnic_number'] as String?,
      cnicVerified: verified,
      verificationStatus: status,
      nadraTransactionId: json['nadra_transaction_id'] as String?,
      photoUrl: json['photo_url'] as String?,
      cnicFrontUrl: json['cnic_front_url'] as String?,
      licenseUrl: json['license_url'] as String?,
      registrationUrl: json['registration_url'] as String?,
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
      'verification_status': verificationStatus,
      'nadra_transaction_id': nadraTransactionId,
      'photo_url': photoUrl,
      'cnic_front_url': cnicFrontUrl,
      'license_url': licenseUrl,
      'registration_url': registrationUrl,
      'rating': rating,
      'total_ratings': totalRatings,
    };
  }

  UserProfile copyWith({
    String? id,
    String? role,
    String? fullName,
    String? phone,
    String? cnicNumber,
    bool? cnicVerified,
    String? verificationStatus,
    String? nadraTransactionId,
    String? photoUrl,
    String? cnicFrontUrl,
    String? licenseUrl,
    String? registrationUrl,
    double? rating,
    int? totalRatings,
  }) {
    return UserProfile(
      id: id ?? this.id,
      role: role ?? this.role,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      cnicNumber: cnicNumber ?? this.cnicNumber,
      cnicVerified: cnicVerified ?? this.cnicVerified,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      nadraTransactionId: nadraTransactionId ?? this.nadraTransactionId,
      photoUrl: photoUrl ?? this.photoUrl,
      cnicFrontUrl: cnicFrontUrl ?? this.cnicFrontUrl,
      licenseUrl: licenseUrl ?? this.licenseUrl,
      registrationUrl: registrationUrl ?? this.registrationUrl,
      rating: rating ?? this.rating,
      totalRatings: totalRatings ?? this.totalRatings,
    );
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
