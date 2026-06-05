import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../config/app_palette.dart';
import '../../../config/constants.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/booking_controller.dart';
import '../../../controllers/providers/room_provider.dart';
import '../../../models/entities/room.dart';
import '../../widgets/common/app_button.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final Room room;
  final int depositMonths;
  final int amount;
  final DateTime moveInDate;

  const PaymentScreen({
    super.key,
    required this.room,
    required this.depositMonths,
    required this.amount,
    required this.moveInDate,
  });

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  bool _isProcessing = false;

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã sao chép $label!'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _onPaymentConfirm(
      String landlordName, String tenantName, String tenantId) async {
    final palette = context.palette;
    setState(() {
      _isProcessing = true;
    });

    try {
      final bookingCtrl = ref.read(bookingControllerProvider);

      // 1. Tạo đặt phòng pending và Hóa đơn unpaid trên Firebase Realtime Database
      final result = await bookingCtrl.createBookingDeposit(
        room: widget.room,
        tenantId: tenantId,
        tenantName: tenantName,
        depositMonths: widget.depositMonths,
        amount: widget.amount,
        moveInDate: widget.moveInDate,
      );

      final rentalId = result['rentalId']!;
      final billId = result['billId']!;

      // 2. Xác nhận thanh toán cọc thành công
      await bookingCtrl.confirmDepositPayment(
        rentalId: rentalId,
        billId: billId,
        roomId: widget.room.id,
      );

      // Trigger tải lại danh sách phòng
      ref.invalidate(roomProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Xác nhận đặt cọc và thanh toán thành công! 🎉'),
          backgroundColor: palette.success,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Chuyển về trang Hợp đồng của tôi
      context.go('/tenant');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Có lỗi xảy ra: $e'),
          backgroundColor: palette.danger,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final landlordAsync = ref.watch(userByIdProvider(widget.room.landlordId));
    final currentTenant = ref.watch(currentUserProvider);
    final palette = context.palette;

    final tenantName = currentTenant?.fullName ?? 'Khách thuê';
    final tenantId = currentTenant?.id ?? '';

    return Scaffold(
      backgroundColor: palette.surface,
      appBar: AppBar(
        title: const Text('Thanh toán đặt cọc'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: landlordAsync.when(
        loading: () =>
            Center(child: CircularProgressIndicator(color: palette.primary)),
        error: (e, _) => Center(child: Text('Lỗi tải thông tin chủ trọ: $e')),
        data: (landlord) {
          if (landlord == null) {
            return const Center(
                child: Text('Không tìm thấy thông tin chủ nhà'));
          }

          // Tài khoản trung gian Escrow cố định của Platform
          const stk = '0938888888';
          const nameNoSign = 'CONG TY PHONG TRO TAN PHU';
          final addInfo = 'TAN PHU ESCROW COCPHONG ${widget.room.id}';

          // VietQR compact image URL
          final qrUrl = 'https://img.vietqr.io/image/MB-$stk-compact.png'
              '?amount=${widget.amount}'
              '&addInfo=$addInfo'
              '&accountName=CONG%20TY%20PHONG%20TRO%20TAN%20PHU';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ─── Header Tóm tắt ────────────────────
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: palette.surfaceLowest,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    boxShadow: const [AppShadows.card],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.room.title,
                        style: AppTypography.titleSM.copyWith(
                          color: palette.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.room.address,
                        style: AppTypography.bodySM.copyWith(
                          color: palette.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Divider(height: AppSpacing.md),

                      // Cảnh báo giao dịch bảo chứng an toàn
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: palette.successContainer,
                          borderRadius: BorderRadius.circular(AppRadius.button),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.verified_user_outlined,
                                color: palette.success, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Tiền cọc sẽ được tạm khóa an toàn tại ví Platform. Bạn có quyền hoàn trả cọc 100% nếu có tranh chấp!',
                                style: TextStyle(
                                  color: palette.success,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Số tiền cọc giữ chỗ:',
                            style: AppTypography.bodyMD.copyWith(
                              color: palette.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            '${_formatCurrency(widget.amount)}đ',
                            style: AppTypography.titleSM.copyWith(
                              color: palette.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // ─── Ảnh Mã QR VietQR Napas động ───────────
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: palette.qrSurface,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      boxShadow: const [AppShadows.bottomSheet],
                      border: Border.all(
                          color: palette.primary.withValues(alpha: 0.15),
                          width: 1.5),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.qr_code_2,
                                color: palette.primary, size: 24),
                            const SizedBox(width: 6),
                            Text(
                              'QUÉT MÃ VIETQR QUA NGÂN HÀNG',
                              style: TextStyle(
                                color: palette.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        SizedBox(
                          width: 210,
                          height: 210,
                          child: CachedNetworkImage(
                            imageUrl: qrUrl,
                            fit: BoxFit.contain,
                            placeholder: (_, __) => Center(
                              child: CircularProgressIndicator(
                                  color: palette.primary),
                            ),
                            errorWidget: (_, __, ___) => Center(
                              child: Icon(Icons.qr_code,
                                  size: 100, color: palette.outline),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Sử dụng ứng dụng ngân hàng quét để tự động điền STK & Nội dung',
                          style: TextStyle(
                            color: palette.onSurfaceVariant,
                            fontSize: 9,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // ─── Chi tiết chuyển khoản (Để copy) ──────
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
                      Text(
                        'Hoặc chuyển khoản thủ công:',
                        style: AppTypography.labelSM.copyWith(
                          color: palette.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _buildCopyableRow(
                          'Ngân hàng', 'MB Bank (Quân Đội)', palette,
                          copyable: false),
                      _buildCopyableRow('Số tài khoản', stk, palette,
                          onCopy: () => _copyToClipboard(stk, 'Số tài khoản')),
                      _buildCopyableRow('Chủ tài khoản', nameNoSign, palette,
                          copyable: false),
                      _buildCopyableRow(
                        'Số tiền',
                        '${_formatCurrency(widget.amount)}đ',
                        palette,
                        onCopy: () => _copyToClipboard(
                            widget.amount.toString(), 'Số tiền'),
                      ),
                      _buildCopyableRow(
                        'Nội dung chuyển',
                        addInfo,
                        palette,
                        onCopy: () =>
                            _copyToClipboard(addInfo, 'Nội dung chuyển khoản'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // ─── Nút Xác nhận Thanh toán ────────────
                AppButton(
                  text: 'Tôi đã chuyển khoản thành công',
                  onPressed: _isProcessing
                      ? null
                      : () => _onPaymentConfirm(
                          landlord.fullName, tenantName, tenantId),
                  isLoading: _isProcessing,
                  icon: Icons.check_circle_outline,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('Hủy bỏ giao dịch'),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCopyableRow(String label, String value, AppPalette palette,
      {bool copyable = true, VoidCallback? onCopy}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: AppTypography.bodySM
                    .copyWith(color: palette.onSurfaceVariant)),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodyMD.copyWith(
                fontWeight: FontWeight.bold,
                color: palette.onSurface,
              ),
            ),
          ),
          if (copyable && onCopy != null)
            GestureDetector(
              onTap: onCopy,
              child: Icon(
                Icons.copy,
                size: 16,
                color: palette.primary,
              ),
            ),
        ],
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
