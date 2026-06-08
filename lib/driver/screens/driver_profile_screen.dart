import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qayda_taxi_app/core/theme.dart';
import 'package:qayda_taxi_app/core/utils/kz_validators.dart';
import 'package:qayda_taxi_app/data/services/auth_service.dart';

/// Экран профиля водителя с валидацией ИИН и госномера РК.
class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _iinCtrl = TextEditingController();
  final _plateCtrl = TextEditingController();

  String? _iinError;
  String? _plateError;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthService>().currentUser;
    _nameCtrl.text = user?.name ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _iinCtrl.dispose();
    _plateCtrl.dispose();
    super.dispose();
  }

  bool get _isValid {
    return _iinError == null &&
        _plateError == null &&
        _iinCtrl.text.trim().length == 12 &&
        _plateCtrl.text.trim().isNotEmpty;
  }

  void _onIinChanged(String val) {
    setState(() => _iinError = KzValidators.iinError(val));
  }

  void _onPlateChanged(String val) {
    final upper = val.toUpperCase();
    // Автоматически переводим в верхний регистр
    if (val != upper) {
      _plateCtrl.value = _plateCtrl.value.copyWith(
        text: upper,
        selection: TextSelection.collapsed(offset: upper.length),
      );
    }
    setState(() => _plateError = KzValidators.plateError(upper));
  }

  void _save() {
    HapticFeedback.mediumImpact();
    setState(() => _saved = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(children: [
          Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
          SizedBox(width: 8),
          Text('Профиль сохранён', style: TextStyle(fontWeight: FontWeight.w600)),
        ]),
        backgroundColor: const Color(0xFF22C55E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.colors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Профиль водителя',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: context.colors.onSurface)),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Аватар ──────────────────────────────────────────────────────
          Center(
            child: Stack(children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  gradient: context.colors.brandGradient,
                  shape: BoxShape.circle,
                  boxShadow: context.colors.primaryGlow,
                ),
                child: const Icon(Icons.person_rounded, color: Colors.white, size: 44),
              ),
              Positioned(
                bottom: 0, right: 0,
                child: Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: context.colors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: context.colors.surface, width: 2),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(user?.phone ?? '—',
                style: TextStyle(
                    color: context.colors.onSurfaceVariant,
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
          ),
          const SizedBox(height: 28),

          // ── Имя ──────────────────────────────────────────────────────────
          const _FieldLabel('ИМЯ'),
          const SizedBox(height: 8),
          _SimpleField(
            controller: _nameCtrl,
            hint: 'Асылбек',
            icon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 20),

          // ── ИИН ──────────────────────────────────────────────────────────
          const _FieldLabel('ИИН'),
          const SizedBox(height: 8),
          _ValidatedField(
            controller: _iinCtrl,
            hint: '880101300123',
            icon: Icons.badge_outlined,
            errorText: _iinError,
            keyboardType: TextInputType.number,
            maxLength: 12,
            onChanged: _onIinChanged,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 4),
          const _HelperText('12-значный ИИН. Проверяется алгоритмом РК.'),
          const SizedBox(height: 20),

          // ── Госномер ─────────────────────────────────────────────────────
          const _FieldLabel('ГОСУДАРСТВЕННЫЙ НОМЕР ТС'),
          const SizedBox(height: 8),
          _ValidatedField(
            controller: _plateCtrl,
            hint: '777 ABC 02',
            icon: Icons.directions_car_outlined,
            errorText: _plateError,
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.characters,
            onChanged: _onPlateChanged,
          ),
          const SizedBox(height: 4),
          const _HelperText('Форматы: 123 ABC 02 · A 123 ABC · AB 1234 A'),
          const SizedBox(height: 32),

          // ── Кнопка Сохранить ─────────────────────────────────────────────
          AnimatedOpacity(
            opacity: _isValid ? 1.0 : 0.4,
            duration: const Duration(milliseconds: 200),
            child: IgnorePointer(
              ignoring: !_isValid,
              child: GestureDetector(
                onTap: _save,
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: context.colors.brandGradientH,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: _isValid ? context.colors.primaryGlow : null,
                  ),
                  child: const Center(
                    child: Text('Сохранить профиль',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16)),
                  ),
                ),
              ),
            ),
          ),

          if (_saved) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.3)),
              ),
              child: const Row(children: [
                Icon(Icons.verified_rounded, color: Color(0xFF22C55E), size: 18),
                SizedBox(width: 8),
                Text('ИИН верифицирован. Профиль активен.',
                    style: TextStyle(
                        color: Color(0xFF22C55E),
                        fontWeight: FontWeight.w600,
                        fontSize: 12)),
              ]),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Helper Widgets ───────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: context.colors.onSurfaceVariant));
  }
}

class _HelperText extends StatelessWidget {
  final String text;
  const _HelperText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: TextStyle(fontSize: 11, color: context.colors.onSurfaceVariant));
  }
}

class _SimpleField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  const _SimpleField({required this.controller, required this.hint, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.colors.outlineVariant),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(children: [
        Icon(icon, size: 18, color: context.colors.onSurfaceVariant),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: controller,
            style: TextStyle(fontWeight: FontWeight.w600, color: context.colors.onSurface),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: context.colors.onSurfaceVariant.withValues(alpha: 0.5)),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ]),
    );
  }
}

class _ValidatedField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final String? errorText;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final List<TextInputFormatter>? inputFormatters;

  const _ValidatedField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.errorText,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.maxLength,
    this.onChanged,
    this.inputFormatters,
  });

  @override
  State<_ValidatedField> createState() => _ValidatedFieldState();
}

class _ValidatedFieldState extends State<_ValidatedField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;
    final borderColor = hasError
        ? context.colors.error
        : _focused
            ? context.colors.primary
            : context.colors.outlineVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Focus(
          onFocusChange: (f) => setState(() => _focused = f),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: context.colors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor, width: _focused ? 2 : 1),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(children: [
              Icon(widget.icon, size: 18,
                  color: hasError ? context.colors.error : context.colors.onSurfaceVariant),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  keyboardType: widget.keyboardType,
                  textCapitalization: widget.textCapitalization,
                  maxLength: widget.maxLength,
                  onChanged: widget.onChanged,
                  inputFormatters: widget.inputFormatters,
                  style: TextStyle(fontWeight: FontWeight.w600, color: context.colors.onSurface),
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    hintStyle: TextStyle(
                        color: context.colors.onSurfaceVariant.withValues(alpha: 0.5)),
                    border: InputBorder.none,
                    isDense: true,
                    counterText: '',
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              if (widget.controller.text.isNotEmpty)
                Icon(
                  hasError ? Icons.cancel_rounded : Icons.check_circle_rounded,
                  size: 18,
                  color: hasError ? context.colors.error : const Color(0xFF22C55E),
                ),
            ]),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          Row(children: [
            Icon(Icons.error_outline_rounded, size: 13, color: context.colors.error),
            const SizedBox(width: 4),
            Text(widget.errorText!,
                style: TextStyle(fontSize: 11, color: context.colors.error)),
          ]),
        ],
      ],
    );
  }
}
