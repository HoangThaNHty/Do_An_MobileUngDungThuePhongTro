import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/constants.dart';
import '../../../controllers/providers/room_provider.dart';
import '../../../models/entities/room.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  GoogleMapController? _mapController;
  Room? _selectedRoom;

  static const LatLng _hcmCenter = LatLng(10.7769, 106.7009);

  @override
  Widget build(BuildContext context) {
    final rooms = ref.watch(filteredRoomsProvider);

    // Build markers
    final markers = <Marker>{};
    for (final room in rooms) {
      if (room.latitude != null && room.longitude != null) {
        markers.add(
          Marker(
            markerId: MarkerId(room.id),
            position: LatLng(room.latitude!, room.longitude!),
            icon: room.status == RoomStatus.available
                ? BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueGreen)
                : BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueRed),
            infoWindow: InfoWindow(
              title: room.title,
              snippet: '${_formatCurrency(room.price)}đ/tháng',
            ),
            onTap: () => setState(() => _selectedRoom = room),
          ),
        );
      }
    }

    return Scaffold(
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            onMapCreated: (ctrl) => _mapController = ctrl,
            initialCameraPosition: const CameraPosition(
              target: _hcmCenter,
              zoom: 12,
            ),
            markers: markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            onTap: (_) => setState(() => _selectedRoom = null),
          ),

          // Back button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.go('/tenant'),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        shape: BoxShape.circle,
                        boxShadow: const [AppShadows.card],
                      ),
                      child: const Icon(Icons.arrow_back, size: 20),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius:
                            BorderRadius.circular(AppRadius.chip),
                        boxShadow: const [AppShadows.card],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search,
                              size: 18, color: AppColors.onSurfaceVariant),
                          const SizedBox(width: 8),
                          Text('Tìm trên bản đồ',
                              style: AppTypography.bodyMD),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Legend
          Positioned(
            top: 80,
            right: AppSpacing.md,
            child: SafeArea(
              child: Column(
                children: [
                  _legendItem(AppColors.available, 'Còn trống'),
                  const SizedBox(height: 4),
                  _legendItem(AppColors.overdue, 'Đã thuê'),
                ],
              ),
            ),
          ),

          // Selected room card
          if (_selectedRoom != null)
            Positioned(
              bottom: 90,
              left: AppSpacing.md,
              right: AppSpacing.md,
              child: _buildRoomPreviewCard(context, _selectedRoom!),
            ),

          // Room count badge
          Positioned(
            bottom: 90,
            right: AppSpacing.md,
            child: _selectedRoom == null
                ? Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    decoration: BoxDecoration(
                      gradient: AppGradients.primaryButton,
                      borderRadius:
                          BorderRadius.circular(AppRadius.chip),
                      boxShadow: const [AppShadows.fab],
                    ),
                    child: Text(
                      '${markers.length} phòng',
                      style: AppTypography.labelSM.copyWith(
                        color: AppColors.onPrimary,
                      ),
                    ),
                  )
                : const SizedBox(),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.button),
        boxShadow: const [AppShadows.card],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
                color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(label, style: AppTypography.bodySM),
        ],
      ),
    );
  }

  Widget _buildRoomPreviewCard(BuildContext context, Room room) {
    return GestureDetector(
      onTap: () => context.go('/tenant/room/${room.id}'),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: const [AppShadows.bottomSheet],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(room.title, style: AppTypography.titleSM),
                  const SizedBox(height: 2),
                  Text(room.address,
                      style: AppTypography.bodySM,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${_formatCurrency(room.price)}đ/tháng',
                    style: AppTypography.bodyMD.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                gradient: AppGradients.primaryButton,
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
              child: const Text(
                'Xem',
                style: AppTypography.button,
              ),
            ),
          ],
        ),
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
