import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/utils/app_notification.dart';
import '../data/chat_api.dart';
import '../models/chat.dart';
import '../models/llm_model.dart';
import '../models/message.dart';
import 'widgets/message_bubble.dart';
import 'widgets/model_picker.dart';
import 'widgets/thinking_indicator.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.chatId});
  final String chatId;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _api = ChatApi();
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _inputFocus = FocusNode();

  Chat? _chat;
  List<Message> _messages = [];
  LlmModel _model = LlmModel.defaultModel;

  bool _loadingMessages = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadChat();
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  Future<void> _loadChat() async {
    setState(() => _loadingMessages = true);
    try {
      final results = await Future.wait([
        _api.getChat(widget.chatId),
        _api.getMessages(widget.chatId),
      ]);

      final chat = Chat.fromJson(results[0].data as Map<String, dynamic>);
      final messages = (results[1].data as List<dynamic>)
          .map((e) => Message.fromJson(e as Map<String, dynamic>))
          .toList();

      if (mounted) {
        setState(() {
          _chat = chat;
          _messages = messages;
        });
        _scrollToBottom(animate: false);
      }
    } on DioException catch (e) {
      AppNotification.showError(e.error as String? ?? 'Failed to load chat.');
    } catch (_) {
      AppNotification.showError('Something went wrong.');
    } finally {
      if (mounted) setState(() => _loadingMessages = false);
    }
  }

  Future<void> _send() async {
    final content = _inputCtrl.text.trim();
    if (content.isEmpty || _sending) return;

    final userMsg = Message(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      role: MessageRole.user,
      content: content,
    );

    setState(() {
      _messages.add(userMsg);
      _sending = true;
    });
    _inputCtrl.clear();
    _scrollToBottom();

    try {
      final res = await _api.sendMessage(
        widget.chatId,
        content: content,
        model: _model,
      );

      final data = res.data as Map<String, dynamic>;
      final confirmedUser =
          Message.fromJson(data['user_message'] as Map<String, dynamic>);
      final assistantMsg =
          Message.fromJson(data['assistant_message'] as Map<String, dynamic>);

      if (mounted) {
        setState(() {
          _messages[_messages.length - 1] = confirmedUser;
          _messages.add(assistantMsg);
        });
        _scrollToBottom();
      }
    } on DioException catch (e) {
      if (mounted) {
        setState(() => _messages.removeWhere((m) => m.id == userMsg.id));
        _inputCtrl.text = content;
      }
      AppNotification.showError(e.error as String? ?? 'Failed to send message.');
    } catch (_) {
      if (mounted) {
        setState(() => _messages.removeWhere((m) => m.id == userMsg.id));
        _inputCtrl.text = content;
      }
      AppNotification.showError('Something went wrong.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      if (animate) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
      }
    });
  }

  Future<void> _renameChat() async {
    final ctrl = TextEditingController(text: _chat?.title ?? '');
    final newTitle = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename chat'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'Enter a title…',
            prefixIcon: Icon(Icons.edit_outlined),
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Rename'),
          ),
        ],
      ),
    );
    ctrl.dispose();

    if (newTitle == null || newTitle.isEmpty || newTitle == _chat?.title) return;

    try {
      await _api.updateChat(widget.chatId, title: newTitle);
      if (mounted) setState(() => _chat = _chat?.copyWith(title: newTitle));
    } on DioException catch (e) {
      AppNotification.showError(e.error as String? ?? 'Could not rename chat.');
    } catch (_) {
      AppNotification.showError('Something went wrong.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: InkWell(
          onTap: _renameChat,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    _chat?.title ?? 'Chat',
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.edit_rounded, size: 13, color: cs.onSurfaceVariant),
              ],
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ModelPickerButton(
              selected: _model,
              onChanged: (m) => setState(() => _model = m),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _loadingMessages
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? _WelcomeHint(
                        model: _model,
                        onSuggestionTap: (text) {
                          _inputCtrl.text = text;
                          _inputFocus.requestFocus();
                        },
                      )
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        itemCount: _messages.length + (_sending ? 1 : 0),
                        itemBuilder: (context, i) {
                          if (_sending && i == _messages.length) {
                            return const ThinkingIndicator();
                          }
                          return MessageBubble(message: _messages[i]);
                        },
                      ),
          ),
          _InputBar(
            controller: _inputCtrl,
            focusNode: _inputFocus,
            sending: _sending,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

// ─── Welcome hint ─────────────────────────────────────────────────────────────

class _WelcomeHint extends StatelessWidget {
  const _WelcomeHint({required this.model, required this.onSuggestionTap});
  final LlmModel model;
  final ValueChanged<String> onSuggestionTap;

  static const _suggestions = [
    'Explain quantum computing simply',
    'Write a short poem about the ocean',
    'What are the best productivity tips?',
    'Help me debug my Flutter code',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cs.primaryContainer, cs.secondaryContainer],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.auto_awesome_rounded,
                size: 36, color: cs.primary),
          ),
          const SizedBox(height: 20),
          Text(
            'Hi, I\'m Lux',
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Powered by ${model.label}',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 36),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Try asking…',
              style: theme.textTheme.labelMedium?.copyWith(
                color: cs.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestions
                .map((s) => _SuggestionChip(
                      label: s,
                      onTap: () => onSuggestionTap(s),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: cs.surfaceContainerLow,
      side: BorderSide(color: cs.outlineVariant),
      labelStyle: TextStyle(
        color: cs.onSurface,
        fontSize: 13,
      ),
    );
  }
}

// ─── Input bar ────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.sending,
    required this.onSend,
  });
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border(
              top: BorderSide(color: cs.outlineVariant.withOpacity(0.5))),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
                ),
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  minLines: 1,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.newline,
                  keyboardType: TextInputType.multiline,
                  decoration: const InputDecoration(
                    hintText: 'Message Lux…',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                    filled: false,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: sending
                  ? Padding(
                      key: const ValueKey('spinner'),
                      padding: const EdgeInsets.all(10),
                      child: SizedBox(
                        height: 26,
                        width: 26,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: cs.primary,
                        ),
                      ),
                    )
                  : IconButton(
                      key: const ValueKey('send'),
                      onPressed: onSend,
                      style: IconButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary,
                        minimumSize: const Size(46, 46),
                      ),
                      icon: const Icon(Icons.arrow_upward_rounded, size: 22),
                      tooltip: 'Send',
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
