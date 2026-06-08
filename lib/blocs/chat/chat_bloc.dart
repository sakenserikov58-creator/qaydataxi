import 'dart:async';
import 'package:flutter/foundation.dart';

/// Модель одного сообщения в чате
class ChatMessage {
  final String id;
  final String text;
  final bool isUser; // true = пассажир, false = водитель
  final DateTime sentAt;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.sentAt,
    this.isRead = false,
  });

  String get timeFormatted {
    final h = sentAt.hour.toString().padLeft(2, '0');
    final m = sentAt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  ChatMessage copyWith({bool? isRead}) => ChatMessage(
        id: id,
        text: text,
        isUser: isUser,
        sentAt: sentAt,
        isRead: isRead ?? this.isRead,
      );
}

/// ChatBloc (ChangeNotifier) — управляет состоянием чата с водителем.
///
/// Особенности:
/// - Сообщения хранятся в in-memory List (не персистентны — закрыл чат = история очищена)
/// - StreamController транслирует каждое новое сообщение → ListView авто-прокручивается
/// - Авто-ответы водителя через 1.5–3 сек (mock)
/// - Быстрые ответы (quick replies) для частых фраз
class ChatBloc extends ChangeNotifier {
  ChatBloc({String? driverName, String? vehicle})
      : _driverName = driverName ?? 'Водитель',
        _vehicle = vehicle ?? 'Toyota Camry' {
    // Вводное сообщение от водителя
    _addDriverMessage('Я уже подъезжаю, буду через несколько минут 🚗');
  }

  final String _driverName;
  final String _vehicle;
  String get driverName => _driverName;
  String get vehicle => _vehicle;

  final List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  // Stream для auto-scroll — каждое новое сообщение пушит true
  final _newMsgController = StreamController<void>.broadcast();
  Stream<void> get onNewMessage => _newMsgController.stream;

  bool _isDriverTyping = false;
  bool get isDriverTyping => _isDriverTyping;

  // Быстрые ответы
  static const quickReplies = [
    'Уже выхожу 🏃',
    'Подождите 1 мин ⏱',
    'Где вы? 📍',
    'Спасибо! 🙏',
  ];

  // Mock-ответы водителя
  static const _driverReplies = [
    'Понял, жду вас ✅',
    'Хорошо, никуда не уезжаю',
    'Стою у главного входа 🚗',
    'Ок, понял',
    'Торопитесь, мест нет 😄',
    'Всё хорошо, не спешите',
  ];

  /// Отправить сообщение от пассажира
  void sendMessage(String text) {
    if (text.trim().isEmpty) return;

    _messages.add(ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: text.trim(),
      isUser: true,
      sentAt: DateTime.now(),
    ));
    _newMsgController.add(null);
    notifyListeners();

    // Имитируем "водитель печатает" → ответ через 1.5–2.5 сек
    _simulateDriverTyping();
  }

  void _simulateDriverTyping() {
    _isDriverTyping = true;
    notifyListeners();

    final delay = 1500 + (_messages.length * 100 % 1000);
    Future.delayed(Duration(milliseconds: delay), () {
      if (!_newMsgController.isClosed) {
        _isDriverTyping = false;
        final reply = _driverReplies[
            _messages.length % _driverReplies.length];
        _addDriverMessage(reply);
      }
    });
  }

  void _addDriverMessage(String text) {
    _messages.add(ChatMessage(
      id: 'drv_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      isUser: false,
      sentAt: DateTime.now(),
    ));
    _newMsgController.add(null);
    notifyListeners();
  }

  /// Пометить все входящие как прочитанные
  void markAllRead() {
    for (var i = 0; i < _messages.length; i++) {
      if (!_messages[i].isUser && !_messages[i].isRead) {
        _messages[i] = _messages[i].copyWith(isRead: true);
      }
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _newMsgController.close();
    super.dispose();
  }
}
