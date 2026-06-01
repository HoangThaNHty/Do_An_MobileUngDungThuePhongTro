import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/entities/rental.dart';
import '../models/entities/bill.dart';
import '../models/entities/room.dart';
import 'auth_controller.dart';

class BookingController {
  FirebaseDatabase get _db => FirebaseDatabase.instance;

  BookingController();

  /// Lắng nghe danh sách Hợp đồng/Đặt cọc của Tenant cụ thể từ Firebase
  Stream<List<Rental>> watchRentals(String tenantId) {
    return _db.ref('rentals').onValue.map((event) {
      final snapshot = event.snapshot;
      if (!snapshot.exists) return [];

      final data = snapshot.value as Map<dynamic, dynamic>;
      final list = <Rental>[];

      data.forEach((key, value) {
        final rentalData = Map<String, dynamic>.from(value as Map);
        final rental = Rental.fromMap(rentalData, key.toString());
        if (rental.tenantId == tenantId && rental.showToTenant) {
          list.add(rental);
        }
      });
      return list;
    });
  }

  /// Lắng nghe danh sách tất cả các Hợp đồng/Đặt cọc của Landlord cụ thể từ Firebase
  Stream<List<Rental>> watchAllRentals(String landlordId) {
    return _db.ref('rentals').onValue.map((event) {
      final snapshot = event.snapshot;
      if (!snapshot.exists) return [];

      final data = snapshot.value as Map<dynamic, dynamic>;
      final list = <Rental>[];

      data.forEach((key, value) {
        final rentalData = Map<String, dynamic>.from(value as Map);
        final rental = Rental.fromMap(rentalData, key.toString());
        if (rental.landlordId == landlordId && rental.showToLandlord) {
          list.add(rental);
        }
      });
      return list;
    });
  }

  /// Lắng nghe danh sách Hóa đơn của Tenant cụ thể từ Firebase
  Stream<List<Bill>> watchBills(String tenantId) {
    return _db.ref('bills').onValue.map((event) {
      final snapshot = event.snapshot;
      if (!snapshot.exists) return [];

      final data = snapshot.value as Map<dynamic, dynamic>;
      final list = <Bill>[];

      data.forEach((key, value) {
        final billData = Map<String, dynamic>.from(value as Map);
        final bill = Bill.fromMap(billData, key.toString());
        if (bill.tenantId == tenantId) {
          list.add(bill);
        }
      });
      return list;
    });
  }

  /// Tạo đặt cọc và hóa đơn cọc trên Firebase Database
  Future<Map<String, String>> createBookingDeposit({
    required Room room,
    required String tenantId,
    required String tenantName,
    required int depositMonths,
    required int amount,
    required DateTime moveInDate,
  }) async {
    final rentalId = 'rental_${DateTime.now().millisecondsSinceEpoch}';
    final billId = 'bill_${DateTime.now().millisecondsSinceEpoch}';

    // 1. Tạo thực thể Rental (status: pending)
    final rental = Rental(
      id: rentalId,
      roomId: room.id,
      roomTitle: room.title,
      roomAddress: room.address,
      tenantId: tenantId,
      tenantName: tenantName,
      landlordId: room.landlordId,
      monthlyRent: room.price,
      startDate: moveInDate,
      endDate: moveInDate.add(Duration(days: depositMonths * 30)),
      status: RentalStatus.pending,
      createdAt: DateTime.now(),
    );

    // 2. Tạo thực thể Bill (status: unpaid)
    final bill = Bill(
      id: billId,
      roomId: room.id,
      roomTitle: room.title,
      tenantId: tenantId,
      tenantName: tenantName,
      rentAmount: amount, // tiền cọc
      electricityAmount: 0,
      waterAmount: 0,
      internetAmount: 0,
      trashAmount: 0,
      otherAmount: 0,
      electricityUsage: 0,
      waterUsage: 0,
      status: BillStatus.unpaid,
      billingMonth: DateTime.now(),
      dueDate: DateTime.now().add(const Duration(days: 3)),
      createdAt: DateTime.now(),
    );

    // 3. Đẩy lên Firebase Realtime Database
    await _db.ref('rentals/$rentalId').set(rental.toMap());
    await _db.ref('bills/$billId').set(bill.toMap());

    return {
      'rentalId': rentalId,
      'billId': billId,
    };
  }

  /// Xác nhận đã thanh toán cọc -> Giữ trạng thái cọc là pending để Platform bảo lãnh trung gian
  Future<void> confirmDepositPayment({
    required String rentalId,
    required String billId,
    required String roomId,
  }) async {
    final now = DateTime.now();

    // 1. Cập nhật hóa đơn đặt cọc thành paid
    await _db.ref('bills/$billId').update({
      'status': BillStatus.paid.name,
      'paidDate': now.toIso8601String(),
    });

    // 2. Cập nhật trạng thái Rental giữ là pending (Đang đặt cọc giữ chỗ)
    await _db.ref('rentals/$rentalId').update({
      'status': RentalStatus.pending.name,
    });

    // 3. Cập nhật trạng thái phòng trọ thành rented (Đã giữ chỗ) để tạm thời ẩn khỏi danh sách tìm kiếm
    await _db.ref('rooms/$roomId').update({
      'status': RoomStatus.rented.name,
    });
  }

  /// Giải ngân cọc giữ chỗ cho chủ trọ -> Rental thành active (Thuê chính thức)
  Future<void> releaseDeposit({
    required String rentalId,
  }) async {
    await _db.ref('rentals/$rentalId').update({
      'status': RentalStatus.active.name,
    });
  }

  /// Hủy cọc hoàn tiền cho khách thuê -> Rental thành cancelled, mở lại phòng thành available
  Future<void> cancelDeposit({
    required String rentalId,
    required String roomId,
  }) async {
    // 1. Cập nhật Rental thành cancelled
    await _db.ref('rentals/$rentalId').update({
      'status': RentalStatus.cancelled.name,
    });

    // 2. Mở lại phòng thành available
    await _db.ref('rooms/$roomId').update({
      'status': RoomStatus.available.name,
    });
  }

  /// Ẩn giao dịch rental phía chủ trọ hoặc khách thuê độc lập, hoặc xóa vĩnh viễn nếu cả hai bên cùng xóa
  Future<void> hideOrDeleteRental({
    required String rentalId,
    required String roomId,
    required String tenantId,
    required bool isLandlord,
  }) async {
    final rentalRef = _db.ref('rentals/$rentalId');
    final snapshot = await rentalRef.get();
    if (!snapshot.exists) return;

    final rentalData = Map<String, dynamic>.from(snapshot.value as Map);
    final rental = Rental.fromMap(rentalData, rentalId);

    // 1. Xác định trạng thái xóa hiện tại của từng bên
    bool nextShowToLandlord = rental.showToLandlord;
    bool nextShowToTenant = rental.showToTenant;

    if (isLandlord) {
      nextShowToLandlord = false;
    } else {
      nextShowToTenant = false;
    }

    // 2. Nếu cả hai bên đều chọn xóa, tiến hành xóa cứng khỏi DB
    if (!nextShowToLandlord && !nextShowToTenant) {
      await rentalRef.remove();

      // Đồng thời tìm và xóa các hóa đơn liên quan đến phòng và khách thuê này
      final billsSnapshot = await _db.ref('bills').get();
      if (billsSnapshot.exists) {
        final billsData = billsSnapshot.value as Map<dynamic, dynamic>;
        for (final entry in billsData.entries) {
          final key = entry.key.toString();
          final val = Map<String, dynamic>.from(entry.value as Map);
          if (val['roomId'] == roomId && val['tenantId'] == tenantId) {
            await _db.ref('bills/$key').remove();
          }
        }
      }
    } else {
      // 3. Nếu mới chỉ một bên xóa, cập nhật cờ ẩn tương ứng trên Firebase
      await rentalRef.update({
        'showToLandlord': nextShowToLandlord,
        'showToTenant': nextShowToTenant,
      });
    }
  }
}

// Providers
final bookingControllerProvider = Provider<BookingController>((ref) {
  return BookingController();
});

// Lắng nghe cọc của khách hiện tại
final tenantRentalsProvider = StreamProvider<List<Rental>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  return ref.watch(bookingControllerProvider).watchRentals(user.id);
});

// Lắng nghe hóa đơn của khách hiện tại
final tenantBillsProvider = StreamProvider<List<Bill>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  return ref.watch(bookingControllerProvider).watchBills(user.id);
});
