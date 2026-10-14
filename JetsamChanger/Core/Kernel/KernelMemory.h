#ifndef KernelMemory_h
#define KernelMemory_h

#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>
#include "KernelTypes.h"

#ifdef __cplusplus
extern "C" {
#endif

// Kernel Memory Primitives Interface
uint8_t  kread8(uint64_t kaddr);
uint16_t kread16(uint64_t kaddr);
uint32_t kread32(uint64_t kaddr);
uint64_t kread64(uint64_t kaddr);
uint64_t kread_ptr(uint64_t kaddr);

bool kwrite8(uint64_t kaddr, uint8_t val);
bool kwrite16(uint64_t kaddr, uint16_t val);
bool kwrite32(uint64_t kaddr, uint32_t val);
bool kwrite64(uint64_t kaddr, uint64_t val);

bool kread_buf(uint64_t kaddr, void *buf, size_t sz);
bool kwrite_buf(uint64_t kaddr, const void *buf, size_t sz);

// Offset Calibration & Resolution
proc_offsets_t *get_calibrated_offsets(void);
bool calibrate_dynamic_offsets(uint64_t self_proc_addr);

// System Inspection
uint64_t get_kernel_base(void);
uint64_t get_kernel_slide(void);
uint64_t get_allproc_head(void);
uint64_t get_self_proc_addr(void);

void set_kernel_primitive_handlers(
    uint64_t (*custom_kread64)(uint64_t),
    bool (*custom_kwrite64)(uint64_t, uint64_t),
    bool (*custom_kread_buf)(uint64_t, void*, size_t),
    bool (*custom_kwrite_buf)(uint64_t, const void*, size_t)
);

#ifdef __cplusplus
}
#endif

#endif /* KernelMemory_h */
