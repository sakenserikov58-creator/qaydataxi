import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// NotificationService — централизованный сервис push-уведомлений.
///
/// Инициализируется один раз в main() перед runApp.
/// Показывает системные уведомления при ключевых событиях RideBloc:
///   - Водитель прибыл → driver_arrived
///   - Поездка началась → trip_started
///   - Поездка завершена → trip_completed
class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  // ID каналов (Android 8+)
  static const _channelId   = 'qayda_ride_channel';
  static const _channelName = 'Уведомления о поездке';
  static const _channelDesc = 'Статус заказа Qayda Taxi';

  // Уникальные ID уведомлений
  static const _idDriverArrived  = 1001;
  static const _idTripStarted    = 1002;
  static const _idTripCompleted  = 1003;
  static const _idGpsTimeout     = 2001;

  /// Инициализация — вызвать в main() ПОСЛЕ WidgetsFlutterBinding.ensureInitialized()
  static Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    // Создаём Android notification channel
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Запрашиваем разрешения на iOS/Android 13+
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  // ─── Ride notifications ────────────────────────────────────────────────────

  /// Водитель прибыл к месту подачи
  static Future<void> showDriverArrived({
    String driverName = 'Водитель',
    String address = 'вашей точки',
  }) async {
    await _show(
      id: _idDriverArrived,
      title: 'Водитель прибыл! 🚗',
      body: '$driverName ждёт вас у $address',
    );
  }

  /// Поездка началась
  static Future<void> showTripStarted({
    String destination = 'пункта назначения',
  }) async {
    await _show(
      id: _idTripStarted,
      title: 'Поездка началась! 🛣',
      body: 'Вы едете в $destination. Хорошей дороги!',
    );
  }

  /// Поездка завершена
  static Future<void> showTripCompleted({required String price}) async {
    await _show(
      id: _idTripCompleted,
      title: 'Поездка завершена ✅',
      body: 'Стоимость: $price. Оцените водителя.',
    );
  }

  /// GPS таймаут (> 10 сек без позиции)
  static Future<void> showGpsTimeout() async {
    await _show(
      id: _idGpsTimeout,
      title: 'Геолокация недоступна 📍',
      body: 'Не удаётся определить местоположение более 10 секунд.',
    );
  }

  // ─── Private ───────────────────────────────────────────────────────────────

  static Future<void> _show({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_initialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(''),
    );

    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(android: androidDetails),
    );
  }
}
