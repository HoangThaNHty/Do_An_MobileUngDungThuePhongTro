import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../config/app_palette.dart';
import '../../../config/constants.dart';
import '../../../controllers/providers/room_provider.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/chat_controller.dart';
import '../../widgets/common/app_button.dart';

class ContactScreen extends ConsumerWidget {
  final String landlordId;

  const ContactScreen({super.key, required this.landlordId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rooms = ref.watch(roomProvider).rooms;
    final landlordRoom =
        rooms.where((r) => r.landlordId == landlordId).toList();
    final landlordAsync = ref.watch(userByIdProvider(landlordId));
    final currentUser = ref.watch(currentUserProvider);
    final palette = context.palette;

    return Scaffold(
      backgroundColor: palette.surface,
      appBar: AppBar(
        title: const Text('Liên hệ chủ nhà'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: landlordAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: palette.primary),
        ),
        error: (err, _) => Center(
          child: Text('Lỗi tải thông tin chủ nhà: $err',
              style: AppTypography.bodyMD),
        ),
        data: (landlord) {
          if (landlord == null) {
            return const Center(
              child: Text('Không tìm thấy thông tin chủ nhà',
                  style: AppTypography.bodyMD),
            );
          }

          final landlordName = landlord.fullName;
          final landlordPhone =
              landlord.phone.isNotEmpty ? landlord.phone : 'Chưa cập nhật';
          final landlordEmail = landlord.email;
          const address =
              'Quận Tân Phú, TP. Hồ Chí Minh'; // Địa bàn hoạt động của chủ trọ
          final ratingVal = landlord.averageRating ?? 5.0;
          final ratingStr = '${ratingVal.toStringAsFixed(1)} ★';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                // Avatar card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    gradient: AppGradients.primaryButton,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor:
                            AppColors.onPrimary.withValues(alpha: 0.2),
                        backgroundImage: landlord.avatarUrl != null &&
                                landlord.avatarUrl!.isNotEmpty
                            ? NetworkImage(landlord.avatarUrl!)
                            : null,
                        child: landlord.avatarUrl == null ||
                                landlord.avatarUrl!.isEmpty
                            ? Text(
                                landlordName.isNotEmpty
                                    ? landlordName[0].toUpperCase()
                                    : 'C',
                                style: AppTypography.headlineMD.copyWith(
                                  color: AppColors.onPrimary,
                                  fontSize: 28,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        landlordName,
                        style: AppTypography.titleMD.copyWith(
                          color: AppColors.onPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.onPrimary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(AppRadius.chip),
                        ),
                        child: Text(
                          'Chủ trọ',
                          style: AppTypography.labelSM.copyWith(
                            color: AppColors.onPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Stats row
                Row(
                  children: [
                    Expanded(
                      child: _statBox(
                        context,
                        '${landlordRoom.length}',
                        'Phòng đang cho thuê',
                        Icons.home_work_outlined,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _statBox(
                        context,
                        ratingStr,
                        'Đánh giá trung bình',
                        Icons.star_outline,
                        valueColor: const Color(0xFFFF8F00),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Contact info
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: palette.surfaceLowest,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    boxShadow: const [AppShadows.card],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Thông tin liên hệ',
                          style: AppTypography.titleSM),
                      const SizedBox(height: AppSpacing.md),
                      _contactRow(
                        context: context,
                        icon: Icons.phone_outlined,
                        label: 'Số điện thoại',
                        value: landlordPhone,
                        onCopy: () => _copyToClipboard(context, landlordPhone),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _contactRow(
                        context: context,
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: landlordEmail,
                        onCopy: () => _copyToClipboard(context, landlordEmail),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _contactRow(
                        context: context,
                        icon: Icons.location_on_outlined,
                        label: 'Khu vực quản lý',
                        value: address,
                        onCopy: () => _copyToClipboard(context, address),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Working hours
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: palette.surfaceLowest,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    boxShadow: const [AppShadows.card],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Giờ tiếp nhận', style: AppTypography.titleSM),
                      const SizedBox(height: AppSpacing.sm),
                      _workingRow(context, 'Thứ 2 – Thứ 6', '8:00 – 18:00'),
                      const SizedBox(height: 4),
                      _workingRow(context, 'Thứ 7 – Chủ nhật', '8:00 – 12:00'),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Call button
                AppButton(
                  text: 'Gọi điện ngay',
                  onPressed: () async {
                    if (landlord.phone.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Chủ nhà chưa cập nhật số điện thoại!')),
                      );
                      return;
                    }
                    final Uri launchUri = Uri(
                      scheme: 'tel',
                      path: landlord.phone,
                    );
                    try {
                      if (await canLaunchUrl(launchUri)) {
                        await launchUrl(launchUri);
                      } else {
                        if (context.mounted) {
                          _copyToClipboard(context, landlord.phone);
                        }
                      }
                    } catch (_) {
                      if (context.mounted) {
                        _copyToClipboard(context, landlord.phone);
                      }
                    }
                  },
                  icon: Icons.phone,
                ),
                const SizedBox(height: AppSpacing.sm),

                // Chat button
                AppButton(
                  text: 'Nhắn tin',
                  onPressed: () async {
                    if (currentUser == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Vui lòng đăng nhập để nhắn tin!')),
                      );
                      return;
                    }
                    if (currentUser.id == landlord.id) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Bạn không thể tự nhắn tin cho chính mình!')),
                      );
                      return;
                    }

                    try {
                      final chatController = ref.read(chatControllerProvider);
                      // Tạo phòng chat trên Firebase
                      final chatId = await chatController.getOrCreateChatRoom(
                        tenant: currentUser,
                        landlord: landlord,
                      );

                      if (context.mounted) {
                        context.push('/chat/$chatId');
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Lỗi kết nối phòng chat: $e')),
                        );
                      }
                    }
                  },
                  type: AppButtonType.secondary,
                  icon: Icons.chat_bubble_outline,
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statBox(
      BuildContext context, String value, String label, IconData icon,
      {Color? valueColor}) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: palette.surfaceLowest,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: const [AppShadows.card],
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: palette.primary),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTypography.titleMD.copyWith(
              color: valueColor ?? palette.primary,
            ),
          ),
          Text(label, style: AppTypography.bodySM, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _contactRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onCopy,
  }) {
    final palette = context.palette;
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: palette.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: palette.primary),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTypography.bodySM),
              Text(
                value,
                style: AppTypography.bodyMD.copyWith(
                  color: palette.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.copy_outlined, size: 18),
          color: palette.onSurfaceVariant,
          onPressed: onCopy,
        ),
      ],
    );
  }

  Widget _workingRow(BuildContext context, String days, String hours) {
    final palette = context.palette;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(days, style: AppTypography.bodyMD),
        Text(
          hours,
          style: AppTypography.bodyMD.copyWith(
            color: palette.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã sao chép vào clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
