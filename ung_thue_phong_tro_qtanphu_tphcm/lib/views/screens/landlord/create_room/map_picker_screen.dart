import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../../../../config/constants.dart';

class MapPickerScreen extends ConsumerStatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const MapPickerScreen({
    super.key,
    this.initialLat,
    this.initialLng,
  });

  @override
  ConsumerState<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends ConsumerState<MapPickerScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  
  // Mặc định ban đầu tại trung tâm Quận Tân Phú, TP.HCM
  static const CameraPosition _defaultPos = CameraPosition(
    target: LatLng(10.7936, 106.6385),
    zoom: 14.5,
  );

  LatLng? _selectedLocation;
  String _selectedAddress = '';
  bool _isLoadingLocation = false;
  bool _isGeocoding = false;

  // Tìm kiếm địa điểm
  final TextEditingController _searchCtrl = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLng != null) {
      _selectedLocation = LatLng(widget.initialLat!, widget.initialLng!);
      _reverseGeocode(_selectedLocation!);
    }
    _checkPermissionAndGetLocation();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  /// Lấy vị trí GPS hiện tại của người dùng
  Future<void> _checkPermissionAndGetLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    
    if (permission == LocationPermission.deniedForever) return;

    if (widget.initialLat == null && widget.initialLng == null) {
      setState(() => _isLoadingLocation = true);
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        
        LatLng myLocation = LatLng(position.latitude, position.longitude);
        
        // KIỂM TRA: Nếu GPS trả về nằm ngoài lãnh thổ Việt Nam (VD: tọa độ mặc định của máy ảo Android bên Mỹ: 37.4220, -122.0840)
        // Ta sẽ tự động đưa tâm bản đồ về Quận Tân Phú, TP.HCM để dễ sử dụng.
        if (myLocation.latitude > 11.5 || myLocation.latitude < 8.0 || 
            myLocation.longitude > 109.5 || myLocation.longitude < 102.0) {
          myLocation = const LatLng(10.7936, 106.6385);
        }
        
        setState(() {
          _selectedLocation = myLocation;
          _isLoadingLocation = false;
        });
        
        // Dịch tọa độ GPS hiện tại thành địa chỉ chữ
        _reverseGeocode(myLocation);
        
        final GoogleMapController controller = await _controller.future;
        controller.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(target: myLocation, zoom: 16),
        ));
      } catch (e) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  /// Tìm kiếm địa điểm bằng API Nominatim của OpenStreetMap (Miễn phí)
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      if (query.trim().isNotEmpty) {
        _searchPlaces(query.trim());
      } else {
        setState(() {
          _searchResults = [];
        });
      }
    });
  }

  Future<void> _searchPlaces(String query) async {
    setState(() => _isSearching = true);
    try {
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=5&countrycodes=vn&accept-language=vi');
      
      final response = await http.get(url, headers: {
        'User-Agent': 'DoAnNhomDomChua_UngThuePhongTro/1.0',
      });
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        setState(() {
          _searchResults = data;
        });
      }
    } catch (e) {
      debugPrint('Lỗi tìm kiếm địa điểm: $e');
    } finally {
      setState(() => _isSearching = false);
    }
  }

  /// Dịch tọa độ LatLng thành địa chỉ chi tiết (Reverse Geocoding)
  Future<void> _reverseGeocode(LatLng latLng) async {
    setState(() => _isGeocoding = true);
    try {
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?lat=${latLng.latitude}&lon=${latLng.longitude}&format=json&accept-language=vi');
      
      final response = await http.get(url, headers: {
        'User-Agent': 'DoAnNhomDomChua_UngThuePhongTro/1.0',
      });
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String address = data['display_name'] ?? '';
        
        // Làm sạch địa chỉ, cắt bỏ các thông tin thừa của OSM
        address = address
            .replaceAll(', Việt Nam', '')
            .replaceAll(', 700000', '')
            .replaceAll(', 70000', '');
            
        setState(() {
          _selectedAddress = address;
        });
      }
    } catch (e) {
      debugPrint('Lỗi Reverse Geocode: $e');
    } finally {
      setState(() => _isGeocoding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chọn vị trí phòng'),
        actions: [
          if (_selectedLocation != null)
            TextButton(
              onPressed: _isGeocoding
                  ? null
                  : () {
                      // Trả về cả tọa độ lẫn chuỗi địa chỉ dịch ngược
                      Navigator.of(context).pop({
                        'location': _selectedLocation,
                        'address': _selectedAddress,
                      });
                    },
              child: _isGeocoding
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    )
                  : const Text('Xong', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
        ],
      ),
      body: Stack(
        children: [
          // BẢN ĐỒ GOOGLE MAPS
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: widget.initialLat != null && widget.initialLng != null
                ? CameraPosition(
                    target: LatLng(widget.initialLat!, widget.initialLng!),
                    zoom: 16,
                  )
                : _defaultPos,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
            onTap: (LatLng location) {
              setState(() {
                _selectedLocation = location;
                _searchResults = []; // Đóng gợi ý tìm kiếm
              });
              _reverseGeocode(location);
            },
            markers: _selectedLocation == null
                ? {}
                : {
                    Marker(
                      markerId: const MarkerId('selected'),
                      position: _selectedLocation!,
                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                      infoWindow: InfoWindow(
                        title: 'Vị trí phòng trọ',
                        snippet: _selectedAddress.isNotEmpty ? _selectedAddress : 'Đang dịch địa chỉ...',
                      ),
                    ),
                  },
          ),

          // THANH TÌM KIẾM ĐỊA CHỈ (PLACES SEARCH)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    boxShadow: const [AppShadows.card],
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Nhập địa điểm để tìm nhanh...',
                      prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() {
                                  _searchResults = [];
                                });
                              },
                            )
                          : (_isSearching
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                )
                              : null),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onChanged: _onSearchChanged,
                  ),
                ),
              ],
            ),
          ),

          // OVERLAY HIỂN THỊ GỢI Ý TÌM KIẾM
          if (_searchResults.isNotEmpty)
            Positioned(
              top: 72,
              left: 16,
              right: 16,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 250),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  boxShadow: const [AppShadows.card],
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final item = _searchResults[index];
                    String displayName = item['display_name'] ?? '';
                    displayName = displayName
                        .replaceAll(', Việt Nam', '')
                        .replaceAll(', 700000', '')
                        .replaceAll(', 70000', '');

                    return ListTile(
                      leading: const Icon(Icons.location_on, color: AppColors.primary),
                      title: Text(
                        displayName,
                        style: AppTypography.bodyMD,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () async {
                        final lat = double.parse(item['lat']);
                        final lon = double.parse(item['lon']);
                        final location = LatLng(lat, lon);

                        setState(() {
                          _selectedLocation = location;
                          _selectedAddress = displayName;
                          _searchResults = [];
                          _searchCtrl.text = displayName;
                        });

                        final GoogleMapController controller = await _controller.future;
                        controller.animateCamera(CameraUpdate.newCameraPosition(
                          CameraPosition(target: location, zoom: 16),
                        ));
                      },
                    );
                  },
                ),
              ),
            ),

          // KHUNG THÔNG TIN ĐỊA CHỈ ĐANG CHỌN (DƯỚI CÙNG)
          if (_selectedLocation != null)
            Positioned(
              bottom: 24,
              left: 16,
              right: 76, // Để chừa chỗ cho nút My Location mặc định của Google Maps
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  boxShadow: const [AppShadows.card],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: AppColors.available, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'Vị trí đã chọn',
                          style: AppTypography.labelSM.copyWith(color: AppColors.available, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isGeocoding ? 'Đang xác định địa chỉ...' : _selectedAddress,
                      style: AppTypography.bodyMD.copyWith(color: AppColors.onSurface),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),

          // HIỂN THỊ ĐANG LOAD VỊ TRÍ GPS BAN ĐẦU
          if (_isLoadingLocation)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
