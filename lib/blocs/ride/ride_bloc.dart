import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qayda_taxi_app/blocs/ride/ride_event_state.dart';
import 'package:qayda_taxi_app/data/models/driver_model.dart';
import 'package:qayda_taxi_app/data/models/ride_order.dart';
import 'package:qayda_taxi_app/data/repositories/ride_repository.dart';
import 'package:qayda_taxi_app/data/repositories/user_repository.dart';
import 'package:qayda_taxi_app/data/services/auth_service.dart';
import 'package:qayda_taxi_app/data/services/notification_service.dart';
import 'package:qayda_taxi_app/data/services/ride_persistence.dart';
import 'package:qayda_taxi_app/data/services/sound_service.dart';
import 'package:qayda_taxi_app/data/state/ride_notifier.dart';

/// RideBloc — полный FSM поездки пассажира.
/// Интегрирована с RideRepository и UserRepository для реальной синхронизации.
class RideBloc extends Bloc<RideEvent, RideBlocState> {
  final RideNotifier _rideNotifier;
  final RideRepository _rideRepository;
  final UserRepository _userRepository;
  final AuthService _auth;

  StreamSubscription<RideOrder?>? _orderSub;
  StreamSubscription<int>? _etaSub;
  bool _cancelled = false;

  RideBloc({
    required RideNotifier rideNotifier,
    required RideRepository rideRepository,
    required UserRepository userRepository,
    required AuthService auth,
  })  : _rideNotifier = rideNotifier,
        _rideRepository = rideRepository,
        _userRepository = userRepository,
        _auth = auth,
        super(const RideIdleState()) {
    on<TariffSelected>(_onTariffSelected);
    on<RideRequested>(_onRideRequested);
    on<RideCancelRequested>(_onCancelRequested);
    on<RideDriverFoundEvent>(_onDriverFound);
    on<RideEtaTickEvent>(_onEtaTick);
    on<RidePositionUpdateEvent>(_onPositionUpdate);
    on<RideDriverArrivedEvent>(_onDriverArrived);
    on<RideTripStartedEvent>(_onTripStarted);
    on<RideTripProgressEvent>(_onTripProgress);
    on<RideTripCompletedEvent>(_onTripCompleted);
    on<RateSubmitted>(_onRateSubmitted);
    on<RideReset>(_onReset);
  }

  void _onTariffSelected(TariffSelected event, Emitter<RideBlocState> emit) {
    if (state is RideTariffState) {
      emit((state as RideTariffState).copyWith(selectedIndex: event.index));
    } else {
      emit(RideTariffState(selectedIndex: event.index));
    }
  }

  Future<void> _onRideRequested(RideRequested event, Emitter<RideBlocState> emit) async {
    _cancelled = false;
    final user = _auth.currentUser;
    
    final order = RideOrder(
      id: 'ord_${DateTime.now().millisecondsSinceEpoch}',
      passengerId: user?.id,
      origin: event.origin,
      destination: event.destination,
      originPoint: event.originPoint,
      destinationPoint: event.destinationPoint,
      tariff: event.tariff,
      priceKzt: event.tariff.basePriceKzt,
      createdAt: DateTime.now(),
      status: RideStatus.searching,
    );

    _rideNotifier.startSearch(
      origin: event.origin, 
      destination: event.destination,
      originPoint: event.originPoint,
      destinationPoint: event.destinationPoint,
    );
    emit(RideSearchingState(order));

    _orderSub?.cancel();

    // 1. Сохраняем заказ в Firestore (Водители увидят его в стриме)
    await _rideRepository.createRide(order);

    // 2. Слушаем обновления этого конкретного заказа из БД
    _orderSub = _rideRepository.streamRide(order.id).listen((updatedOrder) async {
      if (_cancelled || updatedOrder == null) return;
      
      switch (updatedOrder.status) {
        case RideStatus.accepted:
          if (updatedOrder.driverId != null) {
            // Подгружаем профиль водителя
            final driverUser = await _userRepository.getUser(updatedOrder.driverId!);
            if (driverUser != null) {
              final dm = DriverModel(
                id: driverUser.id,
                name: driverUser.name,
                carModel: driverUser.vehicleBrand ?? 'Toyota Camry',
                licensePlate: driverUser.vehiclePlate ?? '777 XXX 01',
                rating: driverUser.rating,
              );
              if (!isClosed) {
                add(RideDriverFoundEvent(driver: dm, etaMinutes: 5));
              }
            }
          }
          break;
        case RideStatus.arrived:
          if (!isClosed) add(const RideDriverArrivedEvent());
          break;
        case RideStatus.inProgress:
          if (!isClosed) add(const RideTripStartedEvent());
          break;
        case RideStatus.completed:
          if (!isClosed) add(const RideTripCompletedEvent());
          break;
        case RideStatus.cancelled:
          if (!isClosed) add(const RideReset());
          break;
        default:
          break;
      }
    });
  }

  void _onCancelRequested(RideCancelRequested event, Emitter<RideBlocState> emit) {
    _cancelled = true;
    _orderSub?.cancel();
    _etaSub?.cancel();
    _rideNotifier.cancelRide();
    emit(const RideIdleState());
  }

  void _onDriverFound(RideDriverFoundEvent event, Emitter<RideBlocState> emit) {
    if (state is! RideSearchingState) return;
    final order = (state as RideSearchingState).order;
    _rideNotifier.driverFound();
    emit(RideDriverFoundState(
      order: order,
      driver: event.driver,
      etaSeconds: event.etaMinutes * 60,
      driverLat: event.driver.currentLat,
      driverLng: event.driver.currentLng,
    ));
    
    // Эмуляция тика ETA для наглядности (если не идет сострима)
    _etaSub?.cancel();
    _etaSub = Stream.periodic(const Duration(seconds: 1), (i) => event.etaMinutes * 60 - i - 1)
        .take(event.etaMinutes * 60)
        .listen((rem) => add(RideEtaTickEvent(rem)));
  }

  void _onEtaTick(RideEtaTickEvent event, Emitter<RideBlocState> emit) {
    if (state is RideDriverFoundState) {
      emit((state as RideDriverFoundState).copyWith(etaSeconds: event.secondsRemaining));
    }
  }

  void _onPositionUpdate(RidePositionUpdateEvent event, Emitter<RideBlocState> emit) {
    if (state is RideDriverFoundState) {
      final s = state as RideDriverFoundState;
      emit(s.copyWith(driverLat: event.lat, driverLng: event.lng));
    }
  }

  void _onDriverArrived(RideDriverArrivedEvent event, Emitter<RideBlocState> emit) {
    if (state is RideDriverFoundState) {
      final s = state as RideDriverFoundState;
      _etaSub?.cancel();
      _rideNotifier.driverArrived();
      NotificationService.showDriverArrived(
        driverName: s.driver.name,
        address: s.order.origin,
      );
      emit(RideDriverArrivedState(order: s.order, driver: s.driver));
    }
  }

  void _onTripStarted(RideTripStartedEvent event, Emitter<RideBlocState> emit) {
    if (state is RideDriverArrivedState) {
      final s = state as RideDriverArrivedState;
      _rideNotifier.startRide();
      NotificationService.showTripStarted(destination: s.order.destination);
      emit(RideInProgressBlocState(order: s.order, driver: s.driver, elapsedSeconds: 0));
    }
  }

  void _onTripProgress(RideTripProgressEvent event, Emitter<RideBlocState> emit) {
    if (state is RideInProgressBlocState) {
      final s = state as RideInProgressBlocState;
      emit(RideInProgressBlocState(order: s.order, driver: s.driver, elapsedSeconds: event.elapsedSeconds));
    }
  }

  void _onTripCompleted(RideTripCompletedEvent event, Emitter<RideBlocState> emit) {
    if (state is RideInProgressBlocState) {
      final s = state as RideInProgressBlocState;
      _rideNotifier.completeRide();
      RidePersistence.clear();
      SoundService.successHaptic();
      NotificationService.showTripCompleted(price: '${s.order.priceKzt.toStringAsFixed(0)} ₸');
      emit(RideCompletedState(order: s.order, driver: s.driver));
    }
  }

  void _onRateSubmitted(RateSubmitted event, Emitter<RideBlocState> emit) {
    emit(const RideRatedState());
    _rideNotifier.reset();
  }

  void _onReset(RideReset event, Emitter<RideBlocState> emit) {
    _cancelled = true;
    _orderSub?.cancel();
    _etaSub?.cancel();
    _rideNotifier.reset();
    emit(const RideIdleState());
  }

  @override
  Future<void> close() {
    _orderSub?.cancel();
    _etaSub?.cancel();
    return super.close();
  }
}
