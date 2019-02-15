bits    64

%macro define_interrupt 2
        global  interrupt_%2
        interrupt_%2:
                mov     rax, 0xDEADBEAF
                mov     rbx, %1
                jmp     $
                iretq
%endmacro

define_interrupt        0x00,   division_error
define_interrupt        0x01,   single_step
define_interrupt        0x02,   nmi
define_interrupt        0x03,   breakpoint
define_interrupt        0x04,   overflow
define_interrupt        0x05,   bounds_range
define_interrupt        0x06,   invalid_opcode
define_interrupt        0x07,   device_not_available
define_interrupt        0x08,   double_fault
define_interrupt        0x0A,   invalid_tss
define_interrupt        0x0B,   segment_not_present
define_interrupt        0x0C,   stack_fault
define_interrupt        0x0D,   gpf
define_interrupt        0x0E,   page_fault
define_interrupt        0x11,   alignment_check
