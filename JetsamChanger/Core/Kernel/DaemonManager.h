#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, DaemonStatus) {
    DaemonStatusRunning = 0,
    DaemonStatusFrozen,
    DaemonStatusDisabled
};

@interface DaemonItem : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *bundleID;
@property (nonatomic, copy) NSString *desc;
@property (nonatomic, copy) NSString *category;
@property (nonatomic, assign) pid_t pid;
@property (nonatomic, assign) int memoryUsageMB;
@property (nonatomic, assign) DaemonStatus status;
@property (nonatomic, assign) BOOL isEnabled;
@end

@interface DaemonManager : NSObject

+ (instancetype)shared;

/// Returns all discoverable system LaunchDaemons
- (NSArray<DaemonItem *> *)getAllDaemons;

/// Toggles a specific daemon's state (Running vs Disabled/Frozen)
- (BOOL)toggleDaemon:(DaemonItem *)daemon enable:(BOOL)enable NS_SWIFT_NAME(toggleDaemon(_:enable:));

/// Freezes a running daemon with SIGSTOP
- (BOOL)freezeDaemon:(DaemonItem *)daemon NS_SWIFT_NAME(freezeDaemon(_:));

/// Resumes a frozen daemon with SIGCONT
- (BOOL)resumeDaemon:(DaemonItem *)daemon NS_SWIFT_NAME(resumeDaemon(_:));

/// One-tap extreme optimization: freezes/disables all telemetry & crash daemons
- (int)oneTapOptimizeAllDaemons NS_SWIFT_NAME(oneTapOptimizeAllDaemons());

@end

NS_ASSUME_NONNULL_END
