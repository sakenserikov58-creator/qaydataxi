import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:qayda_taxi_app/blocs/auth/auth_bloc.dart';
import 'package:qayda_taxi_app/blocs/auth/auth_event.dart';
import 'package:qayda_taxi_app/blocs/auth/auth_state.dart';
import 'package:qayda_taxi_app/core/theme.dart';
import 'package:qayda_taxi_app/core/utils/phone_formatter.dart';
import 'package:qayda_taxi_app/data/models/app_user.dart';

/// LoginScreen — Light Mode, premium design.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneCtrl = TextEditingController();

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthOtpSent) {
          context.push('/verify', extra: {
            'phone': state.phone,
            'role': state.role,
          });
        }
        if (state is AuthSuccess) {
          final isDriver = state.user.role == UserRole.driver;
          context.go(isDriver ? '/driver/home' : '/home');
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthOtpLoading;
        final currentRole = _extractRole(state);

        return Scaffold(
          backgroundColor: context.colors.background,
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),

                    // ── Logo row ─────────────────────────────────────────────
                    Row(children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: context.colors.brandGradient,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: context.colors.primaryGlow,
                        ),
                        child: const Icon(Icons.local_taxi_rounded,
                            color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Text('QAYDA',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                              color: context.colors.onSurface)),
                    ]),
                    const SizedBox(height: 40),

                    // ── Hero text ─────────────────────────────────────────────
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                            height: 1.15,
                            color: context.colors.onSurface),
                        children: [
                          const TextSpan(text: 'Поездка\nначнётся\nс '),
                          TextSpan(
                              text: 'комфорта',
                              style: TextStyle(color: context.colors.primary)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Введите номер телефона для входа',
                      style: TextStyle(
                          color: context.colors.onSurfaceVariant,
                          fontSize: 15,
                          fontWeight: FontWeight.w400),
                    ),
                    const SizedBox(height: 40),

                    // ── Auth card ─────────────────────────────────────────────
                    Container(
                      decoration: BoxDecoration(
                        color: context.colors.surface,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: context.colors.elevatedShadow,
                        border: Border.all(color: context.colors.outlineVariant),
                      ),
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Role selector
                          _RoleSelector(
                            selected: currentRole,
                            onChanged: (r) =>
                                context.read<AuthBloc>().add(RoleSelected(r)),
                          ),
                          const SizedBox(height: 24),

                          // Phone label
                          Text('НОМЕР ТЕЛЕФОНА',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                  color: context.colors.onSurfaceVariant)),
                          const SizedBox(height: 8),

                          // Phone field
                          _PhoneField(
                            controller: _phoneCtrl,
                            onChanged: (v) =>
                                context.read<AuthBloc>().add(PhoneChanged(v)),
                          ),
                          const SizedBox(height: 16),

                          // Terms
                          RichText(
                            text: TextSpan(
                              style: TextStyle(
                                  fontSize: 12,
                                  color: context.colors.onSurfaceVariant,
                                  height: 1.5),
                              children: [
                                const TextSpan(
                                    text: 'Нажимая «Продолжить», вы принимаете '),
                                TextSpan(
                                    text: 'Пользовательское соглашение',
                                    style: TextStyle(
                                        color: context.colors.primary,
                                        fontWeight: FontWeight.w600)),
                                const TextSpan(text: ' и '),
                                TextSpan(
                                    text: 'Политику конфиденциальности',
                                    style: TextStyle(
                                        color: context.colors.primary,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Error state
                          if (state is AuthError) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: context.colors.errorContainer,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: context.colors.error.withValues(alpha: 0.3)),
                              ),
                              child: Row(children: [
                                Icon(Icons.error_outline_rounded,
                                    color: context.colors.error, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text((state).message,
                                      style: TextStyle(
                                          color: context.colors.errorDim,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500)),
                                ),
                              ]),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // CTA button — неактивна если номер неполный
                          Builder(builder: (ctx) {
                            final isValid = state is AuthInitial
                                ? (state).isPhoneValid
                                : false;
                            final buttonActive = isValid && !isLoading;

                            return AnimatedOpacity(
                              opacity: buttonActive ? 1.0 : 0.45,
                              duration: const Duration(milliseconds: 250),
                              child: IgnorePointer(
                                ignoring: !buttonActive,
                                child: GestureDetector(
                                  onTap: () {
                                    HapticFeedback.mediumImpact();
                                    context
                                        .read<AuthBloc>()
                                        .add(const ContinueTapped());
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    height: 58,
                                    decoration: BoxDecoration(
                                      gradient: context.colors.brandGradientH,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: buttonActive
                                          ? context.colors.primaryGlow
                                          : null,
                                    ),
                                    child: isLoading
                                        ? const Center(
                                            child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2.5))
                                        : const Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text('Продолжить',
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 17,
                                                      letterSpacing: -0.3)),
                                              SizedBox(width: 8),
                                              Icon(
                                                  Icons.arrow_forward_rounded,
                                                  color: Colors.white,
                                                  size: 20),
                                            ],
                                          ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ── Social login ──────────────────────────────────────────
                    Row(children: [
                      Expanded(
                          child: Divider(color: context.colors.outlineVariant)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('или войти через',
                            style: TextStyle(
                                fontSize: 12,
                                color: context.colors.onSurfaceVariant)),
                      ),
                      Expanded(
                          child: Divider(color: context.colors.outlineVariant)),
                    ]),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _SocialBtn(
                          icon: Icons.g_mobiledata_rounded,
                          label: 'Google',
                          onTap: () {},
                        ),
                        const SizedBox(width: 12),
                        _SocialBtn(
                          icon: Icons.apple_rounded,
                          label: 'Apple',
                          onTap: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  UserRole _extractRole(AuthState state) {
    if (state is AuthInitial) return state.role;
    if (state is AuthOtpLoading) return state.role;
    if (state is AuthOtpSent) return state.role;
    if (state is AuthVerifying) return state.role;
    if (state is AuthError) return state.role;
    return UserRole.passenger;
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _RoleSelector extends StatelessWidget {
  final UserRole selected;
  final ValueChanged<UserRole> onChanged;
  const _RoleSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.colors.outlineVariant),
      ),
      child: Row(children: [
        _Pill('👤 Пассажир', selected == UserRole.passenger,
            () => onChanged(UserRole.passenger)),
        _Pill('🚗 Водитель', selected == UserRole.driver,
            () => onChanged(UserRole.driver)),
      ]),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Pill(this.label, this.active, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: active ? context.colors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: active ? context.colors.cardShadow : null,
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: active ? context.colors.primary : context.colors.onSurfaceVariant)),
          ),
        ),
      ),
    );
  }
}

class _PhoneField extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _PhoneField({required this.controller, required this.onChanged});

  @override
  State<_PhoneField> createState() => _PhoneFieldState();
}

class _PhoneFieldState extends State<_PhoneField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _focused ? context.colors.primary : context.colors.outlineVariant,
            width: _focused ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(children: [
          Text('+7',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: context.colors.primary)),
          const SizedBox(width: 4),
          Icon(Icons.expand_more, color: context.colors.onSurfaceVariant, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: widget.controller,
              keyboardType: TextInputType.phone,
              inputFormatters: [KzPhoneFormatter()],
              onChanged: widget.onChanged,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: context.colors.onSurface),
              decoration: InputDecoration(
                hintText: '(700) 000-00-00',
                hintStyle: TextStyle(
                    color: context.colors.onSurfaceVariant.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w400),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                fillColor: Colors.transparent,
                filled: false,
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _SocialBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SocialBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.colors.outlineVariant),
          boxShadow: context.colors.cardShadow,
        ),
        child: Row(children: [
          Icon(icon, color: context.colors.onSurface, size: 22),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                  color: context.colors.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 14)),
        ]),
      ),
    );
  }
}
