import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/app_palette.dart';
import '../../../../config/constants.dart';
import '../../../../controllers/providers/create_room_provider.dart';
import '../../../widgets/common/app_button.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'map_picker_screen.dart';

class Step1Screen extends ConsumerStatefulWidget {
  const Step1Screen({super.key});

  @override
  ConsumerState<Step1Screen> createState() => _Step1ScreenState();
}

class _Step1ScreenState extends ConsumerState<Step1Screen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _areaCtrl;
  late TextEditingController _descCtrl;
  String _district = 'Tân Phú';

  static const List<String> _districts = [
    'Tân Phú',
    'Tân Bình',
    'Bình Thạnh',
    'Phú Nhuận',
    'Gò Vấp',
    'Quận 1',
    'Quận 3',
    'Quận 5',
    'Quận 7',
    'Bình Chánh',
    'Hóc Môn',
    'Củ Chi',
  ];

  static const List<int> _depositOptions = [1, 2, 3];
  int _depositMonths = 2;

  @override
  void initState() {
    super.initState();
    final state = ref.read(createRoomProvider);
    _titleCtrl = TextEditingController(text: state.title);
    _addressCtrl = TextEditingController(text: state.address);
    _priceCtrl = TextEditingController(
        text: state.price > 0 ? state.price.toString() : '');
    _areaCtrl = TextEditingController(
        text: state.area > 0 ? state.area.toStringAsFixed(0) : '');
    _descCtrl = TextEditingController(text: state.description);
    _district =
        _districts.contains(state.district) ? state.district : _districts.first;
    _depositMonths = state.depositMonths;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _addressCtrl.dispose();
    _priceCtrl.dispose();
    _areaCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (!_formKey.currentState!.validate()) return;

    final state = ref.read(createRoomProvider);
    if (!state.isLocationValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Vui lòng chọn vị trí trên bản đồ!'),
          backgroundColor: context.palette.danger,
        ),
      );
      return;
    }

    ref.read(createRoomProvider.notifier).updateBasicInfo(
          title: _titleCtrl.text.trim(),
          address: _addressCtrl.text.trim(),
          district: _district,
          area: double.tryParse(_areaCtrl.text) ?? 20,
          price: int.tryParse(_priceCtrl.text.replaceAll('.', '')) ?? 0,
          depositMonths: _depositMonths,
          description: _descCtrl.text.trim(),
        );
    context.go('/landlord/create-room/step2');
  }

  Future<void> _pickLocation() async {
    final state = ref.read(createRoomProvider);
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (context) => MapPickerScreen(
          initialLat: state.latitude,
          initialLng: state.longitude,
        ),
      ),
    );

    if (result != null) {
      final LatLng location = result['location'] as LatLng;
      final String address = result['address'] as String;

      ref
          .read(createRoomProvider.notifier)
          .updateLocation(location.latitude, location.longitude);

      // Tự động điền địa chỉ chi tiết nhận được từ Bản đồ vào ô nhập liệu
      setState(() {
        _addressCtrl.text = address;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createRoomProvider);
    final hasLocation = state.isLocationValid;
    final palette = context.palette;

    return Scaffold(
      backgroundColor: palette.surface,
      appBar: AppBar(
        title: Text(state.isEditing ? 'Chỉnh sửa phòng' : 'Thêm phòng'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            ref.read(createRoomProvider.notifier).reset();
            context.go('/landlord');
          },
        ),
      ),
      body: Column(
        children: [
          // Progress indicator
          _buildProgress(1),
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _sectionTitle('Bước 1: Thông tin cơ bản'),
                    const SizedBox(height: AppSpacing.md),

                    // Title
                    TextFormField(
                      controller: _titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Tên phòng *',
                        prefixIcon: Icon(Icons.meeting_room_outlined, size: 20),
                        hintText: 'VD: Phòng 101 - Master',
                      ),
                      validator: (v) => v == null || v.isEmpty
                          ? 'Vui lòng nhập tên phòng'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // District dropdown
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: palette.surfaceLow,
                        borderRadius: BorderRadius.circular(AppRadius.input),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _district,
                          isExpanded: true,
                          items: _districts
                              .map((d) =>
                                  DropdownMenuItem(value: d, child: Text(d)))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _district = v ?? _district),
                          style: AppTypography.bodyMD
                              .copyWith(color: palette.onSurface),
                          dropdownColor: palette.surfaceLowest,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Address
                    TextFormField(
                      controller: _addressCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Địa chỉ chi tiết *',
                        prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                        hintText: 'Số nhà, đường, phường...',
                      ),
                      validator: (v) => v == null || v.isEmpty
                          ? 'Vui lòng nhập địa chỉ'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Price + Area row
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _priceCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Giá thuê/tháng *',
                              suffixText: 'đ',
                              prefixIcon:
                                  Icon(Icons.payments_outlined, size: 20),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Nhập giá';
                              final p = int.tryParse(v.replaceAll('.', ''));
                              if (p == null || p < 500000) {
                                return 'Tối thiểu 500.000đ';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: TextFormField(
                            controller: _areaCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Diện tích *',
                              suffixText: 'm²',
                              prefixIcon:
                                  Icon(Icons.straighten_outlined, size: 20),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Nhập DT';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Deposit months
                    const Text('Số tháng đặt cọc', style: AppTypography.bodyMD),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: _depositOptions
                          .map((m) => Padding(
                                padding:
                                    const EdgeInsets.only(right: AppSpacing.sm),
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _depositMonths = m),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    width: 56,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: _depositMonths == m
                                          ? palette.primary
                                          : palette.surfaceLow,
                                      borderRadius: BorderRadius.circular(
                                          AppRadius.button),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '$m tháng',
                                        style: AppTypography.labelSM.copyWith(
                                          color: _depositMonths == m
                                              ? palette.onPrimary
                                              : palette.onSurfaceVariant,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Map Picker
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: palette.surfaceLowest,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        border: Border.all(color: palette.outlineVariant),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Vị trí bản đồ *',
                              style: AppTypography.labelSM),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  hasLocation
                                      ? 'Đã chọn tọa độ: ${state.latitude!.toStringAsFixed(4)}, ${state.longitude!.toStringAsFixed(4)}'
                                      : 'Chưa chọn vị trí',
                                  style: AppTypography.bodyMD.copyWith(
                                    color: hasLocation
                                        ? palette.primary
                                        : palette.danger,
                                    fontWeight: hasLocation
                                        ? FontWeight.w500
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                              AppButton(
                                text: hasLocation ? 'Sửa' : 'Chọn trên Map',
                                type: AppButtonType.secondary,
                                icon: Icons.map_outlined,
                                fullWidth: false,
                                onPressed: _pickLocation,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Description
                    TextFormField(
                      controller: _descCtrl,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Mô tả phòng',
                        hintText: 'Mô tả chi tiết về phòng, ưu điểm...',
                        prefixIcon: Icon(Icons.description_outlined, size: 20),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    AppButton(
                      text: 'Tiếp theo: Ảnh & Tiện nghi',
                      onPressed: _next,
                      icon: Icons.arrow_forward,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgress(int step) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      color: palette.surfaceLow,
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
                    color: isActive || isDone
                        ? palette.primary
                        : palette.surfaceHigh,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isDone
                        ? Icon(Icons.check, size: 14, color: palette.onPrimary)
                        : Text(
                            '$s',
                            style: AppTypography.labelSM.copyWith(
                              color: isActive
                                  ? palette.onPrimary
                                  : palette.onSurfaceVariant,
                            ),
                          ),
                  ),
                ),
                if (s < 3)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isDone ? palette.primary : palette.surfaceHigh,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(text, style: AppTypography.titleMD);
  }
}
