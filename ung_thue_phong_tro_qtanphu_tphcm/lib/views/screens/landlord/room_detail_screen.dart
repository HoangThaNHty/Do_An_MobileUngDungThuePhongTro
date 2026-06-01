import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/constants.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/providers/room_provider.dart';
import '../../../controllers/providers/create_room_provider.dart';
import '../../../repositories/room_repository.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/status_chips.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LandlordRoomDetailScreen extends ConsumerWidget {
  final String roomId;

  const LandlordRoomDetailScreen({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final room = ref.watch(roomByIdProvider(roomId));
    final user = ref.watch(currentUserProvider);

    if (room == null || room.landlordId != user?.id) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết phòng trọ')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              const Text('Không tìm thấy phòng hoặc bạn không có quyền truy cập!', style: AppTypography.titleSM),
              TextButton(
                onPressed: () => context.go('/landlord'),
                child: const Text('Quay lại Trang chủ'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(room.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── Image Slide/Carousel ────────────────
            SizedBox(
              height: 250,
              child: room.images.isNotEmpty
                  ? PageView.builder(
                      itemCount: room.images.length,
                      itemBuilder: (context, index) {
                        return Image.network(
                          room.images[index],
                          fit: BoxFit.cover,
                          width: double.infinity,
                        );
                      },
                    )
                  : Container(
                      color: AppColors.surfaceContainerLow,
                      child: const Icon(
                        Icons.home_outlined,
                        size: 72,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
            ),

            // ─── Room Info Content ───────────────────
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          room.title,
                          style: AppTypography.headlineMD,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      RoomStatusChip(status: room.status),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Price & Area
                  Row(
                    children: [
                      Text(
                        '${_formatCurrency(room.price)}đ/tháng',
                        style: AppTypography.titleMD.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.straighten_outlined, size: 16, color: AppColors.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        '${room.area.toStringAsFixed(0)} m²',
                        style: AppTypography.titleSM.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                  const Divider(height: AppSpacing.xl),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Địa chỉ phòng', style: AppTypography.titleSM),
                            const SizedBox(height: 2),
                            Text(room.address, style: AppTypography.bodyMD),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (room.latitude != null && room.longitude != null)
                    Container(
                      height: 150,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        border: Border.all(color: AppColors.outlineVariant),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(room.latitude!, room.longitude!),
                          zoom: 15,
                        ),
                        liteModeEnabled: true,
                        mapToolbarEnabled: false,
                        myLocationButtonEnabled: false,
                        myLocationEnabled: false,
                        zoomControlsEnabled: false,
                        markers: {
                          Marker(
                            markerId: const MarkerId('room_location_mini'),
                            position: LatLng(room.latitude!, room.longitude!),
                          ),
                        },
                      ),
                    ),
                  const Divider(height: AppSpacing.xl),

                  // Amenities Grid
                  const Text('Tiện nghi sẵn có', style: AppTypography.titleSM),
                  const SizedBox(height: AppSpacing.sm),
                  if (room.amenities.isEmpty)
                    const Text('Chưa cấu hình tiện nghi', style: AppTypography.bodySM)
                  else
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      children: room.amenities.map((amenity) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check, size: 14, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text(
                                amenity,
                                style: AppTypography.labelSM.copyWith(color: AppColors.primary),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  const Divider(height: AppSpacing.xl),

                  // Description
                  const Text('Mô tả chi tiết', style: AppTypography.titleSM),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    room.description.isNotEmpty ? room.description : 'Không có mô tả cho phòng trọ này.',
                    style: AppTypography.bodyMD.copyWith(height: 1.5),
                  ),
                  
                  // Video introduction (if exists)
                  if (room.videoUrl != null && room.videoUrl!.isNotEmpty) ...[
                    const Divider(height: AppSpacing.xl),
                    const Text('Video giới thiệu', style: AppTypography.titleSM),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        boxShadow: const [AppShadows.card],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.video_library_outlined, color: AppColors.primary),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Đã tải lên video giới thiệu phòng trọ thành công.',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Video link copy vào clipboard!')),
                              );
                            },
                            child: const Text('Xem link'),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xxl),

                  // ─── Landlord Action Buttons ────────────
                  Row(
                    children: [
                      // Nút Gỡ phòng (Xóa)
                      Expanded(
                        child: AppButton(
                          text: 'Gỡ bài đăng',
                          type: AppButtonType.secondary,
                          onPressed: () => _confirmDeleteRoom(context, ref),
                          icon: Icons.delete_outline,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      // Nút Chỉnh sửa phòng
                      Expanded(
                        child: AppButton(
                          text: 'Chỉnh sửa',
                          onPressed: () {
                            ref.read(createRoomProvider.notifier).loadRoomForEdit(room);
                            context.go('/landlord/create-room/step1');
                          },
                          icon: Icons.edit_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteRoom(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Xác nhận gỡ bài đăng?'),
          content: const Text(
            'Hành động này sẽ xóa hoàn toàn thông tin phòng trọ khỏi hệ thống và không thể khôi phục lại. Bạn có chắc chắn muốn gỡ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy bỏ'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext); // Đóng Dialog
                
                try {
                  final repo = ref.read(roomRepositoryProvider);
                  await repo.deleteRoom(roomId);
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã gỡ bài đăng phòng trọ thành công! 🎉'),
                        backgroundColor: Color(0xFF2E7D32),
                      ),
                    );
                    context.pop(); // Quay lại màn hình quản lý
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Gỡ bài thất bại: $e'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
              child: const Text(
                'Đồng ý gỡ',
                style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }
}
