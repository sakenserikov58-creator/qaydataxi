import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qayda_taxi_app/data/services/sound_service.dart';

/// KaspiPaymentDialog — полноэкранный диалог оплаты в стиле Kaspi Pay.
///
/// Состояния (FSM):
///   loading → confirm → processing → success
///
/// Использование:
/// ```dart
/// final paid = await KaspiPaymentDialog.show(
///   context,
///   amount: 1800,
///   destination: 'Esentai Tower',
///   driverName: 'Асылбек',
/// );
/// if (paid == true) { /* оплата прошла */ }
/// ```
class KaspiPaymentDialog extends StatefulWidget {
  final double amount;
  final String destination;
  final String driverName;

  const KaspiPaymentDialog({
    super.key,
    required this.amount,
    required this.destination,
    required this.driverName,
  });

  static Future<bool?> show(
    BuildContext context, {
    required double amount,
    required String destination,
    required String driverName,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      isDismissible: false,
      builder: (_) => KaspiPaymentDialog(
        amount: amount,
        destination: destination,
        driverName: driverName,
      ),
    );
  }

  @override
  State<KaspiPaymentDialog> createState() => _KaspiPaymentDialogState();
}

enum _PayStep { loading, confirm, processing, success }

class _KaspiPaymentDialogState extends State<KaspiPaymentDialog>
    with TickerProviderStateMixin {
  _PayStep _step = _PayStep.loading;

  // ── Чекмарк анимация (для success) ────────────────────────────────────────
  late final AnimationController _checkCtrl;
  late final Animation<double> _checkAnim;

  // ── Scale bounce (для карточки) ───────────────────────────────────────────
  late final AnimationController _bounceCtrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();

    _checkCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _checkAnim = CurvedAnimation(parent: _checkCtrl, curve: Curves.easeOutBack);

    _bounceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0)
        .animate(CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeOutBack));

    // Симулируем загрузку данных карты (600мс)
    _bounceCtrl.forward();
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _step = _PayStep.confirm);
    });
  }

  @override
  void dispose() {
    _checkCtrl.dispose();
    _bounceCtrl.dispose();
    super.dispose();
  }

  void _onPay() async {
    HapticFeedback.mediumImpact();
    setState(() => _step = _PayStep.processing);

    // Симуляция обработки (1.5 сек)
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    setState(() => _step = _PayStep.success);
    _checkCtrl.forward();
    await SoundService.successHaptic();

    // Закрываем через 2 сек
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _step == _PayStep.confirm ? null : () {},
      child: Container(
        color: Colors.black.withValues(alpha: 0.5),
        child: DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, __) => ScaleTransition(
            scale: _scaleAnim,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: _buildStep(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case _PayStep.loading:
        return const _LoadingStep(key: ValueKey('loading'));
      case _PayStep.confirm:
        return _ConfirmStep(
          key: const ValueKey('confirm'),
          amount: widget.amount,
          destination: widget.destination,
          driverName: widget.driverName,
          onPay: _onPay,
          onCancel: () => Navigator.pop(context, false),
        );
      case _PayStep.processing:
        return const _ProcessingStep(key: ValueKey('processing'));
      case _PayStep.success:
        return _SuccessStep(
          key: const ValueKey('success'),
          checkAnim: _checkAnim,
          amount: widget.amount,
        );
    }
  }
}

// ─── Steps ────────────────────────────────────────────────────────────────────

class _LoadingStep extends StatelessWidget {
  const _LoadingStep({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Kaspi logo style
        Container(
          width: 64, height: 64,
          decoration: const BoxDecoration(
            color: Color(0xFFE53935), // Kaspi red
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text('K',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w900)),
          ),
        ),
        const SizedBox(height: 24),
        const Text('Kaspi Pay',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1A1A2E))),
        const SizedBox(height: 8),
        Text('Загрузка данных...',
            style:
                TextStyle(fontSize: 13, color: Colors.grey.shade500)),
        const SizedBox(height: 32),
        const CircularProgressIndicator(
            color: Color(0xFFE53935), strokeWidth: 3),
      ],
    );
  }
}

class _ConfirmStep extends StatelessWidget {
  final double amount;
  final String destination;
  final String driverName;
  final VoidCallback onPay;
  final VoidCallback onCancel;

  const _ConfirmStep({
    super.key,
    required this.amount,
    required this.destination,
    required this.driverName,
    required this.onPay,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final amountStr =
        amount.toStringAsFixed(0).replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
              (m) => '${m[1]} ',
            );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Header ──────────────────────────────────────────────────────────
        Row(children: [
          Container(
            width: 44, height: 44,
            decoration: const BoxDecoration(
                color: Color(0xFFE53935), shape: BoxShape.circle),
            child: const Center(
              child: Text('K',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900)),
            ),
          ),
          const SizedBox(width: 12),
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Kaspi Pay',
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                    color: Color(0xFF1A1A2E))),
            Text('Оплата поездки',
                style:
                    TextStyle(fontSize: 12, color: Color(0xFF757575))),
          ]),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, color: Color(0xFF757575)),
            onPressed: onCancel,
          ),
        ]),

        const SizedBox(height: 24),
        const Divider(height: 1),
        const SizedBox(height: 24),

        // ── Сумма ───────────────────────────────────────────────────────────
        Center(
          child: Column(children: [
            Text('$amountStr ₸',
                style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.5,
                    color: Color(0xFF1A1A2E))),
            const SizedBox(height: 4),
            Text('за поездку в $destination',
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF757575))),
          ]),
        ),

        const SizedBox(height: 24),

        // ── Детали ──────────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: [
            _DetailRow('Водитель', driverName),
            const SizedBox(height: 10),
            _DetailRow('Маршрут', destination),
            const SizedBox(height: 10),
            const _DetailRow('Метод оплаты', '•••• 4242'),
            const SizedBox(height: 10),
            _DetailRow('Cashback', '+${(amount * 0.05).round()} бонусов',
                valueColor: const Color(0xFFE53935)),
          ]),
        ),

        const SizedBox(height: 28),

        // ── Кнопка оплаты ───────────────────────────────────────────────────
        SizedBox(
          width: double.infinity,
          height: 58,
          child: ElevatedButton(
            onPressed: onPay,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: const Text('Подтвердить в Kaspi.kz',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w800)),
          ),
        ),

        const SizedBox(height: 12),

        // Отмена
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: onCancel,
            child: const Text('Отменить',
                style:
                    TextStyle(color: Color(0xFF757575), fontSize: 15)),
          ),
        ),

        const SizedBox(height: 8),
        Center(
          child: Text('Защищено 256-bit SSL · Kaspi Bank',
              style:
                  TextStyle(fontSize: 11, color: Colors.grey.shade400)),
        ),
      ]),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _DetailRow(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(label,
          style:
              const TextStyle(fontSize: 13, color: Color(0xFF757575))),
      const Spacer(),
      Text(value,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: valueColor ?? const Color(0xFF1A1A2E))),
    ]);
  }
}

class _ProcessingStep extends StatelessWidget {
  const _ProcessingStep({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const CircularProgressIndicator(
          color: Color(0xFFE53935), strokeWidth: 3),
      const SizedBox(height: 24),
      const Text('Обработка платежа...',
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E))),
      const SizedBox(height: 8),
      Text('Пожалуйста, подождите',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
    ]);
  }
}

class _SuccessStep extends StatelessWidget {
  final Animation<double> checkAnim;
  final double amount;
  const _SuccessStep({super.key, required this.checkAnim, required this.amount});

  @override
  Widget build(BuildContext context) {
    final amountStr = amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]} ',
        );

    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      ScaleTransition(
        scale: checkAnim,
        child: Container(
          width: 96, height: 96,
          decoration: const BoxDecoration(
            color: Color(0xFF4CAF50),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 52),
        ),
      ),
      const SizedBox(height: 24),
      const Text('Оплата прошла! ✅',
          style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1A1A2E))),
      const SizedBox(height: 8),
      Text('$amountStr ₸ списано с карты •••• 4242',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          textAlign: TextAlign.center),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8F8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '+${(amount * 0.05).round()} бонусов Kaspi Gold зачислено',
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFFE53935)),
        ),
      ),
    ]);
  }
}
