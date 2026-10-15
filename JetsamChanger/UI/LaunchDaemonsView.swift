import SwiftUI

struct LaunchDaemonsView: View {
    @ObservedObject var manager = ToolboxManager.shared
    @State private var showOptimizeAlert: Bool = false
    @State private var freedRAMAmount: Int = 0

    var body: some View {
        NavigationView {
            ZStack {
                Theme.bgPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // 1. One-Tap Optimizer Banner
                        oneTapOptimizeCard

                        // 2. Search Daemons
                        searchBar

                        // 3. Header
                        HStack {
                            Text("DỊCH VỤ HỆ THỐNG NGẦM (\(manager.filteredDaemons.count))")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Theme.textTertiary)
                            Spacer()
                            Button(action: { manager.refreshDaemons() }) {
                                Image(systemName: "arrow.clockwise")
                                    .foregroundColor(Theme.accentCyan)
                            }
                        }

                        // 4. Daemons List
                        LazyVStack(spacing: 12) {
                            ForEach(manager.filteredDaemons, id: \.bundleID) { daemon in
                                daemonCard(daemon)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Dịch Vụ Ngầm (Daemons)")
            .navigationBarTitleDisplayMode(.inline)
            .alert(isPresented: $showOptimizeAlert) {
                Alert(
                    title: Text("Tối Ưu Thành Công! ✅"),
                    message: Text("Đã đóng băng các tiến trình ngầm không cần thiết (ReportCrash, Telemetry, Tips, Siri).\nGiải phóng ước tính: ~\(freedRAMAmount) MB RAM!"),
                    dismissButton: .default(Text("Tuyệt Vời"))
                )
            }
        }
    }

    private var oneTapOptimizeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Theme.accentGreen.opacity(0.2))
                        .frame(width: 48, height: 48)
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Theme.accentGreen)
                        .glow(color: Theme.accentGreen, radius: 6)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Tối Ưu RAM 1-Chạm")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(Theme.textPrimary)
                    Text("Đóng băng các daemon rác (Crash, Analytics, OTA) để máy mát và pin trâu hơn.")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.textSecondary)
                }
            }

            Button(action: {
                let freed = manager.oneTapOptimizeDaemons()
                freedRAMAmount = freed
                showOptimizeAlert = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                    Text("Kích Hoạt Tối Ưu Ngay (Free ~400MB+ RAM)")
                        .font(.system(size: 14, weight: .bold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Theme.gradientCyanPurple)
                .foregroundColor(.white)
                .cornerRadius(12)
                .glow(color: Theme.accentCyan, radius: 4)
            }
        }
        .padding(14)
        .background(Theme.gradientCard)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Theme.accentCyan.opacity(0.2), lineWidth: 1)
        )
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Theme.textTertiary)
                .font(.system(size: 14))

            TextField("Tìm daemon (ReportCrash, softwareupdate...)", text: $manager.daemonSearchQuery)
                .font(.system(size: 13))
                .foregroundColor(Theme.textPrimary)
                .autocapitalization(.none)
                .disableAutocorrection(true)

            if !manager.daemonSearchQuery.isEmpty {
                Button(action: { manager.daemonSearchQuery = "" }) {
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
    }

    private func daemonCard(_ daemon: DaemonItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(daemon.name)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Theme.textPrimary)

                        Text(daemon.category)
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Theme.bgSecondary)
                            .foregroundColor(Theme.accentCyan)
                            .cornerRadius(4)
                    }

                    Text(daemon.bundleID)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(Theme.textTertiary)
                }

                Spacer()

                // RAM Badge
                Text("~\(daemon.memoryUsageMB) MB")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(daemon.isEnabled ? Theme.accentAmber : Theme.accentGreen)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(daemon.isEnabled ? Theme.accentAmber.opacity(0.15) : Theme.accentGreen.opacity(0.15))
                    .cornerRadius(6)

                // Toggle
                Toggle("", isOn: Binding(
                    get: { daemon.isEnabled },
                    set: { newVal in
                        _ = manager.toggleDaemon(daemon: daemon, enable: newVal)
                    }
                ))
                .labelsHidden()
                .tint(Theme.accentGreen)
            }

            Text(daemon.desc)
                .font(.system(size: 11))
                .foregroundColor(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(Theme.bgCard)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(daemon.isEnabled ? Theme.bgSecondary : Theme.accentGreen.opacity(0.3), lineWidth: 1)
        )
    }
}
