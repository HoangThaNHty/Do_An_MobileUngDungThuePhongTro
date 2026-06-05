import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/app_palette.dart';
import '../../../config/constants.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/providers/bill_provider.dart';
import '../../../controllers/providers/room_provider.dart';
import '../../../controllers/providers/create_room_provider.dart';
import '../../../models/entities/rental.dart';
import '../../../repositories/room_repository.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/room_video_player.dart';
import '../../widgets/common/status_chips.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LandlordRoomDetailScreen extends ConsumerWidget {
  final String roomId;

  const LandlordRoomDetailScreen({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final room = ref.watch(roomByIdProvider(roomId));
    final user = ref.watch(currentUserProvider);
    final palette = context.palette;
    final lockedByRental = ref.watch(allRentalsProvider).maybeWhen(
          data: (rentals) => rentals.any(
            (rental) =>
                rental.roomId == roomId &&
                rental.showToLandlord &&
                (rental.status == RentalStatus.pending ||
                    rental.status == RentalStatus.active),
          ),
          orElse: () => false,
        );

    if (room == null || room.landlordId != user?.id) {
      return Scaffold(
        backgroundColor: palette.surface,
        appBar: AppBar(title: const Text('Chi tiết phòng trọ')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              const Text(
                  'Không tìm thấy phòng hoặc bạn không có quyền truy cập!',
                  style: AppTypography.titleSM),
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
      backgroundColor: palette.surface,
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
                      color: palette.surfaceLow,
                      child: Icon(
                        Icons.home_outlined,
                        size: 72,
                        color: palette.onSurfaceVariant,
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
                          color: palette.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.straighten_outlined,
                          size: 16, color: palette.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        '${room.area.toStringAsFixed(0)} m²',
                        style: AppTypography.titleSM
                            .copyWith(color: palette.onSurfaceVariant),
                      ),
                    ],
                  ),
                  const Divider(height: AppSpacing.xl),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on_outlined,
                          color: palette.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Địa chỉ phòng',
                                style: AppTypography.titleSM),
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
                        border: Border.all(color: palette.outlineVariant),
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
                    const Text('Chưa cấu hình tiện nghi',
                        style: AppTypography.bodySM)
                  else
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      children: room.amenities.map((amenity) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: palette.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check,
                                  size: 14, color: palette.primary),
                              const SizedBox(width: 4),
                              Text(
                                amenity,
                                style: AppTypography.labelSM
                                    .copyWith(color: palette.primary),
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
                    room.description.isNotEmpty
                        ? room.description
                        : 'Không có mô tả cho phòng trọ này.',
                    style: AppTypography.bodyMD.copyWith(height: 1.5),
                  ),

                  // Video introduction (if exists)
                  if (room.videoUrl != null &&
                      room.videoUrl!.trim().isNotEmpty) ...[
                    const Divider(height: AppSpacing.xl),
                    RoomVideoPlayer(
                      videoUrl: room.videoUrl!,
                      subtitle:
                          'Video này đang hiển thị cho người thuê khi xem chi tiết phòng',
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xxl),

                  if (lockedByRental) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: palette.warningContainer,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        border: Border.all(
                          color: palette.warning.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.lock_outline, color: palette.warning),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Phòng đang có đặt cọc hoặc người thuê, không thể gỡ bài đăng. Hãy xử lý/hủy hợp đồng trước khi gỡ phòng.',
                              style: AppTypography.bodySM.copyWith(
                                color: palette.warning,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // ─── Landlord Action Buttons ────────────
                  Row(
                    children: [
                      // Nút Gỡ phòng (Xóa)
                      Expanded(
                        child: AppButton(
                          text: 'Gỡ bài đăng',
                          type: AppButtonType.secondary,
                          onPressed: lockedByRental
                              ? null
                              : () => _confirmDeleteRoom(context, ref),
                          icon: lockedByRental
                              ? Icons.lock_outline
                              : Icons.delete_outline,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      // Nút Chỉnh sửa phòng
                      Expanded(
                        child: AppButton(
                          text: 'Chỉnh sửa',
                          onPressed: () {
                            ref
                                .read(createRoomProvider.notifier)
                                .loadRoomForEdit(room);
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
                        content:
                            Text('Đã gỡ bài đăng phòng trọ thành công! 🎉'),
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
                style: TextStyle(
                    color: AppColors.error, fontWeight: FontWeight.bold),
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
