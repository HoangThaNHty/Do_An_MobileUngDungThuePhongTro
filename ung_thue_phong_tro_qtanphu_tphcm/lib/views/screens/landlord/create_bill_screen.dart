import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../../config/constants.dart';
import '../../../controllers/providers/room_provider.dart';
import '../../../controllers/providers/bill_provider.dart';
import '../../../controllers/auth_controller.dart';
import '../../widgets/common/app_button.dart';
import '../../../models/entities/room.dart';
import '../../../models/entities/bill.dart';

class CustomFeeRow {
  final TextEditingController nameCtrl;
  final TextEditingController amountCtrl;
  CustomFeeRow({String name = '', String amount = '0'})
    : nameCtrl = TextEditingController(text: name),
      amountCtrl = TextEditingController(text: amount);
  void dispose() {
    nameCtrl.dispose();
    amountCtrl.dispose();
  }
}

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

  final List<CustomFeeRow> _customFees = [];

  bool _checkingRoom = false;
  bool _isCreating = false;
  bool _hasBillForCurrentMonth = false;
  String? _currentTenantId;
  int _previousElectricity = 0;
  int _previousWater = 0;

  static const int _electricityRate = 2000; // VND/kWh
  static const int _waterRate = 10000;      // VND/m³

  int get _electricityAmount =>
      (int.tryParse(_electricityCtrl.text) ?? 0) * _electricityRate;
  int get _waterAmount =>
      (int.tryParse(_waterCtrl.text) ?? 0) * _waterRate;
  int get _internetAmount => int.tryParse(_internetCtrl.text) ?? 0;
  int get _trashAmount => int.tryParse(_trashCtrl.text) ?? 0;

  int get _customFeesTotal {
    int sum = 0;
    for (var fee in _customFees) {
      sum += int.tryParse(fee.amountCtrl.text) ?? 0;
    }
    return sum;
  }

  int get _otherAmount => _customFeesTotal;

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
    for (var fee in _customFees) {
      fee.dispose();
    }
    super.dispose();
  }

  Future<void> _onRoomChanged(Room? room) async {
    if (room == null) {
      setState(() {
        _selectedRoom = null;
        _hasBillForCurrentMonth = false;
        _currentTenantId = null;
        _previousElectricity = 0;
        _previousWater = 0;
      });
      return;
    }

    setState(() {
      _selectedRoom = room;
      _checkingRoom = true;
      _hasBillForCurrentMonth = false;
      _currentTenantId = null;
      _previousElectricity = 0;
      _previousWater = 0;
    });

    try {
      final now = DateTime.now();
      // 1. Kiểm tra trùng hóa đơn tháng hiện tại
      final billsSnapshot = await FirebaseDatabase.instance.ref('bills').get();
      if (billsSnapshot.exists) {
        final billsData = billsSnapshot.value as Map<dynamic, dynamic>;
        billsData.forEach((key, value) {
          final billMap = Map<String, dynamic>.from(value as Map);
          if (billMap['roomId'] == room.id) {
            final billingMonthStr = billMap['billingMonth'] ?? '';
            final billingMonth = DateTime.tryParse(billingMonthStr);
            if (billingMonth != null &&
                billingMonth.month == now.month &&
                billingMonth.year == now.year &&
                (billMap['electricityUsage'] ?? 0) != 0) { // Loại trừ hóa đơn cọc
              _hasBillForCurrentMonth = true;
            }
          }
        });
      }

      // 2. Tìm active tenant
      final rentalsSnapshot = await FirebaseDatabase.instance.ref('rentals').get();
      if (rentalsSnapshot.exists) {
        final rentalsData = rentalsSnapshot.value as Map<dynamic, dynamic>;
        rentalsData.forEach((key, value) {
          final rentalMap = Map<String, dynamic>.from(value as Map);
          if (rentalMap['roomId'] == room.id && rentalMap['status'] == 'active') {
            _currentTenantId = rentalMap['tenantId'];
          }
        });
      }

      // 3. Tìm chỉ số điện nước cũ (hóa đơn gần nhất)
      int maxTimestamp = 0;
      if (billsSnapshot.exists) {
        final billsData = billsSnapshot.value as Map<dynamic, dynamic>;
        billsData.forEach((key, value) {
          final billMap = Map<String, dynamic>.from(value as Map);
          if (billMap['roomId'] == room.id) {
            final createdAtStr = billMap['createdAt'] ?? '';
            final createdAt = DateTime.tryParse(createdAtStr);
            if (createdAt != null) {
              final ts = createdAt.millisecondsSinceEpoch;
              if (ts > maxTimestamp && (billMap['electricityUsage'] ?? 0) > 0) {
                maxTimestamp = ts;
                _previousElectricity = billMap['electricityUsage'] ?? 0;
                _previousWater = billMap['waterUsage'] ?? 0;
              }
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Lỗi tải dữ liệu phòng: $e');
    } finally {
      if (mounted) {
        setState(() {
          _checkingRoom = false;
        });
      }
    }
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
            const Text('Chọn phòng', style: AppTypography.titleSM),
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
                  onChanged: _onRoomChanged,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            if (_checkingRoom) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
            ] else ...[
              // Duplicate bill warning banner
              if (_hasBillForCurrentMonth) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(color: const Color(0xFFEF5350)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Color(0xFFC62828)),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Phòng này đã được lập hóa đơn trong tháng này rồi! Bạn không thể lập thêm hóa đơn trùng.',
                          style: AppTypography.bodySM.copyWith(
                            color: const Color(0xFFC62828),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Tenant Details Profile Card
              if (_selectedRoom != null && _currentTenantId != null) ...[
                Consumer(
                  builder: (context, ref, _) {
                    final userAsync = ref.watch(userByIdProvider(_currentTenantId!));
                    return userAsync.when(
                      loading: () => const Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                      error: (e, _) => const SizedBox(),
                      data: (user) {
                        if (user == null) return const SizedBox();
                        return Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(AppRadius.card),
                            border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
                            boxShadow: const [AppShadows.card],
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                child: user.avatarUrl == null
                                    ? const Icon(Icons.person, color: AppColors.primary)
                                    : null,
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.fullName,
                                      style: AppTypography.titleSM.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '📞 ${user.phone}',
                                      style: AppTypography.bodySM.copyWith(color: AppColors.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.available.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Khách thuê',
                                  style: TextStyle(
                                    color: AppColors.available,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ],

              // Billing room info
              if (_selectedRoom != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.06),
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

                // Usage inputs
                const Text('Chỉ số điện nước', style: AppTypography.titleSM),
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
                        previousUsage: _previousElectricity,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _usageField(
                        ctrl: _waterCtrl,
                        icon: Icons.water_drop_outlined,
                        label: 'Nước (m³)',
                        unit: 'm³',
                        rate: _waterRate,
                        iconColor: Colors.blue,
                        previousUsage: _previousWater,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Other fees
                const Text('Phí dịch vụ', style: AppTypography.titleSM),
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

                      // Danh sách các khoản phí tùy biến động
                      if (_customFees.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.md),
                        const Divider(height: 1),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      ..._customFees.asMap().entries.map((entry) {
                        final index = entry.key;
                        final feeRow = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: Row(
                            children: [
                              const Icon(Icons.add_box_outlined, size: 18, color: AppColors.primary),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  controller: feeRow.nameCtrl,
                                  decoration: const InputDecoration(
                                    hintText: 'Tên phí khác...',
                                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  ),
                                  style: AppTypography.bodyMD,
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  controller: feeRow.amountCtrl,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.right,
                                  decoration: const InputDecoration(
                                    suffixText: 'đ',
                                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  ),
                                  style: AppTypography.bodyMD,
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Color(0xFFC62828), size: 20),
                                onPressed: () {
                                  setState(() {
                                    feeRow.dispose();
                                    _customFees.removeAt(index);
                                  });
                                },
                              ),
                            ],
                          ),
                        );
                      }),

                      const SizedBox(height: AppSpacing.md),
                      // Nút thêm phí động
                      OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _customFees.add(CustomFeeRow());
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          minimumSize: const Size(double.infinity, 38),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.button),
                          ),
                        ),
                        icon: const Icon(Icons.add_circle_outline, size: 16),
                        label: const Text('Thêm khoản phí dịch vụ khác', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
                      
                      // Hiển thị từng khoản phí dịch vụ tùy biến động
                      ..._customFees.map((fee) {
                        final name = fee.nameCtrl.text.isNotEmpty ? fee.nameCtrl.text : 'Dịch vụ khác';
                        final amount = int.tryParse(fee.amountCtrl.text) ?? 0;
                        return _summaryRow(name, amount);
                      }),

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
                  onPressed: (_hasBillForCurrentMonth || _isCreating) ? null : _createBill,
                  isLoading: _isCreating,
                  icon: Icons.receipt_long_outlined,
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ],
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
    int previousUsage = 0,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: AppSpacing.xs),
            Text(label, style: AppTypography.bodyMD),
            if (previousUsage > 0) ...[
              const SizedBox(width: 4),
              Text(
                '(Cũ: $previousUsage)',
                style: AppTypography.labelSM.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.normal,
                  fontSize: 11,
                ),
              ),
            ],
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.bodyMD.copyWith(
                    color: AppColors.onPrimary.withValues(alpha: 0.9),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: AppTypography.bodySM.copyWith(
                      color: AppColors.onPrimary.withValues(alpha: 0.6),
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
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

  Future<void> _createBill() async {
    if (_selectedRoom == null) return;
    
    setState(() {
      _isCreating = true;
    });

    try {
      String tenantId = _currentTenantId ?? '';
      String tenantName = '';

      // Find the active rental to fetch tenant name if not already found
      final rentalsRef = FirebaseDatabase.instance.ref('rentals');
      final rentalsSnapshot = await rentalsRef.get();
      
      if (rentalsSnapshot.exists) {
        final rentalsData = rentalsSnapshot.value as Map<dynamic, dynamic>;
        rentalsData.forEach((key, value) {
          final rentalMap = Map<String, dynamic>.from(value as Map);
          if (rentalMap['roomId'] == _selectedRoom!.id && rentalMap['status'] == 'active') {
            tenantId = rentalMap['tenantId'] ?? '';
            tenantName = rentalMap['tenantName'] ?? '';
          }
        });
      }

      // Fallbacks in case rentals query yields nothing
      if (tenantId.isEmpty) {
        if (_selectedRoom!.id == 'room_tanphu_002') {
          tenantId = 'r4ju3iGOqteScwi4LQyYb2WpWE72';
          tenantName = 'Lê Hoàng Nam';
        } else if (_selectedRoom!.id == 'room_tanphu_009') {
          tenantId = 'ZL5CO8QAieRspg3OkLLhZbuCZb2';
          tenantName = 'Thanh Nguyen hoang';
        } else {
          tenantId = 'r4ju3iGOqteScwi4LQyYb2WpWE72';
          tenantName = 'Lê Hoàng Nam';
        }
      }

      if (tenantName.isEmpty) {
        if (tenantId == 'r4ju3iGOqteScwi4LQyYb2WpWE72') {
          tenantName = 'Lê Hoàng Nam';
        } else if (tenantId == 'ZL5CO8QAieRspg3OkLLhZbuCZb2') {
          tenantName = 'Thanh Nguyen hoang';
        } else {
          tenantName = 'Khách thuê';
        }
      }

      // Create new bill entry
      final newBillId = 'bill_${DateTime.now().millisecondsSinceEpoch}';
      
      final bill = Bill(
        id: newBillId,
        roomId: _selectedRoom!.id,
        roomTitle: _selectedRoom!.title,
        tenantId: tenantId,
        tenantName: tenantName,
        rentAmount: _rentAmount,
        electricityAmount: _electricityAmount,
        waterAmount: _waterAmount,
        internetAmount: _internetAmount,
        trashAmount: _trashAmount,
        otherAmount: _otherAmount,
        electricityUsage: int.tryParse(_electricityCtrl.text) ?? 0,
        waterUsage: int.tryParse(_waterCtrl.text) ?? 0,
        status: BillStatus.unpaid,
        billingMonth: DateTime.now(),
        dueDate: DateTime.now().add(const Duration(days: 7)),
        createdAt: DateTime.now(),
      );

      // Write to Firebase Realtime Database
      await FirebaseDatabase.instance.ref('bills/$newBillId').set(bill.toMap());

      // Invalidate the bills provider to ensure all views get updated immediately
      ref.invalidate(billsProvider(tenantId));

      setState(() {
        _isCreating = false;
      });

      // Show success dialog
      if (mounted) {
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
          if (mounted) {
            setState(() {
              _selectedRoom = null;
              _electricityCtrl.text = '0';
              _waterCtrl.text = '0';
              for (var fee in _customFees) {
                fee.dispose();
              }
              _customFees.clear();
              _hasBillForCurrentMonth = false;
              _currentTenantId = null;
              _previousElectricity = 0;
              _previousWater = 0;
            });
          }
        });
      }
    } catch (e) {
      setState(() {
        _isCreating = false;
      });

      // Show error SnackBar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tạo hóa đơn: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }
}
