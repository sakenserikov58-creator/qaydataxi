import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qayda_taxi_app/data/models/app_user.dart';
import 'package:qayda_taxi_app/data/models/ride_order.dart';

/// Сервис для работы с Firebase Firestore.
/// Реализует реальную синхронизацию данных между Пассажиром и Водителем.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Users ─────────────────────────────────────────────────────────────────

  /// Сохранение/обновление данных пользователя
  Future<void> saveUser(AppUser user) async {
    await _db.collection('users').doc(user.id).set(user.toMap(), SetOptions(merge: true));
  }

  /// Стрим данных пользователя
  Stream<AppUser?> streamUser(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      return AppUser.fromMap(snap.data()!);
    });
  }

  // ─── Rides ─────────────────────────────────────────────────────────────────

  /// Создание нового заказа (Пассажир)
  Future<void> createRide(RideOrder order) async {
    await _db.collection('rides').doc(order.id).set({
      ...order.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Обновление статуса заказа
  Future<void> updateRideStatus(String rideId, RideStatus status, {String? driverId}) async {
    final data = <String, dynamic>{'status': status.name};
    if (driverId != null) data['driverId'] = driverId;
    await _db.collection('rides').doc(rideId).update(data);
  }

  /// Стрим конкретной поездки (Пассажир слушает статус)
  Stream<RideOrder?> streamRide(String rideId) {
    return _db.collection('rides').doc(rideId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return RideOrder.fromMap(snap.data()!);
    });
  }

  /// Стрим доступных заказов для водителя (статус 'searching')
  /// Если тариф 'pink', водитель должен быть женщиной (фильтрация на уровне клиента или правил).
  Stream<List<RideOrder>> streamAvailableOrders(UserGender driverGender) {
    return _db
        .collection('rides')
        .where('status', isEqualTo: RideStatus.searching.name)
        .snapshots()
        .map((snap) {
      final rides = snap.docs.map((doc) => RideOrder.fromMap(doc.data())).toList();
      
      // Фильтрация тарифа Pink: только если водитель — женщина
      return rides.where((r) {
        if (r.tariff == RideTariff.pink) {
          return driverGender == UserGender.female;
        }
        return true;
      }).toList();
    });
  }
}
