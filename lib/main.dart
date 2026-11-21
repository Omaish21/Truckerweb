import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'core/config/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase initialization (safe fallback for offline & dev mode)
  try {
    if (SupabaseConfig.url.isNotEmpty &&
        SupabaseConfig.anonKey.isNotEmpty &&
        !SupabaseConfig.anonKey.contains('dummy')) {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        // ignore: deprecated_member_use
        anonKey: SupabaseConfig.anonKey,
      );
    }
  } catch (e) {
    debugPrint('Supabase initialization skipped / fallback to local mode: $e');
  }

  runApp(
    const ProviderScope(
      child: TruckLinkApp(),
    ),
  );
}
