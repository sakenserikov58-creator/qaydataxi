import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qayda_taxi_app/data/models/app_user.dart';
import 'package:qayda_taxi_app/data/models/ride_order.dart';

/// Репозиторий для управления поездками в реальном времени.
class RideRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Пассажир создает заказ -> статус 'searching'.
  Future<void> createRide(RideOrder order) async {
    await _db.collection('rides').doc(order.id).set({
      ...order.toMap(),
      'status': RideStatus.searching.name,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Обновление статуса заказа (accepted, arrived, inProgress, etc.)
  /// Если водитель принимает заказ, он передает свой driverId.
  Future<void> updateRideStatus(String rideId, RideStatus status, {String? driverId}) async {
    final data = <String, dynamic>{
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (driverId != null) {
      data['driverId'] = driverId;
    }
    await _db.collection('rides').doc(rideId).update(data);
  }

  /// Стрим конкретной поездки для пассажира (слушает изменения статуса).
  Stream<RideOrder?> streamRide(String rideId) {
    return _db.collection('rides').doc(rideId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return RideOrder.fromMap(snap.data()!);
    });
  }

  /// Стрим всех доступных заказов для водителя (статус 'searching').
  /// Здесь реализуется Deep Logic тарифа Pink: водители-мужчины не видят Pink заказы.
  Stream<List<RideOrder>> streamAvailableOrders(UserGender driverGender) {
    return _db
        .collection('rides')
        .where('status', isEqualTo: RideStatus.searching.name)
        .snapshots()
        .map((snap) {
      final rides = snap.docs.map((doc) => RideOrder.fromMap(doc.data())).toList();
      
      // Фильтрация тарифа Pink: только если водитель — женщина
      return rides.where((ride) {
        if (ride.tariff == RideTariff.pink) {
          return driverGender == UserGender.female;
        }
        return true;
      }).toList();
    });
  }
}
