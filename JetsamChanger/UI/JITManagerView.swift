import SwiftUI

struct JITManagerView: View {
    @ObservedObject var manager = ToolboxManager.shared
    @State private var selectedApp: InstalledAppItem? = nil
    @State private var isShowingDetail: Bool = false
    @State private var showResultBanner: Bool = false
    @State private var isSuccess: Bool = false
    @State private var statusMessage: String = ""

    var body: some View {
        NavigationView {
            ZStack {
                Theme.bgPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // Exploit Requirement Notice
                        if !manager.isExploited {
                            unexploitedWarningCard
                        }

                        // JIT Exploit Info Banner
                        jitInfoBanner

                        // Search Bar
                        searchBar

                        // Header Summary
                        HStack {
                            Text("CHỌN ỨNG DỤNG BẬT JIT (\(manager.filteredInstalledApps.count))")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Theme.textTertiary)
                            Spacer()
                            Button(action: { manager.refreshInstalledApps() }) {
                                Image(systemName: "arrow.clockwise")
                                    .foregroundColor(Theme.accentCyan)
                            }
                        }

                        // Apps List
                        if manager.filteredInstalledApps.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "bolt.slash.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(Theme.textTertiary)
                                Text("Chưa tìm thấy ứng dụng thật nào")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(Theme.textSecondary)
                                Text("Vui lòng kích hoạt Kernel Exploit ở tab Console để thoát Sandbox và quét danh sách app thật đã cài trên iPhone của bạn.")
                                    .font(.system(size: 11))
                                    .foregroundColor(Theme.textTertiary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 20)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 30)
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(manager.filteredInstalledApps, id: \.bundleID) { app in
                                    appRow(app)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Bật JIT Vĩnh Viễn")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $isShowingDetail) {
                if let app = selectedApp {
                    jitDetailSheet(app)
                }
            }
        }
    }

    private var unexploitedWarningCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(Theme.accentAmber)
                .font(.system(size: 18))

            VStack(alignment: .leading, spacing: 4) {
                Text("Cần Kích Hoạt Kernel Exploit")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Theme.accentAmber)
                Text("Để thoát khỏi Sandbox và cấp cờ CS_DEBUGGED (JIT) cho app trong máy, hãy bấm nút kích hoạt Kernel Exploit trước.")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.textSecondary)

                Button(action: {
                    manager.triggerAutoExploit()
                }) {
                    Text("Kích Hoạt Ngay")
                        .font(.system(size: 11, weight: .bold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Theme.accentAmber)
                        .foregroundColor(.black)
                        .cornerRadius(6)
                        .padding(.top, 4)
                }
            }
            Spacer()
        }
        .padding(14)
        .background(Theme.accentAmber.opacity(0.12))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Theme.accentAmber.opacity(0.3), lineWidth: 1)
        )
    }

    private var jitInfoBanner: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Theme.accentGreen.opacity(0.2))
                    .frame(width: 44, height: 44)
                Image(systemName: "bolt.fill")
                    .font(.system(size: 22))
                    .foregroundColor(Theme.accentGreen)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("JIT Không Cần Máy Tính / Wi-Fi")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                Text("Dùng DarkSword Exploit cấp quyền JIT trực tiếp on-device cho PojavLauncher, Dolphin, PPSSPP, UTM.")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.textSecondary)
            }
            Spacer()
        }
        .padding(12)
        .background(Theme.bgCard)
        .cornerRadius(14)
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Theme.textTertiary)
                .font(.system(size: 14))

            TextField("Tìm app muốn bật JIT (Pojav, Dolphin, UTM)...", text: $manager.appSearchQuery)
                .font(.system(size: 13))
                .foregroundColor(Theme.textPrimary)
                .autocapitalization(.none)
                .disableAutocorrection(true)

            if !manager.appSearchQuery.isEmpty {
                Button(action: { manager.appSearchQuery = "" }) {
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

    private func appRow(_ app: InstalledAppItem) -> some View {
        Button(action: {
            selectedApp = app
            showResultBanner = false
            isShowingDetail = true
        }) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Theme.bgSecondary)
                        .frame(width: 48, height: 48)

                    Image(systemName: "bolt.badge.clock.fill")
                        .font(.system(size: 22))
                        .foregroundColor(Theme.accentGreen)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(app.displayName)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Theme.textPrimary)

                    Text(app.bundleID)
                        .font(.system(size: 11))
                        .foregroundColor(Theme.textTertiary)
                        .lineLimit(1)
                }

                Spacer()

                Text(app.isJITEnabled ? "JIT BẬT ✅" : "CHƯA BẬT")
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(app.isJITEnabled ? Theme.accentGreen.opacity(0.2) : Theme.bgSecondary)
                    .foregroundColor(app.isJITEnabled ? Theme.accentGreen : Theme.textTertiary)
                    .cornerRadius(6)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.textTertiary)
            }
            .padding(12)
            .background(Theme.bgCard)
            .cornerRadius(14)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func jitDetailSheet(_ app: InstalledAppItem) -> some View {
        ZStack {
            Theme.bgPrimary.ignoresSafeArea()

            VStack(spacing: 20) {
                jitAppHeader(app)
                jitStatusCard(app)
                jitActionButton(app)
                if showResultBanner {
                    jitResultBanner
                }
                Spacer()
            }
            .padding(16)
        }
    }

    private func jitAppHeader(_ app: InstalledAppItem) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Theme.gradientCyanPurple)
                    .frame(width: 56, height: 56)
                Image(systemName: "bolt.badge.checkmark.fill")
                    .font(.system(size: 26))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(app.displayName)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                Text(app.bundleID)
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textSecondary)
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding(14)
        .background(Theme.bgCard)
        .cornerRadius(16)
    }

    private func jitStatusCard(_ app: InstalledAppItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("TRẠNG THÁI JIT TẦNG NHÂN")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Theme.textTertiary)

            HStack {
                Text("Trạng thái:")
                    .font(.system(size: 13))
                    .foregroundColor(Theme.textSecondary)
                Spacer()
                Text(app.isJITEnabled ? "Đã Kích Hoạt Vĩnh Viễn ✅" : "Chưa Kích Hoạt ⚠️")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(app.isJITEnabled ? Theme.accentGreen : Theme.accentAmber)
            }

            Divider().background(Theme.bgSecondary)

            Text("Khi kích hoạt, cờ CS_DEBUGGED và quyền dynamic-codesigning sẽ được tiêm trực tiếp vào tiến trình app. Bạn chỉ cần mở app lên là chơi game tốc độ cao ngay mà không cần máy tính Mac/PC hay mạng Wi-Fi.")
                .font(.system(size: 11))
                .foregroundColor(Theme.textSecondary)
        }
        .padding(14)
        .background(Theme.bgCard)
        .cornerRadius(16)
    }

    private func jitActionButton(_ app: InstalledAppItem) -> some View {
        Button(action: {
            let (ok, msg) = manager.enablePermanentJIT(for: app)
            isSuccess = ok
            statusMessage = ok ? "Đã kích hoạt JIT vĩnh viễn cho \(app.displayName)! Bây giờ bạn có thể mở app lên và tận hưởng 60-120 FPS." : msg
            showResultBanner = true
        }) {
            HStack(spacing: 8) {
                Image(systemName: "bolt.fill")
                Text("Kích Hoạt JIT Vĩnh Viễn (On-Device)")
                    .font(.system(size: 15, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Theme.gradientCyanPurple)
            .foregroundColor(.white)
            .cornerRadius(16)
            .glow(color: Theme.accentGreen, radius: 8)
        }
    }

    private var jitResultBanner: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: isSuccess ? "checkmark.circle.fill" : "xmark.octagon.fill")
                .foregroundColor(isSuccess ? Theme.accentGreen : Theme.accentRed)
            Text(statusMessage)
                .font(.system(size: 12))
                .foregroundColor(Theme.textPrimary)
            Spacer()
        }
        .padding(12)
        .background((isSuccess ? Theme.accentGreen : Theme.accentRed).opacity(0.15))
        .cornerRadius(12)
    }
}
