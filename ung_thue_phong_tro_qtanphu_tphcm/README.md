# Ứng Dụng Cho Thuê Phòng Trọ - Quận Tân Phú, TP.HCM

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=flat&logo=flutter)
![Firebase](https://img.shields.io/badge/Firebase-9.x-FFCA28?style=flat&logo=firebase)
![License](https://img.shields.io/badge/License-MIT-green)

</div>

## 📋 Giới Thiệu

Ứng dụng di động Flutter hỗ trợ cho thuê phòng trọ tại khu vực Quận Tân Phú, TP.HCM. Dự án hướng đến việc kết nối chủ trọ và người tìm thuê phòng một cách nhanh chóng và thuận tiện.

---

## 👥 Phân Loại Người Dùng

| Vai trò | Mô tả | Màn hình chính |
|---------|-------|----------------|
| **Tenant** (Người thuê) | Người tìm và thuê phòng trọ | `HomeScreen` |
| **Landlord** (Chủ trọ) | Chủ đầu tư cho thuê phòng | `DashboardScreen` |
| **Admin** *(Đang phát triển)* | Quản lý hệ thống | `AdminDashboardScreen` |

---

## 🚀 Tính Năng

### 🔑 Authentication
- Đăng nhập / Đăng ký tài khoản
- Phân quyền theo role (tenant / landlord / admin)
- Firebase Authentication (email/password)

### 🏠 Dành Cho Người Thuê (Tenant)
- **Trang chủ:** Danh sách phòng trọ available
- **Tìm kiếm nâng cao:** Lọc theo giá, diện tích, khu vực
- **Chi tiết phòng:** Xem thông tin, hình ảnh, tiện ích
- **Bản đồ:** Hiển thị vị trí phòng trên Google Maps
- **Phòng đang thuê:** Xem danh sách phòng đã thuê
- **Hóa đơn:** Xem lịch sử thanh toán
- **Liên hệ:** Liên hệ chủ trọ
- **Chính sách:** Xem quy định, điều khoản

### 🏢 Dành Cho Chủ Trọ (Landlord)
- **Dashboard:** Tổng quan thống kê (số phòng, doanh thu, khách thuê)
- **Quản lý phòng:** Thêm mới / chỉnh sửa / xóa phòng (3 bước)
- **Quản lý khách thuê:** Xem danh sách khách đang thuê
- **Tạo hóa đơn:** Tạo và gửi hóa đơn cho khách

### 🛠️ Dành Cho Admin *(Đang phát triển - branch: feature/admin-management)*
- Dashboard thống kê tổng quan
- Duyệt phòng trọ mới đăng
- Quản lý người dùng
- Xem tất cả hóa đơn

---

## 📁 Cấu Trúc Project

```
lib/
├── main.dart                      # Entry point
├── app.dart                       # App configuration
│
├── config/                        # Cấu hình
│   ├── routes.dart               # Định nghĩa routes
│   ├── theme.dart                # Theme & styling
│   ├── constants.dart            # Hằng số
│   └── google_maps_config.dart   # Google Maps API
│
├── controllers/                   # Logic xử lý
│   ├── auth_controller.dart       # Auth logic
│   └── providers/                 # State management (Provider)
│       ├── room_provider.dart
│       ├── bill_provider.dart
│       └── create_room_provider.dart
│
├── models/                        # Data models
│   └── entities/
│       ├── user.dart
│       ├── room.dart
│       ├── rental.dart
│       └── bill.dart
│
└── views/                         # Giao diện
    ├── screens/
    │   ├── auth/                  # Login, Register
    │   ├── shared/                # Splash
    │   ├── tenant/                # Màn hình người thuê
    │   ├── landlord/              # Màn hình chủ trọ
    │   └── admin/                 # Màn hình admin (mới)
    └── widgets/                   # Reusable components
        ├── cards/
        └── common/
```

---

## 🔧 Công Nghệ Sử Dụng

| Thành phần | Công nghệ |
|------------|-----------|
| Framework | Flutter 3.x |
| Language | Dart |
| State Management | Provider |
| Backend | Firebase (Firestore, Auth) |
| Maps | Google Maps Flutter |
| UI | Material Design 3 |

---

## 📋 Yêu Cầu Cài Đặt

```bash
# Clone repo
git clone https://github.com/HoangThaNHty/Do_An_MobileUngDungThuePhongTro.git

# Di chuyển vào thư mục
cd ung_thue_phong_tro_qtanphu_tphcm

# Cài đặt dependencies
flutter pub get

# Chạy ứng dụng
flutter run
```

---

## ⚙️ Cấu Hình

### Firebase
1. Tạo project Firebase tại [console.firebase.google.com](https://console.firebase.google.com)
2. Bật **Authentication** (Email/Password)
3. Bật **Firestore Database**
4. Tải `google-services.json` (Android) / `GoogleService-Info.plist` (iOS)
5. Đặt trong thư mục `android/app/` hoặc `ios/Runner/`

### Google Maps API
1. Lấy API Key tại [Google Cloud Console](https://console.cloud.google.com)
2. Bật **Maps SDK for Android** và **Maps SDK for iOS**
3. Cập nhật API Key trong:
   - `android/app/src/main/AndroidManifest.xml`
   - `lib/config/google_maps_config.dart`

### Environment Variables
Copy `.env.example` thành `.env` và điền thông tin:
```
GOOGLE_MAPS_API_KEY=your_api_key
FIREBASE_API_KEY=your_firebase_key
```

---

## 🔄 Quy Trình Làm Việc Với Git

```bash
# 1. Tạo branch mới cho feature
git checkout -b feature/ten-feature

# 2. Làm việc và commit
git add .
git commit -m "Mô tả công việc"

# 3. Push lên remote
git push origin feature/ten-feature

# 4. Tạo Pull Request trên GitHub để merge vào main
```

---

## 📝 Các Branch Hiện Tại

| Branch | Mô tả |
|--------|-------|
| `main` | Phiên bản chính (Tenant + Landlord) |
| `feature/admin-management` | Phát triển tính năng Admin |

---

## 🤝 Đóng Góp

Dự án này là bài tập lớn môn học. Mọi đóng góp và góp ý đều được hoan nghênh!

---

## 📄 License

MIT License - xem file [LICENSE](LICENSE) để biết thêm chi tiết.

---

## 📞 Liên Hệ

- **GitHub:** [HoangThaNHty](https://github.com/HoangThaNHty)
- **Email:** nguyenhoangthanhty.2503@gmail.com