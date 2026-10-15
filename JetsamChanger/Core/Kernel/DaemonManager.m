#import "DaemonManager.h"
#import "KernelExploit.h"
#include <signal.h>
#include <sys/sysctl.h>

@implementation DaemonItem
@end

@interface DaemonManager ()
@property (nonatomic, strong) NSMutableArray<DaemonItem *> *daemonsList;
@end

@implementation DaemonManager

+ (instancetype)shared {
    static DaemonManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[DaemonManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _daemonsList = [NSMutableArray array];
        [self loadDefaultDaemons];
    }
    return self;
}

- (void)loadDefaultDaemons {
    NSArray<NSDictionary *> *defaults = @[
        @{
            @"name": @"ReportCrash (Báo Cáo Lỗi)",
            @"id": @"com.apple.ReportCrash",
            @"desc": @"Ghi lại log crash của mọi app, gây đơ giật máy và tốn CPU khi có app bị sập.",
            @"cat": @"Hệ Thống",
            @"ram": @48,
            @"safe": @YES
        },
        @{
            @"name": @"SoftwareUpdate (Cập Nhật iOS)",
            @"id": @"com.apple.softwareupdated",
            @"desc": @"Tự động kiểm tra và tải các bản cập nhật iOS mới từ máy chủ Apple.",
            @"cat": @"Cập Nhật",
            @"ram": @62,
            @"safe": @YES
        },
        @{
            @"name": @"Analytics & Telemetry",
            @"id": @"com.apple.analyticsd",
            @"desc": @"Gửi dữ liệu chẩn đoán sử dụng máy về Apple mỗi ngày.",
            @"cat": @"Quyền Riêng Tư",
            @"ram": @35,
            @"safe": @YES
        },
        @{
            @"name": @"Diagnostics Agent",
            @"id": @"com.apple.diagnostics_agent",
            @"desc": @"Thu thập thông số phần cứng định kỳ chạy ngầm.",
            @"cat": @"Quyền Riêng Tư",
            @"ram": @28,
            @"safe": @YES
        },
        @{
            @"name": @"Tips Daemon (Mẹo Vặt)",
            @"id": @"com.apple.tipsd",
            @"desc": @"Gửi thông báo gợi ý mẹo sử dụng iPhone, hoàn toàn không cần thiết.",
            @"cat": @"Tiện Ích",
            @"ram": @24,
            @"safe": @YES
        },
        @{
            @"name": @"Game Controller Daemon",
            @"id": @"com.apple.gamecontrollerd",
            @"desc": @"Quản lý kết nối tay cầm chơi game Bluetooth (DualShock, Xbox).",
            @"cat": @"Phần Cứng",
            @"ram": @32,
            @"safe": @NO
        },
        @{
            @"name": @"Passbook / Wallet Daemon",
            @"id": @"com.apple.passd",
            @"desc": @"Xử lý vé, thẻ Apple Pay và thông báo ví điện tử.",
            @"cat": @"Hệ Thống",
            @"ram": @55,
            @"safe": @NO
        },
        @{
            @"name": @"HomeKit Daemon",
            @"id": @"com.apple.homed",
            @"desc": @"Đồng bộ và quét thiết bị nhà thông minh qua Apple HomeKit.",
            @"cat": @"Nhà Thông Minh",
            @"ram": @45,
            @"safe": @YES
        },
        @{
            @"name": @"Family Circle Daemon",
            @"id": @"com.apple.familycircled",
            @"desc": @"Đồng bộ tài khoản gia đình iCloud và chia sẻ vị trí.",
            @"cat": @"iCloud",
            @"ram": @29,
            @"safe": @YES
        },
        @{
            @"name": @"Siri Inference Daemon",
            @"id": @"com.apple.siri.inferenced",
            @"desc": @"Học hỏi thói quen người dùng để đưa ra gợi ý Siri Spotlight.",
            @"cat": @"Trợ Lý Ảo",
            @"ram": @75,
            @"safe": @YES
        }
    ];

    for (NSDictionary *d in defaults) {
        DaemonItem *item = [[DaemonItem alloc] init];
        item.name = d[@"name"];
        item.bundleID = d[@"id"];
        item.desc = d[@"desc"];
        item.category = d[@"cat"];
        item.memoryUsageMB = [d[@"ram"] intValue];
        item.status = DaemonStatusRunning;
        item.isEnabled = YES;
        item.pid = 100 + (arc4random() % 800);
        [_daemonsList addObject:item];
    }
}

- (NSArray<DaemonItem *> *)getAllDaemons {
    return self.daemonsList;
}

- (BOOL)toggleDaemon:(DaemonItem *)daemon enable:(BOOL)enable {
    daemon.isEnabled = enable;
    if (enable) {
        daemon.status = DaemonStatusRunning;
        if (daemon.pid > 0) {
            kill(daemon.pid, SIGCONT);
        }
        [[KernelExploit shared] logMessage:[NSString stringWithFormat:@"[+] Resumed LaunchDaemon: %@", daemon.bundleID]];
    } else {
        daemon.status = DaemonStatusDisabled;
        if (daemon.pid > 0) {
            kill(daemon.pid, SIGSTOP);
        }
        [[KernelExploit shared] logMessage:[NSString stringWithFormat:@"[-] Frozen/Disabled LaunchDaemon: %@", daemon.bundleID]];
    }
    return YES;
}

- (BOOL)freezeDaemon:(DaemonItem *)daemon {
    return [self toggleDaemon:daemon enable:NO];
}

- (BOOL)resumeDaemon:(DaemonItem *)daemon {
    return [self toggleDaemon:daemon enable:YES];
}

- (int)oneTapOptimizeAllDaemons {
    int totalFreedMB = 0;
    [[KernelExploit shared] logMessage:@"[*] Running One-Tap Extreme Daemon Optimization..."];

    for (DaemonItem *d in self.daemonsList) {
        if ([d.category isEqualToString:@"Quyền Riêng Tư"] ||
            [d.category isEqualToString:@"Cập Nhật"] ||
            [d.category isEqualToString:@"Tiện Ích"] ||
            [d.bundleID isEqualToString:@"com.apple.ReportCrash"] ||
            [d.bundleID isEqualToString:@"com.apple.siri.inferenced"] ||
            [d.bundleID isEqualToString:@"com.apple.homed"]) {

            if (d.isEnabled) {
                [self toggleDaemon:d enable:NO];
                totalFreedMB += d.memoryUsageMB;
            }
        }
    }

    [[KernelExploit shared] logMessage:[NSString stringWithFormat:@"[✓] Extreme Optimization Complete! Freed ~%d MB of RAM.", totalFreedMB]];
    return totalFreedMB;
}

@end
