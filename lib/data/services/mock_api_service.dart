import 'dart:math';
import 'package:qayda_taxi_app/data/models/app_user.dart';
import 'package:qayda_taxi_app/data/models/driver_model.dart';
import 'package:qayda_taxi_app/data/models/ride_order.dart';

/// Реалистичная mock-симуляция бэкенда Qayda.
///
/// Все тайминги максимально приближены к реальному InDrive / Яндекс.Go:
///   - Поиск водителя: 3–6 секунд
///   - ETA прибытия: 3–8 минут (счётчик идёт каждую секунду)
///   - Поездка: 20–45 секунд симуляции
///   - Ошибки сети: ~8% запросов (симуляция нестабильной связи)
///
/// Нет сетевых вызовов, работает полностью офлайн.
class MockApiService {
  static final _rng = Random();

  // ────────────────────────────────────────────────────────────────────────────
  // AUTH
  // ────────────────────────────────────────────────────────────────────────────

  /// Симулирует отправку OTP-кода по SMS.
  /// Задержка 800–1200 мс (как реальная сеть).
  /// 8% шанс ошибки сети.
  static Future<void> sendOtp(String phone) async {
    await Future.delayed(Duration(milliseconds: 800 + _rng.nextInt(400)));
    if (_rng.nextInt(100) < 8) {
      throw NetworkException('Нет подключения к интернету. Проверьте соединение.');
    }
  }

  /// Проверяет OTP (mock: любой код ≥4 символов — успех).
  static Future<AppUser> verifyOtp({
    required String phone,
    required String otp,
    required UserRole role,
    UserGender gender = UserGender.unspecified,
  }) async {
    await Future.delayed(Duration(milliseconds: 600 + _rng.nextInt(300)));
    if (otp.length < 4) {
      throw Exception('Неверный код подтверждения');
    }
    if (_rng.nextInt(100) < 5) {
      throw NetworkException('Сервер не отвечает. Попробуйте ещё раз.');
    }
    return AppUser(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      name: role == UserRole.driver
          ? _driverNames[_rng.nextInt(_driverNames.length)]
          : _passengerNames[_rng.nextInt(_passengerNames.length)],
      phone: phone,
      role: role,
      gender: gender,
      rating: role == UserRole.driver
          ? 4.8 + _rng.nextDouble() * 0.19
          : 4.5 + _rng.nextDouble() * 0.49,
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // RIDE SEARCH (PASSENGER)
  // ────────────────────────────────────────────────────────────────────────────

  /// Возвращает стрим событий поездки пассажира с координатами водителя.
  /// Порядок: searching → driverFound → etaCountdown + positionUpdate → driverArrived → inProgress → completed
  static Stream<RideEvent> streamPassengerRide({
    required RideOrder order,
    required bool cancelled,
  }) async* {
    // 1. Поиск водителя (3–6 секунд)
    final searchDelay = 3000 + _rng.nextInt(3000);
    await Future.delayed(Duration(milliseconds: searchDelay));

    if (cancelled) return;

    // 2. Водитель найден — стартовая позиция случайная в радиусе 1–2 км
    final driver = _pickRandomDriver(order.tariff);
    final eta = 3 + _rng.nextInt(6); // 3–8 минут
    yield RideEvent.driverFound(driver: driver, etaMinutes: eta);

    // 3. Обратный отсчёт ETA + ДВИЖЕНИЕ маркера (каждые 10 сек)
    var currentLat = driver.currentLat;
    var currentLng = driver.currentLng;

    // Целевая точка — пассажир (Алматы центр)
    const targetLat = 43.2380;
    const targetLng = 76.8829;

    final totalSteps = eta * 60 ~/ 10; // шаги по 10 сек
    for (var step = 0; step < totalSteps && !cancelled; step++) {
      await Future.delayed(const Duration(seconds: 10));
      final remaining = (eta * 60) - (step + 1) * 10;

      // Интерполируем позицию к целевой точке
      final progress = (step + 1) / totalSteps;
      currentLat = driver.currentLat + (targetLat - driver.currentLat) * progress;
      currentLng = driver.currentLng + (targetLng - driver.currentLng) * progress;

      // Небольшой случайный jitter для реалистичности
      currentLat += (_rng.nextDouble() - 0.5) * 0.0005;
      currentLng += (_rng.nextDouble() - 0.5) * 0.0005;

      yield RideEvent.positionUpdate(lat: currentLat, lng: currentLng);
      if (remaining > 0) {
        yield RideEvent.etaTick(secondsRemaining: remaining.clamp(0, 9999));
      }
    }

    if (cancelled) return;

    // 4. Водитель прибыл
    yield const RideEvent.driverArrived();
    await Future.delayed(Duration(seconds: 8 + _rng.nextInt(7)));

    if (cancelled) return;

    // 5. Поездка началась
    yield const RideEvent.tripStarted();

    // 6. Симуляция поездки (20–45 сек)
    final tripDuration = 20 + _rng.nextInt(25);
    for (var elapsed = 0; elapsed < tripDuration && !cancelled; elapsed += 5) {
      await Future.delayed(const Duration(seconds: 5));
      yield RideEvent.tripProgress(elapsedSeconds: elapsed + 5);
    }

    if (cancelled) return;

    // 7. Поездка завершена
    yield const RideEvent.tripCompleted();
  }

  // ────────────────────────────────────────────────────────────────────────────
  // DRIVER SIMULATION
  // ────────────────────────────────────────────────────────────────────────────

  /// Генерирует случайный входящий заказ для водителя.
  static Future<RideOrder> waitForIncomingOrder() async {
    final delay = 5000 + _rng.nextInt(10000); // 5–15 сек
    await Future.delayed(Duration(milliseconds: delay));
    if (_rng.nextInt(100) < 5) {
      throw NetworkException('Потеряно соединение с сервером.');
    }
    return RideOrder(
      id: 'ord_${DateTime.now().millisecondsSinceEpoch}',
      origin: _almatyPickups[_rng.nextInt(_almatyPickups.length)],
      destination: _almatyDestinations[_rng.nextInt(_almatyDestinations.length)],
      status: RideStatus.searching,
      tariff: RideTariff.values[_rng.nextInt(3)],
      priceKzt: _tariffPrices[_rng.nextInt(_tariffPrices.length)],
      createdAt: DateTime.now(),
    );
  }

  /// Стрим состояний водителя после принятия заказа.
  static Stream<DriverRideEvent> streamDriverTrip(RideOrder order) async* {
    final etaToPickup = 3 + _rng.nextInt(5);
    yield DriverRideEvent.enRoute(etaMinutes: etaToPickup, order: order);

    for (var t = etaToPickup * 60; t > 0; t -= 20) {
      await Future.delayed(const Duration(seconds: 20));
      yield DriverRideEvent.etaTick(secondsRemaining: t - 20, order: order);
    }

    yield DriverRideEvent.arrivedAtPickup(order: order);
    await Future.delayed(const Duration(seconds: 10));

    yield DriverRideEvent.tripStarted(order: order);

    final tripDur = 25 + _rng.nextInt(25);
    for (var el = 0; el < tripDur; el += 5) {
      await Future.delayed(const Duration(seconds: 5));
      yield DriverRideEvent.tripProgress(elapsed: el + 5, order: order);
    }

    yield DriverRideEvent.tripCompleted(order: order, earnings: order.priceKzt);
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Helpers
  // ────────────────────────────────────────────────────────────────────────────

  static DriverModel _pickRandomDriver(RideTariff tariff) {
    final List<Map<String,String>> pool;
    if (tariff == RideTariff.business) {
      pool = _premiumDrivers;
    } else if (tariff == RideTariff.pink) {
      pool = _pinkDrivers; // всегда водитель-женщина
    } else {
      pool = _standardDrivers;
    }
    final d = pool[_rng.nextInt(pool.length)];
    final eta = 3 + _rng.nextInt(6);
    return DriverModel(
      id: 'drv_${_rng.nextInt(9999)}',
      name: d['name']!,
      carModel: d['vehicle']!,
      licensePlate: d['plate']!,
      rating: 4.7 + _rng.nextDouble() * 0.29,
      photoUrl: null,
      etaMinutes: eta,
      // Стартовые координаты: 0.5–2 км от пассажира
      currentLat: 43.2380 + (_rng.nextDouble() - 0.5) * 0.02,
      currentLng: 76.8829 + (_rng.nextDouble() - 0.5) * 0.02,
    );
  }

  static const _standardDrivers = [
    {'name': 'Асылбек', 'vehicle': 'Toyota Camry', 'plate': 'A 777 AA'},
    {'name': 'Дамир', 'vehicle': 'Hyundai Accent', 'plate': 'B 123 BB'},
    {'name': 'Рустем', 'vehicle': 'Kia Rio', 'plate': 'C 456 CC'},
    {'name': 'Ержан', 'vehicle': 'Toyota Corolla', 'plate': 'D 888 DD'},
  ];

  static const _premiumDrivers = [
    {'name': 'Константин', 'vehicle': 'BMW 5 Series', 'plate': 'E 001 EE'},
    {'name': 'Самат', 'vehicle': 'Mercedes E-Class', 'plate': 'F 002 FF'},
    {'name': 'Нурлан', 'vehicle': 'Lexus ES', 'plate': 'G 003 GG'},
  ];

  /// Пул Pink-тарифа (водители-женщины, всегда Kia Rio)
  static const _pinkDrivers = [
    {'name': 'Айгерим', 'vehicle': 'Kia Rio', 'plate': 'H 001 HH'},
    {'name': 'Зарина', 'vehicle': 'Kia Rio', 'plate': 'H 002 HH'},
    {'name': 'Малика', 'vehicle': 'Hyundai Solaris', 'plate': 'H 003 HH'},
    {'name': 'Асель', 'vehicle': 'Kia Rio', 'plate': 'H 004 HH'},
  ];

  static const _driverNames = ['Асылбек', 'Дамир', 'Рустем', 'Константин', 'Самат', 'Ержан'];
  static const _passengerNames = ['Алибек', 'Айгерим', 'Нурлан', 'Зарина', 'Бекзат'];
  static const _tariffPrices = [1250.0, 1500.0, 1800.0, 2200.0, 2800.0, 3400.0, 4200.0];

  static const _almatyPickups = [
    'пр. Аль-Фараби, 77',
    'ул. Достык, 5',
    'мкр. Самал-2, 111',
    'пр. Назарбаева, 200',
    'Esentai Tower',
    'ТРЦ Mega Alma-Ata',
    'Аэропорт Алматы',
    'ЦПКиО им. Горького',
    'Медеу, Ледовый каток',
  ];

  static const _almatyDestinations = [
    'ул. Тимирязева, 42',
    'пр. Сейфуллина, 128',
    'ул. Фурманова, 100',
    'мкр. Алмагуль',
    'ТРЦ Dostyk Plaza',
    'БЦ «Нурлы Тау», Блок 4Б',
    'КБТУ, ул. Толе Би, 59',
    'Парк 28 панфиловцев',
    'Зелёный базар',
  ];
}

// ────────────────────────────────────────────────────────────────────────────
// Custom exceptions
// ────────────────────────────────────────────────────────────────────────────

class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);
  @override
  String toString() => message;
}

// ────────────────────────────────────────────────────────────────────────────
// Event types
// ────────────────────────────────────────────────────────────────────────────

class RideEvent {
  final String type;
  final DriverModel? driver;
  final int? etaMinutes;
  final int? secondsRemaining;
  final int? elapsedSeconds;
  // Координаты водителя для плавной анимации маркера
  final double? driverLat;
  final double? driverLng;

  const RideEvent._({
    required this.type,
    this.driver,
    this.etaMinutes,
    this.secondsRemaining,
    this.elapsedSeconds,
    this.driverLat,
    this.driverLng,
  });

  factory RideEvent.driverFound({required DriverModel driver, required int etaMinutes}) =>
      RideEvent._(
          type: 'driver_found',
          driver: driver,
          etaMinutes: etaMinutes,
          driverLat: driver.currentLat,
          driverLng: driver.currentLng);

  factory RideEvent.etaTick({required int secondsRemaining}) =>
      RideEvent._(type: 'eta_tick', secondsRemaining: secondsRemaining);

  /// Обновление позиции водителя (для плавной анимации маркера)
  factory RideEvent.positionUpdate({required double lat, required double lng}) =>
      RideEvent._(type: 'position_update', driverLat: lat, driverLng: lng);

  const RideEvent.driverArrived() : this._(type: 'driver_arrived');
  const RideEvent.tripStarted()   : this._(type: 'trip_started');

  factory RideEvent.tripProgress({required int elapsedSeconds}) =>
      RideEvent._(type: 'trip_progress', elapsedSeconds: elapsedSeconds);

  const RideEvent.tripCompleted() : this._(type: 'trip_completed');
}

class DriverRideEvent {
  final String type;
  final RideOrder order;
  final int? etaMinutes;
  final int? secondsRemaining;
  final int? elapsed;
  final double? earnings;

  const DriverRideEvent._({
    required this.type,
    required this.order,
    this.etaMinutes,
    this.secondsRemaining,
    this.elapsed,
    this.earnings,
  });

  factory DriverRideEvent.enRoute({required int etaMinutes, required RideOrder order}) =>
      DriverRideEvent._(type: 'en_route', order: order, etaMinutes: etaMinutes);

  factory DriverRideEvent.etaTick({required int secondsRemaining, required RideOrder order}) =>
      DriverRideEvent._(type: 'eta_tick', order: order, secondsRemaining: secondsRemaining);

  factory DriverRideEvent.arrivedAtPickup({required RideOrder order}) =>
      DriverRideEvent._(type: 'arrived', order: order);

  factory DriverRideEvent.tripStarted({required RideOrder order}) =>
      DriverRideEvent._(type: 'trip_started', order: order);

  factory DriverRideEvent.tripProgress({required int elapsed, required RideOrder order}) =>
      DriverRideEvent._(type: 'trip_progress', order: order, elapsed: elapsed);

  factory DriverRideEvent.tripCompleted({required RideOrder order, required double earnings}) =>
      DriverRideEvent._(type: 'completed', order: order, earnings: earnings);
}
