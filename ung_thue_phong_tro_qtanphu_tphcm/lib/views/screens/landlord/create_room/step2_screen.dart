import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
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
    'Điều hòa', 'Nóng lạnh', 'Tủ lạnh', 'WiFi',
    'Máy giặt', 'Ban công', 'Bếp', 'Tivi',
    'Tủ quần áo', 'Bãi giữ xe', 'Bảo vệ 24/7',
    'Camera an ninh', 'Thang máy', 'Hồ bơi',
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
        SnackBar(content: Text('Không thể chọn ảnh: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  /// Chọn video thật từ Thư viện thiết bị
  Future<void> _pickVideo(CreateRoomNotifier notifier) async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 60), // Giới hạn video 60s để tối ưu băng thông
      );
      if (video != null) {
        notifier.setVideo(video.path);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể chọn video: $e'), backgroundColor: AppColors.error),
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
        SnackBar(content: Text('Không thể phát video: $e'), backgroundColor: AppColors.error),
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
        SnackBar(content: Text('Không thể mở video: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createRoomProvider);
    final notifier = ref.read(createRoomProvider.notifier);

    // Đồng bộ các tiện nghi hiện có vào gợi ý tùy chọn khi chỉnh sửa phòng
    for (final a in state.amenities) {
      if (!_allAmenities.contains(a) && !_customSuggestions.contains(a)) {
        _customSuggestions.add(a);
      }
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
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
                const Text('Bước 2: Ảnh, Video & Tiện nghi', style: AppTypography.titleMD),
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
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(AppRadius.button),
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
                      
                      // 1. Danh sách ảnh Cloudinary cũ (khi sửa phòng)
                      ...state.existingImages.asMap().entries.map((e) {
                        final index = e.key;
                        final url = e.value;

                        return Stack(
                          children: [
                            Container(
                              width: 90,
                              height: 90,
                              margin: const EdgeInsets.only(right: AppSpacing.sm),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(AppRadius.button),
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
                                onTap: () => notifier.removeExistingImage(index),
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
                            // Thêm nhãn "Ảnh cũ" nhỏ ở góc dưới để phân biệt
                            Positioned(
                              bottom: 2,
                              left: 2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Hiện tại',
                                  style: TextStyle(color: Colors.white, fontSize: 8),
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
                              margin: const EdgeInsets.only(right: AppSpacing.sm),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(AppRadius.button),
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
                            Positioned(
                              bottom: 2,
                              left: 2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.only(
                                    bottomLeft: Radius.circular(4),
                                    topRight: Radius.circular(4),
                                  ),
                                ),
                                child: const Text(
                                  'Mới',
                                  style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
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
                      style: AppTypography.bodySM.copyWith(color: AppColors.error),
                    ),
                  ),
                const SizedBox(height: AppSpacing.lg),

                // ─── VIDEO SECTION ──────────────────────
                const Text('Video giới thiệu (Tùy chọn)', style: AppTypography.titleSM),
                const SizedBox(height: AppSpacing.sm),
                
                if (state.videoPath != null)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(color: AppColors.outlineVariant),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.video_file, color: AppColors.primary, size: 36),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.basename(state.videoPath!),
                                style: AppTypography.bodyMD.copyWith(fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Video mới chọn sẵn sàng tải lên',
                                style: AppTypography.bodySM.copyWith(color: AppColors.available),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.play_circle_outline, color: AppColors.primary),
                          onPressed: () => _playLocalVideo(state.videoPath!),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppColors.error),
                          onPressed: () => notifier.removeVideo(),
                        ),
                      ],
                    ),
                  )
                else if (state.existingVideoUrl != null)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(color: AppColors.outlineVariant),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.video_camera_back, color: AppColors.primary, size: 36),
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
                                style: AppTypography.bodySM.copyWith(color: AppColors.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.play_circle_outline, color: AppColors.primary),
                          onPressed: () => _playOnlineVideo(state.existingVideoUrl!),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppColors.error),
                          onPressed: () => notifier.removeExistingVideo(),
                        ),
                      ],
                    ),
                  )
                else
                  GestureDetector(
                    onTap: () => _pickVideo(notifier),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        border: Border.all(color: AppColors.outlineVariant, style: BorderStyle.solid),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.video_call_outlined, color: AppColors.primary, size: 26),
                          SizedBox(width: 8),
                          Text('Tải lên Video phòng trọ (Max 60s)', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
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
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.1)
                                : AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(AppRadius.chip),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isSelected) ...[
                                const Icon(Icons.check_circle, size: 14, color: AppColors.primary),
                                const SizedBox(width: 4),
                              ],
                              Text(
                                a,
                                style: AppTypography.labelSM.copyWith(
                                  color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                    // Hiển thị các tiện nghi gợi ý mặc định chưa được chọn
                    ..._allAmenities.where((a) => !state.amenities.contains(a)).map((a) {
                      return GestureDetector(
                        onTap: () => notifier.toggleAmenity(a),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(AppRadius.chip),
                          ),
                          child: Text(
                            a,
                            style: AppTypography.labelSM.copyWith(
                              color: AppColors.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      );
                    }),

                    // Hiển thị các tiện nghi tự gõ chưa được chọn (tránh bị biến mất)
                    ..._customSuggestions.where((a) => !state.amenities.contains(a)).map((a) {
                      return GestureDetector(
                        onTap: () => notifier.toggleAmenity(a),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(AppRadius.chip),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1),
                          ),
                          child: Text(
                            a,
                            style: AppTypography.labelSM.copyWith(
                              color: AppColors.primary,
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
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppRadius.input),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _customAmenityCtrl,
                          decoration: const InputDecoration(
                            hintText: 'Tự nhập tiện nghi khác (VD: Ban công riêng...)',
                            border: InputBorder.none,
                          ),
                          style: AppTypography.bodyMD,
                          onSubmitted: (_) => _addCustomAmenity(notifier),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: AppColors.primary),
                        onPressed: () => _addCustomAmenity(notifier),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Thống kê tiện nghi đã chọn
                if (state.amenities.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.available.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_outline, size: 16, color: AppColors.onAvailable),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Đã chọn ${state.amenities.length} tiện nghi',
                          style: AppTypography.labelSM.copyWith(color: AppColors.onAvailable),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: AppSpacing.xl),

                AppButton(
                  text: 'Tiếp theo: Xem trước',
                  onPressed: (state.images.isEmpty && state.existingImages.isEmpty)
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
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
                    color: isActive || isDone ? AppColors.primary : AppColors.surfaceContainerHigh,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isDone
                        ? const Icon(Icons.check, size: 14, color: AppColors.onPrimary)
                        : Text(
                            '$s',
                            style: AppTypography.labelSM.copyWith(
                              color: isActive ? AppColors.onPrimary : AppColors.onSurfaceVariant,
                            ),
                          ),
                  ),
                ),
                if (s < 3)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isDone ? AppColors.primary : AppColors.surfaceContainerHigh,
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
