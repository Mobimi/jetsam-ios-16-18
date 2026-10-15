import SwiftUI

struct ProcessDetailView: View {
    let process: JetsamProcessModel
    @ObservedObject var manager = ProcessManager.shared
    @Environment(\.dismiss) var dismiss

    @State private var targetLimitMB: Double = 4096
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

                    // 4. Jetsam Limit Adjuster (Slider + Unlimited Toggle)
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
            } else {
                targetLimitMB = Double(process.activeLimitMB)
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
                        .foregroundColor(Theme.accentPurple)
                }
            }
        }
        .padding(16)
        .background(Theme.gradientCard)
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Theme.accentCyan.opacity(0.15), lineWidth: 1)
        )
    }

    // MARK: - 3. Quick Presets Section
    private var presetsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Cấu Hình Khuyến Nghị (Presets)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Theme.textPrimary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                presetCard(title: "Amethyst / Pojav", desc: "6 GB RAM (Mượt game)", icon: "cube.fill", color: Theme.accentGreen) {
                    targetLimitMB = 6144
                    isUnlimited = false
                    selectedPriority = 18
                }

                presetCard(title: "Giả Lập (Dolphin)", desc: "4 GB RAM + JIT", icon: "gamecontroller.fill", color: Theme.accentCyan) {
                    targetLimitMB = 4096
                    isUnlimited = false
                    selectedPriority = 10
                }

                presetCard(title: "Không Giới Hạn", desc: "Không bao giờ bị Kill", icon: "infinity", color: Theme.accentPurple) {
                    isUnlimited = true
                    selectedPriority = 21
                }

                presetCard(title: "Mặc Định iOS", desc: "2 GB tiêu chuẩn", icon: "arrow.counterclockwise", color: Theme.textSecondary) {
                    targetLimitMB = 2048
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

    // MARK: - 4. Jetsam Limit Adjuster
    private var jetsamAdjusterCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Bảng Sửa Jetsam Memory Limit")
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
                VStack(spacing: 8) {
                    HStack {
                        Text("\(Int(targetLimitMB)) MB")
                            .font(.system(size: 22, weight: .bold, design: .monospaced))
                            .foregroundColor(Theme.accentCyan)
                        Text(String(format: "(~%.1f GB RAM)", targetLimitMB / 1024.0))
                            .font(.system(size: 14))
                            .foregroundColor(Theme.textSecondary)
                        Spacer()
                    }

                    Slider(value: $targetLimitMB, in: 512...16384, step: 256)
                        .tint(Theme.accentCyan)

                    HStack {
                        Text("512 MB")
                            .font(.system(size: 10))
                            .foregroundColor(Theme.textTertiary)
                        Spacer()
                        Text("4 GB")
                            .font(.system(size: 10))
                            .foregroundColor(Theme.textTertiary)
                        Spacer()
                        Text("8 GB")
                            .font(.system(size: 10))
                            .foregroundColor(Theme.textTertiary)
                        Spacer()
                        Text("16 GB")
                            .font(.system(size: 10))
                            .foregroundColor(Theme.textTertiary)
                    }
                }
            }
        }
        .padding(16)
        .background(Theme.bgCard)
        .cornerRadius(16)
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

            Toggle("Cho phép đóng băng nền (Process Freeze)", isOn: $isFreezable)
                .font(.system(size: 13))
                .foregroundColor(Theme.textSecondary)
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
            let limit = Int32(targetLimitMB)
            success = manager.setJetsamLimit(pid: process.pid, limitMB: limit)
            _ = manager.setPriority(pid: process.pid, priority: selectedPriority)
            _ = manager.setFreezable(pid: process.pid, isFreezable: isFreezable)

            if success {
                isApplySuccess = true
                let gbString = String(format: "%.1f", Double(limit) / 1024.0)
                notificationMessage = "Đã chỉnh thành công Jetsam limit cho \(process.name) lên \(limit) MB (~\(gbString) GB) với Priority \(selectedPriority)!"
            } else {
                isApplySuccess = false
                notificationMessage = "Lỗi khi ghi thông số Jetsam vào kernel proc_t cho PID \(process.pid). Vui lòng vào tab Cài Đặt kiểm tra log lỗi."
            }
        }

        withAnimation(.easeInOut) {
            showNotificationBanner = true
        }
    }
}
