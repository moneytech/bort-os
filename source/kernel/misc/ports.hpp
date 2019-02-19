#pragma once

#include <stdint.h>

void port_out_byte(uint16_t port, uint8_t value);

uint8_t port_in_byte(uint16_t port);

void port_io_wait();
