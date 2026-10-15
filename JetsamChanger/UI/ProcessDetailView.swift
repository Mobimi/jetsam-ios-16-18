import SwiftUI

struct ProcessDetailView: View {
    let process: JetsamProcessModel
    @ObservedObject var manager = ToolboxManager.shared
    @Environment(\.dismiss) var dismiss

    @State private var inputLimitMBText: String = "4000"
    @State private var isUnlimited: Bool = false
    @State private var selectedPriority: Int16 = 18
    @State private var isFreezable: Bool = false

    // Result notification banner state
    @State private var showNotificationBanner: Bool = false
    @State private var isApplySuccess: Bool = false
    @State private var notificationMessage: String = ""

    var body: some View {
        ZStack {
            Theme.bgPrimary.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    // 1. Mandatory Running App Warning
                    runningAppNotice

                    // 2. App Profile Header Card
                    appProfileCard

                    // 3. Quick Presets
                    presetsSection

                    // 4. Jetsam Limit Adjuster (MB Text Input + Unlimited Toggle)
                    jetsamAdjusterCard

                    // 5. Priority & Freezer Options
                    priorityAndFreezeCard

                    // 6. Big Apply Button
                    applyButton

                    // 7. Result Notification Banner (Always at the bottom after Apply)
                    if showNotificationBanner {
                        resultNotificationBanner
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle(process.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if process.activeLimitMB <= 0 {
                isUnlimited = true
                inputLimitMBText = ""
            } else {
                isUnlimited = false
                inputLimitMBText = "\(process.activeLimitMB)"
            }
            selectedPriority = process.effectivePriority
            isFreezable = process.isFrozen
        }
    }

    // MARK: - 1. Running App Notice
    private var runningAppNotice: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(Theme.accentCyan)
                .font(.system(size: 16))

            VStack(alignment: .leading, spacing: 2) {
                Text("Trạng thái tiến trình:")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Theme.accentCyan)
                Text("App đang hoạt động với PID \(process.pid). Hãy giữ app chạy ngầm trong khi áp dụng để đảm bảo Jetsam được cập nhật tức thì.")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.textSecondary)
            }
            Spacer()
        }
        .padding(12)
        .background(Theme.accentCyan.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Theme.accentCyan.opacity(0.25), lineWidth: 1)
        )
    }

    // MARK: - 2. App Profile Header Card
    private var appProfileCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Theme.gradientCyanPurple)
                        .frame(width: 52, height: 52)
                    Image(systemName: "app.dashed")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(process.name)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Theme.textPrimary)

                    Text(process.bundleID)
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Text("PID: \(process.pid)")
                            .font(.system(size: 11, design: .monospaced))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Theme.bgSecondary)
                            .cornerRadius(4)
                            .foregroundColor(Theme.accentCyan)

                        if process.procKernelAddr != 0 {
                            Text(String(format: "proc_t: 0x%llX", process.procKernelAddr))
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(Theme.textTertiary)
                        }
                    }
                }
                Spacer()
            }

            Divider().background(Theme.bgSecondary)

            // Current Stats Grid
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("RAM ĐANG DÙNG")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Theme.textTertiary)
                    Text(process.formattedFootprint())
                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.accentGreen)
                }
                Spacer()
                VStack(alignment: .leading, spacing: 2) {
                    Text("JETSAM HIỆN TẠI")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Theme.textTertiary)
                    Text(process.formattedLimit())
                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.accentAmber)
                }
                Spacer()
                VStack(alignment: .leading, spacing: 2) {
                    Text("PRIORITY TIER")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Theme.textTertiary)
                    Text(process.priorityDescription())
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Theme.textPrimary)
                }
            }
        }
        .padding(16)
        .background(Theme.bgCard)
        .cornerRadius(16)
    }

    // MARK: - 3. Quick Presets
    private var presetsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("CẤU HÌNH NHANH (PRESETS)")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Theme.textTertiary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                presetCard(title: "Minecraft / Amethyst", desc: "6000 MB (6 GB)", icon: "cube.fill", color: Theme.accentGreen) {
                    inputLimitMBText = "6000"
                    isUnlimited = false
                    selectedPriority = 18
                }

                presetCard(title: "Giả Lập (Dolphin / UTM)", desc: "4000 MB (4 GB)", icon: "gamecontroller.fill", color: Theme.accentCyan) {
                    inputLimitMBText = "4000"
                    isUnlimited = false
                    selectedPriority = 10
                }

                presetCard(title: "Không Giới Hạn", desc: "Không bao giờ bị Kill", icon: "infinity", color: Theme.accentPurple) {
                    isUnlimited = true
                    selectedPriority = 21
                }

                presetCard(title: "Mặc Định iOS", desc: "Để iPhone tự quản", icon: "arrow.counterclockwise", color: Theme.textSecondary) {
                    inputLimitMBText = ""
                    isUnlimited = false
                    selectedPriority = 10
                }
            }
        }
    }

    private func presetCard(title: String, desc: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(color)
                    Spacer()
                }
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                Text(desc)
                    .font(.system(size: 11))
                    .foregroundColor(Theme.textSecondary)
            }
            .padding(12)
            .background(Theme.bgCard)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color.opacity(0.35), lineWidth: 1)
            )
        }
    }

    // MARK: - 4. Jetsam Limit Adjuster (MB Text Field)
    private var jetsamAdjusterCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Ô Nhập Hạn Mức RAM Jetsam (MB)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Theme.textPrimary)

                Spacer()

                Toggle("Không Giới Hạn", isOn: $isUnlimited)
                    .labelsHidden()
                    .tint(Theme.accentPurple)
            }

            if isUnlimited {
                HStack(spacing: 12) {
                    Image(systemName: "infinity")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(Theme.accentPurple)
                        .glow(color: Theme.accentPurple)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Chế Độ Không Giới Hạn (Unlimited)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Theme.accentPurple)
                        Text("Gỡ bỏ cờ FATAL_MEMLIMIT trong kernel proc_t. App sẽ được dùng tối đa RAM máy mà không bị kill.")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.textSecondary)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.accentPurple.opacity(0.12))
                .cornerRadius(12)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    // Ô NHẬP THEO DẠNG MB
                    HStack {
                        Image(systemName: "square.and.pencil")
                            .foregroundColor(Theme.accentCyan)
                            .font(.system(size: 16))

                        TextField("Nhập số MB (để trống = Mặc định hệ thống)", text: $inputLimitMBText)
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .keyboardType(.numberPad)
                            .foregroundColor(Theme.textPrimary)

                        if !inputLimitMBText.isEmpty {
                            Text("MB")
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundColor(Theme.accentCyan)

                            Button(action: { inputLimitMBText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(Theme.textTertiary)
                            }
                        }
                    }
                    .padding(12)
                    .background(Theme.bgSecondary)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Theme.accentCyan.opacity(0.3), lineWidth: 1)
                    )

                    // Helper / Explanation line
                    HStack {
                        if inputLimitMBText.trimmingCharacters(in: .whitespaces).isEmpty {
                            Image(systemName: "arrow.counterclockwise.circle.fill")
                                .foregroundColor(Theme.accentAmber)
                            Text("Đang xóa trống: Sẽ để MẶC ĐỊNH HỆ THỐNG iPHONE tự quản lý.")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Theme.accentAmber)
                        } else if let mb = Double(inputLimitMBText), mb > 0 {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Theme.accentGreen)
                            Text("Sẽ cấp: \(Int(mb)) MB (~ \(String(format: "%.2f", mb / 1024.0)) GB RAM)")
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundColor(Theme.accentGreen)
                        } else {
                            Text("Vui lòng nhập số hợp lệ.")
                                .font(.system(size: 11))
                                .foregroundColor(Theme.accentRed)
                        }
                    }

                    // Quick Select Buttons
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            quickMBButton("2000 MB (2GB)", mb: 2000)
                            quickMBButton("4000 MB (4GB)", mb: 4000)
                            quickMBButton("6000 MB (6GB)", mb: 6000)
                            quickMBButton("8000 MB (8GB)", mb: 8000)
                            quickMBButton("Xóa Trống (Mặc Định)", mb: 0)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Theme.bgCard)
        .cornerRadius(16)
    }

    private func quickMBButton(_ label: String, mb: Int) -> some View {
        Button(action: {
            if mb == 0 {
                inputLimitMBText = ""
            } else {
                inputLimitMBText = "\(mb)"
            }
        }) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Theme.bgSecondary)
                .foregroundColor(Theme.textPrimary)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Theme.accentCyan.opacity(0.2), lineWidth: 1)
                )
        }
    }

    // MARK: - 5. Priority & Freeze
    private var priorityAndFreezeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Độ Ưu Tiên Hoạt Động (Priority)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Theme.textPrimary)

            Picker("Priority Tier", selection: $selectedPriority) {
                Text("Background (2)").tag(Int16(2))
                Text("Foreground (10)").tag(Int16(10))
                Text("Foreground Key (18)").tag(Int16(18))
                Text("Critical (21)").tag(Int16(21))
            }
            .pickerStyle(SegmentedPickerStyle())

            Toggle(isOn: $isFreezable) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Cho Phép Đóng Băng (App Freezer)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Theme.textPrimary)
                    Text("Khi chạy ngầm, hệ thống sẽ freeze tiến trình để tiết kiệm RAM.")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.textSecondary)
                }
            }
            .tint(Theme.accentCyan)
        }
        .padding(16)
        .background(Theme.bgCard)
        .cornerRadius(16)
    }

    // MARK: - 6. Apply Button
    private var applyButton: some View {
        Button(action: applyJetsamChanges) {
            HStack(spacing: 10) {
                Image(systemName: "bolt.badge.checkmark.fill")
                    .font(.system(size: 18))
                Text("Áp Dụng Thay Đổi Jetsam (Apply)")
                    .font(.system(size: 16, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Theme.gradientCyanPurple)
            .foregroundColor(.white)
            .cornerRadius(16)
            .glow(color: Theme.accentCyan, radius: 8)
        }
    }

    // MARK: - 7. Result Notification Banner
    private var resultNotificationBanner: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: isApplySuccess ? "checkmark.circle.fill" : "xmark.octagon.fill")
                .font(.system(size: 24))
                .foregroundColor(isApplySuccess ? Theme.accentGreen : Theme.accentRed)
                .glow(color: isApplySuccess ? Theme.accentGreen : Theme.accentRed, radius: 6)

            VStack(alignment: .leading, spacing: 4) {
                Text(isApplySuccess ? "ĐÃ ÁP DỤNG THÀNH CÔNG! ✅" : "ÁP DỤNG THẤT BẠI! ❌")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(isApplySuccess ? Theme.accentGreen : Theme.accentRed)

                Text(notificationMessage)
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Button(action: { showNotificationBanner = false }) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Theme.textTertiary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background((isApplySuccess ? Theme.accentGreen : Theme.accentRed).opacity(0.15))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke((isApplySuccess ? Theme.accentGreen : Theme.accentRed).opacity(0.4), lineWidth: 1)
        )
    }

    // MARK: - Action Execution
    private func applyJetsamChanges() {
        var success = false

        if isUnlimited {
            success = manager.setUnlimited(pid: process.pid)
            if success {
                isApplySuccess = true
                notificationMessage = "Đã bật chế độ Không Giới Hạn cho \(process.name) (PID: \(process.pid)). App sẽ không bao giờ bị Jetsam tự ý đóng!"
            } else {
                isApplySuccess = false
                notificationMessage = "Không thể áp dụng Không Giới Hạn cho PID \(process.pid). Hãy kiểm tra tab Cài Đặt xem Kernel Exploit đã kích hoạt chưa."
            }
        } else {
            let trimmed = inputLimitMBText.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty {
                // XÓA HẾT SỐ = ĐỂ MẶC ĐỊNH HỆ THỐNG IPHONE TỰ QUẢN
                success = manager.applyPreset(pid: process.pid, presetName: "System Default")
                if success {
                    isApplySuccess = true
                    notificationMessage = "Đã xóa hạn mức tùy chỉnh: Đưa \(process.name) (PID: \(process.pid)) về MẶC ĐỊNH HỆ THỐNG iPHONE tự quản lý!"
                } else {
                    isApplySuccess = false
                    notificationMessage = "Lỗi khi khôi phục mặc định hệ thống cho PID \(process.pid)."
                }
            } else if let mb = Int32(trimmed), mb > 0 {
                // NHẬP SỐ MB CỤ THỂ
                success = manager.setJetsamLimit(pid: process.pid, limitMB: mb)
                _ = manager.setPriority(pid: process.pid, priority: selectedPriority)
                _ = manager.setFreezable(pid: process.pid, isFreezable: isFreezable)

                if success {
                    isApplySuccess = true
                    let gbString = String(format: "%.2f", Double(mb) / 1024.0)
                    notificationMessage = "Đã chỉnh thành công Jetsam limit cho \(process.name) lên \(mb) MB (~\(gbString) GB) với Priority \(selectedPriority)!"
                } else {
                    isApplySuccess = false
                    notificationMessage = "Lỗi khi ghi thông số Jetsam vào kernel proc_t cho PID \(process.pid). Vui lòng vào tab Cài Đặt kiểm tra log lỗi."
                }
            } else {
                isApplySuccess = false
                notificationMessage = "Số MB không hợp lệ. Vui lòng nhập số MB lớn hơn 0 (ví dụ: 4000) hoặc xóa trống để về mặc định hệ thống."
            }
        }

        withAnimation(.easeInOut) {
            showNotificationBanner = true
        }
    }
}
