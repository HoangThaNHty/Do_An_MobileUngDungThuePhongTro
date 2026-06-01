import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../../config/constants.dart';
import '../../../controllers/booking_controller.dart';
import '../../widgets/common/status_chips.dart';
import '../../widgets/common/app_button.dart';
import '../../../models/entities/bill.dart';
import '../../../models/entities/user.dart';

final landlordByRoomProvider = FutureProvider.family<AppUser?, String>((ref, roomId) async {
  final db = FirebaseDatabase.instance;
  final roomSnapshot = await db.ref('rooms/$roomId').get();
  if (!roomSnapshot.exists) return null;
  final roomData = roomSnapshot.value as Map<dynamic, dynamic>;
  final landlordId = roomData['landlordId'] as String?;
  if (landlordId == null) return null;
  
  final userSnapshot = await db.ref('users/$landlordId').get();
  if (!userSnapshot.exists) return null;
  final userData = userSnapshot.value as Map<dynamic, dynamic>;
  return AppUser(
    id: landlordId,
    fullName: userData['fullName'] ?? 'Chủ trọ',
    email: userData['email'] ?? '',
    phone: userData['phone'] ?? '0969781234',
    role: UserRole.landlord,
    createdAt: DateTime.now(),
  );
});

class MyBillsScreen extends ConsumerWidget {
  final String rentalId;

  const MyBillsScreen({super.key, required this.rentalId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Lấy hóa đơn từ Firebase Realtime Database
    final billsAsync = ref.watch(tenantBillsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Hóa đơn'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/tenant/rentals'),
        ),
      ),
      body: billsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (bills) {
          if (bills.isEmpty) {
            return const Center(child: Text('Chưa có hóa đơn'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: bills.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              return _BillCard(bill: bills[index]);
            },
          );
        },
      ),
    );
  }
}

class _BillCard extends ConsumerWidget {
  final Bill bill;

  const _BillCard({required this.bill});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: const [AppShadows.card],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppRadius.card),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(bill.roomTitle, style: AppTypography.titleSM),
                      Text(
                        'Tháng ${bill.billingMonth.month}/${bill.billingMonth.year}',
                        style: AppTypography.bodySM.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '📅 Ngày tạo: ${_fmtDateTime(bill.createdAt)}',
                        style: AppTypography.labelSM.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusWidget(),
              ],
            ),
          ),
          // Items
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                _billRow('Tiền thuê', bill.rentAmount),
                _billRow(
                    'Điện (${bill.electricityUsage} kWh)',
                    bill.electricityAmount),
                _billRow(
                    'Nước (${bill.waterUsage} m³)', bill.waterAmount),
                _billRow('Internet', bill.internetAmount),
                _billRow('Rác', bill.trashAmount),
                if (bill.otherAmount > 0)
                  _billRow('Khác', bill.otherAmount),
                const SizedBox(height: AppSpacing.sm),
                const Divider(
                    color: AppColors.outlineVariant, thickness: 0.5),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TỔNG CỘNG',
                      style: AppTypography.labelSM.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${_formatCurrency(bill.totalAmount)}đ',
                      style: AppTypography.titleMD.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                // Due date
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: bill.status == BillStatus.overdue
                        ? AppColors.overdue
                        : AppColors.surfaceContainerLow,
                    borderRadius:
                        BorderRadius.circular(AppRadius.button),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: bill.status == BillStatus.overdue
                            ? AppColors.onOverdue
                            : AppColors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Hạn thanh toán: ${_fmtDate(bill.dueDate)}',
                        style: AppTypography.labelSM.copyWith(
                          color: bill.status == BillStatus.overdue
                              ? AppColors.onOverdue
                              : AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                // Payment Action Area
                if (bill.status == BillStatus.unpaid && !bill.paymentSubmitted) ...[
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    text: 'Thanh toán qua VietQR',
                    icon: Icons.qr_code_scanner_outlined,
                    onPressed: () => _showVietQRPaymentSheet(context, ref),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusWidget() {
    if (bill.status == BillStatus.unpaid && bill.paymentSubmitted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.amber.shade100,
          borderRadius: BorderRadius.circular(AppRadius.chip),
          border: Border.all(color: Colors.amber.shade300),
        ),
        child: Text(
          'ĐANG CHỜ DUYỆT ⏳',
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: Colors.amber.shade900,
            letterSpacing: 0.5,
          ),
        ),
      );
    }
    return BillStatusChip(status: bill.status);
  }

  void _showVietQRPaymentSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final landlordAsync = ref.watch(landlordByRoomProvider(bill.roomId));

        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            top: AppSpacing.lg,
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
          ),
          child: landlordAsync.when(
            loading: () => const SizedBox(
              height: 300,
              child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            ),
            error: (err, _) => SizedBox(
              height: 200,
              child: Center(child: Text('Lỗi tải thông tin chủ trọ: $err')),
            ),
            data: (landlord) {
              if (landlord == null) {
                return const SizedBox(
                  height: 200,
                  child: Center(child: Text('Không tìm thấy thông tin chủ trọ')),
                );
              }

              final landlordPhone = landlord.phone.trim();
              final landlordName = landlord.fullName.toUpperCase();
              final totalAmount = bill.totalAmount;
              
              final unaccentedRoom = bill.roomTitle
                  .replaceAll(RegExp(r'[àáạảãâầấậẩẫăằắặẳẵ]'), 'a')
                  .replaceAll(RegExp(r'[èéẹẻẽêềếệểễ]'), 'e')
                  .replaceAll(RegExp(r'[ìíịỉĩ]'), 'i')
                  .replaceAll(RegExp(r'[òóọỏõôồốộổỗơờớợởỡ]'), 'o')
                  .replaceAll(RegExp(r'[ùúụủũưừứựửữ]'), 'u')
                  .replaceAll(RegExp(r'[ỳýỵỷỹ]'), 'y')
                  .replaceAll(RegExp(r'[đ]'), 'd')
                  .replaceAll(RegExp(r'[ÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴ]'), 'A')
                  .replaceAll(RegExp(r'[ÈÉẸẺẼÊỀẾỆỂỄ]'), 'E')
                  .replaceAll(RegExp(r'[ÌÍỊỈĨ]'), 'I')
                  .replaceAll(RegExp(r'[ÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠ]'), 'O')
                  .replaceAll(RegExp(r'[ÙÚỤỦŨƯỪỨỰỬỮ]'), 'U')
                  .replaceAll(RegExp(r'[ỲÝỴỶỸ]'), 'Y')
                  .replaceAll(RegExp(r'[Đ]'), 'D');

              final transactionContent = 'THANH TOAN TIEN PHONG THANG ${bill.billingMonth.month} PHONG ${unaccentedRoom.replaceAll(' ', '')}';
              final qrUrl = 'https://img.vietqr.io/image/MB/$landlordPhone-compact2.png?amount=$totalAmount&addInfo=${Uri.encodeComponent(transactionContent)}&accountName=${Uri.encodeComponent(landlordName)}';

              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    
                    Text(
                      'THANH TOÁN VIETQR',
                      style: AppTypography.titleMD.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Chuyển tiền P2P trực tiếp bằng quét mã QR',
                      style: AppTypography.bodySM.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
                      ),
                      child: Column(
                        children: [
                          _paymentInfoRow('Ngân hàng', 'MB BANK (Quân Đội)'),
                          _paymentInfoRow('Tên chủ tài khoản', landlordName),
                          _paymentInfoRow('Số tài khoản (SĐT)', landlordPhone),
                          _paymentInfoRow('Số tiền chuyển', '${bill.totalAmount.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.")}đ'),
                          _paymentInfoRow('Nội dung chuyển khoản', transactionContent),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [AppShadows.card],
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          qrUrl,
                          width: 240,
                          height: 240,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const SizedBox(
                              width: 240,
                              height: 240,
                              child: Center(
                                child: CircularProgressIndicator(color: AppColors.primary),
                              ),
                            );
                          },
                          errorBuilder: (_, __, ___) => const SizedBox(
                            width: 240,
                            height: 240,
                            child: Center(
                              child: Icon(Icons.broken_image_outlined, size: 48, color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: AppColors.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Vui lòng mở ứng dụng ngân hàng quét mã QR trên để chuyển khoản. Mã QR đã điền sẵn số tiền & nội dung tự động.',
                              style: AppTypography.bodySM.copyWith(fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    AppButton(
                      text: 'Tôi đã chuyển khoản thành công',
                      icon: Icons.check_circle_outline,
                      onPressed: () async {
                        try {
                          final db = FirebaseDatabase.instance;
                          await db.ref('bills/${bill.id}').update({
                            'paymentSubmitted': true,
                          });
                          
                          ref.invalidate(tenantBillsProvider);

                          if (context.mounted) {
                            Navigator.of(context).pop(); // Close sheet
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Báo cáo thanh toán thành công! Vui lòng chờ Chủ trọ duyệt giao dịch ⏳'),
                                backgroundColor: Color(0xFF2E7D32),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
                            );
                          }
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _paymentInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: AppTypography.bodySM.copyWith(color: AppColors.onSurfaceVariant),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTypography.bodySM.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _billRow(String label, int amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodyMD),
          Text(
            '${_formatCurrency(amount)}đ',
            style: AppTypography.bodyMD.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _fmtDateTime(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} lúc ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }
}
