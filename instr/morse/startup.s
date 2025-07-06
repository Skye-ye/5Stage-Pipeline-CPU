# startup.s - matches your linker script
.section .text.init
.global _start

_start:
    # Set stack pointer to fixed value (12KB into 16KB memory)
    li sp, 0x4000
    
    # Clear BSS section using symbols from linker script
    la t0, _bss_start
    la t1, _bss_end
bss_clear:
    beq t0, t1, bss_done
    sw zero, 0(t0)
    addi t0, t0, 4
    blt t0, t1, bss_clear
bss_done:
    
    # Call main function
    jal ra, main
    
    # Infinite loop
halt:
    j halt
