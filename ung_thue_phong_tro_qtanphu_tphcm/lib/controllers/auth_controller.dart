import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/entities/user.dart';

class AuthState {
  final AppUser? user;
  final bool isLoading;
  final String? error;
  final User? pendingGoogleUser;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.pendingGoogleUser,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    AppUser? user,
    bool? isLoading,
    String? error,
    User? pendingGoogleUser,
    bool clearUser = false,
    bool clearPending = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      error: error,
      pendingGoogleUser: clearPending ? null : (pendingGoogleUser ?? this.pendingGoogleUser),
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  AuthController() : super(const AuthState()) {
    // Tự động lắng nghe thay đổi trạng thái đăng nhập
    _auth.authStateChanges().listen((user) async {
      if (user != null) {
        final userModel = await _fetchUserFromDatabase(user.uid);
        if (userModel != null) {
          state = state.copyWith(user: userModel, isLoading: false);
        } else {
          // Người dùng bị kẹt: Có trong Auth nhưng chưa lưu vào Database (chưa chọn role)
          state = state.copyWith(pendingGoogleUser: user, isLoading: false);
        }
      } else {
        state = state.copyWith(user: null, isLoading: false, clearPending: true);
      }
    });
  }

  Future<void> loginWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final credential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      if (credential.user != null) {
        await _saveUserToDatabase(credential.user!);
        final userModel = await _fetchUserFromDatabase(credential.user!.uid);
        state = state.copyWith(user: userModel, isLoading: false);
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Đăng nhập thất bại';
      if (e.code == 'user-not-found') {
        errorMessage = 'Không tìm thấy tài khoản với email này';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Mật khẩu không đúng';
      } else if (e.code == 'invalid-credential') {
        errorMessage = 'Tài khoản hoặc mật khẩu không chính xác';
      }
      state = state.copyWith(isLoading: false, error: errorMessage);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Lỗi không xác định: $e',
      );
    }
  }

  Future<void> loginWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null, clearPending: true);
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        state = state.copyWith(isLoading: false);
        return; // Người dùng hủy đăng nhập
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      if (userCredential.user != null) {
        final ref = _db.ref('users/${userCredential.user!.uid}');
        final snapshot = await ref.get();
        
        if (!snapshot.exists) {
          // Người dùng mới -> Yêu cầu chọn role thông qua UI
          state = state.copyWith(pendingGoogleUser: userCredential.user, isLoading: false);
          return;
        }

        // Người dùng cũ -> Đăng nhập luôn
        final userModel = await _fetchUserFromDatabase(userCredential.user!.uid);
        state = state.copyWith(user: userModel, isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Đăng nhập Google thất bại: $e',
      );
    }
  }

  Future<void> completeGoogleLogin(User firebaseUser, UserRole role) async {
    state = state.copyWith(isLoading: true, clearPending: true);
    try {
      await _saveUserToDatabase(firebaseUser, role);
      final userModel = await _fetchUserFromDatabase(firebaseUser.uid);
      state = state.copyWith(user: userModel, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Lỗi hoàn tất đăng nhập: $e');
    }
  }

  Future<void> cancelGoogleLogin() async {
    state = state.copyWith(clearPending: true, isLoading: false);
    await _auth.signOut();
    await _googleSignIn.signOut();
  }

  Future<void> _saveUserToDatabase(User firebaseUser, [UserRole role = UserRole.tenant]) async {
    final ref = _db.ref('users/${firebaseUser.uid}');
    final snapshot = await ref.get();

    // Nếu user chưa có trong database, tiến hành tạo mới
    if (!snapshot.exists) {
      final newUser = AppUser(
        id: firebaseUser.uid,
        fullName: firebaseUser.displayName ?? 'Người dùng',
        email: firebaseUser.email ?? '',
        phone: firebaseUser.phoneNumber ?? '',
        role: role, // Gán role từ Google Login hoặc mặc định
        createdAt: DateTime.now(),
      );

      await ref.set({
        'id': newUser.id,
        'fullName': newUser.fullName,
        'email': newUser.email,
        'phone': newUser.phone,
        'role': newUser.role.name,
        'createdAt': newUser.createdAt.toIso8601String(),
      });
    }
  }

  Future<AppUser?> _fetchUserFromDatabase(String uid) async {
    try {
      final ref = _db.ref('users/$uid');
      final snapshot = await ref.get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        return AppUser(
          id: data['id'] ?? uid,
          fullName: data['fullName'] ?? '',
          email: data['email'] ?? '',
          phone: data['phone'] ?? '',
          role: UserRole.values.firstWhere(
            (e) => e.name == data['role'],
            orElse: () => UserRole.tenant,
          ),
          createdAt: data['createdAt'] != null
              ? DateTime.parse(data['createdAt'])
              : DateTime.now(),
        );
      }
    } catch (e) {
      // In log hoặc xử lý khi không lấy được
    }
    return null;
  }

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required UserRole role,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user != null) {
        await credential.user!.updateDisplayName(fullName);
        final newUser = AppUser(
          id: credential.user!.uid,
          fullName: fullName,
          email: email,
          phone: phone,
          role: role,
          createdAt: DateTime.now(),
        );

        await _db.ref('users/${newUser.id}').set({
          'id': newUser.id,
          'fullName': newUser.fullName,
          'email': newUser.email,
          'phone': newUser.phone,
          'role': newUser.role.name,
          'createdAt': newUser.createdAt.toIso8601String(),
        });

        await _auth.signOut();
        state = state.copyWith(isLoading: false);
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Đăng ký thất bại';
      if (e.code == 'email-already-in-use') {
        errorMessage = 'Email này đã được sử dụng';
      } else if (e.code == 'weak-password') {
        errorMessage = 'Mật khẩu quá yếu';
      }
      state = state.copyWith(isLoading: false, error: errorMessage);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Lỗi không xác định: $e');
    }
  }

  void logout() {
    _auth.signOut();
    _googleSignIn.signOut();
    state = const AuthState();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Providers
final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController();
});

final currentUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(authControllerProvider).user;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authControllerProvider).isAuthenticated;
});
