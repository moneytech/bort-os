org     0x7C00
bits    16

stage1:
        jmp     long .fix_code_segment

.fix_code_segment:
        mov     [disk_index], dl

        cld
        cli

        mov     ax, 0
        mov     ds, ax
        mov     es, ax
        mov     fs, ax
        mov     gs, ax
        mov     ss, ax

        mov     bp, 0x7C00
        mov     sp, 0x7C00

        sti

        mov     ah, 0x02
        mov     al, 7
        mov     bx, 0x7E00
        mov     ch, 0x00
        mov     cl, 2
        mov     dh, 0x00
        mov     dl, [disk_index]
        int     0x13

        jmp     stage2

disk_index      dd      0x00

times   510 - ($ - $$)  db      0x00
db      0x55, 0xAA
