import 'package:latlong2/latlong.dart';

/// FSM состояния жизненного цикла заказа
enum RideStatus {
  idle,
  selecting,
  searching,
  accepted,
  arrived,
  inProgress,
  completed,
  cancelled,
}

/// Тариф поездки
enum RideTariff { economy, comfort, business, minivan, pink }

extension RideTariffExtension on RideTariff {
  String get displayName {
    switch (this) {
      case RideTariff.economy: return 'Эконом';
      case RideTariff.comfort: return 'Комфорт';
      case RideTariff.business: return 'Бизнес';
      case RideTariff.minivan: return 'Минивэн';
      case RideTariff.pink: return 'Pink';
    }
  }

  double get basePriceKzt {
    switch (this) {
      case RideTariff.economy: return 1250;
      case RideTariff.comfort: return 1800;
      case RideTariff.business: return 3400;
      case RideTariff.minivan: return 4200;
      case RideTariff.pink: return 1500;
    }
  }

  int get etaMinutes {
    switch (this) {
      case RideTariff.economy: return 5;
      case RideTariff.comfort: return 3;
      case RideTariff.business: return 2;
      case RideTariff.minivan: return 7;
      case RideTariff.pink: return 4;
    }
  }
}

/// Модель заказа такси для Firestore
class RideOrder {
  final String id;
  final String? passengerId;
  final String? driverId;
  final String origin;
  final String destination;
  final LatLng? originPoint;
  final LatLng? destinationPoint;
  final RideStatus status;
  final RideTariff tariff;
  final double priceKzt;
  final DateTime? createdAt;

  RideOrder({
    required this.id,
    this.passengerId,
    this.driverId,
    required this.origin,
    required this.destination,
    this.originPoint,
    this.destinationPoint,
    this.status = RideStatus.idle,
    this.tariff = RideTariff.comfort,
    required this.priceKzt,
    this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'passengerId': passengerId,
    'driverId': driverId,
    'origin': origin,
    'destination': destination,
    'originLat': originPoint?.latitude,
    'originLng': originPoint?.longitude,
    'destLat': destinationPoint?.latitude,
    'destLng': destinationPoint?.longitude,
    'status': status.name,
    'tariff': tariff.name, // Now correctly uses enum identifier 'economy', 'pink', etc.
    'priceKzt': priceKzt,
    'createdAt': createdAt?.toIso8601String(),
  };

  factory RideOrder.fromMap(Map<String, dynamic> m) => RideOrder(
    id: m['id'] as String? ?? '',
    passengerId: m['passengerId'] as String?,
    driverId: m['driverId'] as String?,
    origin: m['origin'] as String? ?? '',
    destination: m['destination'] as String? ?? '',
    originPoint: (m['originLat'] != null && m['originLng'] != null)
        ? LatLng(m['originLat'] as double, m['originLng'] as double)
        : null,
    destinationPoint: (m['destLat'] != null && m['destLng'] != null)
        ? LatLng(m['destLat'] as double, m['destLng'] as double)
        : null,
    status: RideStatus.values.firstWhere(
      (e) => e.name == m['status'],
      orElse: () => RideStatus.idle,
    ),
    tariff: RideTariff.values.firstWhere(
      (e) => e.name == m['tariff'],
      orElse: () => RideTariff.comfort,
    ),
    priceKzt: (m['priceKzt'] as num?)?.toDouble() ?? 0.0,
    createdAt: m['createdAt'] != null ? DateTime.parse(m['createdAt'] as String) : null,
  );

  RideOrder copyWith({
    RideStatus? status,
    String? driverId,
    RideTariff? tariff,
    double? priceKzt,
  }) {
    return RideOrder(
      id: id,
      passengerId: passengerId,
      driverId: driverId ?? this.driverId,
      origin: origin,
      destination: destination,
      originPoint: originPoint,
      destinationPoint: destinationPoint,
      status: status ?? this.status,
      tariff: tariff ?? this.tariff,
      priceKzt: priceKzt ?? this.priceKzt,
      createdAt: createdAt,
    );
  }

  String get formattedPrice =>
      '${priceKzt.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} ₸';
}
