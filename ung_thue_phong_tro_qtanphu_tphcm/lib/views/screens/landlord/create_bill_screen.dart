import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/constants.dart';
import '../../../controllers/providers/room_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../../models/entities/room.dart';

class CreateBillScreen extends ConsumerStatefulWidget {
  const CreateBillScreen({super.key});

  @override
  ConsumerState<CreateBillScreen> createState() => _CreateBillScreenState();
}

class _CreateBillScreenState extends ConsumerState<CreateBillScreen> {
  final _formKey = GlobalKey<FormState>();
  Room? _selectedRoom;
  final _electricityCtrl = TextEditingController(text: '0');
  final _waterCtrl = TextEditingController(text: '0');
  final _internetCtrl = TextEditingController(text: '100000');
  final _trashCtrl = TextEditingController(text: '20000');
  final _otherCtrl = TextEditingController(text: '0');

  static const int _electricityRate = 2000; // VND/kWh
  static const int _waterRate = 10000;      // VND/m³

  int get _electricityAmount =>
      (int.tryParse(_electricityCtrl.text) ?? 0) * _electricityRate;
  int get _waterAmount =>
      (int.tryParse(_waterCtrl.text) ?? 0) * _waterRate;
  int get _internetAmount => int.tryParse(_internetCtrl.text) ?? 0;
  int get _trashAmount => int.tryParse(_trashCtrl.text) ?? 0;
  int get _otherAmount => int.tryParse(_otherCtrl.text) ?? 0;
  int get _rentAmount => _selectedRoom?.price ?? 0;
  int get _totalAmount =>
      _rentAmount + _electricityAmount + _waterAmount +
      _internetAmount + _trashAmount + _otherAmount;

  @override
  void dispose() {
    _electricityCtrl.dispose();
    _waterCtrl.dispose();
    _internetCtrl.dispose();
    _trashCtrl.dispose();
    _otherCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roomState = ref.watch(roomProvider);
    final rentedRooms = roomState.rooms
        .where((r) => r.status == RoomStatus.rented)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Tạo hóa đơn'),
        automaticallyImplyLeading: false,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            // Room selector
            Text('Chọn phòng', style: AppTypography.titleSM),
            const SizedBox(height: AppSpacing.sm),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppRadius.input),
              ),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Room>(
                  value: _selectedRoom,
                  hint: const Text('Chọn phòng...'),
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down),
                  style: AppTypography.bodyMD.copyWith(
                    color: AppColors.onSurface,
                  ),
                  items: rentedRooms
                      .map((r) => DropdownMenuItem(
                            value: r,
                            child: Text(r.title),
                          ))
                      .toList(),
                  onChanged: (r) => setState(() => _selectedRoom = r),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Billing month info
            if (_selectedRoom != null) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Thông tin phòng', style: AppTypography.labelSM.copyWith(color: AppColors.primary)),
                    const SizedBox(height: 4),
                    Text(_selectedRoom!.title, style: AppTypography.titleSM),
                    Text(_selectedRoom!.address, style: AppTypography.bodySM),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tiền thuê tháng này:'),
                        Text(
                          '${_formatCurrency(_rentAmount)}đ',
                          style: AppTypography.bodyMD.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

            // Usage inputs
            Text('Chỉ số điện nước', style: AppTypography.titleSM),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppRadius.card),
                boxShadow: const [AppShadows.card],
              ),
              child: Column(
                children: [
                  _usageField(
                    ctrl: _electricityCtrl,
                    icon: Icons.bolt_outlined,
                    label: 'Điện (kWh)',
                    unit: 'kWh',
                    rate: _electricityRate,
                    iconColor: const Color(0xFFFF8F00),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _usageField(
                    ctrl: _waterCtrl,
                    icon: Icons.water_drop_outlined,
                    label: 'Nước (m³)',
                    unit: 'm³',
                    rate: _waterRate,
                    iconColor: Colors.blue,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Other fees
            Text('Phí dịch vụ', style: AppTypography.titleSM),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppRadius.card),
                boxShadow: const [AppShadows.card],
              ),
              child: Column(
                children: [
                  _feeField(
                    ctrl: _internetCtrl,
                    icon: Icons.wifi_outlined,
                    label: 'Internet (đ)',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _feeField(
                    ctrl: _trashCtrl,
                    icon: Icons.delete_outline,
                    label: 'Rác (đ)',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _feeField(
                    ctrl: _otherCtrl,
                    icon: Icons.more_horiz_outlined,
                    label: 'Phí khác (đ)',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Total summary
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                gradient: AppGradients.primaryButton,
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              child: Column(
                children: [
                  _summaryRow('Tiền thuê', _rentAmount),
                  _summaryRow('Tiền điện', _electricityAmount,
                      subtitle:
                          '${_electricityCtrl.text} kWh × ${_formatCurrency(_electricityRate)}đ'),
                  _summaryRow('Tiền nước', _waterAmount,
                      subtitle:
                          '${_waterCtrl.text} m³ × ${_formatCurrency(_waterRate)}đ'),
                  _summaryRow('Internet', _internetAmount),
                  _summaryRow('Rác', _trashAmount),
                  if (_otherAmount > 0)
                    _summaryRow('Khác', _otherAmount),
                  const SizedBox(height: AppSpacing.sm),
                  const Divider(color: Colors.white24, thickness: 0.5),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'TỔNG CỘNG',
                        style: AppTypography.labelSM.copyWith(
                          color: AppColors.onPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${_formatCurrency(_totalAmount)}đ',
                        style: AppTypography.headlineMD.copyWith(
                          color: AppColors.onPrimary,
                          fontSize: 22,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Create bill button
            AppButton(
              text: 'Tạo hóa đơn',
              onPressed: _selectedRoom == null ? null : _createBill,
              icon: Icons.receipt_long_outlined,
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _usageField({
    required TextEditingController ctrl,
    required IconData icon,
    required String label,
    required String unit,
    required int rate,
    required Color iconColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: AppSpacing.xs),
            Text(label, style: AppTypography.bodyMD),
            const Spacer(),
            Text(
              '= ${_formatCurrency(
                (int.tryParse(ctrl.text) ?? 0) * rate,
              )}đ',
              style: AppTypography.bodyMD.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            suffixText: unit,
            suffixStyle: AppTypography.bodyMD,
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _feeField({
    required TextEditingController ctrl,
    required IconData icon,
    required String label,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.onSurfaceVariant),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          flex: 2,
          child: Text(label, style: AppTypography.bodyMD),
        ),
        Expanded(
          flex: 3,
          child: TextFormField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.right,
            decoration: const InputDecoration(
              suffixText: 'đ',
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, int amount, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.bodyMD.copyWith(
                  color: AppColors.onPrimary.withOpacity(0.9),
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: AppTypography.bodySM.copyWith(
                    color: AppColors.onPrimary.withOpacity(0.6),
                    fontSize: 10,
                  ),
                ),
            ],
          ),
          Text(
            '${_formatCurrency(amount)}đ',
            style: AppTypography.bodyMD.copyWith(
              color: AppColors.onPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _createBill() {
    if (_selectedRoom == null) return;
    
    // Show success dialog instead of just a snackbar for better UX
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 48),
            ),
            const SizedBox(height: 16),
            const Text('Tạo hóa đơn thành công!', textAlign: TextAlign.center),
          ],
        ),
        content: Text(
          'Đã tạo hóa đơn ${_formatCurrency(_totalAmount)}đ cho phòng ${_selectedRoom!.title}.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMD,
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: AppButton(
              text: 'Hoàn tất',
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ),
        ],
      ),
    ).then((_) {
      setState(() {
        _selectedRoom = null;
        _electricityCtrl.text = '0';
        _waterCtrl.text = '0';
      });
    });
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }
}
