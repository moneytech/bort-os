bits    16

stage2:
        call    enable_a20_line
        jc      .handle_generic_error

        ;mov     ax, 800
        ;mov     bx, 600
        ;mov     cl, 32
        ;call    set_vesa_mode
        ;jc      .handle_generic_error

        ; Clear the screen by setting the 80x25 video mode.
        mov     ah, 0x00
        mov     al, 0x03
        int     0x10

        ; Set the 80x50 video mode by loading the 8x8 font.
        mov     ax, 0x1112
        mov     bl, 0x00
        int     0x10

        ; Something about blanking attribute. Should not be necessary in 21st
        ; century, but it won't charm anything if put here. Just to make sure
        ; that the 80x25 works correctly.
        mov     ah, 0x12
        mov     bl, 0x30
        int     0x10

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

        mov     esi, KERNEL_BIN_NAME
        mov     edi, 0x00100000
        movzx   edx, byte [disk_index]
        call    bortfs_load_file
        ; TODO: Check if the file was actually loaded successfully...

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
        push    edx
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
        mov     ax, 0x00
        mov     ds, ax
        mov     es, ax
        mov     fs, ax
        mov     gs, ax
        mov     ss, ax

        mov     rsp, 0xA0000

        mov     rax, 0xB8000
        mov     rbx, 0x4141414141414141
        mov     [rax], rbx

        ; Jump to the kernel.
        jmp     0x00100000

KERNEL_BIN_NAME         db      "kernel.bin", 0x00

%include        "stage2/a20.asm"
%include        "stage2/bortfs.asm"
%include        "stage2/disk.asm"
%include        "stage2/gdt.asm"
%include        "stage2/paging.asm"
%include        "stage2/vbe.asm"

times   8 * 512 - ($ - $$)      db      0x00
