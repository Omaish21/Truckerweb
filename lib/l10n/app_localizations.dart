import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ur.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ur'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'TruckLink PK'**
  String get appTitle;

  /// No description provided for @appSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pakistan Truck Driver & Load Logistics Platform'**
  String get appSubtitle;

  /// No description provided for @switchToTransporter.
  ///
  /// In en, this message translates to:
  /// **'Switch to Transporter Mode'**
  String get switchToTransporter;

  /// No description provided for @switchToDriver.
  ///
  /// In en, this message translates to:
  /// **'Switch to Driver Mode'**
  String get switchToDriver;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @inspectRoute.
  ///
  /// In en, this message translates to:
  /// **'Inspect Route'**
  String get inspectRoute;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requiredField;

  /// No description provided for @onlineStatus.
  ///
  /// In en, this message translates to:
  /// **'Online: Receiving Load Requests'**
  String get onlineStatus;

  /// No description provided for @offlineStatus.
  ///
  /// In en, this message translates to:
  /// **'Offline: Hidden from search'**
  String get offlineStatus;

  /// No description provided for @htvPlusLicense.
  ///
  /// In en, this message translates to:
  /// **'HTV+ License'**
  String get htvPlusLicense;

  /// No description provided for @verifiedBadgeText.
  ///
  /// In en, this message translates to:
  /// **'NADRA Verified'**
  String get verifiedBadgeText;

  /// No description provided for @unverifiedBadgeText.
  ///
  /// In en, this message translates to:
  /// **'Unverified'**
  String get unverifiedBadgeText;

  /// No description provided for @tonsUnit.
  ///
  /// In en, this message translates to:
  /// **'{weight} Tons'**
  String tonsUnit(String weight);

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Driver & Transporter Login'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number to receive a 6-digit verification code.'**
  String get loginSubtitle;

  /// No description provided for @mobileNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Mobile Number'**
  String get mobileNumberLabel;

  /// No description provided for @mobileNumberHint.
  ///
  /// In en, this message translates to:
  /// **'0300 1234567'**
  String get mobileNumberHint;

  /// No description provided for @sendVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'Send Verification Code'**
  String get sendVerificationCode;

  /// No description provided for @verifyOtpTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify OTP'**
  String get verifyOtpTitle;

  /// No description provided for @codeSentTo.
  ///
  /// In en, this message translates to:
  /// **'Code sent to {phone}.'**
  String codeSentTo(String phone);

  /// No description provided for @otpLabel.
  ///
  /// In en, this message translates to:
  /// **'6-digit OTP Code'**
  String get otpLabel;

  /// No description provided for @otpHint.
  ///
  /// In en, this message translates to:
  /// **'123456'**
  String get otpHint;

  /// No description provided for @verifyAndContinue.
  ///
  /// In en, this message translates to:
  /// **'Verify & Continue'**
  String get verifyAndContinue;

  /// No description provided for @validPhoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid Pakistani mobile number (e.g. 0300 1234567)'**
  String get validPhoneRequired;

  /// No description provided for @phoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone number is required'**
  String get phoneRequired;

  /// No description provided for @validCnicRequired.
  ///
  /// In en, this message translates to:
  /// **'Valid 13-digit CNIC required (e.g. 42101-1234567-1)'**
  String get validCnicRequired;

  /// No description provided for @cnicRequired.
  ///
  /// In en, this message translates to:
  /// **'CNIC number is required'**
  String get cnicRequired;

  /// No description provided for @selectRoleTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Role'**
  String get selectRoleTitle;

  /// No description provided for @selectRoleHeader.
  ///
  /// In en, this message translates to:
  /// **'How do you want to use TruckLink PK?'**
  String get selectRoleHeader;

  /// No description provided for @driverRole.
  ///
  /// In en, this message translates to:
  /// **'Driver (Job Seeker)'**
  String get driverRole;

  /// No description provided for @driverRoleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find high-paying loads & route alerts'**
  String get driverRoleSubtitle;

  /// No description provided for @driverRoleDescription.
  ///
  /// In en, this message translates to:
  /// **'Find high-paying loads, live bridge clearance alerts, city curfews, and verified profile.'**
  String get driverRoleDescription;

  /// No description provided for @ownerRole.
  ///
  /// In en, this message translates to:
  /// **'Fleet Owner / Shipper'**
  String get ownerRole;

  /// No description provided for @ownerRoleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Post loads & track GPS trips'**
  String get ownerRoleSubtitle;

  /// No description provided for @ownerRoleDescription.
  ///
  /// In en, this message translates to:
  /// **'Post loads, find nearby PostGIS verified drivers, track active GPS trips and routes.'**
  String get ownerRoleDescription;

  /// No description provided for @driverDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Driver Dashboard'**
  String get driverDashboardTitle;

  /// No description provided for @routeIntelligence.
  ///
  /// In en, this message translates to:
  /// **'Route Intelligence'**
  String get routeIntelligence;

  /// No description provided for @routeIntelligenceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Clearances & optimal paths'**
  String get routeIntelligenceSubtitle;

  /// No description provided for @cityCurfewTimings.
  ///
  /// In en, this message translates to:
  /// **'City Curfew Timings'**
  String get cityCurfewTimings;

  /// No description provided for @cityCurfewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Heavy vehicle entry windows'**
  String get cityCurfewSubtitle;

  /// No description provided for @reportRoadHazard.
  ///
  /// In en, this message translates to:
  /// **'Report Road Hazard'**
  String get reportRoadHazard;

  /// No description provided for @reportHazardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Broadcast warnings to drivers'**
  String get reportHazardSubtitle;

  /// No description provided for @allAvailableLoads.
  ///
  /// In en, this message translates to:
  /// **'All Available Loads'**
  String get allAvailableLoads;

  /// No description provided for @allLoadsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Browse active load market'**
  String get allLoadsSubtitle;

  /// No description provided for @matchedLoadsNearYou.
  ///
  /// In en, this message translates to:
  /// **'Matched Loads Near You'**
  String get matchedLoadsNearYou;

  /// No description provided for @criticalLowBridgeAhead.
  ///
  /// In en, this message translates to:
  /// **'⚠️ CRITICAL: LOW BRIDGE AHEAD'**
  String get criticalLowBridgeAhead;

  /// No description provided for @bridgeClearance.
  ///
  /// In en, this message translates to:
  /// **'Clearance: {height} ft'**
  String bridgeClearance(String height);

  /// No description provided for @truckHeight.
  ///
  /// In en, this message translates to:
  /// **'Your Truck: {height} ft'**
  String truckHeight(String height);

  /// No description provided for @distanceAhead.
  ///
  /// In en, this message translates to:
  /// **'{distance} km ahead'**
  String distanceAhead(String distance);

  /// No description provided for @recommendedReroute.
  ///
  /// In en, this message translates to:
  /// **'Recommended: Reroute via Bypass'**
  String get recommendedReroute;

  /// No description provided for @tapToRecalculate.
  ///
  /// In en, this message translates to:
  /// **'Recalculate Safe Route'**
  String get tapToRecalculate;

  /// No description provided for @availableLoadsTitle.
  ///
  /// In en, this message translates to:
  /// **'Available Loads'**
  String get availableLoadsTitle;

  /// No description provided for @postNewLoad.
  ///
  /// In en, this message translates to:
  /// **'Post a Load'**
  String get postNewLoad;

  /// No description provided for @postLoadSuccess.
  ///
  /// In en, this message translates to:
  /// **'Load posted successfully! PostGIS search activated for nearby drivers.'**
  String get postLoadSuccess;

  /// No description provided for @pickupLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Pickup City & Area'**
  String get pickupLocationLabel;

  /// No description provided for @dropoffLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Drop-off City & Destination'**
  String get dropoffLocationLabel;

  /// No description provided for @vehicleRequiredLabel.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Required'**
  String get vehicleRequiredLabel;

  /// No description provided for @loadWeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Weight (Tons)'**
  String get loadWeightLabel;

  /// No description provided for @truckHeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Height (Feet)'**
  String get truckHeightLabel;

  /// No description provided for @offeredRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Offered Rate (PKR)'**
  String get offeredRateLabel;

  /// No description provided for @goodsTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type of Goods'**
  String get goodsTypeLabel;

  /// No description provided for @goodsGeneral.
  ///
  /// In en, this message translates to:
  /// **'General Cargo'**
  String get goodsGeneral;

  /// No description provided for @goodsTextile.
  ///
  /// In en, this message translates to:
  /// **'Textile & Yarn'**
  String get goodsTextile;

  /// No description provided for @goodsAgri.
  ///
  /// In en, this message translates to:
  /// **'Agricultural Produce'**
  String get goodsAgri;

  /// No description provided for @goodsChemical.
  ///
  /// In en, this message translates to:
  /// **'Industrial & Chemical'**
  String get goodsChemical;

  /// No description provided for @submitLoadButton.
  ///
  /// In en, this message translates to:
  /// **'Publish Load Broadcast'**
  String get submitLoadButton;

  /// No description provided for @statusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get statusOpen;

  /// No description provided for @statusAssigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get statusAssigned;

  /// No description provided for @statusInTransit.
  ///
  /// In en, this message translates to:
  /// **'In Transit'**
  String get statusInTransit;

  /// No description provided for @statusDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get statusDelivered;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @routePlannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Route Intelligence'**
  String get routePlannerTitle;

  /// No description provided for @hereTruckProfile.
  ///
  /// In en, this message translates to:
  /// **'HERE Truck Profile'**
  String get hereTruckProfile;

  /// No description provided for @activeConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Active Configuration'**
  String get activeConfiguration;

  /// No description provided for @avoidLowBridges.
  ///
  /// In en, this message translates to:
  /// **'Avoid Low Clearance Bridges'**
  String get avoidLowBridges;

  /// No description provided for @avoidLowBridgesDesc.
  ///
  /// In en, this message translates to:
  /// **'Automatically detects bridges below truck height'**
  String get avoidLowBridgesDesc;

  /// No description provided for @useMotorwayBypass.
  ///
  /// In en, this message translates to:
  /// **'Prefer Motorway & Bypass'**
  String get useMotorwayBypass;

  /// No description provided for @useMotorwayBypassDesc.
  ///
  /// In en, this message translates to:
  /// **'Bypasses city traffic and congestion'**
  String get useMotorwayBypassDesc;

  /// No description provided for @startGpsNavigation.
  ///
  /// In en, this message translates to:
  /// **'Start GPS Navigation'**
  String get startGpsNavigation;

  /// No description provided for @detectedClearanceAlerts.
  ///
  /// In en, this message translates to:
  /// **'Detected Clearance Alerts'**
  String get detectedClearanceAlerts;

  /// No description provided for @recalculatingOptimalRoute.
  ///
  /// In en, this message translates to:
  /// **'Recalculating optimal truck route...'**
  String get recalculatingOptimalRoute;

  /// No description provided for @cityTimingTitle.
  ///
  /// In en, this message translates to:
  /// **'City Entry Timing Windows'**
  String get cityTimingTitle;

  /// No description provided for @heavyCurfewHeader.
  ///
  /// In en, this message translates to:
  /// **'Heavy Vehicle Curfew Windows'**
  String get heavyCurfewHeader;

  /// No description provided for @curfewExplanation.
  ///
  /// In en, this message translates to:
  /// **'Timings are actively verified via traffic police bulletins and driver reports to avoid costly fines or impounds.'**
  String get curfewExplanation;

  /// No description provided for @allowedEntryWindow.
  ///
  /// In en, this message translates to:
  /// **'Allowed Entry Window: {from} - {to}'**
  String allowedEntryWindow(String from, String to);

  /// No description provided for @verifiedConfidence.
  ///
  /// In en, this message translates to:
  /// **'{percent}% Verified Confidence'**
  String verifiedConfidence(String percent);

  /// No description provided for @selectHazardCategory.
  ///
  /// In en, this message translates to:
  /// **'Select Hazard Category'**
  String get selectHazardCategory;

  /// No description provided for @exactLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Exact Road Location'**
  String get exactLocationLabel;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Additional Details & Landmark'**
  String get descriptionLabel;

  /// No description provided for @descriptionHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Deep crater on left lane, heavy waterlogging...'**
  String get descriptionHint;

  /// No description provided for @submitHazardButton.
  ///
  /// In en, this message translates to:
  /// **'Broadcast Hazard Alert'**
  String get submitHazardButton;

  /// No description provided for @hazardBroadcastSuccess.
  ///
  /// In en, this message translates to:
  /// **'Road report submitted & broadcast to nearby drivers within 20km!'**
  String get hazardBroadcastSuccess;

  /// No description provided for @enableAlerts.
  ///
  /// In en, this message translates to:
  /// **'Enable Alerts'**
  String get enableAlerts;

  /// No description provided for @alertsActive.
  ///
  /// In en, this message translates to:
  /// **'Alerts Active'**
  String get alertsActive;

  /// No description provided for @pushNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get pushNotificationsTitle;

  /// No description provided for @notificationsPermissionPrompt.
  ///
  /// In en, this message translates to:
  /// **'Enable instant browser notifications for new bids, accepted offers, and critical road hazards.'**
  String get notificationsPermissionPrompt;

  /// No description provided for @allowNotificationsButton.
  ///
  /// In en, this message translates to:
  /// **'Allow Notifications'**
  String get allowNotificationsButton;

  /// No description provided for @notificationsEnabledSuccess.
  ///
  /// In en, this message translates to:
  /// **'Push notifications successfully enabled!'**
  String get notificationsEnabledSuccess;

  /// No description provided for @notificationsDenied.
  ///
  /// In en, this message translates to:
  /// **'Notifications blocked. Please enable them in your browser settings.'**
  String get notificationsDenied;

  /// No description provided for @newBidNotification.
  ///
  /// In en, this message translates to:
  /// **'New Bid Received'**
  String get newBidNotification;

  /// No description provided for @bidAcceptedNotification.
  ///
  /// In en, this message translates to:
  /// **'Bid Accepted!'**
  String get bidAcceptedNotification;

  /// No description provided for @roadHazardAlert.
  ///
  /// In en, this message translates to:
  /// **'Road Hazard Alert'**
  String get roadHazardAlert;

  /// No description provided for @markAsRead.
  ///
  /// In en, this message translates to:
  /// **'Mark as Read'**
  String get markAsRead;

  /// No description provided for @noNewNotifications.
  ///
  /// In en, this message translates to:
  /// **'No new notifications'**
  String get noNewNotifications;

  /// No description provided for @safetyAndAlerts.
  ///
  /// In en, this message translates to:
  /// **'Safety & Bridge Alerts'**
  String get safetyAndAlerts;

  /// No description provided for @turnByTurnSteps.
  ///
  /// In en, this message translates to:
  /// **'Turn-by-Turn Steps'**
  String get turnByTurnSteps;

  /// No description provided for @costAndStops.
  ///
  /// In en, this message translates to:
  /// **'Cost & Services'**
  String get costAndStops;

  /// No description provided for @liveTraffic.
  ///
  /// In en, this message translates to:
  /// **'Live Traffic'**
  String get liveTraffic;

  /// No description provided for @satelliteView.
  ///
  /// In en, this message translates to:
  /// **'Satellite'**
  String get satelliteView;

  /// No description provided for @normalView.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get normalView;

  /// No description provided for @criticalClearanceDanger.
  ///
  /// In en, this message translates to:
  /// **'CRITICAL CLEARANCE DANGER'**
  String get criticalClearanceDanger;

  /// No description provided for @clearanceSafe.
  ///
  /// In en, this message translates to:
  /// **'Route Clearance Verified Safe'**
  String get clearanceSafe;

  /// No description provided for @speakAlert.
  ///
  /// In en, this message translates to:
  /// **'Listen Alert'**
  String get speakAlert;

  /// No description provided for @openGpsNavigation.
  ///
  /// In en, this message translates to:
  /// **'Open Live GPS Navigation'**
  String get openGpsNavigation;

  /// No description provided for @destinationCurfew.
  ///
  /// In en, this message translates to:
  /// **'Destination City Entry Curfew'**
  String get destinationCurfew;

  /// No description provided for @noHazardReports.
  ///
  /// In en, this message translates to:
  /// **'No active road hazard reports along this corridor'**
  String get noHazardReports;

  /// No description provided for @noTurnStepsAvailable.
  ///
  /// In en, this message translates to:
  /// **'Navigation instructions ready upon route calculation'**
  String get noTurnStepsAvailable;

  /// No description provided for @adminVerificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Admin Document Verification'**
  String get adminVerificationTitle;

  /// No description provided for @pendingReview.
  ///
  /// In en, this message translates to:
  /// **'Pending Review'**
  String get pendingReview;

  /// No description provided for @verifiedDrivers.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verifiedDrivers;

  /// No description provided for @rejectedDrivers.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejectedDrivers;

  /// No description provided for @approveButton.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approveButton;

  /// No description provided for @rejectButton.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get rejectButton;

  /// No description provided for @rejectionReasonPrompt.
  ///
  /// In en, this message translates to:
  /// **'Select or enter rejection reason'**
  String get rejectionReasonPrompt;

  /// No description provided for @reasonBlurryPhoto.
  ///
  /// In en, this message translates to:
  /// **'Blurry or unreadable photo / دستاویز واضح نہیں ہے'**
  String get reasonBlurryPhoto;

  /// No description provided for @reasonExpiredLicense.
  ///
  /// In en, this message translates to:
  /// **'Expired driving license / ڈرائیونگ لائسنس کی مدت ختم ہو چکی ہے'**
  String get reasonExpiredLicense;

  /// No description provided for @reasonCnicMismatch.
  ///
  /// In en, this message translates to:
  /// **'CNIC number or details mismatch / شناختی کارڈ کی معلومات میں تضاد ہے'**
  String get reasonCnicMismatch;

  /// No description provided for @reasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other reason'**
  String get reasonOther;

  /// No description provided for @enterCustomReason.
  ///
  /// In en, this message translates to:
  /// **'Enter custom rejection reason...'**
  String get enterCustomReason;

  /// No description provided for @cnicDocument.
  ///
  /// In en, this message translates to:
  /// **'CNIC Card'**
  String get cnicDocument;

  /// No description provided for @licenseDocument.
  ///
  /// In en, this message translates to:
  /// **'Driving License (HTV/LTV)'**
  String get licenseDocument;

  /// No description provided for @registrationDocument.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Registration'**
  String get registrationDocument;

  /// No description provided for @noPendingDrivers.
  ///
  /// In en, this message translates to:
  /// **'No drivers pending review'**
  String get noPendingDrivers;

  /// No description provided for @noVerifiedDrivers.
  ///
  /// In en, this message translates to:
  /// **'No verified drivers found'**
  String get noVerifiedDrivers;

  /// No description provided for @noRejectedDrivers.
  ///
  /// In en, this message translates to:
  /// **'No rejected drivers found'**
  String get noRejectedDrivers;

  /// No description provided for @driverApprovedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Driver documents approved successfully!'**
  String get driverApprovedSuccess;

  /// No description provided for @driverRejectedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Driver documents rejected and notification sent.'**
  String get driverRejectedSuccess;

  /// No description provided for @adminPanel.
  ///
  /// In en, this message translates to:
  /// **'Admin Panel'**
  String get adminPanel;

  /// No description provided for @adminVerification.
  ///
  /// In en, this message translates to:
  /// **'Admin Verification'**
  String get adminVerification;

  /// No description provided for @toggleAdminMode.
  ///
  /// In en, this message translates to:
  /// **'Toggle Admin Mode'**
  String get toggleAdminMode;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ur'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ur':
      return AppLocalizationsUr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
