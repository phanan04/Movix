# Quy Định Hệ Thống Màu Sắc & Phong Cách Giao Diện Movix (Design System)

> **Mục đích:** Mọi màn hình, widget, nút bấm, huy hiệu (badge), thẻ (card) và hộp thoại trong dự án Movix **bắt buộc** phải tuân thủ bảng màu và quy chuẩn dưới đây. Không tự ý thêm màu thương hiệu bên thứ ba hoặc màu không đồng bộ vào giao diện.

---

## 1. Bảng Màu Chính Thức (`app/lib/core/theme/app_colors.dart`)

Luôn import và sử dụng token từ `AppColors`, **hạn chế tối đa** việc viết mã màu `Color(0xFF...)` trực tiếp trong UI widget.

### 1.1. Màu Thương Hiệu (Brand Red — Netflix / Movix Signature)
| Token | Mã Hex | Mục đích sử dụng |
|---|---|---|
| `AppColors.primary` | `#E50914` | Nút hành động chính (Xem ngay, Áp dụng), tab đang chọn, icon active, thanh tiến độ xem, dấu kiểm active |
| `AppColors.primaryDark` | `#C10712` | Trạng thái nhấn (pressed/hover) của nút chính |
| `AppColors.primaryLight` | `#FF333A` | Chữ / icon nổi bật trên nền tối mờ của badge thương hiệu |
| `AppColors.primaryMuted` | `rgba(229, 9, 20, 0.15)` | Nền nhẹ cho chip đang chọn, badge thương hiệu (`TMDb`, `TMDb Smart Match`, `TMDb Critic`, trạng thái đã lưu) |
| `AppColors.primaryBorder` | `rgba(229, 9, 20, 0.40)` | Viền nhẹ cho chip/badge mang sắc đỏ Movix |

### 1.2. Màu Nền & Bề Mặt Tối (Cinematic OLED Dark)
| Token | Mã Hex | Mục đích sử dụng |
|---|---|---|
| `AppColors.background` | `#0F1014` | Nền chính toàn ứng dụng |
| `AppColors.surface` | `#16181F` | Nền thẻ phim, popup menu, bottom sheet, khung chứa |
| `AppColors.surfaceLight` | `#1E212A` | Nền nút phụ, chip chưa chọn, thẻ khi hover/focus |
| `AppColors.surfaceDarker` | `#0B0C0E` | Nền thanh điều hướng (sidebar/bottom bar) |
| `AppColors.surfaceInput` | `#1B1E28` | Nền ô nhập liệu (tìm kiếm, form) |

### 1.3. Màu Viền & Phân Cách
| Token | Mã Hex | Mục đích sử dụng |
|---|---|---|
| `AppColors.border` | `#222530` | Viền mặc định cho card, khung nội dung |
| `AppColors.borderLight` | `#2E3240` | Viền nút phụ, chip nổi bật vừa phải |
| `AppColors.borderSubtle` | `rgba(255, 255, 255, 0.18)` | Đường phân cách mảnh, viền kính mờ |

### 1.4. Hệ Thống Chữ (Typography)
| Token | Mã Hex | Mục đích sử dụng |
|---|---|---|
| `AppColors.textPrimary` | `#FFFFFF` | Tiêu đề chính, tên phim, nhãn nút active |
| `AppColors.textSecondary` | `#C4C7D4` | Mô tả nội dung, tên gốc, thông tin phụ |
| `AppColors.textMuted` | `#7E8494` | Nhãn thời gian, gợi ý (placeholder), icon không hoạt động |

### 1.5. Màu Trạng Thái & Đánh Giá (Dùng đúng ngữ cảnh)
| Token | Mã Hex | Ngữ cảnh cho phép |
|---|---|---|
| `AppColors.star` | `#FFB800` | Biểu tượng ngôi sao đánh giá điểm số (`8.0 ★`, `9/10`) |
| `AppColors.success` | `#12D18E` | Thông báo thành công (toast thành công, trạng thái hoàn tất) |
| `AppColors.warning` | `#FACC15` | Cảnh báo nhẹ |

---

## 2. Hệ Thống Phông Chữ (`app/lib/core/theme/app_typography.dart`)

- **Phông chữ duy nhất toàn app:** **`Be Vietnam Pro`** (hỗ trợ đầy đủ dấu tiếng Việt hiện đại, sắc nét trên cả Mobile, Tablet, Web và TV).
- **Quy tắc dùng token:** Ưu tiên dùng `AppTypography.*` (hoặc `Theme.of(context).textTheme.*`) thay cho `TextStyle(...)` viết tay rời rạc.
- **Kích thước tối thiểu:** Không dùng cỡ chữ nhỏ hơn **`10.5px`** cho badge/metadata để đảm bảo khả năng đọc trên màn hình nhỏ và TV.

| Token | Kích thước | Độ đậm | Màu mặc định | Mục đích sử dụng |
|---|---|---|---|---|
| `AppTypography.heroTitle` | `30px` | `w900` | `textPrimary` | Tiêu đề lớn trên Hero Banner (Tablet/Desktop) |
| `AppTypography.displayLarge` | `26px` | `w800` | `textPrimary` | Tiêu đề chính trang Chi tiết phim |
| `AppTypography.titleLarge` | `20px` | `w700` | `textPrimary` | Tiêu đề AppBar, tiêu đề màn hình |
| `AppTypography.sectionTitle` | `18px` | `w700` | `textPrimary` | Tiêu đề các hàng danh mục phim (Carousel) |
| `AppTypography.titleMedium` | `16px` | `w600` | `textPrimary` | Tiêu đề khối nội dung, modal, tab |
| `AppTypography.titleSmall` | `14px` | `w600` | `textPrimary` | Tên phim trên thẻ card, tiêu đề phụ |
| `AppTypography.bodyLarge` | `15px` | `w400` | `textSecondary` | Văn bản nội dung chính |
| `AppTypography.bodyMedium` | `13.5px` | `w400` | `textSecondary` | Tóm tắt nội dung phim, bài đánh giá (line-height `1.45`) |
| `AppTypography.bodySmall` | `12px` | `w400` | `textSecondary` | Thông tin metadata (năm, thể loại, diễn viên) |
| `AppTypography.buttonLarge` | `15px` | `w700` | `textPrimary` | Nhãn nút hành động chính (Xem phim, Áp dụng) |
| `AppTypography.buttonMedium` | `14px` | `w600` | `textPrimary` | Nhãn nút phụ |
| `AppTypography.labelMedium` | `12px` | `w500` | `textMuted` | Nhãn mô tả phụ |
| `AppTypography.labelSmall` | `11px` | `w600` | `textMuted` | Nhãn nhỏ (số tập, ngày tháng) |
| `AppTypography.badge` | `10.5px` | `w700` | `textPrimary` | Huy hiệu (`FHD`, `16+`, điểm sao, `TMDb Critic`) |

---

## 3. Quy Tắc Bắt Buộc Khi Thiết Kế UI Mới

1. **Tuyệt đối KHÔNG dùng màu thương hiệu bên ngoài:**
   - **CẤM** sử dụng màu xanh cyan (`#01B4E4`), xanh dương neon, tím, hồng, cam chói... cho nút, tab, badge, viền hoặc hiệu ứng phát sáng — kể cả khi hiển thị tính năng tích hợp dữ liệu từ TMDb hay bên thứ ba.
   - Mọi huy hiệu hoặc tab liên quan đến nguồn dữ liệu (`TMDb`, `KKPhim`, `TMDb Smart Match`, `TMDb Critic`, `Đánh giá quốc tế`) đều phải dùng **tông Đỏ Movix** (`AppColors.primary`, `AppColors.primaryMuted`, `AppColors.primaryBorder`, `AppColors.primaryLight`) hoặc **tông Trung Tính Tối** (`AppColors.surfaceLight`, `AppColors.borderLight`).
2. **Tối giản & Thống nhất:**
   - Giữ bảng màu gọn nhẹ theo phong cách rạp phim tối giản (Dark OLED + Trắng + Đỏ `#E50914` + Vàng sao `#FFB800`).
   - Không lạm dụng icon trang trí thừa, emoji trong tiêu đề danh mục, hoặc viền phát sáng sặc sỡ quanh logo/sidebar.
3. **Kiểm tra trước khi commit:**
   - Rà soát các file mới/sửa đổi để đảm bảo không chứa mã màu lạ ngoài `AppColors`.
