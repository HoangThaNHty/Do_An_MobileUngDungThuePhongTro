import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
  RangeValues _priceRange = const RangeValues(1000000, 15000000);
  double _minArea = 0;
  String? _selectedStatus;
  String? _selectedDistrict;
  final List<String> _selectedAmenities = [];

  static const List<String> _amenityOptions = [
    'Điều hòa', 'Nóng lạnh', 'Tủ lạnh',
    'WiFi', 'Máy giặt', 'Ban công', 'Bếp', 'Tivi',
  ];
  static const List<String> _statusOptions = [
    'Tất cả', 'CÒN TRỐNG', 'ĐÃ THUÊ',
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _applyFilter() {
    final notifier = ref.read(roomProvider.notifier);
    notifier.search(_searchCtrl.text);
    notifier.applyFilter(RoomFilter(
      district: _selectedDistrict,
      minPrice: _priceRange.start.toInt(),
      maxPrice: _priceRange.end.toInt(),
      minArea: _minArea,
      status: _selectedStatus == null || _selectedStatus == 'Tất cả'
          ? null
          : _selectedStatus == 'CÒN TRỐNG'
              ? RoomStatus.available
              : RoomStatus.rented,
      amenities: _selectedAmenities,
    ));
    context.go('/tenant');
  }

  void _clearFilter() {
    setState(() {
      _searchCtrl.clear();
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

    return Scaffold(
      backgroundColor: AppColors.surface,
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
              controller: _searchCtrl,
              decoration: const InputDecoration(
                labelText: 'Từ khóa tìm kiếm',
                prefixIcon: Icon(Icons.search_outlined, size: 20),
                hintText: 'Tên phòng, địa chỉ...',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Khoảng giá
            Text('Khoảng giá thuê', style: AppTypography.titleSM),
            const SizedBox(height: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
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
                            .copyWith(color: AppColors.primary),
                      ),
                      Text(
                        '${_formatM(_priceRange.end.toInt())}tr',
                        style: AppTypography.titleSM
                            .copyWith(color: AppColors.primary),
                      ),
                    ],
                  ),
                  RangeSlider(
                    values: _priceRange,
                    min: 500000,
                    max: 20000000,
                    divisions: 39,
                    activeColor: AppColors.primary,
                    inactiveColor: AppColors.surfaceContainerHigh,
                    onChanged: (v) => setState(() => _priceRange = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Quận
            Text('Khu vực', style: AppTypography.titleSM),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: districts.map((d) {
                final isSelected = _selectedDistrict == d ||
                    (d == 'Tất cả' && _selectedDistrict == null);
                return GestureDetector(
                  onTap: () => setState(() => _selectedDistrict =
                      d == 'Tất cả' ? null : d),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: isSelected ? AppGradients.primaryButton : null,
                      color: isSelected ? null : AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                    ),
                    child: Text(
                      d,
                      style: AppTypography.labelSM.copyWith(
                        color: isSelected
                            ? AppColors.onPrimary
                            : AppColors.onSurfaceVariant,
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
              activeColor: AppColors.primary,
              inactiveColor: AppColors.surfaceContainerHigh,
              label: '${_minArea.toInt()} m²',
              onChanged: (v) => setState(() => _minArea = v),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Tiện nghi
            Text('Tiện nghi', style: AppTypography.titleSM),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: _amenityOptions.map((a) {
                final isSelected = _selectedAmenities.contains(a);
                return GestureDetector(
                  onTap: () => setState(() {
                    isSelected
                        ? _selectedAmenities.remove(a)
                        : _selectedAmenities.add(a);
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.12)
                          : AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected) ...[
                          const Icon(Icons.check,
                              size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          a,
                          style: AppTypography.labelSM.copyWith(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.onSurfaceVariant,
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
