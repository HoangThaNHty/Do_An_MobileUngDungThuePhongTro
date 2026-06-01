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

## 🚀 Tính Năng Nổi Bật (Premium Upgrades & QA Fixed)

Ứng dụng đã được nâng cấp lên chuẩn sản phẩm thương mại cao cấp với các tính năng đột phá:

### 🔑 Authentication & Tester Hybrid Mode
- **Chế độ Tester tiện lợi:** Khi quên mật khẩu, nhập bất kỳ email đuôi `@email.com` của hệ thống ảo (như `namle@email.com` hoặc `annguyen@email.com`), hệ thống tự động reset mật khẩu về `123456` trực quan trên màn hình để test tiếp mà không cần check hòm thư ảo. Nhập email thật sẽ gửi email khôi phục Gmail thực tế.
- **Đồng bộ Avatar tức thì:** Đổi ảnh đại diện sẽ lưu đồng bộ ngay lập tức thời gian thực lên Firebase Realtime Database.

### 🏠 Tính năng Người Thuê (Tenant Premium)
- **Đường đi In-App Polyline:** Bản đồ mini nâng cấp kéo thả mượt mà, vẽ tuyến đường nét đứt màu tím primary độc quyền chỉ từ GPS hiện tại của khách thuê đến trực tiếp phòng trọ.
- **Nút Dẫn đường nổi:** Chuyển hướng nhanh sang ứng dụng Google Maps ngoại vi trên máy điện thoại để dẫn đường lái xe thời gian thực GPS.
- **Cọc giữ chỗ & Ví trung gian:** Hiển thị banner bảo chứng xanh **"Ví trung gian Platform bảo lãnh"** tạo lòng tin tuyệt đối cho người thuê.
- **Thanh toán VietQR Napas P2P:** Tự động tạo mã QR động ngân hàng MB Bank tích hợp sẵn số tiền, người nhận (số điện thoại chủ trọ), kèm lời nhắn không dấu tự động.
- **Xác minh 2 chiều chống gian lận:** Khách báo chuyển tiền xong, hóa đơn chuyển sang trạng thái vàng **"ĐANG CHỜ DUYỆT ⏳"** và khóa nút thanh toán.

### 🏢 Tính năng Chủ Trọ (Landlord Premium)
- **Zero-Leakage (Cách ly dữ liệu 100%):** Áp dụng cơ chế bảo mật kép hai chiều (Double-Layer Security). Bích Trần đăng nhập sẽ chỉ nhìn thấy phòng và người thuê của riêng mình. Mọi thông tin hợp đồng, hóa đơn, chat của Nguyễn Văn An được mã hóa cách ly tuyệt đối, loại bỏ hoàn toàn việc hiển thị chéo.
- **Lập hóa đơn thông minh (Smart Billing Engine):**
  - **Chặn lập trùng hóa đơn:** Tự động quét và khóa nút Tạo, hiện banner cảnh báo đỏ nếu phòng đã được lập hóa đơn trong tháng này.
  - **Thẻ hồ sơ đối chiếu:** Hiện Avatar, Tên, SĐT khách thuê ngay khi chọn phòng để đối chiếu tránh lập nhầm.
  - **Gợi ý chỉ số cũ:** Tự động tra cứu và hiển thị lượng điện cũ, nước cũ tháng trước của phòng để tiện nhập liệu.
  - **Thêm dịch vụ động vô hạn:** Cho phép bấm nút thêm dịch vụ tùy biến (ví dụ: phí gửi xe, giặt ủi, dọn dẹp) nhập tự do và tự động cộng dồn lên Firebase.
- **Quản lý lịch sử hóa đơn:** Nút xem lịch sử hóa đơn trên từng thẻ người thuê. Cho phép hủy/xóa hóa đơn lỗi (chưa thanh toán) trực tiếp khỏi Firebase Realtime Database.
- **Xóa độc lập giao dịch đã hủy:** Cả chủ trọ và khách thuê có quyền ẩn/xóa thẻ giao dịch bị hủy ở phía mình mà không ảnh hưởng tới người còn lại. Khi cả 2 cùng xóa, bản ghi sẽ tự động xóa sạch hoàn toàn khỏi cơ sở dữ liệu.

---

## 📁 Cấu Trúc Project

```
lib/
├── main.dart                      # Khởi tạo & Định dạng hướng Portrait màn hình
├── app.dart                       # Route & Theme binding
│
├── config/                        # Cấu hình
│   ├── routes.dart               # Định nghĩa các GoRouter URL & Kiểm tra phân quyền truy cập chéo (IDOR blocks)
│   ├── theme.dart                # Bảng màu Harmony HSL, Premium Glassmorphism
│   └── constants.dart            # Định nghĩa các hằng số Typography, Spacing, Radius
│
├── controllers/                   # Controllers quản lý logic nghiệp vụ
│   ├── auth_controller.dart       # Đăng ký, Đăng nhập, Reset mật khẩu tester ảo & thật
│   ├── booking_controller.dart    # Lập cọc, thanh toán cọc, giải ngân, hủy giao dịch ẩn độc lập
│   ├── chat_controller.dart       # Quét phòng chat, gửi tin nhắn, đếm tin chưa đọc thời gian thực
│   ├── review_controller.dart     # Tạo đánh giá, tính điểm trung bình cộng rating của chủ trọ
│   └── providers/                 # State management (Riverpod Providers)
│       ├── room_provider.dart     # Quản lý danh sách phòng & Lọc tìm kiếm cục bộ
│       ├── bill_provider.dart     # Danh sách hóa đơn, cách ly doanh thu & Thống kê Dashboard
│       └── create_room_provider.dart
│
├── models/                        # Định nghĩa thực thể dữ liệu (Data models)
│   └── entities/
│       ├── user.dart              # Thông tin mở rộng: Quê quán, Năm sinh, Giới tính, Bio...
│       ├── room.dart              # Tọa độ Map, URL Video giới thiệu, landlordId...
│       ├── rental.dart            # Cờ showToLandlord, showToTenant cách ly xóa độc lập...
│       └── bill.dart              # Cờ paymentSubmitted, các trường cộng dồn...
│
├── repositories/                  # Kết nối Firebase Realtime Database
│   └── room_repository.dart       # Đăng phòng, đổi trạng thái, sửa phòng
│
└── views/                         # Giao diện hiển thị
    ├── screens/
    │   ├── auth/                  # Màn hình đăng ký, đăng nhập chống tràn bàn phím ảo
    │   ├── shared/                # Splash Screen, Chat Room bảo mật, Danh sách nhắn tin
    │   ├── tenant/                # Màn hình Tenant (VietQR sheet, Mini-map Polyline...)
    │   └── landlord/              # Màn hình Landlord (Quản lý người thuê, Lịch sử, Duyệt tiền...)
    └── widgets/                   # Các thành phần tái sử dụng (Reusable widgets)
        ├── cards/                 # RoomCard, StatCard...
        └── common/                # AppButton, Shimmer loading, Scaffolds...
```

---

## 🔧 Công Nghệ Sử Dụng

| Thành phần | Công nghệ |
|------------|-----------|
| Framework | Flutter 3.x |
| Language | Dart |
| State Management | Riverpod (Hệ thống provider đồng bộ tối ưu) |
| Backend | Firebase (Realtime Database, Authentication) |
| Maps | Google Maps Flutter (Polyline Drawing & Directions) |
| UI | Material Design 3 (HSL Harmony Premium, Glassmorphism, Micro-animations) |

---

## 📋 Yêu Cầu Cài Đặt Cho Các Thành Viên Trong Nhóm

Hãy thực hiện các bước sau để thiết lập dự án chuẩn và chạy thử nghiệm mượt mà 100%:

```bash
# 1. Clone repository về máy
git clone -b feature/premium-upgrades-and-privacy https://github.com/HoangThaNHty/Do_An_MobileUngDungThuePhongTro.git

# 2. Di chuyển vào thư mục ứng dụng chính
cd ung_thue_phong_tro_qtanphu_tphcm

# 3. Cài đặt các gói thư viện dependencies
flutter pub get

# 4. Chạy phân tích mã nguồn để kiểm tra sạch lỗi
flutter analyze

# 5. Chạy bộ kiểm thử tự động để đảm bảo luồng hoạt động ổn định
flutter test

# 6. Khởi chạy ứng dụng lên máy ảo hoặc thiết bị thật
flutter run
```

---

## ⚙️ Thiết Lập Firebase & Đồng Bộ Hóa Tester Accounts

Để toàn bộ thành viên trong nhóm có thể dùng chung tài khoản test và dữ liệu đồng bộ tức thì với cơ sở dữ liệu, tôi đã trang bị một kịch bản seeder tự động cực kỳ thông minh:

### 1. Đồng bộ tài khoản test thông minh (Mật khẩu mặc định: `123456`)
Trước khi chạy ứng dụng lần đầu, hãy mở **PowerShell** tại thư mục `ung_thue_phong_tro_qtanphu_tphcm` và chạy lệnh sau để tự động tạo tài khoản kiểm thử trên Authentication và đồng bộ dữ liệu chuẩn lên Realtime Database:

```powershell
# Chạy script seeder tự động hóa đồng bộ tài khoản test
./test/auto_auth_seeder.ps1
```

* **Danh sách tài khoản test sau khi đồng bộ:**
  1. **Chủ trọ Nguyễn Văn An:** `annguyen@email.com` / `123456` (Sở hữu 6 phòng trọ có sẵn, có lịch sử hóa đơn và người thuê).
  2. **Chủ trọ Trần Thị Bích:** `bichtran@email.com` / `123456` (Sở hữu 4 phòng trọ trống).
  3. **Khách thuê Lê Hoàng Nam:** `namle@email.com` / `123456`.
  4. **Khách thuê Phạm Thị Lan:** `lanpham@email.com` / `123456`.

### 2. Thiết lập cấu hình API Keys (.env)
Tạo file `.env` tại thư mục gốc của dự án `ung_thue_phong_tro_qtanphu_tphcm/` và điền cấu hình API của dự án:
```env
GOOGLE_MAPS_API_KEY=your_google_maps_api_key_here
FIREBASE_API_KEY=your_firebase_api_key_here
```

---

## 📝 Nhật Ký Các Chi Nhánh (Branches)

| Chi nhánh | Mô tả | Trạng thái |
|-----------|-------|------------|
| `main` | Phiên bản gốc của nhóm | Ổn định |
| `feature/premium-upgrades-and-privacy` | **Phiên bản mới nhất nâng cấp Premium, VietQR Payment & Cách ly chống rò rỉ dữ liệu** | **Hoàn thành - Sẵn sàng nghiệm thu** |
| `feature/admin-management` | Tính năng Admin đang phát triển | Đang phát triển |
