import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/datasources/mock_data.dart';
import '../../models/entities/room.dart';

// Room filter state
class RoomFilter {
  final String? district;
  final int? minPrice;
  final int? maxPrice;
  final double? minArea;
  final RoomStatus? status;
  final List<String> amenities;

  const RoomFilter({
    this.district,
    this.minPrice,
    this.maxPrice,
    this.minArea,
    this.status,
    this.amenities = const [],
  });

  RoomFilter copyWith({
    String? district,
    int? minPrice,
    int? maxPrice,
    double? minArea,
    RoomStatus? status,
    List<String>? amenities,
    bool clearDistrict = false,
    bool clearStatus = false,
  }) {
    return RoomFilter(
      district: clearDistrict ? null : (district ?? this.district),
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      minArea: minArea ?? this.minArea,
      status: clearStatus ? null : (status ?? this.status),
      amenities: amenities ?? this.amenities,
    );
  }

  bool get hasActiveFilters =>
      district != null ||
      minPrice != null ||
      maxPrice != null ||
      minArea != null ||
      status != null ||
      amenities.isNotEmpty;
}

// Room State
class RoomState {
  final List<Room> rooms;
  final bool isLoading;
  final String? error;
  final RoomFilter filter;
  final String searchQuery;

  const RoomState({
    this.rooms = const [],
    this.isLoading = false,
    this.error,
    this.filter = const RoomFilter(),
    this.searchQuery = '',
  });

  List<Room> get filteredRooms {
    var list = rooms.where((room) {
      // Search query
      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        if (!room.title.toLowerCase().contains(q) &&
            !room.address.toLowerCase().contains(q) &&
            !room.district.toLowerCase().contains(q)) {
          return false;
        }
      }
      // District filter
      if (filter.district != null && room.district != filter.district) {
        return false;
      }
      // Price filter
      if (filter.minPrice != null && room.price < filter.minPrice!) {
        return false;
      }
      if (filter.maxPrice != null && room.price > filter.maxPrice!) {
        return false;
      }
      // Status filter
      if (filter.status != null && room.status != filter.status) {
        return false;
      }
      return true;
    }).toList();
    return list;
  }

  RoomState copyWith({
    List<Room>? rooms,
    bool? isLoading,
    String? error,
    RoomFilter? filter,
    String? searchQuery,
  }) {
    return RoomState(
      rooms: rooms ?? this.rooms,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      filter: filter ?? this.filter,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class RoomNotifier extends StateNotifier<RoomState> {
  RoomNotifier() : super(const RoomState()) {
    loadRooms();
  }

  Future<void> loadRooms() async {
    state = state.copyWith(isLoading: true);
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      // In real app: fetch from Firebase Realtime Database
      state = state.copyWith(rooms: MockData.rooms, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Không thể tải danh sách phòng');
    }
  }

  void search(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void applyFilter(RoomFilter filter) {
    state = state.copyWith(filter: filter);
  }

  void clearFilter() {
    state = state.copyWith(filter: const RoomFilter());
  }

  Room? getRoomById(String id) {
    try {
      return state.rooms.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }
}

// Providers
final roomProvider = StateNotifierProvider<RoomNotifier, RoomState>((ref) {
  return RoomNotifier();
});

final filteredRoomsProvider = Provider<List<Room>>((ref) {
  return ref.watch(roomProvider).filteredRooms;
});

final roomByIdProvider = Provider.family<Room?, String>((ref, id) {
  return ref.watch(roomProvider.notifier).getRoomById(id);
});

// Districts list
final districtsProvider = Provider<List<String>>((ref) {
  final rooms = ref.watch(roomProvider).rooms;
  final districts = rooms.map((r) => r.district).toSet().toList()..sort();
  return ['Tất cả', ...districts];
});
