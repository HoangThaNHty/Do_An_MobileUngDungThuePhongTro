import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/app_palette.dart';
import '../../../config/constants.dart';
import '../../../controllers/providers/room_provider.dart';
import '../../../models/entities/room.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchCtrl = TextEditingController();
  List<Room> _suggestions = [];
  RangeValues _priceRange = const RangeValues(1000000, 15000000);
  double _minArea = 0;
  String? _selectedStatus;
  String? _selectedDistrict;
  final List<String> _selectedAmenities = [];

  static const List<String> _amenityOptions = [
    'Điều hòa',
    'Nóng lạnh',
    'Tủ lạnh',
    'WiFi',
    'Máy giặt',
    'Ban công',
    'Bếp',
    'Tivi',
  ];

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (normalizeRoomSearchText(_searchCtrl.text).isEmpty) {
      if (mounted) setState(() => _suggestions = []);
      return;
    }
    final rooms = ref.read(roomProvider).rooms;
    final filtered = rooms.where((room) {
      return room.status == RoomStatus.available &&
          roomMatchesTextQuery(room, _searchCtrl.text);
    }).toList();
    if (mounted) {
      setState(() {
        _suggestions = filtered;
      });
    }
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _applyFilter() {
    final notifier = ref.read(roomProvider.notifier);
    final normalizedStatus = normalizeRoomSearchText(_selectedStatus ?? '');
    notifier.search(_searchCtrl.text);
    notifier.applyFilter(RoomFilter(
      district: _selectedDistrict,
      minPrice: _priceRange.start.toInt(),
      maxPrice: _priceRange.end.toInt(),
      minArea: _minArea,
      status: _selectedStatus == null || _selectedStatus == 'Tất cả'
          ? null
          : normalizedStatus == normalizeRoomSearchText('CÒN TRỐNG')
              ? RoomStatus.available
              : RoomStatus.rented,
      amenities: _selectedAmenities,
    ));
    context.go('/tenant');
  }

  void _clearFilter() {
    setState(() {
      _searchCtrl.clear();
      _suggestions.clear();
      _priceRange = const RangeValues(1000000, 15000000);
      _minArea = 0;
      _selectedStatus = null;
      _selectedDistrict = null;
      _selectedAmenities.clear();
    });
    ref.read(roomProvider.notifier).clearFilter();
    ref.read(roomProvider.notifier).search('');
  }

  @override
  Widget build(BuildContext context) {
    final districts = ref.watch(districtsProvider);
    final palette = context.palette;

    return Scaffold(
      backgroundColor: palette.surface,
      appBar: AppBar(
        title: const Text('Tìm kiếm nâng cao'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/tenant'),
        ),
        actions: [
          TextButton(
            onPressed: _clearFilter,
            child: const Text('Xóa bộ lọc'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar
            TextFormField(
              key: const ValueKey('search_screen_text_input_field'),
              controller: _searchCtrl,
              decoration: const InputDecoration(
                labelText: 'Từ khóa tìm kiếm',
                prefixIcon: Icon(Icons.search_outlined, size: 20),
                hintText: 'Tên phòng, địa chỉ...',
              ),
            ),
            if (_suggestions.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                constraints: const BoxConstraints(maxHeight: 250),
                decoration: BoxDecoration(
                  color: palette.surfaceLowest,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(
                      color: palette.outlineVariant.withValues(alpha: 0.3)),
                  boxShadow: const [AppShadows.card],
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  itemCount: _suggestions.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final room = _suggestions[index];
                    return ListTile(
                      dense: true,
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: room.images.isNotEmpty
                            ? Image.network(
                                room.images.first,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 40,
                                height: 40,
                                color: palette.surfaceLow,
                                child:
                                    const Icon(Icons.home_outlined, size: 20),
                              ),
                      ),
                      title: Text(
                        room.title,
                        style: AppTypography.titleSM.copyWith(fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${room.price.toVnd()}đ - ${room.address}',
                        style: AppTypography.bodySM.copyWith(fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 12),
                      onTap: () {
                        context.push('/tenant/room/${room.id}');
                      },
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),

            // Khoảng giá
            const Text('Khoảng giá thuê', style: AppTypography.titleSM),
            const SizedBox(height: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: palette.surfaceLowest,
                borderRadius: BorderRadius.circular(AppRadius.card),
                boxShadow: const [AppShadows.card],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_formatM(_priceRange.start.toInt())}tr',
                        style: AppTypography.titleSM
                            .copyWith(color: palette.primary),
                      ),
                      Text(
                        '${_formatM(_priceRange.end.toInt())}tr',
                        style: AppTypography.titleSM
                            .copyWith(color: palette.primary),
                      ),
                    ],
                  ),
                  RangeSlider(
                    values: _priceRange,
                    min: 500000,
                    max: 20000000,
                    divisions: 39,
                    activeColor: palette.primary,
                    inactiveColor: palette.surfaceHigh,
                    onChanged: (v) => setState(() => _priceRange = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Quận
            const Text('Khu vực', style: AppTypography.titleSM),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: districts.map((d) {
                final isSelected = _selectedDistrict == d ||
                    (d == 'Tất cả' && _selectedDistrict == null);
                return GestureDetector(
                  onTap: () => setState(
                      () => _selectedDistrict = d == 'Tất cả' ? null : d),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: isSelected ? AppGradients.primaryButton : null,
                      color: isSelected ? null : palette.surfaceLow,
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                    ),
                    child: Text(
                      d,
                      style: AppTypography.labelSM.copyWith(
                        color: isSelected
                            ? AppColors.onPrimary
                            : palette.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Diện tích tối thiểu
            Text('Diện tích tối thiểu: ${_minArea.toInt()} m²',
                style: AppTypography.titleSM),
            Slider(
              value: _minArea,
              min: 0,
              max: 80,
              divisions: 16,
              activeColor: palette.primary,
              inactiveColor: palette.surfaceHigh,
              label: '${_minArea.toInt()} m²',
              onChanged: (v) => setState(() => _minArea = v),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Tiện nghi
            const Text('Tiện nghi', style: AppTypography.titleSM),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: _amenityOptions.map((a) {
                final normalizedAmenity = normalizeRoomSearchText(a);
                final isSelected = _selectedAmenities.any(
                  (selected) =>
                      normalizeRoomSearchText(selected) == normalizedAmenity,
                );
                return GestureDetector(
                  onTap: () => setState(() {
                    if (isSelected) {
                      _selectedAmenities.removeWhere(
                        (selected) =>
                            normalizeRoomSearchText(selected) ==
                            normalizedAmenity,
                      );
                    } else {
                      _selectedAmenities.add(a);
                    }
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? palette.primary.withValues(alpha: 0.12)
                          : palette.surfaceLow,
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                      border: Border.all(
                        color:
                            isSelected ? palette.primary : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected) ...[
                          Icon(Icons.check, size: 14, color: palette.primary),
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
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Apply button
            Container(
              decoration: BoxDecoration(
                gradient: AppGradients.primaryButton,
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _applyFilter,
                  borderRadius: BorderRadius.circular(AppRadius.button),
                  child: Container(
                    height: AppSpacing.buttonHeight,
                    alignment: Alignment.center,
                    child: const Text(
                      'Áp dụng bộ lọc',
                      style: AppTypography.button,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  String _formatM(int amount) {
    return (amount / 1000000).toStringAsFixed(1);
  }
}
