bits    16

align   8
gdt:
        ; Null segment.
        dq      0
        
        ; Unreal Mode code segment.
        dw      0xFFFF          ; Segment limit bits 15..0.
        dw      0x0000          ; Base bits 15..0.
        db      0x00            ; Base bits 23..16.
        db      0b10011010      ; Access byte.
        db      0b10001111      ; Flags + segment limit bits 19..16.
        db      0x00            ; Base bits 31..24.

        ; Unreal Mode data segment.
        dw      0xFFFF          ; Segment limit bits 15..0.
        dw      0x0000          ; Base bits 15..0.
        db      0x00            ; Base bits 23..16.
        db      0b10010010      ; Access byte.
        db      0b10001111      ; Flags + segment limit bits 19..16.
        db      0x00            ; Base bits 31..24.

        ; 32-bit Protected Mode code segment.
        dw      0xFFFF          ; Segment limit bits 15..0.
        dw      0x0000          ; Base bits 15..0.
        db      0x00            ; Base bits 23..16.
        db      0b10011010      ; Access byte.
        db      0b11001111      ; Flags + segment limit bits 19..16.
        db      0x00            ; Base bits 31..24.
        
        ; 32-bit Protected Mode data segment.
        dw      0xFFFF          ; Segment limit bits 15..0.
        dw      0x0000          ; Base bits 15..0.
        db      0x00            ; Base bits 23..16.
        db      0b10010010      ; Access byte.
        db      0b11001111      ; Flags + segment limit bits 19..16.
        db      0x00            ; Base bits 31..24.

        ; Long Mode code segment.
        dw      0xFFFF          ; Segment limit bits 15..0.
        dw      0x0000          ; Base bits 15..0.
        db      0x00            ; Base bits 23..16.
        db      0b10011010      ; Access byte.
        db      0b10101111      ; Flags + segment limit bits 19..16.
        db      0x00            ; Base bits 31..24.
        
        ; Long Mode data segment.
        dw      0xFFFF          ; Segment limit bits 15..0.
        dw      0x0000          ; Base bits 15..0.
        db      0x00            ; Base bits 23..16.
        db      0b10010010      ; Access byte.
        db      0b10101111      ; Flags + segment limit bits 19..16.
        db      0x00            ; Base bits 31..24.

.descriptor:
        dw      .descriptor - gdt - 1
        dq      gdt
        
