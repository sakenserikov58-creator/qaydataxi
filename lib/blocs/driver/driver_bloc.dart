import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qayda_taxi_app/blocs/driver/driver_event_state.dart';
import 'package:qayda_taxi_app/data/models/app_user.dart';
import 'package:qayda_taxi_app/data/models/ride_order.dart';
import 'package:qayda_taxi_app/data/repositories/ride_repository.dart';
import 'package:qayda_taxi_app/data/services/auth_service.dart';
import 'package:qayda_taxi_app/data/services/sound_service.dart';

/// DriverBloc — полный FSM водителя.
/// Интегрирован с RideRepository для реальной синхронизации заказов.
class DriverBloc extends Bloc<DriverEvent, DriverState> {
  final RideRepository _rideRepository;
  final AuthService _auth;

  StreamSubscription<List<RideOrder>>? _incomingSub;
  StreamSubscription<RideOrder?>? _tripSub;
  
  double _totalEarnings = 0;
  int _totalTrips = 0;

  DriverBloc({
    required RideRepository rideRepository,
    required AuthService auth,
  })  : _rideRepository = rideRepository,
        _auth = auth,
        super(const DriverOfflineState()) {
    on<DriverGoOnline>(_onGoOnline);
    on<DriverGoOffline>(_onGoOffline);
    on<DriverOrderReceived>(_onOrderReceived);
    on<DriverOrderAccepted>(_onOrderAccepted);
    on<DriverOrderDeclined>(_onOrderDeclined);
    on<DriverArrivedAtPickup>(_onArrivedAtPickup);
    on<DriverTripStarted>(_onTripStarted);
    on<DriverTripCompleted>(_onTripCompleted);
    on<DriverEtaTick>(_onEtaTick);
    on<DriverTripProgress>(_onTripProgress);
  }

  Future<void> _onGoOnline(DriverGoOnline event, Emitter<DriverState> emit) async {
    emit(DriverOnlineState(
      todayEarnings: _totalEarnings,
      tripsCount: _totalTrips,
    ));
    _waitForOrder();
  }

  void _onGoOffline(DriverGoOffline event, Emitter<DriverState> emit) {
    _incomingSub?.cancel();
    _tripSub?.cancel();
    emit(const DriverOfflineState());
  }

  void _onOrderReceived(DriverOrderReceived event, Emitter<DriverState> emit) {
    if (state is DriverOnlineState) {
      // 🔔 Звук + вибрация: новый заказ!
      SoundService.playNewOrder();
      emit(DriverHasOrderState(event.order));
    }
  }

  Future<void> _onOrderAccepted(DriverOrderAccepted event, Emitter<DriverState> emit) async {
    if (state is! DriverHasOrderState) return;
    final order = (state as DriverHasOrderState).order;
    final user = _auth.currentUser;

    _incomingSub?.cancel(); // перестаём слушать новые заказы
    _tripSub?.cancel();
    
    // 1. Обновляем статус в Firestore (Пассажир увидит это мгновенно)
    await _rideRepository.updateRideStatus(
      order.id, 
      RideStatus.accepted, 
      driverId: user?.id ?? 'drv_unknown'
    );
    
    // 2. Слушаем изменения этого заказа (напр. отмену пассажиром)
    _tripSub = _rideRepository.streamRide(order.id).listen((updatedOrder) {
      if (isClosed || updatedOrder == null) return;
      if (updatedOrder.status == RideStatus.cancelled) {
        add(const DriverGoOffline()); // Или спец событие отмены
      }
    });

    // Начальное состояние: едем к клиенту (имитируем ETA)
    const initialEta = 300; // 5 минут
    emit(DriverEnRouteState(order: order, etaSeconds: initialEta));
  }

  void _onOrderDeclined(DriverOrderDeclined event, Emitter<DriverState> emit) {
    emit(DriverOnlineState(
      todayEarnings: _totalEarnings,
      tripsCount: _totalTrips,
    ));
    _waitForOrder();
  }

  Future<void> _onArrivedAtPickup(DriverArrivedAtPickup event, Emitter<DriverState> emit) async {
    if (state is DriverEnRouteState) {
      final order = (state as DriverEnRouteState).order;
      await _rideRepository.updateRideStatus(order.id, RideStatus.arrived);
      emit(DriverArrivedState(order));
    }
  }

  Future<void> _onTripStarted(DriverTripStarted event, Emitter<DriverState> emit) async {
    if (state is DriverArrivedState) {
      final order = (state as DriverArrivedState).order;
      await _rideRepository.updateRideStatus(order.id, RideStatus.inProgress);
      emit(DriverInTripState(
        order: order,
        elapsedSeconds: 0,
      ));
    }
  }

  Future<void> _onTripCompleted(DriverTripCompleted event, Emitter<DriverState> emit) async {
    if (state is DriverInTripState) {
      final order = (state as DriverInTripState).order;
      
      // Завершаем в БД
      await _rideRepository.updateRideStatus(order.id, RideStatus.completed);
      
      _totalEarnings += order.priceKzt;
      _totalTrips += 1;
      // 🎉 Двойная вибрация: поездка завершена
      SoundService.successHaptic();
      emit(DriverTripDoneState(
        order: order,
        earnings: order.priceKzt,
        totalEarnings: _totalEarnings,
        totalTrips: _totalTrips,
      ));
    }
  }

  void _onEtaTick(DriverEtaTick event, Emitter<DriverState> emit) {
    if (state is DriverEnRouteState) {
      emit((state as DriverEnRouteState).copyWith(etaSeconds: event.secondsRemaining));
    }
  }

  void _onTripProgress(DriverTripProgress event, Emitter<DriverState> emit) {
    if (state is DriverInTripState) {
      final s = state as DriverInTripState;
      emit(DriverInTripState(order: s.order, elapsedSeconds: event.elapsed));
    }
  }

  void continueOnline() {
    emit(DriverOnlineState(todayEarnings: _totalEarnings, tripsCount: _totalTrips));
    _waitForOrder();
  }

  void _waitForOrder() {
    _incomingSub?.cancel();
    final gender = _auth.currentUser?.gender ?? UserGender.unspecified;
    
    _incomingSub = _rideRepository.streamAvailableOrders(gender).listen((orders) {
      if (!isClosed && state is DriverOnlineState && orders.isNotEmpty) {
        // Берем первый доступный заказ
        add(DriverOrderReceived(orders.first));
      }
    });
  }

  @override
  Future<void> close() {
    _incomingSub?.cancel();
    _tripSub?.cancel();
    return super.close();
  }
}
