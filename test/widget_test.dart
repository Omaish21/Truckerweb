import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trucklink_pk/app.dart';
import 'package:trucklink_pk/core/constants/vehicle_types.dart';
import 'package:trucklink_pk/core/localization/locale_provider.dart';
import 'package:trucklink_pk/core/utils/formatters.dart';
import 'package:trucklink_pk/core/utils/urdu_text.dart';
import 'package:trucklink_pk/core/utils/validators.dart';
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
      expect(AppValidators.validatePhone('0211234567'), isNotNull);

      expect(AppValidators.normalizePhone('0300 1234567'), '+923001234567');
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

    test('LocaleNotifier switches between en and ur', () {
      final notifier = LocaleNotifier();
      expect(notifier.state.languageCode, 'en');
      notifier.setLocale(const Locale('ur'));
      expect(notifier.state.languageCode, 'ur');
      expect(notifier.isUrdu, isTrue);
    });

    testWidgets('App initializes and renders Driver Dashboard without errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
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
