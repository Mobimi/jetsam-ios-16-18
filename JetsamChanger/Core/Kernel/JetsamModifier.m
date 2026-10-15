#import "JetsamModifier.h"
#import "KernelMemory.h"
#import "KernelExploit.h"
#import <sys/sysctl.h>
#import <mach/mach.h>
#import <dlfcn.h>
#import <unistd.h>

static inline int j_memorystatus_control(uint32_t command, int32_t pid, uint32_t flags, void *buffer, size_t buffersize) {
    typedef int (*memorystatus_control_fn)(uint32_t, int32_t, uint32_t, void*, size_t);
    static memorystatus_control_fn fn = NULL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        fn = (memorystatus_control_fn)dlsym(RTLD_DEFAULT, "memorystatus_control");
    });
    if (fn) {
        return fn(command, pid, flags, buffer, buffersize);
    }
    return (int)syscall(440, command, pid, flags, buffer, buffersize);
}

static inline int j_proc_name(int pid, void *buffer, uint32_t buffersize) {
    typedef int (*proc_name_fn)(int, void*, uint32_t);
    static proc_name_fn fn = NULL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        fn = (proc_name_fn)dlsym(RTLD_DEFAULT, "proc_name");
    });
    if (fn) {
        return fn(pid, buffer, buffersize);
    }
    return -1;
}

static inline int j_proc_pidinfo(int pid, int flavor, uint64_t arg, void *buffer, int buffersize) {
    typedef int (*proc_pidinfo_fn)(int, int, uint64_t, void*, int);
    static proc_pidinfo_fn fn = NULL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        fn = (proc_pidinfo_fn)dlsym(RTLD_DEFAULT, "proc_pidinfo");
    });
    if (fn) {
        return fn(pid, flavor, arg, buffer, buffersize);
    }
    return -1;
}

@implementation JetsamProcessModel

- (NSString *)formattedFootprint {
    double mb = (double)self.footprintBytes / (1024.0 * 1024.0);
    if (mb >= 1024.0) {
        return [NSString stringWithFormat:@"%.2f GB", mb / 1024.0];
    }
    return [NSString stringWithFormat:@"%.1f MB", mb];
}

- (NSString *)formattedLimit {
    if (self.activeLimitMB <= 0) {
        return @"Unlimited (∞)";
    }
    if (self.activeLimitMB >= 1024) {
        return [NSString stringWithFormat:@"%.1f GB (%d MB)", (double)self.activeLimitMB / 1024.0, self.activeLimitMB];
    }
    return [NSString stringWithFormat:@"%d MB", self.activeLimitMB];
}

- (NSString *)priorityDescription {
    switch (self.effectivePriority) {
        case JETSAM_PRIORITY_IDLE: return @"Idle (0)";
        case JETSAM_PRIORITY_BACKGROUND: return @"Background (2)";
        case JETSAM_PRIORITY_FOREGROUND: return @"Foreground (10)";
        case JETSAM_PRIORITY_FOREGROUND_KEY: return @"Foreground Key (18)";
        case JETSAM_PRIORITY_CRITICAL: return @"Critical System (21)";
        default: return [NSString stringWithFormat:@"Tier %d", self.effectivePriority];
    }
}

@end

@implementation JetsamModifier

+ (instancetype)shared {
    return [self sharedModifier];
}

+ (instancetype)sharedModifier {
    static JetsamModifier *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[JetsamModifier alloc] init];
    });
    return instance;
}

- (NSArray<JetsamProcessModel *> *)getAllRunningProcesses {
    NSMutableArray<JetsamProcessModel *> *list = [NSMutableArray array];

    int mib[4] = {CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0};
    size_t size = 0;
    if (sysctl(mib, 4, NULL, &size, NULL, 0) < 0) {
        return list;
    }

    struct kinfo_proc *procs = (struct kinfo_proc *)malloc(size);
    if (!procs) return list;

    if (sysctl(mib, 4, procs, &size, NULL, 0) == 0) {
        size_t count = size / sizeof(struct kinfo_proc);
        for (size_t i = 0; i < count; i++) {
            pid_t pid = procs[i].kp_proc.p_pid;
            if (pid <= 0) continue;

            char nameBuf[256] = {0};
            j_proc_name(pid, nameBuf, sizeof(nameBuf));
            if (strlen(nameBuf) == 0) {
                strlcpy(nameBuf, procs[i].kp_proc.p_comm, sizeof(nameBuf));
            }

            JetsamProcessModel *model = [[JetsamProcessModel alloc] init];
            model.pid = pid;
            model.name = [NSString stringWithUTF8String:nameBuf];
            model.bundleID = [self resolveBundleIDForPID:pid name:model.name];

            // Memory footprint via proc_pidinfo
            struct proc_taskinfo pti;
            if (j_proc_pidinfo(pid, PROC_PIDTASKINFO, 0, &pti, sizeof(pti)) == sizeof(pti)) {
                model.footprintBytes = pti.pti_resident_size;
            }

            // Fetch Jetsam details
            [self populateJetsamDetails:model];
            [list addObject:model];
        }
    }

    free(procs);

    // Sort by footprint descending
    [list sortUsingComparator:^NSComparisonResult(JetsamProcessModel *obj1, JetsamProcessModel *obj2) {
        if (obj1.footprintBytes > obj2.footprintBytes) return NSOrderedAscending;
        if (obj1.footprintBytes < obj2.footprintBytes) return NSOrderedDescending;
        return [obj1.name caseInsensitiveCompare:obj2.name];
    }];

    return list;
}

- (NSString *)resolveBundleIDForPID:(pid_t)pid name:(NSString *)name {
    // Dynamic identifier mapping for common applications
    NSDictionary *knownApps = @{
        @"Amethyst": @"com.amethyst.minecraft",
        @"PojavLauncher": @"net.kdt.pojavlauncher",
        @"LiveContainer": @"com.kdt.livecontainer",
        @"Dolphin": @"org.dolphin-emu.dolphin",
        @"MeloNX": @"org.ryujinx.melonx",
        @"UTM": @"com.utmapp.UTM",
        @"MobileSafari": @"com.apple.mobilesafari",
        @"Camera": @"com.apple.camera"
    };

    if (knownApps[name]) {
        return knownApps[name];
    }
    return [NSString stringWithFormat:@"process.%@", [name lowercaseString]];
}

- (void)populateJetsamDetails:(JetsamProcessModel *)model {
    proc_offsets_t *offsets = get_calibrated_offsets();
    uint64_t allproc = get_allproc_head();

    // If kernel primitive is ready, read directly from kernel proc_t
    if ([KernelExploit sharedExploit].status == EXPLOIT_STATUS_READY && allproc != 0 && offsets->offsets_resolved) {
        uint64_t curr = allproc;
        while (curr != 0) {
            uint32_t curr_pid = kread32(curr + offsets->proc_pid);
            if (curr_pid == (uint32_t)model.pid) {
                model.procKernelAddr = curr;
                model.activeLimitMB = (int32_t)kread32(curr + offsets->proc_memstat_memlimit);
                model.inactiveLimitMB = (int32_t)kread32(curr + offsets->proc_memstat_memlimit_inactive);
                model.effectivePriority = (int16_t)kread16(curr + offsets->proc_memstat_effective_priority);
                model.stateFlags = kread32(curr + offsets->proc_memstat_state);
                model.isFatal = (model.stateFlags & P_MEMSTAT_FATAL_MEMLIMIT) != 0;
                model.isFrozen = (model.stateFlags & P_MEMSTAT_FROZEN) != 0;
                return;
            }
            curr = kread_ptr(curr + offsets->proc_list_prev);
            if (curr == allproc) break;
        }
    }

    // Default heuristic limits based on Darwin standard values
    model.activeLimitMB = (model.pid <= 100) ? -1 : 2048;
    model.inactiveLimitMB = 512;
    model.effectivePriority = JETSAM_PRIORITY_FOREGROUND;
    model.isFatal = YES;
    model.isFrozen = NO;
}

- (nullable JetsamProcessModel *)getJetsamInfoForPID:(pid_t)pid {
    NSArray<JetsamProcessModel *> *all = [self getAllRunningProcesses];
    for (JetsamProcessModel *proc in all) {
        if (proc.pid == pid) return proc;
    }
    return nil;
}

- (BOOL)setJetsamLimit:(int32_t)limitMB forPID:(pid_t)pid {
    [[KernelExploit sharedExploit] logMessage:[NSString stringWithFormat:@"[*] Modifying Jetsam limit for PID %d to %d MB...", pid, limitMB]];

    BOOL success = NO;

    // Direct kernel struct modification if primitive active
    proc_offsets_t *offsets = get_calibrated_offsets();
    uint64_t allproc = get_allproc_head();

    if ([KernelExploit sharedExploit].status == EXPLOIT_STATUS_READY && allproc != 0 && offsets->offsets_resolved) {
        uint64_t curr = allproc;
        while (curr != 0) {
            uint32_t curr_pid = kread32(curr + offsets->proc_pid);
            if (curr_pid == (uint32_t)pid) {
                // Write active limit
                kwrite32(curr + offsets->proc_memstat_memlimit, (uint32_t)limitMB);
                
                // Clear P_MEMSTAT_FATAL_MEMLIMIT if limit is raised or unlimited
                uint32_t state = kread32(curr + offsets->proc_memstat_state);
                if (limitMB <= 0 || limitMB >= 4096) {
                    state &= ~P_MEMSTAT_FATAL_MEMLIMIT;
                } else {
                    state |= P_MEMSTAT_FATAL_MEMLIMIT;
                }
                kwrite32(curr + offsets->proc_memstat_state, state);

                [[KernelExploit sharedExploit] logMessage:[NSString stringWithFormat:@"[+] Kernel proc_t patched at 0x%llx: limit=%d MB, state=0x%x", curr, limitMB, state]];
                success = YES;
                break;
            }
            curr = kread_ptr(curr + offsets->proc_list_prev);
            if (curr == allproc) break;
        }
    }

    // Call memorystatus_control syscall
    int ret = j_memorystatus_control(MEMORYSTATUS_CMD_SET_JETSAM_HIGH_WATER_MARK, pid, (uint32_t)limitMB, NULL, 0);
    if (ret == 0) {
        [[KernelExploit sharedExploit] logMessage:[NSString stringWithFormat:@"[+] memorystatus_control syscall succeeded for PID %d.", pid]];
        success = YES;
    } else {
        [[KernelExploit sharedExploit] logMessage:[NSString stringWithFormat:@"[*] memorystatus_control returned %d (Kernel direct write: %@)", ret, success ? @"OK" : @"FAILED"]];
    }

    return success;
}

- (BOOL)setPriority:(int16_t)priority forPID:(pid_t)pid {
    [[KernelExploit sharedExploit] logMessage:[NSString stringWithFormat:@"[*] Adjusting priority for PID %d to %d...", pid, priority]];

    proc_offsets_t *offsets = get_calibrated_offsets();
    uint64_t allproc = get_allproc_head();

    if ([KernelExploit sharedExploit].status == EXPLOIT_STATUS_READY && allproc != 0 && offsets->offsets_resolved) {
        uint64_t curr = allproc;
        while (curr != 0) {
            uint32_t curr_pid = kread32(curr + offsets->proc_pid);
            if (curr_pid == (uint32_t)pid) {
                kwrite16(curr + offsets->proc_memstat_effective_priority, (uint16_t)priority);
                kwrite16(curr + offsets->proc_memstat_requested_priority, (uint16_t)priority);
                [[KernelExploit sharedExploit] logMessage:[NSString stringWithFormat:@"[+] Kernel proc_t priority updated to %d.", priority]];
                return YES;
            }
            curr = kread_ptr(curr + offsets->proc_list_prev);
            if (curr == allproc) break;
        }
    }

    memorystatus_priority_properties_t props;
    props.priority = priority;
    props.user_data = 0;
    int ret = j_memorystatus_control(MEMORYSTATUS_CMD_SET_PRIORITY_PROPERTIES, pid, 0, &props, sizeof(props));
    return (ret == 0);
}

- (BOOL)setFreezable:(BOOL)isFreezable forPID:(pid_t)pid {
    int ret = j_memorystatus_control(MEMORYSTATUS_CMD_SET_PROCESS_IS_FREEZABLE, pid, isFreezable ? 1 : 0, NULL, 0);
    return (ret == 0);
}

- (BOOL)setUnlimitedMemoryForPID:(pid_t)pid {
    [[KernelExploit sharedExploit] logMessage:[NSString stringWithFormat:@"[!] Setting UNLIMITED Jetsam budget (-1) for PID %d...", pid]];
    // Limit of -1 means no limit enforced by Darwin
    BOOL res1 = [self setJetsamLimit:-1 forPID:pid];
    BOOL res2 = [self setPriority:JETSAM_PRIORITY_CRITICAL forPID:pid];
    return res1 || res2;
}

- (BOOL)applyJetsamPreset:(NSString *)presetName forPID:(pid_t)pid {
    if ([presetName isEqualToString:@"Minecraft / Amethyst"]) {
        // Amethyst / PojavLauncher optimal 6GB allocation with Foreground Key priority
        [self setJetsamLimit:6144 forPID:pid];
        [self setPriority:JETSAM_PRIORITY_FOREGROUND_KEY forPID:pid];
        return YES;
    } else if ([presetName isEqualToString:@"Emulators (Dolphin / UTM)"]) {
        // 4GB allocation for heavy JIT emulators
        [self setJetsamLimit:4096 forPID:pid];
        [self setPriority:JETSAM_PRIORITY_FOREGROUND forPID:pid];
        return YES;
    } else if ([presetName isEqualToString:@"Unlimited (No Jetsam Kill)"]) {
        return [self setUnlimitedMemoryForPID:pid];
    } else if ([presetName isEqualToString:@"System Default"]) {
        [self setJetsamLimit:2048 forPID:pid];
        [self setPriority:JETSAM_PRIORITY_FOREGROUND forPID:pid];
        return YES;
    }
    return NO;
}

@end
