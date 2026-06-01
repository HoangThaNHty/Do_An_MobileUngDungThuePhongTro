import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../models/datasources/mock_data.dart';
import '../../models/entities/bill.dart';
import '../../models/entities/rental.dart';
import '../../models/entities/room.dart';
import 'room_provider.dart';
import '../booking_controller.dart';
import '../auth_controller.dart';

// Bill provider
final billsProvider = StreamProvider.family<List<Bill>, String>((ref, tenantId) {
  final bookingCtrl = ref.watch(bookingControllerProvider);
  return bookingCtrl.watchBills(tenantId);
});

final allBillsProvider = StreamProvider<List<Bill>>((ref) {
  return FirebaseDatabase.instance.ref('bills').onValue.map((event) {
    final snapshot = event.snapshot;
    if (!snapshot.exists) return [];

    final data = snapshot.value as Map<dynamic, dynamic>;
    final list = <Bill>[];

    data.forEach((key, value) {
      final billData = Map<String, dynamic>.from(value as Map);
      list.add(Bill.fromMap(billData, key.toString()));
    });
    return list;
  });
});

// Rental provider
final rentalsProvider = FutureProvider.family<List<Rental>, String>((ref, tenantId) async {
  await Future.delayed(const Duration(milliseconds: 400));
  return MockData.rentals.where((r) => r.tenantId == tenantId).toList();
});

final allRentalsProvider = StreamProvider<List<Rental>>((ref) {
  final bookingCtrl = ref.watch(bookingControllerProvider);
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  return bookingCtrl.watchAllRentals(user.id);
});

// Tenant bills (for landlord view)
final tenantBillsByRoomProvider = StreamProvider.family<List<Bill>, String>((ref, roomId) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);

  final room = ref.watch(roomByIdProvider(roomId));
  // Chỉ chủ trọ sở hữu phòng này mới được phép xem lịch sử hóa đơn của phòng
  if (room == null || room.landlordId != user.id) return Stream.value([]);

  return FirebaseDatabase.instance.ref('bills').onValue.map((event) {
    final snapshot = event.snapshot;
    if (!snapshot.exists) return [];

    final data = snapshot.value as Map<dynamic, dynamic>;
    final list = <Bill>[];

    data.forEach((key, value) {
      final billData = Map<String, dynamic>.from(value as Map);
      final bill = Bill.fromMap(billData, key.toString());
      if (bill.roomId == roomId) {
        list.add(bill);
      }
    });
    return list;
  });
});

final dashboardStatsProvider = Provider<AsyncValue<Map<String, int>>>((ref) {
  final roomState = ref.watch(roomProvider);
  final user = ref.watch(currentUserProvider);
  if (roomState.isLoading) return const AsyncValue.loading();
  if (user == null) return const AsyncValue.data({'monthlyRevenue': 0});
  
  int revenue = 0;
  for (var room in roomState.rooms) {
    if (room.landlordId == user.id && room.status == RoomStatus.rented) {
      revenue += room.price;
    }
  }
  return AsyncValue.data({'monthlyRevenue': revenue});
});
