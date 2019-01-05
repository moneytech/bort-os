bits    16

stage2:
        call    enable_a20_line
        jc      .handle_generic_error

        mov     ax, 800
        mov     bx, 600
        mov     cl, 32
        call    set_vesa_mode
        jc      .handle_generic_error

        lgdt    [gdt.descriptor]

        mov     eax, cr0
        or      eax, 1
        mov     cr0, eax

        cli

        jmp     0x08:.break_16bit_segment_limits

.break_16bit_segment_limits:
        mov     ax, 0x10
        mov     ds, ax
        mov     es, ax
        mov     fs, ax
        mov     gs, ax
        mov     ss, ax

        mov     eax, cr0
        and     eax, ~1
        mov     cr0, eax

        jmp     0x00:.break_16bit_segment_limits_exit

.break_16bit_segment_limits_exit:
        xor     ax, ax
        mov     ds, ax
        mov     es, ax
        mov     fs, ax
        mov     gs, ax
        mov     ss, ax

        sti

        ; We're in "Unreal Mode" now.

        cli

        mov     eax, cr0
        or      eax, 1
        mov     cr0, eax

        jmp     0x18:.protected_mode

.handle_generic_error:
        mov     ah, 0x0E
        mov     al, 'X'
        int     0x10
        jmp     $

bits   32
.protected_mode:
        mov     ax, 0x10
        mov     ds, ax
        mov     es, ax
        mov     fs, ax
        mov     gs, ax
        mov     ss, ax

        call    setup_identity_paging_and_long_mode

        jmp     0x28:.long_mode

bits    64
.long_mode:
        mov     ax, 0x00;
        mov     ds, ax
        mov     es, ax
        mov     fs, ax
        mov     gs, ax
        mov     ss, ax

        jmp     $

%include        "stage2/a20.asm"
%include        "stage2/gdt.asm"
%include        "stage2/paging.asm"
%include        "stage2/vbe.asm"

times   8 * 512 - ($ - $$)      db      0x00
