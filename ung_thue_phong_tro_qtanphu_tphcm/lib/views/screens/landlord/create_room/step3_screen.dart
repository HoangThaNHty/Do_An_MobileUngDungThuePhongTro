import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../config/constants.dart';
import '../../../../controllers/providers/create_room_provider.dart';
import '../../../widgets/common/app_button.dart';
import '../../../widgets/common/status_chips.dart';
import '../../../../models/entities/room.dart';

class Step3Screen extends ConsumerWidget {
  const Step3Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createRoomProvider);
    final notifier = ref.read(createRoomProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Thêm phòng'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/landlord/create-room/step2'),
        ),
      ),
      body: Column(
        children: [
          _buildProgress(3),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                Text('Bước 3: Xem trước & Xác nhận',
                    style: AppTypography.titleMD),
                const SizedBox(height: AppSpacing.md),

                // Preview card
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    boxShadow: const [AppShadows.card],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image preview
                      SizedBox(
                        height: 180,
                        width: double.infinity,
                        child: state.images.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: state.images.first,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(
                                    color: AppColors.surfaceContainerLow),
                                errorWidget: (_, __, ___) => Container(
                                  color: AppColors.surfaceContainerLow,
                                  child: const Icon(Icons.home_outlined,
                                      size: 64),
                                ),
                              )
                            : Container(
                                color: AppColors.surfaceContainerLow,
                                child: const Center(
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_photo_alternate_outlined,
                                          size: 48,
                                          color: AppColors.onSurfaceVariant),
                                      SizedBox(height: 8),
                                      Text('Chưa có ảnh'),
                                    ],
                                  ),
                                ),
                              ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    state.title.isEmpty
                                        ? 'Tên phòng chưa điền'
                                        : state.title,
                                    style: AppTypography.titleMD,
                                  ),
                                ),
                                const RoomStatusChip(
                                    status: RoomStatus.available),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              '${_formatCurrency(state.price)}đ/tháng',
                              style: AppTypography.titleMD.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined,
                                    size: 14,
                                    color: AppColors.onSurfaceVariant),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    state.address.isEmpty
                                        ? '${state.district}'
                                        : '${state.address}, ${state.district}',
                                    style: AppTypography.bodyMD,
                                    maxLines: 2,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Row(
                              children: [
                                const Icon(Icons.straighten_outlined,
                                    size: 14,
                                    color: AppColors.onSurfaceVariant),
                                const SizedBox(width: 4),
                                Text(
                                  '${state.area.toStringAsFixed(0)} m²',
                                  style: AppTypography.bodyMD,
                                ),
                                const SizedBox(width: AppSpacing.md),
                                const Icon(Icons.payments_outlined,
                                    size: 14,
                                    color: AppColors.onSurfaceVariant),
                                const SizedBox(width: 4),
                                Text(
                                  'Đặt cọc ${state.depositMonths} tháng',
                                  style: AppTypography.bodyMD,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Info summary
                _summarySection('Thông tin phòng', [
                  _infoRow('Tên phòng', state.title),
                  _infoRow('Quận/Huyện', state.district),
                  _infoRow('Địa chỉ', state.address),
                  _infoRow('Diện tích', '${state.area.toStringAsFixed(0)} m²'),
                  _infoRow('Giá thuê', '${_formatCurrency(state.price)}đ/tháng'),
                  _infoRow('Đặt cọc', '${state.depositMonths} tháng'),
                ]),
                const SizedBox(height: AppSpacing.md),

                if (state.amenities.isNotEmpty)
                  _summarySection('Tiện nghi (${state.amenities.length})', [
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: state.amenities
                            .map((a) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color:
                                        AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(
                                        AppRadius.chip),
                                  ),
                                  child: Text(
                                    a,
                                    style: AppTypography.bodySM.copyWith(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  ]),
                const SizedBox(height: AppSpacing.md),

                if (state.description.isNotEmpty)
                  _summarySection('Mô tả', [
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Text(state.description,
                          style: AppTypography.bodyMD),
                    ),
                  ]),
                const SizedBox(height: AppSpacing.lg),

                // Error
                if (state.error != null)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.errorContainer,
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                    child: Text(state.error!,
                        style: AppTypography.bodyMD.copyWith(
                            color: AppColors.onErrorContainer)),
                  ),
                if (state.error != null)
                  const SizedBox(height: AppSpacing.md),

                // Submit button
                AppButton(
                  text: 'Đăng phòng',
                  onPressed: state.isSubmitting
                      ? null
                      : () => _submit(context, ref, notifier),
                  isLoading: state.isSubmitting,
                  icon: Icons.publish_outlined,
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  text: 'Chỉnh sửa lại',
                  type: AppButtonType.secondary,
                  onPressed: () =>
                      context.go('/landlord/create-room/step1'),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit(
      BuildContext context, WidgetRef ref, CreateRoomNotifier notifier) async {
    final success = await notifier.submit();
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã đăng phòng thành công! 🎉'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );
      notifier.reset();
      context.go('/landlord');
    }
  }

  Widget _summarySection(String title, List<Widget> children) {
    return Container(
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
          Text(title,
              style: AppTypography.labelSM.copyWith(
                  color: AppColors.primary)),
          const SizedBox(height: AppSpacing.sm),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: AppTypography.bodySM),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '–' : value,
              style: AppTypography.bodyMD.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgress(int step) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      color: AppColors.surfaceContainerLow,
      child: Row(
        children: List.generate(3, (i) {
          final s = i + 1;
          final isActive = s == step;
          final isDone = s < step;
          return Expanded(
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isActive || isDone
                        ? AppColors.primary
                        : AppColors.surfaceContainerHigh,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isDone
                        ? const Icon(Icons.check,
                            size: 14, color: AppColors.onPrimary)
                        : Text(
                            '$s',
                            style: AppTypography.labelSM.copyWith(
                              color: isActive
                                  ? AppColors.onPrimary
                                  : AppColors.onSurfaceVariant,
                            ),
                          ),
                  ),
                ),
                if (s < 3)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isDone
                          ? AppColors.primary
                          : AppColors.surfaceContainerHigh,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }
}
