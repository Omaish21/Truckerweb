class SupabaseConfig {
  SupabaseConfig._();

  // Supabase project credentials (can be overridden via environment variables or settings)
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://trucklink-demo.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.dummy_anon_key_for_offline_and_dev_builds',
  );
}
