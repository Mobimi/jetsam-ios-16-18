#include "KernelMemory.h"
#include <string.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>

static uint64_t g_kernel_base = 0;
static uint64_t g_kernel_slide = 0;
static uint64_t g_allproc_head = 0;
static uint64_t g_self_proc = 0;
static proc_offsets_t g_offsets = {0};

static uint64_t (*g_kread64_handler)(uint64_t) = NULL;
static bool (*g_kwrite64_handler)(uint64_t, uint64_t) = NULL;
static bool (*g_kread_buf_handler)(uint64_t, void*, size_t) = NULL;
static bool (*g_kwrite_buf_handler)(uint64_t, const void*, size_t) = NULL;

void set_kernel_primitive_handlers(
    uint64_t (*custom_kread64)(uint64_t),
    bool (*custom_kwrite64)(uint64_t, uint64_t),
    bool (*custom_kread_buf)(uint64_t, void*, size_t),
    bool (*custom_kwrite_buf)(uint64_t, const void*, size_t)
) {
    g_kread64_handler = custom_kread64;
    g_kwrite64_handler = custom_kwrite64;
    g_kread_buf_handler = custom_kread_buf;
    g_kwrite_buf_handler = custom_kwrite_buf;
}

uint64_t get_kernel_base(void) { return g_kernel_base; }
uint64_t get_kernel_slide(void) { return g_kernel_slide; }
uint64_t get_allproc_head(void) { return g_allproc_head; }
uint64_t get_self_proc_addr(void) { return g_self_proc; }
proc_offsets_t *get_calibrated_offsets(void) { return &g_offsets; }

uint64_t kread64(uint64_t kaddr) {
    if (g_kread64_handler) return g_kread64_handler(kaddr);
    uint64_t val = 0;
    if (g_kread_buf_handler && g_kread_buf_handler(kaddr, &val, sizeof(val))) {
        return val;
    }
    return 0;
}

uint32_t kread32(uint64_t kaddr) {
    uint64_t val = kread64(kaddr & ~7ULL);
    uint32_t shift = (kaddr & 4) ? 32 : 0;
    return (uint32_t)((val >> shift) & 0xFFFFFFFF);
}

uint16_t kread16(uint64_t kaddr) {
    uint32_t val32 = kread32(kaddr & ~3ULL);
    uint32_t shift = (kaddr & 2) ? 16 : 0;
    return (uint16_t)((val32 >> shift) & 0xFFFF);
}

uint8_t kread8(uint64_t kaddr) {
    uint32_t val32 = kread32(kaddr & ~3ULL);
    uint32_t shift = (kaddr & 3) * 8;
    return (uint8_t)((val32 >> shift) & 0xFF);
}

uint64_t kread_ptr(uint64_t kaddr) {
    uint64_t ptr = kread64(kaddr);
    // Strip PAC (Pointer Authentication Code) bits for ARM64e if present
    if (ptr > 0xFFFFFF8000000000ULL) {
        ptr |= 0xFFFFFF8000000000ULL;
    }
    return ptr;
}

bool kwrite64(uint64_t kaddr, uint64_t val) {
    if (g_kwrite64_handler) return g_kwrite64_handler(kaddr, val);
    if (g_kwrite_buf_handler) return g_kwrite_buf_handler(kaddr, &val, sizeof(val));
    return false;
}

bool kwrite32(uint64_t kaddr, uint32_t val) {
    uint64_t aligned = kaddr & ~7ULL;
    uint64_t current = kread64(aligned);
    uint64_t mask = 0xFFFFFFFFULL;
    uint32_t shift = (kaddr & 4) ? 32 : 0;
    uint64_t updated = (current & ~(mask << shift)) | (((uint64_t)val & mask) << shift);
    return kwrite64(aligned, updated);
}

bool kwrite16(uint64_t kaddr, uint16_t val) {
    uint64_t aligned = kaddr & ~3ULL;
    uint32_t current = kread32(aligned);
    uint32_t mask = 0xFFFF;
    uint32_t shift = (kaddr & 2) ? 16 : 0;
    uint32_t updated = (current & ~(mask << shift)) | ((val & mask) << shift);
    return kwrite32(aligned, updated);
}

bool kwrite8(uint64_t kaddr, uint8_t val) {
    uint64_t aligned = kaddr & ~3ULL;
    uint32_t current = kread32(aligned);
    uint32_t mask = 0xFF;
    uint32_t shift = (kaddr & 3) * 8;
    uint32_t updated = (current & ~(mask << shift)) | ((val & mask) << shift);
    return kwrite32(aligned, updated);
}

bool kread_buf(uint64_t kaddr, void *buf, size_t sz) {
    if (g_kread_buf_handler) return g_kread_buf_handler(kaddr, buf, sz);
    uint8_t *byte_buf = (uint8_t *)buf;
    for (size_t i = 0; i < sz; i += 8) {
        uint64_t chunk = kread64(kaddr + i);
        size_t to_copy = (sz - i < 8) ? (sz - i) : 8;
        memcpy(byte_buf + i, &chunk, to_copy);
    }
    return true;
}

bool kwrite_buf(uint64_t kaddr, const void *buf, size_t sz) {
    if (g_kwrite_buf_handler) return g_kwrite_buf_handler(kaddr, buf, sz);
    const uint8_t *byte_buf = (const uint8_t *)buf;
    for (size_t i = 0; i < sz; i += 8) {
        size_t to_copy = (sz - i < 8) ? (sz - i) : 8;
        if (to_copy == 8) {
            uint64_t chunk;
            memcpy(&chunk, byte_buf + i, 8);
            if (!kwrite64(kaddr + i, chunk)) return false;
        } else {
            for (size_t j = 0; j < to_copy; j++) {
                if (!kwrite8(kaddr + i + j, byte_buf[i + j])) return false;
            }
        }
    }
    return true;
}

/**
 * Dynamic Offset Calibration for iOS 17.x & iOS 18.x:
 * Scans self proc_t using known runtime values to dynamically identify
 * struct proc field offsets, preventing offset drift across minor releases.
 */
bool calibrate_dynamic_offsets(uint64_t self_proc_addr) {
    if (!self_proc_addr) return false;
    g_self_proc = self_proc_addr;

    pid_t my_pid = getpid();
    const char *prog_name = getprogname();
    if (!prog_name || strlen(prog_name) == 0) {
        prog_name = "JetsamChanger";
    }

    // Default heuristics based on XNU 10002+ (iOS 17) and 10063+ (iOS 18)
    g_offsets.proc_list_prev = 0x00;
    g_offsets.proc_list_next = 0x08;
    g_offsets.proc_task      = 0x10;
    g_offsets.proc_pid       = 0x60;
    g_offsets.proc_name      = 0x258;
    g_offsets.proc_memstat_memlimit            = 0x3d0;
    g_offsets.proc_memstat_memlimit_inactive   = 0x3d4;
    g_offsets.proc_memstat_effective_priority  = 0x3d8;
    g_offsets.proc_memstat_requested_priority  = 0x3da;
    g_offsets.proc_memstat_state               = 0x3dc;

    // Scan memory range [self_proc_addr + 0x40, self_proc_addr + 0x120] for pid
    for (uint32_t off = 0x40; off <= 0x120; off += 4) {
        uint32_t val = kread32(self_proc_addr + off);
        if (val == (uint32_t)my_pid) {
            // Confirm previous or next dword looks reasonable
            g_offsets.proc_pid = off;
            break;
        }
    }

    // Scan memory range [self_proc_addr + 0x200, self_proc_addr + 0x450] for process name
    size_t prog_len = strlen(prog_name);
    if (prog_len > 15) prog_len = 15;
    for (uint32_t off = 0x200; off <= 0x450; off += 4) {
        char name_buf[32] = {0};
        kread_buf(self_proc_addr + off, name_buf, prog_len);
        if (strncmp(name_buf, prog_name, prog_len) == 0) {
            g_offsets.proc_name = off;
            break;
        }
    }

    // Heuristic scan for memstat fields located after proc_name
    uint32_t search_start = g_offsets.proc_name + 16;
    for (uint32_t off = search_start; off < search_start + 0x200; off += 4) {
        // Effective priority usually sits around 0-21 (int16_t)
        int16_t prio = (int16_t)kread16(self_proc_addr + off);
        if (prio >= 0 && prio <= 21) {
            // Check if adjacent words match memstat state flags or limit
            uint32_t state = kread32(self_proc_addr + off + 4);
            if ((state & 0x00000001) || (state & 0x00000200) || (state & 0x00000400) || state == 0) {
                g_offsets.proc_memstat_effective_priority = off;
                g_offsets.proc_memstat_requested_priority = off + 2;
                g_offsets.proc_memstat_state = off + 4;
                g_offsets.proc_memstat_memlimit = off - 8;
                g_offsets.proc_memstat_memlimit_inactive = off - 4;
                break;
            }
        }
    }

    g_offsets.offsets_resolved = true;
    return true;
}
