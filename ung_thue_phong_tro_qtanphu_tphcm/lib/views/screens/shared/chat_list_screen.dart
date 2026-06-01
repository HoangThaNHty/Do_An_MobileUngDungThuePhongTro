import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../config/constants.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/chat_controller.dart';
import '../../../models/entities/user.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final chatsAsync = ref.watch(myChatsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Hộp thư tin nhắn'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: chatsAsync.when(
        loading: () => const _ChatShimmerList(),
        error: (err, _) => Center(
          child: Text('Lỗi: $err', style: AppTypography.bodyMD),
        ),
        data: (rooms) {
          if (rooms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.chat_bubble_outline,
                    size: 72,
                    color: AppColors.outlineVariant,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Chưa có cuộc trò chuyện nào',
                    style: AppTypography.titleSM.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Hãy liên hệ chủ nhà để trao đổi về phòng!',
                    style: AppTypography.bodySM.copyWith(
                      color: AppColors.onSurfaceVariant.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: rooms.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final room = rooms[index];
              final isLandlord = currentUser?.role == UserRole.landlord;
              
              // Lấy thông tin đối phương (nếu mình là landlord thì đối phương là tenant, và ngược lại)
              final partnerName = isLandlord ? room.tenantName : room.landlordName;
              final partnerAvatar = isLandlord ? room.tenantAvatar : room.landlordAvatar;
              final unreadCount = isLandlord ? room.unreadByLandlord : room.unreadByTenant;

              return Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  boxShadow: const [AppShadows.card],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    backgroundImage: partnerAvatar != null && partnerAvatar.isNotEmpty
                        ? NetworkImage(partnerAvatar)
                        : null,
                    child: partnerAvatar == null || partnerAvatar.isEmpty
                        ? Text(
                            partnerName.isNotEmpty ? partnerName[0].toUpperCase() : 'U',
                            style: AppTypography.titleSM.copyWith(
                              color: AppColors.primary,
                            ),
                          )
                        : null,
                  ),
                  title: Text(
                    partnerName,
                    style: AppTypography.titleSM.copyWith(
                      fontWeight: unreadCount > 0 ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    room.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySM.copyWith(
                      color: unreadCount > 0 ? AppColors.onSurface : AppColors.onSurfaceVariant,
                      fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatTime(room.lastMessageTime),
                        style: AppTypography.bodySM.copyWith(
                          fontSize: 10,
                          color: unreadCount > 0 ? AppColors.primary : AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$unreadCount',
                            style: AppTypography.labelSM.copyWith(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  onTap: () => context.push('/chat/${room.id}'),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    if (time.day == now.day && time.month == now.month && time.year == now.year) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
    return '${time.day.toString().padLeft(2, '0')}/${time.month.toString().padLeft(2, '0')}';
  }
}

class _ChatShimmerList extends StatelessWidget {
  const _ChatShimmerList();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: AppColors.surfaceContainerLow,
          highlightColor: AppColors.surfaceContainerLowest,
          child: Container(
            height: 76,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
          ),
        );
      },
    );
  }
}
