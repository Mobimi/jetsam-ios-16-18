#ifndef KernelTypes_h
#define KernelTypes_h

#include <stdint.h>
#include <stdbool.h>
#include <sys/types.h>

// Memorystatus Control Commands (Darwin / XNU)
#define MEMORYSTATUS_CMD_GET_PRIORITY_LIST            1
#define MEMORYSTATUS_CMD_SET_PRIORITY_PROPERTIES      2
#define MEMORYSTATUS_CMD_GET_JETSAM_SNAPSHOT          3
#define MEMORYSTATUS_CMD_GET_PRESSURE_STATUS          4
#define MEMORYSTATUS_CMD_SET_JETSAM_HIGH_WATER_MARK   5
#define MEMORYSTATUS_CMD_SET_PROCESS_IS_FREEZABLE     6
#define MEMORYSTATUS_CMD_GET_AGGRESSIVE_JETSAM_LENIENT_MODE 7
#define MEMORYSTATUS_CMD_PRIVILEGED_LISTENER_WANTS_OPTIONS 8
#define MEMORYSTATUS_CMD_GRP_SET_PROPERTIES           9
#define MEMORYSTATUS_CMD_ELEVATED_INACTIVE_ALLOWED    10
#define MEMORYSTATUS_CMD_SET_MEMLIMIT_PROPERTIES      11

// Memorystatus State Flags in proc_t
#define P_MEMSTAT_SUSPENDED            0x00000001
#define P_MEMSTAT_FROZEN               0x00000002
#define P_MEMSTAT_FREEZE_DISABLED      0x00000004
#define P_MEMSTAT_ERROR                0x00000008
#define P_MEMSTAT_LOCKED               0x00000010
#define P_MEMSTAT_TERMINATED           0x00000020
#define P_MEMSTAT_INTERNAL             0x00000040
#define P_MEMSTAT_FATAL_MEMLIMIT       0x00000080
#define P_MEMSTAT_PRIORITIZED          0x00000100
#define P_MEMSTAT_FOREGROUND           0x00000200
#define P_MEMSTAT_MANAGED              0x00000400

// Jetsam Priority Bands
#define JETSAM_PRIORITY_IDLE              0
#define JETSAM_PRIORITY_IDLE_DEFERRED     1
#define JETSAM_PRIORITY_BACKGROUND        2
#define JETSAM_PRIORITY_MAIL              3
#define JETSAM_PRIORITY_ELEVATED_INACTIVE 4
#define JETSAM_PRIORITY_LOCATION          5
#define JETSAM_PRIORITY_AUDIO             6
#define JETSAM_PRIORITY_BLUETOOTH         7
#define JETSAM_PRIORITY_MEDIA             8
#define JETSAM_PRIORITY_ACTIVITY          9
#define JETSAM_PRIORITY_FOREGROUND        10
#define JETSAM_PRIORITY_FOREGROUND_KEY    18
#define JETSAM_PRIORITY_CRITICAL          21

// Dynamic Offsets Structure for iOS 17.x - 18.x
typedef struct {
    uint32_t proc_pid;
    uint32_t proc_name;
    uint32_t proc_task;
    uint32_t proc_list_prev;
    uint32_t proc_list_next;
    uint32_t proc_memstat_memlimit;
    uint32_t proc_memstat_memlimit_inactive;
    uint32_t proc_memstat_state;
    uint32_t proc_memstat_effective_priority;
    uint32_t proc_memstat_requested_priority;
    bool     offsets_resolved;
} proc_offsets_t;

// Process Jetsam Info for UI
typedef struct {
    pid_t    pid;
    char     name[64];
    int32_t  active_limit_mb;
    int32_t  inactive_limit_mb;
    int16_t  effective_priority;
    int16_t  requested_priority;
    uint32_t state_flags;
    bool     is_fatal;
    bool     is_frozen;
    uint64_t current_footprint_bytes;
    uint64_t proc_kernel_addr;
} process_jetsam_info_t;

// Kernel Exploit Status
typedef enum {
    EXPLOIT_STATUS_UNINITIALIZED = 0,
    EXPLOIT_STATUS_INITIALIZING,
    EXPLOIT_STATUS_PROBING_ENVIRONMENT,
    EXPLOIT_STATUS_GROOMING_HEAP,
    EXPLOIT_STATUS_TRIGGERING_PRIMITIVE,
    EXPLOIT_STATUS_LEAKING_KERNEL_BASE,
    EXPLOIT_STATUS_RESOLVING_ALLPROC,
    EXPLOIT_STATUS_CALIBRATING_OFFSETS,
    EXPLOIT_STATUS_READY,
    EXPLOIT_STATUS_FAILED
} exploit_status_t;

// Struct for memorystatus_control
typedef struct memorystatus_priority_properties {
    int32_t  priority;
    int32_t  user_data;
} memorystatus_priority_properties_t;

typedef struct memorystatus_memlimit_properties {
    int32_t memlimit_active;
    uint32_t memlimit_active_attr;
    int32_t memlimit_inactive;
    uint32_t memlimit_inactive_attr;
} memorystatus_memlimit_properties_t;

int memorystatus_control(uint32_t command, int32_t pid, uint32_t flags, void *buffer, size_t buffersize);

#endif /* KernelTypes_h */
