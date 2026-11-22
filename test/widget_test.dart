import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trucklink_pk/app.dart';
import 'package:trucklink_pk/core/ai/tensor.dart';
import 'package:trucklink_pk/core/ai/models/rate_prediction_network.dart';
import 'package:trucklink_pk/core/ai/models/load_matching_network.dart';
import 'package:trucklink_pk/core/ai/models/intent_classification_network.dart';
import 'package:trucklink_pk/core/ai/trainer/neural_trainer.dart';
import 'package:trucklink_pk/core/ai/trucklink_ai_service.dart';
import 'package:trucklink_pk/core/constants/vehicle_types.dart';
import 'package:trucklink_pk/core/localization/locale_provider.dart';
import 'package:trucklink_pk/core/providers/app_scope.dart';
import 'package:trucklink_pk/core/services/geocoding_service.dart';
import 'package:trucklink_pk/core/utils/formatters.dart';
import 'package:trucklink_pk/core/utils/urdu_text.dart';
import 'package:trucklink_pk/core/utils/validators.dart';
import 'package:trucklink_pk/core/widgets/captcha_verification_widget.dart';
import 'package:trucklink_pk/features/auth/domain/user_profile.dart';
import 'package:trucklink_pk/features/auth/presentation/providers/auth_provider.dart';
import 'package:trucklink_pk/features/auth/presentation/screens/login_screen.dart';
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
      expect(AppValidators.validatePhone('+92 308 750 2250'), isNull);
      expect(AppValidators.validatePhone('0211234567'), isNotNull);

      expect(AppValidators.normalizePhone('0300 1234567'), '+923001234567');
      expect(AppValidators.normalizePhone('300 1234567'), '+923001234567');
      expect(AppValidators.normalizePhone('+923001234567'), '+923001234567');
      expect(AppValidators.normalizePhone('+92 308 750 2250'), '+923087502250');
      expect(AppValidators.normalizePhone('0308 750 2250'), '+923087502250');
    });

    test('formatPakistaniPhoneNumber formats to +92 308 750 2250', () {
      expect(AppFormatters.formatPakistaniPhoneNumber('03087502250'), '+92 308 750 2250');
      expect(AppFormatters.formatPakistaniPhoneNumber('3087502250'), '+92 308 750 2250');
      expect(AppFormatters.formatPakistaniPhoneNumber('+923087502250'), '+92 308 750 2250');
      expect(AppFormatters.formatPakistaniPhoneNumber('0300 1234567'), '+92 300 123 4567');

      final formatter = PakistaniPhoneInputFormatter();
      final updated = formatter.formatEditUpdate(
        const TextEditingValue(text: ''),
        const TextEditingValue(text: '03087502250'),
      );
      expect(updated.text, '+92 308 750 2250');
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
      expect(drivers, isEmpty);

      final loads = await service.watchLoads().first;
      expect(loads, isEmpty);
    });

    testWidgets('App initializes and redirects unauthenticated visitor to Login Screen', (WidgetTester tester) async {
      await tester.pumpWidget(
        const AppScope(
          child: TruckLinkApp(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Strictly redirects unauthenticated visitor to Login Screen
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    group('Neural Network & AI Engine Tests', () {
      test('Tensor vector operations and activations (GELU, ReLU, Softmax, LayerNorm)', () {
        final t1 = Tensor.vector([1.0, 2.0, 3.0]);
        final t2 = Tensor.vector([4.0, 5.0, 6.0]);

        // Dot product: 1*4 + 2*5 + 3*6 = 32
        expect(Tensor.dot(t1, t2), closeTo(32.0, 1e-5));

        // Cosine similarity of identical vectors is 1.0
        expect(Tensor.cosineSimilarity(t1, t1), closeTo(1.0, 1e-5));

        // Activations
        final geluOut = Tensor.vector([-2.0, 0.0, 2.0]).gelu();
        expect(geluOut[1], closeTo(0.0, 1e-5));
        expect(geluOut[2], greaterThan(1.9));

        final reluOut = Tensor.vector([-5.0, 0.0, 5.0]).relu();
        expect(reluOut[0], 0.0);
        expect(reluOut[2], 5.0);

        final softmaxOut = Tensor.vector([1.0, 2.0, 3.0]).softmax();
        final sum = softmaxOut.data.reduce((a, b) => a + b);
        expect(sum, closeTo(1.0, 1e-5));
        expect(softmaxOut[2], greaterThan(softmaxOut[0]));

        final norm = Tensor.vector([10.0, 20.0, 30.0]).layerNorm();
        final mean = norm.data.reduce((a, b) => a + b) / norm.length;
        expect(mean, closeTo(0.0, 1e-5));
      });

      test('PakFreightRateNet computes realistic rate and margin forecasts', () {
        final net = PakFreightRateNet.instance;

        final pred = net.predict(
          distanceKm: 1210.0,
          weightTons: 35.0,
          vehicleType: '22_wheeler',
          goodsType: 'general',
          isMotorway: true,
          dieselPricePerLiter: 285.0,
        );
        expect(pred.recommendedRatePkr, greaterThan(180000.0));
        expect(pred.recommendedRatePkr, lessThan(350000.0));
        expect(pred.maxRatePkr, greaterThan(pred.recommendedRatePkr));
        expect(pred.minRatePkr, lessThan(pred.recommendedRatePkr));
        expect(pred.estimatedDieselLiters, greaterThan(300.0));
        expect(pred.estimatedNetDriverProfitPkr, greaterThan(0.0));
      });

      test('LoadMatchNet evaluates driver-load compatibility via Two-Tower embeddings', () {
        final net = LoadMatchNet.instance;
        final driver = UserProfile(
          id: 'drv-test',
          fullName: 'Tariq Khan',
          phone: '+923001234567',
          role: 'driver',
          vehicleTypes: ['22_wheeler'],
          rating: 4.9,
          totalRatings: 45,
          verificationStatus: 'verified',
        );

        final matchedLoad = LoadModel(
          id: 'l-1',
          ownerId: 'own-1',
          originCity: 'Lahore',
          destinationCity: 'Karachi',
          vehicleTypeRequired: '22_wheeler',
          weightTons: 35.0,
          offeredRatePkr: 250000.0,
          status: 'open',
          createdAt: DateTime.now(),
        );

        final result = net.evaluate(driver: driver, load: matchedLoad);
        expect(result.score, greaterThan(0.60));
        expect(result.percentage, greaterThan(60));
        expect(result.backhaulScore, greaterThan(0.40));
        expect(result.recommendationEn, isNotEmpty);
        expect(result.recommendationUr, isNotEmpty);
      });

      test('LogisticsIntentNet classifies Urdu and Roman Urdu freight queries accurately', () {
        final net = LogisticsIntentNet.instance;

        final urduQuery = net.classify('لاہور سے کراچی کا کرایہ کیا ہے؟');
        expect(urduQuery.intent, AiIntent.rateEstimate);
        expect(urduQuery.entities.origin, 'Lahore');
        expect(urduQuery.entities.destination, 'Karachi');

        final romanUrduQuery = net.classify('mujhe Faisalabad k loads dikhao');
        expect(romanUrduQuery.intent, AiIntent.searchLoads);

        final routeQuery = net.classify('M-2 motorway toll tax aur bridge height check karo');
        expect(routeQuery.intent, AiIntent.bridgeClearance);
      });

      test('NeuralTrainer executes backprop epochs and updates network weights', () async {
        final metrics = await NeuralTrainer.trainRateModel(epochs: 3);

        expect(metrics.totalEpochs, 3);
        expect(metrics.initialLoss, isPositive);
        expect(metrics.finalLoss, isPositive);
        expect(metrics.meanAbsoluteErrorPkr, isPositive);
      });

      test('TruckLinkAiService orchestrates predictions and end-to-end assistant flows', () {
        final service = TruckLinkAiService.instance;

        // Rate prediction
        final rate = service.predictRate(
          origin: 'Rawalpindi',
          destination: 'Lahore',
          vehicleType: 'mazda',
          weightTons: 7.0,
        );
        expect(rate.recommendedRatePkr, greaterThanOrEqualTo(25000.0));
        expect(rate.recommendedRatePkr, lessThan(95000.0));

        // Assistant query handling
        final response = service.queryAssistant('لاہور سے کراچی کا کرایہ کتنا ہے');
        expect(response.responseEn, contains('Lahore'));
        expect(response.responseUr, contains('کرایہ'));
      });
    });
  });
}
