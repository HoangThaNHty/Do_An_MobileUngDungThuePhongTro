import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/constants.dart';
import '../../../controllers/auth_controller.dart';
import '../../../models/entities/user.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;

class LoginScreen extends ConsumerStatefulWidget {
  final String? initialEmail;
  const LoginScreen({super.key, this.initialEmail});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null) {
      _emailCtrl.text = widget.initialEmail!;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authControllerProvider);
      if (authState.pendingGoogleUser != null) {
        _showGoogleRoleDialog(authState.pendingGoogleUser!);
      }
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authControllerProvider.notifier).loginWithEmail(
          _emailCtrl.text.trim(),
          _passwordCtrl.text,
        );
  }

  Future<void> _loginWithGoogle() async {
    await ref.read(authControllerProvider.notifier).loginWithGoogle();
  }

  void _showGoogleRoleDialog(firebase.User firebaseUser) {
    showDialog<UserRole>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Chọn vai trò của bạn'),
          content: const Text(
              'Vì đây là lần đầu bạn đăng nhập bằng Google, vui lòng chọn vai trò để sử dụng ứng dụng.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(UserRole.tenant),
              child: const Text('Người Thuê Trọ'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(UserRole.landlord),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
              ),
              child: const Text('Chủ Trọ'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(null), // Cancel
              child: const Text('Hủy', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    ).then((role) {
      if (role != null) {
        ref.read(authControllerProvider.notifier).completeGoogleLogin(firebaseUser, role);
      } else {
        ref.read(authControllerProvider.notifier).cancelGoogleLogin();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listen to error states
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
          ),
        );
        ref.read(authControllerProvider.notifier).clearError();
      }

      // Lắng nghe sự kiện cần chọn role cho Google Login
      if (next.pendingGoogleUser != null && previous?.pendingGoogleUser == null) {
        _showGoogleRoleDialog(next.pendingGoogleUser!);
      }
    });

    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Stack(
              children: [
                Image.network(
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuD0PzLexj5_DTi4TURKg3nf4KDX39aGe9rYLahfW8JTI9hxT8rgBQZiRwM3rqNsEw4P1sPiHyiBoqwvH4sVP7Lvqv-pMtVj5KIYOx7y1VVK9k8ugXPrOtHunN5keY-b6mXcU4kJeebvqhlzUSPOqMJ3Bltn_hXDc3TxV4zTwwvg4FheKcTTk5i47Xc_pmECoBSLUUwa5mtJOeRVTHp1SNY2HVereUeOXh99yqXZEw9vWTCPjHUcVOgYOYbJRjYqVf11yS_TY8MNMdk',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
                // Blue overlay
                Container(
                  color: AppColors.primaryContainer.withOpacity(0.2),
                ),
                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.primaryContainer.withOpacity(0.6),
                        Colors.black.withOpacity(0.4),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top Area (Logo)
                Expanded(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: const Icon(
                        Icons.location_city,
                        color: Colors.white,
                        size: 60,
                      ),
                    ),
                  ),
                ),

                // Bottom Login Card
                Container(
                  width: double.infinity,
                  height: 618,
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 32,
                        offset: Offset(0, -8),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: AppSpacing.md),
                      // Handle Bar
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Header Text
                      Text(
                        'Hệ thống Quản lý và Thuê phòng trọ',
                        style: AppTypography.titleMD.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tại Quận Tân Phú và TP.HCM',
                        style: AppTypography.bodyMD.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Form Content
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Email Field
                                Text(
                                  'EMAIL',
                                  style: AppTypography.labelSM.copyWith(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                TextFormField(
                                  controller: _emailCtrl,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  decoration: InputDecoration(
                                    hintText: 'example@gmail.com',
                                    prefixIcon: const Icon(Icons.mail_outline),
                                    filled: true,
                                    fillColor: AppColors.surfaceContainerLow,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(AppRadius.input),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  validator: (v) => v!.isEmpty ? 'Vui lòng nhập Email' : null,
                                ),
                                const SizedBox(height: AppSpacing.lg),

                                // Password Field
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'MẬT KHẨU',
                                      style: AppTypography.labelSM.copyWith(
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {},
                                      child: Text(
                                        'Quên mật khẩu?',
                                        style: AppTypography.bodyMD.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                TextFormField(
                                  controller: _passwordCtrl,
                                  obscureText: _obscurePassword,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _login(),
                                  decoration: InputDecoration(
                                    hintText: '••••••••',
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                      ),
                                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                    ),
                                    filled: true,
                                    fillColor: AppColors.surfaceContainerLow,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(AppRadius.input),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  validator: (v) => v!.isEmpty ? 'Vui lòng nhập Mật khẩu' : null,
                                ),
                                const SizedBox(height: AppSpacing.lg),

                                // Login Button
                                SizedBox(
                                  width: double.infinity,
                                  height: AppSpacing.buttonHeight + 4,
                                  child: ElevatedButton(
                                    onPressed: authState.isLoading ? null : _login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: AppColors.onPrimary,
                                      elevation: 8,
                                      shadowColor: AppColors.primary.withOpacity(0.4),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(AppRadius.button),
                                      ),
                                    ),
                                    child: authState.isLoading
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                          )
                                        : Text(
                                            'Đăng Nhập',
                                            style: AppTypography.button.copyWith(fontSize: 16),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.lg),

                                // Divider
                                Row(
                                  children: [
                                    const Expanded(child: Divider(color: AppColors.outlineVariant)),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                                      child: Text(
                                        'HOẶC TIẾP TỤC VỚI',
                                        style: AppTypography.labelSM.copyWith(
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                    ),
                                    const Expanded(child: Divider(color: AppColors.outlineVariant)),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.lg),

                                // Social Buttons
                                Row(
                                  children: [
                                    Expanded(
                                      child: _SocialButton(
                                        iconUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBx0dkE9sQUw5nO-J2SJSqJ0nloegWvYn6GD4FSqNW7EJ98sSKDgGsh5oOiouoNsyKj6Y9MLKsqZZHuaX7AA-ur8NwlZbxgNHFp4ELf3USyskfr5l4SCisnSOUWDUtXsWXKBPt_Bti-oRuOF8XTzSH66PR6i6xnyTONn_GsBrhXyq885yEwcyhGYlz-11JJ5Cpk2ZwqSLTuXgstHqbGH-jtKRlDQfPXCWbrHpwmpP1jCFkfbv2ck3fj1H0oftTIkrGSrn1LXqrz6S8',
                                        text: 'Google',
                                        onTap: authState.isLoading ? null : _loginWithGoogle,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: _SocialButton(
                                        iconUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBv7ooy7GBwn7qq9f6Mf7stskscz8RhT1Is-HG3zkN7PvIMb818KE9sTKr3by8-qmKGKVPgLUbCL3lOibF0fJ3_EUofbafzanVXvFTrCsfdY8TyOHKn-X01ty5Drm2vY7pZ2D76_HDxfEKrsjfAdju6NggGqoImRv0V4ecIB2swpsnXgQbfXLRNqLIIUIE02OzsrrHrIHpttOkQY1O5wk2uI0KlWz2vyIAPFBQQX4Nqoepd0rQDbKorHbOP6Te-NW5h5v8OOWncCOU',
                                        text: 'Facebook',
                                        onTap: () {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Tính năng Facebook sẽ được phát triển sau')),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.xxl),
                                
                                // Footer
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Chưa có tài khoản? ',
                                      style: AppTypography.bodyMD.copyWith(
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () => context.go('/auth/register'),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Text(
                                        'Đăng ký ngay',
                                        style: AppTypography.bodyMD.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.lg),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String iconUrl;
  final String text;
  final VoidCallback? onTap;

  const _SocialButton({
    required this.iconUrl,
    required this.text,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.button),
          border: Border.all(color: AppColors.outlineVariant.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(iconUrl, width: 20, height: 20),
            const SizedBox(width: 8),
            Text(
              text,
              style: AppTypography.bodyMD.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
