import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../config/app_palette.dart';
import '../../../../config/constants.dart';
import '../../../../controllers/providers/create_room_provider.dart';
import '../../../widgets/common/app_button.dart';

class Step2Screen extends ConsumerStatefulWidget {
  const Step2Screen({super.key});

  @override
  ConsumerState<Step2Screen> createState() => _Step2ScreenState();
}

class _Step2ScreenState extends ConsumerState<Step2Screen> {
  final TextEditingController _customAmenityCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final List<String> _customSuggestions = [];

  static const List<String> _allAmenities = [
    'Điều hòa',
    'Nóng lạnh',
    'Tủ lạnh',
    'WiFi',
    'Máy giặt',
    'Ban công',
    'Bếp',
    'Tivi',
    'Tủ quần áo',
    'Bãi giữ xe',
    'Bảo vệ 24/7',
    'Camera an ninh',
    'Thang máy',
    'Hồ bơi',
  ];

  @override
  void dispose() {
    _customAmenityCtrl.dispose();
    super.dispose();
  }

  /// Chọn hình ảnh thật từ Thư viện thiết bị
  Future<void> _pickImage(CreateRoomNotifier notifier) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // Nén ảnh nhẹ ở client để tăng tốc độ upload
      );
      if (image != null) {
        notifier.addImage(image.path);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể chọn ảnh: $e'),
          backgroundColor: context.palette.danger,
        ),
      );
    }
  }

  /// Chọn video thật từ Thư viện thiết bị
  Future<void> _pickVideo(CreateRoomNotifier notifier) async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(
            seconds: 60), // Giới hạn video 60s để tối ưu băng thông
      );
      if (video != null) {
        notifier.setVideo(video.path);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể chọn video: $e'),
          backgroundColor: context.palette.danger,
        ),
      );
    }
  }

  /// Thêm tiện nghi tự gõ
  void _addCustomAmenity(CreateRoomNotifier notifier) {
    final text = _customAmenityCtrl.text.trim();
    if (text.isEmpty) return;

    notifier.addCustomAmenity(text);
    if (!_customSuggestions.contains(text) && !_allAmenities.contains(text)) {
      setState(() {
        _customSuggestions.add(text);
      });
    }
    _customAmenityCtrl.clear();
    FocusScope.of(context).unfocus(); // Đóng bàn phím sau khi thêm
  }

  Future<void> _playLocalVideo(String path) async {
    try {
      final uri = Uri.file(path);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể phát video: $e'),
          backgroundColor: context.palette.danger,
        ),
      );
    }
  }

  Future<void> _playOnlineVideo(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể mở video: $e'),
          backgroundColor: context.palette.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createRoomProvider);
    final notifier = ref.read(createRoomProvider.notifier);
    final palette = context.palette;

    // Đồng bộ các tiện nghi hiện có vào gợi ý tùy chọn khi chỉnh sửa phòng
    for (final a in state.amenities) {
      if (!_allAmenities.contains(a) && !_customSuggestions.contains(a)) {
        _customSuggestions.add(a);
      }
    }

    return Scaffold(
      backgroundColor: palette.surface,
      appBar: AppBar(
        title: Text(state.isEditing ? 'Chỉnh sửa phòng' : 'Thêm phòng'),
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
                const Text('Bước 2: Ảnh, Video & Tiện nghi',
                    style: AppTypography.titleMD),
                const SizedBox(height: AppSpacing.lg),

                // ─── IMAGES SECTION ─────────────────────
                const Text('Ảnh phòng trọ *', style: AppTypography.titleSM),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  height: 110,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      // Nút thêm ảnh
                      GestureDetector(
                        onTap: () => _pickImage(notifier),
                        child: Container(
                          width: 90,
                          height: 90,
                          margin: const EdgeInsets.only(right: AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: palette.surfaceLow,
                            borderRadius:
                                BorderRadius.circular(AppRadius.button),
                            border: Border.all(
                              color: palette.outlineVariant,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate_outlined,
                                color: palette.primary,
                                size: 28,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Thêm ảnh',
                                style: AppTypography.bodySM.copyWith(
                                  color: palette.primary,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // 1. Danh sách ảnh Cloudinary cũ (khi sửa phòng)
                      ...state.existingImages.asMap().entries.map((e) {
                        final index = e.key;
                        final url = e.value;

                        return Stack(
                          children: [
                            Container(
                              width: 90,
                              height: 90,
                              margin:
                                  const EdgeInsets.only(right: AppSpacing.sm),
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.button),
                                image: DecorationImage(
                                  image: CachedNetworkImageProvider(url),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 2,
                              right: AppSpacing.sm + 2,
                              child: GestureDetector(
                                onTap: () =>
                                    notifier.removeExistingImage(index),
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: palette.danger,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.close,
                                    size: 12,
                                    color: palette.onPrimary,
                                  ),
                                ),
                              ),
                            ),
                            // Thêm nhãn "Ảnh cũ" nhỏ ở góc dưới để phân biệt
                            Positioned(
                              bottom: 2,
                              left: 2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Hiện tại',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 8),
                                ),
                              ),
                            ),
                          ],
                        );
                      }),

                      // 2. Danh sách ảnh mới chọn local
                      ...state.images.asMap().entries.map((e) {
                        final index = e.key;
                        final path = e.value;

                        return Stack(
                          children: [
                            Container(
                              width: 90,
                              height: 90,
                              margin:
                                  const EdgeInsets.only(right: AppSpacing.sm),
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.button),
                                image: DecorationImage(
                                  image: FileImage(File(path)),
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
                                  decoration: BoxDecoration(
                                    color: palette.danger,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.close,
                                    size: 12,
                                    color: palette.onPrimary,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 2,
                              left: 2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: palette.primary,
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(4),
                                    topRight: Radius.circular(4),
                                  ),
                                ),
                                child: const Text(
                                  'Mới',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
                if (state.images.isEmpty && state.existingImages.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(
                      'Vui lòng thêm ít nhất 1 ảnh thật của phòng trọ.',
                      style:
                          AppTypography.bodySM.copyWith(color: palette.danger),
                    ),
                  ),
                const SizedBox(height: AppSpacing.lg),

                // ─── VIDEO SECTION ──────────────────────
                const Text('Video giới thiệu (Tùy chọn)',
                    style: AppTypography.titleSM),
                const SizedBox(height: AppSpacing.sm),

                if (state.videoPath != null)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: palette.surfaceLowest,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(color: palette.outlineVariant),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.video_file,
                            color: palette.primary, size: 36),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.basename(state.videoPath!),
                                style: AppTypography.bodyMD
                                    .copyWith(fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Video mới chọn sẵn sàng tải lên',
                                style: AppTypography.bodySM
                                    .copyWith(color: palette.success),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.play_circle_outline,
                              color: palette.primary),
                          onPressed: () => _playLocalVideo(state.videoPath!),
                        ),
                        IconButton(
                          icon:
                              Icon(Icons.delete_outline, color: palette.danger),
                          onPressed: () => notifier.removeVideo(),
                        ),
                      ],
                    ),
                  )
                else if (state.existingVideoUrl != null)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: palette.surfaceLowest,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(color: palette.outlineVariant),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.video_camera_back,
                            color: palette.primary, size: 36),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Video hiện tại của phòng',
                                style: TextStyle(fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Đang lưu trữ trên máy chủ Cloudinary',
                                style: AppTypography.bodySM
                                    .copyWith(color: palette.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.play_circle_outline,
                              color: palette.primary),
                          onPressed: () =>
                              _playOnlineVideo(state.existingVideoUrl!),
                        ),
                        IconButton(
                          icon:
                              Icon(Icons.delete_outline, color: palette.danger),
                          onPressed: () => notifier.removeExistingVideo(),
                        ),
                      ],
                    ),
                  )
                else
                  GestureDetector(
                    onTap: () => _pickVideo(notifier),
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: palette.surfaceLow,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        border: Border.all(
                            color: palette.outlineVariant,
                            style: BorderStyle.solid),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.video_call_outlined,
                              color: palette.primary, size: 26),
                          const SizedBox(width: 8),
                          Text('Tải lên Video phòng trọ (Max 60s)',
                              style: TextStyle(
                                  color: palette.primary,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),

                // ─── AMENITIES SECTION ──────────────────
                const Text('Tiện nghi phòng trọ', style: AppTypography.titleSM),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    // Hiển thị danh sách tiện nghi mặc định + custom đã có trong state
                    ...state.amenities.map((a) {
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
                                ? palette.primary.withValues(alpha: 0.12)
                                : palette.surfaceLow,
                            borderRadius: BorderRadius.circular(AppRadius.chip),
                            border: Border.all(
                              color: isSelected
                                  ? palette.primary
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isSelected) ...[
                                Icon(Icons.check_circle,
                                    size: 14, color: palette.primary),
                                const SizedBox(width: 4),
                              ],
                              Text(
                                a,
                                style: AppTypography.labelSM.copyWith(
                                  color: isSelected
                                      ? palette.primary
                                      : palette.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                    // Hiển thị các tiện nghi gợi ý mặc định chưa được chọn
                    ..._allAmenities
                        .where((a) => !state.amenities.contains(a))
                        .map((a) {
                      return GestureDetector(
                        onTap: () => notifier.toggleAmenity(a),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: palette.surfaceLow,
                            borderRadius: BorderRadius.circular(AppRadius.chip),
                          ),
                          child: Text(
                            a,
                            style: AppTypography.labelSM.copyWith(
                              color: palette.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      );
                    }),

                    // Hiển thị các tiện nghi tự gõ chưa được chọn (tránh bị biến mất)
                    ..._customSuggestions
                        .where((a) => !state.amenities.contains(a))
                        .map((a) {
                      return GestureDetector(
                        onTap: () => notifier.toggleAmenity(a),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: palette.surfaceLow,
                            borderRadius: BorderRadius.circular(AppRadius.chip),
                            border: Border.all(
                                color: palette.primary.withValues(alpha: 0.35),
                                width: 1),
                          ),
                          child: Text(
                            a,
                            style: AppTypography.labelSM.copyWith(
                              color: palette.primary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Ô NHẬP TIỆN NGHI TỰ DO (CUSTOM AMENITY INPUT)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: palette.surfaceLow,
                    borderRadius: BorderRadius.circular(AppRadius.input),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _customAmenityCtrl,
                          decoration: const InputDecoration(
                            hintText:
                                'Tự nhập tiện nghi khác (VD: Ban công riêng...)',
                            border: InputBorder.none,
                          ),
                          style: AppTypography.bodyMD.copyWith(
                            color: palette.onSurface,
                          ),
                          cursorColor: palette.primary,
                          onSubmitted: (_) => _addCustomAmenity(notifier),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.add_circle, color: palette.primary),
                        onPressed: () => _addCustomAmenity(notifier),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Thống kê tiện nghi đã chọn
                if (state.amenities.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: palette.successContainer,
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline,
                            size: 16, color: palette.success),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Đã chọn ${state.amenities.length} tiện nghi',
                          style: AppTypography.labelSM
                              .copyWith(color: palette.success),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: AppSpacing.xl),

                AppButton(
                  text: 'Tiếp theo: Xem trước',
                  onPressed:
                      (state.images.isEmpty && state.existingImages.isEmpty)
                          ? null
                          : () => context.go('/landlord/create-room/step3'),
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

  Widget _buildProgress(int step) {
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
}
