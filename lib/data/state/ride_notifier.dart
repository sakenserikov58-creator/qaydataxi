import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:qayda_taxi_app/data/models/ride_order.dart';
import 'package:qayda_taxi_app/data/models/driver_model.dart';

/// Управляет состоянием текущего заказа (FSM).
/// GoRouter слушает этот нотифаер для auto-redirect.
class RideNotifier extends ChangeNotifier {
  RideStatus _status = RideStatus.idle;
  RideOrder? _currentOrder;
  DriverModel? _assignedDriver;
  RideTariff _selectedTariff = RideTariff.comfort;

  // ─── Геттеры ───────────────────────────────────────────────────
  RideStatus get status => _status;
  RideOrder? get currentOrder => _currentOrder;
  DriverModel? get assignedDriver => _assignedDriver;
  RideTariff get selectedTariff => _selectedTariff;

  bool get isIdle => _status == RideStatus.idle;
  bool get isSearching => _status == RideStatus.searching;
  bool get isInProgress => _status == RideStatus.inProgress;
  bool get isCompleted => _status == RideStatus.completed;

  // ─── Переходы FSM ──────────────────────────────────────────────

  /// Пассажир выбирает тариф
  void selectTariff(RideTariff tariff) {
    _selectedTariff = tariff;
    _status = RideStatus.selecting;
    notifyListeners();
  }

  /// Пассажир подтверждает заказ → поиск водителя
  void startSearch({
    required String origin,
    required String destination,
    LatLng? originPoint,
    LatLng? destinationPoint,
  }) {
    _status = RideStatus.searching;
    _currentOrder = RideOrder(
      id: 'ord_${DateTime.now().millisecondsSinceEpoch}',
      origin: origin,
      destination: destination,
      originPoint: originPoint,
      destinationPoint: destinationPoint,
      status: RideStatus.searching,
      tariff: _selectedTariff,
      priceKzt: _selectedTariff.basePriceKzt,
      createdAt: DateTime.now(),
    );
    _assignedDriver = null;
    notifyListeners();
  }

  /// Водитель найден (вызывается из RideBloc)
  void driverFound() {
    if (_status != RideStatus.searching) return;
    _status = RideStatus.accepted;
    _currentOrder = _currentOrder?.copyWith(status: RideStatus.accepted);
    notifyListeners();
  }

  /// Водитель прибыл к пассажиру
  void driverArrived() {
    _status = RideStatus.arrived;
    _currentOrder = _currentOrder?.copyWith(status: RideStatus.arrived);
    notifyListeners();
  }

  /// Поездка началась
  void startRide() {
    _status = RideStatus.inProgress;
    _currentOrder = _currentOrder?.copyWith(status: RideStatus.inProgress);
    notifyListeners();
  }

  /// Поездка завершена
  void completeRide() {
    _status = RideStatus.completed;
    _currentOrder = _currentOrder?.copyWith(status: RideStatus.completed);
    notifyListeners();
  }

  /// Отмена заказа на любом этапе
  void cancelRide() {
    _status = RideStatus.idle;
    _currentOrder = null;
    _assignedDriver = null;
    notifyListeners();
  }

  /// Сброс после оценки → возврат в начало
  void reset() {
    _status = RideStatus.idle;
    _currentOrder = null;
    _assignedDriver = null;
    _selectedTariff = RideTariff.comfort;
    notifyListeners();
  }
}
