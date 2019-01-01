bits    16

; Try to enable the A20 line.
; Carry set if couldn't enable the A20 line.
enable_a20_line:
        call    .check_is_a20_enabled
        jc      .enable_with_fast_gate_method
        ret

.enable_with_bios_method:
        mov     ax, 0x2401
        int     0x15
        call    .check_is_a20_enabled
        jc      .enable_with_fast_gate_method
        ret

.enable_with_fast_gate_method:
        in      al, 0x92
        or      al, 1 << 1
        out     0x92, al
        call    .check_is_a20_enabled
        jc      .enable_with_ee_port_method
        ret

.enable_with_ee_port_method:
        push    ax
        in      al, 0xEE
        pop     ax
        call    .check_is_a20_enabled
        ret

.check_is_a20_enabled:
        push    ds
        mov     ax, 0xFFFF
        mov     ds, ax
        mov     si, 0x0510
        mov     [ds:si], byte 0xDB
        pop     ds

        mov     al, byte [0x0500]
        cmp     al, 0xDB
        je      .check_is_a20_enabled_failure

        clc
        ret

.check_is_a20_enabled_failure:
        stc
        ret
