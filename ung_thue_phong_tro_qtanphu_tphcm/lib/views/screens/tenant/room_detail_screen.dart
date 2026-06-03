import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../config/constants.dart';
import '../../../controllers/providers/room_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/status_chips.dart';
import '../../../models/entities/room.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';

class RoomDetailScreen extends ConsumerStatefulWidget {
  final String roomId;

  const RoomDetailScreen({super.key, required this.roomId});

  @override
  ConsumerState<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends ConsumerState<RoomDetailScreen> {
  int _currentImageIndex = 0;
  final PageController _pageCtrl = PageController();
  LatLng? _userLocation;
  static const LatLng _tanPhuCenter = LatLng(10.7937, 106.6382);

  @override
  void initState() {
    super.initState();
    _loadUserLocation();
  }

  Future<void> _loadUserLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );
      final detectedLocation = LatLng(position.latitude, position.longitude);
      if (!mounted) return;
      setState(() {
        _userLocation = _isLocationInVietnam(detectedLocation)
            ? detectedLocation
            : _tanPhuCenter;
      });
    } catch (_) {
      if (!mounted) return;
      // Fallback to Tan Phu district center
      setState(() {
        _userLocation = _tanPhuCenter;
      });
    }
  }

  bool _isLocationInVietnam(LatLng location) {
    return location.latitude >= 8.0 &&
        location.latitude <= 24.0 &&
        location.longitude >= 102.0 &&
        location.longitude <= 110.0;
  }

  Future<void> _openGoogleMapsDirections(Room room) async {
    if (room.latitude == null || room.longitude == null) return;

    final origin = _userLocation ?? _tanPhuCenter;
    final destination = LatLng(room.latitude!, room.longitude!);
    final url = Uri.https(
      'www.google.com',
      '/maps/dir/',
      {
        'api': '1',
        'origin': '${origin.latitude},${origin.longitude}',
        'destination': '${destination.latitude},${destination.longitude}',
        'travelmode': 'driving',
      },
    );

    HapticFeedback.mediumImpact();
    final opened = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể mở Google Maps để dẫn đường.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final room = ref.watch(roomByIdProvider(widget.roomId));

    if (room == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết phòng')),
        body: const Center(child: Text('Không tìm thấy phòng')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          // ─── Image Carousel (SliverAppBar) ──────
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppColors.surface,
            leading: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      AppColors.surfaceContainerLowest.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, size: 20),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Image carousel
                  PageView.builder(
                    controller: _pageCtrl,
                    itemCount: room.images.isEmpty ? 1 : room.images.length,
                    onPageChanged: (i) =>
                        setState(() => _currentImageIndex = i),
                    itemBuilder: (context, index) {
                      if (room.images.isEmpty) {
                        return Container(
                          color: AppColors.surfaceContainerLow,
                          child: const Icon(
                            Icons.home_outlined,
                            size: 80,
                            color: AppColors.onSurfaceVariant,
                          ),
                        );
                      }
                      return CachedNetworkImage(
                        imageUrl: room.images[index],
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: AppColors.surfaceContainerLow,
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: AppColors.surfaceContainerLow,
                          child: const Icon(Icons.home_outlined, size: 80),
                        ),
                      );
                    },
                  ),
                  // Page indicator dots
                  if (room.images.length > 1)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          room.images.length,
                          (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: i == _currentImageIndex ? 20 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: i == _currentImageIndex
                                  ? AppColors.primary
                                  : AppColors.onPrimary.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ─── Content ────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + Status
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          room.title,
                          style: AppTypography.titleMD,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      RoomStatusChip(status: room.status),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Price
                  Text(
                    '${room.price.toVnd()}đ/tháng',
                    style: AppTypography.headlineMD.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Address
                  _infoRow(Icons.location_on_outlined, room.address),
                  const SizedBox(height: AppSpacing.xs),
                  _infoRow(Icons.straighten_outlined,
                      '${room.area.toStringAsFixed(0)} m²'),
                  const SizedBox(height: AppSpacing.xs),
                  _infoRow(
                      Icons.visibility_outlined, '${room.viewCount} lượt xem'),

                  const SizedBox(height: AppSpacing.md),
                  // Google Map mini với Chỉ đường xem trước (Polyline) chuẩn Premium
                  if (room.latitude != null && room.longitude != null)
                    Stack(
                      children: [
                        Container(
                          height: 180, // Chiều cao tối ưu để hiển thị cả 2 điểm
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppRadius.card),
                            border: Border.all(color: AppColors.outlineVariant),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: GoogleMap(
                            initialCameraPosition: CameraPosition(
                              // Căn camera ở giữa điểm người dùng và phòng trọ
                              target: _userLocation != null
                                  ? LatLng(
                                      (_userLocation!.latitude +
                                              room.latitude!) /
                                          2,
                                      (_userLocation!.longitude +
                                              room.longitude!) /
                                          2,
                                    )
                                  : LatLng(room.latitude!, room.longitude!),
                              zoom: _userLocation != null ? 13.0 : 15.0,
                            ),
                            liteModeEnabled: false, // Tương tác kéo thả mượt mà
                            mapToolbarEnabled: false,
                            myLocationButtonEnabled: false,
                            myLocationEnabled: true,
                            zoomControlsEnabled: false,
                            markers: {
                              Marker(
                                markerId: const MarkerId('room_location_mini'),
                                position:
                                    LatLng(room.latitude!, room.longitude!),
                                infoWindow: InfoWindow(title: room.title),
                              ),
                              if (_userLocation != null)
                                Marker(
                                  markerId:
                                      const MarkerId('user_location_mini'),
                                  position: _userLocation!,
                                  icon: BitmapDescriptor.defaultMarkerWithHue(
                                      BitmapDescriptor.hueCyan),
                                  infoWindow:
                                      const InfoWindow(title: 'Vị trí của bạn'),
                                ),
                            },
                            polylines: _userLocation != null
                                ? {
                                    Polyline(
                                      polylineId:
                                          const PolylineId('route_preview'),
                                      points: [
                                        _userLocation!,
                                        LatLng(room.latitude!, room.longitude!),
                                      ],
                                      color: AppColors.primary,
                                      width: 4,
                                      patterns: [
                                        PatternItem.dash(10),
                                        PatternItem.gap(10)
                                      ], // Nét đứt sang trọng chuẩn Premium
                                    ),
                                  }
                                : {},
                          ),
                        ),
                        // Directions Button
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Material(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(20),
                            elevation: 4,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () async {
                                await _openGoogleMapsDirections(room);
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.directions,
                                        color: Colors.white, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Dẫn đường (Google Maps)',
                                      style: AppTypography.labelSM.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: AppSpacing.lg),

                  // Amenities
                  const Text(AppStrings.amenities,
                      style: AppTypography.titleSM),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children:
                        room.amenities.map((a) => _amenityChip(a)).toList(),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Description
                  const Text(AppStrings.description,
                      style: AppTypography.titleSM),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    room.description,
                    style: AppTypography.bodyMD,
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Landlord card
                  _buildLandlordCard(context, room),

                  const SizedBox(height: 100), // CTA space
                ],
              ),
            ),
          ),
        ],
      ),

      // ─── Bottom CTA ─────────────────────────────
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md + MediaQuery.of(context).padding.bottom,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          boxShadow: [AppShadows.bottomSheet],
        ),
        child: Row(
          children: [
            // Price summary
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Giá thuê', style: AppTypography.bodySM),
                  Text(
                    '${room.price.toVnd()}đ',
                    style: AppTypography.titleMD.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Nút Nhắn tin liên hệ
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline,
                  color: AppColors.primary),
              onPressed: () => context
                  .go('/tenant/room/${room.id}/contact/${room.landlordId}'),
            ),
            const SizedBox(width: AppSpacing.sm),
            // CTA Button - Đặt cọc
            Expanded(
              flex: 2,
              child: AppButton(
                text: room.status == RoomStatus.available
                    ? 'Đặt cọc giữ chỗ'
                    : 'Phòng đã cho thuê',
                onPressed: room.status == RoomStatus.available
                    ? () => _showBookingBottomSheet(context, room)
                    : null,
                icon: Icons.payments_outlined,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBookingBottomSheet(BuildContext context, Room room) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
      ),
      builder: (context) {
        return _BookingBottomSheet(room: room);
      },
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.onSurfaceVariant),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(text, style: AppTypography.bodyMD),
        ),
      ],
    );
  }

  Widget _amenityChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline,
              size: 14, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.labelSM.copyWith(
              color: AppColors.primary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLandlordCard(BuildContext context, Room room) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: const Icon(
              Icons.person_outline,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Chủ nhà', style: AppTypography.bodySM),
                Text('Xem thông tin liên hệ', style: AppTypography.titleSM),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.primary,
            ),
            onPressed: () => context
                .go('/tenant/room/${room.id}/contact/${room.landlordId}'),
          ),
        ],
      ),
    );
  }
}

class _BookingBottomSheet extends ConsumerStatefulWidget {
  final Room room;
  const _BookingBottomSheet({required this.room});

  @override
  ConsumerState<_BookingBottomSheet> createState() =>
      _BookingBottomSheetState();
}

class _BookingBottomSheetState extends ConsumerState<_BookingBottomSheet> {
  final int _depositAmount =
      500000; // Số tiền cọc giữ chỗ cố định (Holding Fee)
  DateTime _moveInDate = DateTime.now().add(const Duration(days: 3));

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: const BoxDecoration(
                color: AppColors.outlineVariant,
                borderRadius: BorderRadius.all(Radius.circular(2)),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Đặt cọc giữ chỗ phòng trọ',
            style: AppTypography.titleMD,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),

          // Alert Box giải thích cơ chế Escrow Platform bảo chứng an toàn
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2), width: 1),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.shield_outlined,
                  color: AppColors.primary,
                  size: 22,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bảo lãnh trung gian Escrow bởi Platform',
                        style: AppTypography.labelSM.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Số tiền cọc 500.000đ sẽ được khóa an toàn tại tài khoản trung gian của Platform. Bạn có quyền "Hủy cọc & Hoàn tiền 100%" bất cứ lúc nào trước khi ký hợp đồng chính thức nếu phòng không đúng thực tế!',
                        style: AppTypography.bodySM.copyWith(
                          fontSize: 10,
                          color: AppColors.onSurfaceVariant,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Giá thuê phòng:', style: AppTypography.bodyMD),
              Text(
                '${widget.room.price.toVnd()}đ/tháng',
                style: AppTypography.titleSM.copyWith(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Ngày hẹn xem phòng/dọn vào:',
                  style: AppTypography.bodyMD),
              TextButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _moveInDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                  );
                  if (picked != null) {
                    setState(() => _moveInDate = picked);
                  }
                },
                icon: const Icon(Icons.calendar_today_outlined, size: 16),
                label: Text(
                    '${_moveInDate.day}/${_moveInDate.month}/${_moveInDate.year}'),
              ),
            ],
          ),
          const Divider(height: AppSpacing.lg),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Phí đặt cọc giữ chỗ (Holding Fee):',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '${_depositAmount.toVnd()}đ',
                style: AppTypography.titleMD.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          AppButton(
            text: 'Tiến hành Thanh toán VietQR',
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.pop(context); // Đóng BottomSheet
              context.push(
                '/tenant/payment',
                extra: {
                  'room': widget.room,
                  'depositMonths': 1, // Đặt là 1 để tương thích Model ở DB
                  'amount': _depositAmount,
                  'moveInDate': _moveInDate,
                },
              );
            },
            icon: Icons.qr_code_scanner_outlined,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}
