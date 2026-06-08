/// Ключи для SharedPreferences — единое место, без магических строк.
abstract class PrefsKeys {
  PrefsKeys._();

  /// Сохранённая роль: 'passenger' | 'driver'
  static const String role = 'qayda_user_role';

  /// Телефон последней сессии
  static const String phone = 'qayda_user_phone';

  /// Имя пользователя
  static const String name = 'qayda_user_name';

  /// Флаг: пользователь авторизован
  static const String isLoggedIn = 'qayda_is_logged_in';

  /// Пол: 'male' | 'female' | 'unspecified'
  static const String gender = 'qayda_user_gender';

  /// ИИН водителя (12 знаков)
  static const String iin = 'qayda_driver_iin';

  /// Данные авто
  static const String vehicleBrand   = 'qayda_vehicle_brand';
  static const String vehiclePlate   = 'qayda_vehicle_plate';
  static const String vehiclePassport = 'qayda_vehicle_passport';
}
