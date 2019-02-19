#include <misc/ports.hpp>

void port_out_byte(const uint16_t port, const uint8_t value) {
    asm volatile("outb %0, %1" :: "a"(value), "Nd"(port));
}

uint8_t port_in_byte(const uint16_t port) {
    uint8_t value;
    asm volatile("inb %1, %0" : "=a"(value) : "Nd"(port));
    return value;
}

void port_io_wait() {
    port_out_byte(0x80, 0x00);
}
