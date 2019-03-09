bits    64

global  initialize_gdt
initialize_gdt:
        lgdt    [gdt_descriptor]
        jmp     far [.reload_segment_registers_ptr]

align   8
.reload_segment_registers_ptr:
        dq      .reload_segment_registers
        dw      0x08

.reload_segment_registers:
        xor     ax, ax
        mov     ds, ax
        mov     es, ax
        mov     fs, ax
        mov     gs, ax
        mov     ss, ax
        ret

gdt_descriptor:
        dw      gdt_end - gdt_begin - 1
        dq      gdt_begin

gdt_begin:
        ; Null descriptor.
        dq      0x00

        ; Kernel code descriptor.
        dw 0x0000
        dw 0x0000
        db 0x00
        db 0b10011010
        db 0b00100000
        db 0x00

        ; Kernel data descriptor.
        dw 0x0000
        dw 0x0000
        db 0x00
        db 0b10010010
        db 0b00000000
        db 0x00
gdt_end:
