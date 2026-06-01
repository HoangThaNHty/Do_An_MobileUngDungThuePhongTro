import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/constants.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/providers/room_provider.dart';
import '../../../repositories/room_repository.dart';
import '../../../models/entities/room.dart';
import '../../widgets/common/status_chips.dart';

class LandlordMapScreen extends ConsumerStatefulWidget {
  const LandlordMapScreen({super.key});

  @override
  ConsumerState<LandlordMapScreen> createState() => _LandlordMapScreenState();
}

class _LandlordMapScreenState extends ConsumerState<LandlordMapScreen> {
  GoogleMapController? _mapController;
  final _pageController = PageController(viewportFraction: 0.88);
  int _activePageIndex = 0;
  bool _isPageScrolling = false;

  static const LatLng _tanPhuCenter = LatLng(10.7937, 106.6382);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _updateStatus(Room room, RoomStatus newStatus) async {
    try {
      await ref.read(roomRepositoryProvider).updateRoomStatus(room.id, newStatus);
      // Trigger tải lại danh sách phòng
      ref.invalidate(roomProvider);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã cập nhật trạng thái phòng "${room.title}" thành công! 🎉'),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cập nhật thất bại: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final roomState = ref.watch(roomProvider);
    final user = ref.watch(currentUserProvider);

    // Lọc danh sách phòng của riêng chủ trọ
    final landlordRooms = roomState.rooms.where((r) => r.landlordId == user?.id).toList();

    // 1. Tạo Markers phân màu
    final markers = <Marker>{};
    for (int i = 0; i < landlordRooms.length; i++) {
      final room = landlordRooms[i];
      if (room.latitude == null || room.longitude == null) continue;

      // Phân màu Marker dựa trên trạng thái kinh doanh
      double hue = BitmapDescriptor.hueGreen; // Còn trống: Xanh lá
      if (room.status == RoomStatus.rented) {
        hue = BitmapDescriptor.hueBlue; // Đã thuê: Xanh dương
      } else if (room.status == RoomStatus.overdue) {
        hue = BitmapDescriptor.hueRed; // Quá hạn hóa đơn: Đỏ
      }

      markers.add(
        Marker(
          markerId: MarkerId(room.id),
          position: LatLng(room.latitude!, room.longitude!),
          icon: BitmapDescriptor.defaultMarkerWithHue(hue),
          infoWindow: InfoWindow(
            title: room.title,
            snippet: '${room.address} (${room.status == RoomStatus.available ? 'Trống' : 'Đã thuê'})',
          ),
          onTap: () {
            setState(() {
              _activePageIndex = i;
            });
            _isPageScrolling = true;
            _pageController.animateToPage(
              i,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            ).then((_) => _isPageScrolling = false);
          },
        ),
      );
    }

    // Tọa độ trung tâm camera mặc định bay về phòng đầu tiên của chủ trọ, hoặc quận Tân Phú
    LatLng defaultCenter = _tanPhuCenter;
    if (landlordRooms.isNotEmpty) {
      final firstRoom = landlordRooms.first;
      if (firstRoom.latitude != null && firstRoom.longitude != null) {
        defaultCenter = LatLng(firstRoom.latitude!, firstRoom.longitude!);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bản đồ Tài sản của tôi'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/landlord'),
        ),
      ),
      body: Stack(
        children: [
          // ─── Google Map ───────────────────────────
          GoogleMap(
            onMapCreated: (ctrl) {
              _mapController = ctrl;
            },
            initialCameraPosition: CameraPosition(
              target: defaultCenter,
              zoom: 14.2,
            ),
            markers: markers,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),

          // ─── Lối giải thích ý nghĩa màu ghim ─────────
          Positioned(
            left: AppSpacing.md,
            top: AppSpacing.md,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [AppShadows.card],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLegendRow('🟢 Phòng còn trống', Colors.green),
                  const SizedBox(height: 4),
                  _buildLegendRow('🔵 Phòng đã thuê', Colors.blue),
                  const SizedBox(height: 4),
                  _buildLegendRow('🔴 Phòng quá hạn/nợ', Colors.red),
                ],
              ),
            ),
          ),

          // ─── Airbnb-style Carousel quản lý ngang cho Chủ trọ ─────
          if (landlordRooms.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: 12,
              child: SizedBox(
                height: 146,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: landlordRooms.length,
                  onPageChanged: (index) {
                    if (_isPageScrolling) return;
                    setState(() {
                      _activePageIndex = index;
                    });
                    
                    final room = landlordRooms[index];
                    if (room.latitude != null && room.longitude != null) {
                      _mapController?.animateCamera(CameraUpdate.newLatLng(
                        LatLng(room.latitude!, room.longitude!),
                      ));
                    }
                  },
                  itemBuilder: (context, index) {
                    final room = landlordRooms[index];
                    final isActive = index == _activePageIndex;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        border: Border.all(
                          color: isActive ? AppColors.primary : Colors.transparent,
                          width: 2,
                        ),
                        boxShadow: const [AppShadows.bottomSheet],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.card - 2),
                        child: Row(
                          children: [
                            // Room Image
                            Container(
                              width: 110,
                              height: double.infinity,
                              color: AppColors.surfaceContainerLow,
                              child: room.images.isNotEmpty
                                  ? Image.network(
                                      room.images.first,
                                      fit: BoxFit.cover,
                                    )
                                  : const Icon(Icons.home_outlined, size: 36, color: AppColors.onSurfaceVariant),
                            ),
                            // Room Details & Status Control Toggle
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                room.title,
                                                style: AppTypography.titleSM.copyWith(fontSize: 13, fontWeight: FontWeight.bold),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            RoomStatusChip(status: room.status),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          room.address,
                                          style: AppTypography.bodySM.copyWith(fontSize: 11, color: AppColors.onSurfaceVariant),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                    
                                    // Điều khiển trạng thái phòng realtime
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        // Gạt Switch đổi trạng thái kinh doanh
                                        Row(
                                          children: [
                                            const Text('Sẵn sàng', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
                                            Transform.scale(
                                              scale: 0.7,
                                              child: Switch(
                                                value: room.status == RoomStatus.available,
                                                activeThumbColor: AppColors.available,
                                                onChanged: (val) {
                                                  final newStatus = val ? RoomStatus.available : RoomStatus.rented;
                                                  _updateStatus(room, newStatus);
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                        
                                        // Nút xem chi tiết phòng
                                        GestureDetector(
                                          onTap: () => context.push('/landlord/rooms/detail/${room.id}'),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              'Quản lý',
                                              style: AppTypography.labelSM.copyWith(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

          // Trạng thái trống tài sản
          if (landlordRooms.isEmpty)
            Positioned(
              left: AppSpacing.md,
              right: AppSpacing.md,
              bottom: 24,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  boxShadow: const [AppShadows.bottomSheet],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.primary),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Bạn chưa có tài sản/phòng trọ nào ghim trên bản đồ.',
                        style: AppTypography.bodyMD,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLegendRow(String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.onSurface),
        ),
      ],
    );
  }
}
