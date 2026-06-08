import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:qayda_taxi_app/data/services/notification_service.dart';

/// LocationService — централизованное управление GPS.
///
/// Таймаут 10 сек — если за это время позиция не получена,
/// показываем системное уведомление и SnackBar.
class LocationService {
  static const _kTimeout = Duration(seconds: 10);

  /// Запрашивает разрешение и возвращает текущую позицию.
  /// При отказе или таймауте — показывает SnackBar + уведомление.
  static Future<LatLng?> requestAndGetPosition(BuildContext context) async {
    // 1. Сервис GPS включён?
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (context.mounted) {
        _showSnackBar(
          context,
          '📍 GPS отключён. Включите геолокацию в настройках.',
          action: const SnackBarAction(
            label: 'Настройки',
            onPressed: Geolocator.openLocationSettings,
          ),
        );
      }
      return null;
    }

    // 2. Разрешения
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (context.mounted) {
          _showSnackBar(
            context,
            '📍 Разрешение на геолокацию отклонено. Карта использует центр Алматы.',
          );
        }
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (context.mounted) _showPermissionDialog(context);
      return null;
    }

    // 3. Получаем позицию с жёстким таймаутом 10 сек
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: _kTimeout, // встроенный таймаут geolocator
        ),
      ).timeout(
        _kTimeout,
        onTimeout: () => throw TimeoutException('GPS timeout'),
      );
      return LatLng(position.latitude, position.longitude);

    } on TimeoutException {
      // GPS не ответил за 10 сек → системное уведомление
      await NotificationService.showGpsTimeout();
      if (context.mounted) {
        _showSnackBar(
          context,
          '📍 Не удаётся определить местоположение > 10 сек.',
          duration: const Duration(seconds: 6),
        );
      }
      return null;

    } catch (_) {
      if (context.mounted) {
        _showSnackBar(context, '📍 Не удалось определить местоположение.');
      }
      return null;
    }
  }

  /// Проверяет разрешения БЕЗ запроса
  static Future<bool> hasPermission() async {
    final perm = await Geolocator.checkPermission();
    return perm == LocationPermission.always ||
        perm == LocationPermission.whileInUse;
  }

  static void _showSnackBar(
    BuildContext context,
    String message, {
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 4),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: action,
        duration: duration,
      ),
    );
  }

  static void _showPermissionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Геолокация'),
        content: const Text(
          'Разрешение заблокировано навсегда. '
          'Откройте настройки приложения, чтобы включить геолокацию.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Geolocator.openAppSettings();
            },
            child: const Text('Настройки'),
          ),
        ],
      ),
    );
  }
}
