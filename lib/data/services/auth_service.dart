import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qayda_taxi_app/core/utils/prefs_keys.dart';
import 'package:qayda_taxi_app/data/models/app_user.dart';
import 'package:qayda_taxi_app/data/services/mock_api_service.dart';

/// Глобальный сервис авторизации (ChangeNotifier → GoRouter refreshListenable).
///
/// Отвечает за:
///   1. Хранение текущего пользователя в памяти
///   2. Персистентность роли через SharedPreferences
///   3. Восстановление сессии при перезапуске (`initFromPrefs`)
///   4. Обновление профиля (имя, пол, ИИН, данные авто)
class AuthService extends ChangeNotifier {
  AppUser? _currentUser;
  bool _initialized = false;

  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isInitialized => _initialized;
  UserRole get role => _currentUser?.role ?? UserRole.passenger;
  bool get isDriver => role == UserRole.driver;

  /// Проверка: заполнены ли данные для работы водителем (ИИН, авто)
  bool get isProfileCompleteForDriver {
    final u = _currentUser;
    if (u == null) return false;
    return u.iin != null &&
        u.vehicleBrand != null &&
        u.vehiclePlate != null &&
        u.vehiclePassport != null;
  }

  // ─── Инициализация из SharedPreferences ───────────────────────────────────

  Future<void> initFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final wasLoggedIn = prefs.getBool(PrefsKeys.isLoggedIn) ?? false;

    if (wasLoggedIn) {
      final savedRole = prefs.getString(PrefsKeys.role);
      final savedPhone = prefs.getString(PrefsKeys.phone) ?? '';
      final savedName = prefs.getString(PrefsKeys.name) ?? '';
      final savedGender = prefs.getString(PrefsKeys.gender) ?? 'unspecified';
      final savedIin = prefs.getString(PrefsKeys.iin);
      final savedVehicleBrand = prefs.getString(PrefsKeys.vehicleBrand);
      final savedVehiclePlate = prefs.getString(PrefsKeys.vehiclePlate);
      final savedVehiclePassport = prefs.getString(PrefsKeys.vehiclePassport);
      final role = savedRole == 'driver' ? UserRole.driver : UserRole.passenger;
      final gender = UserGender.values.firstWhere(
        (e) => e.name == savedGender,
        orElse: () => UserGender.unspecified,
      );

      _currentUser = AppUser(
        id: 'restored_${DateTime.now().millisecondsSinceEpoch}',
        name: savedName,
        phone: savedPhone,
        role: role,
        gender: gender,
        iin: savedIin,
        rating: role == UserRole.driver ? 4.97 : 4.80,
        vehicleBrand: savedVehicleBrand,
        vehiclePlate: savedVehiclePlate,
        vehiclePassport: savedVehiclePassport,
      );
    }

    _initialized = true;
    notifyListeners();
  }

  // ─── Вход ─────────────────────────────────────────────────────────────────

  Future<void> sendOtp(String phone) => MockApiService.sendOtp(phone);

  /// Верифицирует OTP, создаёт пользователя, сохраняет сессию.
  Future<void> verifyAndLogin({
    required String phone,
    required String otp,
    required UserRole role,
    UserGender gender = UserGender.unspecified,
  }) async {
    final user = await MockApiService.verifyOtp(
      phone: phone,
      otp: otp,
      role: role,
      gender: gender,
    );

    _currentUser = user;
    await _saveToPrefs(user);
    notifyListeners();
  }

  // ─── Обновление профиля ────────────────────────────────────────────────────

  Future<void> updateProfile({
    String? name,
    UserGender? gender,
  }) async {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(name: name, gender: gender);
    await _saveToPrefs(_currentUser!);
    notifyListeners();
  }

  /// Регистрация водителя: сохраняет ИИН и данные авто
  Future<void> becomeDriver({
    required String iin,
    required String vehicleBrand,
    required String vehiclePlate,
    required String vehiclePassport,
  }) async {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(
      role: UserRole.driver,
      iin: iin,
      vehicleBrand: vehicleBrand,
      vehiclePlate: vehiclePlate,
      vehiclePassport: vehiclePassport,
    );
    await _saveToPrefs(_currentUser!);
    notifyListeners();
  }

  // ─── Смена роли без выхода ─────────────────────────────────────────────────

  Future<void> switchRole(UserRole newRole) async {
    if (_currentUser == null) return;
    
    // Блокировка роли водителя, если профиль не заполнен
    if (newRole == UserRole.driver && !isProfileCompleteForDriver) {
      debugPrint('AuthService: Profile incomplete for driver role.');
      return;
    }

    _currentUser = _currentUser!.copyWith(role: newRole);
    await _saveToPrefs(_currentUser!);
    notifyListeners();
  }

  // ─── Выход ────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(PrefsKeys.isLoggedIn);
    await prefs.remove(PrefsKeys.role);
    await prefs.remove(PrefsKeys.phone);
    await prefs.remove(PrefsKeys.name);
    await prefs.remove(PrefsKeys.gender);
    await prefs.remove(PrefsKeys.iin);
    notifyListeners();
  }

  // ─── Приватное ────────────────────────────────────────────────────────────

  Future<void> _saveToPrefs(AppUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefsKeys.isLoggedIn, true);
    await prefs.setString(PrefsKeys.role, user.isDriver ? 'driver' : 'passenger');
    await prefs.setString(PrefsKeys.phone, user.phone);
    await prefs.setString(PrefsKeys.name, user.name);
    await prefs.setString(PrefsKeys.gender, user.gender.name);
    if (user.iin != null) await prefs.setString(PrefsKeys.iin, user.iin!);
    if (user.vehicleBrand != null) {
      await prefs.setString(PrefsKeys.vehicleBrand, user.vehicleBrand!);
    }
    if (user.vehiclePlate != null) {
      await prefs.setString(PrefsKeys.vehiclePlate, user.vehiclePlate!);
    }
    if (user.vehiclePassport != null) {
      await prefs.setString(PrefsKeys.vehiclePassport, user.vehiclePassport!);
    }
  }
}
