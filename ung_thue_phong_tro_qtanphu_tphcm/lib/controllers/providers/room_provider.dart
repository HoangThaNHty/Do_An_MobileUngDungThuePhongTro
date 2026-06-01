import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/entities/room.dart';
import '../../models/entities/user.dart';
import '../../repositories/room_repository.dart';
import '../auth_controller.dart';
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
      // Mặc định chỉ hiển thị phòng còn trống trên danh sách tìm kiếm/khám phá công cộng
      if (filter.status == null && room.status != RoomStatus.available) {
        return false;
      }
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
      // Area filter
      if (filter.minArea != null && room.area < filter.minArea!) {
        return false;
      }
      // Amenities filter
      if (filter.amenities.isNotEmpty) {
        for (var amenity in filter.amenities) {
          if (!room.amenities.contains(amenity)) {
            return false;
          }
        }
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
  final RoomRepository repository;
  final UserRole? userRole;
  StreamSubscription<List<Room>>? _subscription;

  RoomNotifier(this.repository, this.userRole) : super(const RoomState()) {
    _initSubscription();
  }

  void _initSubscription() {
    state = state.copyWith(isLoading: true);
    
    // Tải tất cả phòng để Tenant có thể định vị và xem chi tiết phòng đã thuê/cọc của mình
    const RoomStatus? statusFilter = null;
    
    _subscription = repository.watchRooms(statusFilter: statusFilter).listen(
      (rooms) {
        state = state.copyWith(rooms: rooms, isLoading: false);
      },
      onError: (e) {
        state = state.copyWith(isLoading: false, error: 'Không thể tải danh sách phòng: $e');
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
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
  final repository = ref.watch(roomRepositoryProvider);
  final user = ref.watch(authControllerProvider).user;
  return RoomNotifier(repository, user?.role);
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
