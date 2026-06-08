import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qayda_taxi_app/data/models/ride_order.dart';

/// Сохраняет и восстанавливает активный заказ между сессиями.
///
/// Ключи хранения:
///   qayda_active_ride_status  — rawValue of RideStatus enum
///   qayda_active_ride_order   — JSON строка с полями заказа
///
/// Схема: при запуске приложения AuthService.initFromPrefs() вызывает
/// RidePersistence.restore() → если статус = searching/accepted/inProgress
/// → GoRouter редиректит на нужный экран.
class RidePersistence {
  static const _kStatus = 'qayda_active_ride_status';
  static const _kOrder  = 'qayda_active_ride_order';

  /// Сохранить активный заказ
  static Future<void> save(RideOrder order) async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'id':          order.id,
      'origin':      order.origin,
      'destination': order.destination,
      'status':      order.status.name,
      'tariff':      order.tariff.name,
      'price':       order.priceKzt,
      'createdAt':   order.createdAt?.toIso8601String(),
    };
    await prefs.setString(_kStatus, order.status.name);
    await prefs.setString(_kOrder, jsonEncode(data));
  }

  /// Очистить (поездка завершена/отменена)
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kStatus);
    await prefs.remove(_kOrder);
  }

  /// Восстановить заказ при запуске
  /// Возвращает null если нет активного заказа
  static Future<RestoredRide?> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final statusRaw = prefs.getString(_kStatus);
    final orderRaw  = prefs.getString(_kOrder);

    if (statusRaw == null || orderRaw == null) return null;

    // Статусы, которые требуют восстановления (не idle/completed/cancelled)
    final activeStatuses = {
      RideStatus.searching.name,
      RideStatus.accepted.name,
      RideStatus.arrived.name,
      RideStatus.inProgress.name,
    };
    if (!activeStatuses.contains(statusRaw)) return null;

    try {
      final data = jsonDecode(orderRaw) as Map<String, dynamic>;
      final order = RideOrder(
        id:          data['id'] as String,
        origin:      data['origin'] as String,
        destination: data['destination'] as String,
        status:      _parseStatus(data['status'] as String),
        tariff:      _parseTariff(data['tariff'] as String),
        priceKzt:    (data['price'] as num).toDouble(),
        createdAt:   data['createdAt'] != null
            ? DateTime.tryParse(data['createdAt'] as String)
            : null,
      );
      return RestoredRide(order: order, status: order.status);
    } catch (_) {
      await clear();
      return null;
    }
  }

  static RideStatus _parseStatus(String s) =>
      RideStatus.values.firstWhere((e) => e.name == s, orElse: () => RideStatus.idle);

  static RideTariff _parseTariff(String s) =>
      RideTariff.values.firstWhere((e) => e.name == s, orElse: () => RideTariff.comfort);
}

class RestoredRide {
  final RideOrder order;
  final RideStatus status;
  RestoredRide({required this.order, required this.status});

  /// Маршрут GoRouter куда редиректить
  String get route {
    switch (status) {
      case RideStatus.searching:
      case RideStatus.accepted:
      case RideStatus.arrived:
        return '/searching';
      case RideStatus.inProgress:
        return '/ride-active';
      default:
        return '/home';
    }
  }
}
