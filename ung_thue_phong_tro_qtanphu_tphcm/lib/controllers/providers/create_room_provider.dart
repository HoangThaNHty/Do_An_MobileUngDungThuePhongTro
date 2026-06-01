import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/entities/room.dart';
import '../../repositories/room_repository.dart';
import '../../repositories/storage_repository.dart';
import '../auth_controller.dart';

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

  // Step 2 — Ảnh, Video & Tiện nghi
  final List<String> images;      // local file paths
  final String? videoPath;        // local file path
  final List<String> amenities;

  // Step 3 — Bản đồ
  final double? latitude;
  final double? longitude;

  // Trạng thái chỉnh sửa
  final bool isEditing;
  final String? editingRoomId;
  final List<String> existingImages; // Ảnh Cloudinary hiện tại của phòng
  final String? existingVideoUrl;    // Video Cloudinary hiện tại của phòng

  // Trạng thái xử lý form
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
    this.videoPath,
    this.amenities = const [],
    this.latitude,
    this.longitude,
    this.isEditing = false,
    this.editingRoomId,
    this.existingImages = const [],
    this.existingVideoUrl,
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
    String? videoPath,
    bool clearVideo = false,
    List<String>? amenities,
    double? latitude,
    double? longitude,
    bool? isEditing,
    String? editingRoomId,
    List<String>? existingImages,
    String? existingVideoUrl,
    bool clearExistingVideo = false,
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
      videoPath: clearVideo ? null : (videoPath ?? this.videoPath),
      amenities: amenities ?? this.amenities,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isEditing: isEditing ?? this.isEditing,
      editingRoomId: editingRoomId ?? this.editingRoomId,
      existingImages: existingImages ?? this.existingImages,
      existingVideoUrl: clearExistingVideo ? null : (existingVideoUrl ?? this.existingVideoUrl),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSuccess: isSuccess ?? this.isSuccess,
      error: clearError ? null : (error ?? this.error),
    );
  }

  bool get isStep1Valid =>
      title.isNotEmpty && address.isNotEmpty && price > 0;
      
  bool get isLocationValid => latitude != null && longitude != null;
}

class CreateRoomNotifier extends StateNotifier<CreateRoomState> {
  final RoomRepository repository;
  final StorageRepository storageRepository;
  final String landlordId;

  CreateRoomNotifier(this.repository, this.storageRepository, this.landlordId)
      : super(const CreateRoomState());

  /// Load thông tin phòng có sẵn để chỉnh sửa
  void loadRoomForEdit(Room room) {
    state = CreateRoomState(
      title: room.title,
      address: room.address,
      district: room.district,
      area: room.area,
      price: room.price,
      depositMonths: 2,
      description: room.description,
      images: const [], // Chờ chọn thêm local mới
      videoPath: null,  // Chờ chọn thêm local mới
      amenities: room.amenities,
      latitude: room.latitude,
      longitude: room.longitude,
      isEditing: true,
      editingRoomId: room.id,
      existingImages: room.images,
      existingVideoUrl: room.videoUrl,
    );
  }

  /// Cập nhật thông tin cơ bản ở Bước 1
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

  /// Cập nhật tọa độ vị trí ở Bước 3
  void updateLocation(double lat, double lng) {
    state = state.copyWith(latitude: lat, longitude: lng);
  }

  /// Bật/tắt tiện nghi
  void toggleAmenity(String amenity) {
    final amenities = List<String>.from(state.amenities);
    if (amenities.contains(amenity)) {
      amenities.remove(amenity);
    } else {
      amenities.add(amenity);
    }
    state = state.copyWith(amenities: amenities);
  }

  /// Thêm một tiện nghi tự gõ (Custom Amenity)
  void addCustomAmenity(String amenity) {
    if (amenity.trim().isEmpty) return;
    final trimmed = amenity.trim();
    final amenities = List<String>.from(state.amenities);
    if (!amenities.contains(trimmed)) {
      amenities.add(trimmed);
      state = state.copyWith(amenities: amenities);
    }
  }

  /// Thêm một đường dẫn ảnh local
  void addImage(String path) {
    state = state.copyWith(images: [...state.images, path]);
  }

  /// Xóa ảnh tại vị trí index
  void removeImage(int index) {
    final images = List<String>.from(state.images);
    images.removeAt(index);
    state = state.copyWith(images: images);
  }

  /// Xóa ảnh Cloudinary đã có khỏi danh sách hiện tại (khi sửa)
  void removeExistingImage(int index) {
    final urls = List<String>.from(state.existingImages);
    urls.removeAt(index);
    state = state.copyWith(existingImages: urls);
  }

  /// Xóa video Cloudinary hiện có (khi sửa)
  void removeExistingVideo() {
    state = state.copyWith(clearExistingVideo: true);
  }

  /// Gán đường dẫn video local
  void setVideo(String path) {
    state = state.copyWith(videoPath: path);
  }

  /// Xóa video đã chọn
  void removeVideo() {
    state = state.copyWith(clearVideo: true);
  }

  /// Gửi toàn bộ dữ liệu lên Backend (Cloudinary + Realtime Database)
  Future<bool> submit() async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      if (landlordId.isEmpty) {
        throw Exception('Chủ trọ không hợp lệ. Vui lòng đăng nhập lại.');
      }
      if (state.latitude == null || state.longitude == null) {
        throw Exception('Vui lòng chọn vị trí trên bản đồ');
      }

      List<String> finalImageUrls = [];
      String? finalVideoUrl;

      // 1. Xử lý ảnh
      // Tải ảnh local mới lên Cloudinary (nếu có)
      List<String> newlyUploadedImageUrls = [];
      if (state.images.isNotEmpty) {
        final imageFiles = state.images.map((path) => File(path)).toList();
        newlyUploadedImageUrls = await storageRepository.uploadRoomImages(landlordId, imageFiles);
      }

      if (state.isEditing) {
        // Gom ảnh cũ được giữ lại và ảnh mới
        finalImageUrls = [...state.existingImages, ...newlyUploadedImageUrls];
        if (finalImageUrls.isEmpty) {
          finalImageUrls = ['https://res.cloudinary.com/dl0ltsay7/image/upload/v1716580000/placeholder.png'];
        }
      } else {
        if (newlyUploadedImageUrls.isNotEmpty) {
          finalImageUrls = newlyUploadedImageUrls;
        } else {
          finalImageUrls = ['https://res.cloudinary.com/dl0ltsay7/image/upload/v1716580000/placeholder.png'];
        }
      }

      // 2. Xử lý video
      if (state.videoPath != null) {
        // Tải video mới lên
        finalVideoUrl = await storageRepository.uploadRoomVideo(landlordId, File(state.videoPath!));
      } else {
        if (state.isEditing) {
          // Giữ lại video cũ nếu không bị xóa
          finalVideoUrl = state.existingVideoUrl;
        }
      }

      // 3. Thực hiện tạo mới hoặc cập nhật
      if (state.isEditing && state.editingRoomId != null) {
        final updatedRoom = Room(
          id: state.editingRoomId!,
          title: state.title,
          address: state.address,
          district: state.district,
          area: state.area,
          price: state.price,
          status: RoomStatus.available, // mặc định giữ sẵn
          images: finalImageUrls,
          videoUrl: finalVideoUrl,
          amenities: state.amenities,
          description: state.description,
          landlordId: landlordId,
          latitude: state.latitude,
          longitude: state.longitude,
          createdAt: DateTime.now(), // update hoặc giữ cũ
        );
        await repository.updateRoom(updatedRoom);
      } else {
        final newRoomId = DateTime.now().millisecondsSinceEpoch.toString();
        final newRoom = Room(
          id: newRoomId,
          title: state.title,
          address: state.address,
          district: state.district,
          area: state.area,
          price: state.price,
          status: RoomStatus.available,
          images: finalImageUrls,
          videoUrl: finalVideoUrl,
          amenities: state.amenities,
          description: state.description,
          landlordId: landlordId,
          latitude: state.latitude,
          longitude: state.longitude,
          createdAt: DateTime.now(),
        );
        await repository.createRoom(newRoom);
      }

      state = state.copyWith(isSubmitting: false, isSuccess: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: state.isEditing ? 'Không thể cập nhật phòng: $e' : 'Không thể tạo phòng: $e',
      );
      return false;
    }
  }

  /// Reset form về mặc định
  void reset() {
    state = const CreateRoomState();
  }
}

// Providers (Không có .autoDispose để giữ trạng thái khi chuyển tab!)
final createRoomProvider =
    StateNotifierProvider<CreateRoomNotifier, CreateRoomState>(
  (ref) {
    final repository = ref.watch(roomRepositoryProvider);
    final storageRepo = ref.watch(storageRepositoryProvider);
    final user = ref.watch(authControllerProvider).user;
    return CreateRoomNotifier(repository, storageRepo, user?.id ?? '');
  },
);
