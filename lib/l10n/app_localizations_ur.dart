// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Urdu (`ur`).
class AppLocalizationsUr extends AppLocalizations {
  AppLocalizationsUr([String locale = 'ur']) : super(locale);

  @override
  String get appTitle => 'ٹرک لنک پی کے';

  @override
  String get appSubtitle => 'پاکستان ٹرک ڈرائیور و لوڈ لاجسٹکس پلیٹ فارم';

  @override
  String get switchToTransporter => 'ٹرانسپورٹر موڈ میں تبدیل کریں';

  @override
  String get switchToDriver => 'ڈرائیور موڈ میں تبدیل کریں';

  @override
  String get logout => 'لاگ آؤٹ';

  @override
  String get inspectRoute => 'راستہ دیکھیں';

  @override
  String get viewAll => 'سب دیکھیں';

  @override
  String get requiredField => 'یہ خانہ پر کرنا ضروری ہے';

  @override
  String get onlineStatus => 'آن لائن: لوڈ کی درخواستیں موصول ہو رہی ہیں';

  @override
  String get offlineStatus => 'آف لائن: تلاش میں پوشیدہ';

  @override
  String get htvPlusLicense => 'ایچ ٹی وی پلس لائسنس';

  @override
  String get verifiedBadgeText => 'نادرا سے تصدیق شدہ';

  @override
  String get unverifiedBadgeText => 'غیر تصدیق شدہ';

  @override
  String tonsUnit(String weight) {
    return '$weight ٹن';
  }

  @override
  String get loginTitle => 'ڈرائیور و ٹرانسپورٹر لاگ ان';

  @override
  String get loginSubtitle =>
      '۶ ہندسوں کا تصدیقی کوڈ حاصل کرنے کے لیے اپنا موبائل نمبر درج کریں۔';

  @override
  String get mobileNumberLabel => 'موبائل نمبر';

  @override
  String get mobileNumberHint => '۰۳۰۰ ۱۲۳۴۵۶۷';

  @override
  String get sendVerificationCode => 'تصدیقی کوڈ بھیجیں';

  @override
  String get verifyOtpTitle => 'کوڈ کی تصدیق کریں';

  @override
  String codeSentTo(String phone) {
    return 'کوڈ $phone پر بھیجا گیا ہے۔';
  }

  @override
  String get otpLabel => '۶ ہندسوں کا کوڈ';

  @override
  String get otpHint => '123456';

  @override
  String get verifyAndContinue => 'تصدیق کر کے آگے بڑھیں';

  @override
  String get validPhoneRequired =>
      'درست پاکستانی موبائل نمبر درج کریں (مثلاً 0300 1234567)';

  @override
  String get phoneRequired => 'فون نمبر درج کرنا ضروری ہے';

  @override
  String get validCnicRequired => 'درست ۱۳ ہندسوں کا شناختی کارڈ نمبر درج کریں';

  @override
  String get cnicRequired => 'شناختی کارڈ نمبر درج کرنا ضروری ہے';

  @override
  String get selectRoleTitle => 'کردار کا انتخاب';

  @override
  String get selectRoleHeader =>
      'آپ ٹرک لنک پی کے کس حیثیت سے استعمال کرنا چاہتے ہیں؟';

  @override
  String get driverRole => 'ڈرائیور (ملازمت تلاش کنندہ)';

  @override
  String get driverRoleSubtitle => 'لوڈز، پلوں کے انتباہات اور کرفیو کے اوقات';

  @override
  String get driverRoleDescription =>
      'بہترین کرایے کے لوڈز، پلوں کی محفوظ اونچائی کے الرٹس، شہروں کے کرفیو اوقات اور تصدیق شدہ پروفائل پائیں۔';

  @override
  String get ownerRole => 'گاڑی کا مالک / ٹرانسپورٹر';

  @override
  String get ownerRoleSubtitle => 'لوڈ بک کریں اور جی پی ایس ٹریکنگ کریں';

  @override
  String get ownerRoleDescription =>
      'نیا مال / لوڈ پوسٹ کریں، قریبی تصدیق شدہ ڈرائیورز تلاش کریں اور لائیو جی پی ایس روٹس ٹریک کریں۔';

  @override
  String get driverDashboardTitle => 'Driver Dashboard / ڈرائیور پینل';

  @override
  String get routeIntelligence => 'راستے کی معلومات و الرٹس';

  @override
  String get routeIntelligenceSubtitle =>
      'پلوں کی اونچائی اور محفوظ ترین راستے';

  @override
  String get cityCurfewTimings => 'شہروں میں داخلے کے اوقات';

  @override
  String get cityCurfewSubtitle => 'بڑی گاڑیوں کے داخلے کے اوقات';

  @override
  String get reportRoadHazard => 'سڑک کی خرابی درج کریں';

  @override
  String get reportHazardSubtitle => 'قریبی ڈرائیورز کو خطرات سے آگاہ کریں';

  @override
  String get allAvailableLoads => 'دستیاب لوڈز دیکھیں';

  @override
  String get allLoadsSubtitle => 'کھلی لوڈ مارکیٹ میں تلاش کریں';

  @override
  String get matchedLoadsNearYou => 'آپ کے لیے موزوں قریبی لوڈز';

  @override
  String get criticalLowBridgeAhead => '⚠️ خبردار: آگے کم اونچائی والا پل ہے';

  @override
  String bridgeClearance(String height) {
    return 'پل کی اونچائی: $height فٹ';
  }

  @override
  String truckHeight(String height) {
    return 'آپ کا ٹرک: $height فٹ';
  }

  @override
  String distanceAhead(String distance) {
    return '$distance کلومیٹر آگے';
  }

  @override
  String get recommendedReroute => 'تجویز: بائی پاس کے راستے جائیں';

  @override
  String get tapToRecalculate => 'محفوظ روٹ دوبارہ معلوم کریں';

  @override
  String get availableLoadsTitle => 'دستیاب لوڈز';

  @override
  String get postNewLoad => 'نیا مال / لوڈ بک کریں';

  @override
  String get postLoadSuccess =>
      'لوڈ کامیابی سے پوسٹ ہو گیا! قریبی ڈرائیورز کے لیے تلاش فعال ہو گئی۔';

  @override
  String get pickupLocationLabel => 'روانگی کا مقام و شہر';

  @override
  String get dropoffLocationLabel => 'منزل و ترسیل کا شہر';

  @override
  String get vehicleRequiredLabel => 'گاڑی کی قسم';

  @override
  String get loadWeightLabel => 'وزن (ٹن)';

  @override
  String get truckHeightLabel => 'کل اونچائی (فٹ)';

  @override
  String get offeredRateLabel => 'پیشکش کرایہ (روپے)';

  @override
  String get goodsTypeLabel => 'مال کی قسم';

  @override
  String get goodsGeneral => 'عام سامان';

  @override
  String get goodsTextile => 'ٹیکسٹائل و دھاگہ';

  @override
  String get goodsAgri => 'زرعی اجناس';

  @override
  String get goodsChemical => 'صنعتی و کیمیکل';

  @override
  String get submitLoadButton => 'لوڈ مارکیٹ میں شائع کریں';

  @override
  String get statusOpen => 'دستیاب';

  @override
  String get statusAssigned => 'تفویض شدہ';

  @override
  String get statusInTransit => 'راستے میں';

  @override
  String get statusDelivered => 'پہنچ گیا';

  @override
  String get statusCancelled => 'منسوخ';

  @override
  String get routePlannerTitle => 'روٹ انٹیلیجنس';

  @override
  String get hereTruckProfile => 'HERE ٹرک پروفائل';

  @override
  String get activeConfiguration => 'فعال کنفیگریشن';

  @override
  String get avoidLowBridges => 'کم اونچائی والے پلوں سے بچاؤ';

  @override
  String get avoidLowBridgesDesc =>
      'ٹرک کی اونچائی سے نیچے والے پلوں کا ازخود پتہ لگاتا ہے';

  @override
  String get useMotorwayBypass => 'موٹروے اور بائی پاس کو ترجیح دیں';

  @override
  String get useMotorwayBypassDesc => 'شہری رش اور تنگ سڑکوں سے پرہیز';

  @override
  String get startGpsNavigation => 'جی پی ایس نیویگیشن شروع کریں';

  @override
  String get detectedClearanceAlerts => 'راستے میں شناخت شدہ انتباہات';

  @override
  String get recalculatingOptimalRoute =>
      'محفوظ ترین ٹرک روٹ کا حساب لگایا جا رہا ہے...';

  @override
  String get cityTimingTitle => 'شہروں میں داخلے کے اوقات';

  @override
  String get heavyCurfewHeader => 'بڑی گاڑیوں کے لیے ممنوعہ اوقات';

  @override
  String get curfewExplanation =>
      'یہ اوقات ٹریفک پولیس کے نوٹیفکیشن اور ڈرائیورز کی اطلاعات کے مطابق ہیں تاکہ بھاری چالان سے بچا جا سکے۔';

  @override
  String allowedEntryWindow(String from, String to) {
    return 'داخلے کے کھلے اوقات: $from سے $to';
  }

  @override
  String verifiedConfidence(String percent) {
    return '$percent٪ مصدقہ معلومات';
  }

  @override
  String get selectHazardCategory => 'خرابی یا خطرے کی قسم منتخب کریں';

  @override
  String get exactLocationLabel => 'سڑک کا درست مقام';

  @override
  String get descriptionLabel => 'مزید تفصیلات یا قریبی نشانی';

  @override
  String get descriptionHint =>
      'مثلاً بائیں لین میں گہرا گڑھا، سڑک پر پانی جمع ہے...';

  @override
  String get submitHazardButton => 'خطرے کی اطلاع قریبی ڈرائیورز کو بھیجیں';

  @override
  String get hazardBroadcastSuccess =>
      'اطلاع کامیابی سے جمع ہو گئی اور ۲۰ کلومیٹر کے دائرے میں تمام ڈرائیورز کو الرٹ بھیج دیا گیا!';

  @override
  String get enableAlerts => 'الرٹس آن کریں';

  @override
  String get alertsActive => 'الرٹس فعال ہیں';

  @override
  String get pushNotificationsTitle => 'پش نوٹیفکیشنز';

  @override
  String get notificationsPermissionPrompt =>
      'نئی بولیوں، منظور شدہ آفرز اور سڑک کے خطرات کے فوری براؤزر نوٹیفکیشن آن کریں۔';

  @override
  String get allowNotificationsButton => 'نوٹیفکیشن کی اجازت دیں';

  @override
  String get notificationsEnabledSuccess =>
      'پش نوٹیفکیشن کامیابی سے آن کر دیے گئے!';

  @override
  String get notificationsDenied =>
      'نوٹیفکیشن بلاک ہیں۔ براؤزر کی سیٹنگز سے اجازت دیں۔';

  @override
  String get newBidNotification => 'نئی بولی موصول ہوئی';

  @override
  String get bidAcceptedNotification => 'بولی منظور ہو گئی!';

  @override
  String get roadHazardAlert => 'سڑک پر خطرے کا الرٹ';

  @override
  String get markAsRead => 'پڑھا ہوا نشان زد کریں';

  @override
  String get noNewNotifications => 'کوئی نیا نوٹیفکیشن نہیں';

  @override
  String get safetyAndAlerts => 'حفاظت اور پل الرٹس';

  @override
  String get turnByTurnSteps => 'راستے کی موڑ بہ موڑ ہدایات';

  @override
  String get costAndStops => 'خرچ اور سہولیات';

  @override
  String get liveTraffic => 'لائیو ٹریفک';

  @override
  String get satelliteView => 'سیٹلائٹ';

  @override
  String get normalView => 'سادہ نقشہ';

  @override
  String get criticalClearanceDanger => 'خطرناک کم اونچائی والا پل!';

  @override
  String get clearanceSafe => 'تمام پلوں کی اونچائی محفوظ ہے';

  @override
  String get speakAlert => 'آواز میں سنیں';

  @override
  String get openGpsNavigation => 'گوگل میپس پر نیویگیشن کھولیں';

  @override
  String get destinationCurfew => 'منزل والے شہر میں داخلے کے اوقات';

  @override
  String get noHazardReports => 'اس راستے پر کوئی سڑک کی خرابی رپورٹ نہیں ہوئی';

  @override
  String get noTurnStepsAvailable => 'روٹ کی ہدایات تیار ہیں';

  @override
  String get adminVerificationTitle => 'دستاویزات کی تصدیق و جائزہ';

  @override
  String get pendingReview => 'زیرِ جائزہ';

  @override
  String get verifiedDrivers => 'تصدیق شدہ';

  @override
  String get rejectedDrivers => 'مسترد شدہ';

  @override
  String get approveButton => 'تصدیق کریں';

  @override
  String get rejectButton => 'مسترد کریں';

  @override
  String get rejectionReasonPrompt => 'مسترد کرنے کی وجہ منتخب کریں یا لکھیں';

  @override
  String get reasonBlurryPhoto => 'دستاویز کی تصویر غیر واضح یا دھندلی ہے';

  @override
  String get reasonExpiredLicense => 'ڈرائیونگ لائسنس کی مدت ختم ہو چکی ہے';

  @override
  String get reasonCnicMismatch =>
      'شناختی کارڈ نمبر یا معلومات کا اندراج غلط ہے';

  @override
  String get reasonOther => 'دیگر وجہ';

  @override
  String get enterCustomReason => 'وجہ تحریر کریں...';

  @override
  String get cnicDocument => 'شناختی کارڈ (CNIC)';

  @override
  String get licenseDocument => 'ڈرائیونگ لائسنس (HTV/LTV)';

  @override
  String get registrationDocument => 'گاڑی کی رجسٹریشن بک';

  @override
  String get noPendingDrivers => 'زیرِ جائزہ کوئی ڈرائیور موجود نہیں ہے';

  @override
  String get noVerifiedDrivers => 'کوئی تصدیق شدہ ڈرائیور نہیں ملا';

  @override
  String get noRejectedDrivers => 'کوئی مسترد شدہ ڈرائیور نہیں ہے';

  @override
  String get driverApprovedSuccess =>
      'ڈرائیور کی دستاویزات کامیابی سے منظور ہو گئیں!';

  @override
  String get driverRejectedSuccess =>
      'دستاویزات مسترد کر دی گئیں اور ڈرائیور کو الرٹ بھیج دیا گیا۔';

  @override
  String get adminPanel => 'ایڈمن پینل';

  @override
  String get adminVerification => 'دستاویزات کی تصدیق';

  @override
  String get toggleAdminMode => 'ایڈمن موڈ تبدیل کریں';
}
