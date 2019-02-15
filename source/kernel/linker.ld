OUTPUT_FORMAT("binary")
ENTRY(kernel_main)

SECTIONS {
    . = 0x00100000;

    .text : ALIGN(4096) {
        *(.text.kernel_main)
        *(.text*)
    }

    .rodata : ALIGN(4096) {
        *(.rodata*)
    }

    .data : ALIGN(4096) {
        *(data*)
    }

    .bss : ALIGN(4096) {
        *(.bss*)
        *(COMMON*)
    }
}
