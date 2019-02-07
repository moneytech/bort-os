bits    16

; Load a file from a BortFS filesystem into the memory.
; ESI Pointer to a file name string.
; EDI Address of target buffer.
; DL  Disk number to load the file from.
; CF  Set on failure, clear on success.
bortfs_load_file:
        push    edx

        ; Calculate how many FAT entries are there in a single block.
        mov     eax, [bortfs_header.block_size]
        xor     edx, edx
        mov     ebx, FAT_ENTRY_SIZE
        div     ebx

        ; Calculate how many blocks FAT occupies.
        mov     ecx, eax
        mov     eax, [bortfs_header.block_count + 0]
        mov     edx, [bortfs_header.block_count + 4]
        add     eax, ecx
        jnc     .dont_inc_edx
        inc     edx
.dont_inc_edx:
        dec     eax
        jnc     .dont_dec_edx
.dont_dec_edx:
        div     ecx

        ; Calculate the offset of main directory from the beginning of the disk.
        mov     ebx, [bortfs_header.reserved_blocks]
        add     eax, ebx
        mov     ebx, [bortfs_header.block_size]
        mul     ebx
        mov     [.main_directory_start], eax

        ; And where the main directory ends.
        mov     ebx, eax
        mov     eax, [bortfs_header.main_directory_size]
        mov     ecx, [bortfs_header.block_size]
        mul     ecx
        add     eax, ebx
        mov     [.main_directory_end], eax

        pop     edx

        ; Loop over the main directory until we find an entry with name tag
        ; matching the one requested in ESI. CF clear if the entry was found,
        ; set otherwise.
        mov     eax, [.main_directory_start]
.main_directory_loop:
        push    eax

        call    compare_string_on_disk
        jnc     .entry_found

        pop     eax
        add     eax, DIRECTORY_ENTRY_SIZE
        cmp     eax, [.main_directory_end]
        jne     .main_directory_loop

        ; Entry was not found.
        stc
        ret

.entry_found:
        pop     eax
        clc

.load_chain:
        add     eax, DIRECTORY_ENTRY_FIRST_BLOCK_OFFSET
        call    read_dword_from_disk

        ; Calculate how many sectors a single block contains.
        push    eax
        push    edx
        mov     eax, [bortfs_header.block_size]
        xor     edx, edx
        mov     ebx, SECTOR_SIZE
        div     ebx
        mov     ebx, eax
        pop     edx
        pop     eax

        ; Calculate the FAT offset.
        ; EBX contains number of sectors per block.
        push    eax
        push    ebx
        push    edx
        mov     eax, [bortfs_header.reserved_blocks]
        xor     edx, edx
        mul     ebx
        mov     ebx, SECTOR_SIZE
        mul     ebx
        mov     ecx, eax
        pop     edx
        pop     ebx
        pop     eax
        push    ecx

.load_chain_loop:
        push    edx
        xor     edx, edx
        mul     ebx
        pop     edx

        push    eax
        mov     ebx, 1
        mov     ecx, 8
.load_block_sectors_loop:
        mov     esi, .sector_buffer
        xchg    esi, edi
        call    read_sectors_from_disk
        xchg    esi, edi

        push    ecx
        mov     ecx, SECTOR_SIZE
        a32 o32 rep     movsb
        pop     ecx

        inc     eax
        dec     ecx
        jnz     .load_block_sectors_loop

        pop     eax
        pop     ecx

        add     eax, ecx
        call    read_dword_from_disk
        cmp     eax, 0xFFFFFFFF
        jne     .load_chain_loop
        ret

align   512,    db      0x00
.sector_buffer          times   512     db      0x00

.main_directory_start   dd      0x00
.main_directory_end     dd      0x00

FAT_ENTRY_SIZE                          equ     8
DIRECTORY_ENTRY_SIZE                    equ     64
DIRECTORY_ENTRY_FIRST_BLOCK_OFFSET      equ     48
DIRECTORY_ENTRY_FIRST_SIZE_OFFSET       equ     56
