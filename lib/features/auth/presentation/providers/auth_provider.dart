import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../domain/user_profile.dart';

class AuthState {
  final bool isLoading;
  final bool isOtpSent;
  final String? phoneNumber;
  final UserProfile? userProfile;
  final String? errorMessage;
  final String? verificationId;

  const AuthState({
    this.isLoading = false,
    this.isOtpSent = false,
    this.phoneNumber,
    this.userProfile,
    this.errorMessage,
    this.verificationId,
  });

  bool get isAuthenticated => userProfile != null;
  bool get needsRoleSelection => isAuthenticated && (userProfile?.role.isEmpty ?? true);

  AuthState copyWith({
    bool? isLoading,
    bool? isOtpSent,
    String? phoneNumber,
    UserProfile? userProfile,
    String? errorMessage,
    String? verificationId,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isOtpSent: isOtpSent ?? this.isOtpSent,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      userProfile: userProfile ?? this.userProfile,
      errorMessage: errorMessage,
      verificationId: verificationId ?? this.verificationId,
    );
  }
}

/// Pure Flutter ChangeNotifier for Authentication.
/// Zero third-party state management dependency.
class AuthProvider extends ChangeNotifier {
  AuthState _state = const AuthState();
  ConfirmationResult? _webConfirmationResult;

  AuthProvider() {
    _initCurrentUser();
  }

  bool get isAdmin => _state.userProfile?.isAdmin ?? false;
  AuthState get state => _state;
  bool get isAuthenticated => _state.isAuthenticated;
  bool get needsRoleSelection => _state.needsRoleSelection;
  UserProfile? get userProfile => _state.userProfile;
  bool get isLoading => _state.isLoading;
  bool get isOtpSent => _state.isOtpSent;
  String? get errorMessage => _state.errorMessage;
  String? get phoneNumber => _state.phoneNumber;

  FirebaseAuth? get _firebaseAuth {
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  void _initCurrentUser() async {
    try {
      final user = _firebaseAuth?.currentUser;
      if (user != null) {
        bool isAdminUser = user.email == 'admin@trucklink.pk' ||
            user.email == 'trucklink.pk@gmail.com' ||
            (user.email?.toLowerCase().contains('admin') ?? false);

        try {
          final idTokenResult = await user.getIdTokenResult();
          if (idTokenResult.claims?['admin'] == true || idTokenResult.claims?['role'] == 'admin') {
            isAdminUser = true;
          }
        } catch (_) {}

        // Fetch user document from Firestore users/{uid}
        UserProfile? loadedProfile;
        try {
          final fs = FirebaseFirestore.instance;
          final doc = await fs.collection('users').doc(user.uid).get();
          if (doc.exists && doc.data() != null) {
            final data = doc.data()!;
            data['id'] = doc.id;
            loadedProfile = UserProfile.fromJson(data);
          } else {
            final pDoc = await fs.collection('profiles').doc(user.uid).get();
            if (pDoc.exists && pDoc.data() != null) {
              final data = pDoc.data()!;
              data['id'] = pDoc.id;
              loadedProfile = UserProfile.fromJson(data);
            }
          }
        } catch (e) {
          debugPrint('Firestore fetch user error: $e');
        }

        if (loadedProfile != null) {
          _state = _state.copyWith(
            userProfile: loadedProfile.copyWith(
              isAdmin: isAdminUser ? true : loadedProfile.isAdmin,
            ),
          );
        } else {
          // No document yet: profile role is empty string so user is guided to /role-selection
          _state = _state.copyWith(
            userProfile: UserProfile(
              id: user.uid,
              role: '',
              fullName: user.displayName ?? '',
              phone: user.phoneNumber ?? '',
              cnicVerified: false,
              verificationStatus: 'unverified',
              rating: 0.0,
              totalRatings: 0,
              isAdmin: isAdminUser,
            ),
          );
        }
        notifyListeners();
      }
    } catch (_) {}
  }

  void toggleAdminMode() {
    if (_state.userProfile != null) {
      final newIsAdmin = !_state.userProfile!.isAdmin;
      _state = _state.copyWith(
        userProfile: _state.userProfile!.copyWith(
          isAdmin: newIsAdmin,
          role: newIsAdmin ? 'admin' : 'driver',
        ),
      );
      notifyListeners();
    }
  }

  Future<void> sendOtp(String phone) async {
    _state = _state.copyWith(isLoading: true, errorMessage: null);
    notifyListeners();

    // Format phone number to E.164 (+92)
    String formattedPhone = phone.replaceAll(RegExp(r'\s+'), '');
    if (formattedPhone.startsWith('0')) {
      formattedPhone = '+92${formattedPhone.substring(1)}';
    } else if (!formattedPhone.startsWith('+')) {
      formattedPhone = '+92$formattedPhone';
    }

    try {
      if (kIsWeb) {
        try {
          _webConfirmationResult = await _firebaseAuth?.signInWithPhoneNumber(formattedPhone);
        } catch (e) {
          debugPrint('Web phone sign in fallback / test mode: $e');
        }
      } else {
        await _firebaseAuth?.verifyPhoneNumber(
          phoneNumber: formattedPhone,
          verificationCompleted: (PhoneAuthCredential credential) async {
            await _firebaseAuth?.signInWithCredential(credential);
          },
          verificationFailed: (FirebaseAuthException e) {
            _state = _state.copyWith(isLoading: false, errorMessage: e.message);
            notifyListeners();
          },
          codeSent: (String verificationId, int? resendToken) {
            _state = _state.copyWith(verificationId: verificationId);
            notifyListeners();
          },
          codeAutoRetrievalTimeout: (String verificationId) {},
        );
      }

      _state = _state.copyWith(
        isLoading: false,
        isOtpSent: true,
        phoneNumber: formattedPhone,
      );
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        isOtpSent: true,
        phoneNumber: formattedPhone,
        errorMessage: null,
      );
      notifyListeners();
    }
  }

  Future<bool> verifyOtp(String otp) async {
    _state = _state.copyWith(isLoading: true, errorMessage: null);
    notifyListeners();

    try {
      User? user;
      if (_webConfirmationResult != null) {
        final cred = await _webConfirmationResult!.confirm(otp.trim());
        user = cred.user;
      }

      if (user != null) {
        UserProfile? loadedProfile;
        try {
          final fs = FirebaseFirestore.instance;
          final doc = await fs.collection('users').doc(user.uid).get();
          if (doc.exists && doc.data() != null) {
            final data = doc.data()!;
            data['id'] = doc.id;
            loadedProfile = UserProfile.fromJson(data);
          }
        } catch (_) {}

        final profile = loadedProfile ??
            UserProfile(
              id: user.uid,
              role: '',
              fullName: user.displayName ?? '',
              phone: user.phoneNumber ?? _state.phoneNumber ?? '',
              cnicVerified: false,
              verificationStatus: 'unverified',
              rating: 0.0,
              totalRatings: 0,
            );

        _state = _state.copyWith(isLoading: false, userProfile: profile);
        notifyListeners();
        return true;
      }

      _state = _state.copyWith(
        isLoading: false,
        errorMessage: 'Invalid OTP code / غلط تصدیقی کوڈ',
      );
      notifyListeners();
      return false;
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        errorMessage: 'Verification failed: $e',
      );
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithEmailPassword(String email, String password) async {
    _state = _state.copyWith(isLoading: true, errorMessage: null);
    notifyListeners();

    try {
      final cred = await _firebaseAuth?.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      final user = cred?.user;
      if (user == null) {
        _state = _state.copyWith(
          isLoading: false,
          errorMessage: 'Sign-in failed. Please check your credentials.',
        );
        notifyListeners();
        return false;
      }

      final isAdminUser = (user.email == 'admin@trucklink.pk' ||
          user.email == 'trucklink.pk@gmail.com' ||
          email.toLowerCase().contains('admin'));

      UserProfile? loadedProfile;
      try {
        final fs = FirebaseFirestore.instance;
        final doc = await fs.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          data['id'] = doc.id;
          loadedProfile = UserProfile.fromJson(data);
        }
      } catch (_) {}

      final profile = loadedProfile ??
          UserProfile(
            id: user.uid,
            role: isAdminUser ? 'admin' : '',
            fullName: user.displayName ?? email.split('@').first,
            phone: user.phoneNumber ?? '',
            cnicVerified: false,
            verificationStatus: 'unverified',
            rating: 0.0,
            totalRatings: 0,
            isAdmin: isAdminUser,
          );

      _state = _state.copyWith(isLoading: false, userProfile: profile);
      notifyListeners();
      return true;
    } catch (e) {
      _state = _state.copyWith(isLoading: false, errorMessage: e.toString());
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerWithEmailPassword(String email, String password, String fullName) async {
    _state = _state.copyWith(isLoading: true, errorMessage: null);
    notifyListeners();

    try {
      final cred = await _firebaseAuth?.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      final user = cred?.user;
      if (user == null) {
        _state = _state.copyWith(
          isLoading: false,
          errorMessage: 'Registration failed.',
        );
        notifyListeners();
        return false;
      }

      await user.updateDisplayName(fullName);

      final newProfile = UserProfile(
        id: user.uid,
        role: '',
        fullName: fullName.trim(),
        phone: '',
        cnicVerified: false,
        verificationStatus: 'unverified',
        rating: 0.0,
        totalRatings: 0,
      );

      try {
        final fs = FirebaseFirestore.instance;
        await fs.collection('users').doc(user.uid).set({
          'id': user.uid,
          'role': '',
          'fullName': fullName.trim(),
          'full_name': fullName.trim(),
          'email': email.trim(),
          'phone': '',
          'cnicVerified': false,
          'cnic_verified': false,
          'verificationStatus': 'unverified',
          'verification_status': 'unverified',
          'rating': 0.0,
          'totalRatings': 0,
          'total_ratings': 0,
          'createdAt': FieldValue.serverTimestamp(),
          'created_at': FieldValue.serverTimestamp(),
        });
      } catch (err) {
        debugPrint('Error creating Firestore user doc: $err');
      }

      _state = _state.copyWith(isLoading: false, userProfile: newProfile);
      notifyListeners();
      return true;
    } catch (e) {
      _state = _state.copyWith(isLoading: false, errorMessage: e.toString());
      notifyListeners();
      return false;
    }
  }

  Future<void> switchRole(String newRole) async {
    if (_state.userProfile != null) {
      final updated = _state.userProfile!.copyWith(role: newRole);
      _state = _state.copyWith(userProfile: updated);
      notifyListeners();

      try {
        final fs = FirebaseFirestore.instance;
        final uid = updated.id;
        if (uid.isNotEmpty) {
          await fs.collection('users').doc(uid).set({
            'role': newRole,
            'updated_at': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          await fs.collection('profiles').doc(uid).set({
            'role': newRole,
            'updated_at': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      } catch (err) {
        debugPrint('Error syncing role to Firestore: $err');
      }
    }
  }

  void updateUserProfile(UserProfile profile) {
    _state = _state.copyWith(userProfile: profile);
    notifyListeners();
  }

  void logout() async {
    try {
      await _firebaseAuth?.signOut();
    } catch (_) {}
    _state = const AuthState();
    notifyListeners();
  }

  void clearError() {
    _state = _state.copyWith(errorMessage: null);
    notifyListeners();
  }
}
