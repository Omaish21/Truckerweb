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
  String get appSubtitle => 'Pakistan Truck Driver & Load Logistics Platform';

  @override
  String get switchToTransporter => 'Switch to Transporter Mode';

  @override
  String get switchToDriver => 'Switch to Driver Mode';

  @override
  String get logout => 'Logout';

  @override
  String get inspectRoute => 'Inspect Route';

  @override
  String get viewAll => 'View All';

  @override
  String get requiredField => 'Required';

  @override
  String get onlineStatus => 'Online: Receiving Load Requests';

  @override
  String get offlineStatus => 'Offline: Hidden from search';

  @override
  String get htvPlusLicense => 'HTV+ License';

  @override
  String get verifiedBadgeText => 'NADRA Verified';

  @override
  String get unverifiedBadgeText => 'Unverified';

  @override
  String tonsUnit(String weight) {
    return '$weight Tons';
  }

  @override
  String get loginTitle => 'Driver & Transporter Login';

  @override
  String get loginSubtitle =>
      'Enter your phone number to receive a 6-digit verification code.';

  @override
  String get mobileNumberLabel => 'Mobile Number';

  @override
  String get mobileNumberHint => '0300 1234567';

  @override
  String get sendVerificationCode => 'Send Verification Code';

  @override
  String get verifyOtpTitle => 'Verify OTP';

  @override
  String codeSentTo(String phone) {
    return 'Code sent to $phone. (Demo OTP: 123456)';
  }

  @override
  String get otpLabel => '6-digit OTP Code';

  @override
  String get otpHint => '123456';

  @override
  String get verifyAndContinue => 'Verify & Continue';

  @override
  String get validPhoneRequired =>
      'Enter a valid Pakistani mobile number (e.g. 0300 1234567)';

  @override
  String get phoneRequired => 'Phone number is required';

  @override
  String get validCnicRequired =>
      'Valid 13-digit CNIC required (e.g. 42101-1234567-1)';

  @override
  String get cnicRequired => 'CNIC number is required';

  @override
  String get selectRoleTitle => 'Select Role';

  @override
  String get selectRoleHeader => 'How do you want to use TruckLink PK?';

  @override
  String get driverRole => 'Driver (Job Seeker)';

  @override
  String get driverRoleSubtitle => 'Find high-paying loads & route alerts';

  @override
  String get driverRoleDescription =>
      'Find high-paying loads, live bridge clearance alerts, city curfews, and verified profile.';

  @override
  String get ownerRole => 'Fleet Owner / Shipper';

  @override
  String get ownerRoleSubtitle => 'Post loads & track GPS trips';

  @override
  String get ownerRoleDescription =>
      'Post loads, find nearby PostGIS verified drivers, track active GPS trips and routes.';

  @override
  String get driverDashboardTitle => 'Driver Dashboard';

  @override
  String get routeIntelligence => 'Route Intelligence';

  @override
  String get routeIntelligenceSubtitle => 'Clearances & optimal paths';

  @override
  String get cityCurfewTimings => 'City Curfew Timings';

  @override
  String get cityCurfewSubtitle => 'Heavy vehicle entry windows';

  @override
  String get reportRoadHazard => 'Report Road Hazard';

  @override
  String get reportHazardSubtitle => 'Broadcast warnings to drivers';

  @override
  String get allAvailableLoads => 'All Available Loads';

  @override
  String get allLoadsSubtitle => 'Browse active load market';

  @override
  String get matchedLoadsNearYou => 'Matched Loads Near You';

  @override
  String get criticalLowBridgeAhead => '⚠️ CRITICAL: LOW BRIDGE AHEAD';

  @override
  String bridgeClearance(String height) {
    return 'Clearance: $height ft';
  }

  @override
  String truckHeight(String height) {
    return 'Your Truck: $height ft';
  }

  @override
  String distanceAhead(String distance) {
    return '$distance km ahead';
  }

  @override
  String get recommendedReroute => 'Recommended: Reroute via Bypass';

  @override
  String get tapToRecalculate => 'Recalculate Safe Route';

  @override
  String get availableLoadsTitle => 'Available Loads';

  @override
  String get postNewLoad => 'Post a Load';

  @override
  String get postLoadSuccess =>
      'Load posted successfully! PostGIS search activated for nearby drivers.';

  @override
  String get pickupLocationLabel => 'Pickup City & Area';

  @override
  String get dropoffLocationLabel => 'Drop-off City & Destination';

  @override
  String get vehicleRequiredLabel => 'Vehicle Required';

  @override
  String get loadWeightLabel => 'Weight (Tons)';

  @override
  String get truckHeightLabel => 'Total Height (Feet)';

  @override
  String get offeredRateLabel => 'Offered Rate (PKR)';

  @override
  String get goodsTypeLabel => 'Type of Goods';

  @override
  String get goodsGeneral => 'General Cargo';

  @override
  String get goodsTextile => 'Textile & Yarn';

  @override
  String get goodsAgri => 'Agricultural Produce';

  @override
  String get goodsChemical => 'Industrial & Chemical';

  @override
  String get submitLoadButton => 'Publish Load Broadcast';

  @override
  String get statusOpen => 'Open';

  @override
  String get statusAssigned => 'Assigned';

  @override
  String get statusInTransit => 'In Transit';

  @override
  String get statusDelivered => 'Delivered';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get routePlannerTitle => 'Route Intelligence';

  @override
  String get hereTruckProfile => 'HERE Truck Profile';

  @override
  String get activeConfiguration => 'Active Configuration';

  @override
  String get avoidLowBridges => 'Avoid Low Clearance Bridges';

  @override
  String get avoidLowBridgesDesc =>
      'Automatically detects bridges below truck height';

  @override
  String get useMotorwayBypass => 'Prefer Motorway & Bypass';

  @override
  String get useMotorwayBypassDesc => 'Bypasses city traffic and congestion';

  @override
  String get startGpsNavigation => 'Start GPS Navigation';

  @override
  String get detectedClearanceAlerts => 'Detected Clearance Alerts';

  @override
  String get recalculatingOptimalRoute =>
      'Recalculating optimal truck route...';

  @override
  String get cityTimingTitle => 'City Entry Timing Windows';

  @override
  String get heavyCurfewHeader => 'Heavy Vehicle Curfew Windows';

  @override
  String get curfewExplanation =>
      'Timings are actively verified via traffic police bulletins and driver reports to avoid costly fines or impounds.';

  @override
  String allowedEntryWindow(String from, String to) {
    return 'Allowed Entry Window: $from - $to';
  }

  @override
  String verifiedConfidence(String percent) {
    return '$percent% Verified Confidence';
  }

  @override
  String get selectHazardCategory => 'Select Hazard Category';

  @override
  String get exactLocationLabel => 'Exact Road Location';

  @override
  String get descriptionLabel => 'Additional Details & Landmark';

  @override
  String get descriptionHint =>
      'e.g., Deep crater on left lane, heavy waterlogging...';

  @override
  String get submitHazardButton => 'Broadcast Hazard Alert';

  @override
  String get hazardBroadcastSuccess =>
      'Road report submitted & broadcast to nearby drivers within 20km!';
}
