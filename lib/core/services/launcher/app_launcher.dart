import 'app_launcher_stub.dart'
    if (dart.library.html) 'app_launcher_web.dart';

class AppLauncher {
  static Future<bool> openUrl(String url) => appLauncherOpenUrl(url);

  static Future<bool> makeCall(String phone) => appLauncherMakeCall(phone);

  static Future<bool> openWhatsApp({
    required String phone,
    required String message,
  }) =>
      appLauncherOpenWhatsApp(phone: phone, message: message);
}
