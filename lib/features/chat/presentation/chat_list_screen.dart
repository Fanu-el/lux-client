import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/app_notification.dart';
import '../data/chat_api.dart';
import '../models/chat.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _api = ChatApi();

  List<Chat> _chats = [];
  bool _loading = true;
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    setState(() => _loading = true);
    try {
      final res = await _api.getChats();
      final list = (res.data as List<dynamic>)
          .map((e) => Chat.fromJson(e as Map<String, dynamic>))
          .toList();
      if (mounted) setState(() => _chats = list);
    } on DioException catch (e) {
      AppNotification.showError(e.error as String? ?? 'Failed to load chats.');
    } catch (_) {
      AppNotification.showError('Something went wrong.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _newChat() async {
    setState(() => _creating = true);
    try {
      final res = await _api.createChat();
      final chat = Chat.fromJson(res.data as Map<String, dynamic>);
      if (!mounted) return;
      await context.push('/chats/${chat.id}');
      _loadChats();
    } on DioException catch (e) {
      AppNotification.showError(e.error as String? ?? 'Could not create chat.');
    } catch (_) {
      AppNotification.showError('Something went wrong.');
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _deleteChat(Chat chat) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return AlertDialog(
          icon: Icon(Icons.delete_forever_rounded, color: cs.error, size: 32),
          title: const Text('Delete chat?'),
          content: Text(
            '"${chat.title}" and all its messages will be permanently deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: cs.error),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;

    try {
      await _api.deleteChat(chat.id);
      if (mounted) setState(() => _chats.removeWhere((c) => c.id == chat.id));
      AppNotification.showInfo('Chat deleted.');
    } on DioException catch (e) {
      AppNotification.showError(e.error as String? ?? 'Could not delete chat.');
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
        title: Text(
          'Lux',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: cs.primary,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => context.push('/settings/profile'),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: cs.primaryContainer,
                child: Icon(Icons.person_outline,
                    size: 18, color: cs.onPrimaryContainer),
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _chats.isEmpty
              ? _EmptyState(onNewChat: _newChat, creating: _creating)
              : RefreshIndicator(
                  onRefresh: _loadChats,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: _chats.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final chat = _chats[i];
                      return _ChatTile(
                        chat: chat,
                        onTap: () async {
                          await context.push('/chats/${chat.id}');
                          _loadChats();
                        },
                        onDelete: () => _deleteChat(chat),
                      );
                    },
                  ),
                ),
      floatingActionButton: _chats.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _creating ? null : _newChat,
              elevation: 2,
              icon: _creating
                  ? SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: cs.onPrimary),
                    )
                  : const Icon(Icons.add_rounded),
              label: const Text('New chat',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            )
          : null,
    );
  }
}

// ─── Chat tile ────────────────────────────────────────────────────────────────

class _ChatTile extends StatelessWidget {
  const _ChatTile({
    required this.chat,
    required this.onTap,
    required this.onDelete,
  });
  final Chat chat;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Material(
      color: cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.chat_bubble_outline_rounded,
                    size: 18, color: cs.onPrimaryContainer),
              ),
              const SizedBox(width: 14),

              // Title + subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chat.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (chat.updatedAt != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        _formatDate(chat.updatedAt!),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Delete button — red
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                color: cs.error,
                tooltip: 'Delete',
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onNewChat, required this.creating});
  final VoidCallback onNewChat;
  final bool creating;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cs.primaryContainer, cs.secondaryContainer],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(Icons.auto_awesome_rounded,
                  size: 44, color: cs.primary),
            ),
            const SizedBox(height: 28),
            Text(
              'Meet Lux',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Your AI assistant, ready to help with anything. Start a new conversation.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: cs.onSurfaceVariant, height: 1.5),
            ),
            const SizedBox(height: 36),
            FilledButton.icon(
              onPressed: creating ? null : onNewChat,
              icon: creating
                  ? SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: cs.onPrimary),
                    )
                  : const Icon(Icons.add_rounded),
              label: const Text('Start chatting'),
            ),
          ],
        ),
      ),
    );
  }
}
