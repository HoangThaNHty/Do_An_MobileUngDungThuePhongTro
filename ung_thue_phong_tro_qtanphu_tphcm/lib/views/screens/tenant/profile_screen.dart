import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../config/app_palette.dart';
import '../../../config/constants.dart';
import '../../../controllers/auth_controller.dart';
import '../../../repositories/storage_repository.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/theme_mode_selector.dart';

class TenantProfileScreen extends ConsumerStatefulWidget {
  const TenantProfileScreen({super.key});

  @override
  ConsumerState<TenantProfileScreen> createState() =>
      _TenantProfileScreenState();
}

class _TenantProfileScreenState extends ConsumerState<TenantProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullNameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _birthYearCtrl;
  late TextEditingController _hometownCtrl;
  late TextEditingController _occupationCtrl;
  late TextEditingController _bioCtrl;
  String? _gender;
  String? _avatarUrl;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _fullNameCtrl = TextEditingController(text: user?.fullName ?? '');
    _phoneCtrl = TextEditingController(text: user?.phone ?? '');
    _birthYearCtrl =
        TextEditingController(text: user?.birthYear?.toString() ?? '');
    _hometownCtrl = TextEditingController(text: user?.hometown ?? '');
    _occupationCtrl = TextEditingController(text: user?.occupation ?? '');
    _bioCtrl = TextEditingController(text: user?.bio ?? '');
    _gender = user?.gender;
    _avatarUrl = user?.avatarUrl;
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _birthYearCtrl.dispose();
    _hometownCtrl.dispose();
    _occupationCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 500,
    );

    if (image == null) return;

    setState(() {
      _isUploadingImage = true;
    });

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      final storageRepo = ref.read(storageRepositoryProvider);
      final newUrl =
          await storageRepo.uploadRoomImage(user.id, File(image.path));

      setState(() {
        _avatarUrl = newUrl;
      });

      // Ghi tức thì avatar mới lên Firebase Realtime Database
      await ref.read(authControllerProvider.notifier).updateProfile(
            fullName: _fullNameCtrl.text,
            phone: _phoneCtrl.text,
            avatarUrl: newUrl,
            gender: _gender,
            birthYear: int.tryParse(_birthYearCtrl.text),
            hometown: _hometownCtrl.text,
            occupation: _occupationCtrl.text,
            bio: _bioCtrl.text,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tải ảnh đại diện lên và đồng bộ thành công!'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải ảnh đại diện: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isUploadingImage = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final birthYearVal = int.tryParse(_birthYearCtrl.text.trim());
      await ref.read(authControllerProvider.notifier).updateProfile(
            fullName: _fullNameCtrl.text.trim(),
            phone: _phoneCtrl.text.trim(),
            avatarUrl: _avatarUrl,
            gender: _gender,
            birthYear: birthYearVal,
            hometown: _hometownCtrl.text.trim(),
            occupation: _occupationCtrl.text.trim(),
            bio: _bioCtrl.text.trim(),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật thông tin thành công! 🎉'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cập nhật thất bại: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final palette = context.palette;

    return Scaffold(
      backgroundColor: palette.surface,
      appBar: AppBar(
        title: const Text('Tài khoản cá nhân'),
        automaticallyImplyLeading: false, // Là tab chính, không cần nút Back
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.md),
              // Avatar edit area
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 56,
                    backgroundColor: palette.primary.withValues(alpha: 0.14),
                    backgroundImage:
                        _avatarUrl != null && _avatarUrl!.isNotEmpty
                            ? NetworkImage(_avatarUrl!)
                            : null,
                    child: _avatarUrl == null || _avatarUrl!.isEmpty
                        ? Text(
                            user?.fullName.isNotEmpty == true
                                ? user!.fullName[0].toUpperCase()
                                : 'U',
                            style: AppTypography.headlineLG.copyWith(
                              color: palette.primary,
                              fontSize: 36,
                            ),
                          )
                        : null,
                  ),
                  if (_isUploadingImage)
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black38,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  GestureDetector(
                    onTap: _isUploadingImage ? null : _pickAndUploadAvatar,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [AppShadows.fab],
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                user?.email ?? '',
                style: AppTypography.bodyMD.copyWith(
                  color: palette.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Fields card
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: palette.surfaceLowest,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  boxShadow: const [AppShadows.card],
                ),
                child: Column(
                  children: [
                    // Full Name
                    TextFormField(
                      controller: _fullNameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Họ và tên *',
                        prefixIcon: Icon(Icons.person_outline, size: 20),
                      ),
                      validator: (v) => v == null || v.isEmpty
                          ? 'Vui lòng nhập họ tên'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Phone Number
                    TextFormField(
                      controller: _phoneCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Số điện thoại *',
                        prefixIcon: Icon(Icons.phone_outlined, size: 20),
                        hintText: 'VD: 090xxxxxxx',
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (v) => v == null || v.isEmpty
                          ? 'Vui lòng nhập số điện thoại'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Gender (Dropdown)
                    DropdownButtonFormField<String>(
                      initialValue: _gender,
                      decoration: const InputDecoration(
                        labelText: 'Giới tính',
                        prefixIcon: Icon(Icons.transgender_outlined, size: 20),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Nam', child: Text('Nam')),
                        DropdownMenuItem(value: 'Nữ', child: Text('Nữ')),
                        DropdownMenuItem(value: 'Khác', child: Text('Khác')),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _gender = val;
                        });
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Birth Year
                    TextFormField(
                      controller: _birthYearCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Năm sinh',
                        prefixIcon: Icon(Icons.cake_outlined, size: 20),
                        hintText: 'VD: 2002',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v != null && v.isNotEmpty) {
                          final val = int.tryParse(v);
                          if (val == null ||
                              val < 1940 ||
                              val > DateTime.now().year) {
                            return 'Năm sinh không hợp lệ';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Hometown
                    TextFormField(
                      controller: _hometownCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Quê quán',
                        prefixIcon: Icon(Icons.home_outlined, size: 20),
                        hintText: 'VD: Lâm Đồng',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Occupation
                    TextFormField(
                      controller: _occupationCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nghề nghiệp / Công việc',
                        prefixIcon: Icon(Icons.work_outline, size: 20),
                        hintText: 'VD: Sinh viên, Nhân viên văn phòng',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Bio (Giới thiệu bản thân)
                    TextFormField(
                      controller: _bioCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Giới thiệu bản thân (Bio)',
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(bottom: 24),
                          child: Icon(Icons.edit_note_outlined, size: 20),
                        ),
                        hintText:
                            'Hãy chia sẻ một chút về bản thân (thói quen sinh hoạt, gọn gàng, giờ giấc...) để chủ trọ dễ dàng kết nối nhé!',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Role (Read-only)
                    TextFormField(
                      initialValue: 'Người tìm phòng',
                      decoration: const InputDecoration(
                        labelText: 'Vai trò tài khoản',
                        prefixIcon: Icon(Icons.badge_outlined, size: 20),
                      ),
                      enabled: false,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const ThemeModeSelector(),
              const SizedBox(height: AppSpacing.xl),

              // Submit Button
              AppButton(
                text: 'Lưu thay đổi',
                onPressed: authState.isLoading ? null : _saveProfile,
                isLoading: authState.isLoading,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
