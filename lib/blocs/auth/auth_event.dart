import 'package:equatable/equatable.dart';
import 'package:qayda_taxi_app/data/models/app_user.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

/// Пользователь ввёл/изменил номер телефона
class PhoneChanged extends AuthEvent {
  final String phone;
  const PhoneChanged(this.phone);
  @override
  List<Object?> get props => [phone];
}

/// Пользователь переключил роль (Пассажир / Водитель)
class RoleSelected extends AuthEvent {
  final UserRole role;
  const RoleSelected(this.role);
  @override
  List<Object?> get props => [role];
}

/// Нажата кнопка «Продолжить» — запросить SMS
class ContinueTapped extends AuthEvent {
  const ContinueTapped();
}

/// Пользователь ввёл/изменил OTP-код
class OtpChanged extends AuthEvent {
  final String otp;
  const OtpChanged(this.otp);
  @override
  List<Object?> get props => [otp];
}

/// Нажата кнопка «Подтвердить» на экране верификации
class VerifyTapped extends AuthEvent {
  const VerifyTapped();
}

/// Пользователь нажал «Выйти»
class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}
