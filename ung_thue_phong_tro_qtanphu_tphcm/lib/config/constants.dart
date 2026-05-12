import 'package:flutter/material.dart';

// ═══════════════════════════════════════════
// APP COLORS — Material 3 Tonal Palette
// ═══════════════════════════════════════════
class AppColors {
  // Primary
  static const Color primary = Color(0xFF005DAC);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF1976D2);
  static const Color onPrimaryContainer = Color(0xFFFFFFFF);

  // Surface — Tonal Layering
  static const Color surface = Color(0xFFF9F9F9);           // Background
  static const Color surfaceContainerLow = Color(0xFFF3F3F3);    // Content areas
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF); // Cards
  static const Color surfaceContainerHigh = Color(0xFFE8E8E8);   // Hover/divider

  // Text
  static const Color onSurface = Color(0xFF1A1C1C);         // Primary text
  static const Color onSurfaceVariant = Color(0xFF414752);   // Secondary text

  // Status Chips — Pastel
  static const Color available = Color(0xFF94F990);          // CÒN TRỐNG bg
  static const Color onAvailable = Color(0xFF002204);        // CÒN TRỐNG text
  static const Color rented = Color(0xFFE3E2E2);             // ĐÃ THUÊ bg
  static const Color onRented = Color(0xFF646464);           // ĐÃ THUÊ text
  static const Color overdue = Color(0xFFFFDAD6);            // QUÁ HẠN bg
  static const Color onOverdue = Color(0xFF93000A);          // QUÁ HẠN text

  // Outline
  static const Color outline = Color(0xFF717783);
  static const Color outlineVariant = Color(0xFFC1C6D4);

  // Error
  static const Color error = Color(0xFFD32F2F);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF93000A);

  // Shadow — Very limited (primary toned)
  static const Color shadow = Color(0x10005DAC);

  // Misc
  static const Color scrim = Color(0x99000000);

  AppColors._();
}

// ═══════════════════════════════════════════
// APP SPACING — 4dp Grid
// ═══════════════════════════════════════════
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  // Component heights
  static const double appBarHeight = 56;
  static const double bottomNavHeight = 80;
  static const double inputHeight = 56;
  static const double buttonHeight = 48;
  static const double chipHeight = 32;

  AppSpacing._();
}

// ═══════════════════════════════════════════
// APP TYPOGRAPHY — Roboto
// ═══════════════════════════════════════════
class AppTypography {
  static const String fontFamily = 'Roboto';

  static const TextStyle headlineLG = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.onSurface,
    height: 1.2,
    letterSpacing: -0.5,
  );

  static const TextStyle headlineMD = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.onSurface,
    height: 1.25,
  );

  static const TextStyle titleMD = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurface,
    height: 1.3,
  );

  static const TextStyle titleSM = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurface,
    height: 1.35,
  );

  static const TextStyle bodyMD = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurfaceVariant,
    height: 1.5,
  );

  static const TextStyle bodySM = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurfaceVariant,
    height: 1.4,
  );

  static const TextStyle labelSM = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurfaceVariant,
    height: 1.4,
    letterSpacing: 0.5,
  );

  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.onPrimary,
    height: 1.0,
  );

  AppTypography._();
}

// ═══════════════════════════════════════════
// APP RADIUS
// ═══════════════════════════════════════════
class AppRadius {
  static const double card = 12;
  static const double button = 8;
  static const double input = 8;
  static const double chip = 9999;
  static const double bottomSheet = 24;
  static const double avatar = 9999;

  AppRadius._();
}

// ═══════════════════════════════════════════
// APP SHADOWS — Very limited use
// ═══════════════════════════════════════════
class AppShadows {
  static const BoxShadow card = BoxShadow(
    color: AppColors.shadow,
    blurRadius: 4,
    offset: Offset(0, 2),
  );

  static const BoxShadow bottomSheet = BoxShadow(
    color: Color(0x1F000000),
    blurRadius: 10,
    offset: Offset(0, -4),
  );

  static const BoxShadow fab = BoxShadow(
    color: Color(0x33005DAC),
    blurRadius: 12,
    offset: Offset(0, 4),
  );

  AppShadows._();
}

// ═══════════════════════════════════════════
// APP GRADIENTS
// ═══════════════════════════════════════════
class AppGradients {
  static const LinearGradient primaryButton = LinearGradient(
    colors: [AppColors.primary, AppColors.primaryContainer],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient primaryFab = LinearGradient(
    colors: [AppColors.primary, AppColors.primaryContainer],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  AppGradients._();
}

// ═══════════════════════════════════════════
// APP STRINGS — Vietnamese
// ═══════════════════════════════════════════
class AppStrings {
  // App
  static const String appName = 'Phòng Trọ Tân Phú';
  static const String appTagline = 'Quản lý phòng trọ dễ dàng';

  // Auth
  static const String login = 'Đăng nhập';
  static const String register = 'Đăng ký';
  static const String email = 'Email';
  static const String password = 'Mật khẩu';
  static const String phone = 'Số điện thoại';
  static const String fullName = 'Họ và tên';
  static const String forgotPassword = 'Quên mật khẩu?';
  static const String noAccount = 'Chưa có tài khoản?';
  static const String haveAccount = 'Đã có tài khoản?';
  static const String loginWithGoogle = 'Đăng nhập với Google';
  static const String registerAsLandlord = 'Đăng ký làm chủ trọ';
  static const String registerAsTenant = 'Đăng ký tìm phòng';

  // Navigation — Tenant
  static const String explore = 'Khám phá';
  static const String rentals = 'Đặt phòng';
  static const String notifications = 'Thông báo';
  static const String profile = 'Cá nhân';

  // Navigation — Landlord
  static const String home = 'Trang chủ';
  static const String rooms = 'Phòng trọ';
  static const String add = 'Thêm';
  static const String contracts = 'Hợp đồng';
  static const String settings = 'Cài đặt';

  // Rooms
  static const String available = 'CÒN TRỐNG';
  static const String rented = 'ĐÃ THUÊ';
  static const String overdue = 'QUÁ HẠN';
  static const String pending = 'CHỜ DUYỆT';
  static const String roomList = 'Danh sách phòng';
  static const String viewAll = 'Xem tất cả';
  static const String totalRooms = 'Tổng số phòng';
  static const String myRooms = 'Phòng của tôi';
  static const String addRoom = 'Thêm phòng';
  static const String roomDetail = 'Chi tiết phòng';
  static const String price = 'Giá thuê';
  static const String area = 'Diện tích';
  static const String address = 'Địa chỉ';
  static const String description = 'Mô tả';
  static const String amenities = 'Tiện nghi';
  static const String contact = 'Liên hệ';
  static const String contactLandlord = 'Liên hệ chủ nhà';

  // Bills
  static const String bills = 'Hóa đơn';
  static const String createBill = 'Tạo hóa đơn';
  static const String electricity = 'Điện';
  static const String water = 'Nước';
  static const String internet = 'Internet';
  static const String trash = 'Rác';
  static const String totalAmount = 'Tổng tiền';
  static const String dueDate = 'Ngày đến hạn';
  static const String paid = 'ĐÃ THANH TOÁN';
  static const String unpaid = 'CHƯA THANH TOÁN';

  // Common
  static const String search = 'Tìm kiếm phòng trọ...';
  static const String cancel = 'Hủy';
  static const String confirm = 'Xác nhận';
  static const String save = 'Lưu';
  static const String edit = 'Chỉnh sửa';
  static const String delete = 'Xóa';
  static const String next = 'Tiếp theo';
  static const String back = 'Quay lại';
  static const String preview = 'Xem trước';
  static const String publish = 'Đăng phòng';
  static const String loading = 'Đang tải...';
  static const String error = 'Đã có lỗi xảy ra';
  static const String noData = 'Không có dữ liệu';
  static const String policy = 'Chính sách';

  AppStrings._();
}
