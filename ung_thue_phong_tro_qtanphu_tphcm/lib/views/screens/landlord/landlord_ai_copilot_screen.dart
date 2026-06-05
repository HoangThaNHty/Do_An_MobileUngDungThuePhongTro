import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/constants.dart';
import '../../../controllers/ai_copilot_controller.dart';
import '../../../controllers/landlord_ai_copilot_controller.dart';
import '../../../controllers/providers/bill_provider.dart';
import '../../../controllers/providers/room_provider.dart';

class LandlordAICopilotScreen extends ConsumerStatefulWidget {
  const LandlordAICopilotScreen({super.key});

  @override
  ConsumerState<LandlordAICopilotScreen> createState() =>
      _LandlordAICopilotScreenState();
}

class _LandlordAICopilotScreenState
    extends ConsumerState<LandlordAICopilotScreen> {
  final _messageCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  static const _quickPrompts = [
    'Có hóa đơn nào chờ duyệt không?',
    'Ai chưa thanh toán?',
    'Phòng nào đang trống?',
    'Doanh thu tháng này bao nhiêu?',
    'Soạn tin nhắn nhắc khách thanh toán lịch sự',
  ];

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
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final aiState = ref.watch(landlordAICopilotProvider);
    final aiNotifier = ref.read(landlordAICopilotProvider.notifier);
    final roomState = ref.watch(roomProvider);
    final billsAsync = ref.watch(allBillsProvider);
    final rentalsAsync = ref.watch(allRentalsProvider);
    final isDataLoading =
        roomState.isLoading || billsAsync.isLoading || rentalsAsync.isLoading;

    ref.listen(landlordAICopilotProvider, (_, __) => _scrollToBottom());

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(AppSpacing.appBarHeight),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: AppBar(
              backgroundColor: AppColors.surface.withValues(alpha: 0.86),
              elevation: 0,
              scrolledUnderElevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
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
                      Icons.manage_search_outlined,
                      color: AppColors.onPrimary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Chủ trọ AI Copilot',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
                        Text(
                          'Hỗ trợ quản lý phòng và hóa đơn',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete_sweep_outlined),
                  tooltip: 'Làm mới hội thoại',
                  onPressed: () => _showClearHistoryDialog(context, aiNotifier),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (isDataLoading) _buildDataLoadingBar(),
            _buildQuickPrompts(aiState, aiNotifier, isDataLoading),
            Expanded(
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: aiState.messages.length,
                itemBuilder: (context, index) {
                  final message = aiState.messages[index];
                  return _buildMessageRow(message);
                },
              ),
            ),
            if (aiState.isLoading) _buildTypingIndicator(),
            _buildInputBox(aiState, aiNotifier, isDataLoading),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickPrompts(
    AICopilotState state,
    LandlordAICopilotNotifier notifier,
    bool isDataLoading,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      color: AppColors.surface.withValues(alpha: 0.92),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _quickPrompts.map((prompt) {
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: ActionChip(
                label: Text(prompt),
                avatar: const Icon(Icons.bolt_outlined, size: 16),
                onPressed: state.isLoading || isDataLoading
                    ? null
                    : () {
                        notifier.sendMessage(prompt);
                        _messageCtrl.clear();
                      },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMessageRow(AICopilotMessage message) {
    final isUser = message.role == 'user';
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
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
                Icons.manage_search_outlined,
                color: AppColors.primary,
                size: 16,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                message.text,
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
    );
  }

  Widget _buildTypingIndicator() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
      child: Row(
        children: [
          SizedBox(width: 28),
          SizedBox(width: AppSpacing.sm),
          Text('AI đang xử lý...', style: AppTypography.bodySM),
        ],
      ),
    );
  }

  Widget _buildDataLoadingBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      color: AppColors.primary.withValues(alpha: 0.06),
      child: Row(
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Đang tải dữ liệu phòng, hợp đồng và hóa đơn...',
              style: AppTypography.bodySM.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBox(
    AICopilotState state,
    LandlordAICopilotNotifier notifier,
    bool isDataLoading,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(
          top: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.3),
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
                  hintText: 'Hỏi về phòng, người thuê, hóa đơn...',
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onSubmitted: (value) {
                  if (!state.isLoading && !isDataLoading) {
                    notifier.sendMessage(value);
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
              color: state.isLoading || isDataLoading
                  ? AppColors.outlineVariant
                  : AppColors.primary,
            ),
            onPressed: state.isLoading || isDataLoading
                ? null
                : () {
                    notifier.sendMessage(_messageCtrl.text);
                    _messageCtrl.clear();
                  },
          ),
        ],
      ),
    );
  }

  void _showClearHistoryDialog(
    BuildContext context,
    LandlordAICopilotNotifier notifier,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Làm mới hội thoại?'),
        content: const Text('Toàn bộ nội dung chat AI hiện tại sẽ được xóa.'),
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
