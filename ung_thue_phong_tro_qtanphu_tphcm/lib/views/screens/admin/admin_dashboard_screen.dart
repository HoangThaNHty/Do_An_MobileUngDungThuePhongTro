import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/constants.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/providers/bill_provider.dart';
import '../../../controllers/providers/room_provider.dart';
import '../../../models/entities/bill.dart';
import '../../../models/entities/rental.dart';
import '../../../models/entities/room.dart';
import '../../../models/entities/user.dart';

final adminUsersProvider = StreamProvider<List<AppUser>>((ref) {
  return FirebaseDatabase.instance.ref('users').onValue.map((event) {
    final snapshot = event.snapshot;
    if (!snapshot.exists) return [];

    final data = snapshot.value as Map<dynamic, dynamic>;
    final users = <AppUser>[];
    data.forEach((key, value) {
      final map = Map<String, dynamic>.from(value as Map);
      users.add(
        AppUser(
          id: map['id'] ?? key.toString(),
          fullName: map['fullName'] ?? '',
          email: map['email'] ?? '',
          phone: map['phone'] ?? '',
          avatarUrl: map['avatarUrl'] as String?,
          role: UserRole.values.firstWhere(
            (role) => role.name == map['role'],
            orElse: () => UserRole.tenant,
          ),
          createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
              DateTime.now(),
          gender: map['gender'] as String?,
          birthYear: map['birthYear'] as int?,
          hometown: map['hometown'] as String?,
          occupation: map['occupation'] as String?,
          bio: map['bio'] as String?,
          averageRating: (map['averageRating'] as num?)?.toDouble(),
        ),
      );
    });
    users.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return users;
  });
});

final adminRentalsProvider = StreamProvider<List<Rental>>((ref) {
  return FirebaseDatabase.instance.ref('rentals').onValue.map((event) {
    final snapshot = event.snapshot;
    if (!snapshot.exists) return [];

    final data = snapshot.value as Map<dynamic, dynamic>;
    final rentals = <Rental>[];
    data.forEach((key, value) {
      final map = Map<String, dynamic>.from(value as Map);
      rentals.add(Rental.fromMap(map, key.toString()));
    });
    rentals.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return rentals;
  });
});

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(adminUsersProvider);
    final billsAsync = ref.watch(allBillsProvider);
    final rentalsAsync = ref.watch(adminRentalsProvider);
    final roomState = ref.watch(roomProvider);

    final users =
        usersAsync.maybeWhen(data: (value) => value, orElse: () => []);
    final bills =
        billsAsync.maybeWhen(data: (value) => value, orElse: () => []);
    final rentals =
        rentalsAsync.maybeWhen(data: (value) => value, orElse: () => []);
    final rooms = roomState.rooms;
    final isLoading = usersAsync.isLoading ||
        billsAsync.isLoading ||
        rentalsAsync.isLoading ||
        roomState.isLoading;

    final landlords = users.where((user) => user.role == UserRole.landlord);
    final tenants = users.where((user) => user.role == UserRole.tenant);
    final pendingPaymentBills = bills.where(
      (bill) => bill.status == BillStatus.unpaid && bill.paymentSubmitted,
    );
    final unpaidBills = bills.where(
      (bill) => bill.status == BillStatus.unpaid && !bill.paymentSubmitted,
    );
    final availableRooms =
        rooms.where((room) => room.status == RoomStatus.available);
    final rentedRooms = rooms.where((room) => room.status == RoomStatus.rented);
    final activeRentals =
        rentals.where((rental) => rental.status == RentalStatus.active);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Admin giám sát'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(adminUsersProvider);
          ref.invalidate(adminRentalsProvider);
          ref.invalidate(allBillsProvider);
          await Future.delayed(const Duration(milliseconds: 400));
        },
        child: CustomScrollView(
          slivers: [
            if (isLoading)
              const SliverToBoxAdapter(
                child: LinearProgressIndicator(color: AppColors.primary),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tổng quan hệ thống',
                      style: AppTypography.headlineMD.copyWith(
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Admin chỉ giám sát dữ liệu, không duyệt thanh toán hoặc sửa giao dịch thay chủ trọ.',
                      style: AppTypography.bodySM.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: AppSpacing.sm,
                  mainAxisSpacing: AppSpacing.sm,
                  childAspectRatio: 1.65,
                ),
                delegate: SliverChildListDelegate.fixed([
                  _AdminStatTile(
                    label: 'Tài khoản',
                    value: '${users.length}',
                    icon: Icons.groups_outlined,
                    color: AppColors.primary,
                  ),
                  _AdminStatTile(
                    label: 'Chủ trọ',
                    value: '${landlords.length}',
                    icon: Icons.home_work_outlined,
                    color: const Color(0xFF2E7D32),
                  ),
                  _AdminStatTile(
                    label: 'Người thuê',
                    value: '${tenants.length}',
                    icon: Icons.person_search_outlined,
                    color: const Color(0xFF1565C0),
                  ),
                  _AdminStatTile(
                    label: 'Phòng',
                    value: '${rooms.length}',
                    icon: Icons.apartment_outlined,
                    color: const Color(0xFF6A1B9A),
                  ),
                  _AdminStatTile(
                    label: 'Phòng trống',
                    value: '${availableRooms.length}',
                    icon: Icons.meeting_room_outlined,
                    color: const Color(0xFF00897B),
                  ),
                  _AdminStatTile(
                    label: 'Đang thuê',
                    value: '${rentedRooms.length}',
                    icon: Icons.key_outlined,
                    color: const Color(0xFFEF6C00),
                  ),
                  _AdminStatTile(
                    label: 'HĐ chờ duyệt',
                    value: '${pendingPaymentBills.length}',
                    icon: Icons.pending_actions_outlined,
                    color: const Color(0xFFC62828),
                  ),
                  _AdminStatTile(
                    label: 'HĐ chưa trả',
                    value: '${unpaidBills.length}',
                    icon: Icons.receipt_long_outlined,
                    color: const Color(0xFF5D4037),
                  ),
                ]),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    _AdminSection(
                      title: 'Tài khoản gần đây',
                      emptyText: 'Chưa có tài khoản',
                      children: users.take(5).map((user) {
                        return _AdminListRow(
                          icon: user.role == UserRole.landlord
                              ? Icons.home_work_outlined
                              : user.role == UserRole.admin
                                  ? Icons.admin_panel_settings_outlined
                                  : Icons.person_outline,
                          title: user.fullName,
                          subtitle: '${user.email} • ${_roleLabel(user.role)}',
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _AdminSection(
                      title: 'Hóa đơn cần chủ trọ xử lý',
                      emptyText: 'Không có hóa đơn chờ duyệt',
                      children: pendingPaymentBills.take(5).map((bill) {
                        return _AdminListRow(
                          icon: Icons.pending_actions_outlined,
                          title: bill.tenantName,
                          subtitle:
                              '${bill.roomTitle} • ${_formatCurrency(bill.totalAmount)}đ',
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _AdminSection(
                      title: 'Hợp đồng đang hoạt động',
                      emptyText: 'Chưa có hợp đồng đang thuê',
                      children: activeRentals.take(5).map((rental) {
                        return _AdminListRow(
                          icon: Icons.key_outlined,
                          title: rental.tenantName,
                          subtitle:
                              '${rental.roomTitle} • ${_formatCurrency(rental.monthlyRent)}đ/tháng',
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _roleLabel(UserRole role) {
    return switch (role) {
      UserRole.admin => 'Admin',
      UserRole.landlord => 'Chủ trọ',
      UserRole.tenant => 'Người thuê',
    };
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
  }
}

class _AdminStatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _AdminStatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border:
            Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
        boxShadow: const [AppShadows.card],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: AppTypography.titleMD.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  label,
                  style: AppTypography.bodySM.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminSection extends StatelessWidget {
  final String title;
  final String emptyText;
  final List<Widget> children;

  const _AdminSection({
    required this.title,
    required this.emptyText,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: const [AppShadows.card],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.titleSM),
          const SizedBox(height: AppSpacing.sm),
          if (children.isEmpty)
            Text(
              emptyText,
              style: AppTypography.bodySM.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            )
          else
            ...children,
        ],
      ),
    );
  }
}

class _AdminListRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _AdminListRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMD.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: AppTypography.bodySM.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
