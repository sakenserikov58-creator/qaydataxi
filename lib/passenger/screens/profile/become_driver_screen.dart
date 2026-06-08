import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:qayda_taxi_app/core/theme.dart';
import 'package:qayda_taxi_app/data/services/auth_service.dart';

/// Экран онбординга водителя — 3 шага:
/// Шаг 1: Проверка ИИН (12 цифр, алгоритм КЗ)
/// Шаг 2: Данные автомобиля (Марка, Номер, Техпаспорт)
/// Шаг 3: Переключение роли в Driver + переход на /splash
class BecomeDriverScreen extends StatefulWidget {
  const BecomeDriverScreen({super.key});

  @override
  State<BecomeDriverScreen> createState() => _BecomeDriverScreenState();
}

class _BecomeDriverScreenState extends State<BecomeDriverScreen>
    with TickerProviderStateMixin {
  int _step = 0;
  bool _loading = false;

  // ── Step 1: IIN ──────────────────────────────────────────────────────────
  final _iinCtrl = TextEditingController();
  String? _iinError;

  // ── Step 2: Vehicle ───────────────────────────────────────────────────────
  final _brandCtrl = TextEditingController();
  final _plateCtrl = TextEditingController();
  final _passportCtrl = TextEditingController();

  // ── Animation ─────────────────────────────────────────────────────────────
  late final AnimationController _slideCtrl;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(1.0, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _iinCtrl.dispose();
    _brandCtrl.dispose();
    _plateCtrl.dispose();
    _passportCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  void _nextStep() {
    _slideCtrl.reset();
    setState(() => _step++);
    _slideCtrl.forward();
  }

  // ── KZ IIN Validation ─────────────────────────────────────────────────────

  bool _validateIin(String iin) {
    if (iin.length != 12) return false;
    if (!RegExp(r'^\d{12}$').hasMatch(iin)) return false;

    // Контрольная сумма (алгоритм КЗ)
    const weights1 = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];
    const weights2 = [3, 4, 5, 6, 7, 8, 9, 10, 11, 1, 2];

    int sum = 0;
    for (int i = 0; i < 11; i++) {
      sum += int.parse(iin[i]) * weights1[i];
    }
    int check = sum % 11;

    if (check == 10) {
      sum = 0;
      for (int i = 0; i < 11; i++) {
        sum += int.parse(iin[i]) * weights2[i];
      }
      check = sum % 11;
    }

    return check == int.parse(iin[11]);
  }

  void _submitIin() {
    final iin = _iinCtrl.text.trim();
    if (!_validateIin(iin)) {
      setState(() => _iinError = 'onboarding.iin_error'.tr());
      HapticFeedback.heavyImpact();
      return;
    }
    setState(() => _iinError = null);
    HapticFeedback.mediumImpact();
    _nextStep();
  }

  void _submitVehicle() {
    if (_brandCtrl.text.trim().isEmpty ||
        _plateCtrl.text.trim().isEmpty ||
        _passportCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('onboarding.fill_all'.tr(),
              style: const TextStyle(fontWeight: FontWeight.w600)),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    _nextStep();
  }

  Future<void> _finishOnboarding() async {
    setState(() => _loading = true);
    HapticFeedback.heavyImpact();

    await context.read<AuthService>().becomeDriver(
          iin: _iinCtrl.text.trim(),
          vehicleBrand: _brandCtrl.text.trim(),
          vehiclePlate: _plateCtrl.text.trim(),
          vehiclePassport: _passportCtrl.text.trim(),
        );

    if (mounted) {
      setState(() => _loading = false);
      context.go('/splash');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _step == 0
            ? IconButton(
                icon: Icon(Icons.close_rounded, color: context.colors.onSurface),
                onPressed: () => context.pop(),
              )
            : IconButton(
                icon: Icon(Icons.arrow_back_ios_rounded, color: context.colors.onSurface),
                onPressed: () {
                  _slideCtrl.reset();
                  setState(() => _step--);
                  _slideCtrl.forward();
                },
              ),
        title: Text(
          'onboarding.title'.tr(),
          style: TextStyle(
            color: context.colors.onSurface,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ── Progress indicator ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: List.generate(3, (i) {
                return Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 4,
                    margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      gradient: i <= _step
                          ? context.colors.brandGradientH
                          : null,
                      color: i > _step ? context.colors.outlineVariant : null,
                    ),
                  ),
                );
              }),
            ),
          ),

          // ── Step content ────────────────────────────────────────────────────
          Expanded(
            child: SlideTransition(
              position: _slideAnim,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: _buildStep(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(BuildContext context) {
    switch (_step) {
      case 0:
        return _StepIin(
          ctrl: _iinCtrl,
          error: _iinError,
          onSubmit: _submitIin,
        );
      case 1:
        return _StepVehicle(
          brandCtrl: _brandCtrl,
          plateCtrl: _plateCtrl,
          passportCtrl: _passportCtrl,
          onSubmit: _submitVehicle,
        );
      case 2:
        return _StepConfirm(
          iin: _iinCtrl.text.trim(),
          brand: _brandCtrl.text.trim(),
          plate: _plateCtrl.text.trim(),
          loading: _loading,
          onConfirm: _finishOnboarding,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

// ─── Step 1: IIN ─────────────────────────────────────────────────────────────

class _StepIin extends StatelessWidget {
  final TextEditingController ctrl;
  final String? error;
  final VoidCallback onSubmit;
  const _StepIin({required this.ctrl, this.error, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _StepTitle('onboarding.step_1'.tr(), 'onboarding.iin_title'.tr(), Icons.badge_rounded),
        const SizedBox(height: 8),
        Text(
          'onboarding.iin_desc'.tr(),
          style: TextStyle(
              color: context.colors.onSurfaceVariant, fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          maxLength: 12,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: TextStyle(
              color: context.colors.onSurface,
              fontSize: 22,
              letterSpacing: 4,
              fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            hintText: 'onboarding.iin_hint'.tr(),
            hintStyle: TextStyle(
                color: context.colors.outlineVariant,
                fontSize: 22,
                letterSpacing: 4),
            counterText: '',
            errorText: error,
            filled: true,
            fillColor: context.colors.surfaceContainerLowest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: context.colors.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: context.colors.primary, width: 2),
            ),
            prefixIcon: Icon(Icons.numbers_rounded, color: context.colors.primary),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'onboarding.iin_standard'.tr(),
          style: TextStyle(
              color: context.colors.onSurfaceVariant.withValues(alpha: 0.7),
              fontSize: 11),
        ),
        const Spacer(),
        _PrimaryButton(label: 'onboarding.next_btn'.tr(), onTap: onSubmit),
      ],
    );
  }
}

// ─── Step 2: Vehicle ─────────────────────────────────────────────────────────

class _StepVehicle extends StatelessWidget {
  final TextEditingController brandCtrl, plateCtrl, passportCtrl;
  final VoidCallback onSubmit;
  const _StepVehicle({
    required this.brandCtrl,
    required this.plateCtrl,
    required this.passportCtrl,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _StepTitle('onboarding.step_2'.tr(), 'onboarding.vehicle_title'.tr(), Icons.directions_car_rounded),
        const SizedBox(height: 24),
        _Field(ctrl: brandCtrl, label: 'onboarding.vehicle_brand'.tr(), hint: 'onboarding.vehicle_brand_hint'.tr(),
            icon: Icons.directions_car_rounded),
        const SizedBox(height: 14),
        _Field(ctrl: plateCtrl, label: 'onboarding.vehicle_plate'.tr(), hint: 'onboarding.vehicle_plate_hint'.tr(),
            icon: Icons.confirmation_number_rounded,
            inputFormatter: FilteringTextInputFormatter.allow(
                RegExp(r'[A-Za-z0-9\s]'))),
        const SizedBox(height: 14),
        _Field(ctrl: passportCtrl, label: 'onboarding.vehicle_passport'.tr(), hint: 'onboarding.vehicle_passport_hint'.tr(),
            icon: Icons.article_rounded),
        const Spacer(),
        _PrimaryButton(label: 'onboarding.next_btn'.tr(), onTap: onSubmit),
      ],
    );
  }
}

// ─── Step 3: Confirm ─────────────────────────────────────────────────────────

class _StepConfirm extends StatelessWidget {
  final String iin, brand, plate;
  final bool loading;
  final VoidCallback onConfirm;
  const _StepConfirm({
    required this.iin,
    required this.brand,
    required this.plate,
    required this.loading,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _StepTitle('onboarding.step_3'.tr(), 'onboarding.confirm_title'.tr(), Icons.check_circle_rounded),
        const SizedBox(height: 24),

        // Summary card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.colors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.colors.outlineVariant),
          ),
          child: Column(
            children: [
              _SummaryRow(Icons.badge_rounded, 'ИИН', iin),
              const Divider(height: 20),
              _SummaryRow(Icons.directions_car_rounded, 'Авто', brand),
              const Divider(height: 20),
              _SummaryRow(Icons.confirmation_number_rounded, 'Номер', plate),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Warning
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.colors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(children: [
            Icon(Icons.info_outline_rounded,
                color: context.colors.primary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'onboarding.warning_text'.tr(),
                style: TextStyle(
                    color: context.colors.onSurface, fontSize: 12, height: 1.5),
              ),
            ),
          ]),
        ),

        const Spacer(),
        loading
            ? const Center(child: CircularProgressIndicator())
            : _PrimaryButton(
                label: 'onboarding.finish_btn'.tr(),
                onTap: onConfirm,
                gradient: true,
              ),
      ],
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _StepTitle extends StatelessWidget {
  final String step, title;
  final IconData icon;
  const _StepTitle(this.step, this.title, this.icon);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: context.colors.brandGradientH,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
      const SizedBox(width: 14),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(step,
            style: TextStyle(
                color: context.colors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2)),
        Text(title,
            style: TextStyle(
                color: context.colors.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.w800)),
      ]),
    ]);
  }
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label, hint;
  final IconData icon;
  final TextInputFormatter? inputFormatter;
  const _Field({
    required this.ctrl,
    required this.label,
    required this.hint,
    required this.icon,
    this.inputFormatter,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      inputFormatters: inputFormatter != null ? [inputFormatter!] : null,
      style: TextStyle(color: context.colors.onSurface, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: context.colors.primary, size: 20),
        filled: true,
        fillColor: context.colors.surfaceContainerLowest,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: context.colors.outlineVariant)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: context.colors.primary, width: 2)),
        labelStyle: TextStyle(color: context.colors.onSurfaceVariant),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _SummaryRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, color: context.colors.primary, size: 18),
      const SizedBox(width: 10),
      Text('$label:',
          style: TextStyle(
              color: context.colors.onSurfaceVariant,
              fontSize: 13,
              fontWeight: FontWeight.w500)),
      const Spacer(),
      Text(value,
          style: TextStyle(
              color: context.colors.onSurface,
              fontSize: 13,
              fontWeight: FontWeight.w700)),
    ]);
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool gradient;
  const _PrimaryButton({required this.label, required this.onTap, this.gradient = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: context.colors.brandGradientH,
          borderRadius: BorderRadius.circular(16),
          boxShadow: context.colors.primaryGlow,
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 15,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
