class HereConfig {
  HereConfig._();

  static const String accessKeyId = String.fromEnvironment(
    'HERE_ACCESS_KEY_ID',
    defaultValue: 'HERE_DEV_KEY_ID',
  );

  static const String accessKeySecret = String.fromEnvironment(
    'HERE_ACCESS_KEY_SECRET',
    defaultValue: 'HERE_DEV_KEY_SECRET',
  );
}

class TplConfig {
  TplConfig._();

  static const String apiKey = String.fromEnvironment(
    'TPL_MAPS_API_KEY',
    defaultValue: 'TPL_DEV_API_KEY',
  );
}
