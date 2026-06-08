import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qayda_taxi_app/blocs/chat/chat_bloc.dart';
import 'package:qayda_taxi_app/core/theme.dart';

/// ChatScreen — полноценный чат пассажира с водителем.
///
/// Архитектура:
///   - ChatBloc (ChangeNotifier) — список сообщений + авто-ответы водителя
///   - StreamSubscription<void> → авто-прокрутка при новом сообщении
///   - Quick replies для быстрых ответов
///   - "Водитель печатает..." индикатор
class ChatScreen extends StatefulWidget {
  final String? driverName;
  final String? vehicle;

  const ChatScreen({super.key, this.driverName, this.vehicle});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final ChatBloc _chatBloc;
  late final ScrollController _scroll;
  final _textCtrl = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _chatBloc = ChatBloc(
      driverName: widget.driverName,
      vehicle: widget.vehicle,
    );
    _scroll = ScrollController();

    // Авто-прокрутка при каждом новом сообщении
    _chatBloc.onNewMessage.listen((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    });

    _chatBloc.markAllRead();
  }

  @override
  void dispose() {
    _chatBloc.dispose();
    _scroll.dispose();
    _textCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scroll.hasClients) {
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _send([String? override]) {
    final text = override ?? _textCtrl.text;
    if (text.trim().isEmpty) return;
    HapticFeedback.lightImpact();
    _chatBloc.sendMessage(text);
    if (override == null) {
      _textCtrl.clear();
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ChatBloc>.value(
      value: _chatBloc,
      child: Scaffold(
        backgroundColor: context.colors.background,
        appBar: _buildAppBar(context),
        body: Column(children: [
          Expanded(child: _MessageList(scroll: _scroll)),
          _QuickReplies(onTap: _send),
          _InputBar(
            ctrl: _textCtrl,
            focus: _focusNode,
            onSend: _send,
          ),
        ]),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: context.colors.topBarColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded,
            color: context.colors.onSurface, size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
      titleSpacing: 0,
      title: Row(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            gradient: context.colors.brandGradient,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person_rounded, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            widget.driverName ?? 'Водитель',
            style: TextStyle(
                color: context.colors.onSurface,
                fontWeight: FontWeight.w800,
                fontSize: 15),
          ),
          Text(
            'На заказе · ${widget.vehicle ?? 'Toyota Camry'}',
            style: TextStyle(
                color: context.colors.onSurfaceVariant,
                fontSize: 11,
                letterSpacing: 0.3),
          ),
        ]),
      ]),
      actions: [
        IconButton(
          icon:
              Icon(Icons.call_rounded, color: context.colors.primary, size: 22),
          onPressed: () {
            HapticFeedback.lightImpact();
            // В prod — вызов через SIP/WebRTC
          },
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: context.colors.outlineVariant),
      ),
    );
  }
}

// ─── Message List ─────────────────────────────────────────────────────────────

class _MessageList extends StatelessWidget {
  final ScrollController scroll;
  const _MessageList({required this.scroll});

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatBloc>(
      builder: (_, bloc, __) {
        final messages = bloc.messages;
        return ListView.builder(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          itemCount: messages.length + (bloc.isDriverTyping ? 1 : 0) + 1,
          itemBuilder: (_, i) {
            // Header
            if (i == 0) return _DateHeader();

            // Typing indicator
            if (bloc.isDriverTyping && i == messages.length + 1) {
              return const _TypingIndicator();
            }

            final msg = messages[i - 1];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: msg.isUser
                  ? _UserBubble(msg: msg)
                  : _DriverBubble(msg: msg),
            );
          },
        );
      },
    );
  }
}

class _DateHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: context.colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(9999),
          ),
          child: Text('СЕГОДНЯ',
              style: TextStyle(
                  fontSize: 10,
                  color: context.colors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.5)),
        ),
      ),
    );
  }
}

class _DriverBubble extends StatelessWidget {
  final ChatMessage msg;
  const _DriverBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 280),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: context.colors.surfaceContainerLow,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(18),
            ),
            border: Border.all(color: context.colors.outlineVariant),
          ),
          child: Text(msg.text,
              style: TextStyle(
                  color: context.colors.onSurface, fontSize: 14)),
        ),
        const SizedBox(height: 3),
        Text(msg.timeFormatted,
            style: TextStyle(
                fontSize: 10, color: context.colors.onSurfaceVariant)),
      ]),
    );
  }
}

class _UserBubble extends StatelessWidget {
  final ChatMessage msg;
  const _UserBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 280),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: context.colors.brandGradient,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(4),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(18),
            ),
            boxShadow: [
              BoxShadow(
                  color: context.colors.primary.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Text(msg.text,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
        ),
        const SizedBox(height: 3),
        Row(mainAxisSize: MainAxisSize.min, children: [
          Text(msg.timeFormatted,
              style: TextStyle(
                  fontSize: 10, color: context.colors.onSurfaceVariant)),
          const SizedBox(width: 4),
          Icon(Icons.done_all_rounded, size: 13, color: context.colors.primary),
        ]),
      ]),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: context.colors.surfaceContainerLow,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(18),
            ),
            border: Border.all(color: context.colors.outlineVariant),
          ),
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final delay = i / 3;
                final val = ((_ctrl.value - delay) % 1.0).clamp(0.0, 1.0);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.colors.onSurfaceVariant
                          .withValues(alpha: 0.3 + 0.6 * val),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Quick Replies ─────────────────────────────────────────────────────────────

class _QuickReplies extends StatelessWidget {
  final ValueChanged<String> onTap;
  const _QuickReplies({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: ChatBloc.quickReplies.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final reply = ChatBloc.quickReplies[i];
          return GestureDetector(
            onTap: () => onTap(reply),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(9999),
                border: Border.all(color: context.colors.outlineVariant),
                boxShadow: context.colors.cardShadow,
              ),
              child: Text(reply,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.colors.primary)),
            ),
          );
        },
      ),
    );
  }
}

// ─── Input Bar ─────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController ctrl;
  final FocusNode focus;
  final VoidCallback onSend;
  const _InputBar(
      {required this.ctrl, required this.focus, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(top: BorderSide(color: context.colors.outlineVariant)),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 12, offset: Offset(0, -4)),
        ],
      ),
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      child: Row(children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            decoration: BoxDecoration(
              color: context.colors.background,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: context.colors.outlineVariant),
            ),
            child: TextField(
              controller: ctrl,
              focusNode: focus,
              style: TextStyle(
                  color: context.colors.onSurface, fontSize: 14),
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Сообщение...',
                hintStyle:
                    TextStyle(color: context.colors.onSurfaceVariant, fontSize: 14),
                border: InputBorder.none,
                isDense: true,
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Send button
        GestureDetector(
          onTap: onSend,
          child: Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              gradient: context.colors.brandGradient,
              shape: BoxShape.circle,
              boxShadow: context.colors.primaryGlow,
            ),
            child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
          ),
        ),
      ]),
    );
  }
}
