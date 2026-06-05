import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:path/path.dart' as p;
import '../../../../config/app_palette.dart';
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
    final palette = context.palette;

    // Kiểm tra ảnh xem trước đầu tiên
    final hasImage = state.images.isNotEmpty || state.existingImages.isNotEmpty;
    final firstImagePath = state.images.isNotEmpty
        ? state.images.first
        : (state.existingImages.isNotEmpty ? state.existingImages.first : '');
    final isNetworkImage = firstImagePath.startsWith('http');

    return Scaffold(
      backgroundColor: palette.surface,
      appBar: AppBar(
        title: Text(state.isEditing ? 'Chỉnh sửa phòng' : 'Thêm phòng'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/landlord/create-room/step2'),
        ),
      ),
      body: Column(
        children: [
          _buildProgress(context, 3),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                const Text('Bước 3: Xem trước & Xác nhận',
                    style: AppTypography.titleMD),
                const SizedBox(height: AppSpacing.md),

                // ─── THẺ XEM TRƯỚC PHÒNG (PREVIEW CARD) ──────────────────
                Container(
                  decoration: BoxDecoration(
                    color: palette.surfaceLowest,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    boxShadow: const [AppShadows.card],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hiển thị ảnh xem trước (hỗ trợ cả link Web lẫn file Local)
                      SizedBox(
                        height: 180,
                        width: double.infinity,
                        child: hasImage
                            ? (isNetworkImage
                                ? CachedNetworkImage(
                                    imageUrl: firstImagePath,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) =>
                                        Container(color: palette.surfaceLow),
                                    errorWidget: (_, __, ___) => Container(
                                      color: palette.surfaceLow,
                                      child: const Icon(Icons.home_outlined,
                                          size: 64),
                                    ),
                                  )
                                : Image.file(
                                    File(firstImagePath),
                                    fit: BoxFit.cover,
                                  ))
                            : Container(
                                color: palette.surfaceLow,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_photo_alternate_outlined,
                                          size: 48,
                                          color: palette.onSurfaceVariant),
                                      const SizedBox(height: 8),
                                      const Text('Chưa có ảnh'),
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
                                color: palette.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Row(
                              children: [
                                Icon(Icons.location_on_outlined,
                                    size: 14, color: palette.onSurfaceVariant),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    state.address.isEmpty
                                        ? state.district
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
                                Icon(Icons.straighten_outlined,
                                    size: 14, color: palette.onSurfaceVariant),
                                const SizedBox(width: 4),
                                Text(
                                  '${state.area.toStringAsFixed(0)} m²',
                                  style: AppTypography.bodyMD,
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Icon(Icons.payments_outlined,
                                    size: 14, color: palette.onSurfaceVariant),
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

                // ─── TÓM TẮT THÔNG TIN (INFO SUMMARY) ──────────────────────
                _summarySection(context, 'Thông tin phòng', [
                  _infoRow(context, 'Tên phòng', state.title),
                  _infoRow(context, 'Quận/Huyện', state.district),
                  _infoRow(context, 'Địa chỉ', state.address),
                  _infoRow(context, 'Diện tích',
                      '${state.area.toStringAsFixed(0)} m²'),
                  _infoRow(context, 'Giá thuê',
                      '${_formatCurrency(state.price)}đ/tháng'),
                  _infoRow(context, 'Đặt cọc', '${state.depositMonths} tháng'),
                  if (state.videoPath != null)
                    _infoRow(context, 'Video giới thiệu mới',
                        p.basename(state.videoPath!))
                  else if (state.existingVideoUrl != null)
                    _infoRow(context, 'Video giới thiệu',
                        'Đang sử dụng video đã lưu'),
                ]),
                const SizedBox(height: AppSpacing.md),

                // Tiện nghi
                if (state.amenities.isNotEmpty)
                  _summarySection(
                      context, 'Tiện nghi (${state.amenities.length})', [
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
                                        palette.primary.withValues(alpha: 0.12),
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.chip),
                                  ),
                                  child: Text(
                                    a,
                                    style: AppTypography.bodySM.copyWith(
                                      color: palette.primary,
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  ]),
                const SizedBox(height: AppSpacing.md),

                // Mô tả
                if (state.description.isNotEmpty)
                  _summarySection(context, 'Mô tả', [
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child:
                          Text(state.description, style: AppTypography.bodyMD),
                    ),
                  ]),
                const SizedBox(height: AppSpacing.lg),

                // Hiển thị thông báo lỗi (nếu có)
                if (state.error != null)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: palette.dangerContainer,
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                    child: Text(
                      state.error!,
                      style:
                          AppTypography.bodyMD.copyWith(color: palette.danger),
                    ),
                  ),
                if (state.error != null) const SizedBox(height: AppSpacing.md),

                // NÚT ĐĂNG PHÒNG & CHỈNH SỬA
                AppButton(
                  text: state.isEditing ? 'Lưu thay đổi' : 'Đăng phòng trọ',
                  onPressed: state.isSubmitting
                      ? null
                      : () => _submit(context, ref, notifier, state.isEditing),
                  isLoading: state.isSubmitting,
                  icon: state.isEditing
                      ? Icons.save_outlined
                      : Icons.publish_outlined,
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  text: 'Chỉnh sửa lại',
                  type: AppButtonType.secondary,
                  onPressed: () => context.go('/landlord/create-room/step1'),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit(BuildContext context, WidgetRef ref,
      CreateRoomNotifier notifier, bool isEditing) async {
    final success = await notifier.submit();
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing
              ? 'Cập nhật phòng trọ thành công! 🎉'
              : 'Đăng phòng trọ thành công! 🎉'),
          backgroundColor: context.palette.success,
        ),
      );
      notifier.reset();
      context.go('/landlord');
    }
  }

  Widget _summarySection(
      BuildContext context, String title, List<Widget> children) {
    final palette = context.palette;
    return Container(
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
          Text(title,
              style: AppTypography.labelSM.copyWith(color: palette.primary)),
          const SizedBox(height: AppSpacing.sm),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    final palette = context.palette;
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
                color: palette.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgress(BuildContext context, int step) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      color: palette.surfaceLow,
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
                        ? palette.primary
                        : palette.surfaceHigh,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isDone
                        ? Icon(Icons.check, size: 14, color: palette.onPrimary)
                        : Text(
                            '$s',
                            style: AppTypography.labelSM.copyWith(
                              color: isActive
                                  ? palette.onPrimary
                                  : palette.onSurfaceVariant,
                            ),
                          ),
                  ),
                ),
                if (s < 3)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isDone ? palette.primary : palette.surfaceHigh,
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
