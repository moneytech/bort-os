bits    16

align   16
vbe_info:
.signature:             db      "VBE2"
.version:               dw      0x00
.oem_string_ptr:        dd      0x00
.capabilities:          dd      0x00
.video_modes_ptr:       dd      0x00
.vram_size:             dw      0x00
.software_revision:     dw      0x00
.vendor:                dd      0x00
.product:               dd      0x00
.product_revision:      dd      0x00
.reserved:              times   222     db      0x00
.oem_data:              times   256     db      0x00

align   16
vesa_mode_info:
.attributes:            dw      0x00
.window_a:              db      0x00
.window_b:              db      0x00
.granularity:           dw      0x00
.window_size:           dw      0x00
.segment_a:             dw      0x00
.segment_b:             dw      0x00
.win_func_ptr:          dd      0x00
.pitch:                 dw      0x00
.width:                 dw      0x00
.height:                dw      0x00
.char_height:           db      0x00
.char_width:            db      0x00
.planes:                db      0x00
.bpp:                   db      0x00
.banks:                 db      0x00
.memory_model:          db      0x00
.bank_size:             db      0x00
.image_pages:           db      0x00
.reserved1:             db      0x00
.red_mask:              db      0x00
.red_position:          db      0x00
.green_mask:            db      0x00
.green_position:        db      0x00
.blue_mask:             db      0x00
.blue_position:         db      0x00
.reserved_mask:         db      0x00
.reserved_position:     db      0x00
.direct_color:          db      0x00
.framebuffer:           dd      0x00
.invisible_vram:        dd      0x00
.invisible_vram_size:   dw      0x00
.reserved2:             times   206     db      0x00

align   16
edid_info:
.header:                times   8       db      0x00
.vendor_product:        times   10      db      0x00
.edid_version:          db      0x00
.edid_revision:         db      0x00
.display_params:        times   5       db      0x00
.color_params:          times   10      db      0x00
.established_timings:   times   3       db      0x00
.standard_timings:      times   8       dw      0x00
.detailed_timings:      times   72      db      0x00
.extension_flag:        db      0x00
.checksum:              db      0x00

; AX Width.
; BX Height.
; CL Depth.
set_vesa_mode:
        mov     [.requested_width], ax
        mov     [.requested_height], bx
        mov     [.requested_depth], cl

        push    es
        mov     dword [vbe_info.signature], "VBE2"
        mov     ax, 0x4F00
        mov     di, vbe_info
        int     0x10
        pop     es

        cmp     ax, 0x004F
        jne     .exit_failure

        cmp     [vbe_info.signature], dword "VESA"
        jne     .exit_failure

        cmp     [vbe_info.version], word 0x0200
        jl      .exit_failure

        mov     ax, [vbe_info.video_modes_ptr + 2]
        mov     fs, ax
        mov     si, [vbe_info.video_modes_ptr]

.loop:

        mov     cx, [fs:si]
        cmp     cx, 0xFFFF
        je      .exit_failure

        mov     [.best_mode], cx

        add     si, 2
        mov     [.next_mode_ptr], si

        push    es
        mov     ax, 0x4F01
        mov     di, vesa_mode_info
        int     0x10
        pop     es

        cmp     ax, 0x004F
        jne     .exit_failure

        mov     ax, [.requested_width]
        mov     bx, [.requested_height]
        mov     cl, [.requested_depth]

        cmp     ax, [vesa_mode_info.width]
        jne     .next

        cmp     bx, [vesa_mode_info.height]
        jne     .next

        cmp     cl, [vesa_mode_info.bpp]
        jne     .next

        push    es
        mov     ax, 0x4F02
        mov     bx, [.best_mode]
        or      bx, 0x4000
        int     0x10
        pop     es

        cmp     ax, 0x004F
        jne     .exit_failure

        jmp     .exit_success

.next:
        mov     si, [.next_mode_ptr]
        jmp     .loop

.exit_failure:
        stc
        ret

.exit_success:
        clc
        ret

.requested_width:       dw      0x00
.requested_height:      dw      0x00
.requested_depth:       db      0x00
.best_mode:             dw      0x00
.next_mode_ptr:         dw      0x00
