import SwiftUI

struct AppListView: View {
    @ObservedObject var manager = ProcessManager.shared

    var body: some View {
        NavigationView {
            ZStack {
                Theme.bgPrimary.ignoresSafeArea()

                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 14) {
                            // 1. Memory Gauge Summary
                            memorySummaryBar

                            // 2. Mandatory Notice Banner (App must be running)
                            noticeRunningAppBanner

                            // 3. Search Bar
                            searchBar

                            // 4. Filter Tags
                            filterPills

                            // 5. Apps List
                            appsListSection
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 10)
                        .padding(.bottom, 24)
                    }
                    .refreshable {
                        manager.refreshProcesses()
                        manager.updateMemoryStats()
                    }
                }
            }
            .navigationTitle("Chỉnh Jetsam")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        manager.refreshProcesses()
                        manager.updateMemoryStats()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(Theme.accentCyan)
                    }
                }
            }
        }
    }

    // MARK: - 1. Memory Summary Bar
    private var memorySummaryBar: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("RAM HỆ THỐNG")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Theme.textTertiary)
                Text(manager.memoryStats.totalRAMString)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("CÒN TRỐNG")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Theme.textTertiary)
                Text(manager.memoryStats.availableString)
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.accentGreen)
            }

            // Small status dot
            Circle()
                .fill(manager.isExploited ? Theme.accentGreen : Theme.accentAmber)
                .frame(width: 8, height: 8)
                .glow(color: manager.isExploited ? Theme.accentGreen : Theme.accentAmber, radius: 4)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Theme.bgCard)
        .cornerRadius(12)
    }

    // MARK: - 2. Notice Banner
    private var noticeRunningAppBanner: some View {
        Group {
            if !manager.isExploited {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(Theme.accentAmber)
                        .font(.system(size: 16))
                        .padding(.top, 2)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Cần Kích Hoạt Kernel Exploit:")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Theme.accentAmber)
                        Text("Để thoát khỏi Sandbox và can thiệp bộ nhớ struct proc_t của app, vui lòng kích hoạt Kernel Exploit trước.")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.textSecondary)

                        Button(action: { manager.triggerAutoExploit() }) {
                            Text("Kích Hoạt Ngay")
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Theme.accentAmber)
                                .foregroundColor(.black)
                                .cornerRadius(6)
                        }
                    }
                    Spacer()
                }
                .padding(12)
                .background(Theme.accentAmber.opacity(0.12))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Theme.accentAmber.opacity(0.3), lineWidth: 1)
                )
            } else {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(Theme.accentCyan)
                        .font(.system(size: 16))
                        .padding(.top, 2)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Lưu ý quan trọng:")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Theme.accentCyan)
                        Text("Bắt buộc bạn phải MỞ APP TRƯỚC rồi chuyển sang đây để chỉnh. Ứng dụng chưa được mở sẽ chưa thể can thiệp Jetsam.")
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
        }
    }

    // MARK: - 3. Search Bar
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Theme.textTertiary)
                .font(.system(size: 14))

            TextField("Gõ tên app hoặc bundle ID (ví dụ: Amethyst, Pojav)...", text: $manager.searchQuery)
                .font(.system(size: 13))
                .foregroundColor(Theme.textPrimary)
                .autocapitalization(.none)
                .disableAutocorrection(true)

            if !manager.searchQuery.isEmpty {
                Button(action: { manager.searchQuery = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Theme.textTertiary)
                        .font(.system(size: 14))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Theme.bgCard)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Theme.accentCyan.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - 4. Filter Pills
    private var filterPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ProcessManager.ProcessFilter.allCases) { filter in
                    Button(action: { manager.selectedFilter = filter }) {
                        Text(filter.rawValue)
                            .font(.system(size: 12, weight: .semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(manager.selectedFilter == filter ? Theme.accentCyan : Theme.bgCard)
                            .foregroundColor(manager.selectedFilter == filter ? .black : Theme.textSecondary)
                            .cornerRadius(16)
                    }
                }
            }
        }
    }

    // MARK: - 5. Apps List Section
    private var appsListSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("ỨNG DỤNG ĐANG CHẠY (\(manager.filteredProcesses.count))")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Theme.textTertiary)
                Spacer()
                Text("Chạm vào app để chỉnh Jetsam")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.accentCyan)
            }

            if manager.filteredProcesses.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "app.dashed")
                        .font(.system(size: 40))
                        .foregroundColor(Theme.textTertiary)
                    Text("Không tìm thấy app nào phù hợp")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Theme.textSecondary)
                    Text("Hãy chắc chắn rằng ứng dụng bạn muốn chỉnh đã được mở trên iPhone/iPad.")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.textTertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(manager.filteredProcesses, id: \.pid) { proc in
                        NavigationLink(destination: ProcessDetailView(process: proc)) {
                            appRowCard(proc)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }

    private func appRowCard(_ proc: JetsamProcessModel) -> some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Theme.bgSecondary)
                    .frame(width: 48, height: 48)

                Image(systemName: iconForApp(proc.name))
                    .font(.system(size: 20))
                    .foregroundColor(Theme.accentCyan)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(proc.name)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Theme.textPrimary)
                        .lineLimit(1)

                    Text("PID: \(proc.pid)")
                        .font(.system(size: 10, design: .monospaced))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Theme.bgSecondary)
                        .cornerRadius(4)
                        .foregroundColor(Theme.textTertiary)
                }

                Text(proc.bundleID)
                    .font(.system(size: 11))
                    .foregroundColor(Theme.textTertiary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(proc.formattedFootprint())
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.accentGreen)

                Text(proc.formattedLimit())
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(proc.activeLimitMB <= 0 ? Theme.accentPurple.opacity(0.2) : Theme.bgSecondary)
                    .foregroundColor(proc.activeLimitMB <= 0 ? Theme.accentPurple : Theme.accentAmber)
                    .cornerRadius(4)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.textTertiary)
        }
        .padding(12)
        .background(Theme.bgCard)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Theme.bgSecondary, lineWidth: 1)
        )
    }

    private func iconForApp(_ name: String) -> String {
        let lower = name.lowercased()
        if lower.contains("amethyst") || lower.contains("pojav") || lower.contains("minecraft") {
            return "cube.fill"
        } else if lower.contains("dolphin") || lower.contains("melonx") || lower.contains("retroarch") || lower.contains("game") {
            return "gamecontroller.fill"
        } else if lower.contains("camera") {
            return "camera.fill"
        } else if lower.contains("safari") {
            return "safari.fill"
        } else {
            return "app.fill"
        }
    }
}
