import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:qayda_taxi_app/blocs/auth/auth_bloc.dart';
import 'package:qayda_taxi_app/blocs/auth/auth_event.dart';
import 'package:qayda_taxi_app/blocs/auth/auth_state.dart';
import 'package:qayda_taxi_app/core/theme.dart';
import 'package:qayda_taxi_app/data/models/app_user.dart';
import 'package:qayda_taxi_app/data/services/auth_service.dart';

/// SmsVerificationScreen — подключён к AuthBloc.
class SmsVerificationScreen extends StatefulWidget {
  final String phone;
  final UserRole role;

  const SmsVerificationScreen({
    super.key,
    required this.phone,
    required this.role,
  });

  @override
  State<SmsVerificationScreen> createState() => _SmsVerificationScreenState();
}

class _SmsVerificationScreenState extends State<SmsVerificationScreen> {
  final List<TextEditingController> _controllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  Timer? _resendTimer;
  int _resendSeconds = 59;
  bool _canResend = false;

  bool _showGenderSelection = false;
  AppUser? _verifiedUser;
  UserGender _selectedGender = UserGender.unspecified;

  @override
  void initState() {
    super.initState();
    context.read<AuthBloc>().add(const OtpChanged(''));
    _startResendTimer();
  }

  void _startResendTimer() {
    _resendSeconds = 59;
    _canResend = false;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        if (_resendSeconds > 0) {
          _resendSeconds--;
        } else {
          _canResend = true;
          t.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onDigitChanged(int index, String value) {
    if (value.isNotEmpty && index < 3) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    final otp = _controllers.map((c) => c.text).join();
    context.read<AuthBloc>().add(OtpChanged(otp));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthSuccess) {
          setState(() {
            _showGenderSelection = true;
            _verifiedUser = state.user;
          });
        }
        if (state is AuthInitial) {
          context.go('/login');
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthVerifying && state.isLoading;
        final errorMsg = state is AuthError ? state.message : null;

        return Scaffold(
          backgroundColor: context.colors.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: context.colors.primary),
              onPressed: () {
                context.read<AuthBloc>().add(const LogoutRequested());
                context.pop();
              },
            ),
            title: const Text('QAYDA TAXI',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5)),
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: _showGenderSelection
                ? _buildGenderSelection(context)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: context.colors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(Icons.sms_outlined, color: context.colors.primary, size: 26),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Подтверждение',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Код отправлен на ${widget.phone}',
                        style: TextStyle(color: context.colors.onSurfaceVariant, fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: context.colors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: context.colors.primary.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          widget.role == UserRole.driver
                              ? '🚗  Вход как Водитель'
                              : '👤  Вход как Пассажир',
                          style: TextStyle(
                              color: context.colors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(height: 40),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(
                          4,
                          (i) => _OtpCell(
                            controller: _controllers[i],
                            focusNode: _focusNodes[i],
                            hasError: errorMsg != null,
                            onChanged: (v) => _onDigitChanged(i, v),
                          ),
                        ),
                      ),
                      if (errorMsg != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: context.colors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: context.colors.error.withValues(alpha: 0.3)),
                          ),
                          child: Row(children: [
                            Icon(Icons.error_outline_rounded, color: context.colors.error, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(errorMsg, style: TextStyle(color: context.colors.error, fontSize: 13)),
                            ),
                          ]),
                        ),
                      ],
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: _canResend ? () {
                          context.read<AuthBloc>().add(const ContinueTapped());
                          _startResendTimer();
                        } : null,
                        child: Text(
                          _canResend
                              ? 'Отправить повторно'
                              : 'Отправить повторно через 0:${_resendSeconds.toString().padLeft(2, '0')}',
                          style: TextStyle(
                              color: _canResend
                                  ? context.colors.primaryFixed
                                  : context.colors.onSurfaceVariant,
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: 36),
                      GestureDetector(
                        onTap: isLoading
                            ? null
                            : () => context.read<AuthBloc>().add(const VerifyTapped()),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: double.infinity,
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: isLoading
                                ? LinearGradient(colors: [
                                    context.colors.primary.withValues(alpha: 0.5),
                                    context.colors.secondary.withValues(alpha: 0.5),
                                  ])
                                : context.colors.brandGradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: isLoading
                                ? null
                                : [
                                    const BoxShadow(
                                      color: Color(0x40A3A6FF),
                                      blurRadius: 20,
                                      offset: Offset(0, 8),
                                    ),
                                  ],
                          ),
                          child: isLoading
                              ? Center(child: CircularProgressIndicator(color: context.colors.onPrimaryFixed, strokeWidth: 2))
                              : Center(
                                  child: Text(
                                    'Войти',
                                    style: TextStyle(
                                        color: context.colors.onPrimaryFixed,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 17),
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildGenderSelection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: context.colors.secondary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(Icons.person_outline_rounded, color: context.colors.secondary, size: 26),
        ),
        const SizedBox(height: 20),
        Text(
          'auth.gender_title'.tr(),
          style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5),
        ),
        const SizedBox(height: 8),
        Text(
          'auth.gender_subtitle'.tr(),
          style: TextStyle(color: context.colors.onSurfaceVariant, fontSize: 14),
        ),
        const SizedBox(height: 40),
        Row(
          children: [
            Expanded(
              child: _GenderCard(
                label: 'auth.gender_male'.tr(),
                icon: Icons.male_rounded,
                isSelected: _selectedGender == UserGender.male,
                color: const Color(0xFF3B82F6),
                onTap: () => setState(() => _selectedGender = UserGender.male),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _GenderCard(
                label: 'auth.gender_female'.tr(),
                icon: Icons.female_rounded,
                isSelected: _selectedGender == UserGender.female,
                color: const Color(0xFFFF69B4),
                onTap: () => setState(() => _selectedGender = UserGender.female),
              ),
            ),
          ],
        ),
        const Spacer(),
        GestureDetector(
          onTap: _selectedGender == UserGender.unspecified
              ? null
              : () async {
                  HapticFeedback.heavyImpact();
                  await context.read<AuthService>().updateProfile(gender: _selectedGender);
                  if (mounted) {
                    final isDriver = _verifiedUser?.role == UserRole.driver;
                    context.go(isDriver ? '/driver/home' : '/home');
                  }
                },
          child: AnimatedOpacity(
            opacity: _selectedGender == UserGender.unspecified ? 0.5 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              width: double.infinity,
              height: 60,
              decoration: BoxDecoration(
                gradient: context.colors.brandGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: _selectedGender == UserGender.unspecified
                    ? null
                    : [
                        const BoxShadow(
                          color: Color(0x40A3A6FF),
                          blurRadius: 20,
                          offset: Offset(0, 8),
                        ),
                      ],
              ),
              child: Center(
                child: Text(
                  'auth.registration_complete'.tr(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 17),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _OtpCell extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasError;
  final ValueChanged<String> onChanged;

  const _OtpCell({
    required this.controller,
    required this.focusNode,
    required this.hasError,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 68,
      height: 76,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: context.colors.surfaceContainerHighest,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: hasError
                  ? context.colors.error.withValues(alpha: 0.5)
                  : context.colors.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: context.colors.primary, width: 2),
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}

class _GenderCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _GenderCard({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : context.colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : context.colors.outlineVariant.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : context.colors.onSurfaceVariant, size: 40),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : context.colors.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
