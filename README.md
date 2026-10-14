# Jetsam Changer ⚡ (iOS 17.x – 18.x)

[![Build Jetsam Changer (iOS 17.x - 18.x)](https://github.com/Mobimi/jetsam-ios-16-18/actions/workflows/build.yml/badge.svg)](https://github.com/Mobimi/jetsam-ios-16-18/actions/workflows/build.yml)

Ứng dụng iOS quản lý và can thiệp bộ nhớ **Jetsam** trực tiếp trên **iOS 17.0 - 18.x** với cơ chế **Automated Kernel Exploit** và **Dynamic Offset Calibration** tích hợp, cho phép điều chỉnh giới hạn RAM (`high_water_mark`), độ ưu tiên tiến trình (`effective_priority`), và chế độ **Không Giới Hạn (Unlimited ∞ - Không bao giờ bị Jetsam kill)** cho các ứng dụng nặng như Minecraft Java (Amethyst, PojavLauncher), giả lập (Dolphin, MeloNX, UTM), hoặc các app sideload khác.

---

## 📱 Giao Diện Đơn Giản & Dễ Dùng (2 Tabs)

Ứng dụng được thiết kế tối giản, tập trung vào 2 mục chính:

### 1. Tab `Danh Sách App` (List App)
- **Thanh tìm kiếm thông minh:** Gõ tên app (ví dụ: `Amethyst`, `Pojav`, `Dolphin`) hoặc `Bundle ID` là app sẽ lập tức xuất hiện.
- **Lưu ý quan trọng:** Bắt buộc ứng dụng bạn muốn chỉnh **phải được mở trước** trên thiết bị (đang chạy trong nền). Các app chưa được mở sẽ không hiển thị trong danh sách.
- **Thẻ thông tin app:** Hiển thị trực quan icon, tên, PID, lượng RAM đang sử dụng thực tế và giới hạn Jetsam hiện tại.
- **Bảng chỉnh Jetsam chuyên sâu:** Khi chạm vào app, bạn sẽ được chuyển sang giao diện chỉnh sửa:
  - Thanh trượt chỉnh RAM từ 512 MB lên đến 16 GB.
  - Công tắc **Không Giới Hạn (Unlimited ∞)** gỡ bỏ hoàn toàn ranh giới kill của Jetsam.
  - Các cấu hình khuyến nghị (Presets) 1-chạm: Amethyst/Pojav (6GB), Giả lập (4GB), Không giới hạn, Mặc định iOS.
  - **Nút Áp Dụng (Apply):** Sau khi bấm, sẽ có **thông báo trạng thái rõ ràng ở dưới** (màu xanh nếu thành công, màu đỏ kèm lý do nếu thất bại).

### 2. Tab `Cài Đặt` (Settings & Console)
- **Status Check Kernel Exploit:** Thẻ trạng thái trực quan với đèn báo (Xanh lá: Đã Exploit thành công, Vàng: Đang chạy, Đỏ: Chưa kích hoạt).
- **Nút Kích Hoạt / Chạy Lại Auto Exploit:** Tự động thực hiện toàn bộ quy trình nhận diện thiết bị, groom heap, leak kernel base và mở khóa quyền đọc/ghi kernel struct.
- **Bảng Console & Log Lỗi:**
  - Hộp terminal hiển thị trực tiếp từng dòng lệnh và tiến trình khai thác kernel.
  - Bộ lọc **Chỉ Xem Log Lỗi [X]** giúp nhanh chóng chẩn đoán sự cố.
  - Nút sao chép toàn bộ log vào Clipboard để báo cáo lỗi.

---

## 🛠️ GitHub Workflow Tự Động Build

Dành cho người dùng không có máy Mac: kho lưu trữ đã tích hợp sẵn GitHub Actions Workflow (`.github/workflows/build.yml`).

### Cách lấy file `.tipa` / `.ipa`:
1. Push mã nguồn lên branch `main` của repo: `https://github.com/Mobimi/jetsam-ios-16-18`.
2. Truy cập tab **Actions** trên GitHub để theo dõi tiến trình build tự động trên máy ảo macOS.
3. Khi build hoàn tất, GitHub sẽ tự động:
   - Tải file lên mục **Releases** với 2 định dạng:
     - `JetsamChanger.tipa` (cho TrollStore)
     - `JetsamChanger.ipa` (cho SideStore / AltStore / Sideloadly)
   - Lưu trữ bản dựng trong mục **Artifacts** (30 ngày).

---

## 📦 Hướng Dẫn Cài Đặt & Sử Dụng

1. Cài đặt file `JetsamChanger.tipa` (iOS 17.0 qua TrollStore) hoặc `JetsamChanger.ipa` (iOS 17.1 - 18.x qua SideStore/AltStore).
2. Mở app **Jetsam Changer**, chuyển sang tab **Cài Đặt** và nhấn **Kích Hoạt Auto Kernel Exploit**.
3. Mở game/app bạn muốn cấp thêm RAM (ví dụ: mở **Amethyst** vào đến màn hình chính).
4. Quay lại **Jetsam Changer** vào tab **Danh Sách App**, gõ tìm app vừa mở.
5. Chạm vào app, chọn preset **Amethyst (6GB)** hoặc bật **Không Giới Hạn**, sau đó nhấn **Áp Dụng Thay Đổi Jetsam**.
6. Kiểm tra bảng thông báo màu xanh báo thành công ở dưới đáy màn hình!
