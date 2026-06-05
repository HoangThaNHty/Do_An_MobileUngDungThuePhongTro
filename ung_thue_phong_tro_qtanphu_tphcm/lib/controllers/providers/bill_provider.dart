import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../models/datasources/mock_data.dart';
import '../../models/entities/bill.dart';
import '../../models/entities/rental.dart';
import '../../models/entities/room.dart';
import 'room_provider.dart';
import '../booking_controller.dart';
import '../auth_controller.dart';

class BillHistoryQuery {
  final String roomId;
  final String tenantId;
  final String roomTitle;

  const BillHistoryQuery({
    required this.roomId,
    required this.tenantId,
    this.roomTitle = '',
  });

  @override
  bool operator ==(Object other) {
    return other is BillHistoryQuery &&
        other.roomId == roomId &&
        other.tenantId == tenantId &&
        other.roomTitle == roomTitle;
  }

  @override
  int get hashCode => Object.hash(roomId, tenantId, roomTitle);
}

bool sameRoomTitleForBillHistory(String a, String b) {
  final left = normalizeRoomSearchText(a);
  final right = normalizeRoomSearchText(b);
  return left.isNotEmpty && right.isNotEmpty && left == right;
}

bool billMatchesHistoryQuery(Bill bill, BillHistoryQuery query) {
  return bill.roomId == query.roomId ||
      sameRoomTitleForBillHistory(bill.roomTitle, query.roomTitle);
}

bool billBelongsToHistory(Bill bill, BillHistoryQuery query) {
  return bill.tenantId == query.tenantId ||
      billMatchesHistoryQuery(bill, query);
}

bool isDepositBill(Bill bill) {
  final hasNoServiceFees = bill.electricityAmount == 0 &&
      bill.waterAmount == 0 &&
      bill.internetAmount == 0 &&
      bill.trashAmount == 0 &&
      bill.otherAmount == 0 &&
      bill.electricityUsage == 0 &&
      bill.waterUsage == 0;
  final shortDueWindow = bill.dueDate.difference(bill.createdAt).inDays <= 3;
  final demoDepositAmount = bill.rentAmount <= 1000000;
  return hasNoServiceFees && (shortDueWindow || demoDepositAmount);
}

// Bill provider
final billsProvider =
    StreamProvider.family<List<Bill>, String>((ref, tenantId) {
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
final rentalsProvider =
    FutureProvider.family<List<Rental>, String>((ref, tenantId) async {
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
final tenantBillsByRoomProvider =
    StreamProvider.family<List<Bill>, String>((ref, roomId) {
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

final tenantBillsByRentalProvider =
    StreamProvider.family<List<Bill>, BillHistoryQuery>((ref, query) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);

  final room = ref.watch(roomByIdProvider(query.roomId));
  final ownedRoomIds = ref
      .watch(roomProvider)
      .rooms
      .where((room) => room.landlordId == user.id)
      .map((room) => room.id)
      .toSet();
  final landlordRentals = ref.watch(allRentalsProvider).valueOrNull ?? [];
  final hasOwnedRental = landlordRentals.any((rental) =>
      rental.landlordId == user.id &&
      (rental.roomId == query.roomId ||
          rental.tenantId == query.tenantId ||
          sameRoomTitleForBillHistory(rental.roomTitle, query.roomTitle)));
  final canViewRoom = room?.landlordId == user.id ||
      ownedRoomIds.contains(query.roomId) ||
      hasOwnedRental ||
      ownedRoomIds.isEmpty;
  if (!canViewRoom) return Stream.value([]);

  return FirebaseDatabase.instance.ref('bills').onValue.map((event) {
    final snapshot = event.snapshot;
    if (!snapshot.exists) return [];

    final data = snapshot.value as Map<dynamic, dynamic>;
    final exactTenantBills = <Bill>[];
    final roomBills = <Bill>[];
    final tenantBills = <Bill>[];

    data.forEach((key, value) {
      final billData = Map<String, dynamic>.from(value as Map);
      final bill = Bill.fromMap(billData, key.toString());
      final matchesRoom = billMatchesHistoryQuery(bill, query);
      if (bill.tenantId == query.tenantId) {
        tenantBills.add(bill);
      }
      if (matchesRoom) {
        roomBills.add(bill);
        if (bill.tenantId == query.tenantId) {
          exactTenantBills.add(bill);
        }
      }
    });

    if (exactTenantBills.isNotEmpty) return exactTenantBills;
    if (roomBills.isNotEmpty) return roomBills;
    return tenantBills;
  });
});

final landlordBillHistoryProvider =
    StreamProvider.family<List<Bill>, BillHistoryQuery>((ref, query) {
  return FirebaseDatabase.instance.ref('bills').onValue.map((event) {
    final snapshot = event.snapshot;
    if (!snapshot.exists) return <Bill>[];

    final data = snapshot.value as Map<dynamic, dynamic>;
    final relatedBills = <String, Bill>{};
    final pendingBills = <String, Bill>{};

    data.forEach((key, value) {
      final billData = Map<String, dynamic>.from(value as Map);
      final bill = Bill.fromMap(billData, key.toString());
      final related = billBelongsToHistory(bill, query);

      if (related) {
        relatedBills[bill.id] = bill;
      }

      if (bill.status == BillStatus.unpaid && bill.paymentSubmitted) {
        pendingBills[bill.id] = bill;
        if (related) {
          relatedBills[bill.id] = bill;
        }
      }
    });

    if (relatedBills.isEmpty && pendingBills.length == 1) {
      relatedBills[pendingBills.values.first.id] = pendingBills.values.first;
    }

    final result = relatedBills.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  });
});

final landlordBillHistoryViewProvider =
    Provider.family<AsyncValue<List<Bill>>, BillHistoryQuery>((ref, query) {
  final allBillsAsync = ref.watch(allBillsProvider);
  final pendingBills = ref.watch(pendingPaymentBillsProvider).maybeWhen(
        data: (bills) => bills,
        orElse: () => const <Bill>[],
      );

  return allBillsAsync.whenData((allBills) {
    final relatedBills = <String, Bill>{};

    for (final bill in allBills) {
      if (billBelongsToHistory(bill, query)) {
        relatedBills[bill.id] = bill;
      }
    }

    for (final bill in pendingBills) {
      if (billBelongsToHistory(bill, query)) {
        relatedBills[bill.id] = bill;
      }
    }

    if (relatedBills.isEmpty && pendingBills.length == 1) {
      relatedBills[pendingBills.first.id] = pendingBills.first;
    }

    final result = relatedBills.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  });
});

final pendingPaymentBillsProvider = StreamProvider<List<Bill>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);

  final ownedRoomIds = ref
      .watch(roomProvider)
      .rooms
      .where((room) => room.landlordId == user.id)
      .map((room) => room.id)
      .toSet();
  final ownedRoomTitles = ref
      .watch(roomProvider)
      .rooms
      .where((room) => room.landlordId == user.id)
      .map((room) => normalizeRoomSearchText(room.title))
      .toSet();

  if (ownedRoomIds.isEmpty) return Stream.value([]);

  return FirebaseDatabase.instance.ref('bills').onValue.map((event) {
    final snapshot = event.snapshot;
    if (!snapshot.exists) return [];

    final data = snapshot.value as Map<dynamic, dynamic>;
    final list = <Bill>[];

    data.forEach((key, value) {
      final billData = Map<String, dynamic>.from(value as Map);
      final bill = Bill.fromMap(billData, key.toString());
      final ownedBillRoom = ownedRoomIds.contains(bill.roomId) ||
          ownedRoomTitles.contains(normalizeRoomSearchText(bill.roomTitle));
      if (ownedBillRoom &&
          bill.status == BillStatus.unpaid &&
          bill.paymentSubmitted) {
        list.add(bill);
      }
    });

    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  });
});

final pendingPaymentBillsForRentalProvider =
    Provider.family<AsyncValue<List<Bill>>, BillHistoryQuery>((ref, query) {
  final billsAsync = ref.watch(pendingPaymentBillsProvider);
  return billsAsync.whenData(
    (bills) =>
        bills.where((bill) => billBelongsToHistory(bill, query)).toList(),
  );
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
