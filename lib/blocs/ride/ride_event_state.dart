import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';
import 'package:qayda_taxi_app/data/models/driver_model.dart';
import 'package:qayda_taxi_app/data/models/ride_order.dart';

// ─── Events ───────────────────────────────────────────────────────────────────

abstract class RideEvent extends Equatable {
  const RideEvent();
  @override
  List<Object?> get props => [];
}

class TariffSelected extends RideEvent {
  final int index;
  const TariffSelected(this.index);
  @override
  List<Object?> get props => [index];
}

class RideRequested extends RideEvent {
  final String origin;
  final String destination;
  final LatLng? originPoint;
  final LatLng? destinationPoint;
  final RideTariff tariff;
  const RideRequested({
    required this.origin,
    required this.destination,
    this.originPoint,
    this.destinationPoint,
    required this.tariff,
  });
  @override
  List<Object?> get props => [origin, destination, originPoint, destinationPoint, tariff];
}

class RideCancelRequested extends RideEvent {
  const RideCancelRequested();
}

// Внутренние события от MockApiService
class RideDriverFoundEvent extends RideEvent {
  final DriverModel driver;
  final int etaMinutes;
  const RideDriverFoundEvent({required this.driver, required this.etaMinutes});
  @override
  List<Object?> get props => [driver, etaMinutes];
}

class RideEtaTickEvent extends RideEvent {
  final int secondsRemaining;
  const RideEtaTickEvent(this.secondsRemaining);
  @override
  List<Object?> get props => [secondsRemaining];
}

class RideDriverArrivedEvent extends RideEvent {
  const RideDriverArrivedEvent();
}

class RideTripStartedEvent extends RideEvent {
  const RideTripStartedEvent();
}

class RideTripProgressEvent extends RideEvent {
  final int elapsedSeconds;
  const RideTripProgressEvent(this.elapsedSeconds);
  @override
  List<Object?> get props => [elapsedSeconds];
}

class RideTripCompletedEvent extends RideEvent {
  const RideTripCompletedEvent();
}

class RateSubmitted extends RideEvent {
  final int stars;
  final List<String> tags;
  const RateSubmitted({required this.stars, this.tags = const []});
  @override
  List<Object?> get props => [stars, tags];
}

class RideReset extends RideEvent {
  const RideReset();
}

/// Позиция водителя движется → плавная анимация маркера
class RidePositionUpdateEvent extends RideEvent {
  final double lat;
  final double lng;
  const RidePositionUpdateEvent(this.lat, this.lng);
  @override
  List<Object?> get props => [lat, lng];
}

// ─── States ───────────────────────────────────────────────────────────────────

abstract class RideBlocState extends Equatable {
  const RideBlocState();
  @override
  List<Object?> get props => [];
}

class RideIdleState extends RideBlocState {
  const RideIdleState();
}

/// Экран выбора тарифа
class RideTariffState extends RideBlocState {
  final int selectedIndex;
  final String origin;
  final String destination;
  static const tariffs = [RideTariff.economy, RideTariff.comfort, RideTariff.business, RideTariff.minivan, RideTariff.pink];

  const RideTariffState({
    this.selectedIndex = 1,
    this.origin = '',
    this.destination = '',
  });

  RideTariff get selectedTariff => tariffs[selectedIndex];

  RideTariffState copyWith({int? selectedIndex, String? origin, String? destination}) =>
      RideTariffState(
        selectedIndex: selectedIndex ?? this.selectedIndex,
        origin: origin ?? this.origin,
        destination: destination ?? this.destination,
      );

  @override
  List<Object?> get props => [selectedIndex, origin, destination];
}

/// Поиск водителя
class RideSearchingState extends RideBlocState {
  final RideOrder order;
  const RideSearchingState(this.order);
  @override
  List<Object?> get props => [order.id];
}

/// Водитель найден, обратный отсчёт ETA + позиция маркера
class RideDriverFoundState extends RideBlocState {
  final RideOrder order;
  final DriverModel driver;
  final int etaSeconds;
  /// Текущая позиция водителя (для плавной анимации маркера)
  final double driverLat;
  final double driverLng;

  const RideDriverFoundState({
    required this.order,
    required this.driver,
    required this.etaSeconds,
    this.driverLat = 43.2380,
    this.driverLng = 76.8829,
  });

  String get etaFormatted {
    final m = etaSeconds ~/ 60;
    final s = etaSeconds % 60;
    return m > 0 ? '$m мин $sс' : '$sс';
  }

  RideDriverFoundState copyWith({int? etaSeconds, double? driverLat, double? driverLng}) =>
      RideDriverFoundState(
        order: order,
        driver: driver,
        etaSeconds: etaSeconds ?? this.etaSeconds,
        driverLat: driverLat ?? this.driverLat,
        driverLng: driverLng ?? this.driverLng,
      );

  @override
  List<Object?> get props => [order.id, driver.id, etaSeconds, driverLat, driverLng];
}

/// Водитель прибыл
class RideDriverArrivedState extends RideBlocState {
  final RideOrder order;
  final DriverModel driver;
  const RideDriverArrivedState({required this.order, required this.driver});
  @override
  List<Object?> get props => [order.id, driver.id];
}

/// Поездка в процессе
class RideInProgressBlocState extends RideBlocState {
  final RideOrder order;
  final DriverModel driver;
  final int elapsedSeconds;
  const RideInProgressBlocState({
    required this.order,
    required this.driver,
    required this.elapsedSeconds,
  });
  @override
  List<Object?> get props => [order.id, elapsedSeconds];
}

/// Поездка завершена — показать экран оценки
class RideCompletedState extends RideBlocState {
  final RideOrder order;
  final DriverModel driver;
  const RideCompletedState({required this.order, required this.driver});
  @override
  List<Object?> get props => [order.id];
}

/// Оценка отправлена
class RideRatedState extends RideBlocState {
  const RideRatedState();
}

/// Ошибка: сеть, сервер, отмена
class RideErrorBlocState extends RideBlocState {
  final String message;
  final RideBlocState? previousState; // чтобы вернуться по кнопке "Повторить"
  const RideErrorBlocState({required this.message, this.previousState});
  @override
  List<Object?> get props => [message];
}
