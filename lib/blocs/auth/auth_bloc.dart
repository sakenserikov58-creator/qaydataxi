import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qayda_taxi_app/blocs/auth/auth_event.dart';
import 'package:qayda_taxi_app/blocs/auth/auth_state.dart';
import 'package:qayda_taxi_app/data/services/auth_service.dart';

/// Управляет потоком авторизации:
///   Ввод телефона → OTP → Верификация → Успех/Ошибка
///
/// Обновляет [AuthService] (ChangeNotifier) при успехе,
/// что автоматически тригерит GoRouter redirect.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;

  AuthBloc({required AuthService authService})
      : _authService = authService,
        super(const AuthInitial()) {
    on<PhoneChanged>(_onPhoneChanged);
    on<RoleSelected>(_onRoleSelected);
    on<ContinueTapped>(_onContinueTapped);
    on<OtpChanged>(_onOtpChanged);
    on<VerifyTapped>(_onVerifyTapped);
    on<LogoutRequested>(_onLogoutRequested);
  }

  void _onPhoneChanged(PhoneChanged event, Emitter<AuthState> emit) {
    final current = state is AuthInitial ? state as AuthInitial : const AuthInitial();
    final digits = event.phone.replaceAll(RegExp(r'[^\d]'), '');
    emit(current.copyWith(
      phone: event.phone,
      isPhoneValid: digits.length >= 10,
    ));
  }

  void _onRoleSelected(RoleSelected event, Emitter<AuthState> emit) {
    if (state is AuthInitial) {
      emit((state as AuthInitial).copyWith(role: event.role));
    }
  }

  Future<void> _onContinueTapped(ContinueTapped event, Emitter<AuthState> emit) async {
    if (state is! AuthInitial) return;
    final s = state as AuthInitial;
    if (!s.isPhoneValid) return;

    final phone = '+7${s.phone.replaceAll(RegExp(r'[^\d]'), '').substring(
      (s.phone.replaceAll(RegExp(r'[^\d]'), '').length - 10).clamp(0, 100),
    )}';

    emit(AuthOtpLoading(phone: phone, role: s.role));

    try {
      await _authService.sendOtp(phone);
      emit(AuthOtpSent(phone: phone, role: s.role));
    } catch (e) {
      emit(AuthError(
        message: 'Не удалось отправить SMS. Попробуйте ещё раз.',
        phone: phone,
        role: s.role,
      ));
    }
  }

  void _onOtpChanged(OtpChanged event, Emitter<AuthState> emit) {
    if (state is AuthOtpSent) {
      final s = state as AuthOtpSent;
      emit(AuthVerifying(phone: s.phone, role: s.role, otp: event.otp));
    } else if (state is AuthVerifying) {
      emit((state as AuthVerifying).copyWith(otp: event.otp));
    } else if (state is AuthError) {
      final s = state as AuthError;
      emit(AuthVerifying(phone: s.phone, role: s.role, otp: event.otp));
    }
  }

  Future<void> _onVerifyTapped(VerifyTapped event, Emitter<AuthState> emit) async {
    if (state is! AuthVerifying) return;
    final s = state as AuthVerifying;
    if (s.otp.length < 4) return;

    emit(s.copyWith(isLoading: true));

    try {
      await _authService.verifyAndLogin(
        phone: s.phone,
        otp: s.otp,
        role: s.role,
      );
      // GoRouter will redirect via AuthService.notifyListeners()
      emit(AuthSuccess(_authService.currentUser!));
    } catch (e) {
      emit(AuthError(
        message: 'Неверный код. Попробуйте ещё раз.',
        phone: s.phone,
        role: s.role,
      ));
    }
  }

  Future<void> _onLogoutRequested(LogoutRequested event, Emitter<AuthState> emit) async {
    await _authService.logout();
    emit(const AuthInitial());
  }
}
