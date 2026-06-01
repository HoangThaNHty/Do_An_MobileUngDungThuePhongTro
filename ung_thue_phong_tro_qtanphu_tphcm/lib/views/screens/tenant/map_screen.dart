import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../../../config/constants.dart';
import '../../../controllers/providers/room_provider.dart';
import '../../../controllers/booking_controller.dart';
import '../../../models/entities/room.dart';
import '../../../models/entities/rental.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  GoogleMapController? _mapController;
  final _searchCtrl = TextEditingController();
  final _pageController = PageController(viewportFraction: 0.88);
  
  LatLng? _currentLatLng;
  LatLng? _searchLatLng;
  Marker? _searchMarker;
  int _activePageIndex = 0;
  bool _isPageScrolling = false;
  bool _showRadiusSelector = false;
  bool _isMyRoomsMode = false; // false = Explore, true = My Rented Rooms

  // Radar Scan Animation States
  bool _isScanning = false;
  double _radarRadius = 10;
  Timer? _radarTimer;

  // Radius Filter (in meters). null means All
  double? _selectedRadius;
  static const List<double?> _radiusOptions = [null, 500, 1000, 2000, 5000];

  static const LatLng _tanPhuCenter = LatLng(10.7937, 106.6382); // Mặc định quận Tân Phú

  @override
  void initState() {
    super.initState();
    _initCurrentLocation();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _pageController.dispose();
    _radarTimer?.cancel();
    super.dispose();
  }

  Future<void> _initCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _setToTanPhuDefault();
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _setToTanPhuDefault();
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      _setToTanPhuDefault();
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      // Kiểm tra xem vị trí có nằm ngoài Việt Nam không (Đề phòng máy ảo GPS lỗi ở Mỹ)
      if (position.latitude < 8.0 || position.latitude > 24.0 ||
          position.longitude < 102.0 || position.longitude > 110.0) {
        if (!mounted) return;
        _setToTanPhuDefault();
        return;
      }

      if (!mounted) return;
      final myLocation = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentLatLng = myLocation;
      });
      _startRadarScan();
      _mapController?.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: myLocation, zoom: 14.5),
      ));
    } catch (_) {
      if (!mounted) return;
      _setToTanPhuDefault();
    }
  }

  void _setToTanPhuDefault() {
    if (!mounted) return;
    setState(() {
      _currentLatLng = _tanPhuCenter;
    });
    _startRadarScan();
    _mapController?.animateCamera(CameraUpdate.newCameraPosition(
      const CameraPosition(target: _tanPhuCenter, zoom: 14.5),
    ));
  }

  void _flyToCurrentLocation() {
    if (_currentLatLng != null) {
      _mapController?.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: _currentLatLng!, zoom: 15.5),
      ));
      _startRadarScan();
    } else {
      _initCurrentLocation();
    }
  }

  /// Kích hoạt hiệu ứng Radar Quét phòng trọ Công nghệ
  void _startRadarScan() {
    _radarTimer?.cancel();
    setState(() {
      _isScanning = true;
      _radarRadius = 10;
    });

    _radarTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      setState(() {
        _radarRadius += 35; // Lan tỏa bán kính
        if (_radarRadius > 1200) {
          _radarRadius = 10; // Reset
        }
      });
    });

    // Kết thúc radar sau 1.8 giây
    Future.delayed(const Duration(milliseconds: 1800), () {
      _radarTimer?.cancel();
      setState(() {
        _isScanning = false;
      });
    });
  }

  /// Tìm kiếm địa điểm thật qua Nominatim API
  Future<void> _searchLocation(String query) async {
    if (query.trim().isEmpty) return;

    try {
      // Gọi OpenStreetMap Nominatim API tìm vị trí (giới hạn trong TP.HCM để chính xác)
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent("$query, Hồ Chí Minh")}&format=json&limit=1');
      
      final response = await http.get(url, headers: {'User-Agent': 'RoomFinderApp'});
      if (response.statusCode == 200) {
        final List<dynamic> results = jsonDecode(response.body);
        if (results.isNotEmpty) {
          final lat = double.parse(results[0]['lat']);
          final lon = double.parse(results[0]['lon']);
          final displayAddress = results[0]['display_name'] as String;
          final searchPoint = LatLng(lat, lon);

          setState(() {
            _searchLatLng = searchPoint;
            _searchMarker = Marker(
              markerId: const MarkerId('search_pin'),
              position: searchPoint,
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
              infoWindow: InfoWindow(
                title: 'Kết quả tìm kiếm',
                snippet: displayAddress.split(',')[0],
              ),
            );
          });

          // Di chuyển camera và radar quét tại điểm mới tìm
          _mapController?.animateCamera(CameraUpdate.newCameraPosition(
            CameraPosition(target: searchPoint, zoom: 15),
          ));
          
          if (!mounted) return;
          FocusScope.of(context).unfocus();
        } else {
          _showErrorSnackBar('Không tìm thấy vị trí phù hợp');
        }
      } else {
        _showErrorSnackBar('Lỗi kết nối dịch vụ bản đồ');
      }
    } catch (e) {
      _showErrorSnackBar('Lỗi tìm kiếm: $e');
    }
  }

  void _showErrorSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.error,
      ),
    );
  }

  double _calculateDistance(LatLng start, LatLng end) {
    return Geolocator.distanceBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );
  }

  @override
  Widget build(BuildContext context) {
    final rawRooms = ref.watch(filteredRoomsProvider);
    final myRentalsAsync = ref.watch(tenantRentalsProvider);
    final myRentals = myRentalsAsync.value ?? [];
    final centerPoint = _searchLatLng ?? _currentLatLng ?? _tanPhuCenter;

    final List<Room> filteredRooms;

    if (_isMyRoomsMode) {
      final allRooms = ref.watch(roomProvider).rooms;
      final rentedRoomIds = myRentals.map((r) => r.roomId).toSet();
      filteredRooms = allRooms.where((r) => rentedRoomIds.contains(r.id)).toList();
    } else {
      // 1. Lọc danh sách phòng theo bán kính (Radius) nếu được chọn
      filteredRooms = rawRooms.where((room) {
        if (room.latitude == null || room.longitude == null) return false;
        if (_selectedRadius == null) return true; // Tất cả
        
        final distance = _calculateDistance(
          centerPoint,
          LatLng(room.latitude!, room.longitude!),
        );
        return distance <= _selectedRadius!;
      }).toList();
    }

    // 2. Xây dựng Markers từ phòng đã lọc
    final markers = <Marker>{};
    
    // Ghim vị trí tìm kiếm
    if (_searchMarker != null) {
      markers.add(_searchMarker!);
    }

    // Ghim vị trí GPS hiện tại của người dùng bằng chấm đỏ nổi bật
    if (_currentLatLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('user_current_gps'),
          position: _currentLatLng!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(
            title: 'Vị trí của bạn',
          ),
        ),
      );
    }

    for (int i = 0; i < filteredRooms.length; i++) {
      final room = filteredRooms[i];
      
      // Phân loại Marker theo trạng thái hoặc Giá phòng trọ
      double hue = BitmapDescriptor.hueGreen; // Dưới 3.5Tr: Xanh lá
      String snippet = '${room.price.toVnd()}đ/tháng';

      if (_isMyRoomsMode) {
        hue = BitmapDescriptor.hueCyan; // Màu Cyan đặc trưng đại diện cho Phòng của bạn
        final rental = myRentals.firstWhere((r) => r.roomId == room.id, orElse: () => myRentals.first);
        final statusStr = rental.status == RentalStatus.pending ? 'Đang cọc giữ chỗ' : 'Đang thuê';
        snippet = '$statusStr - ${room.price.toVnd()}đ/tháng';
      } else {
        if (room.price >= 3500000 && room.price <= 5000000) {
          hue = BitmapDescriptor.hueBlue; // 3.5Tr - 5Tr: Xanh dương
        } else if (room.price > 5000000) {
          hue = BitmapDescriptor.hueOrange; // Trên 5Tr: Cam
        }
      }

      markers.add(
        Marker(
          markerId: MarkerId(room.id),
          position: LatLng(room.latitude!, room.longitude!),
          icon: BitmapDescriptor.defaultMarkerWithHue(hue),
          infoWindow: InfoWindow(
            title: room.title,
            snippet: snippet,
          ),
          onTap: () {
            // Khi nhấn Marker, cuộn Carousel ngang đến phòng tương ứng
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
    final selectedRoom = filteredRooms.isNotEmpty && _activePageIndex < filteredRooms.length
        ? filteredRooms[_activePageIndex]
        : null;

    final polylines = <Polyline>{};
    if (_currentLatLng != null && selectedRoom != null && selectedRoom.latitude != null && selectedRoom.longitude != null) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('route_to_selected_room'),
          points: [
            _currentLatLng!,
            LatLng(selectedRoom.latitude!, selectedRoom.longitude!),
          ],
          color: AppColors.primary,
          width: 4,
          patterns: [
            PatternItem.dash(15),
            PatternItem.gap(10),
          ],
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // ─── Google Map ───────────────────────────
          GoogleMap(
            onMapCreated: (ctrl) {
              _mapController = ctrl;
            },
            initialCameraPosition: CameraPosition(
              target: centerPoint,
              zoom: 14.5,
            ),
            markers: markers,
            polylines: polylines,
            circles: _isScanning
                ? {
                    Circle(
                      circleId: const CircleId('radar_scan'),
                      center: centerPoint,
                      radius: _radarRadius,
                      fillColor: AppColors.primary.withValues(alpha: 0.12),
                      strokeColor: AppColors.primary.withValues(alpha: 0.35),
                      strokeWidth: 2,
                    ),
                  }
                : _selectedRadius != null
                    ? {
                        Circle(
                          circleId: const CircleId('radius_filter'),
                          center: centerPoint,
                          radius: _selectedRadius!,
                          fillColor: AppColors.primary.withValues(alpha: 0.06),
                          strokeColor: AppColors.primary.withValues(alpha: 0.22),
                          strokeWidth: 1,
                        )
                      }
                    : {},
            myLocationEnabled: true,
            myLocationButtonEnabled: false, // Dùng nút custom đẹp hơn
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),

          // ─── Top Floating Search Bar ──────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      // Back Button
                      GestureDetector(
                        onTap: () => context.go('/tenant'),
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: const BoxDecoration(
                            color: AppColors.surfaceContainerLowest,
                            shape: BoxShape.circle,
                            boxShadow: [AppShadows.card],
                          ),
                          child: const Icon(Icons.arrow_back, size: 20),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      // Search TextField
                      Expanded(
                        child: Container(
                          height: 46,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: const [AppShadows.card],
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: AppSpacing.md),
                              const Icon(Icons.search, size: 18, color: AppColors.onSurfaceVariant),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _searchCtrl,
                                  textInputAction: TextInputAction.search,
                                  onSubmitted: _searchLocation,
                                  decoration: const InputDecoration(
                                    hintText: 'Nhập địa điểm tìm kiếm...',
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                                  ),
                                  style: AppTypography.bodyMD,
                                ),
                              ),
                              if (_searchCtrl.text.isNotEmpty)
                                IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    setState(() {
                                      _searchCtrl.clear();
                                      _searchLatLng = null;
                                      _searchMarker = null;
                                    });
                                    _startRadarScan();
                                  },
                                ),
                              IconButton(
                                icon: Icon(
                                  Icons.radar_outlined,
                                  size: 20,
                                  color: _showRadiusSelector ? AppColors.primary : AppColors.onSurfaceVariant,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _showRadiusSelector = !_showRadiusSelector;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // Segmented Tab for Map Mode (Explore vs My Rooms)
                  Container(
                    height: 40,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [AppShadows.card],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _isMyRoomsMode = false;
                              });
                              _startRadarScan();
                              // Tự động di chuyển camera về vị trí tâm điểm tìm kiếm hoặc GPS
                              final targetLoc = _searchLatLng ?? _currentLatLng ?? _tanPhuCenter;
                              _mapController?.animateCamera(CameraUpdate.newCameraPosition(
                                CameraPosition(target: targetLoc, zoom: 14.5),
                              ));
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: !_isMyRoomsMode ? AppColors.primary : Colors.transparent,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.explore_outlined,
                                    size: 16,
                                    color: !_isMyRoomsMode ? Colors.white : AppColors.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Khám phá',
                                    style: AppTypography.labelSM.copyWith(
                                      color: !_isMyRoomsMode ? Colors.white : AppColors.onSurfaceVariant,
                                      fontWeight: !_isMyRoomsMode ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _isMyRoomsMode = true;
                              });
                              _startRadarScan();
                              // Tự động di chuyển camera đến phòng đã thuê/cọc đầu tiên của Tenant nếu có
                              final allRooms = ref.read(roomProvider).rooms;
                              final rentedRoomIds = myRentals.map((r) => r.roomId).toSet();
                              final myRentedRooms = allRooms.where((r) => rentedRoomIds.contains(r.id)).toList();
                              if (myRentedRooms.isNotEmpty) {
                                final firstRoom = myRentedRooms.first;
                                if (firstRoom.latitude != null && firstRoom.longitude != null) {
                                  _mapController?.animateCamera(CameraUpdate.newCameraPosition(
                                    CameraPosition(
                                      target: LatLng(firstRoom.latitude!, firstRoom.longitude!),
                                      zoom: 15.0,
                                    ),
                                  ));
                                }
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: _isMyRoomsMode ? AppColors.primary : Colors.transparent,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.home_work_outlined,
                                    size: 16,
                                    color: _isMyRoomsMode ? Colors.white : AppColors.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Phòng của tôi',
                                    style: AppTypography.labelSM.copyWith(
                                      color: _isMyRoomsMode ? Colors.white : AppColors.onSurfaceVariant,
                                      fontWeight: _isMyRoomsMode ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // ─── Radius Filter Selector ───────────
                  if (_showRadiusSelector) ...[
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      height: 34,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _radiusOptions.length,
                        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xs),
                        itemBuilder: (context, index) {
                          final radius = _radiusOptions[index];
                          final isSelected = _selectedRadius == radius;
                          final label = radius == null
                              ? 'Tất cả'
                              : radius >= 1000
                                  ? 'Trong bán kính ${(radius / 1000).toStringAsFixed(0)}km'
                                  : 'Trong bán kính ${radius.toStringAsFixed(0)}m';

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedRadius = radius;
                              });
                              _startRadarScan();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: isSelected ? AppGradients.primaryButton : null,
                                color: isSelected ? null : AppColors.surfaceContainerLowest,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: const [AppShadows.card],
                                border: Border.all(
                                  color: isSelected ? Colors.transparent : AppColors.outlineVariant.withValues(alpha: 0.5),
                                ),
                              ),
                              child: Text(
                                label,
                                style: AppTypography.labelSM.copyWith(
                                  color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ─── Floating Control Buttons ─────────────
          Positioned(
            right: AppSpacing.md,
            bottom: filteredRooms.isNotEmpty ? 226 : 100, // Nhảy lên tránh che Carousel
            child: Column(
              children: [
                // Radar Scan Button
                GestureDetector(
                  onTap: _startRadarScan,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [AppShadows.fab],
                    ),
                    child: const Icon(Icons.radar, color: Colors.white, size: 22),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                // Current Location Button (Tâm ngắm xanh bay mượt camera)
                GestureDetector(
                  onTap: _flyToCurrentLocation,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      shape: BoxShape.circle,
                      boxShadow: [AppShadows.fab],
                    ),
                    child: const Icon(Icons.gps_fixed, color: AppColors.primary, size: 22),
                  ),
                ),
              ],
            ),
          ),

          // ─── Airbnb-like Room Carousel ────────────
          if (filteredRooms.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: 8,
              child: SizedBox(
                height: 124,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: filteredRooms.length,
                  onPageChanged: (index) {
                    if (_isPageScrolling) return;
                    setState(() {
                      _activePageIndex = index;
                    });
                    
                    // Di chuyển bản đồ đến phòng trọ tương ứng khi vuốt Carousel
                    final room = filteredRooms[index];
                    if (room.latitude != null && room.longitude != null) {
                      _mapController?.animateCamera(CameraUpdate.newLatLng(
                        LatLng(room.latitude!, room.longitude!),
                      ));
                    }
                  },
                  itemBuilder: (context, index) {
                    final room = filteredRooms[index];
                    Rental? rental;
                    try {
                      rental = myRentals.firstWhere((r) => r.roomId == room.id);
                    } catch (_) {
                      rental = null;
                    }
                    return _buildCarouselCard(context, room, index == _activePageIndex, rental: rental);
                  },
                ),
              ),
            ),

          // No rooms fallback on Map
          if (filteredRooms.isEmpty)
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
                        'Không có phòng nào trong khu vực này.',
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

  Widget _buildCarouselCard(BuildContext context, Room room, bool isActive, {Rental? rental}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: isActive
              ? (rental != null ? const Color(0xFF00ACC1) : AppColors.primary)
              : Colors.transparent,
          width: 2,
        ),
        boxShadow: const [AppShadows.bottomSheet],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.card - 2),
        child: GestureDetector(
          onTap: () => context.push('/tenant/room/${room.id}'),
          child: Row(
            children: [
              // Room Image
              Container(
                width: 110,
                height: double.infinity,
                color: AppColors.surfaceContainerLow,
                child: room.images.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: room.images.first,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: AppColors.surfaceContainerLow,
                        ),
                        errorWidget: (_, __, ___) => const Icon(
                          Icons.home_outlined,
                          size: 36,
                          color: AppColors.onSurfaceVariant,
                        ),
                      )
                    : const Icon(
                        Icons.home_outlined,
                        size: 36,
                        color: AppColors.onSurfaceVariant,
                      ),
              ),
              // Room Details
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
                          Text(
                            room.title,
                            style: AppTypography.titleSM.copyWith(fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          if (rental != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: rental.status == RentalStatus.pending
                                    ? const Color(0xFFE0F7FA)
                                    : const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                rental.status == RentalStatus.pending ? 'Đã đặt cọc giữ chỗ' : 'Đang thuê hợp đồng',
                                style: AppTypography.labelSM.copyWith(
                                  fontSize: 10,
                                  color: rental.status == RentalStatus.pending
                                      ? const Color(0xFF00838F)
                                      : const Color(0xFF2E7D32),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          else
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined, size: 12, color: AppColors.onSurfaceVariant),
                                const SizedBox(width: 2),
                                Expanded(
                                  child: Text(
                                    room.address,
                                    style: AppTypography.bodySM.copyWith(fontSize: 11),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            rental != null
                                ? (rental.status == RentalStatus.pending ? 'Cọc: 500K' : '${room.price.toVnd()}đ')
                                : '${room.price.toVnd()}đ',
                            style: AppTypography.bodyMD.copyWith(
                              color: rental != null
                                  ? (rental.status == RentalStatus.pending ? const Color(0xFF00838F) : AppColors.primary)
                                  : AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              if (rental != null) {
                                context.push('/tenant/rentals');
                              } else {
                                context.push('/tenant/room/${room.id}');
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: rental != null
                                    ? const LinearGradient(colors: [Color(0xFF0097A7), Color(0xFF00E5FF)])
                                    : AppGradients.primaryButton,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                rental != null ? 'Hợp đồng' : 'Chi tiết',
                                style: AppTypography.labelSM.copyWith(color: Colors.white, fontSize: 10),
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
      ),
    );
  }
}
