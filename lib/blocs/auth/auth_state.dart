import 'package:equatable/equatable.dart';
import 'package:qayda_taxi_app/data/models/app_user.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

/// Начальное состояние — форма ввода телефона
class AuthInitial extends AuthState {
  final String phone;
  final UserRole role;
  final bool isPhoneValid;

  const AuthInitial({
    this.phone = '',
    this.role = UserRole.passenger,
    this.isPhoneValid = false,
  });

  AuthInitial copyWith({String? phone, UserRole? role, bool? isPhoneValid}) {
    return AuthInitial(
      phone: phone ?? this.phone,
      role: role ?? this.role,
      isPhoneValid: isPhoneValid ?? this.isPhoneValid,
    );
  }

  @override
  List<Object?> get props => [phone, role, isPhoneValid];
}

/// Идёт запрос OTP (кнопка "Продолжить" нажата)
class AuthOtpLoading extends AuthState {
  final String phone;
  final UserRole role;
  const AuthOtpLoading({required this.phone, required this.role});
  @override
  List<Object?> get props => [phone, role];
}

/// OTP отправлен — переход на экран верификации
class AuthOtpSent extends AuthState {
  final String phone;
  final UserRole role;
  const AuthOtpSent({required this.phone, required this.role});
  @override
  List<Object?> get props => [phone, role];
}

/// Экран верификации — пользователь вводит код
class AuthVerifying extends AuthState {
  final String phone;
  final UserRole role;
  final String otp;
  final bool isLoading;

  const AuthVerifying({
    required this.phone,
    required this.role,
    this.otp = '',
    this.isLoading = false,
  });

  AuthVerifying copyWith({String? otp, bool? isLoading}) {
    return AuthVerifying(
      phone: phone,
      role: role,
      otp: otp ?? this.otp,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [phone, role, otp, isLoading];
}

/// Успешная авторизация
class AuthSuccess extends AuthState {
  final AppUser user;
  const AuthSuccess(this.user);
  @override
  List<Object?> get props => [user];
}

/// Ошибка (неверный код, сеть и т.д.)
class AuthError extends AuthState {
  final String message;
  final String phone;
  final UserRole role;

  const AuthError({
    required this.message,
    required this.phone,
    required this.role,
  });
  @override
  List<Object?> get props => [message, phone, role];
}
