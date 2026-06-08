/// Модель водителя
class DriverModel {
  final String id;
  final String name;
  final String carModel;
  final String licensePlate;
  final double rating;
  final String? photoUrl;
  final bool isOnline;
  final int etaMinutes;
  final double currentLat;
  final double currentLng;
  // Казахстанские поля
  final String? iin;
  final String? govPlate;

  DriverModel({
    required this.id,
    required this.name,
    required this.carModel,
    required this.licensePlate,
    this.rating = 4.9,
    this.photoUrl,
    this.isOnline = true,
    this.etaMinutes = 5,
    this.currentLat = 43.238,
    this.currentLng = 76.883,
    this.iin,
    this.govPlate,
  });

  DriverModel copyWith({
    String? id,
    String? name,
    String? carModel,
    String? licensePlate,
    double? rating,
    String? photoUrl,
    bool? isOnline,
    int? etaMinutes,
    double? currentLat,
    double? currentLng,
    String? iin,
    String? govPlate,
  }) {
    return DriverModel(
      id: id ?? this.id,
      name: name ?? this.name,
      carModel: carModel ?? this.carModel,
      licensePlate: licensePlate ?? this.licensePlate,
      rating: rating ?? this.rating,
      photoUrl: photoUrl ?? this.photoUrl,
      isOnline: isOnline ?? this.isOnline,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      currentLat: currentLat ?? this.currentLat,
      currentLng: currentLng ?? this.currentLng,
      iin: iin ?? this.iin,
      govPlate: govPlate ?? this.govPlate,
    );
  }

  // Алиасы для совместимости с MockApiService
  String get vehicle => carModel;
  String get plate => licensePlate;

  String get displayRating => rating.toStringAsFixed(2);
  String get vehicleInfo => '$carModel \u2022 $licensePlate';
}

/// Mock-данные водителей для демонстрации
class MockDrivers {
  static final assigned = DriverModel(
    id: 'drv_001',
    name: 'Константин',
    carModel: 'Toyota Camry',
    licensePlate: '777 YMK 07',
    rating: 4.97,
  );

  static final ratingScreen = DriverModel(
    id: 'drv_002',
    name: 'Александр',
    carModel: 'Mercedes-Benz S-Class',
    licensePlate: '001 AMG 01',
    rating: 4.98,
  );
}
