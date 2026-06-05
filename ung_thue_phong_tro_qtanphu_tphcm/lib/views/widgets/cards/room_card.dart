import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../config/app_palette.dart';
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
    final palette = context.palette;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: palette.surfaceLowest,
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
                        placeholder: (_, __) => _imagePlaceholder(palette),
                        errorWidget: (_, __, ___) => _imagePlaceholder(palette),
                      )
                    : _imagePlaceholder(palette),
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
                            style: AppTypography.titleSM.copyWith(
                              color: palette.onSurface,
                            ),
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
                        Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: palette.onSurfaceVariant,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            room.address,
                            style: AppTypography.bodySM.copyWith(
                              color: palette.onSurfaceVariant,
                            ),
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
                        Icon(
                          Icons.straighten_outlined,
                          size: 13,
                          color: palette.onSurfaceVariant,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${room.area.toStringAsFixed(0)} m²',
                          style: AppTypography.bodySM.copyWith(
                            color: palette.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    // Price
                    Text(
                      '${room.price.toVnd()}đ/tháng',
                      style: AppTypography.titleSM.copyWith(
                        color: palette.primary,
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

  Widget _imagePlaceholder(AppPalette palette) {
    return Container(
      width: 84,
      height: 84,
      color: palette.surfaceLow,
      child: Icon(
        Icons.home_outlined,
        color: palette.onSurfaceVariant,
        size: 32,
      ),
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
    final palette = context.palette;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: palette.surfaceLowest,
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
                            color: palette.surfaceLow,
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: palette.surfaceLow,
                            child: Icon(
                              Icons.home_outlined,
                              color: palette.onSurfaceVariant,
                              size: 48,
                            ),
                          ),
                        )
                      : Container(
                          color: palette.surfaceLow,
                          child: Icon(
                            Icons.home_outlined,
                            color: palette.onSurfaceVariant,
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
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    room.title,
                    style: AppTypography.titleSM.copyWith(
                      color: palette.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${room.price.toVnd()}đ/tháng',
                    style: AppTypography.bodyMD.copyWith(
                      color: palette.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // Views + Toggle
                  Row(
                    children: [
                      Icon(
                        Icons.visibility_outlined,
                        size: 14,
                        color: palette.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${room.viewCount} lượt xem',
                        style: AppTypography.bodySM.copyWith(
                          color: palette.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                      const Spacer(),
                      // Status toggle
                      Transform.scale(
                        scale: 0.8,
                        child: Switch(
                          value: room.status == RoomStatus.rented,
                          onChanged: (_) => onStatusToggle?.call(),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
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
}
