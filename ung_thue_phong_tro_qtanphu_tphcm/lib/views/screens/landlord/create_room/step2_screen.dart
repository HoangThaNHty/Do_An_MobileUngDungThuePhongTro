import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/constants.dart';
import '../../../../controllers/providers/create_room_provider.dart';
import '../../../widgets/common/app_button.dart';

class Step2Screen extends ConsumerWidget {
  const Step2Screen({super.key});

  static const List<String> _allAmenities = [
    'Điều hòa', 'Nóng lạnh', 'Tủ lạnh', 'WiFi',
    'Máy giặt', 'Ban công', 'Bếp', 'Tivi',
    'Tủ quần áo', 'Bãi giữ xe', 'Bảo vệ 24/7',
    'Camera an ninh', 'Thang máy', 'Hồ bơi',
  ];

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
          onPressed: () => context.go('/landlord/create-room/step1'),
        ),
      ),
      body: Column(
        children: [
          _buildProgress(2),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                Text('Bước 2: Ảnh & Tiện nghi',
                    style: AppTypography.titleMD),
                const SizedBox(height: AppSpacing.lg),

                // ─── Images Section ─────────────────────
                Text('Ảnh phòng', style: AppTypography.titleSM),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  height: 110,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      // Add photo button
                      GestureDetector(
                        onTap: () => _pickImage(context, notifier),
                        child: Container(
                          width: 90,
                          height: 90,
                          margin: const EdgeInsets.only(right: AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius:
                                BorderRadius.circular(AppRadius.button),
                            border: Border.all(
                              color: AppColors.outlineVariant,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.add_photo_alternate_outlined,
                                color: AppColors.primary,
                                size: 28,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Thêm ảnh',
                                style: AppTypography.bodySM.copyWith(
                                  color: AppColors.primary,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Existing images
                      ...state.images.asMap().entries.map((e) {
                        final index = e.key;
                        final url = e.value;
                        return Stack(
                          children: [
                            Container(
                              width: 90,
                              height: 90,
                              margin: const EdgeInsets.only(right: AppSpacing.sm),
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.button),
                                image: DecorationImage(
                                  image: NetworkImage(url),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 2,
                              right: AppSpacing.sm + 2,
                              child: GestureDetector(
                                onTap: () => notifier.removeImage(index),
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: const BoxDecoration(
                                    color: AppColors.error,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 12,
                                    color: AppColors.onPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
                if (state.images.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(
                      'Thêm ít nhất 1 ảnh để phòng được duyệt nhanh hơn',
                      style: AppTypography.bodySM,
                    ),
                  ),
                const SizedBox(height: AppSpacing.lg),

                // ─── Amenities ──────────────────────────
                Text('Tiện nghi', style: AppTypography.titleSM),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: _allAmenities.map((a) {
                    final isSelected = state.amenities.contains(a);
                    return GestureDetector(
                      onTap: () => notifier.toggleAmenity(a),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withOpacity(0.1)
                              : AppColors.surfaceContainerLow,
                          borderRadius:
                              BorderRadius.circular(AppRadius.chip),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected) ...[
                              const Icon(
                                Icons.check_circle,
                                size: 14,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              a,
                              style: AppTypography.labelSM.copyWith(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Selected count badge
                if (state.amenities.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.available.withOpacity(0.3),
                      borderRadius:
                          BorderRadius.circular(AppRadius.button),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          size: 16,
                          color: AppColors.onAvailable,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Đã chọn ${state.amenities.length} tiện nghi',
                          style: AppTypography.labelSM.copyWith(
                            color: AppColors.onAvailable,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: AppSpacing.xl),

                AppButton(
                  text: 'Tiếp theo: Xem trước',
                  onPressed: () => context.go('/landlord/create-room/step3'),
                  icon: Icons.arrow_forward,
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _pickImage(BuildContext context, CreateRoomNotifier notifier) {
    // Demo: use placeholder URLs since image_picker needs device context
    const demoUrls = [
      'https://images.unsplash.com/photo-1555854877-bab0e564b8d5?w=400',
      'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=400',
      'https://images.unsplash.com/photo-1484154218962-a197022b5858?w=400',
      'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=400',
    ];
    final idx = DateTime.now().millisecond % demoUrls.length;
    notifier.addImage(demoUrls[idx]);
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
}
