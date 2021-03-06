#include <stddef.h>
#include <stdint.h>

#include <devices/display/vga.hpp>
#include <interrupts/idt.hpp>
#include <misc/logger.hpp>
#include <misc/serial.hpp>

// This is a dirty workaround for LD. For raw binaries entry point isn't guaranteed to be the very
// first thing in the binary, so we manualy assign the 'kernel_main' function to a section we're
// later referencing in LinkerScript to be on top of '.text' section what effectively makes it
// the very first thing in the output file.
extern "C" void kernel_main() __attribute__((section(".text.kernel_main")));

extern "C" void initialize_gdt();

extern "C" void kernel_main() {
    GET_VGA().reset_screen();
    GET_VGA().show_cursor(false);
    GET_VGA().reset_screen();
    GET_VGA().set_color(0x0F);
    GET_VGA().put_string("BortOS v0.1.0-alpha0\n");
    GET_VGA().set_color(0x07);

    initialize_serial(SerialPort::COM1);
    log(LogType::INFO, "Initialized: COM1\n");

    initialize_gdt();
    log(LogType::INFO, "Initialized: GDT\n");

    initialize_idt();
    log(LogType::INFO, "Initialized: IDT\n");

    GET_VGA().show_cursor(true);
    GET_VGA().put_string("This is a test!\n");
    GET_VGA().put_string("\tSome indent...\n");
    GET_VGA().put_string("Carriage return?\r");

    while (true) {
    }
}
