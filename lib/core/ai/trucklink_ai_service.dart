import '../../features/auth/domain/user_profile.dart';
import '../../features/loads/domain/load_model.dart';
import '../services/geocoding_service.dart';
import 'models/intent_classification_network.dart';
import 'models/load_matching_network.dart';
import 'models/rate_prediction_network.dart';
import 'trainer/neural_trainer.dart';

/// Central AI Orchestration Service for TruckLink PK.
/// Powered entirely by bespoke client-side neural networks.
class TruckLinkAiService {
  static final TruckLinkAiService instance = TruckLinkAiService._internal();
  factory TruckLinkAiService() => instance;
  TruckLinkAiService._internal();

  final _rateNet = PakFreightRateNet.instance;
  final _matchNet = LoadMatchNet.instance;
  final _intentNet = LogisticsIntentNet.instance;

  bool _isTrained = false;
  TrainingMetrics? _lastTrainingMetrics;

  bool get isTrained => _isTrained;
  TrainingMetrics? get lastTrainingMetrics => _lastTrainingMetrics;

  /// Predict fair market freight rate in PKR
  RatePredictionResult predictRate({
    required String origin,
    required String destination,
    required double weightTons,
    required String vehicleType,
    String goodsType = 'general',
    bool isMotorway = true,
    double dieselPricePerLiter = 285.0,
  }) {
    // Estimate distance via Geocoding coordinates if not specified
    final origCoord = GeocodingService.instance.getKnownCoordinates(origin);
    final destCoord = GeocodingService.instance.getKnownCoordinates(destination);

    double distanceKm = 1205.0; // Default Karachi-Lahore
    if (origCoord != null && destCoord != null) {
      distanceKm = GeocodingService.calculateDistanceKm(origCoord, destCoord) * 1.25; // 25% road winding factor
    }

    return _rateNet.predict(
      distanceKm: distanceKm,
      weightTons: weightTons,
      vehicleType: vehicleType,
      goodsType: goodsType,
      isMotorway: isMotorway,
      dieselPricePerLiter: dieselPricePerLiter,
    );
  }

  /// Evaluates two-tower neural compatibility between Driver and Load
  AiMatchScore matchDriverToLoad({
    required UserProfile? driver,
    required LoadModel load,
  }) {
    return _matchNet.evaluate(driver: driver, load: load);
  }

  /// Natural Language understanding in Urdu / Roman Urdu
  NlpIntentResult queryAssistant(String query) {
    return _intentNet.classify(query);
  }

  /// Runs in-engine neural training / calibration
  Future<TrainingMetrics> trainNetwork({int epochs = 15}) async {
    final metrics = await NeuralTrainer.trainRateModel(epochs: epochs);
    _isTrained = true;
    _lastTrainingMetrics = metrics;
    return metrics;
  }
}
