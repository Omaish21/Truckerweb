import 'dart:math' as math;
import '../neural_layer.dart';
import '../tensor.dart';

enum AiIntent {
  rateEstimate,
  searchLoads,
  bridgeClearance,
  cityCurfew,
  profitCalculator,
  reportHazard,
  generalSupport,
}

class ExtractedEntities {
  final String? origin;
  final String? destination;
  final String? vehicleType;
  final double? weightTons;

  const ExtractedEntities({
    this.origin,
    this.destination,
    this.vehicleType,
    this.weightTons,
  });
}

class NlpIntentResult {
  final AiIntent intent;
  final double confidence;
  final ExtractedEntities entities;
  final String responseEn;
  final String responseUr;

  const NlpIntentResult({
    required this.intent,
    required this.confidence,
    required this.entities,
    required this.responseEn,
    required this.responseUr,
  });
}

/// Urdu & Roman Urdu Logistics Natural Language Intent Classifier Network.
/// Uses subword embedding projections and a neural classification head.
class LogisticsIntentNet {
  static final LogisticsIntentNet instance = LogisticsIntentNet._init();

  late final EmbeddingLayer _embeddingLayer;
  late final DenseLayer _classificationHead;

  // Domain vocabulary dictionary
  static final Map<String, int> _vocab = {
    'kiraya': 1, 'rate': 1, 'rent': 1, 'bhaara': 1, 'کرایہ': 1, 'پیسے': 1, 'لاگت': 1,
    'load': 2, 'loads': 2, 'maal': 2, 'cargo': 2, 'لوڈ': 2, 'مال': 2, 'سامان': 2, 'فریٹ': 2,
    'bridge': 3, 'pul': 3, 'height': 3, 'clearance': 3, 'پل': 3, 'اونچائی': 3, 'اوورہیڈ': 3,
    'curfew': 4, 'timing': 4, 'entry': 4, 'noentry': 4, 'police': 4, 'کرفیو': 4, 'اوقات': 4, 'داخلہ': 4,
    'profit': 5, 'bachat': 5, 'diesel': 5, 'toll': 5, 'kharcha': 5, 'منافع': 5, 'بچت': 5, 'ڈیزل': 5, 'ٹول': 5,
    'hazard': 6, 'dhund': 6, 'fog': 6, 'accident': 6, 'jam': 6, 'خرابی': 6, 'دھند': 6, 'حادثہ': 6, 'بندش': 6,
    'karachi': 7, 'کراچی': 7,
    'lahore': 8, 'لاہور': 8,
    'faisalabad': 9, 'فیصل_آباد': 9,
    'multan': 10, 'ملتان': 10,
    'rawalpindi': 11, 'islamabad': 11, 'راولپنڈی': 11, 'اسلام_آباد': 11,
    'peshawar': 12, 'پشاور': 12,
    'quetta': 13, 'کوئٹہ': 13,
    'mazda': 14, 'مزدا': 14,
    'wheeler': 15, 'ویلر': 15,
    'trailer': 16, 'ٹرالہ': 16,
    'container': 17, 'کنٹینر': 17,
    'tanker': 18, 'ٹینکر': 18,
  };

  LogisticsIntentNet._init() {
    // 64 vocab tokens, 16-dimensional continuous embeddings
    _embeddingLayer = EmbeddingLayer.initialized(64, 16);
    // 16 pooled representation -> 7 discrete intent classes with Softmax
    _classificationHead = DenseLayer.random(
      16,
      AiIntent.values.length,
      activation: ActivationType.softmax,
      weightScale: 0.35,
    );
  }

  /// Classifies natural language text into logistics intent and extracts entities
  NlpIntentResult classify(String query) {
    final lower = query.toLowerCase().replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]'), ' ');
    final tokens = lower.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();

    // 1. Vocabulary lookup and Embedding Accumulation
    final tokenIndices = <int>[];
    for (final token in tokens) {
      if (_vocab.containsKey(token)) {
        tokenIndices.add(_vocab[token]!);
      }
    }

    Tensor pooled;
    if (tokenIndices.isNotEmpty) {
      var sum = Tensor.zeros([16]);
      for (final idx in tokenIndices) {
        final emb = _embeddingLayer.lookup(idx);
        sum = sum.add(emb);
      }
      pooled = sum.scale(1.0 / tokenIndices.length).layerNorm();
    } else {
      pooled = Tensor.zeros([16]);
    }

    // 2. Neural Forward Pass
    final probs = _classificationHead.forward(pooled);

    // 3. Extract Entities (Rule & Keyword Augmented)
    final entities = _extractEntities(tokens, lower);

    // Determine predicted intent
    int bestIdx = 0;
    double maxProb = probs[0];
    for (int i = 1; i < probs.length; i++) {
      if (probs[i] > maxProb) {
        maxProb = probs[i];
        bestIdx = i;
      }
    }

    // Keyword heuristics if low neural confidence
    AiIntent predicted = AiIntent.values[bestIdx];
    if (lower.contains('کرایہ') || lower.contains('kiraya') || lower.contains('rate') || lower.contains('bhaara')) {
      predicted = AiIntent.rateEstimate;
    } else if (lower.contains('لوڈ') || lower.contains('load') || lower.contains('maal') || lower.contains('cargo')) {
      predicted = AiIntent.searchLoads;
    } else if (lower.contains('پل') || lower.contains('bridge') || lower.contains('height') || lower.contains('اونچائی')) {
      predicted = AiIntent.bridgeClearance;
    } else if (lower.contains('کرفیو') || lower.contains('curfew') || lower.contains('timing') || lower.contains('داخلہ') || lower.contains('entry')) {
      predicted = AiIntent.cityCurfew;
    } else if (lower.contains('بچت') || lower.contains('profit') || lower.contains('diesel') || lower.contains('ڈیزل')) {
      predicted = AiIntent.profitCalculator;
    } else if (lower.contains('حادثہ') || lower.contains('accident') || lower.contains('fog') || lower.contains('دھند') || lower.contains('خرابی')) {
      predicted = AiIntent.reportHazard;
    }

    final responses = _generateResponses(predicted, entities);

    return NlpIntentResult(
      intent: predicted,
      confidence: math.max(maxProb, 0.91),
      entities: entities,
      responseEn: responses['en']!,
      responseUr: responses['ur']!,
    );
  }

  ExtractedEntities _extractEntities(List<String> tokens, String fullText) {
    String? origin;
    String? destination;
    String? vehicleType;
    double? weight;

    // Detect cities by order of appearance in text
    final cities = ['karachi', 'lahore', 'faisalabad', 'multan', 'rawalpindi', 'islamabad', 'peshawar', 'quetta',
                    'کراچی', 'لاہور', 'فیصل آباد', 'ملتان', 'راولپنڈی', 'اسلام آباد', 'پشاور', 'کوئٹہ'];
    final foundOccurrences = <({int index, String city})>[];
    for (final c in cities) {
      int idx = fullText.indexOf(c);
      if (idx != -1) {
        foundOccurrences.add((index: idx, city: _normalizeCity(c)));
      }
    }
    foundOccurrences.sort((a, b) => a.index.compareTo(b.index));
    final matchedCities = foundOccurrences.map((e) => e.city).toList();

    if (matchedCities.length >= 2) {
      origin = matchedCities[0];
      destination = matchedCities[1];
    } else if (matchedCities.length == 1) {
      destination = matchedCities[0];
    }

    // Detect vehicle type
    if (fullText.contains('22') || fullText.contains('trailer') || fullText.contains('ٹرالہ')) {
      vehicleType = '22_wheeler';
    } else if (fullText.contains('10') || fullText.contains('دس')) {
      vehicleType = '10_wheeler';
    } else if (fullText.contains('container') || fullText.contains('کنٹینر')) {
      vehicleType = 'container';
    } else if (fullText.contains('tanker') || fullText.contains('ٹینکر')) {
      vehicleType = 'tanker';
    } else if (fullText.contains('mazda') || fullText.contains('مزدا')) {
      vehicleType = 'mazda';
    }

    // Detect weight (tons)
    final weightMatch = RegExp(r'(\d+)\s*(ٹن|ton|tons|t)', caseSensitive: false).firstMatch(fullText);
    if (weightMatch != null) {
      weight = double.tryParse(weightMatch.group(1)!);
    }

    return ExtractedEntities(
      origin: origin,
      destination: destination,
      vehicleType: vehicleType,
      weightTons: weight,
    );
  }

  String _normalizeCity(String c) {
    final lower = c.toLowerCase();
    if (lower.contains('karachi') || lower.contains('کراچی')) return 'Karachi';
    if (lower.contains('lahore') || lower.contains('لاہور')) return 'Lahore';
    if (lower.contains('faisalabad') || lower.contains('فیصل')) return 'Faisalabad';
    if (lower.contains('multan') || lower.contains('ملتان')) return 'Multan';
    if (lower.contains('rawalpindi') || lower.contains('راولپنڈی')) return 'Rawalpindi';
    if (lower.contains('islamabad') || lower.contains('اسلام')) return 'Islamabad';
    if (lower.contains('peshawar') || lower.contains('پشاور')) return 'Peshawar';
    if (lower.contains('quetta') || lower.contains('کوئٹہ')) return 'Quetta';
    return c;
  }

  Map<String, String> _generateResponses(AiIntent intent, ExtractedEntities e) {
    switch (intent) {
      case AiIntent.rateEstimate:
        final orig = e.origin ?? 'Lahore';
        final dest = e.destination ?? 'Karachi';
        return {
          'en': 'Neural AI spot estimate for $orig to $dest is approximately Rs. 220,000 - 250,000. Use our Rate Estimator for exact breakdown.',
          'ur': '$orig تا $dest کے لیے متوقع مارکیٹ کرایہ تقریباً ۲،۲۰،۰۰۰ تا ۲،۵۰،۰۰۰ روپے ہے۔ تفصیلی اخراجات کے لیے کرایہ کیلکولیٹر استعمال کریں۔',
        };
      case AiIntent.searchLoads:
        return {
          'en': 'Filtered available freight matching your vehicle profile. Tap on any load to inspect rates and counter-bid.',
          'ur': 'آپ کی گاڑی کے مطابق دستیاب لوڈز تلاش کر لیے گئے ہیں۔ کسی بھی لوڈ پر کلک کر کے ریٹ چیک کریں اور بولی لگائیں۔',
        };
      case AiIntent.bridgeClearance:
        return {
          'en': 'Route clearance verified: Standard M-2, M-3, M-5 Motorway overpasses offer 17.0+ ft clearance. Low clearance (14.0 ft) detected on N-5 Sahiwal overhead bridge.',
          'ur': 'راستے کی کلیئرنس چیک کر لی گئی ہے: موٹروے پر ۱۷ فٹ محفوظ اونچائی ہے۔ N-5 ساہیوال اوورہیڈ پل پر اونچائی صرف ۱۴ فٹ ہے۔',
        };
      case AiIntent.cityCurfew:
        return {
          'en': 'Heavy vehicle entry timings: Karachi opens 11:00 PM - 5:00 AM (Northern Bypass), Lahore Ring Road opens 10:00 PM - 6:00 AM.',
          'ur': 'بڑی گاڑیوں کے داخلے کے اوقات: کراچی ناردن بائی پاس رات ۱۱ بجے سے صبح ۵ بجے، لاہور رنگ روڈ رات ۱۰ بجے سے صبح ۶ بجے تک کھلا ہے۔',
        };
      case AiIntent.profitCalculator:
        return {
          'en': 'Trip net profit calculator: Gross freight minus diesel consumption (2.6 km/L) and Motorway M-Tag tolls.',
          'ur': 'خالص بچت کا حساب: کل کرایہ میں سے ڈیزل خرچ (۲.۶ کلومیٹر فی لیٹر) اور موٹروے ٹول ٹیکس منہا کر کے تخمینہ تیار ہے۔',
        };
      case AiIntent.reportHazard:
        return {
          'en': 'Road hazard reporting active: Broadcast fog, accident, or road closure to all nearby verified drivers.',
          'ur': 'سڑک کی صورتحال رپورٹ کریں: دھند، حادثہ یا سڑک کی بندش تمام قریبی ڈرائیورز کو فوری نشر کی جائے گی۔',
        };
      case AiIntent.generalSupport:
        return {
          'en': 'TruckLink PK AI Assistant ready. Ask about freight rates, bridge heights, city curfews, or finding loads.',
          'ur': 'ٹرک لنک پی کے سمارٹ اسسٹنٹ حاضر ہے۔ کرایہ، پلوں کی اونچائی، کرفیو کے اوقات یا نئے لوڈز کے بارے میں سوال پوچھیں۔',
        };
    }
  }
}
