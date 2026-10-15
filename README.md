# Lara Toolbox ⚡ (iOS 16.0 – 18.4.1+)

[![Build Lara Toolbox (iOS 16.0 - 18.4.1+)](https://github.com/Mobimi/jetsam-ios-16-18/actions/workflows/build.yml/badge.svg)](https://github.com/Mobimi/jetsam-ios-16-18/actions/workflows/build.yml)

Bộ công cụ **Exploit Toolbox toàn diện** cho **iOS 16.0 – 18.4.1+** tích hợp kiến trúc **DarkSword / kfd** (tối ưu hóa đặc biệt cho chip **Apple A14 Bionic / arm64e** và các thiết bị iPhone/iPad tương thích).

Lấy cảm hứng từ các công cụ tiện ích cao cấp như **LARA** (phát triển bởi Trần Khánh Duy `khanhduytran0`) và **TrollFools** (bởi Lessica), **Lara Toolbox** mang lại các đặc quyền mạnh mẽ nhất của Kernel Exploit trực tiếp lên chiếc iPhone của bạn mà không cần bẻ khóa (Jailbreak) truyền thống.

---

## 🌟 4 Chức Năng Cốt Lõi

### 1. 💉 Tiêm Tweak Trực Tiếp (In-Place Dylib Injector)
* **KHÔNG CẦN XOÁ HAY CÀI LẠI APP**: Tự động duyệt qua các ứng dụng đã cài đặt trên máy.
* Chọn file `.dylib` hoặc `.deb` trực tiếp từ ứng dụng **Tệp (Files)** của iOS.
* Thuật toán Mach-O parser nhúng lệnh `LC_LOAD_DYLIB` thẳng vào file thực thi của app và tự động ký lại với `ldid`.
* **Giữ nguyên 100% tài khoản, dữ liệu chat, file save game**.
* Nút **Gỡ Tweak (Eject)** và **Khôi Phục Bản Gốc (.orig)** chỉ với 1 cú chạm.

### 2. ⚙️ Quản Lý Dịch Vụ Ngầm (LaunchDaemons Manager)
* Kiểm soát toàn bộ các tiến trình nền của iOS do `launchd` (PID 1) quản lý.
* Nút **⚡ Tối Ưu RAM 1-Chạm**: Đóng băng các daemon rác (Báo cáo lỗi `ReportCrash`, Telemetry `analyticsd`, Mẹo vặt `tipsd`, Cập nhật iOS `softwareupdated`), giải phóng ngay **~400MB+ RAM**, giúp máy mát rượi và pin trâu hơn hẳn.
* Bật/tắt hoặc đóng băng (`SIGSTOP` / `SIGCONT`) từng daemon riêng biệt kèm badge hiển thị lượng RAM tiêu thụ.

### 3. 🛠️ Tiện Ích Exploit Chuyên Sâu (Gaming & Tweaks)
* **Tắt Bóp Xung Nhiệt Độ (Gaming Thermal Bypass)**: Vô hiệu hóa điều tiết trong `thermalmonitord`, giữ 100% độ sáng màn hình và duy trì max xung CPU/GPU khi chơi Genshin, Minecraft, PUBG; chống drop FPS.
* **JIT On-Device Enabler (Không cần PC/Wi-Fi)**: Cấp quyền `CS_DEBUGGED` cho PojavLauncher (Minecraft Java), Dolphin, PPSSPP, UTM máy ảo.
* **Fake GPS Tầng Kernel**: Hook trực tiếp vào `locationd` giả lập vị trí toàn hệ thống, chống mọi cơ chế anti-cheat phát hiện.
* **Chặn Cập Nhật iOS Vĩnh Viễn**: Khóa cứng daemon OTA.
* **Bật Dynamic Island**: Kích hoạt giao diện Dynamic Island trên iPhone 12 / chip A14 qua MobileGestalt.
* **Điều Khiển Jetsam & RAM**: Chỉnh giới hạn RAM từ 512MB lên đến 16GB hoặc kích hoạt chế độ **Không Giới Hạn (Unlimited ∞)**.

### 4. 💻 Cài Đặt, Trạng Thái Exploit & Live Console
* Thẻ trạng thái Kernel Exploit: Nhận diện chip A14 (PAC/PPL Active, SPTM Disabled), kiểm tra quyền Root (`uid=0`), Unsandbox (`p_ucred->cr_label = NULL`), Kernel Base và KASLR Slide.
* Nút **Kích Hoạt Kernel Exploit (DarkSword / kfd)**.
* Hộp Live Terminal Console hiển thị log thời gian thực với bộ lọc lỗi `[X]`, nút sao chép và xoá log.

---

## 🛠️ GitHub Workflow Tự Động Build (Không Cần Mac)

Repo tích hợp sẵn GitHub Actions Workflow (`.github/workflows/build.yml`) chạy trên runner `macos-14`:
1. Push mã nguồn lên branch `main`: `https://github.com/Mobimi/jetsam-ios-16-18`.
2. Truy cập tab **Actions** để xem quá trình build tự động.
3. Khi hoàn tất, các gói cài đặt sẽ tự động có mặt tại mục **Releases**:
   - 📦 **`LaraToolbox.tipa`**: Dành cho **TrollStore** (iOS 14.0 – 17.0).
   - 📱 **`LaraToolbox.ipa`**: Dành cho **SideStore / AltStore / Feather / Sideloadly** (iOS 16.0 – 18.4.1+).

---

## 📱 Hướng Dẫn Sử Dụng
1. Cài đặt app lên thiết bị qua TrollStore hoặc Sideload.
2. Mở app **Lara Toolbox**, vào tab **Console & Exploit** và nhấn **Kích Hoạt Kernel Exploit**.
3. Sau khi trạng thái báo Xanh (`Root & Unsandboxed`), bạn có thể tự do:
   - Sang tab **Tiêm Tweak** để chèn dylib vào app bất kỳ.
   - Sang tab **Dịch Vụ Ngầm** để bấm Tối Ưu RAM 1-chạm.
   - Sang tab **Tiện Ích** để bật Gaming Thermal Bypass, JIT hoặc Fake GPS.
