import 'dart:async';
import 'dart:math';

import 'package:qayda_taxi_app/data/models/ride_order.dart';
import 'package:qayda_taxi_app/data/models/driver_model.dart' as import_driver;

/// Глобальный диспетчер для кросс-ролевого взаимодействия на одном устройстве.
/// Позволяет Пассажиру отправлять заказы, а Водителю - получать и принимать их.
class SystemDispatcher {
  static final SystemDispatcher _instance = SystemDispatcher._internal();
  factory SystemDispatcher() => _instance;
  SystemDispatcher._internal();

  final _rng = Random();

  // ─── Шины данных ────────────────────────────────────────────────────────
  
  // Текущий активный заказ в системе (в реальном приложении это была бы таблица БД)
  RideOrder? _activeOrder;
  
  // Назначенный водитель
  import_driver.DriverModel? assignedDriver;
  
  // Стрим обновления состояния заказа (для Пассажира)
  final _passengerOrderStream = StreamController<RideOrder>.broadcast();
  
  // Стрим ETA для пассажира
  final _passengerEtaStream = StreamController<int>.broadcast();

  // Стрим входящих заказов (для Водителя)
  final _incomingOrdersStream = StreamController<RideOrder>.broadcast();

  // Стрим для водителя: отсчет времени или состояния маршрута
  final _driverTripStream = StreamController<DriverTripState>.broadcast();

  Timer? _simulationTimer;

  // ─── Геттеры ────────────────────────────────────────────────────────────

  Stream<RideOrder> get passengerOrderUpdates => _passengerOrderStream.stream;
  Stream<int> get passengerEtaUpdates => _passengerEtaStream.stream;
  Stream<RideOrder> get incomingOrders => _incomingOrdersStream.stream;
  Stream<DriverTripState> get driverTripUpdates => _driverTripStream.stream;

  // ─── Методы Пассажира ───────────────────────────────────────────────────

  /// Пассажир создает заказ.
  void dispatchOrder(RideOrder order) {
    _activeOrder = order.copyWith(status: RideStatus.searching);
    _passengerOrderStream.add(_activeOrder!);
    
    // Отправляем заказ всем активным водителям
    _incomingOrdersStream.add(_activeOrder!);
  }

  /// Пассажир отменяет заказ
  void cancelOrder() {
    if (_activeOrder != null) {
      _activeOrder = _activeOrder!.copyWith(status: RideStatus.cancelled);
      _passengerOrderStream.add(_activeOrder!);
    }
    _stopSimulation();
  }

  // ─── Методы Водителя ────────────────────────────────────────────────────

  /// Водитель принимает заказ
  void acceptOrder(String orderId, import_driver.DriverModel driver) {
    if (_activeOrder != null && _activeOrder!.id == orderId) {
      assignedDriver = driver;
      
      // Вкидываем координаты водителя в activeOrder (хотя обычно они живут в водительском стейте, оставим в assignedDriver)
      _activeOrder = _activeOrder!.copyWith(status: RideStatus.accepted);
      _passengerOrderStream.add(_activeOrder!);
      
      _startEtaSimulation();
    }
  }

  /// Водитель прибыл
  void markArrived() {
    if (_activeOrder != null) {
      _activeOrder = _activeOrder!.copyWith(status: RideStatus.arrived);
      _passengerOrderStream.add(_activeOrder!);
      _driverTripStream.add(DriverTripState.arrived);
    }
  }
  
  /// Водитель начал поездку
  void startTrip() {
    if (_activeOrder != null) {
      _activeOrder = _activeOrder!.copyWith(status: RideStatus.inProgress);
      _passengerOrderStream.add(_activeOrder!);
      _driverTripStream.add(DriverTripState.inProgress);
    }
  }
  
  /// Водитель завершил поездку
  void completeTrip() {
    if (_activeOrder != null) {
      _activeOrder = _activeOrder!.copyWith(status: RideStatus.completed);
      _passengerOrderStream.add(_activeOrder!);
      _driverTripStream.add(DriverTripState.completed);
    }
    _stopSimulation();
  }

  // ─── Внутренняя логика симуляции ───────────────────────────────────────

  void _startEtaSimulation() {
    _stopSimulation();

    int etaSeconds = _activeOrder!.tariff.etaMinutes * 60;
    
    _simulationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_activeOrder?.status != RideStatus.accepted) {
        timer.cancel();
        return;
      }
      
      // Симулируем "пробку": 10% шанс, что время не уменьшится в эту секунду
      if (_rng.nextInt(100) > 10) {
        etaSeconds--;
      }
      
      if (etaSeconds <= 0) {
        timer.cancel();
        markArrived(); // Если время вышло, авто-статус "прибыл"
      } else {
        _passengerEtaStream.add(etaSeconds);
        // Симулируем движение водителя к пассажиру
        if (assignedDriver != null) {
            assignedDriver = assignedDriver!.copyWith(
                currentLat: assignedDriver!.currentLat + (_rng.nextDouble() - 0.5) * 0.0005,
                currentLng: assignedDriver!.currentLng + (_rng.nextDouble() - 0.5) * 0.0005,
            );
        }
        _driverTripStream.add(DriverTripState.enRoute(etaSeconds));
      }
    });
  }

  void _stopSimulation() {
    _simulationTimer?.cancel();
    _simulationTimer = null;
  }
}

enum DriverTripStateEnum { enRoute, arrived, inProgress, completed }

class DriverTripState {
  final DriverTripStateEnum state;
  final int? secondsRemaining;

  const DriverTripState._(this.state, [this.secondsRemaining]);

  factory DriverTripState.enRoute(int secondsRemaining) => DriverTripState._(DriverTripStateEnum.enRoute, secondsRemaining);
  static const arrived = DriverTripState._(DriverTripStateEnum.arrived);
  static const inProgress = DriverTripState._(DriverTripStateEnum.inProgress);
  static const completed = DriverTripState._(DriverTripStateEnum.completed);
}
