# Interrupt test program
# Tests basic interrupt handling functionality

.text
.globl _start

_start:
    # Initialize registers
    addi x1, x0, 1          # x1 = 1
    addi x2, x0, 2          # x2 = 2
    
    # Enable interrupts in mstatus
    li x3, 0x8              # MIE bit (bit 3)
    csrw mstatus, x3        # Set mstatus.MIE = 1
    
    # Enable timer interrupts in mie
    li x4, 0x80             # Timer interrupt enable (bit 7)  
    csrw mie, x4            # Enable timer interrupts
    
    # Set interrupt vector base
    la x5, interrupt_handler
    csrw mtvec, x5          # Set interrupt vector
    
    # Main loop - simple computation
main_loop:
    add x6, x1, x2          # x6 = x1 + x2
    addi x1, x1, 1          # Increment x1
    addi x7, x7, 1          # Increment loop counter
    bne x7, x0, main_loop   # Continue loop
    
    # Should never reach here in normal operation
    ebreak

# Interrupt handler
interrupt_handler:
    # Save some registers (simplified)
    addi x10, x0, 0x100     # Load marker value
    
    # Read interrupt cause
    csrr x11, mcause        # Read cause
    
    # Simple interrupt handling
    addi x12, x12, 1        # Increment interrupt counter
    
    # Clear interrupt (would be done by hardware/timer in real system)
    # For simulation, we just acknowledge it
    
    # Return from interrupt
    mret

# Data section (if needed)
.data
    .word 0x12345678