import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

final storageRepositoryProvider = Provider<StorageRepository>((ref) {
  return StorageRepository();
});

class StorageRepository {
  // Cấu hình Cloudinary của bạn
  static const String _cloudName = 'dl0ltsay7'; // Cloud Name của bạn
  static const String _uploadPreset = 'ml_default'; // Upload Preset mặc định (Unsigned)

  StorageRepository();

  /// Tải một file ảnh lên Cloudinary và trả về đường dẫn URL an toàn (HTTPS)
  Future<String> uploadRoomImage(String landlordId, File imageFile) async {
    try {
      final url = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');
      
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = _uploadPreset
        ..fields['folder'] = 'rooms/$landlordId' // Tổ chức ảnh theo thư mục của chủ trọ
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(responseBody);
        return data['secure_url'] as String; // URL HTTPS của ảnh từ Cloudinary
      } else {
        throw Exception('Lỗi từ Cloudinary: $responseBody (Mã lỗi: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Lỗi trong quá trình upload ảnh lên Cloudinary: $e');
    }
  }

  /// Tải một file video lên Cloudinary và trả về đường dẫn URL an toàn (HTTPS)
  Future<String> uploadRoomVideo(String landlordId, File videoFile) async {
    try {
      final url = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/video/upload');
      
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = _uploadPreset
        ..fields['folder'] = 'rooms/$landlordId/videos' // Lưu video riêng biệt trong thư mục videos
        ..files.add(await http.MultipartFile.fromPath('file', videoFile.path));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(responseBody);
        return data['secure_url'] as String; // URL HTTPS của video từ Cloudinary
      } else {
        throw Exception('Lỗi từ Cloudinary khi upload video: $responseBody (Mã lỗi: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Lỗi trong quá trình upload video lên Cloudinary: $e');
    }
  }

  /// Tải danh sách file ảnh lên Cloudinary và trả về danh sách đường dẫn URL tương ứng
  Future<List<String>> uploadRoomImages(String landlordId, List<File> imageFiles) async {
    final List<String> downloadUrls = [];
    for (final file in imageFiles) {
      final url = await uploadRoomImage(landlordId, file);
      downloadUrls.add(url);
    }
    return downloadUrls;
  }
}
