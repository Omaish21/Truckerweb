// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'TruckLink PK';

  @override
  String get driverRole => 'Driver (Job Seeker)';

  @override
  String get ownerRole => 'Fleet Owner / Shipper';

  @override
  String get loginTitle => 'Login with Phone';

  @override
  String get phoneNumberHint => '03XX XXXXXXX';

  @override
  String get sendOtp => 'Send Verification Code';

  @override
  String get verifyOtp => 'Verify Code';

  @override
  String get enterOtp => 'Enter 6-digit OTP';

  @override
  String get routeIntelligence => 'Route Intelligence';

  @override
  String get bridgeHeightWarning => 'Bridge Clearance Alert';

  @override
  String get cityTimingTitle => 'City Entry Timing Windows';

  @override
  String get roadReportsTitle => 'Road Hazard Reports';

  @override
  String get nearbyDrivers => 'Nearby Drivers';

  @override
  String get postLoadTitle => 'Post a Load';

  @override
  String get activeTrips => 'Active Trips';
}
