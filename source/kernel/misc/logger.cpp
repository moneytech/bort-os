#include <misc/logger.hpp>

#include <misc/serial.hpp>

static void log_put_char(const char c) {
    serial_write(SerialPort::COM1, static_cast<uint8_t>(c));
}

static void log_put_string(const char* s) {
    while (*s != '\0') {
        serial_write(SerialPort::COM1, static_cast<uint8_t>(*s));
        s += 1;
    }
}

void log([[maybe_unused]] LogType type, const char* format, ...) {
    switch (type) {
        case LogType::INFO:
            log_put_string("[INFO]  ");
            break;
        case LogType::WARNING:
            log_put_string("[WARN]  ");
            break;
        case LogType::ERROR:
            log_put_string("[ERROR] ");
            break;
    }

    while (*format != '\0') {
        log_put_char(*format);
        format += 1;
    }
}
