import SwiftUI
import UniformTypeIdentifiers

struct DocumentPicker: UIViewControllerRepresentable {
    var onPick: (URL) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.item, .data], asCopy: true)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var onPick: (URL) -> Void

        init(onPick: @escaping (URL) -> Void) {
            self.onPick = onPick
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            if let first = urls.first {
                onPick(first)
            }
        }
    }
}

struct DylibInjectorView: View {
    @ObservedObject var manager = ToolboxManager.shared
    @State private var selectedApp: InstalledAppItem? = nil
    @State private var isShowingDetail: Bool = false
    @State private var showingFilePicker = false
    @State private var pickedDylibURL: URL? = nil
    @State private var pickedDylibName: String = ""
    @State private var statusMessage: String = ""
    @State private var showStatusBanner: Bool = false
    @State private var isSuccess: Bool = false

    var body: some View {
        NavigationView {
            ZStack {
                Theme.bgPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // 1. Exploit Requirement Notice
                        if !manager.isExploited {
                            unexploitedWarningCard
                        }

                        // 2. Search & Filter
                        searchBar

                        // 3. Header summary
                        HStack {
                            Text("ỨNG DỤNG ĐÃ CÀI ĐẶT (\(manager.filteredInstalledApps.count))")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Theme.textTertiary)
                            Spacer()
                            Button(action: { manager.refreshInstalledApps() }) {
                                Image(systemName: "arrow.clockwise")
                                    .foregroundColor(Theme.accentCyan)
                            }
                        }

                        // 4. Installed Apps List
                        LazyVStack(spacing: 12) {
                            ForEach(manager.filteredInstalledApps, id: \.bundleID) { app in
                                appCard(app)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Tiêm Tweak (Dylib)")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $isShowingDetail) {
                if let app = selectedApp {
                    appDetailSheet(app)
                }
            }
            .sheet(isPresented: $showingFilePicker) {
                DocumentPicker { url in
                    self.pickedDylibURL = url
                    self.pickedDylibName = url.lastPathComponent
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
                Text("Để thoát Sandbox và quét danh sách app trong máy, hãy bấm nút kích hoạt Kernel Exploit trước.")
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

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Theme.textTertiary)
                .font(.system(size: 14))

            TextField("Tìm kiếm app đã cài đặt (Tên, bundle ID)...", text: $manager.appSearchQuery)
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

    private func appCard(_ app: InstalledAppItem) -> some View {
        Button(action: {
            selectedApp = app
            pickedDylibURL = nil
            pickedDylibName = ""
            showStatusBanner = false
            isShowingDetail = true
        }) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Theme.bgSecondary)
                        .frame(width: 48, height: 48)

                    Image(systemName: app.displayName.lowercased().contains("pojav") || app.displayName.lowercased().contains("minecraft") ? "cube.fill" : "app.fill")
                        .font(.system(size: 22))
                        .foregroundColor(Theme.accentCyan)
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(app.displayName)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Theme.textPrimary)

                        if app.injectedDylibs.count > 0 {
                            Text("\(app.injectedDylibs.count) Tweak")
                                .font(.system(size: 9, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Theme.accentGreen.opacity(0.2))
                                .foregroundColor(Theme.accentGreen)
                                .cornerRadius(4)
                        }
                    }

                    Text(app.bundleID)
                        .font(.system(size: 11))
                        .foregroundColor(Theme.textTertiary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.textTertiary)
            }
            .padding(12)
            .background(Theme.bgCard)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(app.injectedDylibs.count > 0 ? Theme.accentGreen.opacity(0.3) : Theme.bgSecondary, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // Detail modal for injecting tweaks into the chosen app
    private func appDetailSheet(_ app: InstalledAppItem) -> some View {
        ZStack {
            Theme.bgPrimary.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    sheetHeader(app)
                    sheetInjectedDylibs(app)
                    sheetTweakPicker(app)
                }
                .padding(16)
            }
        }
    }

    private func sheetHeader(_ app: InstalledAppItem) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Theme.gradientCyanPurple)
                    .frame(width: 56, height: 56)
                Image(systemName: "app.gift.fill")
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

    private func sheetInjectedDylibs(_ app: InstalledAppItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("TWEAK / DYLIB ĐÃ CHÈN TRỰC TIẾP")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Theme.textTertiary)

            if app.injectedDylibs.isEmpty {
                Text("Chưa có dylib nào được tiêm vào app này.")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textTertiary)
                    .padding(12)
            } else {
                ForEach(app.injectedDylibs, id: \.self) { dylib in
                    HStack {
                        Image(systemName: "puzzlepiece.fill")
                            .foregroundColor(Theme.accentGreen)
                        Text(dylib)
                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                            .foregroundColor(Theme.textPrimary)
                        Spacer()
                        Button(action: {
                            _ = manager.ejectDylib(named: dylib, from: app)
                        }) {
                            Text("Gỡ (Eject)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Theme.accentRed)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Theme.accentRed.opacity(0.15))
                                .cornerRadius(6)
                        }
                    }
                    .padding(12)
                    .background(Theme.bgCard)
                    .cornerRadius(12)
                }
            }
        }
    }

    private func sheetTweakPicker(_ app: InstalledAppItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("TIÊM TWEAK MỚI (IN-PLACE INJECTION)")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Theme.textTertiary)

            Button(action: { showingFilePicker = true }) {
                HStack {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 16))
                    Text(pickedDylibName.isEmpty ? "Chọn file .dylib từ Ứng dụng Tệp..." : pickedDylibName)
                        .font(.system(size: 13, weight: .medium))
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: "chevron.up.and.down")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textTertiary)
                }
                .padding(14)
                .background(Theme.bgSecondary)
                .foregroundColor(pickedDylibName.isEmpty ? Theme.textSecondary : Theme.accentCyan)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Theme.accentCyan.opacity(0.3), lineWidth: 1)
                )
            }

            // Inject Button
            Button(action: {
                if let url = pickedDylibURL {
                    let (ok, msg) = manager.injectDylib(url: url, to: app)
                    isSuccess = ok
                    statusMessage = msg
                    showStatusBanner = true
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "bolt.badge.checkmark.fill")
                    Text("Tiêm Tweak Ngay (Inject)")
                        .font(.system(size: 15, weight: .bold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(pickedDylibURL == nil ? Theme.bgSecondary : Theme.gradientCyanPurple)
                .foregroundColor(.white)
                .cornerRadius(14)
            }
            .disabled(pickedDylibURL == nil)

            // Status Banner
            if showStatusBanner {
                HStack(spacing: 10) {
                    Image(systemName: isSuccess ? "checkmark.circle.fill" : "xmark.octagon.fill")
                        .foregroundColor(isSuccess ? Theme.accentGreen : Theme.accentRed)
                    Text(statusMessage)
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textPrimary)
                    Spacer()
                }
                .padding(12)
                .background((isSuccess ? Theme.accentGreen : Theme.accentRed).opacity(0.15))
                .cornerRadius(10)
            }

            // Restore original pristine binary
            Button(action: {
                _ = manager.restoreOriginalApp(app: app)
                isSuccess = true
                statusMessage = "Đã khôi phục file binary gốc (.orig)!"
                showStatusBanner = true
            }) {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Khôi Phục File Gốc Ban Đầu (.orig)")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(Theme.accentAmber)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
            }
        }
        .padding(14)
        .background(Theme.bgCard)
        .cornerRadius(16)
    }
}

