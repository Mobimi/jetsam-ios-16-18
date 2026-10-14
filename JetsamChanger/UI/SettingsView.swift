import SwiftUI

struct SettingsView: View {
    @ObservedObject var manager = ProcessManager.shared
    @State private var filterErrorsOnly: Bool = false
    @State private var copiedAlert: Bool = false

    var body: some View {
        NavigationView {
            ZStack {
                Theme.bgPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // 1. Kernel Exploit Status Card
                        kernelStatusCard

                        // 2. Exploit Action Button
                        exploitActionButton

                        // 3. System & Kernel Technical Details
                        kernelDetailsCard

                        // 4. Live Console & Error Logs Section
                        consoleLogCard
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Cài Đặt & Console")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - 1. Status Card
    private var kernelStatusCard: some View {
        VStack(spacing: 14) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(manager.isExploited ? Theme.accentGreen.opacity(0.2) : (manager.isExploiting ? Theme.accentAmber.opacity(0.2) : Theme.accentRed.opacity(0.2)))
                        .frame(width: 50, height: 50)

                    Image(systemName: manager.isExploited ? "checkmark.shield.fill" : (manager.isExploiting ? "hourglass" : "exclamationmark.shield.fill"))
                        .font(.system(size: 26))
                        .foregroundColor(manager.isExploited ? Theme.accentGreen : (manager.isExploiting ? Theme.accentAmber : Theme.accentRed))
                        .glow(color: manager.isExploited ? Theme.accentGreen : Theme.accentRed, radius: 6)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("TRẠNG THÁI KERNEL EXPLOIT")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Theme.textTertiary)

                    Text(manager.isExploited ? "Đã Exploit Thành Công ✅" : (manager.isExploiting ? "Đang chạy exploit..." : "Chưa Exploit ⚠️"))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(manager.isExploited ? Theme.accentGreen : (manager.isExploiting ? Theme.accentAmber : Theme.accentRed))

                    Text(manager.exploitStatusText)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(Theme.textSecondary)
                }

                Spacer()
            }

            Divider().background(Theme.bgSecondary)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Hệ Điều Hành")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.textTertiary)
                    Text("iOS \(KernelExploit.shared().osProductVersion)")
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundColor(Theme.textPrimary)
                }
                Spacer()
                VStack(alignment: .leading, spacing: 2) {
                    Text("Thiết Bị")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.textTertiary)
                    Text(KernelExploit.shared().deviceModel)
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundColor(Theme.textPrimary)
                }
                Spacer()
                VStack(alignment: .leading, spacing: 2) {
                    Text("SPTM / TXM")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.textTertiary)
                    Text(KernelExploit.shared().isSPTMActive ? "Active" : "Disabled")
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundColor(KernelExploit.shared().isSPTMActive ? Theme.accentAmber : Theme.accentGreen)
                }
            }
        }
        .padding(16)
        .background(Theme.gradientCard)
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke((manager.isExploited ? Theme.accentGreen : Theme.accentRed).opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - 2. Action Button
    private var exploitActionButton: some View {
        Button(action: {
            manager.triggerAutoExploit()
        }) {
            HStack(spacing: 10) {
                if manager.isExploiting {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 16))
                }
                Text(manager.isExploiting ? "Đang Khai Thác Kernel..." : (manager.isExploited ? "Chạy Lại Kernel Exploit" : "Kích Hoạt Auto Kernel Exploit"))
                    .font(.system(size: 15, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(manager.isExploiting ? Theme.bgSecondary : Theme.gradientCyanPurple)
            .foregroundColor(.white)
            .cornerRadius(14)
            .glow(color: Theme.accentCyan, radius: 6)
        }
        .disabled(manager.isExploiting)
    }

    // MARK: - 3. Kernel Details Card
    private var kernelDetailsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Thông Số Kỹ Thuật Kernel")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Theme.textTertiary)

            VStack(spacing: 8) {
                detailRow(label: "Kernel Base:", value: String(format: "0x%llX", KernelExploit.shared().kernelBase))
                detailRow(label: "Kernel Slide:", value: String(format: "0x%llX", KernelExploit.shared().kernelSlide))
                detailRow(label: "allproc Pointer:", value: String(format: "0x%llX", KernelExploit.shared().allprocAddress))
                detailRow(label: "Quyền Truy Cập:", value: manager.isExploited ? "Đọc/Ghi Trực Tiếp struct proc_t" : "Chưa Kích Hoạt")
            }
            .padding(12)
            .background(Theme.bgCard)
            .cornerRadius(12)
        }
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(Theme.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(Theme.accentCyan)
        }
    }

    // MARK: - 4. Live Console & Error Logs Section
    private var consoleLogCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "terminal.fill")
                        .foregroundColor(Theme.accentCyan)
                    Text("Bảng Console & Log Lỗi")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Theme.textPrimary)
                }

                Spacer()

                // Filter errors toggle
                Button(action: {
                    filterErrorsOnly.toggle()
                }) {
                    Text(filterErrorsOnly ? "Chỉ Lỗi [X]" : "Tất Cả Log")
                        .font(.system(size: 11, weight: .bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(filterErrorsOnly ? Theme.accentRed.opacity(0.2) : Theme.bgSecondary)
                        .foregroundColor(filterErrorsOnly ? Theme.accentRed : Theme.textSecondary)
                        .cornerRadius(6)
                }

                // Copy button
                Button(action: {
                    copyLogsToClipboard()
                }) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.textSecondary)
                }

                // Trash button
                Button(action: {
                    manager.kernelLogs.removeAll()
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.textSecondary)
                }
            }

            // Terminal Viewport
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 6) {
                        let displayedLogs = filterErrorsOnly ? manager.kernelLogs.filter { $0.isError } : manager.kernelLogs

                        if displayedLogs.isEmpty {
                            Text(filterErrorsOnly ? "Không có log lỗi nào." : "Chưa có log. Hãy nhấn 'Kích Hoạt Auto Kernel Exploit' ở trên.")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(Theme.textTertiary)
                                .padding(12)
                        } else {
                            ForEach(displayedLogs) { log in
                                HStack(alignment: .top, spacing: 6) {
                                    Text(log.formattedTime)
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundColor(Theme.textTertiary)

                                    Text(log.message)
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(log.isError ? Theme.accentRed : (log.message.contains("[✓]") || log.message.contains("[+]") ? Theme.accentGreen : Theme.accentCyan))
                                        .multilineTextAlignment(.leading)
                                }
                                .id(log.id)
                            }
                        }
                    }
                    .padding(10)
                }
                .frame(height: 240)
                .background(Color.black.opacity(0.85))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Theme.accentCyan.opacity(0.25), lineWidth: 1)
                )
            }

            if copiedAlert {
                Text("Đã sao chép log vào bộ nhớ tạm!")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Theme.accentGreen)
            }
        }
    }

    private func copyLogsToClipboard() {
        let text = manager.kernelLogs.map { "[\($0.formattedTime)] \($0.message)" }.joined(separator: "\n")
        UIPasteboard.general.string = text
        copiedAlert = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            copiedAlert = false
        }
    }
}
