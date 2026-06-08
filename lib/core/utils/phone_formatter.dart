import 'package:flutter/services.dart';

/// Форматирует ввод под казахстанский формат: +7 (7ХХ) ХХХ-ХХ-ХХ
class KzPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');

    // Ограничиваем 10 цифрами (без кода страны)
    final limited = digits.length > 10 ? digits.substring(0, 10) : digits;

    final buffer = StringBuffer();
    for (int i = 0; i < limited.length; i++) {
      if (i == 0) buffer.write('(');
      if (i == 3) buffer.write(') ');
      if (i == 6) buffer.write('-');
      if (i == 8) buffer.write('-');
      buffer.write(limited[i]);
    }

    final formatted = buffer.toString();

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Очищает форматированный номер → возвращает только цифры с кодом страны
String normalizeKzPhone(String formatted) {
  final digits = formatted.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('7') && digits.length == 11) {
    return '+$digits';
  }
  if (digits.length == 10) {
    return '+7$digits';
  }
  return '+7$digits';
}
