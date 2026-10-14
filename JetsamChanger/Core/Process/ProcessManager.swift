import Foundation
import Combine
import SwiftUI

public struct ConsoleLogItem: Identifiable {
    public let id = UUID()
    public let timestamp: Date
    public let message: String
    public let isError: Bool

    public var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: timestamp)
    }
}

public struct DeviceMemoryStats {
    public var totalPhysicalRAMBytes: UInt64
    public var availableMemoryBytes: UInt64
    public var activeMemoryBytes: UInt64
    public var wiredMemoryBytes: UInt64

    public var totalRAMString: String {
        let gb = Double(totalPhysicalRAMBytes) / (1024.0 * 1024.0 * 1024.0)
        return String(format: "%.1f GB", gb)
    }

    public var availableString: String {
        let gb = Double(availableMemoryBytes) / (1024.0 * 1024.0 * 1024.0)
        return String(format: "%.2f GB", gb)
    }

    public var usagePercentage: Double {
        guard totalPhysicalRAMBytes > 0 else { return 0 }
        let used = totalPhysicalRAMBytes - availableMemoryBytes
        return Double(used) / Double(totalPhysicalRAMBytes)
    }
}

@MainActor
public class ProcessManager: ObservableObject {
    public static let shared = ProcessManager()

    @Published public var processes: [JetsamProcessModel] = []
    @Published public var filteredProcesses: [JetsamProcessModel] = []
    @Published public var searchQuery: String = "" {
        didSet { filterProcesses() }
    }
    @Published public var selectedFilter: ProcessFilter = .all {
        didSet { filterProcesses() }
    }

    @Published public var isExploiting: Bool = false
    @Published public var isExploited: Bool = false
    @Published public var exploitStatusText: String = "Exploit Not Initialized"
    @Published public var kernelLogs: [ConsoleLogItem] = []
    @Published public var memoryStats: DeviceMemoryStats = DeviceMemoryStats(
        totalPhysicalRAMBytes: ProcessInfo.processInfo.physicalMemory,
        availableMemoryBytes: 0,
        activeMemoryBytes: 0,
        wiredMemoryBytes: 0
    )

    public enum ProcessFilter: String, CaseIterable, Identifiable {
        case all = "Tất Cả"
        case userApps = "User Apps"
        case highMemory = "Bộ Nhớ Cao"
        case unlimited = "Không Giới Hạn"

        public var id: String { rawValue }
    }

    private var cancellables = Set<AnyCancellable>()
    private var timer: Timer?

    private init() {
        setupLoggingBridge()
        updateMemoryStats()
        refreshProcesses()
        startPeriodicRefresh()
    }

    private func setupLoggingBridge() {
        KernelExploit.shared().logHandler = { [weak self] message, isError in
            Task { @MainActor in
                let item = ConsoleLogItem(timestamp: Date(), message: message, isError: isError)
                self?.kernelLogs.append(item)
                if self?.kernelLogs.count ?? 0 > 300 {
                    self?.kernelLogs.removeFirst(50)
                }
            }
        }
    }

    public func startPeriodicRefresh() {
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateMemoryStats()
            }
        }
    }

    public func updateMemoryStats() {
        let total = ProcessInfo.processInfo.physicalMemory
        var available: UInt64 = total / 2 // Fallback estimate

        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        let hostPort = mach_host_self()

        let kr = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(hostPort, HOST_VM_INFO64, $0, &count)
            }
        }

        if kr == KERN_SUCCESS {
            let pageSize = UInt64(vm_kernel_page_size)
            let free = UInt64(stats.free_count) * pageSize
            let inactive = UInt64(stats.inactive_count) * pageSize
            let active = UInt64(stats.active_count) * pageSize
            let wired = UInt64(stats.wire_count) * pageSize
            available = free + inactive
            self.memoryStats = DeviceMemoryStats(
                totalPhysicalRAMBytes: total,
                availableMemoryBytes: available,
                activeMemoryBytes: active,
                wiredMemoryBytes: wired
            )
        } else {
            self.memoryStats = DeviceMemoryStats(
                totalPhysicalRAMBytes: total,
                availableMemoryBytes: available,
                activeMemoryBytes: 0,
                wiredMemoryBytes: 0
            )
        }
    }

    public func triggerAutoExploit() {
        guard !isExploiting else { return }
        isExploiting = true
        exploitStatusText = "Đang chạy kernel exploit..."

        DispatchQueue.global(qos: .userInitiated).async {
            var error: NSError?
            let success = KernelExploit.shared().runAutomaticExploit(&error)

            Task { @MainActor in
                self.isExploiting = false
                self.isExploited = success
                self.exploitStatusText = KernelExploit.shared().statusString
                self.refreshProcesses()
            }
        }
    }

    public func refreshProcesses() {
        DispatchQueue.global(qos: .userInteractive).async {
            let procs = JetsamModifier.shared().getAllRunningProcesses()
            Task { @MainActor in
                self.processes = procs
                self.filterProcesses()
            }
        }
    }

    private func filterProcesses() {
        var result = processes

        // Apply filter category
        switch selectedFilter {
        case .all:
            break
        case .userApps:
            result = result.filter { proc in
                !proc.name.hasPrefix("com.apple.") && proc.pid > 50 && !["kernel_task", "launchd"].contains(proc.name)
            }
        case .highMemory:
            result = result.filter { $0.footprintBytes >= 200 * 1024 * 1024 }
        case .unlimited:
            result = result.filter { $0.activeLimitMB <= 0 }
        }

        // Apply search query
        if !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty {
            let query = searchQuery.lowercased()
            result = result.filter {
                $0.name.lowercased().contains(query) ||
                $0.bundleID.lowercased().contains(query) ||
                String($0.pid).contains(query)
            }
        }

        filteredProcesses = result
    }

    public func setJetsamLimit(pid: pid_t, limitMB: Int32) -> Bool {
        var err: NSError?
        let ok = JetsamModifier.shared().setJetsamLimit(limitMB, forPID: pid, error: &err)
        if ok { refreshProcesses() }
        return ok
    }

    public func setUnlimited(pid: pid_t) -> Bool {
        var err: NSError?
        let ok = JetsamModifier.shared().setUnlimitedMemory(forPID: pid, error: &err)
        if ok { refreshProcesses() }
        return ok
    }

    public func setPriority(pid: pid_t, priority: Int16) -> Bool {
        var err: NSError?
        let ok = JetsamModifier.shared().setPriority(priority, forPID: pid, error: &err)
        if ok { refreshProcesses() }
        return ok
    }

    public func setFreezable(pid: pid_t, isFreezable: Bool) -> Bool {
        var err: NSError?
        let ok = JetsamModifier.shared().setFreezable(isFreezable, forPID: pid, error: &err)
        if ok { refreshProcesses() }
        return ok
    }

    public func applyPreset(pid: pid_t, presetName: String) -> Bool {
        var err: NSError?
        let ok = JetsamModifier.shared().applyJetsamPreset(presetName, forPID: pid, error: &err)
        if ok { refreshProcesses() }
        return ok
    }
}
