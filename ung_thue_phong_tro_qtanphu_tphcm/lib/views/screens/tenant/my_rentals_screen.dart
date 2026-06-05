import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../config/app_palette.dart';
import '../../../config/constants.dart';
import '../../../controllers/booking_controller.dart';
import '../../../controllers/review_controller.dart';
import '../../../controllers/providers/bill_provider.dart';
import '../../../models/entities/bill.dart';
import '../../../models/entities/rental.dart';

class MyRentalsScreen extends ConsumerWidget {
  const MyRentalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rentalsAsync = ref.watch(tenantRentalsProvider);
    final palette = context.palette;

    return Scaffold(
      backgroundColor: palette.surface,
      appBar: AppBar(
        title: const Text('Phòng đang thuê'),
        automaticallyImplyLeading: false,
      ),
      body: rentalsAsync.when(
        loading: () => const _RentalShimmerList(),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (rentals) {
          if (rentals.isEmpty) {
            return _buildEmpty(context);
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: rentals.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              final rental = rentals[index];
              return _RentalCard(
                rental: rental,
                onViewBills: () =>
                    context.go('/tenant/rentals/bills/${rental.id}'),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    final palette = context.palette;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.home_outlined,
            size: 72,
            color: palette.outlineVariant,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Bạn chưa thuê phòng nào',
            style: AppTypography.titleSM.copyWith(
              color: palette.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Hãy tìm kiếm và liên hệ chủ trọ để thuê phòng',
            style: AppTypography.bodyMD,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _RentalCard extends ConsumerWidget {
  final Rental rental;
  final VoidCallback onViewBills;

  const _RentalCard({
    required this.rental,
    required this.onViewBills,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final bookingCtrl = ref.read(bookingControllerProvider);
    final billsAsync = ref.watch(billsProvider(rental.tenantId));

    final activeMonthlyBills = billsAsync.maybeWhen(
      data: (list) {
        final bills = list
            .where((bill) =>
                bill.roomId == rental.roomId &&
                bill.status == BillStatus.unpaid &&
                !isDepositBill(bill))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return bills;
      },
      orElse: () => const <Bill>[],
    );
    final payableBills = activeMonthlyBills
        .where((bill) => !bill.paymentSubmitted)
        .toList(growable: false);
    final waitingApprovalBills = activeMonthlyBills
        .where((bill) => bill.paymentSubmitted)
        .toList(growable: false);
    final payableBill = payableBills.isNotEmpty ? payableBills.first : null;
    final waitingApprovalBill =
        waitingApprovalBills.isNotEmpty ? waitingApprovalBills.first : null;

    // Logic tự động kiểm tra quá hạn (Timeout check): Ngày hẹn gặp + 48 giờ
    final deadline = rental.startDate.add(const Duration(hours: 48));
    final isOverdue = DateTime.now().isAfter(deadline);

    if (rental.status == RentalStatus.pending && isOverdue) {
      // Tự động giải ngân cho chủ trọ khi khách im lặng bùng hẹn quá 48h
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          await bookingCtrl.releaseDeposit(rentalId: rental.id);
        } catch (_) {}
      });
    }

    String statusText = 'ĐANG THUÊ';
    if (rental.status == RentalStatus.pending) {
      statusText = 'CỌC GIỮ CHỖ';
    } else if (rental.status == RentalStatus.cancelled) {
      statusText = 'ĐÃ HỦY';
    } else if (rental.status == RentalStatus.expired) {
      statusText = 'HẾT HẠN';
    }

    final daysLeft = rental.remainingDays;

    return Container(
      decoration: BoxDecoration(
        color: palette.surfaceLowest,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: const [AppShadows.card],
      ),
      child: Column(
        children: [
          // Wrap Header and Info block in GestureDetector for room view navigation
          GestureDetector(
            onTap: () => context.push('/tenant/room/${rental.roomId}'),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: rental.status == RentalStatus.pending
                          ? [const Color(0xFFEF6C00), const Color(0xFFFFB74D)]
                          : rental.status == RentalStatus.cancelled
                              ? [
                                  const Color(0xFFC62828),
                                  const Color(0xFFE57373)
                                ]
                              : [palette.primary, palette.primaryContainer],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppRadius.card),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.home_work_outlined,
                          color: AppColors.onPrimary, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              rental.roomTitle,
                              style: AppTypography.titleSM.copyWith(
                                color: AppColors.onPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Chạm để xem chi tiết phòng và chủ nhà ➔',
                              style: AppTypography.labelSM.copyWith(
                                color:
                                    AppColors.onPrimary.withValues(alpha: 0.8),
                                fontSize: 9,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.onPrimary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(AppRadius.chip),
                        ),
                        child: Text(
                          statusText,
                          style: AppTypography.labelSM.copyWith(
                            color: AppColors.onPrimary,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Visual touch hint banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      vertical: 8, horizontal: AppSpacing.md),
                  color: palette.primary.withValues(alpha: 0.1),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.touch_app_outlined,
                          size: 14, color: AppColors.primary),
                      SizedBox(width: 6),
                      Text(
                        'Chạm vào thẻ này để xem lại phòng & vị trí bản đồ ➔',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _infoRow(Icons.location_on_outlined, rental.roomAddress),
                      const SizedBox(height: AppSpacing.xs),
                      _infoRow(
                        Icons.calendar_today_outlined,
                        'Ngày hẹn dọn vào: ${_fmtDate(rental.startDate)}',
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      _infoRow(
                        Icons.payments_outlined,
                        rental.status == RentalStatus.pending
                            ? 'Tiền cọc giữ chỗ: 500.000đ (Đang khóa Escrow)'
                            : '${rental.monthlyRent.toVnd()}đ/tháng',
                        valueColor: rental.status == RentalStatus.pending
                            ? const Color(0xFFEF6C00)
                            : AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Action Buttons and Alerts (Not inside GestureDetector to prevent conflicts!)
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (rental.status == RentalStatus.pending) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(AppRadius.button),
                      border: Border.all(color: const Color(0xFFFFD54F)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.shield_outlined,
                                color: Color(0xFFF57F17), size: 16),
                            SizedBox(width: 6),
                            Text(
                              'Đang được Bảo lãnh bởi Platform',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFF57F17),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Vui lòng dọn vào trước ${_fmtDate(deadline)}. Sau thời hạn này 48 tiếng, nếu bạn không xác nhận, tiền cọc sẽ được tự động giải ngân cho chủ trọ để đền bù.',
                          style: const TextStyle(
                              color: Colors.black87, fontSize: 10, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Hai nút hành động Escrow của khách thuê
                  Row(
                    children: [
                      // Nút hủy cọc tự động
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _onCancelDeposit(context, ref),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFC62828),
                            side: const BorderSide(color: Color(0xFFFFCDD2)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.button),
                            ),
                          ),
                          icon: const Icon(Icons.cancel_outlined, size: 16),
                          label: const Text('Hủy cọc',
                              style: TextStyle(fontSize: 11)),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      // Nút xác nhận giải ngân
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _onReleaseDeposit(context, ref),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.button),
                            ),
                          ),
                          icon:
                              const Icon(Icons.check_circle_outline, size: 16),
                          label: const Text('Xác nhận thuê',
                              style: TextStyle(fontSize: 11)),
                        ),
                      ),
                    ],
                  ),
                ],

                if (rental.status == RentalStatus.active &&
                    payableBill != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: palette.dangerContainer,
                      borderRadius: BorderRadius.circular(AppRadius.button),
                      border: Border.all(
                          color: palette.danger.withValues(alpha: 0.45)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: palette.danger, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Chủ trọ đã tạo hóa đơn tháng ${payableBill.billingMonth.month}/${payableBill.billingMonth.year}: ${payableBill.totalAmount.toVnd()}đ. Vui lòng thanh toán trước ${_fmtDate(payableBill.dueDate)}.',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: palette.danger,
                              fontSize: 11,
                              height: 1.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: onViewBills,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: palette.danger,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Thanh toán ngay',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (rental.status == RentalStatus.active &&
                    payableBill == null &&
                    waitingApprovalBill != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: palette.warningContainer,
                      borderRadius: BorderRadius.circular(AppRadius.button),
                      border: Border.all(
                          color: palette.warning.withValues(alpha: 0.45)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.hourglass_top_outlined,
                            color: palette.warning, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Bạn đã báo chuyển khoản hóa đơn ${waitingApprovalBill.totalAmount.toVnd()}đ. Đang chờ chủ trọ xác nhận.',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: palette.warning,
                              fontSize: 11,
                              height: 1.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        TextButton(
                          onPressed: onViewBills,
                          child: const Text('Xem'),
                        ),
                      ],
                    ),
                  ),
                ],
                if (rental.status == RentalStatus.active) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: daysLeft < 30
                          ? AppColors.overdue
                          : AppColors.available.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 14,
                          color: daysLeft < 30
                              ? AppColors.onOverdue
                              : AppColors.onAvailable,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Còn $daysLeft ngày đến hạn hợp đồng',
                          style: AppTypography.labelSM.copyWith(
                            color: daysLeft < 30
                                ? AppColors.onOverdue
                                : AppColors.onAvailable,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (rental.status == RentalStatus.cancelled) ...[
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton.icon(
                    onPressed: () =>
                        _onDeleteCancelledTransaction(context, ref),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFC62828),
                      side: const BorderSide(color: Color(0xFFFFCDD2)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.button),
                      ),
                    ),
                    icon: const Icon(Icons.delete_forever_outlined, size: 18),
                    label: const Text('Xóa giao dịch',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
                if (rental.status != RentalStatus.pending) ...[
                  const SizedBox(height: AppSpacing.sm),
                  GestureDetector(
                    onTap: () => _showReviewBottomSheet(context, ref),
                    child: Container(
                      width: double.infinity,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(AppRadius.button),
                        border: Border.all(
                            color: const Color(0xFFFFB300), width: 1.5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.star_outline_rounded,
                              size: 18, color: Color(0xFFFF8F00)),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'Đánh giá chủ trọ',
                            style: AppTypography.button.copyWith(
                              color: const Color(0xFFFF8F00),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                // View bills button
                GestureDetector(
                  onTap: onViewBills,
                  child: Container(
                    width: double.infinity,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.receipt_long_outlined,
                            size: 18, color: AppColors.primary),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Xem hóa đơn',
                          style: AppTypography.button.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showReviewBottomSheet(BuildContext context, WidgetRef ref) {
    double selectedRating = 5.0;
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Handle line
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.outlineVariant,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Title
                    Text(
                      'Đánh giá Chủ trọ',
                      style: AppTypography.titleMD.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Nhận xét của bạn về trải nghiệm tại "${rental.roomTitle}"',
                      style: AppTypography.bodySM,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Star Selector
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final starValue = index + 1.0;
                        final isSelected = starValue <= selectedRating;
                        return GestureDetector(
                          onTap: () {
                            setModalState(() {
                              selectedRating = starValue;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              isSelected ? Icons.star : Icons.star_border,
                              color: const Color(0xFFFFB300),
                              size: 40,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Star label description
                    Text(
                      _getRatingDescription(selectedRating),
                      style: AppTypography.labelSM.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Comment Input
                    TextField(
                      controller: commentController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText:
                            'Hãy chia sẻ cảm nhận chân thực của bạn về thái độ phục vụ, tính chính xác và chất lượng phòng trọ...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.outlineVariant),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: AppColors.primary, width: 2),
                        ),
                        contentPadding: const EdgeInsets.all(AppSpacing.md),
                      ),
                      style: AppTypography.bodyMD,
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Submit Button
                    ElevatedButton(
                      onPressed: () async {
                        final comment = commentController.text.trim();
                        if (comment.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Vui lòng nhập nhận xét của bạn!'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                          return;
                        }

                        // Close bottom sheet
                        Navigator.pop(ctx);

                        // Submit review
                        try {
                          final reviewType =
                              rental.status == RentalStatus.active
                                  ? 'Verified Tenant Review'
                                  : 'Cancelled Booking Review';

                          await ref.read(reviewControllerProvider).submitReview(
                                landlordId: rental.landlordId,
                                roomId: rental.roomId,
                                roomTitle: rental.roomTitle,
                                tenantId: rental.tenantId,
                                tenantName: rental.tenantName,
                                rating: selectedRating,
                                comment: comment,
                                type: reviewType,
                              );

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Gửi đánh giá bảo chứng thành công! Cảm ơn bạn. 🎉'),
                                backgroundColor: Color(0xFF2E7D32),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Lỗi gửi đánh giá: $e'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding:
                            const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.button),
                        ),
                      ),
                      child: const Text('Gửi đánh giá ngay',
                          style: AppTypography.button),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _getRatingDescription(double rating) {
    if (rating <= 1.0) return 'Rất không hài lòng 😞';
    if (rating <= 2.0) return 'Không hài lòng 😐';
    if (rating <= 3.0) return 'Bình thường 🙂';
    if (rating <= 4.0) return 'Hài lòng 😊';
    return 'Tuyệt vời, cực kỳ hài lòng! 😍';
  }

  Future<void> _onReleaseDeposit(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận thuê phòng?'),
        content: const Text(
            'Bạn xác nhận đã ký hợp đồng thành công và đồng ý giải ngân 500.000đ tiền cọc giữ chỗ cho chủ trọ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                TextButton.styleFrom(foregroundColor: const Color(0xFF2E7D32)),
            child: const Text('Đồng ý giải ngân'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref
            .read(bookingControllerProvider)
            .releaseDeposit(rentalId: rental.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Giải ngân cọc và bắt đầu hợp đồng thành công! 🎉'),
              backgroundColor: Color(0xFF2E7D32),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  Future<void> _onCancelDeposit(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hủy cọc giữ chỗ?'),
        content: const Text(
            'Bạn có chắc chắn muốn hủy đặt cọc giữ chỗ phòng trọ này? 500.000đ sẽ được tự động hoàn lại 100% về ví của bạn ngay lập tức!'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                TextButton.styleFrom(foregroundColor: const Color(0xFFC62828)),
            child: const Text('Đồng ý hủy cọc'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(bookingControllerProvider).cancelDeposit(
              rentalId: rental.id,
              roomId: rental.roomId,
            );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Đã hủy đặt cọc giữ chỗ và hoàn tiền thành công! 💸'),
              backgroundColor: Color(0xFF2E7D32),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  Future<void> _onDeleteCancelledTransaction(
      BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa lịch sử giao dịch?'),
        content: const Text(
            'Bạn có chắc chắn muốn xóa lịch sử giao dịch đặt cọc đã hủy này khỏi danh sách hiển thị của bạn?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                TextButton.styleFrom(foregroundColor: const Color(0xFFC62828)),
            child: const Text('Xóa vĩnh viễn'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(bookingControllerProvider).hideOrDeleteRental(
              rentalId: rental.id,
              roomId: rental.roomId,
              tenantId: rental.tenantId,
              isLandlord: false,
            );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã xóa lịch sử giao dịch thành công!'),
              backgroundColor: Color(0xFF2E7D32),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  Widget _infoRow(IconData icon, String text, {Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.onSurfaceVariant),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodyMD.copyWith(color: valueColor),
          ),
        ),
      ],
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _RentalShimmerList extends StatelessWidget {
  const _RentalShimmerList();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: AppColors.surfaceContainerLow,
          highlightColor: AppColors.surfaceContainerLowest,
          child: Container(
            height: 220,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
          ),
        );
      },
    );
  }
}
