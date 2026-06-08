/// Казахстанские валидаторы — ИИН, Госномер, Телефон
class KzValidators {
  // ─── ИИН ────────────────────────────────────────────────────────────────────
  // Официальный алгоритм проверки ИИН РК: контрольная сумма Mod 11.
  // Весовые коэффициенты для первого прохода: b1=[1,2,3,4,5,6,7,8,9,10,11]
  // При остатке == 10 используется второй набор: b2=[3,4,5,6,7,8,9,10,11,1,2]
  static bool isValidIin(String iin) {
    iin = iin.trim();
    if (iin.length != 12) return false;

    final digits = <int>[];
    for (final ch in iin.split('')) {
      final d = int.tryParse(ch);
      if (d == null) return false;
      digits.add(d);
    }

    // Первый проход
    const b1 = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];
    int sum = 0;
    for (int i = 0; i < 11; i++) {
      sum += digits[i] * b1[i];
    }
    int control = sum % 11;

    if (control == 10) {
      // Второй проход с другими весами
      const b2 = [3, 4, 5, 6, 7, 8, 9, 10, 11, 1, 2];
      sum = 0;
      for (int i = 0; i < 11; i++) {
        sum += digits[i] * b2[i];
      }
      control = sum % 11;
    }

    return control == digits[11];
  }

  // ─── Номер ТС (Казахстан) ───────────────────────────────────────────────────
  // Допустимые форматы РК:
  //   123 ABC 02   (цифры + буквы + регион)
  //   A 123 ABC    (буква + цифры + буквы)
  //   AB 1234 A    (буквы + цифры + буква)
  static bool isValidPlate(String plate) {
    plate = plate.trim().toUpperCase();
    // Убираем пробелы для унификации проверки
    final cleaned = plate.replaceAll(' ', '');

    // Формат: 3 цифры + 3 буквы латиницы + 2 цифры региона
    final pattern1 = RegExp(r'^\d{3}[A-Z]{3}\d{2}$');
    // Формат: 1 буква + 3 цифры + 3 буквы (транзит, спец.)
    final pattern2 = RegExp(r'^[A-Z]\d{3}[A-Z]{3}$');
    // Формат старого типа: 2 буквы + 4 цифры + 1 буква
    final pattern3 = RegExp(r'^[A-Z]{2}\d{4}[A-Z]$');
    // Формат спецтехники: 2 буквы + 4 цифры
    final pattern4 = RegExp(r'^[A-Z]{2}\d{4}$');

    return pattern1.hasMatch(cleaned) ||
        pattern2.hasMatch(cleaned) ||
        pattern3.hasMatch(cleaned) ||
        pattern4.hasMatch(cleaned);
  }

  // ─── Телефон (РК) ───────────────────────────────────────────────────────────
  // Проверяет что в поле уже введено 10 местных цифр (без +7)
  static bool isPhoneComplete(String localDigits) {
    final digits = localDigits.replaceAll(RegExp(r'\D'), '');
    return digits.length == 10;
  }

  /// Возвращает человекочитаемую ошибку ИИН
  static String? iinError(String iin) {
    final cleaned = iin.trim();
    if (cleaned.isEmpty) return null; // ещё не трогали
    if (cleaned.length < 12) return 'ИИН должен содержать 12 цифр';
    if (!RegExp(r'^\d{12}$').hasMatch(cleaned)) {
      return 'ИИН должен содержать только цифры';
    }
    if (!isValidIin(cleaned)) return 'Некорректный ИИН (ошибка контрольной суммы)';
    return null; // всё ок
  }

  /// Возвращает ошибку госномера
  static String? plateError(String plate) {
    if (plate.trim().isEmpty) return null;
    if (!isValidPlate(plate)) {
      return 'Неверный формат номера (напр: 123 ABC 02)';
    }
    return null;
  }
}
