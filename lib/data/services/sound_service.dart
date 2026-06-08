import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// SoundService — звуки и виброотклик приложения.
///
/// Звук нового заказа водителю:
///   SoundService.playNewOrder();
///
/// Haptic при успешном завершении поездки (двойная вибрация):
///   SoundService.successHaptic();
class SoundService {
  static final _player = AudioPlayer();
  static bool _initialized = false;

  static Future<void> _ensureInit() async {
    if (_initialized) return;
    await _player.setReleaseMode(ReleaseMode.stop);
    _initialized = true;
  }

  /// Звук нового входящего заказа для водителя.
  /// Файл: assets/sounds/new_order.mp3
  static Future<void> playNewOrder() async {
    try {
      await _ensureInit();
      await _player.stop();
      await _player.play(AssetSource('sounds/new_order.mp3'));
    } catch (_) {
      // Если файл не загрузился — только вибрация
      HapticFeedback.vibrate();
    }
  }

  /// Тихий звук для кнопок тарифа (selectionClick).
  static void selectionHaptic() {
    HapticFeedback.selectionClick();
  }

  /// Лёгкий отклик на кнопки действий.
  static void lightTap() {
    HapticFeedback.lightImpact();
  }

  /// Средний отклик (CTA-кнопки, подтверждения).
  static void mediumTap() {
    HapticFeedback.mediumImpact();
  }

  /// Двойная вибрация — успешное завершение поездки / оплата.
  static Future<void> successHaptic() async {
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 120));
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 120));
    HapticFeedback.lightImpact();
  }

  /// Ошибка / отмена — тяжёлый одиночный.
  static void errorHaptic() {
    HapticFeedback.heavyImpact();
  }

  static void dispose() {
    _player.dispose();
  }
}
