import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/entities/room.dart';

final roomRepositoryProvider = Provider<RoomRepository>((ref) {
  return RoomRepository(FirebaseDatabase.instance);
});

class RoomRepository {
  final FirebaseDatabase _db;

  RoomRepository(this._db);

  // Lắng nghe tất cả các phòng (Có thể lọc theo status)
  Stream<List<Room>> watchRooms({RoomStatus? statusFilter}) {
    final ref = _db.ref('rooms');
    
    return ref.onValue.map((event) {
      final snapshot = event.snapshot;
      if (!snapshot.exists) return [];

      final data = snapshot.value as Map<dynamic, dynamic>;
      final rooms = <Room>[];
      
      data.forEach((key, value) {
        final roomData = Map<String, dynamic>.from(value as Map);
        final room = Room.fromMap(roomData, key.toString());
        
        if (statusFilter == null || room.status == statusFilter) {
          rooms.add(room);
        }
      });
      
      // Sắp xếp theo ngày tạo mới nhất
      rooms.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return rooms;
    });
  }

  // Lắng nghe các phòng của một Chủ trọ cụ thể
  Stream<List<Room>> watchLandlordRooms(String landlordId) {
    final ref = _db.ref('rooms').orderByChild('landlordId').equalTo(landlordId);
    
    return ref.onValue.map((event) {
      final snapshot = event.snapshot;
      if (!snapshot.exists) return [];

      final data = snapshot.value as Map<dynamic, dynamic>;
      final rooms = <Room>[];
      
      data.forEach((key, value) {
        final roomData = Map<String, dynamic>.from(value as Map);
        rooms.add(Room.fromMap(roomData, key.toString()));
      });
      
      // Sắp xếp theo ngày tạo mới nhất
      rooms.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return rooms;
    });
  }

  // Thêm mới một phòng
  Future<void> createRoom(Room room) async {
    final ref = _db.ref('rooms').child(room.id);
    await ref.set(room.toMap());
  }

  // Cập nhật trạng thái phòng
  Future<void> updateRoomStatus(String roomId, RoomStatus newStatus) async {
    final ref = _db.ref('rooms').child(roomId);
    await ref.update({
      'status': newStatus.name,
    });
  }

  // Cập nhật thông tin phòng
  Future<void> updateRoom(Room room) async {
    final ref = _db.ref('rooms').child(room.id);
    await ref.update(room.toMap());
  }

  // Xóa phòng
  Future<void> deleteRoom(String roomId) async {
    final ref = _db.ref('rooms').child(roomId);
    await ref.remove();
  }
}
