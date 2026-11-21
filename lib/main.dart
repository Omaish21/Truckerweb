import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'core/config/supabase_config.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase initialization & offline persistence (web / multi-platform)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
    );
  } catch (e) {
    debugPrint('Firebase initialization skipped / error: $e');
  }

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
