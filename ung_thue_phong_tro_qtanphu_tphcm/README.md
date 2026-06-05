# Ứng Dụng Cho Thuê Phòng Trọ - Quận Tân Phú, TP.HCM

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=flat&logo=flutter)
![Firebase](https://img.shields.io/badge/Firebase-9.x-FFCA28?style=flat&logo=firebase)
![License](https://img.shields.io/badge/License-MIT-green)

</div>

## 📋 Giới Thiệu

Ứng dụng di động Flutter hỗ trợ cho thuê phòng trọ tại khu vực Quận Tân Phú, TP.HCM. Dự án hướng đến việc kết nối chủ trọ và người tìm thuê phòng một cách nhanh chóng và thuận tiện. Phiên bản này đã được nâng cấp toàn diện lên chuẩn thương mại cao cấp (Premium) với hệ thống bảo mật cách ly dữ liệu hai chiều, cổng thanh toán VietQR Napas động, bản đồ mini thông minh định tuyến nội bộ (In-App Direction) và kịch bản seeder tài khoản test tự động.

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
- **Chế độ Tester tiện lợi:** Khi quên mật khẩu, nhập bất kỳ email đuôi `@email.com` của hệ thống ảo (như `khang.demo@email.com` hoặc `chutro.demo@email.com`), hệ thống tự động reset mật khẩu về `123456` trực quan trên màn hình để test tiếp mà không cần check hòm thư ảo. Nhập email thật sẽ gửi email khôi phục Gmail thực tế.
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

## ✅ Cập Nhật Demo & Tester - 05/06/2026

Phiên bản mới nhất đã được chỉnh lại để nhóm demo theo luồng thực tế, tránh dữ liệu test bị lẫn hoặc màn hình trắng khi nghiệm thu.

### Luồng thanh toán hóa đơn đã hoàn chỉnh
1. Chủ trọ chỉ tạo hóa đơn được cho **phòng có hợp đồng đang thuê thật sự**. Phòng chỉ bị gạt trạng thái thủ công sang "Đã thuê" sẽ không xuất hiện trong màn tạo hóa đơn.
2. Mỗi người thuê chỉ có **1 hóa đơn tháng hiện tại cho mỗi phòng**. Nếu nhập sai, chủ trọ vào **Người thuê -> Lịch sử hóa đơn** để xóa hóa đơn khi khách chưa thanh toán.
3. Khi chủ trọ tạo hóa đơn tháng, người thuê sẽ thấy thông báo ngay trên trang **Khám phá** và trong tab **Đặt phòng**:
   - "Có hóa đơn mới cần thanh toán" nếu chưa chuyển khoản.
   - "Đang chờ chủ trọ duyệt thanh toán" nếu khách đã báo chuyển khoản.
4. Người thuê bấm **Thanh toán qua VietQR**, quét QR, rồi bấm **Tôi đã chuyển khoản thành công**. Hóa đơn chuyển sang trạng thái chờ duyệt.
5. Chủ trọ nhận banner **Có thanh toán cần xác nhận** ở Dashboard và cả màn **Quản lý người thuê**. Bấm **Duyệt** để mở danh sách hóa đơn chờ duyệt trực tiếp, không còn bị màn hình trắng.
6. Chủ trọ có thể duyệt hoặc từ chối giao dịch. Khi duyệt, hóa đơn chuyển sang **Đã thanh toán** realtime cho cả hai phía.

### Những lỗi đã khóa để tránh demo sai
- Không cho gỡ/xóa bài đăng phòng đang có hợp đồng thuê hoặc đang cọc giữ chỗ.
- Không cho đổi phòng đang thuê thật về trạng thái còn trống bằng thao tác gạt thủ công.
- Lịch sử hóa đơn chủ trọ lấy từ nguồn tổng hợp realtime, không phụ thuộc cache cũ nên không còn trắng khi có hóa đơn chờ duyệt.
- Màn hóa đơn của người thuê lọc theo đúng phòng đang xem, tránh lẫn hóa đơn giữa nhiều phòng.
- QR VietQR dùng nền sáng cố định để đảm bảo app ngân hàng quét được dù app đang ở chế độ tối.

### Lưu ý khi test trên điện thoại thật
- Sau khi pull code mới, nên chạy lại bằng `flutter run` hoặc cài lại APK debug. Không chỉ hot reload nếu có thay đổi provider/Firebase.
- Nếu dữ liệu demo bị rối do test nhiều lần, chạy lại script `./test/auto_auth_seeder.ps1` để reset về bộ dữ liệu chuẩn demo.
- Không commit file `.env`, APK build, hoặc tài liệu Word cá nhân vào repo.

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
├── repositories/                  # Kết nối các dịch vụ ngoại vi
│   ├── room_repository.dart       # Đăng phòng, đổi trạng thái, sửa phòng trên Firebase
│   └── storage_repository.dart    # Đăng tải hình ảnh & video lên Cloudinary API
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
| Storage | Cloudinary API (Lưu trữ hình ảnh & video chuyên dụng) |
| Maps | Google Maps Flutter (Polyline Drawing & Directions) |
| UI | Material Design 3 (HSL Harmony Premium, Glassmorphism, Micro-animations) |

---

## 📋 Yêu Cầu Cài Đặt Cho Các Thành Viên Trong Nhóm

Hãy thực hiện các bước sau để thiết lập dự án chuẩn và chạy thử nghiệm mượt mà 100%:

```bash
# 1. Clone repository về máy (Sử dụng branch mới đã nâng cấp bảo mật & Premium)
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

* **Danh sách tài khoản demo sau khi đồng bộ:**
  1. **Admin hệ thống:** `admin.demo@email.com` / `123456` (Giám sát tổng quan tài khoản, phòng, hợp đồng và hóa đơn).
  2. **Chủ trọ Nguyễn Văn An:** `chutro.demo@email.com` / `123456` (Sở hữu 6 phòng trọ đang trống, dữ liệu phù hợp để thuyết trình).
  3. **Người thuê mới Trần Minh Khang:** `khang.demo@email.com` / `123456` (Chưa thuê phòng, chưa đặt cọc, chưa có hóa đơn/chat).
  4. **Người thuê mới Lê Ngọc Mai:** `mai.demo@email.com` / `123456` (Chưa thuê phòng, chưa đặt cọc, chưa có hóa đơn/chat).

### 2. Thiết lập cấu hình API Keys (.env)
Tạo file `.env` tại thư mục gốc của dự án `ung_thue_phong_tro_qtanphu_tphcm/` và điền cấu hình API của dự án:
```env
GOOGLE_MAPS_API_KEY=your_google_maps_api_key_here
FIREBASE_API_KEY=your_firebase_api_key_here
```

### 3. Cấu hình Lưu trữ Hình ảnh & Video (Cloudinary Storage - Thay thế Firebase Storage)
Để tối ưu hóa tốc độ tải ảnh, xử lý video giới thiệu và tránh các giới hạn băng thông/chi phí của Firebase Storage, ứng dụng đã được tích hợp **Cloudinary** làm giải pháp lưu trữ hình ảnh & video chuyên dụng:
* **Cấu hình sẵn có**: Dự án đã được thiết lập sẵn Cloud Name (`dl0ltsay7`) và Unsigned Upload Preset (`ml_default`) hoạt động ngay lập tức không cần cấu hình thêm.
* **Tự cấu hình lại (Nếu muốn dùng tài khoản Cloudinary riêng)**:
  1. Đăng ký tài khoản miễn phí tại [Cloudinary](https://cloudinary.com).
  2. Tạo một **Unsigned Upload Preset** (ví dụ: `ml_default`) trong mục *Settings -> Upload -> Upload presets*.
  3. Mở tệp `lib/repositories/storage_repository.dart` và cập nhật các thông số:
     ```dart
     static const String _cloudName = 'your_cloud_name_cua_ban';
     static const String _uploadPreset = 'your_upload_preset_cua_ban';
     ```

---

## 📝 Nhật Ký Các Chi Nhánh (Branches)

| Chi nhánh | Mô tả | Trạng thái |
|-----------|-------|------------|
| `main` | Phiên bản gốc của nhóm | Ổn định |
| `feature/premium-upgrades-and-privacy` | **Phiên bản mới nhất nâng cấp Premium, VietQR Payment & Cách ly chống rò rỉ dữ liệu** | **Hoàn thành - Sẵn sàng nghiệm thu** |
| `feature/demo-ready-clean-data` | Nhánh song song chứa cùng bộ sửa demo, dùng khi cần reset/test dữ liệu sạch nhanh | Sẵn sàng test |
| `feature/admin-management` | Tính năng Admin đang phát triển | Đang phát triển |
