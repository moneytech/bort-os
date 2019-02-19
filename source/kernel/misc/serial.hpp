#pragma once

#include <stdint.h>

enum class SerialPort : uint16_t {
    COM1 = 0x03F8,
    COM2 = 0x02F8,
    COM3 = 0x03E8,
    COM4 = 0x02E8
};

void initialize_serial(const SerialPort port);

void serial_write(SerialPort port, uint8_t value);

uint8_t serial_read(SerialPort port, uint8_t value);
