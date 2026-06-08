import 'package:equatable/equatable.dart';
import 'package:qayda_taxi_app/data/models/ride_order.dart';

// ─── Events ───────────────────────────────────────────────────────────────────

abstract class DriverEvent extends Equatable {
  const DriverEvent();
  @override
  List<Object?> get props => [];
}

class DriverGoOnline extends DriverEvent {
  const DriverGoOnline();
}

class DriverGoOffline extends DriverEvent {
  const DriverGoOffline();
}

// Внутреннее событие: пришёл заказ от MockApiService
class DriverOrderReceived extends DriverEvent {
  final RideOrder order;
  const DriverOrderReceived(this.order);
  @override
  List<Object?> get props => [order.id];
}

class DriverOrderAccepted extends DriverEvent {
  const DriverOrderAccepted();
}

class DriverOrderDeclined extends DriverEvent {
  const DriverOrderDeclined();
}

class DriverArrivedAtPickup extends DriverEvent {
  const DriverArrivedAtPickup();
}

class DriverTripStarted extends DriverEvent {
  const DriverTripStarted();
}

class DriverTripCompleted extends DriverEvent {
  const DriverTripCompleted();
}

// Внутренние тики от MockApiService
class DriverEtaTick extends DriverEvent {
  final int secondsRemaining;
  const DriverEtaTick(this.secondsRemaining);
  @override
  List<Object?> get props => [secondsRemaining];
}

class DriverTripProgress extends DriverEvent {
  final int elapsed;
  const DriverTripProgress(this.elapsed);
  @override
  List<Object?> get props => [elapsed];
}

// ─── States ───────────────────────────────────────────────────────────────────

abstract class DriverState extends Equatable {
  const DriverState();
  @override
  List<Object?> get props => [];
}

class DriverOfflineState extends DriverState {
  const DriverOfflineState();
}

/// Водитель в сети, ожидает заказа
class DriverOnlineState extends DriverState {
  final double todayEarnings;
  final int tripsCount;
  final double rating;

  const DriverOnlineState({
    this.todayEarnings = 0,
    this.tripsCount = 0,
    this.rating = 4.97,
  });

  DriverOnlineState copyWith({double? todayEarnings, int? tripsCount}) =>
      DriverOnlineState(
        todayEarnings: todayEarnings ?? this.todayEarnings,
        tripsCount: tripsCount ?? this.tripsCount,
        rating: rating,
      );

  @override
  List<Object?> get props => [todayEarnings, tripsCount, rating];
}

/// Пришёл входящий заказ — показать карточку принятия
class DriverHasOrderState extends DriverState {
  final RideOrder order;
  const DriverHasOrderState(this.order);
  @override
  List<Object?> get props => [order.id];
}

/// Заказ принят — едет к клиенту (ETA countdown)
class DriverEnRouteState extends DriverState {
  final RideOrder order;
  final int etaSeconds;

  const DriverEnRouteState({required this.order, required this.etaSeconds});

  String get etaFormatted {
    final m = etaSeconds ~/ 60;
    final s = etaSeconds % 60;
    return m > 0 ? '$m мин' : '$sс';
  }

  DriverEnRouteState copyWith({int? etaSeconds}) =>
      DriverEnRouteState(order: order, etaSeconds: etaSeconds ?? this.etaSeconds);

  @override
  List<Object?> get props => [order.id, etaSeconds];
}

/// Водитель прибыл к клиенту
class DriverArrivedState extends DriverState {
  final RideOrder order;
  const DriverArrivedState(this.order);
  @override
  List<Object?> get props => [order.id];
}

/// Поездка активна
class DriverInTripState extends DriverState {
  final RideOrder order;
  final int elapsedSeconds;
  const DriverInTripState({required this.order, required this.elapsedSeconds});
  @override
  List<Object?> get props => [order.id, elapsedSeconds];
}

/// Поездка завершена
class DriverTripDoneState extends DriverState {
  final RideOrder order;
  final double earnings;
  final double totalEarnings;
  final int totalTrips;

  const DriverTripDoneState({
    required this.order,
    required this.earnings,
    required this.totalEarnings,
    required this.totalTrips,
  });

  @override
  List<Object?> get props => [order.id, earnings, totalEarnings];
}
