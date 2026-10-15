#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface InstalledAppItem : NSObject
@property (nonatomic, readonly) NSString *id;
@property (nonatomic, copy) NSString *displayName;
@property (nonatomic, copy) NSString *bundleID;
@property (nonatomic, copy) NSString *bundlePath;
@property (nonatomic, copy) NSString *executablePath;
@property (nonatomic, copy) NSString *versionString;
@property (nonatomic, assign) BOOL isSystemApp;
@property (nonatomic, copy) NSArray<NSString *> *injectedDylibs;
@property (nonatomic, assign) BOOL isJITEnabled;
@end

@interface DylibInjector : NSObject

+ (instancetype)shared;

/// Scans installed applications on the device (/var/containers/Bundle/Application)
- (NSArray<InstalledAppItem *> *)scanInstalledApplications;

/// Inspects an app bundle to list currently injected dylibs
- (NSArray<NSString *> *)getInjectedDylibsForApp:(InstalledAppItem *)app NS_SWIFT_NAME(getInjectedDylibs(for:));

/// Injects a dylib into an application bundle without reinstalling
- (BOOL)injectDylibAtURL:(NSURL *)dylibURL intoApp:(InstalledAppItem *)app error:(NSString * _Nullable * _Nullable)outError NS_SWIFT_NAME(injectDylib(at:into:error:));

/// Removes an injected dylib or restores the original unpatched binary
- (BOOL)ejectDylibNamed:(NSString *)dylibName fromApp:(InstalledAppItem *)app error:(NSString * _Nullable * _Nullable)outError NS_SWIFT_NAME(ejectDylib(named:from:error:));

/// Restores the app binary to its pristine state (.orig backup)
- (BOOL)restoreOriginalBinaryForApp:(InstalledAppItem *)app error:(NSString * _Nullable * _Nullable)outError NS_SWIFT_NAME(restoreOriginalBinary(for:error:));

/// Enables permanent JIT on-device for an app
- (BOOL)enablePermanentJITForApp:(InstalledAppItem *)app error:(NSString * _Nullable * _Nullable)outError NS_SWIFT_NAME(enablePermanentJIT(for:error:));

@end

NS_ASSUME_NONNULL_END
