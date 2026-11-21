class TranslationService {
  static final TranslationService _instance = TranslationService._internal();
  factory TranslationService() => _instance;
  TranslationService._internal();

  // In-memory cache for translated strings: key is "$text-$targetLang"
  final Map<String, String> _cache = {};

  // High-accuracy Pakistani logistics bilingual terminology lookup
  static final Map<String, String> _enToUrDict = {
    'general cargo': 'عام سامان / مال',
    'general': 'عام مال',
    'textile yarn': 'سوتی دھاگہ',
    'textile': 'ٹیکسٹائل / کپڑا',
    'agricultural produce': 'زرعی اجناس / فصل',
    'agri': 'زرعی اجناس',
    'industrial solvents': 'صنعتی کیمیکل',
    'chemical': 'کیمیکل',
    'broken road': 'ٹوٹی ہوئی سڑک / کھڈے',
    'potholes on highway': 'ہائی وے پر گہرے کھڈے',
    'fog': 'شدید دھند',
    'dense fog on motorway': 'موٹروے پر شدید دھند، حد نگاہ کم',
    'flooded': 'سیلابی پانی / روڈ بند',
    'landslide': 'لینڈ سلائیڈنگ / پہاڑی تودہ',
    'protest': 'احتجاج / دھرنا / سڑک بند',
    'accident': 'حادثہ / ٹریفک جام',
    'weigh station': 'کانٹا / وزن کا کانٹا',
    'bridge clearance': 'پل کی اونچائی',
    'low bridge': 'کم اونچائی والا پل',
    'caution': 'احتیاط فرمائیں',
  };

  static final Map<String, String> _urToEnDict = {
    'عام سامان': 'General Cargo',
    'عام مال': 'General Cargo',
    'سوتی دھاگہ': 'Textile Yarn',
    'ٹیکسٹائل': 'Textiles',
    'زرعی اجناس': 'Agricultural Produce',
    'صنعتی کیمیکل': 'Industrial Solvents',
    'کیمیکل': 'Chemicals',
    'ٹوٹی ہوئی سڑک': 'Broken Road / Potholes',
    'کھڈے': 'Potholes',
    'شدید دھند': 'Dense Fog on Road',
    'دھند': 'Fog',
    'سیلابی پانی': 'Flooded Road',
    'لینڈ سلائیڈنگ': 'Landslide Blockage',
    'احتجاج': 'Protest / Roadblock',
    'حادثہ': 'Traffic Accident / Congestion',
    'کانٹا': 'Weigh Station',
  };

  String translate({required String text, required String targetLanguageCode}) {
    if (text.trim().isEmpty) return text;
    final cacheKey = '${text.trim().toLowerCase()}_$targetLanguageCode';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    String result = text;
    final clean = text.trim().toLowerCase();

    if (targetLanguageCode == 'ur') {
      // English to Urdu lookup
      for (final entry in _enToUrDict.entries) {
        if (clean.contains(entry.key)) {
          result = result.replaceAll(RegExp(entry.key, caseSensitive: false), entry.value);
        }
      }
      if (result == text) {
        result = '$text (ترجمہ: پاکستانی مال برداری تفصیل)';
      }
    } else {
      // Urdu to English lookup
      for (final entry in _urToEnDict.entries) {
        if (text.contains(entry.key)) {
          result = result.replaceAll(entry.key, entry.value);
        }
      }
      if (result == text) {
        result = '$text (Translated: Pakistani Cargo Notes)';
      }
    }

    _cache[cacheKey] = result;
    return result;
  }
}
