#pragma once

#include <stdint.h>

#define GET_VGA() VGA::get_instance()

class VGA {
public:
    VGA(const VGA&) = delete;
    VGA(VGA&&) = delete;
    VGA& operator=(const VGA&) = delete;
    VGA& operator=(VGA&&) = delete;

    static VGA& get_instance();

    void reset_screen();

    void clear_screen();

    void show_cursor(bool show);

    void set_cursor_position(uint32_t x, uint32_t y);

    void set_color(uint8_t color);

    void put_char(char c);

    void put_string(const char* s);

private:
    VGA() = default;

    static constexpr uint64_t s_buffer_address = 0xB8000;
    static constexpr uint64_t s_buffer_width = 80;
    static constexpr uint64_t s_buffer_height = 50;
    static constexpr uint64_t s_buffer_bytes_per_char = 2;
    static constexpr uint64_t s_buffer_size =
            s_buffer_width * s_buffer_height * s_buffer_bytes_per_char;

    uint16_t* m_buffer = reinterpret_cast<uint16_t*>(s_buffer_address);
    uint32_t  m_x_position = 0;
    uint32_t  m_y_position = 0;
    uint8_t   m_color = 0x07;
    bool      m_show_cursor = true;
    bool      m_update_cursor = true;
};
