/// Dataset representing Pakistani domestic freight tariffs, historical corridor rates,
/// vehicle fuel economics, and route terrain characteristics.
class FreightTrainingSample {
  final String origin;
  final String destination;
  final double distanceKm;
  final String vehicleType;
  final double weightTons;
  final String goodsType;
  final bool isMotorway;
  final double dieselPricePerLiter;
  final double actualRatePkr;

  const FreightTrainingSample({
    required this.origin,
    required this.destination,
    required this.distanceKm,
    required this.vehicleType,
    required this.weightTons,
    required this.goodsType,
    required this.isMotorway,
    required this.dieselPricePerLiter,
    required this.actualRatePkr,
  });
}

class PakistanFreightDataset {
  /// Base spot market observations across major Pakistani trade corridors
  static const List<FreightTrainingSample> trainingSamples = [
    // Karachi to Lahore (Long-Haul Trunk Line N-5 / M-5)
    FreightTrainingSample(origin: 'Karachi', destination: 'Lahore', distanceKm: 1205, vehicleType: '22_wheeler', weightTons: 35.0, goodsType: 'general', isMotorway: true, dieselPricePerLiter: 285.0, actualRatePkr: 245000),
    FreightTrainingSample(origin: 'Karachi', destination: 'Lahore', distanceKm: 1180, vehicleType: '22_wheeler', weightTons: 38.0, goodsType: 'industrial', isMotorway: false, dieselPricePerLiter: 285.0, actualRatePkr: 235000),
    FreightTrainingSample(origin: 'Karachi', destination: 'Lahore', distanceKm: 1205, vehicleType: 'container', weightTons: 28.0, goodsType: 'general', isMotorway: true, dieselPricePerLiter: 285.0, actualRatePkr: 260000),
    FreightTrainingSample(origin: 'Karachi', destination: 'Lahore', distanceKm: 1205, vehicleType: '10_wheeler', weightTons: 16.0, goodsType: 'textiles', isMotorway: true, dieselPricePerLiter: 285.0, actualRatePkr: 165000),
    FreightTrainingSample(origin: 'Karachi', destination: 'Lahore', distanceKm: 1205, vehicleType: 'mazda', weightTons: 7.0, goodsType: 'general', isMotorway: true, dieselPricePerLiter: 285.0, actualRatePkr: 95000),

    // Lahore to Karachi (Agricultural & Industrial Export Transit)
    FreightTrainingSample(origin: 'Lahore', destination: 'Karachi', distanceKm: 1205, vehicleType: '22_wheeler', weightTons: 35.0, goodsType: 'agricultural', isMotorway: true, dieselPricePerLiter: 285.0, actualRatePkr: 220000),
    FreightTrainingSample(origin: 'Lahore', destination: 'Karachi', distanceKm: 1205, vehicleType: 'tanker', weightTons: 40.0, goodsType: 'petroleum', isMotorway: true, dieselPricePerLiter: 285.0, actualRatePkr: 310000),

    // Faisalabad to Karachi (Textile Corridor)
    FreightTrainingSample(origin: 'Faisalabad', destination: 'Karachi', distanceKm: 1120, vehicleType: '22_wheeler', weightTons: 32.0, goodsType: 'textiles', isMotorway: true, dieselPricePerLiter: 285.0, actualRatePkr: 230000),
    FreightTrainingSample(origin: 'Faisalabad', destination: 'Rawalpindi', distanceKm: 310, vehicleType: '10_wheeler', weightTons: 16.0, goodsType: 'textiles', isMotorway: true, dieselPricePerLiter: 285.0, actualRatePkr: 85000),

    // Multan Corridor (Cotton, Mangoes, Fertilizers)
    FreightTrainingSample(origin: 'Multan', destination: 'Karachi', distanceKm: 890, vehicleType: '22_wheeler', weightTons: 35.0, goodsType: 'agricultural', isMotorway: true, dieselPricePerLiter: 285.0, actualRatePkr: 195000),
    FreightTrainingSample(origin: 'Multan', destination: 'Lahore', distanceKm: 340, vehicleType: '10_wheeler', weightTons: 18.0, goodsType: 'fertilizer', isMotorway: true, dieselPricePerLiter: 285.0, actualRatePkr: 72000),
    FreightTrainingSample(origin: 'Multan', destination: 'Quetta', distanceKm: 610, vehicleType: '22_wheeler', weightTons: 30.0, goodsType: 'agricultural', isMotorway: false, dieselPricePerLiter: 285.0, actualRatePkr: 190000),

    // Rawalpindi / Islamabad to Peshawar
    FreightTrainingSample(origin: 'Rawalpindi', destination: 'Peshawar', distanceKm: 175, vehicleType: 'mazda', weightTons: 6.5, goodsType: 'general', isMotorway: true, dieselPricePerLiter: 285.0, actualRatePkr: 38000),
    FreightTrainingSample(origin: 'Rawalpindi', destination: 'Peshawar', distanceKm: 175, vehicleType: '10_wheeler', weightTons: 15.0, goodsType: 'construction', isMotorway: true, dieselPricePerLiter: 285.0, actualRatePkr: 55000),

    // CPEC / Northern Corridor (Salt Range & Mountain Slopes)
    FreightTrainingSample(origin: 'Rawalpindi', destination: 'Gilgit', distanceKm: 510, vehicleType: '10_wheeler', weightTons: 14.0, goodsType: 'provisions', isMotorway: false, dieselPricePerLiter: 285.0, actualRatePkr: 145000),
    FreightTrainingSample(origin: 'Lahore', destination: 'Peshawar', distanceKm: 485, vehicleType: '22_wheeler', weightTons: 34.0, goodsType: 'industrial', isMotorway: true, dieselPricePerLiter: 285.0, actualRatePkr: 115000),
  ];
}
