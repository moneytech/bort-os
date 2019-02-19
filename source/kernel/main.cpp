#include <interrupts/idt.hpp>
#include <misc/logger.hpp>
#include <misc/serial.hpp>

// This is a dirty workaround for LD. For raw binaries entry point isn't guaranteed to be the very
// first thing in the binary, so we manualy assign the 'kernel_main' function to a section we're
// later referencing in LinkerScript to be on top of '.text' section what effectively makes it
// the very first thing in the output file.
extern "C" void kernel_main() __attribute__((section(".text.kernel_main")));

int div(int a, int b) { return a / b; };

extern "C" void kernel_main() {
    initialize_serial(SerialPort::COM1);
    log(LogType::INFO, "Initialized: COM1\n");

    initialize_idt();
    log(LogType::INFO, "Initialized: IDT\n");

    const int x = div(7, 0);
    while (true) {
    }
}
