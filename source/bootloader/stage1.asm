org     0x7C00
bits    16

start:
        jmp     short stage1

bortfs_header:
.signature:             db      "BortFS"
.version:               dw      0x00
.padding:               dw      0x00
.block_size:            dd      0x00    ; Size of a single block in bytes.
.block_count:           dq      0x00    ; Total number of blocks in the filesystem.
.reserved_blocks:       dd      0x00    ; Number of reserved blocks in the filesystem.
.main_directory_size:   dd      0x00    ; Size of the main directory in blocks.

stage1:
        jmp     long .fix_code_segment

.fix_code_segment:
        mov     [disk_index], dl

        clc
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

        ; Calculate size of a single block in sectors.
        xor     edx, edx
        mov     eax, [bortfs_header.block_size]
        mov     ebx, SECTOR_SIZE
        div     ebx

        ; Calculate number of reserved sectors.
        ; NOTE: We assume that number of reserved sectors is <256.
        ; NOTE: That wouldn't be a problem if we used Int13/AH=42.
        mov     ebx, [bortfs_header.reserved_blocks]
        mul     ebx

        mov     ah, 0x02
        mov     bx, 0x7E00
        mov     ch, 0x00
        mov     cl, 2
        mov     dh, 0x00
        mov     dl, [disk_index]
        int     0x13

        jmp     stage2

disk_index      dd      0x00

SECTOR_SIZE     equ     512

times   510 - ($ - $$)  db      0x00
db      0x55, 0xAA
