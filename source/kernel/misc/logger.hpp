#pragma once

enum class LogType {
    INFO,
    WARNING,
    ERROR
};

void log(LogType type, const char* format, ...);
