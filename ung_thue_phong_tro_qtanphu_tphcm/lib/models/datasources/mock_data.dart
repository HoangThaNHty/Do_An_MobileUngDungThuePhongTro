import '../../models/entities/room.dart';
import '../../models/entities/user.dart';
import '../../models/entities/bill.dart';
import '../../models/entities/rental.dart';

// ═══════════════════════════════════════════
// MOCK DATA — Firebase Realtime Database structure
// ═══════════════════════════════════════════

class MockData {
  // Sample room images (using placeholder rooms)
  static const List<String> _roomImages = [
    'https://images.unsplash.com/photo-1555854877-bab0e564b8d5?w=400&q=80',
    'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=400&q=80',
    'https://images.unsplash.com/photo-1484154218962-a197022b5858?w=400&q=80',
    'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=400&q=80',
    'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=400&q=80',
    'https://images.unsplash.com/photo-1493809842364-78817add7ffb?w=400&q=80',
  ];

  static final List<Room> rooms = [
    Room(
      id: 'room_001',
      title: 'Phòng 102 - Tầng 1',
      address: 'Hẻm 42 Ung Văn Khiêm, Phường 25, Quận Bình Thạnh',
      district: 'Bình Thạnh',
      area: 25,
      price: 4500000,
      status: RoomStatus.available,
      images: [_roomImages[0], _roomImages[1]],
      amenities: ['Điều hòa', 'Nóng lạnh', 'Tủ lạnh', 'WiFi', 'Ban công', 'Bếp'],
      description:
          'Phòng thoáng mát, yên tĩnh, gần chợ và các tiện ích. Có bảo vệ 24/7, camera an ninh. Thích hợp cho sinh viên và người đi làm.',
      landlordId: 'landlord_001',
      latitude: 10.8014883,
      longitude: 106.7087971,
      viewCount: 128,
      createdAt: DateTime(2024, 1, 15),
    ),
    Room(
      id: 'room_002',
      title: 'Phòng 201 - Tầng 2',
      address: 'Hẻm 42 Ung Văn Khiêm, Phường 25, Quận Bình Thạnh',
      district: 'Bình Thạnh',
      area: 30,
      price: 5000000,
      status: RoomStatus.rented,
      images: [_roomImages[1], _roomImages[2]],
      amenities: ['Điều hòa', 'Nóng lạnh', 'Tủ lạnh', 'WiFi', 'Máy giặt'],
      description:
          'Phòng rộng rãi, đủ tiện nghi. Gần trường đại học và bệnh viện.',
      landlordId: 'landlord_001',
      latitude: 10.8015,
      longitude: 106.7090,
      viewCount: 210,
      createdAt: DateTime(2024, 1, 20),
    ),
    Room(
      id: 'room_003',
      title: 'Phòng 305 - Tầng 3',
      address: '210 Điện Biên Phủ, Phường 15, Quận Bình Thạnh',
      district: 'Bình Thạnh',
      area: 35,
      price: 6200000,
      status: RoomStatus.available,
      images: [_roomImages[2], _roomImages[3]],
      amenities: ['Điều hòa', 'Nóng lạnh', 'Tủ lạnh', 'WiFi', 'Ban công', 'Bếp', 'Máy giặt'],
      description:
          'Phòng view đẹp, thoáng mát. Nội thất đầy đủ, mới mua.',
      landlordId: 'landlord_001',
      latitude: 10.7985,
      longitude: 106.7180,
      viewCount: 85,
      createdAt: DateTime(2024, 2, 1),
    ),
    Room(
      id: 'room_004',
      title: 'Phòng 101 - Master',
      address: '45 Nguyễn Thị Minh Khai, Phường 2, Quận 3',
      district: 'Quận 3',
      area: 40,
      price: 7500000,
      status: RoomStatus.rented,
      images: [_roomImages[3], _roomImages[4]],
      amenities: ['Điều hòa', 'Nóng lạnh', 'Tủ lạnh', 'WiFi', 'Bếp', 'Máy giặt', 'Tivi'],
      description:
          'Phòng cao cấp, full nội thất. Vị trí trung tâm, thuận tiện di chuyển.',
      landlordId: 'landlord_001',
      latitude: 10.7769,
      longitude: 106.6900,
      viewCount: 320,
      createdAt: DateTime(2024, 2, 10),
    ),
    Room(
      id: 'room_005',
      title: 'Phòng 202 - Studio',
      address: '12 Lê Văn Sỹ, Phường 1, Quận Tân Bình',
      district: 'Tân Bình',
      area: 28,
      price: 3800000,
      status: RoomStatus.overdue,
      images: [_roomImages[4], _roomImages[5]],
      amenities: ['Điều hòa', 'Nóng lạnh', 'WiFi'],
      description:
          'Phòng gần chợ Tân Bình, tiện ích xung quanh đầy đủ.',
      landlordId: 'landlord_001',
      latitude: 10.7970,
      longitude: 106.6620,
      viewCount: 95,
      createdAt: DateTime(2024, 2, 15),
    ),
    Room(
      id: 'room_006',
      title: 'Phòng 301 - Standard',
      address: '88 Cách Mạng Tháng 8, Phường 5, Quận Tân Bình',
      district: 'Tân Bình',
      area: 22,
      price: 3000000,
      status: RoomStatus.available,
      images: [_roomImages[5], _roomImages[0]],
      amenities: ['Điều hòa', 'WiFi', 'Nóng lạnh'],
      description:
          'Phòng nhỏ gọn, giá sinh viên. Gần Đại học Công nghiệp.',
      landlordId: 'landlord_002',
      latitude: 10.8001,
      longitude: 106.6597,
      viewCount: 50,
      createdAt: DateTime(2024, 3, 1),
    ),
  ];

  static final List<AppUser> users = [
    AppUser(
      id: 'landlord_001',
      fullName: 'Nguyễn Văn An',
      email: 'annguyen@email.com',
      phone: '0901234567',
      role: UserRole.landlord,
      avatarUrl: 'https://i.pravatar.cc/150?img=3',
      createdAt: DateTime(2023, 6, 1),
    ),
    AppUser(
      id: 'landlord_002',
      fullName: 'Trần Thị Bích',
      email: 'bichtran@email.com',
      phone: '0912345678',
      role: UserRole.landlord,
      avatarUrl: 'https://i.pravatar.cc/150?img=5',
      createdAt: DateTime(2023, 8, 15),
    ),
    AppUser(
      id: 'tenant_001',
      fullName: 'Lê Hoàng Nam',
      email: 'namle@email.com',
      phone: '0923456789',
      role: UserRole.tenant,
      avatarUrl: 'https://i.pravatar.cc/150?img=7',
      createdAt: DateTime(2024, 1, 5),
    ),
    AppUser(
      id: 'tenant_002',
      fullName: 'Phạm Thị Lan',
      email: 'lanpham@email.com',
      phone: '0934567890',
      role: UserRole.tenant,
      avatarUrl: 'https://i.pravatar.cc/150?img=9',
      createdAt: DateTime(2024, 2, 10),
    ),
  ];

  static final List<Bill> bills = [
    Bill(
      id: 'bill_001',
      roomId: 'room_002',
      roomTitle: 'Phòng 201 - Tầng 2',
      tenantId: 'tenant_001',
      tenantName: 'Lê Hoàng Nam',
      rentAmount: 5000000,
      electricityAmount: 280000,
      waterAmount: 60000,
      internetAmount: 100000,
      trashAmount: 20000,
      otherAmount: 0,
      electricityUsage: 140,
      waterUsage: 6,
      status: BillStatus.paid,
      billingMonth: DateTime(2024, 3, 1),
      dueDate: DateTime(2024, 3, 10),
      paidDate: DateTime(2024, 3, 8),
      createdAt: DateTime(2024, 3, 1),
    ),
    Bill(
      id: 'bill_002',
      roomId: 'room_002',
      roomTitle: 'Phòng 201 - Tầng 2',
      tenantId: 'tenant_001',
      tenantName: 'Lê Hoàng Nam',
      rentAmount: 5000000,
      electricityAmount: 320000,
      waterAmount: 70000,
      internetAmount: 100000,
      trashAmount: 20000,
      otherAmount: 0,
      electricityUsage: 160,
      waterUsage: 7,
      status: BillStatus.unpaid,
      billingMonth: DateTime(2024, 4, 1),
      dueDate: DateTime(2024, 4, 10),
      createdAt: DateTime(2024, 4, 1),
    ),
    Bill(
      id: 'bill_003',
      roomId: 'room_005',
      roomTitle: 'Phòng 202 - Studio',
      tenantId: 'tenant_002',
      tenantName: 'Phạm Thị Lan',
      rentAmount: 3800000,
      electricityAmount: 200000,
      waterAmount: 50000,
      internetAmount: 100000,
      trashAmount: 20000,
      otherAmount: 0,
      electricityUsage: 100,
      waterUsage: 5,
      status: BillStatus.overdue,
      billingMonth: DateTime(2024, 3, 1),
      dueDate: DateTime(2024, 3, 10),
      createdAt: DateTime(2024, 3, 1),
    ),
  ];

  static final List<Rental> rentals = [
    Rental(
      id: 'rental_001',
      roomId: 'room_002',
      roomTitle: 'Phòng 201 - Tầng 2',
      roomAddress: 'Hẻm 42 Ung Văn Khiêm, Bình Thạnh',
      tenantId: 'tenant_001',
      tenantName: 'Lê Hoàng Nam',
      landlordId: 'landlord_001',
      monthlyRent: 5000000,
      startDate: DateTime(2024, 1, 1),
      endDate: DateTime(2025, 1, 1),
      status: RentalStatus.active,
      createdAt: DateTime(2024, 1, 1),
    ),
    Rental(
      id: 'rental_002',
      roomId: 'room_004',
      roomTitle: 'Phòng 101 - Master',
      roomAddress: '45 Nguyễn Thị Minh Khai, Quận 3',
      tenantId: 'tenant_002',
      tenantName: 'Phạm Thị Lan',
      landlordId: 'landlord_001',
      monthlyRent: 7500000,
      startDate: DateTime(2024, 2, 1),
      endDate: DateTime(2025, 2, 1),
      status: RentalStatus.active,
      createdAt: DateTime(2024, 2, 1),
    ),
  ];

  // Stats for landlord dashboard
  static Map<String, int> get dashboardStats => {
    'totalRooms': rooms.length,
    'rentedRooms': rooms.where((r) => r.status == RoomStatus.rented).length,
    'availableRooms': rooms.where((r) => r.status == RoomStatus.available).length,
    'overdueRooms': rooms.where((r) => r.status == RoomStatus.overdue).length,
    'totalTenants': rentals.where((r) => r.status == RentalStatus.active).length,
    'monthlyRevenue': rooms
        .where((r) => r.status == RoomStatus.rented)
        .fold(0, (sum, r) => sum + r.price),
  };

  MockData._();
}
