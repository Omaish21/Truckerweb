class VehicleType {
  final String id;
  final String nameEn;
  final String nameUr;
  final double typicalCapacityTons;
  final double standardHeightFt;
  final double standardHeightM;
  final double grossWeightLimitTons;

  const VehicleType({
    required this.id,
    required this.nameEn,
    required this.nameUr,
    required this.typicalCapacityTons,
    required this.standardHeightFt,
    required this.standardHeightM,
    required this.grossWeightLimitTons,
  });

  static const List<VehicleType> all = [
    VehicleType(
      id: 'mazda',
      nameEn: 'Mazda / Light Truck',
      nameUr: 'مزدا / ہلکا ٹرک',
      typicalCapacityTons: 5.0,
      standardHeightFt: 10.5,
      standardHeightM: 3.2,
      grossWeightLimitTons: 8.5,
    ),
    VehicleType(
      id: '10_wheeler',
      nameEn: '10-Wheeler Truck',
      nameUr: '۱۰ ویلر ٹرک',
      typicalCapacityTons: 16.0,
      standardHeightFt: 12.5,
      standardHeightM: 3.81,
      grossWeightLimitTons: 28.0,
    ),
    VehicleType(
      id: '22_wheeler',
      nameEn: '22-Wheeler (Trolley)',
      nameUr: '۲۲ ویلر ٹرالہ',
      typicalCapacityTons: 35.0,
      standardHeightFt: 14.8,
      standardHeightM: 4.51,
      grossWeightLimitTons: 48.0,
    ),
    VehicleType(
      id: 'container',
      nameEn: '40ft High-Cube Container Carrier',
      nameUr: 'ہائی کیوب کنٹینر کیریئر',
      typicalCapacityTons: 30.0,
      standardHeightFt: 15.8,
      standardHeightM: 4.82,
      grossWeightLimitTons: 45.0,
    ),
    VehicleType(
      id: 'tanker',
      nameEn: 'Oil / Chemical Tanker',
      nameUr: 'آئل / کیمیکل ٹینکر',
      typicalCapacityTons: 40.0,
      standardHeightFt: 12.0,
      standardHeightM: 3.65,
      grossWeightLimitTons: 44.0,
    ),
    VehicleType(
      id: 'flatbed',
      nameEn: 'Flatbed Trailer',
      nameUr: 'فلیٹ بیڈ ٹریلر',
      typicalCapacityTons: 32.0,
      standardHeightFt: 13.5,
      standardHeightM: 4.11,
      grossWeightLimitTons: 40.0,
    ),
    VehicleType(
      id: 'dumper',
      nameEn: 'Dumper Truck',
      nameUr: 'ڈمپر ٹرک',
      typicalCapacityTons: 20.0,
      standardHeightFt: 11.5,
      standardHeightM: 3.51,
      grossWeightLimitTons: 32.0,
    ),
  ];

  static VehicleType? findById(String id) {
    try {
      return all.firstWhere((element) => element.id == id);
    } catch (_) {
      return null;
    }
  }
}
