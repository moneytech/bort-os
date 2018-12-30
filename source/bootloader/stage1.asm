org     0x7C00
bits    16

stage1:
        jmp     long .fix_code_segment

.fix_code_segment:
        mov     ax, 0
        mov     ds, ax
        mov     es, ax
        mov     fs, ax
        mov     gs, ax
        mov     ss, ax

        mov     bp, 0x7C00
        mov     sp, 0x7C00

        jmp     $

times   510 - ($ - $$)  db      0x00
db      0x55, 0xAA
