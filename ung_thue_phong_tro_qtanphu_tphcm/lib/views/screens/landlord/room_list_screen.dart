import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/constants.dart';
import '../../../controllers/providers/room_provider.dart';
import '../../../models/entities/room.dart';
import '../../widgets/cards/room_card.dart';

class RoomListScreen extends ConsumerStatefulWidget {
  const RoomListScreen({super.key});

  @override
  ConsumerState<RoomListScreen> createState() => _RoomListScreenState();
}

class _RoomListScreenState extends ConsumerState<RoomListScreen> {
  RoomStatus? _selectedFilter;

  @override
  Widget build(BuildContext context) {
    final roomState = ref.watch(roomProvider);
    
    // Lọc danh sách phòng theo trạng thái
    final filteredRooms = _selectedFilter == null 
        ? roomState.rooms 
        : roomState.rooms.where((r) => r.status == _selectedFilter).toList();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Quản lý Phòng trọ'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Filter section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            color: AppColors.surfaceContainerLowest,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(null, 'Tất cả (${roomState.rooms.length})'),
                  _buildFilterChip(RoomStatus.available, 'Còn trống (${roomState.rooms.where((r) => r.status == RoomStatus.available).length})'),
                  _buildFilterChip(RoomStatus.rented, 'Đã thuê (${roomState.rooms.where((r) => r.status == RoomStatus.rented).length})'),
                  _buildFilterChip(RoomStatus.overdue, 'Quá hạn (${roomState.rooms.where((r) => r.status == RoomStatus.overdue).length})'),
                ],
              ),
            ),
          ),
          
          // Room list
          Expanded(
            child: filteredRooms.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.meeting_room_outlined, size: 64, color: AppColors.outlineVariant),
                        const SizedBox(height: 16),
                        Text('Không có phòng nào phù hợp', style: AppTypography.bodyMD),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: filteredRooms.length,
                    itemBuilder: (context, index) {
                      final room = filteredRooms[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: RoomCard(
                          room: room,
                          onTap: () {
                            // Tương lai: Chuyển đến màn hình chi tiết phòng của chủ trọ
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Đang phát triển tính năng xem chi tiết: ${room.title}')),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(RoomStatus? status, String label) {
    final isSelected = _selectedFilter == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = selected ? status : null;
          });
        },
        selectedColor: AppColors.primaryContainer,
        labelStyle: AppTypography.labelSM.copyWith(
          color: isSelected ? AppColors.onPrimary : AppColors.onSurfaceVariant,
        ),
        checkmarkColor: AppColors.onPrimary,
        backgroundColor: AppColors.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.chip),
          side: const BorderSide(color: Colors.transparent),
        ),
      ),
    );
  }
}
