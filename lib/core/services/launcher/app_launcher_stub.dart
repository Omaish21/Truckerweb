import 'package:flutter/foundation.dart';

Future<bool> appLauncherOpenUrl(String url) async {
  debugPrint('[AppLauncher Stub] Opening URL: $url');
  return true;
}

Future<bool> appLauncherMakeCall(String phone) async {
  final clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
  debugPrint('[AppLauncher Stub] Dialing phone: $clean');
  return true;
}

Future<bool> appLauncherOpenWhatsApp({
  required String phone,
  required String message,
}) async {
  debugPrint('[AppLauncher Stub] Opening WhatsApp for $phone: $message');
  return true;
}
