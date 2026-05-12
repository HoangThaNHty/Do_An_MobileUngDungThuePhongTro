import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/datasources/mock_data.dart';
import '../../models/entities/bill.dart';
import '../../models/entities/rental.dart';

// Bill provider
final billsProvider = FutureProvider.family<List<Bill>, String>((ref, tenantId) async {
  await Future.delayed(const Duration(milliseconds: 400));
  return MockData.bills.where((b) => b.tenantId == tenantId).toList();
});

final allBillsProvider = FutureProvider<List<Bill>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 400));
  return MockData.bills;
});

// Rental provider
final rentalsProvider = FutureProvider.family<List<Rental>, String>((ref, tenantId) async {
  await Future.delayed(const Duration(milliseconds: 400));
  return MockData.rentals.where((r) => r.tenantId == tenantId).toList();
});

final allRentalsProvider = FutureProvider<List<Rental>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 400));
  return MockData.rentals;
});

// Tenant bills (for landlord view)
final tenantBillsByRoomProvider = FutureProvider.family<List<Bill>, String>((ref, roomId) async {
  await Future.delayed(const Duration(milliseconds: 300));
  return MockData.bills.where((b) => b.roomId == roomId).toList();
});

// Dashboard stats
final dashboardStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 300));
  return MockData.dashboardStats;
});
