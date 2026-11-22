// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

Future<bool> appLauncherOpenUrl(String url) async {
  try {
    html.window.open(url, '_blank');
    return true;
  } catch (_) {
    return false;
  }
}

Future<bool> appLauncherMakeCall(String phone) async {
  try {
    final clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    html.window.location.href = 'tel:$clean';
    return true;
  } catch (_) {
    return false;
  }
}

Future<bool> appLauncherOpenWhatsApp({
  required String phone,
  required String message,
}) async {
  try {
    var clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.startsWith('0')) {
      clean = '92${clean.substring(1)}';
    }
    final encoded = Uri.encodeComponent(message);
    final url = 'https://wa.me/$clean?text=$encoded';
    html.window.open(url, '_blank');
    return true;
  } catch (_) {
    return false;
  }
}
