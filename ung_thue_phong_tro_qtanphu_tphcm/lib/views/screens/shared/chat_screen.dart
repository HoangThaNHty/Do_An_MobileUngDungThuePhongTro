import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/constants.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/chat_controller.dart';
import '../../../models/entities/user.dart';
import 'package:flutter/services.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String chatId;

  const ChatScreen({super.key, required this.chatId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageCtrl = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _markRead();
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _markRead() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider);
      if (user != null) {
        final isLandlord = user.role == UserRole.landlord;
        ref.read(chatControllerProvider).markAsRead(widget.chatId, user.id, isLandlord);
      }
    });
  }

  void _sendMessage() {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    // Trigger haptic feedback when sending message
    HapticFeedback.lightImpact();

    final isLandlord = user.role == UserRole.landlord;
    ref.read(chatControllerProvider).sendMessage(
          chatId: widget.chatId,
          senderId: user.id,
          text: text,
          isSenderLandlord: isLandlord,
        );

    _messageCtrl.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final messagesAsync = ref.watch(chatMessagesProvider(widget.chatId));
    final chatRoomAsync = ref.watch(myChatsProvider);

    return chatRoomAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Lỗi: $e')),
      ),
      data: (rooms) {
        final hasAccess = rooms.any((r) => r.id == widget.chatId);
        if (!hasAccess) {
          return Scaffold(
            appBar: AppBar(title: const Text('Bảo mật')),
            body: const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline, size: 64, color: AppColors.error),
                    SizedBox(height: 16),
                    Text(
                      'Bạn không có quyền truy cập cuộc trò chuyện này!',
                      style: AppTypography.titleSM,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final room = rooms.firstWhere((r) => r.id == widget.chatId);
        final isLandlord = currentUser?.role == UserRole.landlord;
        final partnerName = isLandlord ? room.tenantName : room.landlordName;
        final partnerAvatar = isLandlord ? room.tenantAvatar : room.landlordAvatar;

        // Tự động đánh dấu đã đọc khi nhận tin nhắn mới trong lúc đang xem màn hình
        ref.listen(chatMessagesProvider(widget.chatId), (prev, next) {
          _markRead();
          _scrollToBottom();
        });

        return Scaffold(
          backgroundColor: AppColors.surface,
          appBar: AppBar(
            titleSpacing: 0,
            title: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  backgroundImage: partnerAvatar != null && partnerAvatar.isNotEmpty
                      ? NetworkImage(partnerAvatar)
                      : null,
                  child: partnerAvatar == null || partnerAvatar.isEmpty
                      ? Text(
                          partnerName.isNotEmpty ? partnerName[0].toUpperCase() : 'U',
                          style: AppTypography.titleSM.copyWith(
                            color: AppColors.primary,
                            fontSize: 14,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    partnerName,
                    style: AppTypography.titleSM,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
          ),
          body: Column(
            children: [
              // Messages list
              Expanded(
                child: messagesAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                  error: (err, _) => Center(
                    child: Text('Lỗi tải tin nhắn: $err'),
                  ),
                  data: (messages) {
                    if (messages.isEmpty) {
                      return Center(
                        child: Text(
                          'Bắt đầu nhắn tin ngay...',
                          style: AppTypography.bodySM.copyWith(
                            color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                          ),
                        ),
                      );
                    }

                    // Scroll to bottom on load
                    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final isMe = msg.senderId == currentUser?.id;

                        return Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.75,
                            ),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? AppColors.primary
                                  : AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                                bottomRight: isMe ? Radius.zero : const Radius.circular(16),
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                )
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                Text(
                                  msg.text,
                                  style: AppTypography.bodyMD.copyWith(
                                    color: isMe ? Colors.white : AppColors.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: Text(
                                    _formatMessageTime(msg.timestamp),
                                    style: TextStyle(
                                      fontSize: 8,
                                      color: isMe ? Colors.white60 : AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              
              // Input bar
              SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    boxShadow: [AppShadows.bottomSheet],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                          child: TextField(
                            controller: _messageCtrl,
                            maxLines: null,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              hintText: 'Nhập tin nhắn...',
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 10),
                            ),
                            style: AppTypography.bodyMD,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      IconButton(
                        icon: const Icon(Icons.send),
                        color: AppColors.primary,
                        onPressed: _sendMessage,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatMessageTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
