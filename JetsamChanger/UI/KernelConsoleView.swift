import SwiftUI

struct KernelConsoleView: View {
    @ObservedObject var manager = ProcessManager.shared
    @Environment(\.dismiss) var dismiss
    @State private var autoScroll = true

    var body: some View {
        NavigationView {
            ZStack {
                Theme.bgPrimary.ignoresSafeArea()

                VStack(spacing: 12) {
                    // Header Status
                    HStack {
                        Circle()
                            .fill(manager.isExploited ? Theme.accentGreen : (manager.isExploiting ? Theme.accentAmber : Theme.accentRed))
                            .frame(width: 10, height: 10)
                            .glow(color: manager.isExploited ? Theme.accentGreen : Theme.accentAmber)

                        Text(manager.exploitStatusText)
                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                            .foregroundColor(Theme.textPrimary)

                        Spacer()

                        Button(action: {
                            manager.kernelLogs.removeAll()
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(Theme.textSecondary)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Theme.bgSecondary)
                    .cornerRadius(10)
                    .padding(.horizontal)

                    // Terminal Output Window
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 6) {
                                ForEach(manager.kernelLogs) { log in
                                    HStack(alignment: .top, spacing: 8) {
                                        Text(log.formattedTime)
                                            .font(.system(size: 11, design: .monospaced))
                                            .foregroundColor(Theme.textTertiary)

                                        Text(log.message)
                                            .font(.system(size: 12, design: .monospaced))
                                            .foregroundColor(log.isError ? Theme.accentRed : (log.message.contains("[✓]") || log.message.contains("[+]") ? Theme.accentGreen : Theme.accentCyan))
                                            .multilineTextAlignment(.leading)
                                    }
                                    .id(log.id)
                                }
                            }
                            .padding(12)
                        }
                        .background(Color.black.opacity(0.75))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Theme.accentCyan.opacity(0.3), lineWidth: 1)
                        )
                        .padding(.horizontal)
                        .onChange(of: manager.kernelLogs.count) {
                            if autoScroll, let last = manager.kernelLogs.last {
                                withAnimation {
                                    proxy.scrollTo(last.id, anchor: .bottom)
                                }
                            }
                        }
                    }

                    // Action bar
                    HStack(spacing: 12) {
                        Button(action: {
                            manager.triggerAutoExploit()
                        }) {
                            HStack {
                                if manager.isExploiting {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "bolt.fill")
                                }
                                Text(manager.isExploited ? "Chạy Lại Kernel Exploit" : "Kích Hoạt Auto Exploit")
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Theme.gradientCyanPurple)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .glow(color: Theme.accentCyan, radius: 6)
                        }
                        .disabled(manager.isExploiting)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
            }
            .navigationTitle("Kernel Console ⚡")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Đóng") {
                        dismiss()
                    }
                    .foregroundColor(Theme.accentCyan)
                }
            }
        }
    }
}
