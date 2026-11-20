# Movix 2Phim - Movie Streaming Application

<div align="center">
  <img src="app/web/icons/Icon-192.png" alt="Movix Logo" width="96" height="96" />
  <h3>Ứng dụng xem phim trực tuyến hiện đại, phong cách Movix Dark & PhimAPI</h3>
</div>

---

## 🌟 Giới thiệu
**Movix 2Phim** là ứng dụng xem phim trực tuyến đa nền tảng (Web, Android APK, iOS) được phát triển bằng Flutter, lấy cảm hứng từ bộ thiết kế UI Kit Movix với giao diện tông màu tối (`#181A20`) cao cấp, trực quan và tốc độ phản hồi nhanh.

Ứng dụng kết nối trực tiếp với **PhimAPI** (dữ liệu phim HD/FullHD cập nhật liên tục), không dùng dữ liệu giả lập (mock data) và hỗ trợ tài khoản VIP trọn đời.

---

## ✨ Tính năng nổi bật

### 1. 🎬 Trình phát Video chuyên nghiệp (Netflix & YouTube Gestures)
- **Cử chỉ YouTube:**
  - Chạm đúp 2 lần bên trái/phải màn hình để tua lùi/tiến 10 giây (kèm hiệu ứng sóng ripple mượt mà).
  - Nhấn giữ bất kỳ điểm nào trên video để phát nhanh tốc độ **2X**.
  - Chạm 1 lần để ẩn/hiện bảng điều khiển.
- **Tính năng phong cách Netflix:**
  - Nút **Bỏ qua đoạn mở đầu (Intro)** tích hợp thông minh cho phim bộ, tự động nhảy qua 01:30 đầu phim.
  - Tự động gợi ý và phát tập tiếp theo khi tập hiện tại sắp kết thúc.
  - Chuyển đổi linh hoạt giữa trình phát **HLS Tối ưu** và **Iframe Embed dự phòng**.
  - Chỉnh âm lượng trực tiếp với thanh trượt và nút tắt tiếng nhanh.
  - Tùy chỉnh chất lượng độ phân giải (1080p FHD, 720p HD, 480p SD, Tự động).
  - Tùy chỉnh tỉ lệ khung hình: Chuẩn 16:9 hoặc Zoom cắt tràn viền.
  - Khóa màn hình chống chạm nhầm khi đang thưởng thức phim.

### 2. 🔐 Hệ thống Xác thực & Tài khoản thật với Firebase
- **Đăng nhập Google thật 100%:** Tích hợp Firebase Authentication & Google Identity Services.
- **Đăng ký / Đăng nhập Email & Mật khẩu:** Quản lý thông tin hồ sơ người dùng thực tế.
- **Bảo mật cổng vào:** Bắt buộc đăng nhập trước khi vào trải nghiệm kho phim. Khi đăng xuất, tự động thoát ra màn hình chào mừng bên ngoài.
- **Đồng bộ hóa cá nhân:** Tự động lưu trữ danh sách phim yêu thích (My List), lịch sử xem phim và bình luận theo thời gian thực vào bộ nhớ thiết bị.

### 3. 📱 Thiết kế Responsive Đa Nền Tảng
- Tối ưu hoàn hảo cho mọi kích thước màn hình: Mobile dọc, Tablet xoay ngang, và Trình duyệt Web.
- Giao diện ngang thông minh: Bảng cài đặt phát tự động chia 2 cột tiện lợi, thanh điều hướng sidebar tự căn chỉnh không bị tràn khung.

---

## 🚀 Hướng dẫn cài đặt & Chạy ứng dụng

### Yêu cầu hệ thống:
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (phiên bản 3.24 trở lên)
- Git

### 1. Cài đặt dependencies:
```bash
cd app
flutter pub get
```

### 2. Chạy trên Web:
```bash
flutter run -d chrome
```

### 3. Build file APK Android Release:
```bash
flutter build apk --release
```
File APK cài đặt sẽ nằm tại thư mục: `app/build/app/outputs/flutter-apk/app-release.apk`.

### 4. Build bản Web Release:
```bash
flutter build web --release
```

---

## 📦 Tải bản phát hành (Releases)
Tải file cài đặt APK mới nhất dành cho Android tại mục [Releases](https://github.com/phanan04/Movix/releases).
