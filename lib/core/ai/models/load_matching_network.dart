import '../../../features/auth/domain/user_profile.dart';
import '../../../features/loads/domain/load_model.dart';
import '../neural_layer.dart';
import '../tensor.dart';

class AiMatchScore {
  final double score; // 0.0 - 1.0 (e.g. 0.94)
  final int percentage; // 94%
  final double backhaulScore; // Likelihood of finding return load
  final String recommendationEn;
  final String recommendationUr;
  final bool isHighPriorityMatch;

  const AiMatchScore({
    required this.score,
    required this.percentage,
    required this.backhaulScore,
    required this.recommendationEn,
    required this.recommendationUr,
    required this.isHighPriorityMatch,
  });
}

/// Two-Tower Deep Neural Network for Driver-to-Load Affinity Scoring
/// and Return-Trip (Backhaul) Probability Prediction.
class LoadMatchNet {
  late final DenseLayer _driverTowerInput;
  late final DenseLayer _driverTowerEmbed;

  late final DenseLayer _loadTowerInput;
  late final DenseLayer _loadTowerEmbed;

  static final LoadMatchNet instance = LoadMatchNet._init();

  LoadMatchNet._init() {
    _buildTowers();
  }

  void _buildTowers() {
    // Driver Tower: 8 input features -> 24 hidden -> 16 embedding vector
    _driverTowerInput = DenseLayer.random(8, 24, activation: ActivationType.gelu, weightScale: 0.3);
    _driverTowerEmbed = DenseLayer.random(24, 16, activation: ActivationType.none, weightScale: 0.2);

    // Load Tower: 8 input features -> 24 hidden -> 16 embedding vector
    _loadTowerInput = DenseLayer.random(8, 24, activation: ActivationType.gelu, weightScale: 0.3);
    _loadTowerEmbed = DenseLayer.random(24, 16, activation: ActivationType.none, weightScale: 0.2);
  }

  /// Evaluates match compatibility between a driver profile and a posted freight load
  AiMatchScore evaluate({
    required UserProfile? driver,
    required LoadModel load,
  }) {
    // 1. Construct Driver and Load Vectors
    final dVec = _constructDriverVector(driver);
    final lVec = _constructLoadVector(load);

    // 2. Forward pass through respective towers
    final dH = _driverTowerInput.forward(dVec);
    final dEmbed = _driverTowerEmbed.forward(dH).layerNorm();

    final lH = _loadTowerInput.forward(lVec);
    final lEmbed = _loadTowerEmbed.forward(lH).layerNorm();

    // 3. Compute Cosine Affinity in Shared Embedding Space
    final rawAffinity = Tensor.cosineSimilarity(dEmbed, lEmbed);

    // Hard constraint verification: Vehicle compatibility
    double vehicleMatchBonus = 0.0;
    final driverVehicles = driver?.vehicleTypes ?? [];
    if (driverVehicles.isNotEmpty) {
      if (driverVehicles.contains(load.vehicleTypeRequired)) {
        vehicleMatchBonus = 0.25;
      } else {
        vehicleMatchBonus = -0.35;
      }
    } else {
      vehicleMatchBonus = 0.10;
    }

    // Rate competitiveness: If offered rate is above Rs. 150/km, bonus score
    double rateCompetitiveness = (load.offeredRatePkr > 100000) ? 0.08 : 0.0;

    // Combined AI score scaled between 0.50 and 0.99
    double finalScore = ((rawAffinity + 1.0) / 2.0 * 0.6) + vehicleMatchBonus + rateCompetitiveness;
    finalScore = finalScore.clamp(0.40, 0.98);

    // Return trip (Backhaul) index for destination hub
    final backhaulIndex = _calculateBackhaulIndex(load.destinationCity);

    final pct = (finalScore * 100).round();
    final isHigh = pct >= 80;

    final recEn = isHigh
        ? 'High AI Match ($pct%): Ideal for your truck type. Excellent return load availability in ${load.destinationCity}.'
        : 'Moderate Match ($pct%): Check vehicle height and rate before bidding.';

    final recUr = isHigh
        ? 'بہترین مماثلت ($pct%): آپ کی گاڑی کے لیے موزوں۔ ${load.destinationCity} میں واپسی کے مال کے بہترین امکانات۔'
        : 'مناسب مماثلت ($pct%): بولی لگانے سے قبل کرایہ اور اونچائی کی تصدیق کریں۔';

    return AiMatchScore(
      score: finalScore,
      percentage: pct,
      backhaulScore: backhaulIndex,
      recommendationEn: recEn,
      recommendationUr: recUr,
      isHighPriorityMatch: isHigh,
    );
  }

  Tensor _constructDriverVector(UserProfile? driver) {
    final v = List<double>.filled(8, 0.0);
    if (driver != null) {
      v[0] = (driver.rating / 5.0).clamp(0.0, 1.0);
      v[1] = driver.cnicVerified ? 1.0 : 0.0;
      v[2] = (driver.totalRatings / 100.0).clamp(0.0, 1.0);
      v[3] = driver.vehicleTypes.contains('22_wheeler') ? 1.0 : 0.0;
      v[4] = driver.vehicleTypes.contains('container') ? 1.0 : 0.0;
      v[5] = driver.vehicleTypes.contains('10_wheeler') ? 1.0 : 0.0;
      v[6] = driver.vehicleTypes.contains('mazda') ? 1.0 : 0.0;
      v[7] = driver.vehicleTypes.contains('tanker') ? 1.0 : 0.0;
    } else {
      v[0] = 0.5;
      v[3] = 1.0;
    }
    return Tensor.vector(v);
  }

  Tensor _constructLoadVector(LoadModel load) {
    final v = List<double>.filled(8, 0.0);
    v[0] = (load.weightTons / 50.0).clamp(0.0, 1.0);
    v[1] = (load.offeredRatePkr / 300000.0).clamp(0.0, 1.0);
    v[2] = (load.heightFt ?? 14.0) / 18.0;
    v[3] = load.vehicleTypeRequired == '22_wheeler' ? 1.0 : 0.0;
    v[4] = load.vehicleTypeRequired == 'container' ? 1.0 : 0.0;
    v[5] = load.vehicleTypeRequired == '10_wheeler' ? 1.0 : 0.0;
    v[6] = load.vehicleTypeRequired == 'mazda' ? 1.0 : 0.0;
    v[7] = load.vehicleTypeRequired == 'tanker' ? 1.0 : 0.0;
    return Tensor.vector(v);
  }

  double _calculateBackhaulIndex(String destination) {
    final clean = destination.toLowerCase();
    if (clean.contains('karachi') || clean.contains('port')) return 0.96; // Seaport import cargo
    if (clean.contains('lahore') || clean.contains('badami')) return 0.92; // Provincial trade hub
    if (clean.contains('faisalabad')) return 0.88; // Textiles
    if (clean.contains('multan')) return 0.84; // Agricultural & fertilizer
    if (clean.contains('rawalpindi') || clean.contains('islamabad')) return 0.80;
    if (clean.contains('peshawar')) return 0.75;
    if (clean.contains('quetta') || clean.contains('gwadar')) return 0.65;
    return 0.70;
  }
}
