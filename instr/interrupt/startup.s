# startup.s - matches your linker script
.section .text.init
.global _start

_start:
    # Set stack pointer using linker-defined symbol
    la sp, __stack_top
    
    # Clear BSS section using symbols from linker script
    la t0, _bss_start
    la t1, _bss_end
bss_clear:
    beq t0, t1, bss_done
    sw zero, 0(t0)
    addi t0, t0, 4
    blt t0, t1, bss_clear
bss_done:
    
    # Clear stack section
    la t0, _stack_start
    la t1, _stack_end
stack_clear:
    beq t0, t1, stack_done
    sw zero, 0(t0)
    addi t0, t0, 4
    blt t0, t1, stack_clear
stack_done:
    
    # Call main function
    jal ra, main
    
    # Infinite loop
halt:
    j halt
