#import <Foundation/Foundation.h>
#include "KernelTypes.h"

NS_ASSUME_NONNULL_BEGIN

@interface JetsamProcessModel : NSObject
@property (nonatomic, assign) pid_t pid;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *bundleID;
@property (nonatomic, assign) int32_t activeLimitMB;
@property (nonatomic, assign) int32_t inactiveLimitMB;
@property (nonatomic, assign) int16_t effectivePriority;
@property (nonatomic, assign) uint32_t stateFlags;
@property (nonatomic, assign) BOOL isFatal;
@property (nonatomic, assign) BOOL isFrozen;
@property (nonatomic, assign) uint64_t footprintBytes;
@property (nonatomic, assign) uint64_t procKernelAddr;

- (NSString *)formattedFootprint;
- (NSString *)formattedLimit;
- (NSString *)priorityDescription;
@end

@interface JetsamModifier : NSObject

+ (instancetype)sharedModifier;

- (NSArray<JetsamProcessModel *> *)getAllRunningProcesses;
- (nullable JetsamProcessModel *)getJetsamInfoForPID:(pid_t)pid;

- (BOOL)setJetsamLimit:(int32_t)limitMB forPID:(pid_t)pid error:(NSError **)error;
- (BOOL)setPriority:(int16_t)priority forPID:(pid_t)pid error:(NSError **)error;
- (BOOL)setFreezable:(BOOL)isFreezable forPID:(pid_t)pid error:(NSError **)error;
- (BOOL)setUnlimitedMemoryForPID:(pid_t)pid error:(NSError **)error;

- (BOOL)applyJetsamPreset:(NSString *)presetName forPID:(pid_t)pid error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
