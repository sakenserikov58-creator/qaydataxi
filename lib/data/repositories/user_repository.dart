import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qayda_taxi_app/data/models/app_user.dart';

/// Репозиторий для работы с пользователями в Firestore.
class UserRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Сохранение или обновление профиля пользователя.
  Future<void> saveUser(AppUser user) async {
    await _db.collection('users').doc(user.id).set(user.toMap(), SetOptions(merge: true));
  }

  /// Стрим данных пользователя для мгновенного обновления профиля.
  Stream<AppUser?> streamUser(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      return AppUser.fromMap(snap.data()!);
    });
  }

  /// Получение данных пользователя один раз.
  Future<AppUser?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromMap(doc.data()!);
  }
}
