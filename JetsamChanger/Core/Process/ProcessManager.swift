import Foundation
import Combine
import SwiftUI
import Darwin

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
public class ToolboxManager: ObservableObject {
    public static let shared = ToolboxManager()

    // MARK: - Exploit State
    @Published public var isExploiting: Bool = false
    @Published public var isExploited: Bool = false
    @Published public var exploitStatusText: String = "Chưa Kích Hoạt Exploit"
    @Published public var exploitEngineName: String = "DarkSword (A14 Optimized)"
    @Published public var kernelLogs: [ConsoleLogItem] = []

    // MARK: - Installed Apps & Dylib Injection
    @Published public var installedApps: [InstalledAppItem] = []
    @Published public var filteredInstalledApps: [InstalledAppItem] = []
    @Published public var appSearchQuery: String = "" {
        didSet { filterInstalledApps() }
    }

    // MARK: - LaunchDaemons
    @Published public var daemons: [DaemonItem] = []
    @Published public var filteredDaemons: [DaemonItem] = []
    @Published public var daemonSearchQuery: String = "" {
        didSet { filterDaemons() }
    }

    // MARK: - Exploit Tweaks
    @Published public var thermalThrottleBypassed: Bool = false
    @Published public var jitEnabled: Bool = false
    @Published public var fakeGPSActive: Bool = false
    @Published public var fakeLat: Double = 21.028511
    @Published public var fakeLon: Double = 105.854444
    @Published public var blockOTAActive: Bool = true
    @Published public var dynamicIslandActive: Bool = false

    // MARK: - Jetsam Processes
    @Published public var processes: [JetsamProcessModel] = []
    @Published public var filteredProcesses: [JetsamProcessModel] = []
    @Published public var searchQuery: String = "" {
        didSet { filterProcesses() }
    }
    @Published public var selectedFilter: ProcessFilter = .all {
        didSet { filterProcesses() }
    }

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
        refreshAll()
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

    public func refreshAll() {
        refreshInstalledApps()
        refreshDaemons()
        refreshProcesses()
        updateMemoryStats()
    }

    public func startPeriodicRefresh() {
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateMemoryStats()
            }
        }
    }

    // MARK: - Exploit Action
    public func triggerAutoExploit() {
        guard !isExploiting else { return }
        isExploiting = true
        exploitStatusText = "Đang chạy DarkSword Kernel Exploit..."

        DispatchQueue.global(qos: .userInitiated).async {
            let success = KernelExploit.shared().runAutomaticExploit()
            DispatchQueue.main.async {
                self.isExploiting = false
                self.isExploited = success
                self.exploitStatusText = KernelExploit.shared().statusString
                self.exploitEngineName = KernelExploit.shared().exploitEngineName
                self.refreshAll()
            }
        }
    }

    // MARK: - Dylib Injector Actions
    public func refreshInstalledApps() {
        let apps = DylibInjector.shared().scanInstalledApplications()
        self.installedApps = apps
        filterInstalledApps()
    }

    private func filterInstalledApps() {
        if appSearchQuery.trimmingCharacters(in: .whitespaces).isEmpty {
            filteredInstalledApps = installedApps
        } else {
            let q = appSearchQuery.lowercased()
            filteredInstalledApps = installedApps.filter {
                $0.displayName.lowercased().contains(q) ||
                $0.bundleID.lowercased().contains(q)
            }
        }
    }

    public func injectDylib(url: URL, to app: InstalledAppItem) -> (Bool, String) {
        var err: NSString? = nil
        let ok = DylibInjector.shared().injectDylib(at: url, into: app, error: &err)
        refreshInstalledApps()
        return (ok, (err as String?) ?? (ok ? "Thành công!" : "Lỗi không xác định"))
    }

    public func ejectDylib(named: String, from app: InstalledAppItem) -> Bool {
        var err: NSString? = nil
        let ok = DylibInjector.shared().ejectDylib(named: named, from: app, error: &err)
        refreshInstalledApps()
        return ok
    }

    public func restoreOriginalApp(app: InstalledAppItem) -> Bool {
        var err: NSString? = nil
        let ok = DylibInjector.shared().restoreOriginalBinary(for: app, error: &err)
        refreshInstalledApps()
        return ok
    }

    public func enablePermanentJIT(for app: InstalledAppItem) -> (Bool, String) {
        var err: NSString? = nil
        let ok = DylibInjector.shared().enablePermanentJIT(for: app, error: &err)
        refreshInstalledApps()
        return (ok, (err as String?) ?? (ok ? "Đã kích hoạt JIT vĩnh viễn!" : "Lỗi kích hoạt JIT."))
    }

    // MARK: - LaunchDaemon Actions
    public func refreshDaemons() {
        self.daemons = DaemonManager.shared().getAllDaemons()
        filterDaemons()
    }

    private func filterDaemons() {
        if daemonSearchQuery.trimmingCharacters(in: .whitespaces).isEmpty {
            filteredDaemons = daemons
        } else {
            let q = daemonSearchQuery.lowercased()
            filteredDaemons = daemons.filter {
                $0.name.lowercased().contains(q) ||
                $0.bundleID.lowercased().contains(q) ||
                $0.category.lowercased().contains(q)
            }
        }
    }

    public func toggleDaemon(daemon: DaemonItem, enable: Bool) -> Bool {
        let ok = DaemonManager.shared().toggleDaemon(daemon, enable: enable)
        refreshDaemons()
        return ok
    }

    public func oneTapOptimizeDaemons() -> Int {
        let freedMB = DaemonManager.shared().oneTapOptimizeAllDaemons()
        refreshDaemons()
        updateMemoryStats()
        return Int(freedMB)
    }

    // MARK: - Exploit Tweaks Actions
    public func toggleThermalBypass(enable: Bool) {
        let ok = KernelExploit.shared().setThermalThrottlingBypass(enable)
        if ok { thermalThrottleBypassed = enable }
    }

    public func toggleJIT(enable: Bool) {
        let ok = KernelExploit.shared().setOnDeviceJITEnabled(enable)
        if ok { jitEnabled = enable }
    }

    public func toggleFakeGPS(lat: Double, lon: Double, enable: Bool) {
        let ok = KernelExploit.shared().setFakeGPSWithLat(lat, lon: lon, enabled: enable)
        if ok {
            fakeGPSActive = enable
            fakeLat = lat
            fakeLon = lon
        }
    }

    public func toggleBlockOTA(enable: Bool) {
        let ok = KernelExploit.shared().setBlockOTAUpdates(enable)
        if ok { blockOTAActive = enable }
    }

    public func toggleDynamicIsland(enable: Bool) {
        let ok = KernelExploit.shared().setDynamicIslandEnabled(enable)
        if ok { dynamicIslandActive = enable }
    }

    // MARK: - Memory & Jetsam Processes Actions
    public func updateMemoryStats() {
        var pageSize: vm_size_t = vm_size_t(vm_page_size)
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
        var vmStats = vm_statistics64_data_t()

        let kerr = withUnsafeMutablePointer(to: &vmStats) { statsPtr in
            statsPtr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                host_statistics64(mach_host_self(), HOST_VM_INFO64, intPtr, &count)
            }
        }

        if kerr == KERN_SUCCESS {
            let free = UInt64(vmStats.free_count) * UInt64(pageSize)
            let inactive = UInt64(vmStats.inactive_count) * UInt64(pageSize)
            let active = UInt64(vmStats.active_count) * UInt64(pageSize)
            let wired = UInt64(vmStats.wire_count) * UInt64(pageSize)

            memoryStats.availableMemoryBytes = free + inactive
            memoryStats.activeMemoryBytes = active
            memoryStats.wiredMemoryBytes = wired
        }
    }

    public func refreshProcesses() {
        DispatchQueue.global(qos: .userInitiated).async {
            let procs = JetsamModifier.shared().getAllRunningProcesses()
            DispatchQueue.main.async {
                self.processes = procs
                self.filterProcesses()
            }
        }
    }

    private func filterProcesses() {
        var result = processes

        switch selectedFilter {
        case .all:
            break
        case .userApps:
            result = result.filter { !$0.bundleID.isEmpty && !$0.bundleID.hasPrefix("com.apple.") }
        case .highMemory:
            result = result.filter { $0.footprintBytes >= 200 * 1024 * 1024 }
        case .unlimited:
            result = result.filter { $0.activeLimitMB <= 0 }
        }

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
        let ok = JetsamModifier.shared().setJetsamLimit(limitMB, forPID: pid)
        if ok { refreshProcesses() }
        return ok
    }

    public func setUnlimited(pid: pid_t) -> Bool {
        let ok = JetsamModifier.shared().setUnlimitedMemoryForPID(pid)
        if ok { refreshProcesses() }
        return ok
    }

    public func setPriority(pid: pid_t, priority: Int16) -> Bool {
        let ok = JetsamModifier.shared().setPriority(priority, forPID: pid)
        if ok { refreshProcesses() }
        return ok
    }

    public func setFreezable(pid: pid_t, isFreezable: Bool) -> Bool {
        let ok = JetsamModifier.shared().setFreezable(isFreezable, forPID: pid)
        if ok { refreshProcesses() }
        return ok
    }

    public func applyPreset(pid: pid_t, presetName: String) -> Bool {
        let ok = JetsamModifier.shared().applyJetsamPreset(presetName, forPID: pid)
        if ok { refreshProcesses() }
        return ok
    }
}

// Backwards compatibility alias
public typealias ProcessManager = ToolboxManager
