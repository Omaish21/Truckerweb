import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trucklink_pk/app.dart';
import 'package:trucklink_pk/core/constants/vehicle_types.dart';
import 'package:trucklink_pk/core/localization/locale_provider.dart';
import 'package:trucklink_pk/core/providers/app_scope.dart';
import 'package:trucklink_pk/core/services/geocoding_service.dart';
import 'package:trucklink_pk/core/utils/formatters.dart';
import 'package:trucklink_pk/core/utils/urdu_text.dart';
import 'package:trucklink_pk/core/utils/validators.dart';
import 'package:trucklink_pk/core/widgets/captcha_verification_widget.dart';
import 'package:trucklink_pk/features/auth/presentation/providers/auth_provider.dart';
import 'package:trucklink_pk/core/services/firebase_service.dart';
import 'package:trucklink_pk/features/loads/domain/load_model.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('TruckLink PK Unit & Smoke Tests', () {
    test('Pakistani CNIC Validator correctly validates 13-digit numbers', () {
      expect(AppValidators.validateCnic('35202-1234567-1'), isNull);
      expect(AppValidators.validateCnic('3520212345671'), isNull);
      expect(AppValidators.validateCnic('123'), isNotNull);
      expect(AppValidators.validateCnic(''), isNotNull);
      expect(AppValidators.formatCnic('3520212345671'), '35202-1234567-1');
    });

    test('Pakistani Phone Validator formats and validates mobile numbers', () {
      expect(AppValidators.validatePhone('03001234567'), isNull);
      expect(AppValidators.validatePhone('+923001234567'), isNull);
      expect(AppValidators.validatePhone('300 1234567'), isNull);
      expect(AppValidators.validatePhone('0211234567'), isNotNull);

      expect(AppValidators.normalizePhone('0300 1234567'), '+923001234567');
      expect(AppValidators.normalizePhone('300 1234567'), '+923001234567');
      expect(AppValidators.normalizePhone('+923001234567'), '+923001234567');
    });

    testWidgets('CaptchaVerificationWidget verifies on user tap', (WidgetTester tester) async {
      bool isVerified = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CaptchaVerificationWidget(
              onVerified: (v) => isVerified = v,
            ),
          ),
        ),
      );

      expect(find.byType(CaptchaVerificationWidget), findsOneWidget);
      expect(find.textContaining("I'm a human"), findsOneWidget);

      await tester.tap(find.textContaining("I'm a human"));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));

      expect(isVerified, isTrue);
      expect(find.textContaining('Human Verification Passed'), findsOneWidget);
    });

    test('Currency & Weight formatters produce proper output', () {
      expect(AppFormatters.formatPkr(245000), 'Rs. 2,45,000');
      expect(AppFormatters.formatWeight(35.0), '35 Tons / ٹن');
    });

    test('Urdu text numeral conversion', () {
      expect(UrduTextUtils.toUrduNumerals('03001234567'), '۰۳۰۰۱۲۳۴۵۶۷');
      expect(UrduTextUtils.toUrduNumerals('22 Wheeler'), '۲۲ Wheeler');
    });

    test('Vehicle types registry includes essential Pakistani freight types', () {
      final types = VehicleType.all.map((v) => v.id).toList();
      expect(types, containsAll(['mazda', '10_wheeler', '22_wheeler', 'container', 'tanker']));
    });

    test('LoadModel fromJson creates valid instance', () {
      final json = {
        'id': 'load-1',
        'owner_id': 'own-1',
        'origin_city': 'Lahore',
        'destination_city': 'Karachi',
        'vehicle_type_required': '22_wheeler',
        'weight_tons': 35.0,
        'offered_rate_pkr': 245000.0,
        'status': 'open',
        'created_at': DateTime.now().toIso8601String(),
      };
      final model = LoadModel.fromJson(json);
      expect(model.id, 'load-1');
      expect(model.originCity, 'Lahore');
      expect(model.destinationCity, 'Karachi');
      expect(model.weightTons, 35.0);
    });

    test('LocaleProvider switches between en and ur (pure Flutter ChangeNotifier)', () {
      final provider = LocaleProvider();
      expect(provider.locale.languageCode, 'en');
      provider.setLocale(const Locale('ur'));
      expect(provider.locale.languageCode, 'ur');
      expect(provider.isUrdu, isTrue);
    });

    test('GeocodingService calculates accurate distance and bearing', () {
      const lahore = LatLng(31.5204, 74.3587);
      const karachi = LatLng(24.8607, 67.0011);

      final distanceKm = GeocodingService.calculateDistanceKm(lahore, karachi);
      expect(distanceKm, greaterThan(900));
      expect(distanceKm, lessThan(1150));

      final bearing = GeocodingService.calculateBearing(lahore, karachi);
      expect(bearing, greaterThan(200));
      expect(bearing, lessThan(250));

      final nearest = GeocodingService.instance.findNearestLandmark(lahore);
      expect(nearest, isNotNull);
      expect(nearest!.city, 'Lahore');
    });

    test('Route planner parameters and deep link query parsing', () {
      final uri = Uri.parse('https://trucklink-pk.web.app/route-planner?origin=Multan&destination=Faisalabad&vehicle=10_wheeler&motorway=false');
      expect(uri.path, '/route-planner');
      expect(uri.queryParameters['origin'], 'Multan');
      expect(uri.queryParameters['destination'], 'Faisalabad');
      expect(uri.queryParameters['vehicle'], '10_wheeler');
      expect(uri.queryParameters['motorway'], 'false');
    });

    test('Loads feed query parameter parsing for sharing', () {
      final uri = Uri.parse('https://trucklink-pk.web.app/loads-feed?city=Lahore&vehicle=22_wheeler');
      expect(uri.path, '/loads-feed');
      expect(uri.queryParameters['city'], 'Lahore');
      expect(uri.queryParameters['vehicle'], '22_wheeler');
    });

    test('AuthProvider admin state and toggleAdminMode', () {
      final auth = AuthProvider();
      expect(auth.isAdmin, isFalse);
      // Verify toggle switch
      auth.toggleAdminMode();
      // If no profile yet, state handles gracefully
      expect(auth.state.isLoading, isFalse);
    });

    test('FirebaseService driver verification stream and updates', () async {
      final service = FirebaseService.instance;
      final drivers = await service.watchDriversByStatus('all').first;
      expect(drivers.isNotEmpty, isTrue);

      final pending = await service.watchDriversByStatus('pending').first;
      expect(pending.every((d) => d.verificationStatus == 'pending'), isTrue);

      // Verify updateDriverVerificationStatus
      final target = drivers.first;
      await service.updateDriverVerificationStatus(
        uid: target.id,
        status: 'verified',
      );
      final updatedList = await service.watchDriversByStatus('all').first;
      final updatedDriver = updatedList.firstWhere((d) => d.id == target.id);
      expect(updatedDriver.verificationStatus, 'verified');
      expect(updatedDriver.cnicVerified, isTrue);
    });

    testWidgets('App initializes and renders Driver Dashboard without errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        const AppScope(
          child: TruckLinkApp(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Check for presence of Dashboard title or brand text
      expect(find.textContaining('Driver Dashboard'), findsOneWidget);
    });
  });
}
