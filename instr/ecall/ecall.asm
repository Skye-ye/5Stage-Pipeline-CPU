        li    t0, %lo(handler)
        csrrw zero, mtvec, t0
        li    a0, 42          # x10 = 42
        li    a7, 1           # x17 = 1
        ecall
halt:   jal   zero, halt
print:  sw    a0, 0(zero)
        jalr  zero, ra, 0      # Return to caller using return address
handler:csrrs t0, mcause, zero
        li    t1, 11
        bne   t0, t1, done
        li    t0, 1            # x5 = 1
        bne   a7, t0, done     # If a7 != 1, go to done
        jal   ra, print        # Call print and set return address
        jal   zero, done       # Jump to done after print returns
done:   csrrs t0, mepc, zero   # x5 = mepc
        addi  t0, t0, 4
        csrrw zero, mepc, t0    # mepc = x5 + 4
        mret 
