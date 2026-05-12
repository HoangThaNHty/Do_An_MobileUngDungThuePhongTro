import 'package:flutter_riverpod/flutter_riverpod.dart';

// ═══════════════════════════════════════════
// CREATE ROOM STATE — Multi-step form
// ═══════════════════════════════════════════
class CreateRoomState {
  // Step 1 — Thông tin cơ bản
  final String title;
  final String address;
  final String district;
  final double area;
  final int price;
  final int depositMonths;
  final String description;

  // Step 2 — Ảnh & Tiện nghi
  final List<String> images;      // local paths
  final List<String> amenities;

  // Step 3 — Xem trước
  final bool isSubmitting;
  final bool isSuccess;
  final String? error;

  const CreateRoomState({
    this.title = '',
    this.address = '',
    this.district = 'Tân Phú',
    this.area = 20,
    this.price = 3000000,
    this.depositMonths = 2,
    this.description = '',
    this.images = const [],
    this.amenities = const [],
    this.isSubmitting = false,
    this.isSuccess = false,
    this.error,
  });

  CreateRoomState copyWith({
    String? title,
    String? address,
    String? district,
    double? area,
    int? price,
    int? depositMonths,
    String? description,
    List<String>? images,
    List<String>? amenities,
    bool? isSubmitting,
    bool? isSuccess,
    String? error,
    bool clearError = false,
  }) {
    return CreateRoomState(
      title: title ?? this.title,
      address: address ?? this.address,
      district: district ?? this.district,
      area: area ?? this.area,
      price: price ?? this.price,
      depositMonths: depositMonths ?? this.depositMonths,
      description: description ?? this.description,
      images: images ?? this.images,
      amenities: amenities ?? this.amenities,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSuccess: isSuccess ?? this.isSuccess,
      error: clearError ? null : (error ?? this.error),
    );
  }

  bool get isStep1Valid =>
      title.isNotEmpty && address.isNotEmpty && price > 0;
}

class CreateRoomNotifier extends StateNotifier<CreateRoomState> {
  CreateRoomNotifier() : super(const CreateRoomState());

  void updateBasicInfo({
    String? title,
    String? address,
    String? district,
    double? area,
    int? price,
    int? depositMonths,
    String? description,
  }) {
    state = state.copyWith(
      title: title,
      address: address,
      district: district,
      area: area,
      price: price,
      depositMonths: depositMonths,
      description: description,
    );
  }

  void toggleAmenity(String amenity) {
    final amenities = List<String>.from(state.amenities);
    if (amenities.contains(amenity)) {
      amenities.remove(amenity);
    } else {
      amenities.add(amenity);
    }
    state = state.copyWith(amenities: amenities);
  }

  void addImage(String path) {
    state = state.copyWith(images: [...state.images, path]);
  }

  void removeImage(int index) {
    final images = List<String>.from(state.images);
    images.removeAt(index);
    state = state.copyWith(images: images);
  }

  Future<bool> submit() async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await Future.delayed(const Duration(seconds: 1));
      // In real app: push to Firebase Realtime Database
      state = state.copyWith(isSubmitting: false, isSuccess: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: 'Không thể tạo phòng. Vui lòng thử lại.',
      );
      return false;
    }
  }

  void reset() {
    state = const CreateRoomState();
  }
}

final createRoomProvider =
    StateNotifierProvider.autoDispose<CreateRoomNotifier, CreateRoomState>(
  (ref) => CreateRoomNotifier(),
);
