; EAX Starting sector index.
; BX  Number of blocks to load.
; DL  Disk index.
; EDI Destination buffer address.
read_sectors_from_disk:
        push    ax
        push    si

        mov     [.first_sector], eax
        mov     [.block_count], bx
        mov     [.target_buffer], edi

        mov     si, .disk_address_packet
        mov     ah, 0x42
        int     0x13

        pop     si
        pop     ax
        ret

.disk_address_packet:
.size           db      0x10
.reserved       db      0x00
.block_count    dw      0x00
.target_buffer  dd      0x00
.first_sector   dq      0x00

; EAX Address of the byte to read.
; DL  Disk index to read from.
read_byte_from_disk:
        push    ebx
        push    ecx

        push    dx
        xor     edx, edx
        mov     bx, SECTOR_SIZE
        div     ebx
        mov     ecx, edx
        pop     dx

        push    edi
        mov     ebx, 1
        mov     edi, __disk_asm_private.sector_buffer
        call    read_sectors_from_disk
        pop     edi

        mov     al, [__disk_asm_private.sector_buffer + ecx]

        pop     ecx
        pop     ebx
        ret

; EAX Address of the word to read.
; DL  Disk index to read from.
read_word_from_disk:
        push    ebx
        push    ecx

        push    dx
        xor     edx, edx
        mov     bx, SECTOR_SIZE
        div     ebx
        mov     ecx, edx
        pop     dx

        push    edi
        mov     ebx, 1
        mov     edi, __disk_asm_private.sector_buffer
        call    read_sectors_from_disk
        pop     edi

        mov     ax, [__disk_asm_private.sector_buffer + ecx]

        pop     ecx
        pop     ebx
        ret

; EAX Address of the dword to read.
; DL  Disk index to read from.
read_dword_from_disk:
        push    ebx
        push    ecx

        push    dx
        xor     edx, edx
        mov     bx, SECTOR_SIZE
        div     ebx
        mov     ecx, edx
        pop     dx

        push    edi
        mov     ebx, 1
        mov     edi, __disk_asm_private.sector_buffer
        call    read_sectors_from_disk
        pop     edi

        mov     eax, [__disk_asm_private.sector_buffer + ecx]

        pop     ecx
        pop     ebx
        ret

; EAX Address of the string on disk.
; ESI Address of the string in memory.
; DL  Disk index to load the string from.
compare_string_on_disk:
        push    eax
        push    esi

.loop:
        push    eax
        call    read_byte_from_disk
        jc      .not_equal
        mov     ah, al
        lodsb

        cmp     ah, al
        jne     .not_equal

        test    al, al
        jz      .equal

        pop     eax
        inc     eax
        jmp     .loop

.equal:
        clc
        jmp     .exit

.not_equal:
        stc

.exit:
        pop     eax
        pop     esi
        pop     eax
        ret

__disk_asm_private:
.sector_buffer  times   512     db      0x00
