bits    32

PML4_PTR        equ     0x1000
PDP_PTR         equ     0x2000
PD_PTR          equ     0x3000

setup_identity_paging_and_long_mode:
        mov     eax, PDP_PTR
        or      eax, 0b00000011 ; Present + writable.
        mov     [PML4_PTR], eax

        mov     eax, PD_PTR
        or      eax, 0b00000011 ; Present + writable.
        mov     [PDP_PTR], eax

        mov     ecx, 0
.loop:
        mov     eax, 0x200000
        mul     ecx
        or      eax, 0b10000011 ; Present + writable + huge.
        mov     [PD_PTR + ecx * 8], eax
        inc     ecx
        cmp     ecx, 512
        jne     .loop

        ; Load the CR3 register with the PML4 table.
        mov     eax, PML4_PTR
        mov     cr3, eax

        ; Enable the PAE flag.
        mov     eax, cr4
        or      eax, 1 << 5
        mov     cr4, eax

        ; Enable Long Mode.
        mov     ecx, 0xC0000080
        rdmsr
        or      eax, 1 << 8
        wrmsr

        ; Enable paging.
        mov     eax, cr0
        or      eax, 1 << 31
        mov     cr0, eax

        ret
