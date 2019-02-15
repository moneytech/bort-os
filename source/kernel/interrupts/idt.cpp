#include <interrupts/idt.hpp>

#include <stdint.h>

#define IDT_ENTRY_COUNT 256

#define GATE_TYPE_INTERRUPT
#define GATE_TYPE_TRAP

struct IDTEntry {
    uint16_t address_low;  // Bits 0..15 of the handler function address.
    uint16_t selector;     // Code segment selector defined by the GDT.
    uint8_t  ist;          // Interrupt Stack Table.
    uint8_t  attributes;   // Type and attributes.
    uint16_t address_mid;  // Bits 16..31 of the handler function address.
    uint32_t address_high; // Bits 32..63 of the handler function address.
    uint32_t padding;      // Always zero.
};

static_assert(sizeof(IDTEntry) == 16);

static struct IDT { IDTEntry entries[IDT_ENTRY_COUNT]; } g_idt = {{0, 0, 0, 0, 0, 0, 0}};

static_assert(sizeof(IDT) == sizeof(IDTEntry) * IDT_ENTRY_COUNT);

struct IDTPtr {
    uint16_t size;
    uint64_t address;
} __attribute__((packed));

static_assert(sizeof(IDTPtr) == 10);

extern "C" void interrupt_division_error(void);
extern "C" void interrupt_single_step(void);
extern "C" void interrupt_nmi(void);
extern "C" void interrupt_breakpoint(void);
extern "C" void interrupt_overflow(void);
extern "C" void interrupt_bounds_range(void);
extern "C" void interrupt_invalid_opcode(void);
extern "C" void interrupt_device_not_available(void);
extern "C" void interrupt_double_fault(void);
extern "C" void interrupt_invalid_tss(void);
extern "C" void interrupt_segment_not_present(void);
extern "C" void interrupt_stack_fault(void);
extern "C" void interrupt_gpf(void);
extern "C" void interrupt_page_fault(void);
extern "C" void interrupt_alignment_check(void);

static void register_interrupt_handler(
        const uint32_t index, void (*handler)(), uint8_t ist, uint8_t attributes) {
    const uint64_t address           = reinterpret_cast<uint64_t>(handler);
    g_idt.entries[index].address_low = address & 0xFFFF;
    g_idt.entries[index].selector    = 0x28;
    g_idt.entries[index].ist         = ist;
    g_idt.entries[index].attributes  = attributes;
    g_idt.entries[index].address_mid = (address & 0xFFFF0000) >> 16;
    g_idt.entries[index].address_low = (address & 0xFFFFFFFF00000000) >> 32;
    g_idt.entries[index].padding     = 0;
}

void initialize_idt() {
    register_interrupt_handler(0x00, interrupt_division_error, 0, 0x8E);
    register_interrupt_handler(0x01, interrupt_single_step, 0, 0x8E);
    register_interrupt_handler(0x02, interrupt_nmi, 0, 0x8E);
    register_interrupt_handler(0x03, interrupt_breakpoint, 0, 0x8E);
    register_interrupt_handler(0x04, interrupt_overflow, 0, 0x8E);
    register_interrupt_handler(0x05, interrupt_bounds_range, 0, 0x8E);
    register_interrupt_handler(0x06, interrupt_invalid_opcode, 0, 0x8E);
    register_interrupt_handler(0x07, interrupt_device_not_available, 0, 0x8E);
    register_interrupt_handler(0x08, interrupt_double_fault, 0, 0x8E);
    register_interrupt_handler(0x0A, interrupt_invalid_tss, 0, 0x8E);
    register_interrupt_handler(0x0B, interrupt_segment_not_present, 0, 0x8E);
    register_interrupt_handler(0x0C, interrupt_stack_fault, 0, 0x8E);
    register_interrupt_handler(0x0D, interrupt_gpf, 0, 0x8E);
    register_interrupt_handler(0x0E, interrupt_page_fault, 0, 0x8E);
    register_interrupt_handler(0x11, interrupt_alignment_check, 0, 0x8E);
    IDTPtr idt_ptr{sizeof(IDTEntry) * IDT_ENTRY_COUNT - 1, reinterpret_cast<uint64_t>(&g_idt)};
    asm volatile("lidt %0" ::"m"(idt_ptr));
    asm volatile("sti");
}
