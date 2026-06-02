import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/constants.dart';
import '../../../controllers/ai_copilot_controller.dart';
import '../../../controllers/providers/room_provider.dart';
import '../../widgets/cards/room_card.dart';

class AICopilotScreen extends ConsumerStatefulWidget {
  const AICopilotScreen({super.key});

  @override
  ConsumerState<AICopilotScreen> createState() => _AICopilotScreenState();
}

class _AICopilotScreenState extends ConsumerState<AICopilotScreen> {
  final _messageCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _messageCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final aiState = ref.watch(aiCopilotProvider);
    final aiNotifier = ref.read(aiCopilotProvider.notifier);

    // Tự động cuộn xuống cuối khi có tin nhắn mới hoặc đang load
    ref.listen(aiCopilotProvider, (prev, next) {
      _scrollToBottom();
    });

    return Scaffold(
      backgroundColor: AppColors.surface,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(AppSpacing.appBarHeight),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
            child: AppBar(
              backgroundColor: AppColors.surface.withValues(alpha: 0.8),
              elevation: 0,
              scrolledUnderElevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
                onPressed: () => context.pop(),
              ),
              title: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      gradient: AppGradients.primaryButton,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.psychology,
                      color: AppColors.onPrimary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Tân Phú AI Copilot',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Sẵn sàng tư vấn',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete_sweep_outlined, color: AppColors.onSurfaceVariant),
                  tooltip: 'Làm mới lịch sử chat',
                  onPressed: () {
                    _showClearHistoryDialog(context, aiNotifier);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Chat Stream
            Expanded(
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: aiState.messages.length,
                itemBuilder: (context, index) {
                  final msg = aiState.messages[index];
                  final isUser = msg.role == 'user';

                  return _buildMessageRow(msg, isUser);
                },
              ),
            ),

            // Typing Indicator & Error state
            if (aiState.isLoading) _buildTypingIndicator(),

            // Chat Input Box
            _buildInputBox(aiState, aiNotifier),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageRow(AICopilotMessage msg, bool isUser) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.psychology_outlined,
                    color: AppColors.primary,
                    size: 16,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: isUser ? AppGradients.primaryButton : null,
                    color: isUser ? null : AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(AppRadius.card),
                      topRight: const Radius.circular(AppRadius.card),
                      bottomLeft: isUser
                          ? const Radius.circular(AppRadius.card)
                          : Radius.zero,
                      bottomRight: isUser
                          ? Radius.zero
                          : const Radius.circular(AppRadius.card),
                    ),
                  ),
                  child: Text(
                    msg.text,
                    style: TextStyle(
                      color: isUser ? AppColors.onPrimary : AppColors.onSurface,
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                ),
              ),
              if (isUser) ...[
                const SizedBox(width: AppSpacing.sm),
                const Icon(
                  Icons.account_circle_outlined,
                  color: AppColors.onSurfaceVariant,
                  size: 24,
                ),
              ],
            ],
          ),
          // Suggested Rooms (If available)
          if (!isUser && msg.suggestedRoomIds.isNotEmpty)
            _buildSuggestedRooms(msg.suggestedRoomIds),
        ],
      ),
    );
  }

  Widget _buildSuggestedRooms(List<String> suggestedRoomIds) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm, left: 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, size: 14, color: AppColors.primary),
              SizedBox(width: 4),
              Text(
                'Phòng gợi ý cho bạn:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          SizedBox(
            height: 128,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: suggestedRoomIds.length,
              itemBuilder: (context, index) {
                final roomId = suggestedRoomIds[index];
                
                return Consumer(
                  builder: (context, ref, _) {
                    final room = ref.watch(roomByIdProvider(roomId));
                    if (room == null) return const SizedBox.shrink();

                    return SizedBox(
                      width: 290,
                      child: Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: RoomCard(
                          room: room,
                          onTap: () => context.push('/tenant/room/${room.id}'),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.psychology_outlined,
              color: AppColors.primary,
              size: 16,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppRadius.card),
                topRight: Radius.circular(AppRadius.card),
                bottomLeft: Radius.zero,
                bottomRight: Radius.circular(AppRadius.card),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DotIndicator(),
                SizedBox(width: 4),
                _DotIndicator(delayMs: 200),
                SizedBox(width: 4),
                _DotIndicator(delayMs: 400),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBox(AICopilotState state, AICopilotNotifier notifier) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(
          top: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              child: TextField(
                controller: _messageCtrl,
                maxLines: null,
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Nhập tin nhắn tìm phòng...',
                  hintStyle: AppTypography.bodyMD,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (val) {
                  if (!state.isLoading) {
                    notifier.sendMessage(val);
                    _messageCtrl.clear();
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            icon: Icon(
              Icons.send_rounded,
              color: state.isLoading ? AppColors.outlineVariant : AppColors.primary,
            ),
            onPressed: state.isLoading
                ? null
                : () {
                    final msg = _messageCtrl.text;
                    notifier.sendMessage(msg);
                    _messageCtrl.clear();
                  },
          ),
        ],
      ),
    );
  }

  void _showClearHistoryDialog(BuildContext context, AICopilotNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Làm mới hội thoại?'),
        content: const Text(
          'Hành động này sẽ xóa toàn bộ lịch sử trò chuyện của bạn với Trợ lý AI và bắt đầu cuộc hội thoại mới.',
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              notifier.clearHistory();
              context.pop();
            },
            child: const Text(
              'Đồng ý',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

// Chấm tròn nhấp nháy chuyển động êm ái
class _DotIndicator extends StatefulWidget {
  final int delayMs;
  const _DotIndicator({this.delayMs = 0});

  @override
  State<_DotIndicator> createState() => _DotIndicatorState();
}

class _DotIndicatorState extends State<_DotIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.6),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
