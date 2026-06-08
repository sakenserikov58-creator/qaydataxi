/// Роль пользователя в системе Qayda
enum UserRole { passenger, driver }

/// Пол пользователя — критично для тарифа Pink
enum UserGender { male, female, unspecified }

/// Модель пользователя приложения
///
/// Структура совместима с Firestore:
/// uid / name / phone / iin / role / gender / rating / avatarUrl
class AppUser {
  final String id;
  final String name;
  final String phone;
  final String? iin; // ИИН: 12 знаков (только для водителей)
  final UserRole role;
  final UserGender gender;
  final String? avatarUrl;
  final double rating;

  /// Машина водителя (заполняется при Онбординге)
  final String? vehicleBrand;
  final String? vehiclePlate;
  final String? vehiclePassport;

  AppUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    this.iin,
    this.gender = UserGender.unspecified,
    this.avatarUrl,
    this.rating = 5.0,
    this.vehicleBrand,
    this.vehiclePlate,
    this.vehiclePassport,
  });

  bool get isDriver => role == UserRole.driver;
  bool get isPassenger => role == UserRole.passenger;
  bool get isFemale => gender == UserGender.female;

  AppUser copyWith({
    String? name,
    String? phone,
    String? iin,
    UserRole? role,
    UserGender? gender,
    String? avatarUrl,
    double? rating,
    String? vehicleBrand,
    String? vehiclePlate,
    String? vehiclePassport,
  }) {
    return AppUser(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      iin: iin ?? this.iin,
      role: role ?? this.role,
      gender: gender ?? this.gender,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      rating: rating ?? this.rating,
      vehicleBrand: vehicleBrand ?? this.vehicleBrand,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      vehiclePassport: vehiclePassport ?? this.vehiclePassport,
    );
  }

  /// Конвертация для Firestore / SharedPreferences
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'phone': phone,
        'iin': iin,
        'role': role.name,
        'gender': gender.name,
        'rating': rating,
        'vehicleBrand': vehicleBrand,
        'vehiclePlate': vehiclePlate,
        'vehiclePassport': vehiclePassport,
      };

  factory AppUser.fromMap(Map<String, dynamic> m) => AppUser(
        id: m['id'] as String? ?? '',
        name: m['name'] as String? ?? '',
        phone: m['phone'] as String? ?? '',
        iin: m['iin'] as String?,
        role: UserRole.values.firstWhere(
          (e) => e.name == m['role'],
          orElse: () => UserRole.passenger,
        ),
        gender: UserGender.values.firstWhere(
          (e) => e.name == m['gender'],
          orElse: () => UserGender.unspecified,
        ),
        rating: (m['rating'] as num?)?.toDouble() ?? 5.0,
        vehicleBrand: m['vehicleBrand'] as String?,
        vehiclePlate: m['vehiclePlate'] as String?,
        vehiclePassport: m['vehiclePassport'] as String?,
      );

  @override
  String toString() => 'AppUser(id: $id, name: $name, role: $role, gender: $gender)';
}
