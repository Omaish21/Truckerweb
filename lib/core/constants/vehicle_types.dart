class VehicleType {
  final String id;
  final String nameEn;
  final String nameUr;
  final double typicalCapacityTons;

  const VehicleType({
    required this.id,
    required this.nameEn,
    required this.nameUr,
    required this.typicalCapacityTons,
  });

  static const List<VehicleType> all = [
    VehicleType(
      id: 'mazda',
      nameEn: 'Mazda / Light Truck',
      nameUr: 'مزدا / ہلکا ٹرک',
      typicalCapacityTons: 5.0,
    ),
    VehicleType(
      id: '10_wheeler',
      nameEn: '10-Wheeler Truck',
      nameUr: '۱۰ ویلر ٹرک',
      typicalCapacityTons: 16.0,
    ),
    VehicleType(
      id: '22_wheeler',
      nameEn: '22-Wheeler (Trolley)',
      nameUr: '۲۲ ویلر ٹرالہ',
      typicalCapacityTons: 35.0,
    ),
    VehicleType(
      id: 'container',
      nameEn: '40ft / 20ft Container Carrier',
      nameUr: 'کنٹینر کیریئر',
      typicalCapacityTons: 30.0,
    ),
    VehicleType(
      id: 'tanker',
      nameEn: 'Oil / Chemical Tanker',
      nameUr: 'آئل / کیمیکل ٹینکر',
      typicalCapacityTons: 40.0,
    ),
    VehicleType(
      id: 'flatbed',
      nameEn: 'Flatbed Trailer',
      nameUr: 'فلیٹ بیڈ ٹریلر',
      typicalCapacityTons: 32.0,
    ),
    VehicleType(
      id: 'dumper',
      nameEn: 'Dumper Truck',
      nameUr: 'ڈمپر ٹرک',
      typicalCapacityTons: 20.0,
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
