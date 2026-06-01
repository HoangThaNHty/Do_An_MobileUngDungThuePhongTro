import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../../config/constants.dart';
import '../../../controllers/providers/bill_provider.dart';
import '../../../models/entities/rental.dart';
import '../../../models/entities/user.dart';
import '../../../models/entities/bill.dart';
import '../../widgets/common/app_button.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/booking_controller.dart';
import '../../../controllers/chat_controller.dart';

class ManageTenantsScreen extends ConsumerWidget {
  const ManageTenantsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rentalsAsync = ref.watch(allRentalsProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Quản lý người thuê'),
        automaticallyImplyLeading: false,
      ),
      body: rentalsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (rentals) {
          // Lọc chắc chắn chỉ hiển thị hợp đồng thuộc về Chủ trọ đang đăng nhập
          final landlordRentals = rentals.where((r) => r.landlordId == user?.id).toList();

          if (landlordRentals.isEmpty) {
            return _buildEmpty();
          }
          return Column(
            children: [
              // Summary bar
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                color: AppColors.surfaceContainerLow,
                child: Row(
                  children: [
                    const Icon(Icons.people_outline,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '${landlordRentals.length} người đang thuê',
                      style: AppTypography.bodyMD
                          .copyWith(color: AppColors.primary),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: landlordRentals.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    return _TenantCard(rental: landlordRentals[index]);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 72, color: AppColors.outlineVariant),
          SizedBox(height: AppSpacing.md),
          Text('Chưa có người thuê', style: AppTypography.titleSM),
        ],
      ),
    );
  }
}

class _TenantCard extends ConsumerWidget {
  final Rental rental;

  const _TenantCard({required this.rental});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userByIdProvider(rental.tenantId));
    final bookingCtrl = ref.read(bookingControllerProvider);

    // Logic tự động kiểm tra quá hạn (Timeout check): Ngày hẹn gặp + 48 giờ
    final deadline = rental.startDate.add(const Duration(hours: 48));
    final isOverdue = DateTime.now().isAfter(deadline);

    if (rental.status == RentalStatus.pending && isOverdue) {
      // Tự động giải ngân cho chủ trọ khi khách im lặng bùng hẹn quá 48h
      Future.microtask(() async {
        try {
          await bookingCtrl.releaseDeposit(rentalId: rental.id);
        } catch (_) {}
      });
    }

    return userAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (e, _) => Center(child: Text('Lỗi tải thông tin: $e')),
      data: (user) {
        if (user == null) {
          return const Center(child: Text('Không tìm thấy người dùng'));
        }

        String statusText = 'ĐANG THUÊ';

        if (rental.status == RentalStatus.pending) {
          statusText = 'CỌC GIỮ CHỖ';
        } else if (rental.status == RentalStatus.cancelled) {
          statusText = 'ĐÃ HỦY';
        } else if (rental.status == RentalStatus.expired) {
          statusText = 'HẾT HẠN';
        }

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppRadius.card),
            boxShadow: const [AppShadows.card],
          ),
          child: Column(
            children: [
              // Header & Status
               GestureDetector(
                onTap: () => _showTenantProfile(context, user),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: rental.status == RentalStatus.pending
                          ? [const Color(0xFFEF6C00), const Color(0xFFFFB74D)]
                          : rental.status == RentalStatus.cancelled
                              ? [const Color(0xFFC62828), const Color(0xFFE57373)]
                              : [AppColors.primary, AppColors.primaryContainer],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppRadius.card),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person_outline, color: AppColors.onPrimary, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              rental.tenantName,
                              style: AppTypography.titleSM.copyWith(color: AppColors.onPrimary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Nhấn để xem chi tiết hồ sơ người thuê ➔',
                              style: AppTypography.labelSM.copyWith(
                                color: AppColors.onPrimary.withValues(alpha: 0.8),
                                fontSize: 9,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      const Icon(
                        Icons.info_outline,
                        color: AppColors.onPrimary,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
              ),
              // Body Content
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Room Title
                    Text(
                      rental.roomTitle,
                      style: AppTypography.titleSM.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    
                    // Basic Rows
                    _infoRow(Icons.location_on_outlined, rental.roomAddress),
                    const SizedBox(height: AppSpacing.xs),
                    _infoRow(
                      Icons.calendar_today_outlined,
                      rental.status == RentalStatus.pending
                          ? 'Ngày hẹn gặp: ${_fmtDate(rental.startDate)}'
                          : 'Từ ${_fmtDate(rental.startDate)} đến ${_fmtDate(rental.endDate)}',
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    
                    // Phone number & Call/Chat Icons
                    Row(
                      children: [
                        const Icon(Icons.phone_outlined, size: 15, color: AppColors.onSurfaceVariant),
                        const SizedBox(width: 6),
                        Text(user.phone, style: AppTypography.bodyMD),
                        const Spacer(),
                        // Nút nhắn tin Chat nhanh
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.chat_bubble_outline, size: 18, color: AppColors.primary),
                          onPressed: () async {
                            final currentUser = ref.read(currentUserProvider);
                            if (currentUser != null) {
                              // Hiển thị chỉ báo đang tải
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (ctx) => const Center(
                                  child: CircularProgressIndicator(color: AppColors.primary),
                                ),
                              );
                              
                              try {
                                final chatId = await ref.read(chatControllerProvider).getOrCreateChatRoom(
                                      tenant: user,
                                      landlord: currentUser,
                                    );
                                if (context.mounted) {
                                  Navigator.of(context).pop(); // Đóng chỉ báo đang tải
                                  context.push('/chat/$chatId');
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  Navigator.of(context).pop(); // Đóng chỉ báo đang tải
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Lỗi khi mở cuộc trò chuyện: $e')),
                                  );
                                }
                              }
                            } else {
                              context.push('/chat-list');
                            }
                          },
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        // Nút gọi điện trực tiếp
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.call, size: 18, color: Color(0xFF2E7D32)),
                          onPressed: () async {
                            final Uri launchUri = Uri(
                              scheme: 'tel',
                              path: user.phone,
                            );
                            try {
                              await launchUrl(launchUri);
                            } catch (_) {
                              await Clipboard.setData(ClipboardData(text: user.phone));
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Thiết bị không hỗ trợ gọi điện. Số điện thoại đã được sao chép!'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    
                    // Rent money
                    _infoRow(
                      Icons.payments_outlined,
                      rental.status == RentalStatus.pending
                          ? 'Tiền cọc giữ phòng: 500.000đ (Ví trung gian bảo lãnh)'
                          : 'Tiền thuê hàng tháng: ${_formatCurrency(rental.monthlyRent)}đ/tháng',
                      valueColor: rental.status == RentalStatus.pending
                          ? const Color(0xFFEF6C00)
                          : AppColors.primary,
                    ),
                    
                    // ─── Phần hồ sơ mở rộng của người đặt cọc ───
                    if (rental.status == RentalStatus.pending) ...[
                      const Divider(height: AppSpacing.md),
                      Text(
                        'Hồ sơ người tìm phòng:',
                        style: AppTypography.labelSM.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      
                      // Gender, Birth Year
                      Row(
                        children: [
                          Expanded(
                            child: _infoRow(
                              Icons.transgender_outlined,
                              'Giới tính: ${user.gender ?? 'Chưa cập nhật'}',
                            ),
                          ),
                          Expanded(
                            child: _infoRow(
                              Icons.cake_outlined,
                              'Năm sinh: ${user.birthYear ?? 'Chưa cập nhật'}',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      
                      // Hometown, Occupation
                      _infoRow(
                        Icons.home_outlined,
                        'Quê quán: ${user.hometown ?? 'Chưa cập nhật'}',
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      _infoRow(
                        Icons.work_outline,
                        'Công việc: ${user.occupation ?? 'Chưa cập nhật'}',
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      
                      // Bio
                      if (user.bio != null && user.bio!.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(AppRadius.button),
                          ),
                          child: Text(
                            'Giới thiệu: "${user.bio}"',
                            style: AppTypography.bodySM.copyWith(
                              fontStyle: FontStyle.italic,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: AppSpacing.md),
                      
                      // Nút chủ trọ chủ động hủy/hoàn cọc cho khách
                      OutlinedButton.icon(
                        onPressed: () => _onCancelDepositByLandlord(context, ref),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFC62828),
                          side: const BorderSide(color: Color(0xFFFFCDD2)),
                          minimumSize: const Size(double.infinity, 40),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.button),
                          ),
                        ),
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: const Text('Đồng ý hoàn cọc & Hủy giữ phòng', style: TextStyle(fontSize: 12)),
                      ),
                    ],

                    if (rental.status == RentalStatus.active) ...[
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm, vertical: 4),
                        decoration: BoxDecoration(
                          color: rental.remainingDays < 30
                              ? AppColors.overdue
                              : AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(AppRadius.button),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              size: 13,
                              color: rental.remainingDays < 30
                                  ? AppColors.onOverdue
                                  : AppColors.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Thời gian hợp đồng còn lại: ${rental.remainingDays} ngày',
                              style: AppTypography.bodySM.copyWith(
                                color: rental.remainingDays < 30
                                    ? AppColors.onOverdue
                                    : AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (rental.status == RentalStatus.active) ...[
                      const SizedBox(height: AppSpacing.sm),
                      ElevatedButton.icon(
                        onPressed: () => _showBillHistoryBottomSheet(context, ref),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          minimumSize: const Size(double.infinity, 44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.button),
                          ),
                        ),
                        icon: const Icon(Icons.receipt_long_outlined, size: 18),
                        label: const Text('Lịch sử Hóa đơn', style: AppTypography.button),
                      ),
                    ],
                    if (rental.status == RentalStatus.cancelled) ...[
                      const SizedBox(height: AppSpacing.sm),
                      OutlinedButton.icon(
                        onPressed: () => _onDeleteCancelledTransaction(context, ref),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFC62828),
                          side: const BorderSide(color: Color(0xFFFFCDD2)),
                          minimumSize: const Size(double.infinity, 44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.button),
                          ),
                        ),
                        icon: const Icon(Icons.delete_forever_outlined, size: 18),
                        label: const Text('Xóa lịch sử giao dịch', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _fmtDateTime(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} lúc ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  void _showBillHistoryBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.md),
              // Drag handle
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
              Text(
                'Lịch sử Hóa đơn',
                style: AppTypography.titleMD.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              Text(
                'Phòng: ${rental.roomTitle}',
                style: AppTypography.bodySM,
              ),
              const SizedBox(height: AppSpacing.md),
              const Divider(height: 1),
              Expanded(
                child: Consumer(
                  builder: (context, ref, _) {
                    final billsAsync = ref.watch(tenantBillsByRoomProvider(rental.roomId));
                    return billsAsync.when(
                      loading: () => const Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                      error: (e, _) => Center(child: Text('Lỗi: $e')),
                      data: (bills) {
                        if (bills.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.receipt_long_outlined,
                                  size: 64,
                                  color: AppColors.outlineVariant,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  'Chưa có hóa đơn nào cho phòng này',
                                  style: AppTypography.bodyMD.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        // Sắp xếp hóa đơn mới nhất lên đầu
                        final sortedBills = List<Bill>.from(bills)
                          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                        return ListView.separated(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          itemCount: sortedBills.length,
                          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (context, index) {
                            final bill = sortedBills[index];
                            final isDeposit = bill.electricityAmount == 0 && bill.waterAmount == 0 && bill.otherAmount == 0;
                            final titleText = isDeposit
                                ? 'Hóa đơn đặt cọc giữ chỗ'
                                : 'Hóa đơn tháng ${bill.billingMonth.month}/${bill.billingMonth.year}';

                            Color statusColor = const Color(0xFFC62828);
                            String statusLabel = 'Chưa thanh toán';
                            if (bill.status == BillStatus.unpaid && bill.paymentSubmitted) {
                              statusColor = Colors.orange.shade900;
                              statusLabel = 'Khách báo đã chuyển tiền - Cần xác nhận ⚠️';
                            } else if (bill.status == BillStatus.paid) {
                              statusColor = const Color(0xFF2E7D32);
                              statusLabel = 'Đã thanh toán';
                            } else if (bill.status == BillStatus.overdue) {
                              statusColor = const Color(0xFFE65100);
                              statusLabel = 'Quá hạn';
                            }

                            return Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerLowest,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
                                boxShadow: const [AppShadows.card],
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          titleText,
                                          style: AppTypography.titleSM.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '📅 Lập lúc: ${_fmtDateTime(bill.createdAt)}',
                                          style: AppTypography.labelSM.copyWith(
                                            color: AppColors.onSurfaceVariant,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Tổng tiền: ${_formatCurrency(bill.totalAmount)}đ',
                                          style: AppTypography.bodyMD.copyWith(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: statusColor.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            statusLabel,
                                            style: AppTypography.labelSM.copyWith(
                                              color: statusColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),
                                        if (bill.status == BillStatus.unpaid && bill.paymentSubmitted) ...[
                                          const SizedBox(height: 12),
                                          const Divider(color: AppColors.outlineVariant, thickness: 0.5),
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              ElevatedButton.icon(
                                                onPressed: () => _onRejectPayment(context, ref, bill),
                                                icon: const Icon(Icons.close, size: 16),
                                                label: const Text('Từ chối'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.red[50],
                                                  foregroundColor: Colors.red[900],
                                                  elevation: 0,
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                    side: BorderSide(color: Colors.red.shade200),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              ElevatedButton.icon(
                                                onPressed: () => _onApprovePayment(context, ref, bill),
                                                icon: const Icon(Icons.check, size: 16),
                                                label: const Text('Duyệt'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.green[50],
                                                  foregroundColor: Colors.green[900],
                                                  elevation: 0,
                                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                    side: BorderSide(color: Colors.green.shade200),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  if (bill.status == BillStatus.unpaid && !bill.paymentSubmitted)
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Color(0xFFC62828)),
                                      onPressed: () => _onDeleteBill(context, bill),
                                    ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _onDeleteBill(BuildContext context, Bill bill) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hủy hóa đơn này?'),
        content: Text('Bạn có chắc chắn muốn hủy vĩnh viễn hóa đơn chưa thanh toán của phòng ${bill.roomTitle}? Khách thuê sẽ không còn nhận được thông báo này nữa.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFC62828)),
            child: const Text('Đồng ý hủy'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseDatabase.instance.ref('bills/${bill.id}').remove();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã hủy và xóa hóa đơn thành công!'),
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
    }
  }

  Future<void> _onApprovePayment(BuildContext context, WidgetRef ref, Bill bill) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận nhận tiền?'),
        content: Text('Bạn có chắc chắn muốn Duyệt hóa đơn ${_formatCurrency(bill.totalAmount)}đ của phòng ${bill.roomTitle}? Trạng thái hóa đơn sẽ chuyển thành Đã thanh toán.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF2E7D32)),
            child: const Text('Duyệt nhận tiền'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final db = FirebaseDatabase.instance;
        await db.ref('bills/${bill.id}').update({
          'status': BillStatus.paid.name,
          'paymentSubmitted': false,
          'paidDate': DateTime.now().toIso8601String(),
        });

        ref.invalidate(billsProvider(bill.tenantId));

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã phê duyệt hóa đơn thành công! Trạng thái cập nhật ĐÃ THANH TOÁN thời gian thực.'),
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
    }
  }

  Future<void> _onRejectPayment(BuildContext context, WidgetRef ref, Bill bill) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Từ chối giao dịch?'),
        content: Text('Bạn có chắc chắn muốn Từ chối thanh toán của phòng ${bill.roomTitle}? Hóa đơn sẽ trả về trạng thái Chưa thanh toán và thông báo lại cho khách thuê.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFC62828)),
            child: const Text('Từ chối'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final db = FirebaseDatabase.instance;
        await db.ref('bills/${bill.id}').update({
          'paymentSubmitted': false,
        });

        ref.invalidate(billsProvider(bill.tenantId));

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã từ chối giao dịch thành công. Trạng thái đã trả về CHƯA THANH TOÁN.'),
              backgroundColor: Color(0xFFC62828),
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
    }
  }

  Future<void> _onDeleteCancelledTransaction(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa lịch sử giao dịch?'),
        content: const Text('Bạn có chắc chắn muốn xóa lịch sử giao dịch đặt cọc đã hủy này khỏi danh sách hiển thị của bạn?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFC62828)),
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
              isLandlord: true,
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
            SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  Future<void> _onCancelDepositByLandlord(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đồng ý Hoàn cọc & Hủy phòng?'),
        content: const Text('Chủ trọ xác nhận hủy lịch hẹn này? Số tiền 500.000đ cọc giữ phòng của khách hàng sẽ được hoàn trả lại 100% về tài khoản của họ và phòng trọ của bạn sẽ được mở lại trạng thái Còn trống.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Đóng')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFC62828)),
            child: const Text('Xác nhận hoàn cọc'),
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
              content: Text('Đã đồng ý hủy giữ phòng và tự động hoàn trả cọc thành công! 💸'),
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

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  void _showTenantProfile(BuildContext context, AppUser user) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 10,
          backgroundColor: AppColors.surfaceContainerLowest,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dialog Header with Gradient background and Avatar
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryContainer],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: AppSpacing.md),
                child: Column(
                  children: [
                    // Avatar or Person Icon
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 34,
                        backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                            ? NetworkImage(user.avatarUrl!)
                            : null,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                            ? const Icon(Icons.person, size: 40, color: AppColors.primary)
                            : null,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      user.fullName,
                      style: AppTypography.titleMD.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      style: AppTypography.bodySM.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              // Profile details body
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    _profileDetailRow(Icons.transgender_outlined, 'Giới tính', user.gender ?? 'Chưa cập nhật'),
                    const Divider(height: AppSpacing.md, thickness: 0.5),
                    _profileDetailRow(Icons.cake_outlined, 'Năm sinh', user.birthYear != null ? user.birthYear.toString() : 'Chưa cập nhật'),
                    const Divider(height: AppSpacing.md, thickness: 0.5),
                    _profileDetailRow(Icons.phone_outlined, 'Số điện thoại', user.phone),
                    const Divider(height: AppSpacing.md, thickness: 0.5),
                    _profileDetailRow(Icons.home_outlined, 'Quê quán', user.hometown ?? 'Chưa cập nhật'),
                    const Divider(height: AppSpacing.md, thickness: 0.5),
                    _profileDetailRow(Icons.work_outline, 'Nghề nghiệp', user.occupation ?? 'Chưa cập nhật'),
                    
                    if (user.bio != null && user.bio!.isNotEmpty) ...[
                      const Divider(height: AppSpacing.md, thickness: 0.5),
                      const SizedBox(height: AppSpacing.xs),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Giới thiệu bản thân:',
                              style: AppTypography.labelSM.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '"${user.bio}"',
                              style: AppTypography.bodyMD.copyWith(
                                fontStyle: FontStyle.italic,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Close button
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
                child: SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    text: 'Đóng',
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _profileDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '$label:',
          style: AppTypography.bodyMD.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            value,
            style: AppTypography.bodyMD.copyWith(
              color: AppColors.onSurface,
            ),
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
