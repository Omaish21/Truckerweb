import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/user_profile.dart';

class AuthState {
  final bool isLoading;
  final bool isOtpSent;
  final String? phoneNumber;
  final UserProfile? userProfile;
  final String? errorMessage;

  const AuthState({
    this.isLoading = false,
    this.isOtpSent = false,
    this.phoneNumber,
    this.userProfile,
    this.errorMessage,
  });

  bool get isAuthenticated => userProfile != null;
  bool get needsRoleSelection => isAuthenticated && (userProfile?.role.isEmpty ?? true);

  AuthState copyWith({
    bool? isLoading,
    bool? isOtpSent,
    String? phoneNumber,
    UserProfile? userProfile,
    String? errorMessage,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isOtpSent: isOtpSent ?? this.isOtpSent,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      userProfile: userProfile ?? this.userProfile,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  Future<void> sendOtp(String phone) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    await Future.delayed(const Duration(milliseconds: 600)); // simulated API delay
    state = state.copyWith(
      isLoading: false,
      isOtpSent: true,
      phoneNumber: phone,
    );
  }

  Future<bool> verifyOtp(String otp) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    await Future.delayed(const Duration(milliseconds: 600));

    if (otp == '123456' || otp.length == 6) {
      // Default initial mock profile (can be driver or owner)
      final profile = UserProfile(
        id: 'usr-101',
        role: 'driver',
        fullName: 'Muhammad Asif',
        phone: state.phoneNumber ?? '+923001234567',
        cnicNumber: '35202-1234567-1',
        cnicVerified: true,
        rating: 4.8,
        totalRatings: 34,
      );
      state = state.copyWith(
        isLoading: false,
        userProfile: profile,
      );
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Invalid OTP code / غلط تصدیقی کوڈ',
      );
      return false;
    }
  }

  void switchRole(String newRole) {
    if (state.userProfile != null) {
      final updated = UserProfile(
        id: state.userProfile!.id,
        role: newRole,
        fullName: state.userProfile!.fullName,
        phone: state.userProfile!.phone,
        cnicNumber: state.userProfile!.cnicNumber,
        cnicVerified: state.userProfile!.cnicVerified,
        rating: state.userProfile!.rating,
        totalRatings: state.userProfile!.totalRatings,
      );
      state = state.copyWith(userProfile: updated);
    }
  }

  void logout() {
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
