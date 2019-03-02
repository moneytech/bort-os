#include <devices/display/vga.hpp>

#include <misc/ports.hpp>

namespace __cxxabiv1 {
__extension__ typedef int __guard __attribute__((mode(__DI__)));
extern "C" int  __cxa_guard_acquire(__guard*);
extern "C" void __cxa_guard_release(__guard*);
extern "C" void __cxa_guard_abort(__guard*);
extern "C" int __cxa_guard_acquire(__guard* g) { return !*(char*)(g); }
extern "C" void __cxa_guard_release(__guard* g) { *(char*)g = 1; }
extern "C" void __cxa_guard_abort(__guard*) {}
}

VGA& VGA::get_instance() {
    static VGA instance;
    return instance;
}

void VGA::reset_screen() {
    set_color(0x07);
    clear_screen();
    set_cursor_position(0, 0);
}

void VGA::clear_screen() {
    for (uint32_t i = 0; i < s_buffer_size; i += 2) {
        m_buffer[i + 0] = ' ';
        m_buffer[i + 1] = m_color;
    }
}

void VGA::show_cursor(bool show) {
    if (show) {
        port_out_byte(0x03D4, 0x0A);
        port_out_byte(0x03D5, (port_in_byte(0x03D5) & 0xC0) | 0);
        port_out_byte(0x03D4, 0x0B);
        port_out_byte(0x03D5, (port_in_byte(0x03D5) & 0xE0) | 15);
    } else {
        port_out_byte(0x03D4, 0x0A);
        port_out_byte(0x03D5, 0x20);
    }
}

void VGA::set_cursor_position(const uint32_t x, const uint32_t y) {
    const auto offset = x + y * s_buffer_width;
    port_out_byte(0x03D4, 0x0F);
    port_out_byte(0x03D5, (uint8_t)(offset & 0xFF));
    port_out_byte(0x03D4, 0x0E);
    port_out_byte(0x03D5, (uint8_t)((offset >> 8) & 0xFF));
    m_x_position = x;
    m_y_position = y;
}

void VGA::set_color(const uint8_t color) {
    m_color = color;
}

void VGA::put_char(const char c) {
    const auto offset = (m_x_position + m_y_position * s_buffer_width) * s_buffer_bytes_per_char;
    switch (c) {
        case '\b':
            if (m_x_position > 0) {
                m_x_position -= 1;
            }
            break;

        case '\t':
            m_x_position += 8 - (m_x_position % 8);
            if (m_x_position >= 80) {
                m_x_position = 0;
                m_y_position += 1;
            }
            break;

        case '\n':
            m_x_position = 0;
            m_y_position += 1;
            break;

        case '\r':
            m_x_position = 0;
            break;

        case '\\':
        case '\"':
        default: {
            m_buffer[offset + 0] = c;
            m_buffer[offset + 1] = m_color;
            m_x_position += 1;
            if (m_x_position >= 80) {
                m_x_position = 0;
                m_y_position += 1;
            }
        }
    }

    if (m_update_cursor) {
        set_cursor_position(m_x_position, m_y_position);
    }
}

void VGA::put_string(const char* s) {
    m_update_cursor = false;
    while (*s != '\0') {
        put_char(*s++);
    }
    m_update_cursor = true;
    set_cursor_position(m_x_position, m_y_position);
}
