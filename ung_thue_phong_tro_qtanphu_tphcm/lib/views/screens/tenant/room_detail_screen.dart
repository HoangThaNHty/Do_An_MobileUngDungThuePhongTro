import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../config/constants.dart';
import '../../../controllers/providers/room_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/status_chips.dart';
import '../../../models/entities/room.dart';

class RoomDetailScreen extends ConsumerStatefulWidget {
  final String roomId;

  const RoomDetailScreen({super.key, required this.roomId});

  @override
  ConsumerState<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends ConsumerState<RoomDetailScreen> {
  int _currentImageIndex = 0;
  final PageController _pageCtrl = PageController();

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final room = ref.watch(roomByIdProvider(widget.roomId));

    if (room == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết phòng')),
        body: const Center(child: Text('Không tìm thấy phòng')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          // ─── Image Carousel (SliverAppBar) ──────
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppColors.surface,
            leading: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, size: 20),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Image carousel
                  PageView.builder(
                    controller: _pageCtrl,
                    itemCount: room.images.isEmpty ? 1 : room.images.length,
                    onPageChanged: (i) =>
                        setState(() => _currentImageIndex = i),
                    itemBuilder: (context, index) {
                      if (room.images.isEmpty) {
                        return Container(
                          color: AppColors.surfaceContainerLow,
                          child: const Icon(
                            Icons.home_outlined,
                            size: 80,
                            color: AppColors.onSurfaceVariant,
                          ),
                        );
                      }
                      return CachedNetworkImage(
                        imageUrl: room.images[index],
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: AppColors.surfaceContainerLow,
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: AppColors.surfaceContainerLow,
                          child: const Icon(Icons.home_outlined, size: 80),
                        ),
                      );
                    },
                  ),
                  // Page indicator dots
                  if (room.images.length > 1)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          room.images.length,
                          (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin:
                                const EdgeInsets.symmetric(horizontal: 3),
                            width: i == _currentImageIndex ? 20 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: i == _currentImageIndex
                                  ? AppColors.primary
                                  : AppColors.onPrimary.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ─── Content ────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + Status
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          room.title,
                          style: AppTypography.titleMD,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      RoomStatusChip(status: room.status),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Price
                  Text(
                    '${_formatCurrency(room.price)}đ/tháng',
                    style: AppTypography.headlineMD.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Address
                  _infoRow(Icons.location_on_outlined, room.address),
                  const SizedBox(height: AppSpacing.xs),
                  _infoRow(Icons.straighten_outlined,
                      '${room.area.toStringAsFixed(0)} m²'),
                  const SizedBox(height: AppSpacing.xs),
                  _infoRow(Icons.visibility_outlined,
                      '${room.viewCount} lượt xem'),

                  const SizedBox(height: AppSpacing.lg),

                  // Amenities
                  Text(AppStrings.amenities,
                      style: AppTypography.titleSM),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: room.amenities
                        .map((a) => _amenityChip(a))
                        .toList(),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Description
                  Text(AppStrings.description,
                      style: AppTypography.titleSM),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    room.description,
                    style: AppTypography.bodyMD,
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Landlord card
                  _buildLandlordCard(context, room),

                  const SizedBox(height: 100), // CTA space
                ],
              ),
            ),
          ),
        ],
      ),

      // ─── Bottom CTA ─────────────────────────────
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md + MediaQuery.of(context).padding.bottom,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          boxShadow: [AppShadows.bottomSheet],
        ),
        child: Row(
          children: [
            // Price summary
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Giá thuê', style: AppTypography.bodySM),
                  Text(
                    '${_formatCurrency(room.price)}đ',
                    style: AppTypography.titleMD.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // CTA Button
            Expanded(
              flex: 2,
              child: AppButton(
                text: room.status == RoomStatus.available
                    ? 'Liên hệ thuê phòng'
                    : 'Phòng đã có người thuê',
                onPressed: room.status == RoomStatus.available
                    ? () => context
                        .go('/tenant/room/${room.id}/contact/${room.landlordId}')
                    : null,
                icon: Icons.phone_outlined,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.onSurfaceVariant),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(text, style: AppTypography.bodyMD),
        ),
      ],
    );
  }

  Widget _amenityChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline,
              size: 14, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.labelSM.copyWith(
              color: AppColors.primary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLandlordCard(BuildContext context, Room room) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary.withOpacity(0.12),
            child: const Icon(
              Icons.person_outline,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Chủ nhà', style: AppTypography.bodySM),
                Text('Xem thông tin liên hệ',
                    style: AppTypography.titleSM),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.primary,
            ),
            onPressed: () => context
                .go('/tenant/room/${room.id}/contact/${room.landlordId}'),
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
