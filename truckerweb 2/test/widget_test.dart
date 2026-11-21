import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trucklink_pk/app.dart';
import 'package:trucklink_pk/core/utils/validators.dart';
import 'package:trucklink_pk/core/utils/formatters.dart';

void main() {
  group('TruckLink PK Unit & Smoke Tests', () {
    test('Pakistani CNIC Validator correctly validates 13-digit numbers', () {
      expect(AppValidators.validateCnic('35202-1234567-1'), isNull);
      expect(AppValidators.validateCnic('3520212345671'), isNull);
      expect(AppValidators.validateCnic('123'), isNotNull);
      expect(AppValidators.validateCnic(''), isNotNull);
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

    testWidgets('App initializes and renders Driver Dashboard without errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: TruckLinkApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Check for presence of Dashboard title or brand text
      expect(find.textContaining('Driver Dashboard'), findsOneWidget);
    });
  });
}
