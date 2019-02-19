#include <misc/serial.hpp>

#include <misc/ports.hpp>

void initialize_serial(const SerialPort port) {
    const auto porti = static_cast<uint16_t>(port);
    port_out_byte(porti + 1, 0x00);   // Disable all interrupts
    port_out_byte(porti + 3, 0x80);   // Enable DLAB (set baud rate divisor)
    port_out_byte(porti + 0, 0x03);   // Set divisor to 3 (lo byte) 38400 baud
    port_out_byte(porti + 1, 0x00);   //                  (hi byte)
    port_out_byte(porti + 3, 0x03);   // 8 bits, no parity, one stop bit
    port_out_byte(porti + 2, 0xC7);   // Enable FIFO, clear them, with 14-byte threshold
    port_out_byte(porti + 4, 0x0B);   // IRQs enabled, RTS/DSR set
}

void serial_write(const SerialPort port, const uint8_t value) {
    while ((port_in_byte(static_cast<uint16_t>(port) + 5) & 0x20) == 0) {}
    port_out_byte(static_cast<uint16_t>(port), value);
}

uint8_t serial_read(const SerialPort port) {
    while ((port_in_byte(static_cast<uint16_t>(port) + 5) & 0x01) == 0) {}
    return port_in_byte(static_cast<uint16_t>(port));
}
