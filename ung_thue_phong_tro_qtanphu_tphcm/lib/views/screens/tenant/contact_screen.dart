import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/constants.dart';
import '../../../controllers/providers/room_provider.dart';
import '../../../controllers/auth_controller.dart';
import '../../widgets/common/app_button.dart';

class ContactScreen extends ConsumerWidget {
  final String landlordId;

  const ContactScreen({super.key, required this.landlordId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Find landlord info (mock)
    final rooms = ref.watch(roomProvider).rooms;
    final landlordRoom = rooms.where((r) => r.landlordId == landlordId).toList();

    // Mock landlord data
    const landlordName = 'Nguyễn Văn An';
    const landlordPhone = '0901234567';
    const landlordEmail = 'annguyen@email.com';
    const address = 'Hẻm 42 Ung Văn Khiêm, Phường 25, Quận Bình Thạnh, TP.HCM';

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Liên hệ chủ nhà'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
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
                    backgroundColor: AppColors.onPrimary.withOpacity(0.2),
                    child: const Icon(
                      Icons.person,
                      size: 44,
                      color: AppColors.onPrimary,
                    ),
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
                      color: AppColors.onPrimary.withOpacity(0.2),
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
                    '${landlordRoom.length}',
                    'Phòng đang cho thuê',
                    Icons.home_work_outlined,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _statBox(
                    '4.8 ★',
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
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppRadius.card),
                boxShadow: const [AppShadows.card],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Thông tin liên hệ', style: AppTypography.titleSM),
                  const SizedBox(height: AppSpacing.md),
                  _contactRow(
                    icon: Icons.phone_outlined,
                    label: 'Số điện thoại',
                    value: landlordPhone,
                    onCopy: () => _copyToClipboard(context, landlordPhone),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _contactRow(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: landlordEmail,
                    onCopy: () => _copyToClipboard(context, landlordEmail),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _contactRow(
                    icon: Icons.location_on_outlined,
                    label: 'Địa chỉ',
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
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppRadius.card),
                boxShadow: const [AppShadows.card],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Giờ tiếp nhận', style: AppTypography.titleSM),
                  const SizedBox(height: AppSpacing.sm),
                  _workingRow('Thứ 2 – Thứ 6', '8:00 – 18:00'),
                  const SizedBox(height: 4),
                  _workingRow('Thứ 7 – Chủ nhật', '8:00 – 12:00'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Call button
            AppButton(
              text: 'Gọi điện ngay',
              onPressed: () {},
              icon: Icons.phone,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              text: 'Nhắn tin',
              onPressed: () {},
              type: AppButtonType.secondary,
              icon: Icons.chat_bubble_outline,
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _statBox(String value, String label, IconData icon,
      {Color? valueColor}) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: const [AppShadows.card],
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTypography.titleMD.copyWith(
              color: valueColor ?? AppColors.primary,
            ),
          ),
          Text(label, style: AppTypography.bodySM, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _contactRow({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onCopy,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
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
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.copy_outlined, size: 18),
          color: AppColors.onSurfaceVariant,
          onPressed: onCopy,
        ),
      ],
    );
  }

  Widget _workingRow(String days, String hours) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(days, style: AppTypography.bodyMD),
        Text(
          hours,
          style: AppTypography.bodyMD.copyWith(
            color: AppColors.primary,
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
