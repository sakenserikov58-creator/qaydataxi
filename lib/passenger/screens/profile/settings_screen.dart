import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:qayda_taxi_app/blocs/theme/theme_bloc.dart';
import 'package:qayda_taxi_app/core/theme.dart';
import 'package:qayda_taxi_app/data/models/app_user.dart';
import 'package:qayda_taxi_app/data/services/auth_service.dart';

/// Экран настроек — Тема, Язык, Уведомления, Стать водителем.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifs = true;

  @override
  Widget build(BuildContext context) {
    final themeBloc = context.read<ThemeBloc>();
    final themeMode = context.watch<ThemeBloc>().state;
    final isDark = themeMode == ThemeMode.dark;
    final lang = context.locale.languageCode;

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.colors.primary),
          onPressed: () => context.pop(),
        ),
        title: Text('Настройки',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: context.colors.onSurface)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── ТЕМА ────────────────────────────────────────────────────────────
          const _SectionHeader('ВНЕШНИЙ ВИД'),
          const SizedBox(height: 10),
          _Card(
            child: Column(children: [
              _SegmentRow(
                label: 'Тема',
                icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                iconColor: isDark ? const Color(0xFFA78BFA) : const Color(0xFFEAB308),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  _ThemeBtn(
                    icon: Icons.wb_sunny_rounded,
                    label: 'Светлая',
                    selected: themeMode == ThemeMode.light,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      themeBloc.changeTheme(ThemeMode.light);
                    },
                  ),
                  const SizedBox(width: 6),
                  _ThemeBtn(
                    icon: Icons.dark_mode_rounded,
                    label: 'Тёмная',
                    selected: themeMode == ThemeMode.dark,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      themeBloc.changeTheme(ThemeMode.dark);
                    },
                  ),
                  const SizedBox(width: 6),
                  _ThemeBtn(
                    icon: Icons.phone_android_rounded,
                    label: 'Авто',
                    selected: themeMode == ThemeMode.system,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      themeBloc.changeTheme(ThemeMode.system);
                    },
                  ),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 16),

          // ── ЯЗЫК ────────────────────────────────────────────────────────────
          const _SectionHeader('ЯЗЫК'),
          const SizedBox(height: 10),
          _Card(
            child: Column(children: [
              _SegmentRow(
                label: 'Язык приложения',
                icon: Icons.translate_rounded,
                iconColor: context.colors.tertiary,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  _LangBtn(
                    flag: '🇷🇺',
                    label: 'Рус',
                    selected: lang == 'ru',
                    onTap: () {
                      HapticFeedback.selectionClick();
                      context.setLocale(const Locale('ru'));
                    },
                  ),
                  const SizedBox(width: 6),
                  _LangBtn(
                    flag: '🇰🇿',
                    label: 'Қаз',
                    selected: lang == 'kk',
                    onTap: () {
                      HapticFeedback.selectionClick();
                      context.setLocale(const Locale('kk'));
                    },
                  ),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 16),

          // ── УВЕДОМЛЕНИЯ ─────────────────────────────────────────────────────
          const _SectionHeader('УВЕДОМЛЕНИЯ'),
          const SizedBox(height: 10),
          _Card(
            child: _SwitchRow(
              label: 'Push-уведомления',
              subtitle: 'Статус поездки, новые заказы',
              icon: Icons.notifications_rounded,
              iconColor: context.colors.primary,
              value: _notifs,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _notifs = v);
              },
            ),
          ),
          const SizedBox(height: 16),

          // ── О ПРИЛОЖЕНИИ ────────────────────────────────────────────────────
          const _SectionHeader('О ПРИЛОЖЕНИИ'),
          const SizedBox(height: 10),
          _Card(
            child: Column(children: [
              const _InfoRow(icon: Icons.info_outline_rounded, label: 'Версия', value: '1.0.0'),
              Divider(height: 1, color: context.colors.outlineVariant),
              const _InfoRow(icon: Icons.location_city_rounded, label: 'Город', value: 'Алматы'),
              Divider(height: 1, color: context.colors.outlineVariant),
              _InfoRow(
                icon: Icons.phone_android_rounded,
                label: 'Поддержка',
                value: '+7 (727) 123-45-67',
                valueColor: context.colors.primary,
              ),
            ]),
          ),
          const SizedBox(height: 24),

          // ── СТАТЬ ВОДИТЕЛЕМ ─────────────────────────────────────────────────
          GestureDetector(
            onTap: () async {
              HapticFeedback.mediumImpact();
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: context.colors.surface,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24)),
                  title: Text('Стать водителем?',
                      style: TextStyle(
                          color: context.colors.onSurface,
                          fontWeight: FontWeight.w800)),
                  content: Text(
                    'Ваш аккаунт будет переключён в режим водителя. '
                    'Заполните ИИН и госномер ТС в профиле.',
                    style: TextStyle(color: context.colors.onSurfaceVariant),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text('Отмена',
                          style: TextStyle(color: context.colors.onSurfaceVariant)),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx, true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: context.colors.brandGradientH,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('Перейти',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              );
              if (confirm == true && mounted) {
                await context.read<AuthService>().switchRole(UserRole.driver);
                if (mounted) context.go('/driver/home');
              }
            },
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: context.colors.brandGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: context.colors.primaryGlow,
              ),
              child: Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.directions_car_rounded,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Стать водителем',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15)),
                    Text('Работайте в своё удовольствие',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12)),
                  ]),
                ),
                const Icon(Icons.arrow_forward_ios_rounded,
                    color: Colors.white, size: 16),
              ]),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ─── Helper Widgets ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.0,
            color: context.colors.onSurfaceVariant));
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: context.colors.cardShadow,
        border: Border.all(color: context.colors.outlineVariant),
      ),
      child: child,
    );
  }
}

class _SegmentRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final Widget child;
  const _SegmentRow({required this.label, required this.icon, required this.iconColor, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.colors.onSurface)),
        ]),
        const SizedBox(height: 12),
        child,
      ]),
    );
  }
}

class _ThemeBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ThemeBtn({required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? context.colors.primaryContainer : context.colors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: selected ? context.colors.primary : context.colors.outlineVariant),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 18,
              color: selected ? context.colors.primary : context.colors.onSurfaceVariant),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: selected ? context.colors.primary : context.colors.onSurfaceVariant)),
        ]),
      ),
    );
  }
}

class _LangBtn extends StatelessWidget {
  final String flag, label;
  final bool selected;
  final VoidCallback onTap;
  const _LangBtn({required this.flag, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? context.colors.primaryContainer : context.colors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: selected ? context.colors.primary : context.colors.outlineVariant),
        ),
        child: Row(children: [
          Text(flag, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? context.colors.primary : context.colors.onSurface)),
        ]),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final String label, subtitle;
  final IconData icon;
  final Color iconColor;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.label, required this.subtitle, required this.icon,
    required this.iconColor, required this.value, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.colors.onSurface)),
            Text(subtitle,
                style: TextStyle(
                    fontSize: 11, color: context.colors.onSurfaceVariant)),
          ]),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: context.colors.primary,
        ),
      ]),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color? valueColor;
  const _InfoRow({required this.icon, required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(children: [
        Icon(icon, size: 18, color: context.colors.onSurfaceVariant),
        const SizedBox(width: 10),
        Text(label,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: context.colors.onSurface)),
        const Spacer(),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? context.colors.onSurfaceVariant)),
      ]),
    );
  }
}
