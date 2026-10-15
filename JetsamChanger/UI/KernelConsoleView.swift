import SwiftUI

struct KernelConsoleView: View {
    @ObservedObject var manager = ToolboxManager.shared
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Theme.bgPrimary.ignoresSafeArea()

                VStack(spacing: 12) {
                    headerStatus
                    terminalOutput
                    actionBar
                }
                .padding()
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

    private var headerStatus: some View {
        HStack {
            Circle()
                .fill(manager.isExploited ? Theme.accentGreen : Theme.accentAmber)
                .frame(width: 10, height: 10)

            Text(manager.exploitStatusText)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(Theme.textPrimary)

            Spacer()

            Button(action: {
                manager.kernelLogs.removeAll()
            }) {
                Image(systemName: "trash")
                    .foregroundColor(Theme.textSecondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Theme.bgSecondary)
        .cornerRadius(10)
    }

    private var terminalOutput: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 6) {
                ForEach(manager.kernelLogs) { log in
                    HStack(alignment: .top, spacing: 6) {
                        Text(log.formattedTime)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(Theme.textTertiary)

                        Text(log.message)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(log.isError ? Theme.accentRed : (log.message.contains("[✓]") ? Theme.accentGreen : Theme.accentCyan))
                    }
                }
            }
            .padding(10)
        }
        .background(Color.black.opacity(0.85))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Theme.accentCyan.opacity(0.25), lineWidth: 1)
        )
    }

    private var actionBar: some View {
        Button(action: {
            manager.triggerAutoExploit()
        }) {
            HStack {
                if manager.isExploiting {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: "bolt.fill")
                }
                Text(manager.isExploited ? "Chạy Lại Kernel Exploit" : "Kích Hoạt Kernel Exploit")
                    .font(.system(size: 14, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Theme.gradientCyanPurple)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(manager.isExploiting)
    }
}
