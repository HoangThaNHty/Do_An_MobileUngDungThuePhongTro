import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../config/constants.dart';
import '../../../models/entities/room.dart';
import '../common/status_chips.dart';

// ═══════════════════════════════════════════
// ROOM CARD — Danh sách dạng list (Người thuê xem)
// ═══════════════════════════════════════════
class RoomCard extends StatelessWidget {
  final Room room;
  final VoidCallback? onTap;

  const RoomCard({
    super.key,
    required this.room,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: const [AppShadows.card],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.button),
                child: room.images.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: room.images.first,
                        width: 84,
                        height: 84,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _imagePlaceholder(),
                        errorWidget: (_, __, ___) => _imagePlaceholder(),
                      )
                    : _imagePlaceholder(),
              ),
              const SizedBox(width: AppSpacing.md),
              // Content
              Expanded(
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
                            style: AppTypography.titleSM,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        RoomStatusChip(status: room.status),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    // Address
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: AppColors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            room.address,
                            style: AppTypography.bodySM,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    // Area
                    Row(
                      children: [
                        const Icon(
                          Icons.straighten_outlined,
                          size: 13,
                          color: AppColors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${room.area.toStringAsFixed(0)} m²',
                          style: AppTypography.bodySM,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    // Price
                    Text(
                      '${_formatCurrency(room.price)}đ/tháng',
                      style: AppTypography.titleSM.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 84,
      height: 84,
      color: AppColors.surfaceContainerLow,
      child: const Icon(
        Icons.home_outlined,
        color: AppColors.onSurfaceVariant,
        size: 32,
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

// ═══════════════════════════════════════════
// ROOM CARD — Dashboard chủ trọ (dạng grid với ảnh lớn)
// ═══════════════════════════════════════════
class LandlordRoomCard extends StatelessWidget {
  final Room room;
  final VoidCallback? onTap;
  final VoidCallback? onStatusToggle;

  const LandlordRoomCard({
    super.key,
    required this.room,
    this.onTap,
    this.onStatusToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: const [AppShadows.card],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Stack(
              children: [
                SizedBox(
                  height: 140,
                  width: double.infinity,
                  child: room.images.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: room.images.first,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: AppColors.surfaceContainerLow,
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: AppColors.surfaceContainerLow,
                            child: const Icon(
                              Icons.home_outlined,
                              color: AppColors.onSurfaceVariant,
                              size: 48,
                            ),
                          ),
                        )
                      : Container(
                          color: AppColors.surfaceContainerLow,
                          child: const Icon(
                            Icons.home_outlined,
                            color: AppColors.onSurfaceVariant,
                            size: 48,
                          ),
                        ),
                ),
                // Status chip overlay
                Positioned(
                  top: AppSpacing.sm,
                  left: AppSpacing.sm,
                  child: RoomStatusChip(status: room.status),
                ),
              ],
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    room.title,
                    style: AppTypography.titleSM,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${_formatCurrency(room.price)}đ/tháng',
                    style: AppTypography.bodyMD.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // Views + Toggle
                  Row(
                    children: [
                      const Icon(
                        Icons.visibility_outlined,
                        size: 14,
                        color: AppColors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${room.viewCount} lượt xem',
                        style: AppTypography.bodySM,
                      ),
                      const Spacer(),
                      // Status toggle
                      Transform.scale(
                        scale: 0.8,
                        child: Switch(
                          value: room.status == RoomStatus.rented,
                          onChanged: (_) => onStatusToggle?.call(),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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
