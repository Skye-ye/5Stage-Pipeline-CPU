        addi x28, x0, 0         # x28 = timer interrupt counter (initially 0)
        li   t0, %lo(handler)
        csrrw zero, mtvec, t0   # Set interrupt vector to timer_handler
        li   t0, 0x8            # MIE bit (bit 3) in mstatus
        csrrs zero, mstatus, t0 # Set mstatus.MIE = 1
        li   t0, 0x80           # MTIE bit (bit 7) for timer interrupts
        csrrs zero, mie, t0     # Set mie.MTIE = 1
        addi x1, x0, 1          # x1 = 1 (increment value)
        addi x2, x0, 0          # x2 = 0 (main loop counter)
        addi x3, x0, 100        # x3 = 100 (loop limit)
main:   add  x2, x2, x1         # x2 = x2 + 1 (increment counter)
        blt  x2, x3, main       # Continue if x2 < 100
        addi x2, x0, 0          # Reset counter to 0
        jal  x0, main           # Jump back to main loop
handler:csrrs t0, mcause, zero
        li    t1, 0x80000007
        bne   t0, t1, other
        addi  x28, x28, 1
other:  mret
# Timer interrupt handler test
# Counts the number of timer interrupts and stores the count in register x28
# Uses timer interrupt cause code 0x80000007